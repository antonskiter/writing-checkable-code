#!/usr/bin/env bash
# L2 fires on lua/ledger.lua handle: an unknown kind is routed by the else branch to
# on_created, the same function a recognised kind reaches.
cd "$(dirname "$0")/.." || exit 1
lua=$(command -v lua5.4 || command -v lua) || { echo "lua not installed"; exit 77; }

out=$("$lua" -e '
package.path = "lua/?.lua;" .. package.path
local ledger = require("ledger")
-- Record which ledger.lua function each kind enters, by the line it is defined on,
-- so the routing is read off a run rather than off the source.
local function route(kind)
  local seen = {}
  debug.sethook(function()
    local info = debug.getinfo(2, "S")
    if info and info.source:find("ledger") then seen[#seen + 1] = info.linedefined end
  end, "c")
  local ok, res = pcall(ledger.handle, { kind = kind })
  debug.sethook()
  local status = ok and type(res) == "table" and tostring(res.status) or "raised"
  return table.concat(seen, ",") .. ":" .. status
end
print(route("created") .. "|" .. route("updated") .. "|" .. route("deleted"))
' 2>&1) || { printf 'lua run failed: %s\n' "$out"; exit 1; }

created=${out%%|*}; rest=${out#*|}; updated=${rest%%|*}; unknown=${rest#*|}
[ "$unknown" = "$created" ] && [ "$unknown" != "$updated" ] || {
  printf 'created=%s updated=%s unknown=%s; expected the unknown kind to take the created route\n' \
    "$created" "$updated" "$unknown"
  exit 1
}
