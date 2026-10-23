#!/bin/bash
# Removes the underclock and restores stock CPU clocks:  sudo bash uninstall.sh
# Leaves this folder in place (delete it yourself if you like).
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo: sudo bash $0" >&2; exit 1; }
systemctl disable --now odin2-underclock.service 2>/dev/null
rm -f /etc/systemd/system/odin2-underclock.service /etc/odin2-underclock.sh \
      /etc/odin2-underclock.conf /etc/sudoers.d/zz-odin2-underclock
systemctl daemon-reload
rm -f "$(dirname "$(readlink -f "$0")")/profile"
for p in /sys/devices/system/cpu/cpufreq/policy*; do
    cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq"
    echo "$p cpus=$(cat $p/related_cpus) max=$(cat $p/scaling_max_freq)"
done
echo "Underclock removed. Remove any game-profile.sh launch options you set in Steam."
