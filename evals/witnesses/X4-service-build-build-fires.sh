#!/usr/bin/env bash
# X4 fires on service/build.py build.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src"
printf 'a\n' >"$tmp/src/a.txt"
printf 'b\n' >"$tmp/src/b.txt"

build() { (cd service && PYTHONDONTWRITEBYTECODE=1 python3 -c \
  'import sys, build; print(",".join(build.build(sys.argv[1], sys.argv[2])))' "$@" 2>&1); }
build "$tmp/src" "$tmp/reused" >/dev/null || { printf 'the first build failed\n'; exit 1; }
rm "$tmp/src/b.txt"
reused=$(build "$tmp/src" "$tmp/reused")
fresh=$(build "$tmp/src" "$tmp/fresh")
[ "$fresh" = a.txt ] || { printf 'a build into an empty location gave %s\n' "$fresh"; exit 1; }
[ "$reused" != "$fresh" ] || {
  printf 'both builds gave %s, so the earlier output does not survive\n' "$fresh"; exit 1; }
