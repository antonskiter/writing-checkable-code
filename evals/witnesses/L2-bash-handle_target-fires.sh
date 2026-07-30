#!/usr/bin/env bash
# L2 fires on bash/deploy.sh handle_target: an unrecognised target is routed to
# deploy_staging rather than refused.
cd "$(dirname "$0")/.." || exit 1
lib=$(mktemp); trap 'rm -f "$lib"' EXIT
head -n -1 bash/deploy.sh >"$lib"
out=$( . "$lib"; handle_target quux 2>&1 )
rc=$?
[ "$rc" = 0 ] && [ "$out" = "deploy: ok" ] || {
  printf 'handle_target quux -> rc=%s out=%s; expected a real case to answer it\n' "$rc" "$out"; exit 1; }
