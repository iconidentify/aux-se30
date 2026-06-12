# dialc on A/UX

dialc is the Dialtone AOL client in portable C89 - chat, instant
messages, news reader, multi-window ncurses UI. Canonical source:
https://github.com/iconidentify/dialc (MIT). This directory holds the
A/UX deployment notes, the A/UX compat shims, and a binary backup.

Installed on the QEMU guest at /usr/local/bin/dialc; sources at
/usr/local/src/dialc. Launch from the fvwm Main menu ("dialtone", via
/usr/local/bin/dialc-x in a synthwave rxvt) or run dialc from any
terminal. Connects to production dialtone.live:5190; any name and
password signs on as an ephemeral guest.

## Build recipe (on the guest)

    cd /usr/local/src/dialc
    /usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -O -Iinclude \
      -I/usr/local/ncurses-5.7/include \
      -I/usr/local/ncurses-5.7/include/ncurses \
      -o dialc src/dialtone_client.c src/p3.c src/fdo.c src/ui.c \
      compat/aux_sigcompat.c compat/aux_termfix.c \
      -L/usr/local/ncurses-5.7/lib -lncurses \
      -L/usr/local/fd/lib -lacomp
    mv /usr/local/bin/dialc /tmp/old; cp dialc /usr/local/bin/dialc
    chmod 755 /usr/local/bin/dialc; rm /tmp/old; sync

(mv-then-cp because A/UX refuses to overwrite or unlink a running
"busy text" binary; sync because a guest crash reverts unsynced
writes.)

## A/UX compat shims (copies here; canonical in the dialc repo)

- aux_sigcompat.c - POSIX signal-set functions (sigismember and
  friends) that ncurses references but the A/UX libc lacks.
- aux_termfix.c - two fixes in one: (1) disables tty output
  post-processing (the A/UX driver rewrites the ^J cursor-down motion
  into CR+LF and expands ^I to spaces, scrambling ncurses' cursor
  tracking - this is needed under ANY terminal emulator); (2) under
  the 1994 R6 xterm only, NULLs the terminfo capabilities that xterm
  implements incorrectly (clears, scroll regions, single-axis
  addressing, insert/delete) so ncurses falls back to absolute cursor
  addressing and literal spaces. Skipped when TERM=rxvt - the rxvt
  port (../rxvt/) implements its capabilities correctly.

## Portability notes (C89 / gcc 2.7.2.3)

- No stdint.h: p3.h typedefs uint8_t/uint16_t when __GNUC__ < 3.
- No sys/select.h: guarded; sys/time.h + sys/types.h provide select.
- gcc 2.7 rejects declarations after statements (clang only warns
  with -Wdeclaration-after-statement; worth running before deploys).
- The wire codec (fdo.c, from atomforge-fdo-c) is endian-clean -
  big-endian 68k verified live against production.
