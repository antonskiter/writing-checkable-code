#!/usr/bin/env bash
# X1 fires on java/Ledger.java renderRow: align="up" is an unknown alignment and
# is silently left-aligned rather than refused.
cd "$(dirname "$0")/.." || exit 1
command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'javac or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp java/Ledger.java "$tmp/Ledger.java"
cat >"$tmp/AlignProbe.java" <<'EOF'
public class AlignProbe {
    public static void main(String[] argv) {
        Ledger ledger = new Ledger();
        for (String align : new String[] {"up", "left", "right"}) {
            try {
                System.out.println(align + "=" + ledger.renderRow("x", 1, "u", 2, align, 12, '.'));
            } catch (RuntimeException e) {
                System.out.println(align + "=refused " + e.getClass().getName());
            }
        }
    }
}
EOF

build=$(javac -d "$tmp" "$tmp/Ledger.java" "$tmp/AlignProbe.java" 2>&1) || {
  printf 'javac failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp" AlignProbe 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'up=x1.00u......
left=x1.00u......
right=......x1.00u' ] || {
  printf 'renderRow reported:\n%s\nexpected align="up" to be silently left-aligned as x1.00u......\n' "$out"
  exit 1; }
