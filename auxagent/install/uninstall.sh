#!/bin/sh
# uninstall.sh - remove the auxagent boot service from an A/UX host.
#
# Run AS ROOT on the target. Removes the /etc/inittab respawn entry, re-reads
# inittab so init stops respawning the agent, and kills the running instance.
# Leaves the binary and source in /usr/local in place.

INITTAB=/etc/inittab

if grep "auxagent" $INITTAB > /dev/null 2>&1; then
    cp $INITTAB $INITTAB.bak.uninstall
    # write every line that does NOT mention auxagent back out
    grep -v "auxagent" $INITTAB > $INITTAB.new && mv $INITTAB.new $INITTAB
    echo "inittab: removed auxagent entry (backup at $INITTAB.bak.uninstall)."
else
    echo "inittab: no auxagent entry found."
fi

# re-read inittab so init stops managing/respawning the agent
if [ -x /etc/telinit ]; then
    /etc/telinit q
elif [ -x /sbin/telinit ]; then
    /sbin/telinit q
fi
sleep 3

# kill any remaining instance
for p in `ps -e | grep auxagent | grep -v grep | awk '{print $1}'`; do
    kill -9 $p 2>/dev/null
done

echo "auxagent boot service removed. running instances now:"
ps -e | grep auxagent | grep -v grep
echo "(none above = fully stopped)"
