#!/bin/sh
# link-xterm.sh - link the R6 xterm against our own R6 shared libraries on A/UX.
#
# THE KEY TRICK (see ../../X11R6-BUILD-NOTES.md Part 10): native A/UX ar/ld
# choke on our full libX11_s.a ("too many external symbols"), so the import
# archive is SPLIT into three pieces (libX11a_s.a / libX11b_s.a / libX11c_s.a),
# each under the limit.  Native ld is single-pass, so the three pieces are
# repeated 4x on the link line to resolve the inter-piece cross-references
# (Xcms colour, HVC anchors).  Native ld (driven by gcc -B.../, which uses
# /usr/lib/shlib.ld) is the ONLY linker that produces a loadable A/UX shared
# executable -- GNU ld links it but the result will not load the shlibs.
#
# Expects in the current dir: the 15 xterm .o files + main.o + mm.o
# Expects in $LIBDIR: the 6 other import libs + libX11{a,b,c}_s.a + libXbsd.a
set -e
LIBDIR=${1:-/tmp/linklib}
gcc=/usr/local/gcc-2.7.2.3/gcc
rm -f xterm-own
$gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return -o xterm-own \
  TekPrsTbl.o Tekproc.o VTPrsTbl.o button.o charproc.o cursor.o data.o \
  input.o main.o menu.o misc.o screen.o scrollbar.o tabs.o util.o mm.o \
  -L"$LIBDIR" \
  -lXaw_s -lXmu_s -lXt_s -lSM_s -lICE_s -lXext_s \
  -lX11a_s -lX11b_s -lX11c_s -lX11a_s -lX11b_s -lX11c_s \
  -lX11a_s -lX11b_s -lX11c_s -lX11a_s -lX11b_s -lX11c_s \
  -lXbsd -lposix -lm -lmr -ltermcap
ls -l xterm-own
