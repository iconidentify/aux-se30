#!/bin/sh
# install.sh - install auxagent as a boot-persistent service on an A/UX host.
#
# Run this AS ROOT on the target machine (the QEMU build guest or the SE/30).
# It is idempotent: safe to run more than once.
#
# What it does:
#   1. Verifies the auxagent binary is in place.
#   2. Adds an /etc/inittab "respawn" entry so the agent starts at every boot
#      AND is automatically restarted by init if it ever exits or crashes.
#   3. Stops any manually-launched instance and re-reads inittab (telinit q) so
#      init takes over the canonical instance immediately - no reboot needed.
#   4. Verifies exactly one instance is running.
#
# The binary does NOT need to be compiled on the target. A/UX 68k binaries are
# portable across machines, so you can build once on the QEMU guest (which has
# the gcc-2.7.2.3 toolchain) and copy /usr/local/auxagent to the SE/30, then run
# this script there. See README "Installing on the SE/30".
#
# usage: install.sh [AGENT_PORT] [AAP_TOKEN]
#   AGENT_PORT  TCP port to listen on              (default 8377)
#   AAP_TOKEN   if set, baked into the boot entry so every request must carry a
#               matching X-Aap-Token header        (default: none, open on LAN)

AP=${1:-8377}
TOKEN=${2:-}
BIN=/usr/local/auxagent
LOG=/usr/local/auxagent.log
INITTAB=/etc/inittab
ID=ax

if [ ! -x "$BIN" ]; then
    echo "error: $BIN not found or not executable." >&2
    echo "  Build it first with install/bootstrap.sh, or copy a prebuilt" >&2
    echo "  /usr/local/auxagent here from another A/UX box." >&2
    exit 1
fi

# Make the admin/settings helper executable if it was placed alongside the
# agent (auxctl admin ... drives it remotely). Non-fatal if absent.
if [ -f /usr/local/auxadmin ]; then
    chmod +x /usr/local/auxadmin
    echo "auxadmin: installed (try: auxctl admin <host:port> list)"
fi

# Compose the command init will run. A token, if given, is set as an
# environment variable in front of the binary (inittab runs the line via sh).
if [ -n "$TOKEN" ]; then
    CMD="AAP_TOKEN=$TOKEN $BIN $AP >>$LOG 2>&1"
else
    CMD="$BIN $AP >>$LOG 2>&1"
fi

# 1. boot persistence -------------------------------------------------------
if grep "auxagent" $INITTAB > /dev/null 2>&1; then
    echo "inittab: an auxagent entry already exists - leaving it unchanged."
    echo "         (edit $INITTAB by hand to change the port or token.)"
else
    cp $INITTAB $INITTAB.bak.auxagent
    echo "$ID:2:respawn:$CMD" >> $INITTAB
    echo "inittab: added respawn entry (backup saved to $INITTAB.bak.auxagent)."
fi

# 2. stop any hand-launched instance so init owns the only copy --------------
for p in `ps -e | grep auxagent | grep -v grep | awk '{print $1}'`; do
    kill -9 $p 2>/dev/null
done
sleep 2

# 3. activate now (no reboot) ------------------------------------------------
if [ -x /etc/telinit ]; then
    /etc/telinit q
elif [ -x /sbin/telinit ]; then
    /sbin/telinit q
else
    echo "telinit not found - auxagent will start on the next reboot."
fi
sleep 5

# 4. verify -----------------------------------------------------------------
N=`ps -e | grep auxagent | grep -v grep | wc -l`
echo "running auxagent instances: $N"
ps -e | grep auxagent | grep -v grep
if [ "$N" -lt 1 ]; then
    echo "warning: agent not up yet; launching directly as a fallback."
    nohup $BIN $AP >> $LOG 2>&1 &
fi

echo ""
echo "done. auxagent is installed for boot and managed by init (respawn)."
echo "test it from your Mac:  curl http://<this-host>:$AP/ping"
