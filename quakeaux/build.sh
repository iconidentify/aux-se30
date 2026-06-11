#!/bin/sh
# build.sh - compile all Quake objects on the A/UX guest.
# Resume-safe: skips any .c whose .o already exists (no make: the guest
# RTC jumps backward across restarts and breaks make's timestamp logic).
# No -O: optimization thrashes the guest (X11R6 build lesson).
cd /usr/local/quakesrc || exit 1
CC=/usr/local/gcc-2.7.2.3/gcc
CFLAGS="-B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -I. -I/usr/local/X11R6/include"
FAILED=""
for f in *.c
do
	b=`basename $f .c`
	if [ -f $b.o ]
	then
		continue
	fi
	echo "CC $f"
	$CC $CFLAGS -c $f
	if [ ! -f $b.o ]
	then
		FAILED="$FAILED $f"
		echo "FAILED: $f"
	fi
done
echo "BUILD DONE failed:[$FAILED]"
