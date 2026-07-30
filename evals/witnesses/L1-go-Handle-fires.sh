#!/usr/bin/env bash
# L1 fires on go/store.go: `_ = validate(r)` in Handle discards a verdict that is really
# there, so Record{Amount: -5} is stored and reported as a success.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store"
cp go/*.go "$tmp/src/store/" || exit 1

cat >"$tmp/src/store/witness_test.go" <<'EOF'
package store

import "testing"

func TestL1(t *testing.T) {
	r := Record{ID: "x", Amount: -5}
	if validate(r) == nil {
		t.Fatalf("validate(%v) returned no error, so there is no verdict to discard", r)
	}
	out := Handle([]byte(`{"ID":"x","Amount":-5}`))
	if len(out) != 1 || out[0] != "x" {
		t.Errorf("Handle returned %v; expected [x], the rejected record reported as stored", out)
	}
	if got, ok := cache["x"]; !ok || got.Amount != -5 {
		t.Errorf("cache[x] = %v ok=%v; expected the record validate rejected to be stored", got, ok)
	}
}
EOF

out=$(cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go test -count=1 -run TestL1 ./ 2>&1)
rc=$?
[ "$rc" = 0 ] || { printf '%s\n' "$out"; exit 1; }
