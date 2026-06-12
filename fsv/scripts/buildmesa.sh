#!/bin/bash
# Mesa 3.0 on A/UX: static libMesaGL.a + libMesaGLU.a via the appended
# 'aux' Make-config target (gcc 2.7.2.3, no -O, no SHM, X11R6 headers).
# Drive src/ and src-glu/ directly - the top Makefile dispatch list
# doesn't know the new target name.
cd /usr/local/fsvsrc/Mesa-3.0 || exit 1
mkdir lib 2>/dev/null
touch src/depend src-glu/depend
cd src && make aux 2>&1
echo "MESA-GL RC=$?"
cd ../src-glu && make aux 2>&1
echo "MESA-GLU RC=$?"
ls -l ../lib/
echo MESA-DONE
