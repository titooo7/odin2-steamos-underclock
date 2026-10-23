#!/bin/bash
# Averages of a thermlog.sh CSV between two times (HH:MM:SS, the Odin 2's clock).
#   bash thermsummary.sh thermlog.csv 22:10:00 22:13:00
awk -F, -v s="$2" -v e="$3" 'NR>1 && $1>=s && $1<=e {
    n++; c+=$3; g+=$4; f+=$5; w+=$7; m+=$8; p+=$9
    if ($3>mc) mc=$3; if ($4>mg) mg=$4 }
  END { if (!n) { print "no rows in that window"; exit 1 }
    printf "%d samples: CPU %.1f C (peak %d), GPU %.1f C (peak %d), fan %.0f rpm, power %.2f W, mid %.0f MHz, prime %.0f MHz\n",
      n, c/n, mc, g/n, mg, f/n, w/n, m/n, p/n }' "$1"
