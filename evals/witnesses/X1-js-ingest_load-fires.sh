#!/usr/bin/env bash
# X1 fires on js/orders.js: ingest("{{{") and ingest("{}") both return null with a
# "bad order" warning that omits the value, and load('{"a":1}') returns the object
# itself despite an array contract.
cd "$(dirname "$0")/.." || exit 1
command -v node >/dev/null 2>&1 || { echo "node not installed"; exit 77; }
err=$(mktemp); trap 'rm -f "$err"' EXIT

out=$(node -e '
const o = require("./js/orders.js");
const a = o.ingest("{{{");
const b = o.ingest("{}");
const c = o.load("{\"a\":1}");
process.stdout.write([String(a), String(b), Array.isArray(c) ? "array" : typeof c].join("|"));
' 2>"$err") || { printf 'run failed: %s %s\n' "$out" "$(cat "$err")"; exit 1; }

[ "$out" = "null|null|object" ] || {
  printf 'ingest("{{{")|ingest("{}")|load(object) -> %s; expected null|null|object\n' "$out"
  exit 1
}

warning=$(cat "$err")
[ "$warning" = "bad order" ] || {
  printf 'warning was %q; expected exactly "bad order", a message omitting the offending value\n' "$warning"
  exit 1
}
