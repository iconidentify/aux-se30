# A/UX SE/30 hacking

Tools and build work for running modern-ish software on **A/UX 3.1.1** (Apple's
Unix) on a real Macintosh **SE/30** (mc68030), driven from a Mac via a QEMU
A/UX build guest.

## Contents

### [`x11r6/`](x11r6/) - X11R6 for A/UX
A complete X11R6 client-library build for A/UX and a working, dynamically
linked R6 `xterm` running in a real A/UX graphical login session on the SE/30.
Seven shared libraries built with `mkshlib`, linked past the native `ar`/`ld`
symbol-limit wall with a split-import-archive trick, plus the one-line xterm
patch that fixes the A/UX pty `TCSETA` problem. See
[`X11R6-BUILD-NOTES.md`](X11R6-BUILD-NOTES.md) for the full engineering log and
[`x11r6/PATCH.md`](x11r6/PATCH.md) for the fix.

### [`auxagent/`](auxagent/) - the A/UX agent
A tiny, reliable remote-exec and file-transfer agent for A/UX, built to replace
fragile telnet/ftp automation. Speaks **AAP** (A/UX Agent Protocol) over
HTTP/1.0; a ~300-line C program (gcc 2.7.2.3 + Berkeley sockets) on the A/UX
side, driven by `curl`/`auxctl` from the Mac. Includes an `auxadmin` settings
layer for A/UX administration (autologin, session type, ...) and an installer
that wires the agent into `/etc/inittab` for boot persistence.

### `dist/` - build artifacts
Our compiled R6 shared libraries, import libraries, the split libX11 archive,
the xterm binaries and objects, the GNU A/UX binutils used for linking, and
third-party reference material (Nicolas Leymann's A/UX X11R6pl4 libs/fonts).

## The machines

- **SE/30** (`jobs`, `10.1.1.214`) - the real hardware, A/UX 3.1.1, mc68030.
- **QEMU A/UX guest** (`10.1.1.20`) - emulated q800 (mc68040), the fast build
  host. See the build notes for the QEMU launch details.

Both run `auxagent` on port 8377 (boot-persistent via inittab).
