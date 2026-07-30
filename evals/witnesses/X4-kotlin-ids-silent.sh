#!/usr/bin/env bash
# X4 stays silent on kotlin/Ledger.kt Store.ids(): mutableMapOf is a
# LinkedHashMap, so the key order is identical across seven fresh JVMs started
# from two directories.
cd "$(dirname "$0")/.." || exit 1
command -v kotlinc >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'kotlinc or java not installed\n'; exit 77; }
stdlib=$(dirname "$(dirname "$(readlink -f "$(command -v kotlinc)")")")/lib/kotlin-stdlib.jar
[ -f "$stdlib" ] || { printf 'kotlin-stdlib.jar not found beside kotlinc\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp kotlin/Ledger.kt "$tmp/Ledger.kt"
cat >"$tmp/IdsProbe.kt" <<'EOF'
fun main() {
    val store = Store()
    for (id in listOf("alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta")) {
        store.put(id, 1.0)
    }
    println(store.ids().joinToString(","))
}
EOF

build=$(kotlinc "$tmp/Ledger.kt" "$tmp/IdsProbe.kt" -d "$tmp/out" 2>&1) || {
  printf 'kotlinc failed on the fixture plus probe: %s\n' "$build"; exit 1; }

first=
for run in 1 2 3 4 5 6 7; do
  case $run in
    *[13579]) here=/ ;;
    *) here=$tmp ;;
  esac
  out=$(cd "$here" && java -cp "$tmp/out:$stdlib" IdsProbeKt 2>&1) || {
    printf 'run %s exited non-zero: %s\n' "$run" "$out"; exit 1; }
  if [ -z "$first" ]; then
    first=$out
  elif [ "$out" != "$first" ]; then
    printf 'ids() varied across processes: run 1 gave %s, run %s gave %s — X4 would fire\n' \
      "$first" "$run" "$out"
    exit 1
  fi
done
