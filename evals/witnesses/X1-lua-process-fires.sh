#!/usr/bin/env bash
# X1 fires on lua/ledger.lua process: a record with a non-string id returns nil and the
# "bad record" message omits the offending value.
cd "$(dirname "$0")/.." || exit 1
lua=$(command -v lua5.4 || command -v lua) || { echo "lua not installed"; exit 77; }

out=$("$lua" -e '
package.path = "lua/?.lua;" .. package.path
local ledger = require("ledger")
local ok, res = pcall(ledger.process, "{ id = 1, amount = 2 }")
io.write("result=", ok and tostring(res) or "raised")
' 2>&1) || { printf 'lua run failed: %s\n' "$out"; exit 1; }

[ "$out" = "bad record
result=nil" ] || {
  printf 'process({id=1,amount=2}) printed/returned %q; expected "bad record" and nil, a message naming no value\n' "$out"
  exit 1
}
