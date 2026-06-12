/* aux_mm.c - raw memmove for A/UX links against the R6 X libraries
 * (the import libs reference it; the A/UX libc predates it). */
char *memmove(dst, src, n)
char *dst;
char *src;
unsigned int n;
{
    char *d = dst;
    if (d == src || n == 0) return dst;
    if (d < src) {
        while (n-- > 0) *d++ = *src++;
    } else {
        d += n;
        src += n;
        while (n-- > 0) *--d = *--src;
    }
    return dst;
}
