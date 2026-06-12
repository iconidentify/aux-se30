#!/bin/bash
# Install Mesa into /usr/local/fd, then build gtkglarea 1.2.3 against
# GTK + MesaGL. Same conventions: static, no -O, libacomp for the
# missing libc symbols (short name - ld's -l breaks on long names).
cp /usr/local/fsvsrc/Mesa-3.0/lib/libMesaGL.a /usr/local/fd/lib/
cp /usr/local/fsvsrc/Mesa-3.0/lib/libMesaGLU.a /usr/local/fd/lib/
if [ ! -d /usr/local/fd/include/GL ]
then
	mkdir -p /usr/local/fd/include
	cp -r /usr/local/fsvsrc/Mesa-3.0/include/GL /usr/local/fd/include/GL
fi
cd /usr/local/fsvsrc/gtkglarea-1.2.3 || exit 1
CC="/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return"
export CC
CFLAGS=" "
export CFLAGS
CONFIG_SHELL=/bin/bash
export CONFIG_SHELL
PATH=/usr/local/fd/bin:$PATH
export PATH
LDFLAGS="-L/usr/local/fd/lib"
export LDFLAGS
LIBS="-lacomp"
export LIBS
/bin/bash ./configure --prefix=/usr/local/fd \
  --disable-shared --enable-static \
  --with-gtk-prefix=/usr/local/fd \
  --with-GL-prefix=/usr/local/fd \
  --with-lib-MesaGL 2>&1
echo "CONFIGURE RC=$?"
make 2>&1
echo "MAKE RC=$?"
make install 2>&1
echo "INSTALL RC=$?"
echo GLAREA-DONE
