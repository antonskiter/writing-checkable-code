#!/usr/bin/env bash
# X4 stays silent on js/orders.js totals: it reorders integer-like keys first (ids
# b,10,a,2 come back as 2,10,b,a) but does so identically in every fresh process.
cd "$(dirname "$0")/.." || exit 1
command -v node >/dev/null 2>&1 || { echo "node not installed"; exit 77; }

probe='
const o = require("./js/orders.js");
const ids = ["b", "10", "a", "2"];
process.stdout.write(Object.keys(o.totals(ids.map((id) => ({ id, amount: 1 })))).join(","));
'

first=""
for i in 1 2 3 4; do
  run=$(node -e "$probe" 2>&1) || { printf 'run %s failed: %s\n' "$i" "$run"; exit 1; }
  if [ -z "$first" ]; then
    first=$run
  elif [ "$run" != "$first" ]; then
    printf 'fresh processes disagree: %s vs %s; X4 would fire\n' "$first" "$run"
    exit 1
  fi
done

[ "$first" = "2,10,b,a" ] || {
  printf 'totals(b,10,a,2) key order is %s; recorded order is 2,10,b,a\n' "$first"
  exit 1
}
