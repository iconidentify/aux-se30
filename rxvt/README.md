# rxvt 2.6.4 for A/UX

A working rxvt (VT102 + 8-color ANSI terminal) for A/UX 3.1.1, built with
gcc 2.7.2.3 against the se30 X11R6 client libraries. Replaces the 1994
R6 xterm whose escape-sequence handling corrupts ncurses output (see
auxtop/auxterm.c and the dialc compat notes for the gory details).

Installed on the QEMU guest at /usr/local/bin/rxvt (setuid root for
ptys, like xterm-r6). Sets TERM=rxvt (entry present in the ncurses 5.7
terminfo db), COLORTERM=rxvt, 8 colors.

## Source changes vs pristine rxvt 2.6.4

1. src/command.c: guard IEXTEN (A/UX termios lacks it) and _SC_OPEN_MAX
   (A/UX sysconf lacks it; falls back to getdtablesize). See
   command.c.patched.
2. src/rxvt.h: TERMENV "xterm" -> "rxvt" so the honest terminfo entry
   is used. See rxvt.h.patched.
3. aux_strdup.c, aux_mm.c (this dir): strdup and memmove shims - the
   A/UX libc predates both (memmove is referenced by the R6 libX11
   import libs).

## Build recipe (on the guest, /usr/local/src/rxvt)

    CC="/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/" \
    CONFIG_SHELL=/bin/bash /bin/bash ./configure --prefix=/usr/local \
      --x-includes=/usr/local/xcb/xc --x-libraries=/usr/local/r6lib

    make            # objects compile; the stock link fails (-lX11)

Hand link with the split libX11 import archives (the Part 10 trick from
X11R6-BUILD-NOTES.md - native ld, pieces repeated for single-pass
cross-refs), NO fixups.o (native ld resolves _X11ptr_* from the import
libs themselves; GNU-ld-flow fixups.o collides):

    gcc -B/usr/local/gcc-2.7.2.3/ -O -o rxvt \
      command.o graphics.o grkelot.o logging.o main.o menubar.o misc.o \
      netdisp.o rmemset.o screen.o scrollbar.o xdefaults.o xpm.o \
      aux_strdup.o aux_mm.o \
      -L/usr/local/r6lib \
      -lX11a_s -lX11b_s -lX11c_s -lX11a_s -lX11b_s -lX11c_s \
      -lX11a_s -lX11b_s -lX11c_s -lX11a_s -lX11b_s -lX11c_s \
      -lXbsd -lposix -lm -ltermcap

    cp rxvt /usr/local/bin/rxvt && chmod 4755 /usr/local/bin/rxvt

Import libs on the guest at /usr/local/r6lib (uploaded from
dist/x11split + dist/import).

Binary backed up here as rxvt-aux-binary.
