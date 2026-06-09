# Micropolis (SimCity) on A/UX 3.1.1 / SE/30 - build notes

Porting the tenox7 Micropolis Legacy (DUX SimCity for Unix, ~1997) to A/UX
3.1.1 on the SE/30, against our X11R6 build. Bundled stack: **Tcl 6.4, Tk 2.3,
TclX 6.4c, Xpm 3.x**, plus the C **sim** engine. Built on the QEMU A/UX guest
with gcc 2.7.2.3; links against our X11R6 shared libs (split libX11 import
archive - see ../X11R6-BUILD-NOTES.md).

Build order: **Xpm -> Tcl -> Tk -> TclX -> sim**.

## Common A/UX retargeting (all makefiles)
- `CC = /usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return`
  (trailing slash on -B is mandatory; else native /bin/as rejects the output)
- `-O3` -> `-O` (gcc 2.7.2.3)
- A/UX has no `ranlib`: replace `ranlib LIB.a` with `ar ts LIB.a` (native ar).

## Tcl 6.4  (src/tcl)  -> libtcl.a  [DONE, runs]
- DROP `-DIS_LINUX` (Tcl's IS_LINUX assumes Linux libc/types; A/UX differs).
- `tclenv.c`: the code body uses 3-arg `int setenv` / `int unsetenv` (the BSD
  signature A/UX actually has), but the non-Linux branch declared 2-arg/void.
  Fix: `sed 's/^#ifdef IS_LINUX/#if 1/' tclenv.c` (force the 3-arg path).
- `tclunix.h`: set `#define TCL_UNION_WAIT 1` (A/UX's WIFEXITED macros use
  `union wait`, not int).  Keep TCL_PID_T=0 (A/UX has no pid_t typedef).
- `compat.c` (this dir): A/UX libc lacks ANSI `strtoul` and `strerror`; compile
  and fold into libtcl.a (`COMPAT_OBJS = compat.o`).

## Xpm 3.x  (src/xpm)  -> libXpm.a  [DONE]
- Needs `strdup` at link (A/UX libc lacks it) -> added to compat.c.
- Use `Makefile.noX` (plain makefile; despite the name it uses real Xlib - the
  stub `simx` is only under `FOR_MSW`).
- Strip stale deps referencing the renamed header: `grep -v xpmP.h Makefile.noX`.
- Add X includes: `CFLAGS='-O -DZPIPE -I. -I/usr/local/X11R6/include'`.
- `ar ts` for the index.
- May need `strdup`/`strcasecmp` at link time (add to compat.c if undefined).

## Tk 2.3  (src/tk)  -> libtk.a  [DONE]
- KEEP `-DIS_LINUX` here. In Tk this fork's IS_LINUX selects **R6-safe APIs**
  (e.g. `XDisplayKeycodes` vs `dpy->min_keycode`); X11R6 made Display opaque, so
  the R6 path is required. (Opposite of Tcl, where IS_LINUX meant Linux libc.)
- `XINCLUDE = /usr/local/X11R6/include` (dir containing X11/, so <X11/Xlib.h>).
- `tkwm.c`: delete the tenox `wm fullscreen` EWMH block (`_NET_WM_STATE` atoms
  postdate R6, and it has C89-illegal mid-block `static` decls). Micropolis
  doesn't use it:  `sed '/static Atom _NET_WM_STATE;/,/SubstructureNotifyMask/d'`.
- `ar ts` for the index.

## Linking a Tk program (wish / the sim) against our X11R6
Native ld + split libX11 import archive (single-pass, repeat the 3 pieces x4):

    gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -o PROG \
      PROG.o mm.o  <libtk.a libtcl.a libXpm.a> \
      -L/tmp/linklib \
      -lXext_s -lX11a_s -lX11b_s -lX11c_s  (x4 repeated) \
      -lXbsd -lposix -lm -lmr

(`mm.o` = raw memmove; `compat.o` strtoul/strerror is inside libtcl.a.)

## wish (Tk shell)  [DONE - validates the stack]
Linked 597KB, loads all shlibs + runs Tk init on A/UX over our X11R6.

## TclX 6.4c  (src/tclx)  -> extended libtcl.a  [DONE]
- It ships a `config/aux` (A/UX) target. In `config.mk` set:
  `TCL_CONFIG_FILE=aux`, `CC=<our gcc -B...>`, `OPTIMIZE_FLAG=-O` (NO -DIS_LINUX
  on the Tcl side - here IS_LINUX would mean Linux libc, and config/aux already
  handles A/UX: -DTCL_USE_BZERO_MACRO -DTCL_SIG_PROC_INT, RANLIB_CMD=true).
- `make TCLX_MAKES` copies ../tcl/libtcl.a then ar's the TclX command objects
  (src/ ucbsrc/ ossupp/) into it -> extended libtcl.a with the symbol the sim
  needs: `Tcl_CreateExtendedInterp`. It also links a standalone `tcl` shell.
- `ar ts libtcl.a` afterwards (RANLIB_CMD=true is a no-op).
- The sim uses standard Tk (Tk_CreateMainWindow), not TclX's Tk extensions, so
  skip tksrc/tkucbsrc: just `cp ../tk/libtk.a libtk.a; ar ts libtk.a`.

## sim, 1-bit tiles - TODO

## Gotchas
- The 128MB QEMU guest THRASHES/HANGS on the big native-ld links. Build libs
  with -O; do the final links carefully. If the guest hangs (100% CPU, agent
  unreachable), force-quit + restart QEMU; built .a files survive on disk BUT a crash mid-`ar` can corrupt the
  archive symbol table (`ld: no string table`); just `rm LIB.a; make LIB.a`
  to rebuild the index (the .o files are fine). Run big links in the
  background (`nohup ... &`) + poll so the agent stays reachable if it thrashes.
- A/UX grep has no `\|` alternation, sed no in-place, sh no `$((...))`; use awk.
