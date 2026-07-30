#!/usr/bin/env bash
# X1 fires on kotlin/Ledger.kt process and persist: process(null, 5.0) completes
# normally as "bad record" plus null, and persist's require message omits the id.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'kotlinc or java not installed\n'; exit 77; }
stdlib=$(dirname "$(dirname "$(readlink -f "$(command -v kotlinc)")")")/lib/kotlin-stdlib.jar
[ -f "$stdlib" ] || { printf 'kotlin-stdlib.jar not found beside kotlinc\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp kotlin/Ledger.kt "$tmp/Ledger.kt"
cat >"$tmp/X1Probe.kt" <<'EOF'
fun main() {
    val ledger = Ledger()
    println("process=" + ledger.process(null, 5.0))
    try {
        val kept = ledger.persist("", 5.0)
        println("persist=returned $kept")
    } catch (e: IllegalArgumentException) {
        println("persist=" + e.message)
    }
}
EOF

build=$(kotlinc "$tmp/Ledger.kt" "$tmp/X1Probe.kt" -d "$tmp/out" 2>&1) || {
  printf 'kotlinc failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp/out:$stdlib" X1ProbeKt 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }
mapfile -t line <<<"$out"

[ "${line[0]}" = 'bad record' ] || {
  printf 'process(null, 5.0) printed %s; expected the value-free "bad record"\n' "${line[0]}"; exit 1; }
[ "${line[1]}" = 'process=null' ] || {
  printf 'process(null, 5.0) -> %s; expected it to complete normally with null\n' "${line[1]}"; exit 1; }
[ "${line[2]}" = 'persist=invalid record' ] || {
  printf 'persist("", 5.0) reported %s; expected the require message "invalid record", which names no id\n' \
    "${line[2]}"; exit 1; }
