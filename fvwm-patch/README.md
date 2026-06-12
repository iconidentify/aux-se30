# fvwm 1.24r ArrangeIcons patch

Adds an ArrangeIcons builtin to fvwm 1.24r: re-snaps every iconified
window into the IconBox grid (clears the manual-drag ICON_MOVED flag
and re-runs AutoPlace, two passes so vacated slots repack cleanly).

Files here are the three patched sources (parse.h: F_ARRANGE_ICONS;
configure.c: keyword table entry; functions.c: the case). Guest source
tree: /usr/local/src/fvwm/fvwm1-1.24r.orig/fvwm.

Build on the guest:
    make fvwm "CC=/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/"
The stock link line misses the X11 fixups; hand-link with
/usr/local/r6lib/fixups.o appended after the libraries (single-pass
native ld - same rule as the xterm and rxvt links).

Config: IconBox 126 4 1026 120 (centered top band on the 1152x870
display) plus the "Align Icons" Main-menu entry. Previous binary kept
at /usr/bin/X11/fvwm.pre-arrange.
