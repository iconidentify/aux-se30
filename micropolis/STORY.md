```
  ___ _       ___ _ _              ___  _  _   __   _   _ _  _ _____  __
 / __(_)_ __ / __(_) |_ _  _   ___ _ _    |_  )/_ \ / /  | | | | \ \/ /
 \__ \ | '  \ (__| |  _| || | / _ \ ' \   / /| () / _ \ | |_| |  >  <
 |___/_|_|_|_\___|_|\__|\_, | \___/_||_|  /___|\__/\___/  \___/  /_/\_\
                        |__/
        SimCity, running on a 1989 Macintosh SE/30 under Apple's UNIX.
```

# How we got SimCity running on a Macintosh SE/30

This is the story of getting the classic Unix port of SimCity to build and play
on a real **Apple Macintosh SE/30** (and an emulated one) running **A/UX**,
Apple's own UNIX from the early 1990s. The display is **1 bit** - pure black and
white, 512x342 - and the C compiler is from 1994. It works. You can play it.

## A short history of THIS SimCity

There are many SimCitys. This is a specific, slightly obscure branch of the
family tree:

- **1989 - SimCity.** Designed by **Will Wright**, published by **Maxis**. The
  original city-builder.
- **1993 - "X11 SimCity for Unix"** (a.k.a. *Multi-Player Micropolis*). Ported
  to Unix and X11 by **DUX Software**, with the multiplayer interface designed
  and built by **Don Hopkins**. The whole UI is written in **Tcl/Tk** - you
  could have several mayors editing the same city over the network.
- **2008 - open-sourced as "Micropolis."** EA released the SimCity source under
  the GPL (for the One Laptop Per Child project), led again by Don Hopkins. EA
  kept the "SimCity" trademark, so the free version is called **Micropolis**.
- **today - kept alive** in community forks (we built from the tenox7 fork) that
  still compile the original X11/Tcl-Tk version.

The version we built still proudly prints its lineage on startup:

```
Welcome to X11 Multi Player Micropolis version 4.0 by Will Wright, Don Hopkins.
Copyright (C) 2002 by Electronic Arts, Maxis. All rights reserved.
```

It bundles genuinely ancient toolkit versions: **Tcl 6.4, Tk 2.3, TclX 6.4c,
Xpm 3** - all early-1990s vintage, which is exactly why it has any hope of
running on a machine of that era.

## The machine

- **Apple Macintosh SE/30** (1989): Motorola 68030 at 16 MHz, 1-bit 512x342
  internal display.
- **A/UX 3.1.1**: Apple's UNIX - System V plus BSD, runs both Mac apps and X11.
- **gcc 2.7.2.3** as the compiler, our own hand-built **X11R6**, and Apple's
  **XmacII** X server.
- We iterated fast on **QEMU** emulating a Quadra 800 (68040) running the same
  A/UX, then deploy to the real SE/30 (same 1-bit world).

## The build chain

Everything had to be compiled from source, in order:

```
Xpm  ->  Tcl 6.4  ->  Tk 2.3  ->  TclX 6.4c  ->  the SimCity engine
```

## The fun parts (the patches)

A/UX is UNIX, but a 1990s UNIX with sharp edges. Here are the obstacles, in
plain terms, with the actual fixes.

### 1. There is no `ranlib`

Modern build scripts run `ranlib` to index a static library. A/UX doesn't ship
one. The fix is one weird old incantation:

```sh
ar cr libtcl.a *.o      # make the archive
ar ts libtcl.a          # ...and 't s' writes the symbol index ranlib would have
```

### 2. Missing C standard-library functions

A/UX's C library predates parts of ANSI C. `strtoul`, `strerror`, and `strdup`
simply don't exist. We dropped in tiny replacements (`compat.c`) and folded
them into the Tcl library:

```c
char *strdup(s) char *s; {            /* old K&R style, because old compiler */
    char *p = malloc(strlen(s) + 1);
    if (p) strcpy(p, s);
    return p;
}
```

### 3. The malloc that eats itself (the big one)

On the 1-bit display, the game crashed instantly - inside `malloc` of all
places. After building a little instrumented allocator to catch it, the verdict
was surprising: **A/UX's own `malloc` corrupts its internal bookkeeping** under
the specific pattern of allocations Tk makes on a black-and-white screen. The
game was fine; the system library was not.

The fix: bring our own allocator. We linked in the classic, bullet-proof
allocator from the back of the K&R C book, ahead of the system one, so every
allocation in Tcl/Tk/SimCity uses it instead:

```c
/* auxmalloc.c - the textbook K&R storage allocator, sbrk-backed.
   Linked before libc so the whole program uses it instead of A/UX's
   broken one. ~120 lines, and it Just Works. */
char *malloc(unsigned nbytes) { ... }
void  free(char *ap)          { ... }
```

This single change is what makes the game run on the 1-bit display **at all**.

### 4. The demo was missing pieces

The freely-available city/asset set is a demo, and it's missing some animation
frames (the bus sprite, a traffic frame). The original code treated a missing
file as fatal - it would quietly set "time to exit" and the whole game would
vanish a moment after starting. We made missing art non-fatal:

```c
/* old: a missing sprite frame killed the game */
/* new: skip it and carry on */
if (XpmReadFileToPixmap(... name ...) < 0) {
    fprintf(stderr, "Micropolis: missing sprite \"%s\" (skipping).\n", name);
    /* reuse frame 0, or just don't draw it */
}
```

### 5. Teaching it to draw in pure black & white

SimCity assumes a colour screen. On 1-bit hardware several things broke, each
fixed in turn:

- the X server **crashed** when handed the map as a shared-memory image -> we
  turn shared memory off on 1-bit displays;
- the minimap's image was never actually created without shared memory, so the
  game drew a *null* image and crashed the server -> create it properly;
- the minimap blit used a "bytes per pixel" of **zero** on a 1-bit screen, which
  collapsed the entire city into the first three columns:

```c
/* the whole minimap was drawing into a 3-pixel-wide stripe... */
int pixelBytes = view->pixel_bytes;                 /* == 0 at depth 1!  */
/* ...fixed: an 8-bit work buffer is 1 byte per pixel in mono */
int pixelBytes = view->x->color ? view->pixel_bytes : 1;
```

With that, the dithered black-and-white overview map renders the whole city.

### 6. It ran WAY too fast

Old games tied their speed to the CPU - "run as fast as you can." On a 1989
machine that's a gentle pace; on a modern/emulated CPU the clock spins like a
slot machine. We measured it (about 22 seconds per game-month on "slow") and
re-paced it to wall-clock time:

```c
/* pace the simulation by real time, not CPU speed */
switch (speed) {
    case 1: sim_delay = 200000; break; /* slow   ~1 game-month / minute  */
    case 2: sim_delay =  90000; break; /* medium ~3 game-months / minute */
    case 3: sim_delay =  45000; break; /* fast   ~18 game-months / minute*/
}
```

Because the timer delay is a *minimum*, a slow real SE/30 that can't keep up
just runs as fast as it can - which is the authentic period pace. Fast machine:
sane. Slow machine: sane. Same code.

## The result

A fully playable, multi-window, dithered 1-bit SimCity on Apple's UNIX: the city
editor, the overall map, the RCI graph, disasters ("A Monster has been
sighted!"), the works - on hardware and an OS from when the game was new.

## Making it our own (the C89 Summer overhaul)

Once it ran, we rebuilt the look. The whole interface is Tcl/Tk - a thin
scripting skin over the C engine - so we could restyle everything without
touching a line of the simulation. New work, all in the UI scripts:

- a fresh **18-tool palette** (clean themed icons we drew and converted to XPM),
  packed into a tight 2-column bar with a live **RCI demand gauge** and a
  clickable **mini-map** beside it;
- the old floating Controls window's menus **folded into the editor** as a
  proper File / Options / Speed / Disasters / Windows / Help bar, with a bottom
  status strip for date, funds and messages;
- a redesigned **Welcome screen** and **About** box (with a tasteful C89 Summer
  credit), a clean **New City** flow, and **modals** rebuilt to look like a real
  application - centered text, uniform OK/Cancel buttons, an Enter-key default,
  no garish banners;
- the 1993 **license-key system removed** - it's the full game, always.

The deepest cut was the toolkit itself. Tk 2.3 predates `bindtags`: an instance
binding *replaces* the widget's class binding instead of adding to it. Our hover
handlers were silently overriding Tk's own button machinery, so clicks stopped
firing after the first mouse-over. The fixes (and a dozen other pre-Tk-4.0
quirks) are written up in `micropolis/ui/README.md`.

## Where it lives

- Repo: **github.com/iconidentify/aux-se30**
- Build recipe: `micropolis/BUILD-NOTES.md`
- Every patched source file + notes: `micropolis/patched-src/`
- Missing-libc shims: `micropolis/compat.c`
- The UI overhaul + Tk lessons: `micropolis/ui/README.md` (and the deployed
  scripts + asset generators under `micropolis/ui/` and `micropolis/tools/`)

The SimCity/Micropolis engine and Tcl/Tk are their authors' work (GPL); the
copyrighted EA/Maxis demo assets are **not** included - bring your own from the
archived "SimCity for Unix" demo.

## Credits

Will Wright & Maxis (the game) - Don Hopkins & DUX Software (the Unix/Tcl-Tk
multiplayer port) - EA (the GPL release) - the community forks that keep it
buildable - and a very patient SE/30.
