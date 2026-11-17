#!/usr/bin/env bash
# M2 fires on service/runner.py run_child.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

probe() {
  (cd service && SERVICE_MODE=$1 PYTHONDONTWRITEBYTECODE=1 python3 -c \
    'import runner; print(runner.run_child())' 2>&1)
}
first=$(probe fast)
second=$(probe safe)
[ -n "$first" ] && [ -n "$second" ] || { printf 'run_child gave no answer\n'; exit 1; }
[ "$first" = default ] && [ "$second" = default ] || {
  printf 'run_child answered %s under fast and %s under safe, so the setting reaches the child\n' \
    "$first" "$second"; exit 1; }
