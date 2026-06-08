# A/UX X11R6 shared-library build and R6 xterm link notes

Status as of 2026-06-08. Records what was achieved (all 7 R6 client shared
libraries compiled) and the precise, characterized wall hit when trying to link
a working dynamic R6 xterm against them.

Machines:
- QEMU A/UX 3.1.1 build guest (mc68040 emulated), `10.1.1.20` -- fast but crash-prone at `-m 128`.
- Real Apple SE/30, A/UX 3.1.1 (mc68030), hostname `jobs`, `10.1.1.214` -- slow (16 MHz) but stable; has the full GNU binutils (`/usr/local/gnu/bin`).
- Both run `auxagent` on port 8377 (HTTP remote-exec/file agent; see `auxagent/`).

All artifacts are backed up on the Mac at `/Users/chrisk/se30/dist/`:
- `shlib/`  -- the 7 runtime shared libs `lib*.6.0_s`
- `import/` -- the 7 import libs `lib*_s.a` (+ `libXbsd.a`)
- `bin/auxagent` -- the agent binary (portable across 030/040)
- `xterm/`  -- xterm objects (16 `.o`), the static R6 xterm, Makefile
- `tools/`  -- GNU `ar`, `ld`, `nm`, `objcopy` pulled off the SE/30

## Part 1 -- ACHIEVED: all 7 R6 client shared libraries compiled

The full X11R6 client library stack was built as A/UX host shared libraries
(`mkshlib`), each producing a runtime shlib `lib<L>.6.0_s` and an import lib
`lib<L>_s.a`:

| Lib  | runtime `.6.0_s` | import `_s.a` |
|------|------------------|---------------|
| X11  | 706,659 | 698,624 |
| Xext | 50,666  | 27,042  |
| ICE  | 119,804 | 71,892  |
| SM   | 48,272  | 23,294  |
| Xt   | 367,179 | 245,450 |
| Xmu  | 109,712 | 108,842 |
| Xaw  | 314,809 | 288,876 |

Build recipe (on the QEMU guest, X11R6 `xc` tree at `/usr/local/xcb/xc`):
- Toolchain: gcc 2.7.2.3 at `/usr/local/gcc-2.7.2.3`. The `-B/usr/local/gcc-2.7.2.3/`
  prefix is mandatory (trailing slash!) so gcc uses its bundled `as`, not the
  native `/bin/as` (which rejects GNU syntax). ABI flag `-fpcc-struct-return`.
- Compile with `make CDEBUGFLAGS=` (i.e. -O0). With any optimization the
  128 MB guest thrashes to a network-dead wedge mid-build. -O0 is the lever.
- `macII.cf` patched: `AsCmd=/usr/local/gcc-2.7.2.3/as`, `CcCmd=gcc -B.../ -fpcc-struct-return`.
- Per-lib fixes that were required:
  - `isascii`/`toascii`: A/UX provides these as macros, so many objects emit
    unresolved external refs and `mkshlib` aborts. Fix: define them once in an
    `AuStub.c` (`int isascii(c) int c; { return ((unsigned)(c))<=0177; }`,
    similarly `toascii`) compiled to `AuStub.o` and added to the lib's
    `auxshlib.spec` `#objects` list (right after `auxshlib.o`). Needed for X11,
    Xaw, ICE, Xmu.
  - libX11 also needed the XDM-auth branch-table slots restored (don't leave
    gaps in `#branch`) with stub functions in `AuStub.c`, and the bare `Wrap.o`
    removed from `#objects`.
  - Crash-corrupted objects (from force-quitting QEMU mid-build) show up as
    `nm <obj>` -> "bad magic" / "no string table"; the `nm` exit code does NOT
    catch it. Stale `.o` dated earlier than the `.c` were silently skipped by
    `make` and fed corrupt into `mkshlib`. Fix: wipe `*.o unshared/*.o` and the
    lib, then rebuild clean (sources are pristine because the build restores
    every `*.c.save`).
  - Xt: a crash left `Initialize.c.save` corrupt; pushed the pristine
    `Initialize.c` from the Mac mirror `/tmp/x11r6build/xc/lib/Xt/`.

This is, as far as we can tell, the first complete X11R6 client-library build on
emulated A/UX.

## Part 2 -- THE WALL: linking a working dynamic R6 xterm

Goal: a dynamic xterm that loads our `/shlib/lib*.6.0_s` at runtime. A *static*
R6 xterm does not work on A/UX -- it bypasses `/shlib/libX11_s`, where A/UX's
local display-connection transport lives, so it can never connect to the local
XmacII server (documented in the SE/30 notes; static client = silent
"Process killed"). So a dynamic link against the shlibs is required.

We have all 16 xterm `.o` already compiled (from the earlier static build) plus
`fixups.o` (supplies `memmove` + `_X11ptr_malloc/calloc/free`, placed AFTER the
X libs because A/UX `ld` is single-pass). So this is purely a *link* problem.

### Native A/UX `ld` -- correct output, but cannot handle libX11

Native `ld` (driven by gcc via `/usr/lib/shlib.ld`) is the only linker that
produces a correct A/UX shared executable. But:
- `ld` fails: "archive symbol directory in `libX11_s.a` is too large."
- native `/bin/ar` cannot even build the index: "too many external symbols."
R6 `libX11` exports far more symbols than R4 did, exceeding native `ar`/`ld`
limits. The other 6 import libs are small enough; only libX11 busts the limit.

### GNU `ld` 2.10.1 (`m68kaux`) -- handles the big lib, but output crashes

The robbraun GNU binutils (`/usr/local/gnu/bin`, emulation `m68kaux`) handle the
large symbol table. Bridged to the guest via the agents; also present natively
on the SE/30 (where the final attempts were run, since the guest kept crashing).

GNU `ld` cannot be driven through gcc (gcc passes it the native `/usr/lib/shlib.ld`
script, which GNU `ld` syntax-errors on), so it must be invoked directly with the
startup files: `crt1.o crt2.o ... crtn.o`, `-lgcc -lc_s -lgcc`.

Multiple-definition problem: each A/UX shared lib *re-exports* the libc symbols
it uses (via `auxmemcpy.o` and syscall stubs) plus our `AuStub` `isascii`/`toascii`.
Native `ld` + `shlib.ld` dedups these silently; GNU `ld` 2.10.1 errors on them and
has no `--allow-multiple-definition` / `-z muldefs` (those came in binutils 2.13+).
What was tried:
- `objcopy --localize-symbol` / `--weaken`: do NOT work on these absolute COFF
  branch-table symbols (no effect).
- `--start-group` with `libc_s` first: fixed the `isascii`/`toascii` collisions
  (only the first `AuStub` gets pulled) but not the libc ones (the libc
  re-exports live in an always-pulled essential member).
- Deleting the conflicting members from a `libc_s` copy just moved the collision
  to *between* the X libs (every X import lib bundles `auxmemcpy.o`).
- WORKING: `objcopy -N <sym>` (strip-symbol) IS able to remove these symbols.
  Strip the 10 re-exported libc symbols (`cerror close connect memcpy read
  select stat strchr time write`) from all 7 X import libs, keep the original
  `libc_s` as the sole provider, link with `--start-group` (libc_s first).

That link SUCCEEDS: `xterm-r6`, 576 KB, COFF paged executable, LINKRC=0, zero
multiple-def, zero undefined. `objdump` confirms the output is structurally
correct:
- magic/flags match the native R4 xterm (`EXEC_P, D_PAGED`)
- the `.lib` section correctly lists `/shlib/libXaw.6.0_s`, `/shlib/libXmu.6.0_s`,
  `/shlib/libXt.6.0_s`, `/shlib/libc1_s`, etc.
- the `.lt/.ld/.lb` placeholder sections sit at the shlibs' fixed addresses
  (e.g. libXaw at `0x49d00000`).

BUT it crashes at startup:
- default layout (text `0x40468`, data `0x80310`): SIGILL (rc 132)
- forcing `-Ttext 0x1c0 -Tdata 0x400000` (matching `shlib.ld`'s mandated data
  at `0x400000`): SIGSEGV (rc 139)

So despite a correct `.lib` section and magic, the A/UX runtime does not map/
resolve the host shared libraries for a GNU-`ld`-produced executable. GNU `ld`
2.10.1's `m68kaux` port links A/UX COFF but does not fully implement A/UX's
host-shared-library runtime contract.

### Net: two-sided tooling wall
- native `ld`: correct shared-exec output, but can't link the oversized libX11 import lib.
- GNU `ld`: links the big lib, but its shared-exec output doesn't load shlibs at runtime.

## Part 3 -- Realistic next steps (not yet done)

1. Most promising: TRIM `libX11_s.a` down to only the X11 symbols xterm actually
   references (`nm` the xterm `.o` for undefined `X*` symbols -> keep just those
   stub members + the essential shlib-descriptor/`auxshlib` members), re-index
   with NATIVE `ar`. A few hundred symbols should fit under native `ar`/`ld`'s
   limit -- then native `ld` links it and produces a correct, working shared exec.
2. Build/obtain binutils >= 2.13 for `m68k-apple-aux` (has
   `--allow-multiple-definition`) AND verify it emits a loadable A/UX shared exec.
   The 2.10.1 runtime-load failure suggests this alone may not be enough.
3. Rebuild the shlibs so their import libs don't re-export libc symbols at all
   (cleaner, but the re-export is inherent to how `mkshlib` builds self-contained
   shlibs; biggest effort).

Note: the R4 xterm WORKS in the QEMU guest, which proves the SE/30's original
"no available ptys / EIO" xterm failure is environmental to that machine (pty
device nodes), not an R4 xterm defect.

## Reproduce the GNU-ld link (on the SE/30)

Materials in `/usr/local/r6lib` (import libs, `objcopy -N`-stripped) and
`/usr/local/src/xterm` (objects); shlibs installed in `/shlib`. Script
`/usr/local/dolink2.sh`. The 10 libc re-exports were stripped from the import
libs with `/usr/local/gnu/bin/objcopy -N <sym> lib<L>_s.a` (+ `ranlib`).
Clean, unmodified copies of every import lib are in the Mac backup
`/Users/chrisk/se30/dist/import/`.

## Part 2b -- DECISIVE: it's the executable format, not xterm (2026-06-08)

Per the "tiny test program beats another xterm cycle" approach: built a minimal
program `main(){ extern char *XOpenDisplay(); XOpenDisplay(0); return 0; }`
(no headers needed), compiled with gcc -B (native as), linked through the EXACT
same GNU `ld` flow/library environment that linked xterm-r6 cleanly (ld rc=0,
137 KB binary). Ran it with no DISPLAY (should just return NULL and exit 0 if
the shlib loads): **RUNRC=139 (SIGSEGV)**.

Conclusion: a trivial X client crashes the same way as xterm. The problem is
100% the A/UX shared-executable format/loader contract -- GNU `ld` 2.10.1
(`m68kaux`) does NOT emit a loadable A/UX shared executable, despite producing
structurally valid COFF (correct `.lib`, correct magic). GNU `ld` is a dead end
for RUNNING; only native `ld` produces loadable shared-lib binaries.

Note: the nleymann A/UX X11R6 port (source of our auxshlib spec files;
X11R6pl4.tar.gz on aux-penelope/jagubox) DID build a working R6 xterm with
native `ld` -- so native-ld linking of R6 clients IS possible. Either their
libX11 import lib was small enough for native ar/ld, or it was structured
differently than our `mkshlib` output. Worth comparing our libX11_s.a symbol
count/structure against a known-good A/UX R6 import lib, OR just using
nleymann's prebuilt xterm + prebuilt shlibs if a complete matching set exists.

## Part 4 -- THE REAL PATH: nleymann's prebuilt clients + shlibs built from HIS tree

Downloaded nleymann's `X11R6pl4.tar.gz` (12 MB, aux-penelope/jagubox).
Findings:
- It ships PREBUILT clients: `X11R6/bin/{xterm(219636),twm,xclock,oclock,...}`
  (xterm 219636 = exactly the "xterm-candidate" from the original plan; dynamic).
- It ships the IMPORT libs `X11R6/lib/lib*_s.a` but `X11R6/shlib/` is EMPTY --
  i.e. you are meant to BUILD the runtime `.6.0_s` shlibs on your A/UX box from
  his tree, then his prebuilt clients work. (That's the handoff.)
- His import libs are ~50% SMALLER than ours: libX11_s.a 469386 vs our 698624,
  libICE_s.a 47280 vs 71892, libXmu_s.a 80072 vs 108842, etc. => OUR shlib build
  diverged from his (we used MIT xc source + bolted-on nleymann specs + our
  AuStub/XDM edits; the bloat is why native ar choked on our libX11_s.a).
- His prebuilt xterm's `.lib` correctly names `/shlib/libXaw.6.0_s` etc.
- TEST: his prebuilt xterm + OUR `/shlib/lib*.6.0_s` -> SIGSEGV (rc 139). So our
  runtime shlibs are NOT binary-compatible with his client. Backed up his xterm
  + all his import libs at Mac `/Users/chrisk/se30/dist/nleymann/`.

CONCLUSION / recommended path (no broken linker needed):
1. Build the 7 runtime shlibs from nleymann's OWN tree (X11R6pl4.tar.gz),
   unmodified specs, with `mkshlib` on A/UX -> shlibs that MATCH his prebuilt
   clients.
2. Install those shlibs to `/shlib` + install his prebuilt `xterm`/`twm`/etc.
3. Run against XmacII. This is the end-to-end route the port author intended;
   it sidesteps the native-ld-too-small / GNU-ld-unloadable wall entirely
   (no client linking by us at all).
Alternative if a rebuild from his tree is undesirable: diff our shlib build vs
his to find the divergence and make our shlibs match his clients.

## Part 5 -- ROOT CAUSE FOUND: patchlevel mismatch (pl11 vs pl4)

Compared branch-table addresses of every common symbol between nleymann's
prebuilt import libs and our runtime shlibs (nm both, match symbol->address):

  X11:  common=963 mismatched=0    (compatible)
  Xext: common=84  mismatched=0    (compatible)
  Xmu:  common=95  mismatched=0    (compatible)
  Xaw:  common=423 mismatched=0    (compatible)
  ICE:  common=112 mismatched=53   (DRIFT)
  SM:   common=42  mismatched=5    (DRIFT)
  Xt:   common=486 mismatched=8    (DRIFT)

XOpenDisplay etc. are at IDENTICAL addresses (0x49f026c6) his vs ours -> libX11
is fine. The ICE drift is all `_Ice*` internal funcs with NON-constant deltas
(0xBA0, 0x1362, 0x1ED4, 0x55EC ...) = different compiled code, not an insertion.

ROOT CAUSE: we built from MIT X11R6 patchlevel 11 (/tmp/x11r6src) + nleymann's
A/UX patches; nleymann's prebuilt CLIENTS are patchlevel 4. The libs that did
NOT change pl4->pl11 (X11/Xext/Xmu/Xaw) match his xterm exactly; the ones that
WERE patched (ICE/SM/Xt = session-mgmt stack) drifted -> his xterm SIGSEGVs on
their wrong addresses.

FIX (narrow): rebuild ONLY ICE/SM/Xt from nleymann's OWN pl4 objects (inside his
static libICE.a/libSM.a/libXt.a, backed up at dist/nleymann/lib/) via mkshlib,
reusing the per-lib auxshlib.o/auxmemcpy.o + auxshlib.spec. Same objects -> same
layout -> addresses match his prebuilt xterm. Keep the other 4 shlibs as built.
Verify each rebuilt import lib matches his (e.g. libICE_s.a == 47280 bytes / same
branch addrs), then install all 7 to /shlib + his prebuilt clients, run xterm.
Best done on the QEMU guest (has the auxshlib build scaffolding + speed).

## Part 6 -- "rebuild from his objects" is blocked; the two real paths

Tried rebuilding ICE shlib from nleymann's pl4 objects (his libICE.a) via mkshlib
on the SE/30 (pushed his libICE.a + auxshlib.c/h + auxmemcpy.s + spec + the R6
include tree via the AGENT, tarball extracted with /usr/bin/tar). auxshlib.o
compiled fine, but mkshlib FAILED: "Undefined symbol malloc in accept.o not
defined in archive", and the rebuilt _IceAddOpcodeMapping landed at 49b0531a
(still != his 49b055c0).

ROOT REASON: his static libICE.a holds the UNSHARED objects (plain malloc). The
shlib needs objects compiled -DAUXSHLIB -DSHAREDCODE, where auxshlib.h redirects
malloc->_ICEptr_malloc. Those shared objects are build artifacts nleymann did
NOT ship, and his tarball has NO .c source. So his pl4 shlib cannot be
reproduced from the shipped artifacts.

THE TWO REMAINING REAL PATHS:
A. Get X11R6 patchlevel-4 SOURCE for ICE/SM/Xt (MIT base + patches 1-4), rebuild
   ONLY those 3 shlibs the shared way -> match his prebuilt clients. Keep the
   other 4 shlibs we already built (they match). Then install all 7 + his
   prebuilt xterm. (We have MIT base + applied through pl11; would need to build
   ICE/SM/Xt at pl4 instead.)
B. (cleaner, our own stack) Our 7 pl11 shlibs are internally consistent and
   loadable. The only reason native ld couldn't link OUR xterm against them was
   our libX11_s.a is bloated to 698K ("too many external symbols" for native ar)
   vs nleymann's clean 469K. If we rebuild our import libs WITHOUT the bloat
   (handle isascii/re-exports so the export table stays lean like his), native
   ld -- which DOES produce loadable A/UX shared execs -- can link our own xterm
   objects against our own pl11 libs. No pl4 dependency. Needs: find what
   inflated our libX11_s.a export set and slim it, then native-ld link xterm.

Recommendation: Path B. It uses our consistent stack + the native linker (proven
to make loadable binaries), and the blocker (import-lib bloat) is the same thing
that made nleymann's tools choke -- a scale issue we can likely fix by trimming
the export set to match his ~469K.

## Part 7 -- Plan B result: native ld links, but it converges on the pl-gap

Plan B: native-ld link xterm against [nleymann pl4 libX11_s.a (469K, the only
native-ar-friendly libX11 we have) + our 6 pl11 import libs]. RESULT:
- native ar indexed ALL these (incl the 469K libX11) - good.
- native ld + shlib.ld LINKED cleanly (xterm-native 536560, LINKRC=0, NO
  multiple-def -- native ld dedups the re-exports, unlike GNU ld). Linker SOLVED.
- but xterm-native SIGSEGVs at runtime (rc 139).

Isolation with a tiny program (main(){write(1,"START");XOpenDisplay(0);write("AFTER")}):
native-linked vs nleymann pl4 libX11_s.a, run vs our pl11 /shlib/libX11.6.0_s ->
prints "START" then SIGSEGV (no "AFTER"). So: binary starts, libc works, our
libX11.6.0_s LOADS, but the CALL into XOpenDisplay crashes.

CONVERGENCE: we had to link against nleymann's pl4 libX11_s.a because OUR pl11
libX11_s.a is too big for native ar ("too many external symbols"). The 963 code
symbols match pl4<->pl11, but DATA globals need not -- pl11 XOpenDisplay reading
a libX11 global at the pl4-resolved address = wrong addr = crash. Root: our pl11
libX11 is bigger (698K vs his 469K) because pl11 added i18n/locale code pl4 lacks
-- the same extra symbols that (a) bust native ar's limit and (b) make it
incompatible with his pl4 clients.

NET: native ld is the right linker. The single remaining blocker is that our pl11
libX11_s.a is too big for native ar, so we cannot native-link against our OWN
matched pl11 import lib (which would have correct data addrs). FIX = slim our
libX11_s.a to a native-ar-indexable export set (drop the i18n/locale exports
xterm doesn't use), then native-link our own xterm against our own pl11 stack ->
correct code+data addrs -> should load and run. (Alt: build libX11 at pl4.)

## Part 8 -- DEFINITIVE ROOT CAUSE: 8769 common symbols from missing `extern`

Why native ar/ld reject OUR libX11_s.a but accept nleymann's, at the SAME
A-symbol count (1456 each) and same junk-symbol count (~388 each):

external symbol totals (nm, A=absolute/exported, U=undef, C=common):
  his:  A=1456  U=3926  C=137      (~5519 total externals -> native ar/ld OK)
  ours: A=1456  U=3333  C=8769     (~13558 total externals -> "too many")

The 8769 commons are the `_X11ptr_*` indirection pointers: nm shows
`_X11ptr_strtol` declared COMMON in 375 separate members, `_X11ptr_strcmp` 375,
`_X11ptr_malloc` 372, ... (53 unique names x hundreds of members).

CAUSE: lib/X11/auxshlib.h `#define`s each libc call to `(*_X11ptr_foo)`, but for
the STRING/MEM functions (strtol,strcmp,strlen,strcpy,strcat,strncpy,strncmp,
strrchr,strpbrk,memset,memmove,...) there is NO matching `extern` declaration of
the pointer. So every object that includes auxshlib.h emits a TENTATIVE (common)
definition of `_X11ptr_strtol` etc. -> ~8500 commons. The non-string funcs
(malloc/free/socket/...) DO have `extern ... ();` lines (which the #define turns
into `extern <type>(*_X11ptr_x)();`) so they are single U refs. Nleymann's
auxshlib.h declared ALL of them extern -> 137 commons.

native ar/ld's "too many external symbols" / "symbol directory too large" is the
TOTAL external count (incl commons). His ~5.5k passes; our ~13.5k fails. THIS,
not symbol count or patchlevel, is why native tools can't link our libs and we
were forced onto GNU ld (whose output won't load) or nleymann's pl4 lib (data
mismatch).

THE FIX (clean, surgical): make all `_X11ptr_*` declarations `extern` in
auxshlib.h (add the missing extern lines for the string/mem funcs), so they
become single U refs resolved to auxshlib.o's one definition (not per-member
commons). Rebuild the shlibs (mkshlib) -> our import libs drop to ~his external
count -> native ar/ld accept them -> native-link our OWN xterm against our OWN
matched pl11 stack (correct code AND data addrs) -> loadable, should run.
This is a build-env change, best on the QEMU guest (has the full xc tree).
Same fix applies to ICE/SM/Xt/etc auxshlib.h if they have the same omission.

## Part 9 -- the commons can't be removed post-hoc; needs a real build fix

objcopy -N on all 63 _X11ptr_* names: rc=0 but commons UNCHANGED (still 8769).
Confirmed objcopy (2.10.1, m68kaux) cannot modify these A/UX COFF common (or
absolute) symbols -- same as -L/--weaken earlier. Post-hoc archive surgery is out.

Tried the build fix (add `extern void *_X11ptr_*;` block to auxshlib.h) -> FAILS:
the system headers (string.h/errno.h/memory.h, pulled via Xlibint.h) already
declare these via the #define macro as FUNCTION pointers, so a void* extern
conflicts ("conflicting types for _X11ptr_strcpy"). So the naive header fix is
wrong.

The 8769 commons live in the mkshlib-generated IMPORT-LIB stub members (nm -A
shows each hft* stub carries the _X11ptr_* commons). nleymann's mkshlib produced
137. So the difference is in how the SHARED objects were compiled / how mkshlib
propagated symbols -- a build-config detail of nleymann's port we have not yet
matched. Eliminating the commons requires replicating his exact build (the right
auxshlib.h + header include order so every shared object gets _X11ptr_* as a
single extern U-ref, not a per-member tentative common), then mkshlib.

STATUS: complete diagnosis, no working fix yet. Restored guest auxshlib.h + the
libX11 shlib/import from the Mac backup (the rebuild attempt had rm'd them).

## Part 10 -- SOLVED: split the import archive (2026-06-08)

THE FIX that worked: keep the runtime libX11.6.0_s WHOLE (all symbols + i18n at
their real addresses), but SPLIT THE IMPORT ARCHIVE libX11_s.a into 3 smaller
archives so each fits under native ar/ld's external-symbol limit:
  - ar t libX11_s.a -> 1 ttmp descriptor + 387 hft stub members
  - extract all, split the 387 into 3 groups (~129 each)
  - libX11a_s.a = ttmp(descriptor) + group1 ; libX11b_s.a = group2 ; libX11c_s.a = group3
  - /bin/ar ts each -> native ar rc=0 for all three (each well under the limit)
Link xterm with NATIVE ld (gcc -B.../, which uses /usr/lib/shlib.ld -> loadable
A/UX shared exec) against the 3 pieces + the other 6 import libs. Native ld is
single-pass, so the inter-piece cross-refs (Xcms color, HVC anchors) need the
3 pieces REPEATED several times on the link line: 
  -lXaw_s -lXmu_s -lXt_s -lSM_s -lICE_s -lXext_s
  -lX11a_s -lX11b_s -lX11c_s  (x4 repeated)
  -lXbsd -lposix -lm -lmr -ltermcap   (+ mm.o for raw memmove, + libc_s via gcc)

RESULT: LINKRC=0, xterm-own 536007 bytes, COFF paged exec. objdump -s -j .lib
shows it loads /shlib/{libXaw,libXmu,libXt,libSM,libICE,libXext,libX11}.6.0_s +
libc1_s -- our OWN matched pl11 stack. Run vs a bad display:
  "Xt error: Can't open display: 1.2.3.4:0"  (RUNRC=1)
i.e. it LOADS the shlibs, runs Xt init, and cleanly handles the display -- NO
crash. First working dynamic R6 xterm linked against our own R6 shlibs on A/UX.

No i18n exclusion, no stubs, no runtime-shlib change -- just split the import
archive + repeat on the link line. The "8769 commons / too many external
symbols" was a per-archive limit; splitting the archive sidesteps it entirely.

Staged at SE/30 /usr/bin/X11/xterm-r6 (setuid root for ptys). Backups on Mac:
dist/xterm/xterm-r6-dynamic (crc ede972b8), dist/x11split/libX11{a,b,c}_s.a.
NEXT: run it in a real X11 (XmacII) session on the SE/30 -> see the window;
also reveals whether R6's pty code avoids the R4 "no available ptys" EIO bug.
