#!/usr/bin/env bash
# M2 fires on go/store.go Put: the store it writes to is a package-level map, not a
# collaborator it receives. Two runs in one process share it, and the only lever for
# giving the second run a different one is assigning that package variable, which no
# caller outside the package can reach.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1

# Two runs in one process, from outside the package: one store.
cat >"$tmp/src/wit/main.go" <<'EOF'
package main

import (
	"fmt"
	"strings"
	"store"
)

func main() {
	_ = store.Put(store.Record{ID: "first", Amount: 1})
	_ = store.Put(store.Record{ID: "second", Amount: 2})
	fmt.Print(strings.Join(store.SummariseSorted(), ","))
}
EOF
build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1)
[ -z "$build" ] || {
  printf 'the two-run probe no longer compiles, so Put no longer takes its store from the package: %s\n' \
    "$build"; exit 1; }
shared=$("$tmp/wit" 2>&1)
[ "$shared" = "first,second" ] || {
  printf 'two runs answered %q; expected one shared store holding both\n' "$shared"; exit 1; }

# The second value cannot reach it except by assigning the package variable.
cat >"$tmp/src/wit/reset.go" <<'EOF'
package main

import "store"

func reset() { store.cache = map[string]store.Record{} }
EOF
outside=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o /dev/null ./ 2>&1)
case $outside in
  *'cache not exported'*|*'undefined: store.cache'*) ;;
  '') printf 'a caller outside the package can now assign the store, so it is not module-private\n'; exit 1 ;;
  *) printf 'the outside-the-package probe failed for another reason: %s\n' "$outside"; exit 1 ;;
esac
rm "$tmp/src/wit/reset.go"

# Inside the package that assignment is the lever, and it is the only one.
cat >"$tmp/src/store/wit_test.go" <<'EOF'
package store

import (
	"strings"
	"testing"
)

func TestTwoStores(t *testing.T) {
	if err := Put(Record{ID: "first", Amount: 1}); err != nil {
		t.Fatal(err)
	}
	cache = map[string]Record{}
	if err := Put(Record{ID: "second", Amount: 2}); err != nil {
		t.Fatal(err)
	}
	if got := strings.Join(SummariseSorted(), ","); got != "second" {
		t.Fatalf("after assigning the package variable the second run held %q, want \"second\"", got)
	}
}
EOF
out=$(cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= \
  go test -count=1 -run TestTwoStores ./ 2>&1) || { printf '%s\n' "$out"; exit 1; }
