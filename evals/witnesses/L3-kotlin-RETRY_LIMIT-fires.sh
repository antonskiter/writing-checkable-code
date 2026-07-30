#!/usr/bin/env bash
# L3 fires on kotlin/Ledger.kt RETRY_LIMIT: no entry point reaches it, deleting
# it rebuilds clean under kotlinc, and no other 3 in the tree states the fact it
# holds.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 || { printf 'kotlinc not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -r kotlin "$tmp/tree"
mapfile -t sources < <(find "$tmp/tree" -name '*.kt' | sort)

base=$(kotlinc "${sources[@]}" -d "$tmp/before" 2>&1)
[ -z "$base" ] || {
  printf 'the tree does not build clean before the deletion: %s\n' "$base"; exit 1; }

readers=$(grep -rn 'RETRY_LIMIT' "$tmp/tree") || {
  printf 'RETRY_LIMIT is not in the tree at all\n'; exit 1; }
[ "$(printf '%s\n' "$readers" | grep -c '')" = 1 ] || {
  printf 'RETRY_LIMIT is named more than once in the tree:\n%s\n' "$readers"; exit 1; }

grep -v 'RETRY_LIMIT' "$tmp/tree/Ledger.kt" >"$tmp/stripped" &&
  mv "$tmp/stripped" "$tmp/tree/Ledger.kt"

after=$(kotlinc "${sources[@]}" -d "$tmp/after" 2>&1) && [ -z "$after" ] || {
  printf 'deleting RETRY_LIMIT did not rebuild clean: %s\n' "$after"; exit 1; }

states3=$(grep -rnE '(^|[^[:alnum:]_])3([^[:alnum:]_]|$)' "$tmp/tree")
[ -z "$states3" ] || {
  printf 'the tree still states 3 elsewhere, so the fact has a second home:\n%s\n' "$states3"; exit 1; }
