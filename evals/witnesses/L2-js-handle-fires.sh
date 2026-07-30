#!/usr/bin/env bash
# L2 fires on js/orders.js handle: handle({kind:"deleted"}) is answered "ok" by the
# default arm, so an unrecognised kind gets a real case's value.
cd "$(dirname "$0")/.." || exit 1
command -v node >/dev/null 2>&1 || { echo "node not installed"; exit 77; }

out=$(node -e '
const o = require("./js/orders.js");
process.stdout.write(String(o.handle({ kind: "deleted" })) + "|" + String(o.handle({ kind: "created" })));
' 2>&1) || { printf 'handle({kind:"deleted"}) did not return: %s\n' "$out"; exit 1; }

[ "$out" = "ok|ok" ] || {
  printf 'deleted|created -> %s; expected ok|ok, an unrecognised kind answered by a real case\n' "$out"
  exit 1
}
