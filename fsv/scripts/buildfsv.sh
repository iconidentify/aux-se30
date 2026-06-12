#!/bin/bash
# fsv 0.9 against the /usr/local/fd stack (glib, gtk, gtkglarea, Mesa)
cd /usr/local/fsvsrc/fsv-0.9 || exit 1
CC="/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return"
export CC
CFLAGS=" "
export CFLAGS
CONFIG_SHELL=/bin/bash
export CONFIG_SHELL
PATH=/usr/local/fd/bin:$PATH
export PATH
LDFLAGS="-L/usr/local/fd/lib -L/usr/local/X11R6/lib"
export LDFLAGS
# single-pass ld: -lMesaGL comes after -lX11 in configure's test links,
# so repeat the X libs (and compat for their memmove/setlocale) at the
# very end - same trick as the micropolis x4-repeat link recipe
LIBS="-lacomp -lXext -lX11 -lacomp"
export LIBS
/bin/bash ./configure --prefix=/usr/local/fd \
  --disable-nls \
  --with-gtk-prefix=/usr/local/fd \
  --with-GL-prefix=/usr/local/fd \
  --with-lib-MesaGL 2>&1
echo "CONFIGURE RC=$?"
make 2>&1
echo "MAKE RC=$?"
echo FSV-DONE
