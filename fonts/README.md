# A/UX desktop fonts

## ProFont (installed 2026-06-11)

ProFont - the classic Mac programmer's font - installed on the QEMU
guest as SNF (the A/UX XmacII server is R4-era: SNF only, no PCF).
Server dir: /usr/lib/X11/fonts/profont (BDF sources + compiled SNF +
fonts.dir + fonts.alias). Aliases: profont10/11/12/15/17/22/29.
Font path added live (xset fp+) and persisted in /.x11start.

Pipeline: tobiasjung.name profont-x11.zip ships PCF only ->
pcf2bdf (github.com/ganaware/pcf2bdf, built on the Mac) ->
auxctl put -> /usr/bin/X11/bdftosnf -> mkfontdir + fonts.alias.
BDF sources mirrored in profont/ here.

ProFont has a single weight: rxvt bold renders via Rxvt*colorBD
(synthwave pink) instead of overstrike, which is the right look at
1-bit anyway.

## auxfont - one-shot font theme switcher

/usr/local/bin/auxfont on the guest (source mirrored here) rewrites
every font consumer in one go:

    auxfont profont        # terminals profont15, chrome profont12
    auxfont profont-big    # terminals profont17
    auxfont profont-small  # terminals profont12
    auxfont fixed          # back to 7x13 / lucidatypewriter

Touches: /.Xdefaults (Rxvt*/XTerm* font+boldFont), /.fvwmrc (Font,
WindowFont, every -fn in Exec lines), /usr/local/bin/auxtop-x and
dialc-x launchers, /.gtkrc (style font XLFD). Runs xrdb -merge and
sync (A/UX crashes can revert unsynced writes). Restart fvwm from the
logout menu and open new terminals to see the change.

Adding a font: drop BDFs in a server dir, bdftosnf, mkfontdir,
fonts.alias, xset fp rehash, then add a theme case to auxfont.
