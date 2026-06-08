/* mm.c - raw memmove for the A/UX X11R6 xterm link.
 *
 * Our R6 client objects reference memmove(), but the A/UX libc and the
 * shared-lib stubs do not provide it.  Supplying this one definition (placed
 * on the link line with the xterm objects) satisfies the reference without
 * pulling in a conflicting libc symbol.
 */
char *memmove(d, s, n)
    char *d; char *s; int n;
{
    char *r = d;
    if (d < s) { while (n-- > 0) *d++ = *s++; }
    else { d = d + n; s = s + n; while (n-- > 0) *--d = *--s; }
    return r;
}
