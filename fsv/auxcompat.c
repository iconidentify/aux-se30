/* auxcompat.c - ANSI/BSD functions missing from A/UX 3.1.1 libc,
   packaged as libauxcompat.a for the fsv/GTK/Mesa stack.
   (Union of the Quake compat.c + setlocale; memmove/setlocale must be
   ANSI-style: A/UX headers declare prototypes, libc lacks symbols.) */
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

static int lc_(c)
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
        ca = lc_(*(unsigned char *)a);
        cb = lc_(*(unsigned char *)b);
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
        ca = lc_(*(unsigned char *)a);
        cb = lc_(*(unsigned char *)b);
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

char *strdup(s)
    char *s;
{
    char *p;
    extern char *malloc();
    p = malloc((unsigned)(strlen(s) + 1));
    if (p) strcpy(p, s);
    return p;
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

char *setlocale(int category, const char *locale)
{
    static char c_locale[] = "C";
    return c_locale;
}

#include <locale.h>
struct lconv *localeconv(void)
{
    static char dot[] = ".";
    static char empty[] = "";
    static struct lconv l;
    l.decimal_point = dot;
    l.thousands_sep = empty;
    l.grouping = empty;
    l.int_curr_symbol = empty;
    l.currency_symbol = empty;
    l.mon_decimal_point = empty;
    l.mon_thousands_sep = empty;
    l.mon_grouping = empty;
    l.positive_sign = empty;
    l.negative_sign = empty;
    l.int_frac_digits = 127;
    l.frac_digits = 127;
    l.p_cs_precedes = 127;
    l.p_sep_by_space = 127;
    l.n_cs_precedes = 127;
    l.n_sep_by_space = 127;
    l.p_sign_posn = 127;
    l.n_sign_posn = 127;
    return &l;
}

/* minimal fnmatch: *, ?, [ranges] with ! or ^ negation; flags ignored
   (fsv only uses plain wildcard matching for color rules) */
int fnmatch(const char *p, const char *s, int flags)
{
    while (*p) {
        if (*p == '*') {
            p++;
            if (!*p) return 0;
            for (; *s; s++)
                if (fnmatch(p, s, flags) == 0) return 0;
            return fnmatch(p, s, flags);
        } else if (*p == '?') {
            if (!*s) return 1;
            p++; s++;
        } else if (*p == '[') {
            const char *q = p + 1;
            int neg = 0, hit = 0;
            if (*q == '!' || *q == '^') { neg = 1; q++; }
            if (!*s) return 1;
            while (*q && *q != ']') {
                if (q[1] == '-' && q[2] && q[2] != ']') {
                    if (*s >= q[0] && *s <= q[2]) hit = 1;
                    q += 3;
                } else {
                    if (*s == *q) hit = 1;
                    q++;
                }
            }
            if (!*q) return 1;
            if (hit == neg) return 1;
            p = q + 1; s++;
        } else {
            if (*p != *s) return 1;
            p++; s++;
        }
    }
    if (*s) return 1;
    return 0;
}

/* bounded printf via vsprintf into a big scratch buffer (A/UX libc has
   no [v]snprintf). Not reentrant; fine for single-threaded 90s apps. */
#include <stdarg.h>

int vsnprintf(char *str, size_t n, const char *fmt, va_list ap)
{
    static char vsnbuf[16384];
    int len;
    len = vsprintf(vsnbuf, fmt, ap);
    if (n > 0) {
        strncpy(str, vsnbuf, n - 1);
        str[n - 1] = '\0';
    }
    return len;
}

int snprintf(char *str, size_t n, const char *fmt, ...)
{
    va_list ap;
    int len;
    va_start(ap, fmt);
    len = vsnprintf(str, n, fmt, ap);
    va_end(ap);
    return len;
}
