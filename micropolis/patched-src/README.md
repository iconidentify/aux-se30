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

Depth-1 rendering is now fully working - editor AND overall map both draw in
1-bit.  The fixes:

- **`w_x.c`** - force `xd->shared = 0` on a 1-bit display (XmacII is unstable
  with depth-1 shared-memory pixmaps); CatchXError logging.
- **`g_map.c`** (`MemDrawMap`) - the mono map dithers an 8-bit buffer to 1-bit
  and `XPutImage`s it, but without shared memory the XImage header was never
  created, so `XPutImage(...,NULL,...)` crashed XmacII.  Create a depth-1
  `XYBitmap` image around the dither buffer lazily.
- **`w_map.c`** (`DoUpdateMap`) - proper map invalidation wasn't firing at
  depth 1, leaving the Overall Map blank; force a full redraw each update (the
  map is small, so it's cheap).
- **`g_smmaps.c`** (`DRAW_BEGIN`) - the small-map tile blit used
  `pixelBytes = view->pixel_bytes`, which is 0 at depth 1, collapsing the column
  stride to 0 so every tile drew into the first 3 columns.  The 8-bit map buffer
  needs `pixelBytes = 1` in mono.  This was why the minimap was a near-empty box.

Test harness: `res/simcity.tcl` `UIStartSimCity` auto-loads a scenario when
`AUXSIM_AUTOLOAD=<1-8>` is set in the environment (so headless testing needs no
human at the picker).  Normal play is unaffected when unset.  (simcity.tcl is an
EA/Maxis asset and is NOT committed; the one-paragraph hook is documented here.)
