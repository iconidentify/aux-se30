/* auxmalloc.c - replacement malloc/free/realloc/calloc for A/UX.

   A/UX's libc malloc corrupts its own arena under the allocation pattern Tk 2.3
   produces on a depth-1 (monochrome StaticGray) display, crashing wish/SimCity
   during main-window creation.  This is the canonical K&R section-8.7 storage
   allocator (circular free list, coalescing on free) backed by sbrk - small,
   proven, and self-contained.  Linked ahead of libc it interposes every
   malloc/free/realloc/calloc in the statically-linked program (Tcl/Tk/sim). */

#include <stdio.h>

extern char *sbrk();

typedef long Align;            /* for alignment to long boundary */

union header {                 /* block header */
    struct {
        union header *ptr;     /* next block if on free list */
        unsigned size;         /* size of this block in header units */
    } s;
    Align x;                   /* force alignment of blocks */
};
typedef union header Header;

static Header base;            /* empty list to get started */
static Header *freep = 0;      /* start of free list */

#define NALLOC 4096            /* min #units to request from sbrk */

void free();

static Header *
morecore(nu)
    unsigned nu;
{
    char *cp;
    Header *up;

    if (nu < NALLOC)
        nu = NALLOC;
    cp = sbrk((int)(nu * sizeof(Header)));
    if (cp == (char *) -1)     /* no space at all */
        return (Header *) 0;
    up = (Header *) cp;
    up->s.size = nu;
    free((char *)(up + 1));
    return freep;
}

char *
malloc(nbytes)
    unsigned nbytes;
{
    Header *p, *prevp;
    unsigned nunits;

    nunits = (nbytes + sizeof(Header) - 1) / sizeof(Header) + 1;
    if ((prevp = freep) == 0) {            /* no free list yet */
        base.s.ptr = freep = prevp = &base;
        base.s.size = 0;
    }
    for (p = prevp->s.ptr; ; prevp = p, p = p->s.ptr) {
        if (p->s.size >= nunits) {         /* big enough */
            if (p->s.size == nunits)       /* exactly */
                prevp->s.ptr = p->s.ptr;
            else {                         /* allocate tail end */
                p->s.size -= nunits;
                p += p->s.size;
                p->s.size = nunits;
            }
            freep = prevp;
            return (char *)(p + 1);
        }
        if (p == freep)                    /* wrapped around free list */
            if ((p = morecore(nunits)) == 0)
                return (char *) 0;         /* none left */
    }
}

void
free(ap)
    char *ap;
{
    Header *bp, *p;

    if (ap == 0)
        return;
    bp = (Header *) ap - 1;                /* point to block header */
    for (p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
        if (p >= p->s.ptr && (bp > p || bp < p->s.ptr))
            break;                         /* freed block at start or end */

    if (bp + bp->s.size == p->s.ptr) {     /* join to upper nbr */
        bp->s.size += p->s.ptr->s.size;
        bp->s.ptr = p->s.ptr->s.ptr;
    } else
        bp->s.ptr = p->s.ptr;
    if (p + p->s.size == bp) {             /* join to lower nbr */
        p->s.size += bp->s.size;
        p->s.ptr = bp->s.ptr;
    } else
        p->s.ptr = bp;
    freep = p;
}

void
cfree(ap)
    char *ap;
{
    free(ap);
}

char *
realloc(ap, nbytes)
    char *ap;
    unsigned nbytes;
{
    Header *bp;
    char *np;
    unsigned oldbytes, copy, i;

    if (ap == 0)
        return malloc(nbytes);
    bp = (Header *) ap - 1;
    oldbytes = (bp->s.size - 1) * sizeof(Header);
    np = malloc(nbytes);
    if (np != 0) {
        copy = (oldbytes < nbytes) ? oldbytes : nbytes;
        for (i = 0; i < copy; i++)
            np[i] = ap[i];
        free(ap);
    }
    return np;
}

char *
calloc(n, size)
    unsigned n, size;
{
    unsigned t = n * size;
    char *p = malloc(t);
    unsigned i;

    if (p != 0)
        for (i = 0; i < t; i++)
            p[i] = 0;
    return p;
}
