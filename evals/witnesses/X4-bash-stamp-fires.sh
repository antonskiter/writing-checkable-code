#!/usr/bin/env bash
# X4 fires on bash/deploy.sh stamp: it embeds the clock, so two runs differ.
cd "$(dirname "$0")/.." || exit 1
lib=$(mktemp); trap 'rm -f "$lib"' EXIT
head -n -1 bash/deploy.sh >"$lib"
a=$( . "$lib"; stamp x )
sleep 1.1
b=$( . "$lib"; stamp x )
[ "$a" != "$b" ] || { printf 'stamp x gave %s twice; X4 would be silent\n' "$a"; exit 1; }
