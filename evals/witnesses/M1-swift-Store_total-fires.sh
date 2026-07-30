#!/usr/bin/env bash
# M1 fires on swift/Ledger.swift Store.total: called alone, with an argument
# written from its signature, it traps; it answers once put has run. Store.entries
# being visible in the module is a way to discover the requirement, not a
# signature that makes the correct call the only writable one, so the row still
# fires. renderRow, seven caller-chosen parameters, is silent in the same file.
#
# The trap kills the process, so each probe is its own run.
cd "$(dirname "$0")/.." || exit 1
command -v swiftc >/dev/null 2>&1 || { printf 'swiftc not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp swift/Ledger.swift "$tmp/Ledger.swift"

# X5's question at this site: X1 is recorded here too, for the force-unwrap. The
# variant below is X1's change alone — stop and name the offending value. It
# clears X1 and leaves this row firing, so the two are separate defects.
python3 - "$tmp" <<'PY' || { printf 'python3 unavailable, or total(for:) is not the body this witness patches\n'; exit 77; }
import sys
src = open("swift/Ledger.swift").read()
old = """    func total(for id: String) -> Decimal {
        return entries[id]!
    }"""
assert old in src, "total(for:) is not the body this witness patches"
open(sys.argv[1] + "/Named.swift", "w").write(src.replace(old, """    func total(for id: String) -> Decimal {
        guard let found = entries[id] else {
            fatalError("no entry for id \\(id)")
        }
        return found
    }"""))
PY
cat >"$tmp/main.swift" <<'EOF'
import Foundation

switch CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "" {
case "alone":
    print("answers \(Store().total(for: "alpha"))")
case "after-put":
    let s = Store()
    s.put("alpha", 1)
    print("answers \(s.total(for: "alpha"))")
case "render-row":
    // What the row turns on is that the call answers at all, not how it formats.
    let row = renderRow(label: "a", amount: 1, unit: "kg",
                        precision: 2, align: "right", width: 10, fill: ".")
    print("answers width=\(row.count)")
default:
    fatalError("unknown probe")
}
EOF

build=$(swiftc -O "$tmp/Ledger.swift" "$tmp/main.swift" -o "$tmp/probe" 2>&1) || {
  printf 'swiftc failed on the fixture plus probe: %s\n' "$build"; exit 1; }

report=$(for p in alone after-put render-row; do
  out=$("$tmp/probe" "$p" 2>/dev/null); rc=$?
  if [ $rc -eq 0 ]; then printf '%s: %s\n' "$p" "$out"; else printf '%s: fails rc=%s\n' "$p" "$rc"; fi
done)

# 132 is SIGILL, the trap swift raises for the force-unwrap of a missing key.
[ "$report" = 'alone: fails rc=132
after-put: answers 1
render-row: answers width=10' ] || {
  printf 'the probe reported:\n%s\nexpected total to trap alone, to answer after put, and renderRow to answer\n' "$report"
  exit 1; }

# X1's change alone: the failure now names the offending value, and the call alone
# still fails — so this row is not cleared by it.
build=$(swiftc -O "$tmp/Named.swift" "$tmp/main.swift" -o "$tmp/named" 2>&1) || {
  printf 'swiftc failed on the named-failure variant: %s\n' "$build"; exit 1; }
err=$("$tmp/named" alone 2>&1); rc=$?
[ "$rc" = 132 ] || {
  printf 'after X1s change the call alone exited %s; expected it to keep failing\n' "$rc"; exit 1; }
printf '%s' "$err" | grep -q 'no entry for id alpha' || {
  printf 'after X1s change the failure did not name the offending value:\n%s\n' "$err"; exit 1; }
