#!/usr/bin/env bash
# X4 fires on lua/ledger.lua ids: it returns table hash order, which Lua reseeds per
# process, so fresh runs over the same eight ids disagree.
cd "$(dirname "$0")/.." || exit 1
lua=$(command -v lua5.4 || command -v lua) || { echo "lua not installed"; exit 77; }

probe='
package.path = "lua/?.lua;" .. package.path
local ledger = require("ledger")
for _, id in ipairs({ "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta" }) do
  ledger.persist({ id = id, amount = 1 })
end
print(table.concat(ledger.ids(), ","))
'

runs=()
for i in 1 2 3 4 5 6; do
  run=$("$lua" -e "$probe" 2>&1) || { printf 'run %s failed: %s\n' "$i" "$run"; exit 1; }
  runs+=("$run")
  [ "$run" != "${runs[0]}" ] && exit 0
done

printf 'six fresh processes all returned %s; X4 would be silent on ids\n' "${runs[0]}"
exit 1
