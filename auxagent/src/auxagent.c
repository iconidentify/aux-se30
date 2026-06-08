/*
 * auxagent - a tiny HTTP server implementing the A/UX Agent Protocol (AAP).
 *
 * Purpose: a reliable, framed replacement for telnet/ftp automation against
 * A/UX machines (the QEMU build guest and the real SE/30). Every operation is
 * a one-shot HTTP request with an explicit Content-Length, so the client
 * always knows when a response is complete -- no flush-lag guessing, no
 * sentinels, no leaked login/ftpd sessions.
 *
 * Endpoints (see README.md for the full spec):
 *   GET  /ping              -> "auxagent <version>"
 *   POST /exec   body=cmd   -> runs `sh -c "(cmd) 2>&1"`, body=output,
 *                              header X-Exit-Code: N
 *   GET  /file/<abspath>    -> file bytes, header X-Aap-Sum: <crc32 hex>
 *   PUT  /file/<abspath>    body=bytes -> writes file, X-Aap-Sum of received
 *
 * Security: if AAP_TOKEN is set in the environment, every request must carry a
 * matching X-Aap-Token header. /exec runs commands as the user that launched
 * the agent (typically root) -- intended only for your own lab machines on a
 * trusted LAN. See README "Security".
 *
 * Portable C89; links against BSD sockets (-lbsd on A/UX).
 */
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <signal.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "aap.h"

#define MAXHDR      16384      /* max request header bytes */
#define MAXCMD      65536      /* max /exec command length */
#define IOBUF       8192
#define READ_TIMEOUT 180       /* seconds before a stuck connection is dropped */
#define EXEC_TMP    "/tmp/auxagent.out"

static int g_client = -1;

static void on_alarm(sig)
int sig;
{
    if (g_client >= 0)
        (void) close(g_client);   /* unblock a stuck read */
}

/* read() from a socket with a timeout via select() (no signals, so it never
   interferes with system()/wait()). Returns the read count, 0 on EOF, or -1 on
   timeout/error so a stalled client can't wedge the sequential server. */
static int timed_read(fd, buf, n)
int fd; char *buf; int n;
{
    fd_set rfds;
    struct timeval tv;
    int r;

    FD_ZERO(&rfds);
    FD_SET(fd, &rfds);
    tv.tv_sec = READ_TIMEOUT;
    tv.tv_usec = 0;
    r = select(fd + 1, &rfds, (fd_set *) 0, (fd_set *) 0, &tv);
    if (r <= 0)
        return -1;
    return read(fd, buf, n);
}

/* Write all <n> bytes of <p> to fd; returns 0 on success, -1 on error. */
static int write_all(fd, p, n)
int fd; const char *p; long n;
{
    long off = 0;
    int w;
    while (off < n) {
        w = write(fd, p + off, (int) (n - off));
        if (w <= 0)
            return -1;
        off += w;
    }
    return 0;
}

static void send_status(fd, code, reason)
int fd; int code; const char *reason;
{
    char line[128];
    sprintf(line, "HTTP/1.0 %d %s\r\n", code, reason);
    (void) write_all(fd, line, (long) strlen(line));
}

static void send_simple(fd, code, reason, body)
int fd; int code; const char *reason; const char *body;
{
    char hdr[256];
    long blen = (long) strlen(body);
    send_status(fd, code, reason);
    sprintf(hdr, "Content-Length: %ld\r\nContent-Type: text/plain\r\n\r\n", blen);
    (void) write_all(fd, hdr, (long) strlen(hdr));
    (void) write_all(fd, body, blen);
}

/* CRC-32 of a file by streaming it. Returns 0 on success (writing the size and
   crc through the pointers), or -1 if the file can't be opened. NOTE: status is
   returned separately from the CRC -- a CRC value with the high bit set must not
   be mistaken for an error. */
static int file_crc(path, sizeout, crcout)
const char *path; long *sizeout; unsigned long *crcout;
{
    unsigned char buf[IOBUF];
    unsigned long crc = 0xFFFFFFFFUL;
    long total = 0;
    int fd, n, k;
    long i;

    fd = open(path, O_RDONLY);
    if (fd < 0)
        return -1;
    while ((n = read(fd, (char *) buf, sizeof buf)) > 0) {
        for (i = 0; i < n; i++) {
            crc ^= (unsigned long) buf[i];
            for (k = 0; k < 8; k++)
                crc = (crc & 1UL) ? (crc >> 1) ^ 0xEDB88320UL : (crc >> 1);
        }
        total += n;
    }
    (void) close(fd);
    if (sizeout)
        *sizeout = total;
    if (crcout)
        *crcout = (crc ^ 0xFFFFFFFFUL) & 0xFFFFFFFFUL;
    return 0;
}

/* Send a file as the response body with size + crc headers. */
static void send_file(fd, path, exitcode)
int fd; const char *path; int exitcode;
{
    char hdr[512];
    char iobuf[IOBUF];
    long size = 0;
    unsigned long crc = 0;
    int in, n;

    if (file_crc(path, &size, &crc) < 0) {
        send_simple(fd, 404, "Not Found", "no such file\n");
        return;
    }
    in = open(path, O_RDONLY);
    if (in < 0) {
        send_simple(fd, 404, "Not Found", "open failed\n");
        return;
    }
    send_status(fd, 200, "OK");
    sprintf(hdr,
            "Content-Length: %ld\r\nContent-Type: application/octet-stream\r\n"
            "X-Exit-Code: %d\r\nX-Aap-Sum: %08lx\r\n\r\n",
            size, exitcode, crc);
    (void) write_all(fd, hdr, (long) strlen(hdr));
    while ((n = read(in, iobuf, sizeof iobuf)) > 0) {
        if (write_all(fd, iobuf, (long) n) < 0)
            break;
    }
    (void) close(in);
}

/* POST /exec : body is the command. */
static void do_exec(fd, body, blen)
int fd; const char *body; long blen;
{
    static long seq = 0;
    char *cmd, *wrap;
    char tmp[64];
    int rc, exitcode;

    /* heap, not stack: a large stack buffer here overflows the daemon stack
       on A/UX and corrupts the command handed to system(). */
    cmd = (char *) malloc((unsigned) (blen + 1));
    wrap = (char *) malloc((unsigned) (blen + 128));
    if (!cmd || !wrap) {
        if (cmd) free(cmd);
        if (wrap) free(wrap);
        send_simple(fd, 500, "Internal Error", "oom\n");
        return;
    }
    memcpy(cmd, body, (int) blen);
    cmd[blen] = '\0';

    /* unique temp file per request (avoids stale output / cross-call races) */
    sprintf(tmp, "/tmp/auxagent.%d.%ld", (int) getpid(), seq++);
    (void) unlink(tmp);

    /* run with stdout+stderr merged into the temp file so we can frame it */
    sprintf(wrap, "(%s) > %s 2>&1", cmd, tmp);
    rc = system(wrap);
    exitcode = (rc >> 8) & 0xff;
    free(cmd);
    free(wrap);

    /* distinguish "command produced no output file" (system/redirect failed)
       from a normal empty result, and report it clearly. */
    if (access(tmp, 0) < 0) {
        send_simple(fd, 500, "Internal Error", "exec output file missing\n");
        return;
    }
    send_file(fd, tmp, exitcode);
    (void) unlink(tmp);
}

/* PUT /file : write <clen> bytes (some already in <pre>/<prelen>) to <path>. */
static void do_put(fd, path, pre, prelen, clen)
int fd; const char *path; const char *pre; int prelen; long clen;
{
    char iobuf[IOBUF];
    char hdr[256];
    unsigned long crc = 0xFFFFFFFFUL;
    long got = 0;
    int out, n, k;
    long i;

    out = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (out < 0) {
        send_simple(fd, 500, "Internal Error", "open for write failed\n");
        return;
    }
    /* leftover body bytes from the header read */
    if (prelen > 0) {
        (void) write_all(out, pre, (long) prelen);
        for (i = 0; i < prelen; i++) {
            crc ^= (unsigned long) (unsigned char) pre[i];
            for (k = 0; k < 8; k++)
                crc = (crc & 1UL) ? (crc >> 1) ^ 0xEDB88320UL : (crc >> 1);
        }
        got += prelen;
    }
    /* bounded reads: never read past Content-Length, or we'd block waiting
       for bytes the client won't send. */
    while (got < clen) {
        long want = clen - got;
        if (want > (long) sizeof iobuf) want = (long) sizeof iobuf;
        n = timed_read(fd, iobuf, (int) want);
        if (n <= 0)
            break;
        if (write_all(out, iobuf, (long) n) < 0)
            break;
        for (i = 0; i < n; i++) {
            crc ^= (unsigned long) (unsigned char) iobuf[i];
            for (k = 0; k < 8; k++)
                crc = (crc & 1UL) ? (crc >> 1) ^ 0xEDB88320UL : (crc >> 1);
        }
        got += n;
    }
    (void) close(out);

    crc = (crc ^ 0xFFFFFFFFUL) & 0xFFFFFFFFUL;
    send_status(fd, 200, "OK");
    sprintf(hdr, "Content-Length: 0\r\nX-Exit-Code: %d\r\nX-Aap-Sum: %08lx\r\n\r\n",
            (got == clen) ? 0 : 1, crc);
    (void) write_all(fd, hdr, (long) strlen(hdr));
}

static void handle(fd)
int fd;
{
    char buf[MAXHDR + 1];
    char method[16], rawpath[2048], path[2048];
    const char *headers;
    char tokwant[256], tokgot[256];
    int nread = 0, boff, n;
    long clen;
    char *token;

    g_client = fd;
    /* (read timeout via alarm removed: it interfered with system() wait) */

    /* read until we have the full header block */
    boff = -1;
    while (nread < MAXHDR) {
        n = timed_read(fd, buf + nread, MAXHDR - nread);
        if (n <= 0)
            break;
        nread += n;
        boff = aap_header_end(buf, nread);
        if (boff >= 0)
            break;
    }
    if (boff < 0) {
        send_simple(fd, 400, "Bad Request", "no header\n");
        return;
    }
    buf[nread] = '\0';

    if (!aap_parse_reqline(buf, method, sizeof method, rawpath, sizeof rawpath)) {
        send_simple(fd, 400, "Bad Request", "bad request line\n");
        return;
    }
    /* header block starts after the first line */
    headers = strchr(buf, '\n');
    headers = headers ? headers + 1 : buf;
    clen = aap_header_long(headers, "Content-Length", 0);

    /* token auth */
    token = getenv("AAP_TOKEN");
    if (token && token[0]) {
        strncpy(tokwant, token, sizeof tokwant - 1);
        tokwant[sizeof tokwant - 1] = '\0';
        if (!aap_header_str(headers, "X-Aap-Token", tokgot, sizeof tokgot) ||
            strcmp(tokgot, tokwant) != 0) {
            fprintf(stderr, "auxagent: %s %s -> 403 (bad token)\n", method, rawpath);
            send_simple(fd, 403, "Forbidden", "bad or missing X-Aap-Token\n");
            return;
        }
    }

    aap_url_decode(rawpath, path, sizeof path);
    fprintf(stderr, "auxagent: %s %s (clen=%ld)\n", method, path, clen);

    if (strcmp(method, "GET") == 0 && strcmp(path, "/ping") == 0) {
        send_simple(fd, 200, "OK", "auxagent " AAP_VERSION "\n");
        return;
    }
    if (strcmp(method, "POST") == 0 && strcmp(path, "/exec") == 0) {
        /* gather full body (leftover in buf + read remainder) */
        static char cmdbuf[MAXCMD + 1];
        long have = nread - boff;
        if (clen > MAXCMD) clen = MAXCMD;
        if (have > clen) have = clen;
        memcpy(cmdbuf, buf + boff, (int) have);
        while (have < clen && (n = timed_read(fd, cmdbuf + have, (int)(clen - have))) > 0) {
            have += n;
        }
        do_exec(fd, cmdbuf, have);
        return;
    }
    if (strncmp(path, "/file/", 6) == 0 || strcmp(path, "/file") == 0) {
        const char *fsp = path + 5;          /* keep leading '/' of abs path */
        if (*fsp == '\0') { send_simple(fd, 400, "Bad Request", "no path\n"); return; }
        if (strcmp(method, "GET") == 0) {
            send_file(fd, fsp, 0);
            return;
        }
        if (strcmp(method, "PUT") == 0) {
            do_put(fd, fsp, buf + boff, nread - boff, clen);
            return;
        }
    }
    send_simple(fd, 404, "Not Found", "unknown endpoint\n");
}

int main(argc, argv)
int argc; char **argv;
{
    int sock, client, port, one = 1, f;
    struct sockaddr_in sa;

    if (argc < 2) {
        fprintf(stderr, "usage: auxagent <port> [bind-ip]\n");
        return 1;
    }
    port = atoi(argv[1]);

    /* Close any file descriptors inherited from the launching shell (the GUI
       CommandShell can pass many), keeping only stdin/stdout/stderr. A/UX has a
       low per-process fd limit, and inherited fds would otherwise leave us
       unable to open files after just a few requests. */
    for (f = 3; f < 64; f++)
        (void) close(f);

    signal(SIGPIPE, SIG_IGN);
    /* no SIGALRM handler: avoids EINTR in system()/wait() */
    /* NB: do NOT ignore SIGCHLD -- system()/popen() must be able to wait()
     * for their own children. The agent is sequential and never forks itself,
     * so there are no stray zombies to reap. */

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) { perror("socket"); return 1; }
    (void) setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char *) &one, sizeof one);
    /* don't let exec'd commands inherit the listening socket */
    (void) fcntl(sock, F_SETFD, 1);

    memset((char *) &sa, 0, sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_port = htons((unsigned short) port);
    sa.sin_addr.s_addr = (argc >= 3) ? inet_addr(argv[2]) : INADDR_ANY;

    if (bind(sock, (struct sockaddr *) &sa, sizeof sa) < 0) {
        perror("bind"); return 1;
    }
    if (listen(sock, 8) < 0) { perror("listen"); return 1; }
    fprintf(stderr, "auxagent " AAP_VERSION " listening on port %d\n", port);

    for (;;) {
        client = accept(sock, (struct sockaddr *) 0, (int *) 0);
        if (client < 0)
            continue;
        /* don't let exec'd commands inherit the client socket */
        (void) fcntl(client, F_SETFD, 1);
        handle(client);
        (void) close(client);
        g_client = -1;
    }
}
