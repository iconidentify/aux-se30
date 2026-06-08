/*
 * aap.c - A/UX Agent Protocol pure helpers. See aap.h.
 * Portable C89: no dynamic allocation, no platform headers.
 */
#include "aap.h"

static int aap_lc(int c)
{
    if (c >= 'A' && c <= 'Z')
        return c - 'A' + 'a';
    return c;
}

int aap_parse_reqline(const char *line, char *method, int msz,
                      char *path, int psz)
{
    int i;
    const char *p = line;

    if (line == 0 || method == 0 || path == 0 || msz <= 0 || psz <= 0)
        return 0;

    /* method = up to first space */
    i = 0;
    while (*p && *p != ' ' && *p != '\r' && *p != '\n') {
        if (i < msz - 1)
            method[i++] = *p;
        p++;
    }
    method[i] = '\0';
    if (i == 0 || *p != ' ')
        return 0;
    while (*p == ' ')
        p++;

    /* path = up to next space */
    i = 0;
    while (*p && *p != ' ' && *p != '\r' && *p != '\n') {
        if (i < psz - 1)
            path[i++] = *p;
        p++;
    }
    path[i] = '\0';
    if (i == 0)
        return 0;
    return 1;
}

/* Compare header name at <line> (up to ':') with <name>, case-insensitive. */
static int aap_name_match(const char *line, const char *name)
{
    while (*name) {
        if (*line == ':' || *line == '\0')
            return 0;
        if (aap_lc((unsigned char) *line) != aap_lc((unsigned char) *name))
            return 0;
        line++;
        name++;
    }
    return (*line == ':');
}

int aap_header_str(const char *headers, const char *name, char *out, int osz)
{
    const char *p = headers;

    if (headers == 0 || name == 0 || out == 0 || osz <= 0)
        return 0;
    out[0] = '\0';

    while (*p) {
        if (aap_name_match(p, name)) {
            int i = 0;
            /* advance past "name:" */
            while (*p && *p != ':')
                p++;
            if (*p == ':')
                p++;
            while (*p == ' ' || *p == '\t')
                p++;
            while (*p && *p != '\r' && *p != '\n') {
                if (i < osz - 1)
                    out[i++] = *p;
                p++;
            }
            /* trim trailing whitespace */
            while (i > 0 && (out[i - 1] == ' ' || out[i - 1] == '\t'))
                i--;
            out[i] = '\0';
            return 1;
        }
        /* skip to next line */
        while (*p && *p != '\n')
            p++;
        if (*p == '\n')
            p++;
    }
    return 0;
}

long aap_header_long(const char *headers, const char *name, long dflt)
{
    char buf[32];
    long v;
    int i, any;
    int neg = 0;

    if (!aap_header_str(headers, name, buf, (int) sizeof(buf)))
        return dflt;
    i = 0;
    if (buf[0] == '-') { neg = 1; i = 1; }
    v = 0;
    any = 0;
    for (; buf[i]; i++) {
        if (buf[i] < '0' || buf[i] > '9')
            return dflt;
        v = v * 10 + (buf[i] - '0');
        any = 1;
    }
    if (!any)
        return dflt;
    return neg ? -v : v;
}

static int aap_hex(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

int aap_url_decode(const char *in, char *out, int osz)
{
    int o = 0;

    if (in == 0 || out == 0 || osz <= 0)
        return 0;
    while (*in && o < osz - 1) {
        if (*in == '%' && in[1] && in[2]) {
            int hi = aap_hex((unsigned char) in[1]);
            int lo = aap_hex((unsigned char) in[2]);
            if (hi >= 0 && lo >= 0) {
                out[o++] = (char) (hi * 16 + lo);
                in += 3;
                continue;
            }
        }
        if (*in == '+')
            out[o++] = ' ';
        else
            out[o++] = *in;
        in++;
    }
    out[o] = '\0';
    return o;
}

int aap_header_end(const char *buf, int len)
{
    int i;

    if (buf == 0)
        return -1;
    for (i = 0; i < len; i++) {
        if (buf[i] == '\n') {
            if (i + 1 < len && buf[i + 1] == '\n')
                return i + 2;
            if (i + 2 < len && buf[i + 1] == '\r' && buf[i + 2] == '\n')
                return i + 3;
        }
    }
    return -1;
}

unsigned long aap_crc32(const unsigned char *data, long len)
{
    unsigned long crc = 0xFFFFFFFFUL;
    long n;
    int k;

    for (n = 0; n < len; n++) {
        crc ^= (unsigned long) data[n];
        for (k = 0; k < 8; k++) {
            if (crc & 1UL)
                crc = (crc >> 1) ^ 0xEDB88320UL;
            else
                crc = crc >> 1;
        }
    }
    return (crc ^ 0xFFFFFFFFUL) & 0xFFFFFFFFUL;
}
