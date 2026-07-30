#!/usr/bin/env bash
# X1 fires on go/store.go: Put rejects a record with "invalid record" and never names the
# value, and Fetch against an unreachable address returns (nil, nil).
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store"
cp go/*.go "$tmp/src/store/" || exit 1

cat >"$tmp/src/store/witness_test.go" <<'EOF'
package store

import (
	"strings"
	"testing"
)

func TestX1(t *testing.T) {
	err := Put(Record{ID: "", Amount: 12.5, Kind: "created"})
	if err == nil {
		t.Fatalf("Put of an empty id returned no error")
	}
	if got := err.Error(); got != "invalid record" || strings.Contains(got, "12.5") {
		t.Errorf("Put error is %q; expected exactly \"invalid record\", naming no value", got)
	}
	resp, ferr := Fetch("http://127.0.0.1:1/")
	if resp != nil || ferr != nil {
		t.Errorf("Fetch of an unreachable address returned (%v, %v); expected (nil, nil)", resp, ferr)
	}
}
EOF

out=$(cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go test -count=1 -run TestX1 ./ 2>&1)
rc=$?
[ "$rc" = 0 ] || { printf '%s\n' "$out"; exit 1; }
