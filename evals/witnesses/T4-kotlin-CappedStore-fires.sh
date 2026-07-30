#!/usr/bin/env bash
# T4 fires on kotlin/Ledger.kt CappedStore: the Store put-then-get contract,
# parameterized over the constructor, holds for Store and fails for CappedStore.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'kotlinc or java not installed\n'; exit 77; }
stdlib=$(dirname "$(dirname "$(readlink -f "$(command -v kotlinc)")")")/lib/kotlin-stdlib.jar
[ -f "$stdlib" ] || { printf 'kotlin-stdlib.jar not found beside kotlinc\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp kotlin/Ledger.kt "$tmp/Ledger.kt"
cat >"$tmp/T4Probe.kt" <<'EOF'
// The supertype's contract as one suite over a constructor: what put stores,
// total returns.
fun contract(factory: () -> Store): String {
    val s = factory()
    for ((i, id) in listOf("alpha", "beta", "gamma").withIndex()) {
        val amount = (i + 1).toDouble()
        s.put(id, amount)
        try {
            if (s.total(id) != amount) return "false"
        } catch (e: RuntimeException) {
            return "false"
        }
    }
    return "true"
}

fun main() {
    println("Store: " + contract { Store() })
    println("CappedStore: " + contract { CappedStore() })
}
EOF

build=$(kotlinc "$tmp/Ledger.kt" "$tmp/T4Probe.kt" -d "$tmp/out" 2>&1) || {
  printf 'kotlinc failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp/out:$stdlib" T4ProbeKt 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'Store: true
CappedStore: false' ] || {
  printf 'the put-then-get suite reported:\n%s\nexpected Store: true and CappedStore: false\n' "$out"
  exit 1; }
