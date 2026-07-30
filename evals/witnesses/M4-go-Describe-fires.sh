#!/usr/bin/env bash
# M4 fires on go/store.go Describe: a new case has no extension point to land in. Executed
# by adding a member to the dispatched-on set — nothing already in the tree serves it, and
# the duplicated case's every changed line lands inside the body of Describe itself.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1
cp "$tmp/src/store/store.go" "$tmp/before.go"

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

func main() { fmt.Print(store.Describe(store.Blob{})) }
EOF
probe() {
  local build out
  build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1)
  [ -z "$build" ] || { printf 'build failed: %s\n' "$build"; return 1; }
  out=$("$tmp/wit" 2>&1) || { printf 'probe failed: %s\n' "$out"; return 1; }
  printf '%s' "$out"
}

# The member alone reaches no extension point: no table, registry or method set answers it.
unserved=$(probe) || { printf '%s\n' "$unserved"; exit 1; }
[ "$unserved" = "text" ] || {
  printf 'the added member was answered %q without editing any dispatch, so an extension point already serves it\n' \
    "$unserved"; exit 1; }

# Duplicate an existing case under the new key.
hits=$(grep -c $'^\tcase Record:$' "$tmp/src/store/store.go")
[ "$hits" = 1 ] || { printf 'expected one "case Record:" arm to duplicate, found %s\n' "$hits"; exit 1; }
awk '
  { print }
  /^\tcase Record:$/ { rec = NR }
  rec && NR == rec + 1 { print "\tcase Blob:"; print "\t\treturn \"blob\"" }
' "$tmp/before.go" >"$tmp/src/store/store.go"

served=$(probe) || { printf '%s\n' "$served"; exit 1; }
[ "$served" = "blob" ] || {
  printf 'the duplicated case answered %q, so the edit did not add the case\n' "$served"; exit 1; }

# Every changed line lands inside the body of Describe.
span=$(awk '/^func Describe/{s=NR} s && /^}/{print s" "NR; exit}' "$tmp/src/store/store.go")
set -- $span
changed=$(diff "$tmp/before.go" "$tmp/src/store/store.go" | grep -c '^>')
lines=$(grep -nF 'case Blob:' "$tmp/src/store/store.go" | cut -d: -f1)
[ "$changed" = 2 ] || { printf 'expected the duplicate to add two lines, added %s\n' "$changed"; exit 1; }
[ "$lines" -gt "$1" ] && [ "$lines" -lt "$2" ] || {
  printf 'the new case landed at line %s, outside func Describe (lines %s-%s): it has an extension point\n' \
    "$lines" "$1" "$2"; exit 1; }
