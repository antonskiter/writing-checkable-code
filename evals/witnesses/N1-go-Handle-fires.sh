#!/usr/bin/env bash
# N1 fires on go/handler.go Handle: the body writes the decoded record into the package
# store, a write the name does not state. Executed by reading the store either side of a
# call from outside the package.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1

# The name states no write: no verb in it names one.
grep -qE '^func Handle\(' "$tmp/src/store/handler.go" || {
  printf 'the unit is no longer named Handle, so the name may now state the write\n'; exit 1; }
printf 'Handle' | grep -qiE 'put|store|save|write|insert|cache|persist' && {
  printf 'the name now states a write\n'; exit 1; }

cat >"$tmp/src/wit/main.go" <<'EOF'
package main

import (
	"fmt"
	"strings"
	"store"
)

func main() {
	before := store.SummariseSorted()
	out := store.Handle([]byte(`{"ID":"h1","Amount":-5}`))
	after := store.SummariseSorted()
	fmt.Printf("before=[%s] returned=[%s] after=[%s]\n",
		strings.Join(before, ","), strings.Join(out, ","), strings.Join(after, ","))
}
EOF
build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1)
[ -z "$build" ] || { printf 'build failed: %s\n' "$build"; exit 1; }
out=$("$tmp/wit" 2>&1) || { printf 'the probe failed: %s\n' "$out"; exit 1; }

[ "$out" = "before=[] returned=[h1] after=[h1]" ] || {
  printf 'the probe read %s; expected an empty store before the call and h1 in it after\n' "$out"
  exit 1; }
