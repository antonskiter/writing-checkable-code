#!/usr/bin/env bash
# L3 fires on go/store.go RequestTimeout: no entry point in the tree reaches it, and
# deleting it vets clean with every observable answer unchanged. The 30-second fact it
# names keeps two live homes in the same tree, so S1 fires here too and deleting the
# constant is not S1's repair.
cd "$(dirname "$0")/.." || exit 1
command -v go >/dev/null 2>&1 || { echo "go not installed"; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/store"
cp go/*.go "$tmp/src/store/" || exit 1

readers=$(grep -rn 'RequestTimeout' "$tmp/src/store") || {
  printf 'RequestTimeout is not in the tree at all\n'; exit 1; }
[ "$(printf '%s\n' "$readers" | grep -c '')" = 1 ] || {
  printf 'RequestTimeout is named more than once in the tree, so an entry point reaches it:\n%s\n' \
    "$readers"; exit 1; }

cat >"$tmp/src/store/wit_test.go" <<'EOF'
package store

import "testing"

func TestReachable(t *testing.T) {
	if err := Put(Record{ID: "a", Amount: 1}); err != nil {
		t.Fatal(err)
	}
	t.Logf("empty-id=%v ids=%v describe=%q|%q|%q handle=%v region=%q",
		Put(Record{}), SummariseSorted(),
		Describe("s"), Describe(1), Describe(Record{}),
		Handle([]byte(`{"ID":"b","Amount":-5}`)), Region())
}
EOF

run() {
  (cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= go vet ./ 2>&1) || return 1
  (cd "$tmp/src/store" && GO111MODULE=off GOPATH="$tmp" GOFLAGS= \
    go test -count=1 -v -run TestReachable ./ 2>&1 | grep 'wit_test.go:')
}

before=$(run) || { printf 'the tree does not vet clean before the deletion\n'; exit 1; }
[ -n "$before" ] || { printf 'nothing was rerun before the deletion\n'; exit 1; }

grep -v '^const RequestTimeout = 30 \* time.Second$' "$tmp/src/store/store.go" >"$tmp/stripped" &&
  mv "$tmp/stripped" "$tmp/src/store/store.go"

after=$(run) || { printf 'deleting RequestTimeout did not vet clean\n'; exit 1; }
[ "$before" = "$after" ] || {
  printf 'the rerun changed after the deletion:\n%s\n%s\n' "$before" "$after"; exit 1; }

# The fact keeps live homes: the deletion clears this row and leaves S1's finding standing.
homes=$(grep -rn '30 \* time.Second' "$tmp/src/store" | grep -c '')
[ "$homes" -ge 2 ] || {
  printf 'the 30-second deadline no longer has a second home in the tree (%s), so S1 does not stand beside this row\n' \
    "$homes"; exit 1; }
