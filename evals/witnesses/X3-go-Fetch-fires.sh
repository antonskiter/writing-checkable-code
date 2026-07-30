#!/usr/bin/env bash
# X3 fires on go/store.go Fetch: nothing states that it answers an unreachable address
# with a nil response and a nil error, so a call written from the signature alone —
# err == nil, therefore the response is usable — dereferences nil.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1

# There is no interface comment above Fetch to write the call from.
doc=$(awk '/^func Fetch\(/ { print prev } { prev = $0 }' "$tmp/src/store/store.go")
case $doc in
  '//'*) printf 'Fetch now carries an interface comment: %s\n' "$doc"; exit 1 ;;
esac

cat >"$tmp/src/wit/main.go" <<'EOF'
package main

import (
	"fmt"
	"store"
)

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("panic|%v\n", r)
		}
	}()
	resp, err := store.Fetch("http://127.0.0.1:1/nothing")
	if err != nil {
		fmt.Printf("error|%v\n", err)
		return
	}
	fmt.Printf("status|%d\n", resp.StatusCode)
}
EOF
build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1)
[ -z "$build" ] || { printf 'build failed: %s\n' "$build"; exit 1; }
out=$("$tmp/wit" 2>&1)

case $out in
  panic*'nil pointer dereference'*) ;;
  error*) printf 'Fetch now reports the failure, so a signature-faithful call is right: %s\n' "$out"; exit 1 ;;
  *) printf 'the signature-faithful call answered %s; expected a nil dereference\n' "$out"; exit 1 ;;
esac
