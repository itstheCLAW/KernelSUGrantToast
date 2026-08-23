#!/system/bin/sh

GREP=/data/data/com.termux/files/usr/bin/grep
KSUD=/data/adb/ksud
SCRIPT=/data/adb/modules/ksuGrantToast/sulog_mirror.sh
LOGDIR=/data/adb/ksu/log
mkdir -p /data/adb/su-toast
sleep 15

# Wait for package manager to be ready
while true; do
    result=$(cmd package list packages -U 2>/dev/null)
    if echo "$result" | grep -q "^package:"; then
        echo "$result" > /data/adb/su-toast/pkglist.txt
        break
    fi
    sleep 2
done

# Find the most recently modified sulog file
# If date has changed since boot, wait for today's log file
TODAY=$(date +%Y-%m-%d)
LOGFILE=$(ls -t $LOGDIR/sulog-*.log 2>/dev/null | head -1)
if [ -z "$LOGFILE" ] || ! echo "$LOGFILE" | grep -q "$TODAY"; then
    # Wait for today's log file to appear
    while [ -z "$(ls $LOGDIR/sulog-$TODAY*.log 2>/dev/null)" ]; do
        sleep 60
    done
    LOGFILE=$(ls -t $LOGDIR/sulog-$TODAY*.log 2>/dev/null | head -1)
fi

# Start tail in background and track PID
tail -F "$LOGFILE" | while read line; do
    case "$line" in
        *type=sucompat*) ;;
        *) continue ;;
    esac
    case "$line" in
        *comm=\"busybox\"*|*comm=\"sh\"*|*comm=\"grep\"*|*comm=\"awk\"*|*comm=\"cat\"*|*comm=\"head\"*|*comm=\"tail\"*|*comm=\"tr\"*) continue ;;
    esac

    pkg=""
    uid="${line#*uid=}"
    uid="${uid%% *}"

    if [ -n "$uid" ] && [ "$uid" != "0" ]; then
        pkg=$($GREP "uid:$uid" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+')
    else
        case "$line" in
            *file=\"/system/bin/su\"*) ;;
            *) continue ;;
        esac

        comm="${line#*comm=\"}"
        comm="${comm%%\"*}"

        case "$comm" in
            sh|busybox|grep|awk|cat|head|tail|tr|init|zygote*) continue ;;
        esac

        ppid="${line#*ppid=}"
        ppid="${ppid%% *}"

        case "$comm" in
            DefaultDispatch|Thread*|BROWSE*|pool-*|bash)
                if [ -n "$ppid" ]; then
                    cmdline=$(cat /proc/$ppid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}')
                    if [ -n "$cmdline" ]; then
                        case "$cmdline" in
                            /data/data/*)
                                cmdline="${cmdline#/data/data/}"
                                cmdline="${cmdline%%/*}"
                                ;;
                        esac
                        pkg=$($GREP "^package:$cmdline" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+' | head -1)
                    fi
                fi
                ;;
            *)
                pkg=$($GREP "$comm" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+' | head -1)
                ;;
        esac
    fi

    [ -z "$pkg" ] && continue

    case "$pkg" in
        *.addon.*)
            basepkg="${pkg%%.addon.*}"
            base=$($GREP "^package:$basepkg " /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+' | head -1)
            [ -n "$base" ] && pkg="$base"
            ;;
    esac

    case "$pkg" in
        android|com.android.*) continue ;;
    esac

    ignored=$($KSUD module config get ignorePackageNames 2>/dev/null)
    [ -n "$ignored" ] && echo "$ignored" | $GREP -q "$pkg" && continue

    last=$(cat /data/adb/su-toast/lastsu.txt 2>/dev/null)
    lastime=$(cat /data/adb/su-toast/lasttime.txt 2>/dev/null)
    now=$(date +%s)
    if [ "$pkg" = "$last" ] && [ -n "$lastime" ] && [ $((now - lastime)) -lt 3 ]; then
        continue
    fi
    echo "$pkg" > /data/adb/su-toast/lastsu.txt
    echo "$now" > /data/adb/su-toast/lasttime.txt
done &
TAIL_PID=$!

# Watch for date change and new log files
START_DATE=$(date +%Y-%m-%d)
while true; do
    NOW_DATE=$(date +%Y-%m-%d)
    if [ "$NOW_DATE" != "$START_DATE" ]; then
        pkill -f "tail -F $LOGFILE" 2>/dev/null
        exec sh $SCRIPT
    fi
    NEWEST=$(ls -t $LOGDIR/sulog-*.log 2>/dev/null | head -1)
    if [ "$NEWEST" != "$LOGFILE" ]; then
        pkill -f "tail -F $LOGFILE" 2>/dev/null
        exec sh $SCRIPT
    fi
    sleep 30
done &
