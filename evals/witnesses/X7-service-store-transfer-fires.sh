#!/usr/bin/env bash
# X7 fires on service/store.py transfer.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import store

refused_once = store.Store({"a": 100, "b": 0}, refusals=1)
print("answer=%s" % store.transfer(refused_once, "a", "b", 30))
print("balances=%d,%d" % (refused_once.balances["a"], refused_once.balances["b"]))
print("again=%s" % store.transfer(refused_once, "a", "b", 30))
RUN
)

answer=$(printf '%s\n' "$out" | sed -n 's/^answer=//p')
balances=$(printf '%s\n' "$out" | sed -n 's/^balances=//p')
again=$(printf '%s\n' "$out" | sed -n 's/^again=//p')
[ -n "$again" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$again" = done ] || { printf 'the same transaction run again gave %s, so a retry would not complete it\n' "$again"; exit 1; }
[ "$answer" = conflict ] && [ "$balances" = 100,0 ] || {
  printf 'the refused transfer answered %s with balances %s\n' "$answer" "$balances"; exit 1; }
