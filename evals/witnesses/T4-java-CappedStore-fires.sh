#!/usr/bin/env bash
# T4 fires on java/Ledger.java CappedStore: the Store put-then-get contract,
# parameterized over the constructor, holds for Store and fails for CappedStore.
cd "$(dirname "$0")/.." || exit 1
command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'javac or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp java/Ledger.java "$tmp/Ledger.java"
cat >"$tmp/T4Probe.java" <<'EOF'
import java.util.function.Supplier;

// The supertype's contract as one suite over a constructor: what put stores,
// total returns.
public class T4Probe {
    static String contract(Supplier<Ledger.Store> factory) {
        Ledger.Store s = factory.get();
        String[] ids = {"alpha", "beta", "gamma"};
        for (int i = 0; i < ids.length; i++) {
            double amount = i + 1;
            s.put(ids[i], amount);
            try {
                if (s.total(ids[i]) != amount) {
                    return "false";
                }
            } catch (RuntimeException e) {
                return "false";
            }
        }
        return "true";
    }

    public static void main(String[] argv) {
        System.out.println("Store: " + contract(Ledger.Store::new));
        System.out.println("CappedStore: " + contract(Ledger.CappedStore::new));
    }
}
EOF

build=$(javac -d "$tmp" "$tmp/Ledger.java" "$tmp/T4Probe.java" 2>&1) || {
  printf 'javac failed on the fixture plus probe: %s\n' "$build"; exit 1; }
out=$(java -cp "$tmp" T4Probe 2>&1) || {
  printf 'probe exited non-zero: %s\n' "$out"; exit 1; }

[ "$out" = 'Store: true
CappedStore: false' ] || {
  printf 'the put-then-get suite reported:\n%s\nexpected Store: true and CappedStore: false\n' "$out"
  exit 1; }
