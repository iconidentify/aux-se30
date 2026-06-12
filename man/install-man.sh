#!/bin/sh
# install-man.sh - format and install the local man pages on A/UX.
# Run on the guest from the directory holding the nroff sources.
# Re-runnable; this is the recovery path if the catman copies are lost.
set -e
U=/usr/catman/u_man
mkdir $U/man7 2>/dev/null || true
for n in auxtop auxfont dialc auxagent auxfetch auxsaver bgroot \
         auxadmin resizewin dialc-x auxtop-x; do
    /bin/nroff -man $n.1 > /tmp/$n.cat
    /usr/ucb/compress -f /tmp/$n.cat
    cp /tmp/$n.cat.Z $U/man1/$n.1.Z
    rm -f /tmp/$n.cat.Z
    echo "installed $n(1)"
done
# rxvt.1 is yodl-generated and beyond the A/UX nroff; ship the
# pre-formatted rxvt.cat (mandoc -Tascii on the Mac) instead.
if [ -f rxvt.cat ]; then
    cp rxvt.cat /tmp/rxvt.cat
    /usr/ucb/compress -f /tmp/rxvt.cat
    cp /tmp/rxvt.cat.Z $U/man1/rxvt.1.Z
    rm -f /tmp/rxvt.cat.Z
    echo 'installed rxvt(1) (pre-formatted)'
fi
/bin/nroff -man aux.7 > /tmp/aux.cat
/usr/ucb/compress -f /tmp/aux.cat
cp /tmp/aux.cat.Z $U/man7/aux.7.Z
rm -f /tmp/aux.cat.Z
echo "installed aux(7)"
sync
