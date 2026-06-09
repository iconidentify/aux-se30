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

Other diagnostic patches (CatchXError logging in `w_x.c`, startup traces and
`xd->shared = 0` to disable XShm, `SIGHUP` -> `SIG_IGN` in `sim.c`) are on the
guest only and should be reverted for a production build.
