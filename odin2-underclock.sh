#!/bin/bash
# Keeps the chosen underclock profile in force. konkrd (profile changes) and
# power_limits.py (Steam TDP slider) rewrite scaling_max_freq, so re-check every
# 2 s. Within a profile it only lowers the max, so a stricter TDP cap still wins;
# on a profile change it lifts to stock first, so a lighter profile takes effect.
. /etc/odin2-underclock.conf
POL=(0 3 7)

caps_for() {
    case $1 in
        small)  echo $SMALL ;;
        medium) echo $MEDIUM ;;
        large)  echo $LARGE ;;
        stock)  echo 0 0 0 ;;
    esac
}

last=
while :; do
    # The profile file is user-writable: only the four names are accepted.
    p=
    [ -f "$PROFILE_FILE" ] && read -r p < "$PROFILE_FILE"
    caps=($(caps_for "$p"))
    [ ${#caps[@]} -eq 3 ] || { p=$DEFAULT_PROFILE; caps=($(caps_for "$p")); }
    [ "$p" != "$last" ] && echo "profile $p (${caps[*]})"
    for i in 0 1 2; do
        d=/sys/devices/system/cpu/cpufreq/policy${POL[i]}
        [ -w "$d/scaling_max_freq" ] || continue
        cap=${caps[i]}
        [ "$cap" -gt 0 ] 2>/dev/null || cap=$(<"$d/cpuinfo_max_freq")
        [ "$p" != "$last" ] && cat "$d/cpuinfo_max_freq" > "$d/scaling_max_freq"
        [ "$(<"$d/scaling_max_freq")" -gt "$cap" ] && echo "$cap" > "$d/scaling_max_freq"
    done
    last=$p
    sleep 2
done
