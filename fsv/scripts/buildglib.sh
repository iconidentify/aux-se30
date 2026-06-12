#!/bin/bash
# glib 1.2.10 on A/UX: configure + make, static, no threads
cd /usr/local/fsvsrc/glib-1.2.10 || exit 1
CC="/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ -fpcc-struct-return"
export CC
CONFIG_SHELL=/bin/bash
export CONFIG_SHELL
/bin/bash ./configure --prefix=/usr/local/fd --disable-shared --enable-static --disable-threads 2>&1
echo "CONFIGURE RC=$?"
make 2>&1
echo "MAKE RC=$?"
make install 2>&1
echo "INSTALL RC=$?"
echo GLIB-BUILD-DONE
