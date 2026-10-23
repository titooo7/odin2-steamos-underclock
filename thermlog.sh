#!/bin/bash
# Logs temps, fan, battery power and clocks every 2 s to a CSV, until Ctrl+C.
#   bash thermlog.sh [out.csv]      (default: /home/steamos/underclock/thermlog.csv)
# Summarize a time window afterwards with thermsummary.sh.
out=${1:-/home/steamos/underclock/thermlog.csv}
pf="$(dirname "$(readlink -f "$0")")/profile"
fan=$(grep -l '^pwmfan$' /sys/class/hwmon/hwmon*/name | head -1 | xargs dirname)
echo "time,svc,cpu_c,gpu_c,fan_rpm,pwm,batt_w,mid_mhz,prime_mhz,gpu_mhz" > "$out"
mx(){ m=0; for z in /sys/class/thermal/thermal_zone*; do case $(<$z/type) in $1) t=$(<$z/temp); [ $t -gt $m ] && m=$t;; esac; done; echo $((m/1000)); }
while :; do
  echo "$(date +%T),$(systemctl is-active odin2-underclock)/$(cat "$pf" 2>/dev/null || echo default),$(mx 'cpu[0-7]-*'),$(mx 'gpuss-*'),$(<$fan/fan1_input),$(<$fan/pwm1),$(awk '{printf "%.2f",$1/1e6}' /sys/class/power_supply/battery/power_now),$(( $(</sys/devices/system/cpu/cpufreq/policy3/scaling_cur_freq)/1000 )),$(( $(</sys/devices/system/cpu/cpufreq/policy7/scaling_cur_freq)/1000 )),$(( $(</sys/class/devfreq/3d00000.gpu/cur_freq)/1000000 ))" >> "$out"
  sleep 2
done
