#!/usr/bin/env bash
# Runs each language's standard linter over the fixtures.
# The invariant: every finding printed here is intentional bait, recorded in
# VERDICTS.md under the rule it baits. A finding that is not in VERDICTS.md is a
# defect in the fixture, not in the code under review.
#
# The exit status decides that invariant mechanically: each finding is reduced
# to a "<linter> <code>" pair and the sorted multiset of pairs is diffed against
# lint.baseline. Any new finding, or any baseline finding that stopped firing,
# fails. Missing linters are reported, never skipped silently: they fail too,
# and their baseline entries are excluded from the diff so the absent toolchain
# is not misreported as fixture drift.
#
# Run with --update-baseline to rewrite lint.baseline from the current run; it
# refuses while any linter is missing.
cd "$(dirname "$0")" || exit 1

# The go fixtures are a bare package with no module file; vet them in GOPATH mode.
export GO111MODULE=off

baseline=lint.baseline
emitted=$(mktemp)
expected=$(mktemp)
trap 'rm -f "$emitted" "$expected"' EXIT
status=0
skipped=()

# Reduces a linter's output on stdin to one code per finding.
codes() {
  case $1 in
    ruff)       grep -oE '^[A-Z]{1,4}[0-9]{3,4}\b' ;;
    eslint)     awk '$2 == "error" || $2 == "warning" { print $NF }' ;;
    luacheck)   grep -oE '\(W[0-9]+\)' | tr -d '()' ;;
    shellcheck) grep -oE 'SC[0-9]{4} \(' | grep -oE 'SC[0-9]{4}' ;;
    # go vet, swiftc, javac and kotlinc find nothing in these fixtures, so they
    # have no finding format to parse: any output at all is unrecorded.
    *)          grep -v '^[[:space:]]*$' | sed 's/.*/UNEXPECTED/' ;;
  esac
}

run() {
  local name=$1 bin=$2 out
  shift 2
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf '%-10s SKIPPED (%s not installed)\n' "$name" "$bin"
    skipped+=("$bin")
    status=1
    return
  fi
  out=$("$@" 2>&1)
  printf '%-10s %s line(s)\n' "$name" "$(printf '%s' "$out" | grep -c '')"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/           /'
  printf '%s\n' "$out" | codes "$bin" | sed "s/^/$bin /" >>"$emitted"
}

run python  ruff       ruff check python/
run js      eslint     eslint -c eslint.config.mjs js/orders.js
run lua     luacheck   luacheck --no-color --codes lua/ledger.lua
run bash    shellcheck shellcheck -S warning bash/deploy.sh
run go      go         go vet ./go/...
run swift   swiftc     swiftc -typecheck swift/Ledger.swift
run java    javac      javac -Xlint:all -d /tmp/wcc-lint-java java/Ledger.java
run kotlin  kotlinc    kotlinc kotlin/Ledger.kt -d /tmp/wcc-lint-kotlin

sort -o "$emitted" "$emitted"

if [ "$1" = --update-baseline ]; then
  if [ ${#skipped[@]} -gt 0 ]; then
    printf '\nrefusing to update %s: %s did not run\n' "$baseline" "${skipped[*]}"
    exit 1
  fi
  {
    printf '# Expected linter findings over the fixtures: one "<linter> <code>"\n'
    printf '# line per finding, sorted. Every entry is intentional bait, recorded\n'
    printf '# in VERDICTS.md under the rule it baits. Regenerate with\n'
    printf '# ./lint.sh --update-baseline after changing a fixture on purpose.\n'
    cat "$emitted"
  } >"$baseline"
  printf '\nwrote %s (%s finding(s))\n' "$baseline" "$(grep -c '' "$emitted")"
  exit 0
fi

grep -vE '^[[:space:]]*(#|$)' "$baseline" | sort >"$expected"
for bin in "${skipped[@]}"; do
  grep -v "^$bin " "$expected" >"$expected.filtered"
  mv "$expected.filtered" "$expected"
done

if diff -u --label "$baseline" --label 'this run' "$expected" "$emitted"; then
  printf '\n%s finding(s), all recorded in %s\n' "$(grep -c '' "$emitted")" "$baseline"
else
  printf '\nunrecorded or missing findings against %s (see diff above)\n' "$baseline"
  status=1
fi

exit $status
