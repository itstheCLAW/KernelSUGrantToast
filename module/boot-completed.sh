#!/system/bin/sh
KSUD=/data/adb/ksud
export KSU_MODULE=ksuGrantToast

# Create working directory for su-toast
mkdir -p /data/local/tmp/su-toast

customToastText="$($KSUD module config get customToastText 2>/dev/null)"
ignoredPackages="$($KSUD module config get ignorePackageNames 2>/dev/null)"
packageSearchDepth="$($KSUD module config get packageSearchDepth 2>/dev/null)"
autoDeleteLog="$($KSUD module config get autoDeleteLog 2>/dev/null)"
experimentalSettingHotUpdate="$($KSUD module config get experimentalSettingHotUpdate 2>/dev/null)"

# Default packageSearchDepth to 1 if not set
if [ -z "$packageSearchDepth" ]; then
    packageSearchDepth="1"
fi

# Create IPC pipe if hot update enabled
if [ "$experimentalSettingHotUpdate" = "true" ]; then
    rm -f /data/adb/toast_ipc
    mkfifo /data/adb/toast_ipc
else
    rm -f /data/adb/toast_ipc
fi

exec /system/bin/app_process -Djava.class.path=./daemon.dex / --nice-name=SuToaster com.suisho.kernelsugranttoast.Entry "$customToastText" "$ignoredPackages" "$packageSearchDepth" "$autoDeleteLog"
