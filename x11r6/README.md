# X11R6 for A/UX (Apple SE/30, mc68030)

A complete X11R6 client-library build for **A/UX 3.1.1** and a working R6
`xterm` running in a real A/UX graphical login session on a 1989 Macintosh
SE/30.

To our knowledge this is the first complete X11R6 client-library build, and the
first dynamically linked R6 `xterm`, on A/UX.

## What's here

- `src/main.c` - the patched xterm `main.c` (see `PATCH.md` for the one-line
  functional change that makes it work on A/UX).
- `src/mm.c` - a `memmove` shim needed at link time.
- `build/compile-main.sh` - compile `main.o` with the A/UX gcc 2.7.2.3.
- `build/link-xterm.sh` - link the R6 xterm against our own R6 shlibs using the
  split-import-archive trick.
- `build/split-import-archive.sh` - notes on splitting `libX11_s.a`.
- `../X11R6-BUILD-NOTES.md` - the full engineering log (Parts 1-10): building
  the 7 shared libraries with `mkshlib`, the native-`ar`/`ld` "too many
  external symbols" wall, and the split-archive solution.

## Build artifacts (in `../dist/`)

- `dist/shlib/` - our seven R6 runtime shared libraries (`lib*.6.0_s`):
  libX11, libXext, libICE, libSM, libXt, libXmu, libXaw.
- `dist/import/` - the matching import libraries (`lib*_s.a`) + `libXbsd.a`.
- `dist/x11split/` - `libX11{a,b,c}_s.a`, the split libX11 import archive.
- `dist/xterm/` - the R6 xterm objects, the patched `main.c`, and the final
  binaries (`xterm-r6-prod` is the clean production build deployed to the SE/30).
- `dist/tools/` - the GNU binutils (m68kaux) `ar`/`ld`/`nm`/`objcopy` used.
- `dist/nleymann/` - third-party reference: Nicolas Leymann's A/UX X11R6pl4
  prebuilt libraries and fonts, used early for comparison. Not our work; see
  their original distribution for licensing.

## Toolchain (on the A/UX host, not in this repo)

- gcc 2.7.2.3 at `/usr/local/gcc-2.7.2.3` (with its bundled GNU `as`).
- The X11R6 `xc` source tree at `/usr/local/xcb/xc` on the build guest.
- Installed headers/config at `/usr/local/X11R6`.
- Config: `macII.cf` (`StandardDefines = -DmacII -DSYSV`), `-fpcc-struct-return`.

## Deploying to the machine

The seven `lib*.6.0_s` go in `/shlib`. The xterm binary goes in
`/usr/bin/X11/xterm` (setuid root, `-rwsr-xr-x`, for pty allocation). A/UX's
X11 session script (`/usr/bin/X11/X11`) launches `xterm -e $HOME/.x11start` as
the console window; add `twm &` to `.x11start` for a window manager.
