#!/bin/sh
# split-import-archive.sh - split libX11_s.a into 3 archives that native ar/ld
# can index.  Run on A/UX with the GNU binutils (m68kaux) ar/ts available.
#
#   ar t libX11_s.a            -> 1 descriptor member + ~387 hft* stub members
#   split the 387 stubs into 3 groups (~129 each)
#   libX11a_s.a = descriptor + group1 ; libX11b_s.a = group2 ; libX11c_s.a = group3
#   /bin/ar ts each            -> native ar accepts each (well under its limit)
#
# This is a sketch of the procedure; see X11R6-BUILD-NOTES.md Part 10 for the
# exact member accounting.  The resulting libX11{a,b,c}_s.a are checked in
# under ../../dist/x11split/.
echo "See X11R6-BUILD-NOTES.md Part 10. Prebuilt split archives are in dist/x11split/."
