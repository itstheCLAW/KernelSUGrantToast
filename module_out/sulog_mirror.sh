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

# Watch clock and restart at midnight
while true; do
    NOW=$(date +%H:%M)
    if [ "$NOW" = "00:00" ]; then
        exec sh $SCRIPT
    fi
    sleep 30
done &

# Find the most recently modified sulog file
LOGFILE=$(ls -t $LOGDIR/sulog-*.log 2>/dev/null | head -1)
if [ -z "$LOGFILE" ]; then
    LOGFILE=$LOGDIR/sulog-$(date +%Y-%m-%d).log
fi

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
        # KSUN style - uid is the app uid
        pkg=$($GREP "uid:$uid" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+')
    else
        # ReSukiSU style - only process real su calls
        case "$line" in
            *file=\"/system/bin/su\"*) ;;
            *) continue ;;
        esac

        # Extract comm value
        comm="${line#*comm=\"}"
        comm="${comm%%\"*}"

        # Skip system/shell comms
        case "$comm" in
            sh|busybox|grep|awk|cat|head|tail|tr|init|zygote*) continue ;;
        esac

        # Extract ppid
        ppid="${line#*ppid=}"
        ppid="${ppid%% *}"

        case "$comm" in
            DefaultDispatch|Thread*|BROWSE*|pool-*|bash)
                # Generic thread name or bash - use ppid lookup
                if [ -n "$ppid" ]; then
                    cmdline=$(cat /proc/$ppid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}')
                    if [ -n "$cmdline" ]; then
                        # If cmdline is a path under /data/data/, extract package name
                        case "$cmdline" in
                            /data/data/*)
                                # Extract package name from path /data/data/PKGNAME/...
                                cmdline="${cmdline#/data/data/}"
                                cmdline="${cmdline%%/*}"
                                ;;
                        esac
                        pkg=$($GREP "^package:$cmdline" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+' | head -1)
                    fi
                fi
                ;;
            *)
                # Try comm as partial package name
                pkg=$($GREP "$comm" /data/adb/su-toast/pkglist.txt | $GREP -oP 'package:\K\S+' | head -1)
                ;;
        esac
    fi

    [ -z "$pkg" ] && continue

    # If pkg is an addon, use base package instead
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
