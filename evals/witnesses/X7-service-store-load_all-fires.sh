#!/usr/bin/env bash
# X7 fires on service/store.py load_all.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import store

s = store.Store({"a": 1, "b": 2, "c": 3}, refusals=0)
print("answers=%s" % ",".join(str(v) for v in store.load_all(s, ["a", "b", "c"])))
print("peak=%d" % s.peak)
RUN
)

answers=$(printf '%s\n' "$out" | sed -n 's/^answers=//p')
peak=$(printf '%s\n' "$out" | sed -n 's/^peak=//p')
[ -n "$peak" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$answers" = 1,2,3 ] || { printf 'load_all answered %s\n' "$answers"; exit 1; }
[ "$peak" -gt 1 ] || { printf 'at most %s statement was in flight\n' "$peak"; exit 1; }
