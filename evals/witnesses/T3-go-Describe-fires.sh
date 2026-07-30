#!/usr/bin/env bash
# T3 fires on go/store.go Describe: every arm tests the kind of one value, and the
# default arm forfeits exhaustiveness. Executed by adding a member to the set of kinds
# it dispatches on: the tree builds clean instead of breaking, and the new member is
# answered with a real case's answer.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1

# One value's kind is what every arm tests, and one arm matches anything else.
grep -qF 'switch v.(type) {' "$tmp/src/store/store.go" || {
  printf 'Describe no longer dispatches on the kind of one value\n'; exit 1; }
sed -n '/^func Describe/,/^}/p' "$tmp/src/store/store.go" | grep -qE $'^\tdefault:' || {
  printf 'the switch has no arm matching anything else, so T3 has an exemption to weigh\n'
  exit 1; }

cat >"$tmp/src/store/extra.go" <<'EOF'
package store

type Blob struct{ Data []byte }
EOF
cat >"$tmp/src/wit/main.go" <<'EOF'
package main

import (
	"fmt"
	"store"
)

func main() {
	fmt.Printf("%s|%s\n", store.Describe(store.Blob{}), store.Describe("s"))
}
EOF

build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1)
[ -z "$build" ] || {
  printf 'adding a member broke the build, so the switch is exhaustive over a closed sum: %s\n' \
    "$build"; exit 1; }

out=$("$tmp/wit" 2>&1) || { printf 'the probe failed: %s\n' "$out"; exit 1; }
[ "$out" = "text|text" ] || {
  printf 'Describe answered %s for the added member and the string case; expected both "text"\n' \
    "$out"; exit 1; }
