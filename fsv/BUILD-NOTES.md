# fsv on A/UX 3.1.1 - the Jurassic Park 3D file manager

fsv 0.9 (the open-source clone of SGI's fsn, the "It's a Unix system!"
file manager from Jurassic Park) built and running on the QEMU q800 A/UX
guest: TreeV mode, Mesa software GL on XmacII at depth 8.

This required building an entire 1999 GNOME-era stack from source with
gcc 2.7.2.3, then patching fsv itself for XmacII.

## The dependency stack (all static, all from source, into /usr/local/fd)

    glib 1.2.10 -> GTK+ 1.2.10 -> Mesa 3.0 -> gtkglarea 1.2.3 -> fsv 0.9

Mesa provides software GL + `fakeglx` (client-side GLX - XmacII has no GLX
extension). Build scripts in `scripts/`. Sources from gnome.org archives,
mesa3d.org older-versions, Debian archive (gtkglarea).

## libacomp (auxcompat.c) - the missing-libc lib

A/UX 3.1.1 libc lacks a pile of ANSI/POSIX functions the stack needs.
`auxcompat.c` -> `libacomp.a` supplies: strerror, strcasecmp, strncasecmp,
strdup, getpagesize, memmove, setlocale, localeconv, fnmatch, snprintf,
vsnprintf, cbrt, strtok_r, atexit. ONE OBJECT PER FUNCTION (else dup-symbol
collisions with GTK's bundled copies). memmove/setlocale must be ANSI-style
(A/UX headers declare prototypes; libc just lacks the symbols).

Link the short name `-lacomp`: A/UX native ld can't find lib stems longer
than ~8 chars via `-l` (so `libauxcompat.a` is unfindable, `libacomp.a` works).

## Stack build gotchas

- A/UX `ar` truncates member names to 14 chars (delete by truncated name).
- A/UX `sed` has no `\n` in replacements (use awk to insert lines).
- A/UX `grep` has no `\|` alternation (separate greps).
- Single-pass ld: merge `/lib/libm.a` INTO libMesaGL.a; repeat
  `-lacomp -lXext -lX11 -lacomp` at the end of every link.
- Mesa 3.0 has no autoconf: append an `aux` target to Make-config; SVR2
  make can't suffix-rule subdir objects (X/*.o) - hand-compile them.
- THE STALE-OBJECT GREMLIN: the guest RTC jumps backward across QEMU
  restarts (sometimes an hour, mid-build) -> make silently reuses stale
  .o. `strings`/`grep` on COFF binaries are unreliable. Only cure: rm all
  .o, explicit per-file compile, explicit link, verify by binary size.
- SVR2 ETXTBSY: A/UX cannot unlink/overwrite a RUNNING executable - kill
  the process BEFORE relinking.

## fsv patches (patched-src/, drop-in over fsv-0.9/src/)

1. `fsv.c`: init `globals.fsv_mode = FSV_NONE` early. Uninitialized it's 0
   == FSV_DISCV (a half-built mode), and XmacII delivers exposes during
   gtk_widget_show BEFORE fsv_load - drawing the null tree crashes. THE
   crash that blocked first launch.
2. `gui.c`/`window.c`/`dirtree.c`/`filelist.c`: gdk_pixmap_create_from_xpm_d
   CRASHES against XmacII (depth-1 mask path, like the SimCity mono crash).
   Toolbar/window icons -> text labels ("<", "/", "..", "Eye"); tree/list
   icon tables -> NULL + gtk_clist_set_text instead of set_pixtext.
3. `ogl.c`: glClearColor(0.72,0.72,0.78) - fsn movie-gray sky (and black
   renders HOT PINK on the starved 8-bit shared colormap); guard
   gtk_gl_area_make_current failure.
4. `viewport.c`: viewport_cb returns early while fsv_mode == FSV_NONE.
5. `window.c`: XStoreName "3D File Navigator" via raw Xlib after realize
   (gdk titles go through XmbSetWMProperties which fails with our setlocale
   stub -> "Untitled"). Labeled toolbar buttons.
6. `callbacks.c`/`window.c`: File->Exit and window-close do `_exit()` -
   GTK/GL teardown crashes XmacII (server reclaims everything on disconnect).
7. `dialog.c`: "Open" context-menu action + double-click on a file opens it
   in vim (one-button-mouse friendly), in a 110x45 synthwave xterm with
   HOME=/ and VIMRUNTIME set so the user's .vimrc + syntax colors load.

## Runtime

- Installed at /usr/local/fsv/fsv; launcher /usr/local/bin/fsv3d (fvwm
  menu "fsv 3D"). Run: `DISPLAY=:0 fsv3d [dir]`.
- COLORMAP: Mesa's ~225-cell RGB cube vs SimCity's Tk icons fight over the
  256 shared cells. fsv3d can export MESA_PRIVATE_CMAP=1 (private cube;
  desktop swaps only while the GL view holds focus) for coexistence, but
  shared+dithered is fine alone.
- Kill fsv with the window manager, not `kill` - killing one holding a GL
  context tends to take XmacII down (autologin respawns it).

## bgroot.c - bonus

A leak-free root-background setter (the old xpmroot leaked colormap cells
every swap -> XpmError -4). Implements _XSETROOT_ID kill-predecessor +
XpmCloseness 65535. Built against the micropolis libXpm with the split-X11
link recipe. Used by the fvwm "BG:" menu entries for the AI wallpapers.
