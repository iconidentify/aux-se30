# auxtop - a themed ncurses process monitor for A/UX 3.1.1

A synthwave, htop-inspired `top` for A/UX, running on the QEMU q800 guest.
Built on top of LeFebvre `top` 3.5's A/UX machine module (`m_aux3.c`),
which needed three never-compiled bugs fixed before it would run, plus a
clean presentation layer and a long fight with the 1994 X11R6 xterm.

## Files

- `auxtop.c` - the whole UI (meters, process table, theme, keys). Formats
  every field itself; does not use top's `format_next_process`.
- `m_aux3-patched.c` - top 3.5's A/UX machine module with our fixes +
  the `auxtop_next` accessor and `auxtop_compare_size` comparator appended.
  Compile as `machine.c` (the top Makefile expects that name).
- `auxterm.c` - isolated unit that NULLs the terminal capabilities the R6
  xterm implements wrong (must be its own file: `<term.h>` defines `tab`,
  `lines`, etc. as macros that collide with normal identifiers).
- `auxtop_proc.h` - the struct the accessor fills.
- `auxtoprc` - the theme (install as `/.auxtoprc`).
- `auxtop-x` - fvwm launcher: opens a synthwave xterm and runs auxtop.

## The top 3.5 m_aux3 bugs (it shipped never having been compiled)

1. `lookup_proc` used `rp->p_pid` instead of its `id` parameter (`rp` isn't
   even in scope) - wouldn't compile.
2. `preal`/`epreal` (the buffer the whole proc table is read into) was
   **never malloc'd** - `read()` into NULL returns EFAULT, whose strerror
   is "Bad address" (the `getkval for proc array: Bad address` failure).
3. Needs `-lposix` (sigismember) and `-lacomp` (setlocale) at link.

Also: macOS `/tmp` is case-insensitive, so generating `top.local.h` from
`top.local.H` with sed clobbers the file - generate to a different name.

## The build (on the guest)

Module (compile as machine.c, in the top-3.5 tree):

    gcc -B/usr/local/gcc-2.7.2.3/ -DAUX3 -O -Dclear=clear_scr \
        -DPRIO_PROCESS=0 -c machine.c

auxterm + auxtop, linked against the proven top objects + ncurses 5.7:

    gcc -B/usr/local/gcc-2.7.2.3/ -O \
        -I/usr/local/ncurses-5.7/include -c auxterm.c
    gcc -B/usr/local/gcc-2.7.2.3/ -O -I<top-3.5> \
        -I/usr/local/ncurses-5.7/include -I/usr/local/ncurses-5.7/include/ncurses \
        -o auxtop auxtop.c auxterm.o machine.o utils.o username.o \
        -L/usr/local/ncurses-5.7/lib -lncurses -lposix -lm \
        -L/usr/local/fd/lib -lacomp

Run with `TERMINFO=/usr/local/ncurses-5.7/share/terminfo`.

## The rendering war (R6 xterm vs ncurses 5.7)

The dump harness (`AUXTOP_DUMP=1` reads the screen back via `mvinnstr`)
proved repeatedly that the drawing logic was always correct - every glitch
was ncurses translating a correct logical screen into wrong escape
sequences for the 1994 xterm. The fixes, in order of discovery:

1. **Unstable sort** -> ghosting. CPU-sort jitters on an idle box (every
   process has a tiny near-zero CPU that reshuffles each frame). Fix:
   `auxtop_compare_size` (stable: size desc, PID tiebreak).
2. **No SIGWINCH** -> resize corruption. A/UX's ncurses doesn't catch the
   resize signal, so resizing desyncs ncurses from the terminal and
   `refresh()` scatters. Fix: our own SIGWINCH handler + `ioctl(TIOCGWINSZ)`
   + `resizeterm()`.
3. **Broken clear caps** -> stale cells. The R6 xterm's clr_eol/clr_eos/
   clear_screen don't clear. Fix: NULL them so ncurses writes literal
   spaces (auxterm.c).
4. **Broken single-axis cursor moves** -> the infamous "init at column 50".
   ncurses optimized a row's redraw with a column-jump (column_address)
   that no-ops on the R6 xterm, leaving the cursor at the previous column.
   Fix: NULL column_address/row_address/parm_*_cursor so ncurses uses only
   absolute cursor_address (auxterm.c).
5. **Self-inflicted flash**: while the above were unsolved, we brute-forced
   a full repaint every frame (`clear()`). Once the real causes were fixed,
   switched the frame loop back to `erase()` (diff update, only changed
   cells) - no flash.

## Other fixes

- Command names: a process's u-area name reads empty/garbage when swapped
  out. Fall back to a `ps -e` cache (pid->name, refreshed every 6 frames).
- Sanitize names (control chars -> nothing) - top's `format_next_process`
  left them unterminated and they scrambled the terminal.
- CPU%: the u-area CPU-time fields aren't where top expects on 3.1.1 (no
  `u_utime`/`u_stime` in A/UX `user.h`), so `p_pcpu` reads 0. Use the proc
  struct's `p_cpu` (the scheduler's own CPU-usage estimate) instead - a
  true relative meter, though not a perfectly calibrated percentage.
- CPU meter: A/UX cpustate order is `idle,user,kernel,wait,nice` - idle is
  FIRST, not last; look it up by name or you compute 100% busy on an idle
  box.

## Dependencies

ncurses 5.7 at `/usr/local/ncurses-5.7` (robbraun prebuilt), libacomp
(the fsv-era compat lib) for setlocale, top 3.5 source tree for the
machine module + utils.o/username.o.
