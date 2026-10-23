#!/bin/bash
# Per-game underclock profile. Steam > game > Properties > Launch options:
#   /home/steamos/underclock/game-profile.sh large %command%
# (small, medium, large or stock). The previous profile comes back when the game exits.
f="$(dirname "$(readlink -f "$0")")/profile"
case $1 in
    small|medium|large|stock) p=$1; shift ;;
    *)  # Unknown profile: run the game unchanged (skipping the bad word, if any).
        echo "usage: $0 small|medium|large|stock command..." >&2
        [ -x "$1" ] && exec "$@"
        shift; exec "$@" ;;
esac
prev=$(cat "$f" 2>/dev/null)
echo "$p" > "$f"
trap 'if [ -n "$prev" ]; then echo "$prev" > "$f"; else rm -f "$f"; fi' EXIT
trap 'kill -TERM "$pid" 2>/dev/null' TERM INT HUP
"$@" &
pid=$!
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; done
