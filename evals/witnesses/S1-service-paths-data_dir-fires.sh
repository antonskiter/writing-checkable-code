#!/usr/bin/env bash
# S1 fires on service/paths.py data_dir.
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
moved = os.path.join(tmp, "moved")
try:
    print("answer=%s" % os.path.relpath(paths.data_dir(moved, home), tmp))
except Exception as exc:
    print("answer=refused %s" % type(exc).__name__)
RUN
)

answer=$(printf '%s\n' "$out" | sed -n 's/^answer=//p')
[ -n "$answer" ] || { printf 'data_dir gave no answer:\n%s\n' "$out"; exit 1; }
[ "$answer" = home/.service ] || {
  printf 'data_dir answered %s for a moved folder, so no second location took over\n' "$answer"
  exit 1; }
