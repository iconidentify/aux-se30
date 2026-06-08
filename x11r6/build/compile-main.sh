#!/bin/sh
# compile-main.sh - compile the patched xterm main.c on the A/UX build guest.
#
# Run on the QEMU A/UX guest (or the SE/30) where gcc 2.7.2.3 is installed.
# The trailing slash on -B is MANDATORY: it forces gcc to use the bundled
# GNU assembler instead of /bin/as (native as rejects the generated code with
# "invalid instruction name").  -fpcc-struct-return matches the X ABI the
# prebuilt libX11 was compiled with.  -O2 for production; use -O0 to avoid
# thrashing a 128MB guest.
set -e
SRC=${1:-main.c}
gcc=/usr/local/gcc-2.7.2.3/gcc
$gcc -B/usr/local/gcc-2.7.2.3/ -pipe -fpcc-struct-return -c -O2 \
     -I/usr/local/X11R6/include \
     -DmacII -DSYSV -DUTMP -DOSMAJORVERSION=3 -DOSMINORVERSION=0 \
     "$SRC"
