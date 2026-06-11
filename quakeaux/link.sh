#!/bin/sh
# link.sh - link quake.x11 against our X11R6 shared libs.
# Native single-pass ld + split libX11 import archive (Micropolis recipe):
# repeat the three libX11 pieces x4 so cross-refs resolve.
cd /usr/local/quakesrc || exit 1
CC=/usr/local/gcc-2.7.2.3/gcc
XS="-lXext_s -lX11a_s -lX11b_s -lX11c_s"
$CC -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -o quake.x11 \
	*.o \
	-L/tmp/linklib \
	$XS $XS $XS $XS \
	-lXbsd -lposix -lm -lmr
echo "LINK RC=$?"
ls -l quake.x11 2>/dev/null
