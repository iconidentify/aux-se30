# auxdock - drag-to-snap icon dock for fvwm 1.x on A/UX

The keeper icon-arranging solution (supersedes the retired `fvwm-patch/`
ArrangeIcons menu builtin). Instead of a menu command that packs icons,
auxdock is a live, innovative drag-to-snap dock: drag a desktop icon up
into the snap zone at the top of the screen and a bright slot illuminates
at the nearest grid column showing where it will land; release and the
icon - with its label - snaps into that slot, tight like a taskbar.

## Why this over the fvwm source patch

- No fvwm rebuild/patch to maintain (the ArrangeIcons patch replaced the
  fvwm 1.24r binary; a stock fvwm + this daemon is cleaner and safer).
- Interactive and discoverable: the slot only appears while you drag.
- Pure Xlib, runs as an ordinary background process.

## How it works

A background daemon selects `SubstructureNotifyMask` on the root window.
fvwm 1.x icons are two root windows (a taller pixmap + a label below it);
with `OpaqueMove 100` set, dragging streams `ConfigureNotify` events. When
an icon-sized window enters the top snap zone, auxdock maps a magenta/cyan
override-redirect highlight at the snapped grid column. When the drag
stops (no events for ~200ms), it moves the pixmap and its label onto the
grid and hides the highlight.

Tunables are one-line constants at the top of auxdock.c: ZONE_TOP/BOT,
SLOTY, SLOTW (column pitch), LEFTM, highlight size, SNAP_MS.

## Build (on the guest, against the split-X11R6 import archive)

    gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -O \
        -I/usr/local/X11R6/include -o auxdock auxdock.c \
        -L/tmp/linklib -lXext_s -lX11a_s -lX11b_s -lX11c_s (x4) \
        -lXbsd -lposix -lm -lmr -L/usr/local/fd/lib -lacomp

## Run

Needs `OpaqueMove 100` in .fvwmrc (so drags stream live). Start at login
from .x11start:  `/usr/local/bin/auxdock &`
