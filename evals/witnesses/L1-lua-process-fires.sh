#!/usr/bin/env bash
# L1 fires on lua/ledger.lua process: the pcall result is discarded, so a chunk that
# raises "boom" and a chunk that will not compile both come back as a bare nil with the
# error text never read.
cd "$(dirname "$0")/.." || exit 1
lua=$(command -v lua5.4 || command -v lua) || { echo "lua not installed"; exit 77; }

out=$("$lua" -e '
package.path = "lua/?.lua;" .. package.path
local ledger = require("ledger")
-- Both errors exist and carry text before process sees them.
local _, compile_err = load("return {{{")
local raised_ok, raised_err = pcall(load("return error(\"boom\")"))
assert(compile_err and not raised_ok and raised_err, "no error to discard")
local a = table.pack(pcall(ledger.process, "error(\"boom\")"))
local b = table.pack(pcall(ledger.process, "{{{"))
io.write("raise=", table.concat({ tostring(a[1]), tostring(a[2]), tostring(a.n) }, "/"),
         " parse=", table.concat({ tostring(b[1]), tostring(b[2]), tostring(b.n) }, "/"))
' 2>&1) || { printf 'lua run failed: %s\n' "$out"; exit 1; }

[ "$out" = "raise=true/nil/2 parse=true/nil/2" ] || {
  printf 'process saw %q; expected each error to arrive as a single nil with no text and nothing printed\n' "$out"
  exit 1
}
