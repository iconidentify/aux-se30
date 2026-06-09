# Patched Micropolis sim sources (A/UX)

These are the two `src/sim/` files from the tenox7 Micropolis Legacy fork with the
A/UX fixes applied. They are the verbatim files built into our `res/sim` on the
QEMU A/UX guest. See `../BUILD-NOTES.md` for the full story.

- **`g_setup.c`** - `GetObjectXpms` no longer calls `sim_exit(1)` when an animation
  frame file is missing. The DUX demo ships an incomplete sprite set (obj1 lacks
  frame 4, obj8 is absent entirely); a missing frame now reuses frame 0 if present,
  otherwise `None`, and loading continues. This was the cause of the startup
  "silent exit" (sim_exit set `tkMustExit`, so the first `Tk_MainLoop` iteration
  bailed right after `UIStartSimCity` reported OK). Also forces `tilesbw.xpm`
  (2-colour tiles) in `GetViewTiles` and prints the XpmError code on failure.

- **`w_sprite.c`** - `DrawSprite` skips any frame whose pixmap is `None`, so the
  absent sprites don't provoke a `BadDrawable` on every animation tick.

- **`auxmalloc.c`** - replacement malloc/free/realloc/calloc (canonical K&R
  section-8.7 coalescing allocator, sbrk-backed). A/UX's libc malloc corrupts
  its own arena under Tk 2.3's allocation pattern on a depth-1 (monochrome)
  display, crashing wish/SimCity inside malloc during main-window creation
  (proven by interposing a debug allocator: Tk init then completes cleanly).
  Link this ahead of libc so the statically-linked Tcl/Tk/sim use it; shared
  Xlib keeps libc malloc (its own pattern is fine - xterm runs at depth 1).
  **This is what makes SimCity initialise and run at depth 1 at all.**
- **`w_x.c`** - also forces `xd->shared = 0` on a 1-bit display (XmacII is
  unstable drawing depth-1 shared-memory pixmaps), plus the CatchXError logging.

Other diagnostic patches (startup traces, `SIGHUP` -> `SIG_IGN` in `sim.c`) are
on the guest only and should be reverted for a production build.

KNOWN ISSUE (depth 1): after the allocator fix the sim runs and enters
Tk_MainLoop at depth 1, but XmacII still crashes on one of SimCity's depth-1
draw operations (the sim then cascades via the non-fatal X error handler).
Under investigation - the editor renders 1-bit tiles fine at depth 8, so this is
an XmacII depth-1 rendering-path bug to be isolated and avoided.
