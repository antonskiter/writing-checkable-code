#!/usr/bin/env bash
# T4 fires on swift/Ledger.swift CappedStore: the Store put-then-get contract,
# parameterized over the constructor, holds for Store and fails for CappedStore.
cd "$(dirname "$0")/.." || exit 1
command -v swiftc >/dev/null 2>&1 || { printf 'swiftc not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp swift/Ledger.swift "$tmp/Ledger.swift"
cat >"$tmp/main.swift" <<'EOF'
import Foundation

// The supertype's contract as one suite over a constructor: what put stores,
// total returns. One constructor per process — total force-unwraps, so a store
// that dropped the value traps instead of answering.
let factories: [String: () -> Store] = [
    "Store": { Store() },
    "CappedStore": { CappedStore() },
]
guard CommandLine.arguments.count == 2,
      let make = factories[CommandLine.arguments[1]] else {
    FileHandle.standardError.write(Data("usage: probe Store|CappedStore\n".utf8))
    exit(2)
}
let subject = make()
var verdict = "true"
for (i, id) in ["alpha", "beta", "gamma"].enumerated() {
    let amount = Decimal(i + 1)
    subject.put(id, amount)
    if subject.total(for: id) != amount {
        verdict = "false"
        break
    }
}
print(verdict)
EOF

build=$(swiftc -o "$tmp/probe" "$tmp/Ledger.swift" "$tmp/main.swift" 2>&1) || {
  printf 'swiftc failed on the fixture plus probe: %s\n' "$build"; exit 1; }

export SWIFT_BACKTRACE=enable=no
sup=$("$tmp/probe" Store 2>&1); sup_rc=$?
sub=$("$tmp/probe" CappedStore 2>&1); sub_rc=$?

[ "$sup_rc" = 0 ] && [ "$sup" = true ] || {
  printf 'Store failed its own contract: rc=%s out=%s\n' "$sup_rc" "$sup"; exit 1; }
if [ "$sub_rc" = 0 ] && [ "$sub" = true ]; then
  printf 'CappedStore satisfied the Store contract (rc=%s out=%s); the recorded CappedStore: false does not reproduce\n' \
    "$sub_rc" "$sub"
  exit 1
fi
