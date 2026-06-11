/* compat.c - ANSI/BSD functions missing from A/UX 3.1.1 libc.
   (Same approach as the Micropolis port's compat.c.) */
#include <stdio.h>
#include <string.h>

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

static int lc(c)
    int c;
{
    if (c >= 'A' && c <= 'Z') return c - 'A' + 'a';
    return c;
}

int strcasecmp(a, b)
    char *a; char *b;
{
    int ca, cb;
    for (;;) {
        ca = lc(*(unsigned char *)a);
        cb = lc(*(unsigned char *)b);
        if (ca != cb) return ca - cb;
        if (!ca) return 0;
        a++; b++;
    }
}

int strncasecmp(a, b, n)
    char *a; char *b; int n;
{
    int ca, cb;
    while (n-- > 0) {
        ca = lc(*(unsigned char *)a);
        cb = lc(*(unsigned char *)b);
        if (ca != cb) return ca - cb;
        if (!ca) return 0;
        a++; b++;
    }
    return 0;
}

int getpagesize()
{
    return 4096;
}

void *memmove(void *dst, const void *src, size_t n)
{
    char *d = (char *)dst;
    const char *s = (const char *)src;
    if (d == s || n == 0) return dst;
    if (d < s) {
        while (n--) *d++ = *s++;
    } else {
        d += n; s += n;
        while (n--) *--d = *--s;
    }
    return dst;
}
