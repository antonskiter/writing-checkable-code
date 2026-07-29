#!/usr/bin/env bash
# Runs each language's standard linter over the fixtures.
# The invariant: every finding printed here is intentional bait, recorded in
# MAP.md under the rule it baits. A finding that is not in MAP.md is a defect
# in the fixture, not in the code under review.
# Missing linters are reported, never skipped silently.
cd "$(dirname "$0")" || exit 1
status=0

run() {
  local name=$1 bin=$2
  shift 2
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf '%-10s SKIPPED (%s not installed)\n' "$name" "$bin"
    status=1
    return
  fi
  printf '%-10s %s\n' "$name" "$("$@" 2>&1 | tail -n +1 | wc -l) line(s)"
  "$@" 2>&1 | sed 's/^/           /'
}

run python  ruff       ruff check python/
run js      eslint     eslint -c eslint.config.mjs js/orders.js
run lua     luacheck   luacheck --no-color lua/ledger.lua
run bash    shellcheck shellcheck -S warning bash/deploy.sh
run go      go         go vet ./go/...
run swift   swiftc     swiftc -typecheck swift/Ledger.swift
run java    javac      javac -Xlint:all -d /tmp/wcc-lint-java java/Ledger.java
run kotlin  kotlinc    kotlinc kotlin/Ledger.kt -d /tmp/wcc-lint-kotlin

exit $status
