# A/UX desktop (fvwm + screensaver + branding)

A small, period-accurate desktop environment for the SE/30 running our X11R6
build, tuned for the machine's **1-bit 512x342 monochrome** display and a
**single-button mouse**.

## Pieces

- **`auxsaver.c`** - a DVD-style bouncing-logo screensaver. Pure Xlib (~130
  lines), built with gcc 2.7.2.3 against our R11R6 shared libraries. Bounces
  `assets/auxlogo.xbm` on a black full-screen window. Idle detection and wake
  are done by **polling the pointer** (no dependence on event delivery or input
  grabs, so it can never get stuck), plus key/button wake. Flicker-free: each
  frame draws the logo at its new position first, then clears only the thin
  strip it vacated.
    - `auxsaver [timeout]` - blank after `timeout` idle seconds (default 120)
    - `auxsaver -test` - bounce immediately, self-exit after ~6s
- **`auxfetch`** - a neofetch-style system summary (Apple logo + A/UX info).
  Bourne sh; works with A/UX's toolset (no `printf(1)`, uses awk + paste).
- **`dot.fvwmrc`** - fvwm 1.24r config: single-button bindings (everything on
  button 1), draggable iconified windows, an Appearance submenu to switch the
  desktop background and new-terminal colors, white-on-black bash terminals.
- **`dot.x11start`** - the X11 session: sets X resources + the desktop
  background, then `exec fvwm` so **fvwm is the session anchor** (closing a
  terminal can't kill the session; "Quit" from the menu logs out).
- **`dot.Xdefaults`** - xterm defaults (white on black, 6x10, login shell).
- **`dot.bashrc`** - interactive bash settings incl. the `\u@\h:\w$` prompt.
- **`gen/genlogo.py`**, **`gen/genbrand.py`** - PIL generators (run on a modern
  host) that emit the XBM assets: the bounce logo and the framed "A/UX" boot-
  style desktop branding. They render the real Apple logo glyph (U+F8FF) from a
  Mac system font, thresholded to crisp 1-bit.
- **`assets/auxlogo.xbm`**, **`assets/auxbrand.xbm`** - the generated bitmaps.

## Install (on the A/UX host)

```
auxsaver           -> /usr/local/bin/auxsaver   (built from auxsaver.c)
auxfetch           -> /usr/local/bin/auxfetch   (symlink neofetch -> auxfetch)
assets/auxlogo.xbm -> /usr/local/auxlogo.xbm
assets/auxbrand.xbm-> /usr/local/auxbrand.xbm
dot.fvwmrc         -> ~/.fvwmrc
dot.x11start       -> ~/.x11start
dot.Xdefaults      -> ~/.Xdefaults
dot.bashrc         -> ~/.bashrc
```

Build `auxsaver` the same way as the R6 xterm (split libX11 import archive):

```
gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -O -c \
    -I/usr/local/X11R6/include auxsaver.c
gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -o auxsaver auxsaver.o mm.o \
    -L<linklib> -lX11a_s -lX11b_s -lX11c_s  (x4 repeated) \
    -lXbsd -lposix -lm -lmr
```

To make it the screensaver, disable XmacII's built-in saver and launch it from
the session: in `.x11start`, before `exec fvwm`, add `xset s off` and
`auxsaver &`.

Prebuilt binaries are in `../dist/fvwm/`.
