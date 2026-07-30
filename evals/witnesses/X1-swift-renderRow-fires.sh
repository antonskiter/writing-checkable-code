#!/usr/bin/env bash
# X1 fires on swift/Ledger.swift renderRow: align="up" is an unknown alignment and is
# silently left-aligned rather than refused.
cd "$(dirname "$0")/.." || exit 1
command -v swiftc >/dev/null 2>&1 || { printf 'swiftc not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp swift/Ledger.swift "$tmp/Ledger.swift"
cat >>"$tmp/Ledger.swift" <<'EOF'

for align in ["up", "left", "right"] {
    print(align + "=" + renderRow(
        label: "x", amount: 1, unit: "u", precision: 2, align: align, width: 12, fill: "."))
}
EOF

build=$(swiftc -o "$tmp/probe" "$tmp/Ledger.swift" 2>&1) || {
  printf 'swiftc failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$("$tmp/probe" 2>&1) || { printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'up=x1.00u......
left=x1.00u......
right=......x1.00u' ] || {
  printf 'renderRow reported:\n%s\nexpected align="up" to be silently left-aligned as x1.00u......\n' "$out"
  exit 1; }
