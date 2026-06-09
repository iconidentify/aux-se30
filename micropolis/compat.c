/* compat.c - ANSI C functions missing from A/UX 3.1.1 libc. */
#include <stdio.h>

char *strerror(e)
    int e;
{
    extern char *sys_errlist[];
    extern int sys_nerr;
    static char buf[40];
    if (e >= 0 && e < sys_nerr) return sys_errlist[e];
    sprintf(buf, "Error %d", e);
    return buf;
}

unsigned long strtoul(nptr, endptr, base)
    char *nptr; char **endptr; int base;
{
    char *s = nptr;
    unsigned long acc = 0;
    int c, neg = 0, any = 0, d;

    while (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r'
           || *s == '\f' || *s == '\v') s++;
    if (*s == '-') { neg = 1; s++; } else if (*s == '+') s++;
    if ((base == 0 || base == 16) && s[0] == '0'
            && (s[1] == 'x' || s[1] == 'X')) { s += 2; base = 16; }
    if (base == 0) base = (s[0] == '0') ? 8 : 10;

    for (;; s++) {
        c = *s;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'z') d = c - 'a' + 10;
        else if (c >= 'A' && c <= 'Z') d = c - 'A' + 10;
        else break;
        if (d >= base) break;
        acc = acc * base + d;
        any = 1;
    }
    if (endptr) *endptr = (char *)(any ? s : nptr);
    return neg ? -acc : acc;
}

char *strdup(s)
    char *s;
{
    char *p;
    extern char *malloc();
    p = malloc((unsigned)(strlen(s) + 1));
    if (p) strcpy(p, s);
    return p;
}
