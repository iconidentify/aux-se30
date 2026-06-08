#!/bin/sh
# bootstrap.sh - run this ON an A/UX target to install & launch auxagent.
#
# Prerequisites on the target:
#   - gcc at /usr/local/gcc-2.7.2.3 (the modernized A/UX toolchain)
#   - /usr/local/httpget (the tiny HTTP-GET client; see README "Bootstrapping
#     the bootstrapper") OR another way to fetch the three source files.
#   - A host (your Mac) running `python3 -m http.server <HTTP_PORT>` whose
#     document root contains aap.h, aap.c, auxagent.c.
#
# usage: bootstrap.sh [MAC_IP] [HTTP_PORT] [AGENT_PORT]
set -e
MAC=${1:-10.1.1.108}
HP=${2:-8000}
AP=${3:-8377}
HG=/usr/local/httpget
GCC=/usr/local/gcc-2.7.2.3/gcc

echo "auxagent bootstrap: source=$MAC:$HP agent-port=$AP"

$HG $MAC $HP /aap.h       /usr/local/aap.h
$HG $MAC $HP /aap.c       /usr/local/aap.c
$HG $MAC $HP /auxagent.c  /usr/local/auxagent.c
$HG $MAC $HP /auxadmin    /usr/local/auxadmin || echo "note: auxadmin not fetched (optional)"

$GCC -B/usr/local/gcc-2.7.2.3/ -o /usr/local/auxagent \
     /usr/local/auxagent.c /usr/local/aap.c -lbsd
echo "compile rc=$?"

# install as a boot-persistent, init-managed service (and start it now).
# install.sh is expected alongside this script; fall back to a plain launch
# if it is not present.
HERE=`dirname $0`
if [ -f "$HERE/install.sh" ]; then
    sh "$HERE/install.sh" $AP
else
    echo "install.sh not found next to bootstrap.sh; launching directly."
    if [ -f /usr/local/auxagent.pid ]; then
        kill -9 `cat /usr/local/auxagent.pid` 2>/dev/null || true
    fi
    nohup /usr/local/auxagent $AP > /usr/local/auxagent.log 2>&1 &
    echo $! > /usr/local/auxagent.pid
    sleep 1
    echo "auxagent launched, pid=`cat /usr/local/auxagent.pid`"
fi
echo "log: /usr/local/auxagent.log"
