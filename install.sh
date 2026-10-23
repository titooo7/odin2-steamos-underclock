#!/bin/bash
set -e
cd "$(dirname "$0")"
# Only for the Snapdragon 8 Gen 2 (SM8550) Odin 2 family on SteamOS: the
# profile values are this chip's clock steps.
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo: sudo bash $0" >&2; exit 1; }
grep -qa 'qcom,sm8550' /proc/device-tree/compatible 2>/dev/null \
    || { echo "Not a Snapdragon 8 Gen 2 (SM8550) device, stopping." >&2; exit 1; }
for n in 0 3 7; do
    [ -w /sys/devices/system/cpu/cpufreq/policy$n/scaling_max_freq ] \
        || { echo "CPU cluster policy$n not found, stopping." >&2; exit 1; }
done
grep -q '^ID=steamos' /etc/os-release || echo "Warning: this doesn't look like SteamOS; continuing anyway." >&2
# The chosen profile lives in this folder, so the user can switch without sudo.
sed "s|^PROFILE_FILE=.*|PROFILE_FILE=$PWD/profile|" odin2-underclock.conf > /etc/odin2-underclock.conf
chmod 644 /etc/odin2-underclock.conf
install -m755 odin2-underclock.sh /etc/odin2-underclock.sh
install -m644 odin2-underclock.service /etc/systemd/system/odin2-underclock.service
# Password-free stop/start for underclock-on/off.sh, for the user running sudo.
tmp=$(mktemp)
sed "s/^steamos /${SUDO_USER:-steamos} /" odin2-underclock.sudoers > "$tmp"
visudo -cf "$tmp"
# zz- so it loads last: sudo uses the last matching rule, and the stock
# "(ALL) ALL" rule for the user would otherwise win and ask for a password.
install -m440 "$tmp" /etc/sudoers.d/zz-odin2-underclock
rm -f /etc/sudoers.d/odin2-underclock
rm -f "$tmp"
chmod 755 underclock-profile.sh game-profile.sh underclock-on.sh underclock-off.sh thermlog.sh thermsummary.sh
rm -f stock-clocks.sh   # replaced by game-profile.sh stock
systemctl daemon-reload
systemctl enable odin2-underclock.service
systemctl restart odin2-underclock.service
sleep 3
for p in /sys/devices/system/cpu/cpufreq/policy*; do echo "$p cpus=$(cat $p/related_cpus) max=$(cat $p/scaling_max_freq)"; done
