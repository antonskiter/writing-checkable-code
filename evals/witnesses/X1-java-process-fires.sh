#!/usr/bin/env bash
# X1 fires on java/Ledger.java process and Store.total: a null id completes
# normally as "bad record" plus null, and total("missing") raises a
# NullPointerException naming a Map internal instead of the id.
cd "$(dirname "$0")/.." || exit 1
command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'javac or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp java/Ledger.java "$tmp/Ledger.java"
cat >"$tmp/X1Probe.java" <<'EOF'
public class X1Probe {
    public static void main(String[] argv) {
        Ledger.Entry bad = new Ledger.Entry();
        bad.id = null;
        bad.amount = 5;
        Ledger.Entry back = new Ledger().process(bad);
        System.out.println("process=" + back);
        try {
            double t = new Ledger.Store().total("missing");
            System.out.println("total=returned " + t);
        } catch (RuntimeException e) {
            System.out.println("total=" + e.getClass().getName() + ": " + e.getMessage());
        }
    }
}
EOF

build=$(javac -d "$tmp" "$tmp/Ledger.java" "$tmp/X1Probe.java" 2>&1) || {
  printf 'javac failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp" X1Probe 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }
mapfile -t line <<<"$out"

[ "${line[0]}" = 'bad record' ] || {
  printf 'process(null id) printed %s; expected the value-free "bad record"\n' "${line[0]}"; exit 1; }
[ "${line[1]}" = 'process=null' ] || {
  printf 'process(null id) -> %s; expected it to complete normally with null\n' "${line[1]}"; exit 1; }

case ${line[2]} in
  total=java.lang.NullPointerException:*) ;;
  *) printf 'total("missing") -> %s; expected a NullPointerException\n' "${line[2]}"; exit 1 ;;
esac
case ${line[2]} in
  *missing*) printf 'total("missing") named the offending id: %s\n' "${line[2]}"; exit 1 ;;
esac
case ${line[2]} in
  *Map.get*) ;;
  *) printf 'total("missing") -> %s; expected a message naming a Map internal\n' "${line[2]}"; exit 1 ;;
esac
