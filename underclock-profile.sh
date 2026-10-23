#!/bin/bash
# Choose the underclock profile (no password needed; kept across reboots):
#   underclock-profile.sh small|medium|large|stock
# Without an argument, shows the current profile and CPU caps.
f="$(dirname "$(readlink -f "$0")")/profile"
case $1 in
    small|medium|large|stock)
        echo "$1" > "$f"
        sleep 3 ;;
    "") ;;
    *) echo "usage: $0 small|medium|large|stock" >&2; exit 1 ;;
esac
echo "profile: $(cat "$f" 2>/dev/null || echo "default ($(. /etc/odin2-underclock.conf; echo $DEFAULT_PROFILE))")"
echo "service: $(systemctl is-active odin2-underclock)"
for n in 0 3 7; do
    echo "policy$n max: $(( $(</sys/devices/system/cpu/cpufreq/policy$n/scaling_max_freq) / 1000 )) MHz"
done
