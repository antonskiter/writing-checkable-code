#!/usr/bin/env bash
# S1 stays silent on service/paths.py default_dir.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.service"

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - "$tmp" <<'RUN' 2>&1
import os
import sys

import paths

tmp = sys.argv[1]
home = os.path.join(tmp, "home")
print("moved=%s" % os.path.relpath(paths.default_dir(os.path.join(tmp, "moved"), home), tmp))
print("unset=%s" % os.path.relpath(paths.default_dir(None, home), tmp))
RUN
)

moved=$(printf '%s\n' "$out" | sed -n 's/^moved=//p')
unset_=$(printf '%s\n' "$out" | sed -n 's/^unset=//p')
[ -n "$unset_" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$moved" = moved ] || {
  printf 'a configured folder answered %s, so a second location took over\n' "$moved"; exit 1; }
[ "$unset_" = home/.service ] || { printf 'with nothing configured it answered %s\n' "$unset_"; exit 1; }
homes=$(grep -rhoF '".service"' service | grep -c '')
[ "$homes" = 1 ] || { printf 'the default folder name is stated %s times in service/\n' "$homes"; exit 1; }
