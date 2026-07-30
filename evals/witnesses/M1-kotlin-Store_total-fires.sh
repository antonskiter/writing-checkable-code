#!/usr/bin/env bash
# M1 fires on kotlin/Ledger.kt Store.total: called alone, with an argument written
# from its signature, it fails; it succeeds once put has run. Store also exports
# ids(), which lets a caller find out which ids are present — that is a way to
# discover the requirement, not a signature that makes the correct call the only
# writable one, so the row still fires. renderRow, seven caller-chosen parameters,
# is silent in the same file.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'kotlinc or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp kotlin/Ledger.kt "$tmp/Ledger.kt"
cat >"$tmp/probe.kt" <<'EOF'
fun outcome(f: () -> Any?): String =
    try { "answers ${f()}" } catch (t: Throwable) { "fails ${t::class.simpleName}" }

fun main() {
    println("alone: " + outcome { Store().total("alpha") })
    println("afterPut: " + outcome { val s = Store(); s.put("alpha", 1.0); s.total("alpha") })
    println("idsAlone: " + outcome { Store().ids() })
    // What the row turns on is that the call answers at all, not how it formats.
    println("renderRow: " + outcome {
        "width=" + Ledger().renderRow("a", 1.0, "kg", 2, "right", 10, '.').length
    })
}
EOF

build=$(kotlinc "$tmp/Ledger.kt" "$tmp/probe.kt" -include-runtime -d "$tmp/probe.jar" 2>&1) || {
  printf 'kotlinc failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -jar "$tmp/probe.jar" 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'alone: fails NoSuchElementException
afterPut: answers 1.0
idsAlone: answers []
renderRow: answers width=10' ] || {
  printf 'the probe reported:\n%s\nexpected total to fail alone, to answer after put, and renderRow to answer\n' "$out"
  exit 1; }
