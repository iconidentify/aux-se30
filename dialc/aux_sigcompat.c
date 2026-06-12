/*
 * aux_sigcompat.c - POSIX signal-set shims missing from the A/UX libc.
 * ncurses references these from its SIGTSTP handling; the A/UX sigset_t
 * is a plain 32-bit mask, so the member operations are one-liners.
 * Build with the dialc objects on A/UX only.
 */

int sigismember(set, signo)
unsigned long *set;
int signo;
{
    return (*set & (1L << (signo - 1))) != 0;
}

int sigaddset(set, signo)
unsigned long *set;
int signo;
{
    *set |= (1L << (signo - 1));
    return 0;
}

int sigdelset(set, signo)
unsigned long *set;
int signo;
{
    *set &= ~(1L << (signo - 1));
    return 0;
}

int sigemptyset(set)
unsigned long *set;
{
    *set = 0;
    return 0;
}

int sigfillset(set)
unsigned long *set;
{
    *set = ~0L;
    return 0;
}
