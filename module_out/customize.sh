#!/system/bin/sh
KSUD=/data/adb/ksud
export KSU_MODULE=ksuGrantToast

checkSuLogEnabled() {
    v="$($KSUD feature get sulog 2>/dev/null | awk -F': *' '/^Value:/ {print $2; exit}')"
    [ "$v" = "1" ]
}

echo "Welcome"

if [ ! "$KSU" ]; then
    abort "This module only supports KernelSU Next!"
fi

# Kill old process if running
oldProcessPid=$(pidof SuToaster)
if [ "$oldProcessPid" ]; then
    echo "Killing old SuToaster process..."
    kill -9 "$oldProcessPid"
fi

# Check SuLog is enabled
if ! checkSuLogEnabled; then
    echo "WARNING:"
    echo "SU Log is not enabled!"
    echo "Please enable SU Log in your KernelSU Next manager"
    echo "before rebooting. This module requires SU Log."
    sleep 3
fi

echo "This module reads SU Log via file tail."
echo "The original Su Log remains fully readable."
echo "Compatible with KernelSU Next."
sleep 2

set_perm "$MODPATH/Shimizu" 0 0 0755
set_perm "$MODPATH/daemon.dex" 0 0 0755
set_perm "$MODPATH/sulog_mirror.sh" 0 0 0755
set_perm "$MODPATH/boot-completed.sh" 0 0 0755

"$KSUD" module config set --temp override.description "[Waiting reboot] Root grant toast for KSUN. Requires SU Log enabled."

echo "Installation successful!"
echo "Please reboot for changes to take effect"
