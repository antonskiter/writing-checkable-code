#!/usr/bin/env bash
# X4 stays silent on java/Ledger.java ids(): the HashMap key order it returns is
# identical across seven fresh JVMs started from two directories.
cd "$(dirname "$0")/.." || exit 1
command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'javac or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp java/Ledger.java "$tmp/Ledger.java"
cat >"$tmp/IdsProbe.java" <<'EOF'
public class IdsProbe {
    public static void main(String[] argv) {
        Ledger ledger = new Ledger();
        String[] ids = {"alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta"};
        for (String id : ids) {
            Ledger.Entry entry = new Ledger.Entry();
            entry.id = id;
            entry.amount = 1;
            ledger.persist(entry);
        }
        System.out.println(String.join(",", ledger.ids()));
    }
}
EOF

build=$(javac -d "$tmp" "$tmp/Ledger.java" "$tmp/IdsProbe.java" 2>&1) || {
  printf 'javac failed on the fixture plus probe: %s\n' "$build"; exit 1; }

first=
for run in 1 2 3 4 5 6 7; do
  case $run in
    *[13579]) here=/ ;;
    *) here=$tmp ;;
  esac
  out=$(cd "$here" && java -cp "$tmp" IdsProbe 2>&1) || {
    printf 'run %s exited non-zero: %s\n' "$run" "$out"; exit 1; }
  if [ -z "$first" ]; then
    first=$out
  elif [ "$out" != "$first" ]; then
    printf 'ids() varied across processes: run 1 gave %s, run %s gave %s — X4 would fire\n' \
      "$first" "$run" "$out"
    exit 1
  fi
done
