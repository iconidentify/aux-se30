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
- Run: `cd /usr/local/quake && DISPLAY=:0 ./quake.x11`
- Window: 320x200 depth 8 PseudoColor, private colormap via XStoreColors,
  plain XPutImage. Demo reel plays. Process verified stable.
- Debug prints: early Con_Printf is swallowed before console init; the
  pak-load diagnostics were switched to Sys_Printf to see them.
- Agent gotcha: processes launched via auxagent have fd 0 closed, so the
  pak file lands on fd 0 - harmless for the client (only dedicated mode
  reads stdin), but don't add stdin tricks.

## Not done yet / next

- Performance: built -O0 with XSynchronize(True) still on (id's debug
  line in vid_x.c) - remove the XSynchronize call and try -O per-file
  for the renderer when we care about frame rate.
- SE/30 (1-bit): vid_x.c has no depth-1 path; would need a mono
  dither/threshold stage like the Micropolis depth-1 work. The binary
  itself is 030-portable.
- Sound: A/UX has no audio path; snd_null forever (or a /dev/null DMA
  experiment for the brave).
- Keyboard/mouse in-game not yet exercised (demo loop only).
