# The xterm patch for A/UX (macII)

Getting a working X11R6 `xterm` running in a real A/UX graphical login session
required exactly **one functional source change** to `programs/xterm/main.c`,
plus the build/link machinery described in the notes. This documents the source
change and *why* it is needed.

## The change

In `get_terminal()`'s child tty-setup block, stock R6 xterm only re-reads the
freshly allocated pty's own termio modes for a few platforms:

```c
#if defined(umips) || defined(CRAY) || defined(linux)
```

We add `macII` to that list:

```c
#if defined(umips) || defined(CRAY) || defined(linux) || defined(macII)
    /* ... On A/UX (macII) the modes inherited from the console are invalid
       for a pty slave (TCSETA -> EINVAL); reading the pty's own valid modes
       first fixes that and lets us turn ECHO back on. */
    if (ioctl (tty, TCGETA, &tio) == -1)
      SysError (ERROR_TIOCGETP);
    tio.c_lflag |= ECHOE;
#endif
```

That is the entire diff.

## Why

When A/UX launches the X11 session, `xinit` runs the console xterm directly
from `/dev/console`. xterm captures the controlling terminal's `termio`
settings at startup and later applies them to the pty slave with the SYSV
`TCSETA` ioctl. **The console's termio settings are not valid for a pty
slave**, so `TCSETA` returns `EINVAL` (xterm reports `Error 23, errno 22`) and
the session dies.

Reading the *new pty's own* modes first (with `TCGETA`) gives a valid base;
xterm then OR-s in the bits it wants (`ICRNL`, `ONLCR`, `ISIG|ICANON|ECHO`,
...). A freshly opened A/UX pty slave defaults to `ICANON` set but `ECHO`
clear, which is why, before this fix, line mode worked but you could not see
what you typed.

## Two A/UX gotchas this also clears up

1. **"no available ptys" was never an R6 bug.** That message came from the
   *stock R4* `/usr/bin/X11/xterm` that `xinit` launches as the session
   gatekeeper; its pty allocation fails on A/UX. Our R6 build's `pty_search`
   succeeds (`/dev/ptyp0` on the first try), so installing the R6 binary as the
   console xterm gets past it.

2. **Verified launch-context dependence.** The bug only reproduces in the real
   `Login -> X11 -> xinit -> console-xterm -> pty` chain. Running xterm by hand
   from a pty-backed shell (e.g. a CommandShell or telnet session, as on the
   QEMU guest) inherits *valid pty* modes, so `TCSETA` succeeds and everything
   "just works" -- which is why this was invisible until tested on the real
   SE/30 graphical login.
