#!/usr/bin/env bash
# L2 fires on go/store.go Describe: an unlisted type reaches the default arm and is
# answered "text", the same answer the string case gives.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store"
cp go/*.go "$tmp/src/store/" || exit 1

cat >"$tmp/src/store/witness_test.go" <<'EOF'
package store

import "testing"

func TestL2(t *testing.T) {
	unknown := Describe(3.5)
	text := Describe("s")
	if unknown != "text" || unknown != text {
		t.Errorf("Describe(3.5)=%q Describe(\"s\")=%q; expected both \"text\", an unlisted type answered by a real case",
			unknown, text)
	}
	if Describe(nil) != "text" {
		t.Errorf("Describe(nil)=%q; expected \"text\"", Describe(nil))
	}
}
EOF

out=$(cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go test -count=1 -run TestL2 ./ 2>&1)
rc=$?
[ "$rc" = 0 ] || { printf '%s\n' "$out"; exit 1; }
