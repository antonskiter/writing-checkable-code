#!/usr/bin/env bash
# X4 fires on go/store.go Summarise: it returns map keys in iteration order, which Go
# randomises, so fresh processes over the same eight ids disagree.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store" "$tmp/src/wit"
cp go/*.go "$tmp/src/store/" || exit 1

cat >"$tmp/src/wit/main.go" <<'EOF'
package main

import (
	"fmt"
	"strings"

	"store"
)

func main() {
	for _, id := range []string{"alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"} {
		if err := store.Put(store.Record{ID: id, Amount: 1}); err != nil {
			panic(err)
		}
	}
	fmt.Println(strings.Join(store.Summarise(), ","))
}
EOF

build=$(cd "$tmp/src/wit" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go build -o "$tmp/wit" ./ 2>&1) || {
  printf 'build failed: %s\n' "$build"; exit 1; }

first=""
for i in 1 2 3 4 5 6; do
  run=$("$tmp/wit" 2>&1) || { printf 'run %s failed: %s\n' "$i" "$run"; exit 1; }
  [ -z "$first" ] && first=$run
  [ "$run" != "$first" ] && exit 0
done

printf 'six fresh processes all returned %s; X4 would be silent on Summarise\n' "$first"
exit 1
