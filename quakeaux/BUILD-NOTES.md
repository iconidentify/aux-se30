# Quake 1 on A/UX 3.1.1 (m68k)

Original id Software GPL Quake (WinQuake tree, the `quake.x11` target) ported
to A/UX 3.1.1, built on the QEMU q800 guest (mc68040) with the jagubox
gcc 2.7.2.3 and linked against our self-built X11R6 shared libraries.
First confirmed run 2026-06-10: 320x200 depth-8 window on XmacII, demo reel
playing, shareware pak0.pak.

## Why this source tree

The id GPL release (github.com/id-Software/Quake) is a near-perfect era match:

- Built with gcc 2.7.x on mid-90s Unix; compiles under A/UX gcc 2.7.2.3
  with zero C-language changes (all 67 files first try).
- Runtime big-endian support (`COM_Init` swaptest sets Big/LittleShort
  function pointers) - no endian patching needed on m68k.
- The x86 assembly is optional: `id386` is 0 off-Intel, the C renderer
  paths take over, `nonintel.c` provides the patch stubs. The `.s` files
  are simply not compiled.
- Ships null drivers: `snd_null.c` (whole sound API) and `cd_null.c`,
  plus `net_none.c` (loopback only - all single player needs).
- `vid_x.c` is 8-bit PseudoColor first, exactly what XmacII at depth 8 is.

Modern ports (TyrQuake etc.) assume C99/POSIX far beyond A/UX SVR2.

## File set

The `X11_OBJS` list from Makefile.linuxi386 minus all `.s`, with:
cd_linux.c -> cd_null.c, snd_{dma,mem,mix,linux}.c -> snd_null.c,
net_{udp,bsd,dgrm}.c -> net_none.c, sys_linux.c -> sys_aux.c (new),
plus compat.c (new). Don't forget progdefs.q1/q2 (included by progdefs.h).

## Status

Playable. Menu, new game, level loads, demos, interactive play all work.
`timedemo demo1` = 969 frames / 28.9 s = 33.5 fps (depth-8 X11 non-SHM
path, -O0 build, -scale 2 window, QEMU q800 on an Apple Silicon host).

## The actual port (everything that had to change)

1. `sys_aux.c` (from sys_linux.c): drop sys/mman.h+ipc+shm includes; drop
   the fcntl FNDELAY non-blocking-stdin games (A/UX non-blocking I/O is
   broken at the kernel level - the inbound-sshd lesson); usleep ->
   select-based sleep; `Sys_MakeCodeWriteable` = no-op (x86 self-modifying
   surface-cache code only).

2. `vid_x.c`: force `doShm` off (`if (XShmQueryExtension..)` -> `if (0)`) -
   XmacII SHM is unstable, the SimCity lesson; the non-SHM XPutImage path
   is the original working renderer. srandom/random -> srand/rand (no
   BSD random in A/UX libc). sigaction block -> plain signal().

3. `r_main.c` R_RenderView: wrap the three alignment Sys_Errors
   ("Hunk/Stack/Globals are missaligned") in `#if id386`. m68k gcc aligns
   byte arrays and stack frames to 2 bytes, so `&r_warpbuffer & 3` fires
   spuriously; 68020+ handles any alignment correctly in the C renderer.

4. THE BIG ONE - `%i` is not a format specifier on SVR2: A/UX vsprintf
   emits it literally, so `va("%s/pak%i.pak", ...)` produced
   "./id1/paki.pak" and the pak silently never loaded ("can't find
   gfx.wad" while pak0.pak sits right there). id used %i in 184 format
   strings across 20 files. Global fix:
   `perl -pi -e 's/%(-?[0-9.]*)i/%${1}d/g' *.c`
   (verified no modulo-by-variable-i false positives first).

5. `compat.c`: strerror, strcasecmp/strncasecmp, getpagesize, memmove.
   NOTE: A/UX string.h DECLARES an ANSI memmove prototype (libc just
   doesn't ship the symbol), so memmove must be defined ANSI-style,
   not K&R, or gcc errors "argument doesn't match prototype".

6. `r_main.c` R_RenderView (second landmine, fired only on NEW GAME, not
   demos): the x86-era check that R_RenderView runs within 10KB of the
   init-time stack position fails with -O0's fat frames on the deep
   level-load chain (Host_Frame -> CL_ParseServerMessage ->
   SCR_UpdateScreen). Gated #if id386 with the alignment checks.

7. `vid_x.c` shared colormap (the desktop-flashing fix): the stock
   private AllocAll colormap makes everything else on an 8-bit display
   turn to garbage whenever quake holds colormap focus (one hardware
   palette). Instead: allocate the 256 quake colors read-only from the
   DEFAULT colormap (193 of 256 got exact cells on a busy desktop) and
   remap dirty-rect pixels through an 8-to-8 table (st1_fixup) before
   XPutImage - the same trick the engine's 16/24-bit paths use.
   CRITICAL FOLLOW-UP: palette SHIFTS (damage/underwater, every frame
   when active) must NOT re-allocate cells - that is 256 X round-trips
   per frame and craters performance. Allocate + XQueryColors snapshot
   once, then rebuild the lookup table client-side per shift (zero
   server traffic). `-privatecmap` restores the old exact-palette mode.

8. `vid_x.c` resize/move crash: ANY ConfigureNotify - including plain
   window MOVES - fired the mid-frame framebuffer-reset path while the
   renderer still held pointers into the old buffers. Fix: pin the
   window size with WM hints (PMinSize=PMaxSize), only honor a real
   size change, size at launch time only. `-scale N` (1-4, depth 8)
   pixel-doubles dirty rects into a second XImage: bigger window at
   zero render cost. Mouse deltas are divided by the scale.

9. SIGTERM used to hang the process (TragicDeath closed the display,
   then VID_Shutdown closed it again): both now guard and clear x_disp,
   so plain `kill` works.

## Build (on the guest)

- Source at /usr/local/quakesrc. `sh build.sh` - resume-safe loop that
  skips existing .o (no make: guest RTC jumps backward across restarts).
- CC = /usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/
  -fpcc-struct-return -I. -I/usr/local/X11R6/include
  (trailing slash on -B mandatory; -fpcc-struct-return matches the X
  shlib ABI; NO -O - optimizer thrashes the guest, X11R6 lesson).
- Link = `sh link.sh`: the Micropolis split-import-archive recipe,
  -L/tmp/linklib -lXext_s -lX11a_s -lX11b_s -lX11c_s repeated x4
  (single-pass native ld), -lXbsd -lposix -lm -lmr. 587KB binary,
  links clean first try.

## Runtime

- /usr/local/quake/quake.x11 + id1/pak0.pak (shareware 1.06, 18689235
  bytes, from ftp.gamers.org/pub/idgames/idstuff/quake/quake106.zip ->
  unzip -> 7z x resource.1 (LHA self-extractor) -> ID1/PAK0.PAK).
- Run: `cd /usr/local/quake && DISPLAY=:0 ./quake.x11 -scale 2`
- Useful flags: `-scale N` window pixel-doubling (1-4); `-privatecmap`
  exact palette (desktop flashes while focused); `-winsize W H` real
  render resolution (costs render time, unlike -scale); `+map start`
  skip demos; `+timedemo demo1` benchmark. In-game: `~` console,
  `_windowed_mouse 1` to grab the mouse.
- id's `XSynchronize(x_disp, True)` debug line was removed (it made
  every Xlib call a server round-trip).
- Debug prints: early Con_Printf is swallowed before console init; the
  pak-load diagnostics were switched to Sys_Printf to see them.
- Agent gotcha: processes launched via auxagent have fd 0 closed, so the
  pak file lands on fd 0 - harmless for the client (only dedicated mode
  reads stdin), but don't add stdin tricks.

## Lessons learned (the short list)

1. Era-match the source to the toolchain: 1996 id C compiled UNCHANGED
   on 1997 gcc. Every single crash/bug was a platform assumption (x86
   alignment, x86 stack layout, Linux libc, BSD random, %i printf), not
   the engine and not A/UX.
2. SVR2 printf has no %i. It prints it literally. The only symptom was
   "can't find gfx.wad" - three layers downstream of the actual bug.
3. On one-hardware-palette displays, never take a private colormap if
   you can closest-match into the default one; and never put colormap
   allocation in a per-frame path.
4. ConfigureNotify fires on window MOVES, not just resizes. If your
   resize path is fragile, a move will find it.
5. Old sanity checks encode old platforms. Three separate Sys_Errors
   (alignment x2, stack position) were x86-truths that are simply false
   on m68k/-O0 - all behind #if id386 now.
6. For pixel art video/screenshots: keep (or upscale to) 2x before any
   4:2:0 encode, or chroma subsampling halves your color resolution.

## Not done yet / next

- SE/30 (1-bit): vid_x.c has no depth-1 path; would need a mono
  dither/threshold stage like the Micropolis depth-1 work. The binary
  itself is 030-portable.
- TrueColor option: QEMU q800 macfb supports 24bpp only at 640x480 /
  800x600 (1152x870 caps at 8bpp). start24.sh is staged on the host;
  XmacII at depth 24 is unverified. At 24bpp all colormap concerns
  vanish and quake uses its existing st3_fixup path.
- Sound: A/UX has no audio path; snd_null forever (or a /dev/null DMA
  experiment for the brave).
- Perf headroom if wanted: try -O on the r_*/d_* renderer files only
  (the X11R6 -O wedge lesson applied selectively).
