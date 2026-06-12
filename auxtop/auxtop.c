/* auxtop - a themed, htop-inspired ncurses process monitor for A/UX.
 *
 * Rides on the machine-dependent module from top 3.5 (m_aux3.c, with our
 * fixes + the auxtop_next accessor) for kernel access; this file owns all
 * presentation and formats every field itself - no reliance on top's
 * format_next_process (which left command names unterminated).
 *
 * Themes: key=value file /.auxtoprc or $AUXTOP_THEME. Keys title/text/
 * accent/bar/header/status = the eight ANSI color names. Defaults to the
 * C89 SUMMER synthwave palette.
 *
 * Keys: q quit, space refresh now, i toggle idle processes.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <curses.h>

#include "top.h"
#include "boolean.h"
#include "machine.h"
#include "auxtop_proc.h"

extern int machine_init();
extern int get_system_info();
extern caddr_t get_process_info();
extern int proc_compare();
extern int auxtop_compare_size();
extern void init_hash();
extern char *username();
extern void auxtop_defeat_clear();

#define CP_TITLE   1
#define CP_TEXT    2
#define CP_ACCENT  3
#define CP_BAR     4
#define CP_HEADER  5
#define CP_STATUS  6

static int delay = 5;

struct themeent {
    char *key;
    int pair;
    int defcolor;
};
static struct themeent theme[] = {
    { "title",  CP_TITLE,  COLOR_MAGENTA },
    { "text",   CP_TEXT,   COLOR_WHITE },
    { "accent", CP_ACCENT, COLOR_CYAN },
    { "bar",    CP_BAR,    COLOR_MAGENTA },
    { "header", CP_HEADER, COLOR_MAGENTA },
    { "status", CP_STATUS, COLOR_CYAN },
    { NULL, 0, 0 }
};

static int colorbyname(name)
    char *name;
{
    static struct { char *n; int c; } tab[] = {
        { "black", COLOR_BLACK }, { "red", COLOR_RED },
        { "green", COLOR_GREEN }, { "yellow", COLOR_YELLOW },
        { "blue", COLOR_BLUE }, { "magenta", COLOR_MAGENTA },
        { "cyan", COLOR_CYAN }, { "white", COLOR_WHITE },
        { NULL, -1 }
    };
    int i;
    for (i = 0; tab[i].n != NULL; i++)
        if (strcmp(tab[i].n, name) == 0)
            return tab[i].c;
    return -1;
}

static void load_theme()
{
    FILE *fp;
    char buf[128], *eq, *nl, *path;
    int i, c;

    for (i = 0; theme[i].key != NULL; i++)
        init_pair(theme[i].pair, theme[i].defcolor, COLOR_BLACK);

    path = getenv("AUXTOP_THEME");
    if (path == NULL)
        path = "/.auxtoprc";
    fp = fopen(path, "r");
    if (fp == NULL)
        return;
    while (fgets(buf, sizeof(buf), fp) != NULL) {
        if (buf[0] == '#' || buf[0] == '\n')
            continue;
        eq = strchr(buf, '=');
        if (eq == NULL)
            continue;
        *eq++ = '\0';
        nl = strchr(eq, '\n');
        if (nl != NULL)
            *nl = '\0';
        c = colorbyname(eq);
        if (c < 0)
            continue;
        for (i = 0; theme[i].key != NULL; i++)
            if (strcmp(theme[i].key, buf) == 0)
                init_pair(theme[i].pair, c, COLOR_BLACK);
    }
    fclose(fp);
}

/* a labeled meter:  LBL [|||||||......]  nn%   bounded to `width` cols */
static void draw_meter(y, label, pct, width)
    int y;
    char *label;
    int pct;        /* percent * 10 */
    int width;
{
    int fill, i, barw;

    if (pct > 1000) pct = 1000;
    if (pct < 0) pct = 0;
    barw = width - 12;
    if (barw < 6) barw = 6;
    if (barw > 40) barw = 40;
    fill = (pct * barw) / 1000;
    if (fill > barw) fill = barw;

    move(y, 0);
    clrtoeol();
    attrset(COLOR_PAIR(CP_TEXT) | A_BOLD);
    mvprintw(y, 0, "%-3s", label);
    attrset(COLOR_PAIR(CP_ACCENT));
    addch('[');
    attrset(COLOR_PAIR(CP_BAR) | A_BOLD);
    for (i = 0; i < fill; i++)
        addch('|');
    attrset(COLOR_PAIR(CP_TEXT));
    for (; i < barw; i++)
        addch('.');
    attrset(COLOR_PAIR(CP_ACCENT));
    printw("] %3d%%", pct / 10);
}

/* human-readable KB: 364K, 1.2M, 3.4G */
static char *humanK(k, buf)
    long k;
    char *buf;
{
    if (k < 1000)
        sprintf(buf, "%ldK", k);
    else if (k < 1024L * 1000L)
        sprintf(buf, "%.1fM", (double)k / 1024.0);
    else
        sprintf(buf, "%.1fG", (double)k / (1024.0 * 1024.0));
    return buf;
}

/* one-char process state */
static char statechar(stat)
    int stat;
{
    switch (stat) {
        case 1: return 'S';     /* sleep */
        case 2: return 'R';     /* run   */
        case 3: return 'Z';     /* zombie */
        case 4: return 'T';     /* stop  */
        case 5: return 'R';     /* start */
        case 6: return 'R';     /* on cpu */
        case 7: return 'W';     /* swap  */
        default: return '?';
    }
}

/* A/UX ps(1) gives correct command names for every process, including
 * ones whose u-area is swapped out (which the kernel read returns empty
 * or garbage for). Cache pid->name from `ps -e`, refreshed periodically. */
#define MAXPS 1024
static struct { long pid; char name[16]; } pscache[MAXPS];
static int npscache = 0;

static int name_clean(s)
    char *s;
{
    int n = 0;
    if (s == NULL || s[0] == '\0')
        return 0;
    for (; *s != '\0'; s++, n++) {
        unsigned char c = (unsigned char)*s;
        if (c < 32 || c >= 127)
            return 0;
    }
    return n > 0;
}

static void load_pscache()
{
    FILE *fp;
    char line[256], tty[64], tm[64], cmd[64];
    long pid;

    npscache = 0;
    fp = popen("/bin/ps -e 2>/dev/null", "r");
    if (fp == NULL)
        return;
    (void)fgets(line, sizeof(line), fp);            /* header */
    while (npscache < MAXPS && fgets(line, sizeof(line), fp) != NULL) {
        if (sscanf(line, "%ld %63s %63s %63s", &pid, tty, tm, cmd) == 4) {
            pscache[npscache].pid = pid;
            strncpy(pscache[npscache].name, cmd, sizeof(pscache[0].name) - 1);
            pscache[npscache].name[sizeof(pscache[0].name) - 1] = '\0';
            npscache++;
        }
    }
    pclose(fp);
}

static char *pslookup(pid)
    long pid;
{
    int i;
    for (i = 0; i < npscache; i++)
        if (pscache[i].pid == pid)
            return pscache[i].name;
    return NULL;
}

/* A/UX's ncurses doesn't catch SIGWINCH itself, so resizing the xterm
 * desyncs ncurses from the terminal and refresh() scatters the changed
 * rows. Catch it, query the new size, and tell ncurses via resizeterm. */
static volatile int got_winch = 0;

static void on_winch(sig)
    int sig;
{
    got_winch = 1;
    signal(SIGWINCH, on_winch);
}

void quit(status)
    int status;
{
    endwin();
    exit(status);
}

int main(argc, argv)
    int argc;
    char **argv;
{
    struct statics st;
    struct system_info si;
    struct process_select ps;
    struct auxtop_proc p;
    time_t now;
    char szbuf[16], tbuf[16], *uname;
    int i, y, x, rows, cols, ch, nproc, running;
    int idle_idx, cpu_busy, frame = 0;
    int show_idle = 1;
    long memused, memtot, swapused, swaptot;

    if (machine_init(&st) != 0) {
        fprintf(stderr, "auxtop: machine_init failed (need /dev/kmem)\n");
        return 1;
    }
    init_hash();
    load_pscache();

    /* which cpustate is "idle"? (A/UX order is idle,user,kernel,wait,nice
       - NOT last, so we must look it up by name) */
    idle_idx = 0;
    for (i = 0; st.cpustate_names[i] != NULL; i++)
        if (strcmp(st.cpustate_names[i], "idle") == 0)
            idle_idx = i;

    initscr();
    if (has_colors()) {
        start_color();
        load_theme();
    }
    /* force space-based clearing (R6 xterm's clear sequences are broken) */
    auxtop_defeat_clear();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    scrollok(stdscr, FALSE);
    nodelay(stdscr, FALSE);
    signal(SIGWINCH, on_winch);
    timeout(delay * 1000);
    curs_set(0);

    ps.system = 1;
    ps.uid = -1;
    ps.command = NULL;

    for (;;) {
        if (got_winch) {
            struct winsize ws;
            got_winch = 0;
            if (ioctl(1, TIOCGWINSZ, &ws) == 0 && ws.ws_row > 0)
                resizeterm((int)ws.ws_row, (int)ws.ws_col);
            clear();
        }
        getmaxyx(stdscr, rows, cols);
        if (cols > 200) cols = 200;
        if ((frame++ % 6) == 0)
            load_pscache();
        get_system_info(&si);
        ps.idle = show_idle;
        (void)get_process_info(&si, &ps, auxtop_compare_size);
        nproc = si.P_ACTIVE;

        running = si.procstates ? si.procstates[2] : 0;
        cpu_busy = 1000 - si.cpustates[idle_idx];
        memused = si.memory[0];
        memtot  = si.memory[0] + si.memory[1];
        if (memtot < 1) memtot = 1;
        swapused = si.memory[3];
        swaptot  = si.memory[3] + si.memory[4];
        if (swaptot < 1) swaptot = 1;

        time(&now);
        erase();    /* logical blank; refresh diffs -> only changed cells redraw (no flash) */

        /* ---- title bar ---- */
        attrset(COLOR_PAIR(CP_TITLE) | A_BOLD);
        mvaddstr(0, 0, " auxtop ");
        attrset(COLOR_PAIR(CP_TEXT));
        addstr(" A/UX process monitor");
        attrset(COLOR_PAIR(CP_ACCENT) | A_BOLD);
        mvprintw(0, cols - 9, "%.8s", ctime(&now) + 11);

        /* ---- meters + summary (htop-style top block) ---- */
        draw_meter(1, "CPU", cpu_busy, cols / 2);
        draw_meter(2, "Mem", (int)((memused * 1000) / memtot), cols / 2);
        draw_meter(3, "Swp", (int)((swapused * 1000) / swaptot), cols / 2);

        attrset(COLOR_PAIR(CP_TEXT));
        mvprintw(1, cols / 2 + 2, "tasks ");
        attrset(COLOR_PAIR(CP_ACCENT) | A_BOLD);
        printw("%d", si.p_total);
        attrset(COLOR_PAIR(CP_TEXT));
        printw("  running ");
        attrset(COLOR_PAIR(CP_ACCENT) | A_BOLD);
        printw("%d", running);

        attrset(COLOR_PAIR(CP_TEXT));
        mvprintw(2, cols / 2 + 2, "load  ");
        attrset(COLOR_PAIR(CP_ACCENT) | A_BOLD);
        printw("%.2f %.2f %.2f", si.load_avg[0], si.load_avg[1],
            si.load_avg[2]);

        attrset(COLOR_PAIR(CP_TEXT));
        mvprintw(3, cols / 2 + 2, "mem   ");
        attrset(COLOR_PAIR(CP_ACCENT) | A_BOLD);
        printw("%ldK used  %ldK free", memused, si.memory[1]);

        /* ---- process table header ---- */
        attrset(COLOR_PAIR(CP_HEADER) | A_REVERSE | A_BOLD);
        mvprintw(5, 0, "%-*.*s", cols, cols,
            "   PID USER       PRI  NI   SIZE S   CPU%   TIME  COMMAND");

        /* ---- process rows ---- */
        y = 6;
        for (i = 0; i < nproc && y < rows - 1; i++) {
            if (!auxtop_next(&p))
                break;
            uname = username((int)p.uid);
            humanK(p.size, szbuf);
            sprintf(tbuf, "%ld:%02ld", p.secs / 60, p.secs % 60);

            move(y, 0);
            clrtoeol();
            /* meta columns in calm cyan (fixed 48-col width) */
            attrset(COLOR_PAIR(CP_ACCENT));
            mvprintw(y, 0, "%6ld %-9.9s %3d %3d %6s %c %5.1f %6s",
                p.pid, uname, p.pri, p.nice, szbuf,
                statechar(p.stat), (double)p.cpu, tbuf);
            /* pick the command name: real-time u-area name if it's
             * clean, else the ps(1) fallback; draw at a FIXED column +
             * explicit row (no getyx), bold white so it reads */
            {
                char *cmd = p.name;
                if (!name_clean(cmd)) {
                    char *q = pslookup(p.pid);
                    cmd = (q != NULL && name_clean(q)) ? q : "";
                }
                if (cmd[0] != '\0') {
                    char nm[64];
                    int j, max = cols - 50;
                    if (max > (int)sizeof(nm) - 1)
                        max = sizeof(nm) - 1;
                    for (j = 0; j < max && cmd[j] != '\0'; j++)
                        nm[j] = cmd[j];
                    nm[j] = '\0';
                    attrset(COLOR_PAIR(CP_TEXT) | A_BOLD);
                    mvaddstr(y, 49, nm);
                }
            }
            y++;
        }
        /* wipe any rows left from a previous (taller) frame */
        attrset(COLOR_PAIR(CP_TEXT));
        move(y, 0);
        clrtobot();

        /* ---- status bar ---- */
        attrset(COLOR_PAIR(CP_STATUS) | A_REVERSE | A_BOLD);
        mvprintw(rows - 1, 0,
            " q quit   space refresh   i idle procs %s %*s",
            show_idle ? "(on) " : "(off)", cols - 46, "auxtop");

        refresh();

        ch = getch();
        if (ch == 'q' || ch == 'Q')
            break;
        if (ch == 'i' || ch == 'I')
            show_idle = !show_idle;

    }

    endwin();
    return 0;
}
