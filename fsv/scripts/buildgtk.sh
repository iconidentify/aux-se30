#!/bin/bash
# GTK+ 1.2.10 on A/UX: static, no shm, no nls, against /usr/local/fd glib
# CFLAGS deliberately empty: gcc -O2 on big files wedges the -m128 guest
cd /usr/local/fsvsrc/gtk+-1.2.10 || exit 1
CC="/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return"
export CC
CFLAGS=" "
export CFLAGS
CONFIG_SHELL=/bin/bash
export CONFIG_SHELL
PATH=/usr/local/fd/bin:$PATH
export PATH
# libauxcompat supplies memmove/setlocale/strdup/strcasecmp etc that the
# R6 static libX11.a references but A/UX libc lacks. ABSOLUTE PATH:
# A/UX native ld can't find it via -L/-l (quirk), explicit path works.
LIBS="/usr/local/fd/lib/libauxcompat.a"
export LIBS
/bin/bash ./configure --prefix=/usr/local/fd \
  --disable-shared --enable-static \
  --with-glib-prefix=/usr/local/fd \
  --disable-shm --disable-nls \
  --with-x \
  --x-includes=/usr/local/X11R6/include \
  --x-libraries=/usr/local/X11R6/lib 2>&1
echo "CONFIGURE RC=$?"
make 2>&1
echo "MAKE RC=$?"
make install 2>&1
echo "INSTALL RC=$?"
echo GTK-DONE
