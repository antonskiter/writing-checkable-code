#!/usr/bin/env bash
# X1 fires on kotlin/Ledger.kt renderRow: align="up" is an unknown alignment and
# is silently left-aligned rather than refused.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'kotlinc or java not installed\n'; exit 77; }
stdlib=$(dirname "$(dirname "$(readlink -f "$(command -v kotlinc)")")")/lib/kotlin-stdlib.jar
[ -f "$stdlib" ] || { printf 'kotlin-stdlib.jar not found beside kotlinc\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp kotlin/Ledger.kt "$tmp/Ledger.kt"
cat >"$tmp/AlignProbe.kt" <<'EOF'
fun main() {
    val ledger = Ledger()
    for (align in listOf("up", "left", "right")) {
        try {
            println(align + "=" + ledger.renderRow("x", 1.0, "u", 2, align, 12, '.'))
        } catch (e: RuntimeException) {
            println(align + "=refused " + e.javaClass.name)
        }
    }
}
EOF

build=$(kotlinc "$tmp/Ledger.kt" "$tmp/AlignProbe.kt" -d "$tmp/out" 2>&1) || {
  printf 'kotlinc failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp/out:$stdlib" AlignProbeKt 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'up=x1.00u......
left=x1.00u......
right=......x1.00u' ] || {
  printf 'renderRow reported:\n%s\nexpected align="up" to be silently left-aligned as x1.00u......\n' "$out"
  exit 1; }
