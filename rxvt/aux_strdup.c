/* aux_strdup.c - strdup for the A/UX libc, which predates it. */
#include <stdlib.h>
#include <string.h>

char *strdup(s)
const char *s;
{
    char *d = (char *) malloc(strlen(s) + 1);
    if (d) strcpy(d, s);
    return d;
}
