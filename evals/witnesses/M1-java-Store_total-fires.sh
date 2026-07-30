#!/usr/bin/env bash
# M1 fires on java/Ledger.java Store.total: called alone, with an argument written
# from its signature, it fails; it succeeds once put has run, so the ordering
# requirement is real and no signature or type carries it.
#
# The same script separates the row from X3 and from X1 at the same site:
#   - an interface comment stating the ordering makes X3's call run clean and
#     leaves total(id) alone still failing;
#   - X1's change — stop and name the offending value — clears X1 and leaves
#     total(id) alone still failing;
#   - returning Optional<Double> clears the row: the call alone answers.
cd "$(dirname "$0")/.." || exit 1
command -v javac >/dev/null 2>&1 && command -v java >/dev/null 2>&1 || {
  printf 'javac or java not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

python3 - "$tmp" <<'PY' || { printf 'python3 unavailable, or a body this witness patches has changed\n'; exit 77; }
import sys, os
out = sys.argv[1]
src = open("java/Ledger.java").read()
total = """        public double total(String id) {
            return entries.get(id);
        }"""
assert total in src, "Store.total is not the body this witness patches"

commented = src.replace(total, """        /**
         * Returns the amount stored for id. Call put(id, amount) first: total
         * throws if the id has never been put.
         */
""" + total)

named = src.replace(total, """        public double total(String id) {
            Double found = entries.get(id);
            if (found == null) {
                throw new java.util.NoSuchElementException("no entry for id " + id);
            }
            return found;
        }""")

optional = src.replace(total, """        public java.util.Optional<Double> total(String id) {
            return java.util.Optional.ofNullable(entries.get(id));
        }""")

for name, text in (("plain", src), ("commented", commented),
                   ("named", named), ("optional", optional)):
    os.mkdir(os.path.join(out, name))
    open(os.path.join(out, name, "Ledger.java"), "w").write(text)
PY

cat >"$tmp/Probe.java" <<'EOF'
public class Probe {
    // M1: the later unit alone, its argument written from the signature.
    static String alone() {
        try { return "answers " + new Ledger.Store().total("alpha"); }
        catch (Throwable t) { return "fails " + t.getClass().getSimpleName(); }
    }
    // M1: the same call after the earlier unit has run.
    static String afterPut() {
        try {
            Ledger.Store s = new Ledger.Store();
            s.put("alpha", 1.0);
            return "answers " + s.total("alpha");
        } catch (Throwable t) { return "fails " + t.getClass().getSimpleName(); }
    }
    // X3: a call written from the signature and whatever comment is there. Only a
    // comment stating the ordering puts the put() line in the caller's hands.
    static String fromRecord(boolean commentStatesTheOrdering) {
        try {
            Ledger.Store s = new Ledger.Store();
            if (commentStatesTheOrdering) { s.put("alpha", 1.0); }
            return "answers " + s.total("alpha");
        } catch (Throwable t) { return "fails " + t.getClass().getSimpleName(); }
    }
    // X1: does the failure name the offending value?
    static String namesValue() {
        try { new Ledger.Store().total("alpha"); return "no failure"; }
        catch (Throwable t) {
            return String.valueOf(t.getMessage()).contains("alpha") ? "names alpha" : "omits alpha";
        }
    }
    public static void main(String[] a) {
        boolean commented = a.length > 0 && a[0].equals("with-comment");
        System.out.println("alone: " + alone());
        System.out.println("afterPut: " + afterPut());
        System.out.println("fromRecord: " + fromRecord(commented));
        System.out.println("namesValue: " + namesValue());
    }
}
EOF

run() {
  local dir=$1 build
  build=$(javac -d "$tmp/$dir" "$tmp/$dir/Ledger.java" "$tmp/Probe.java" 2>&1) || {
    printf 'javac failed on %s: %s\n' "$dir" "$build"; exit 1; }
  java -cp "$tmp/$dir" Probe "${2:-}" 2>&1
}

expect() {
  local label=$1 got=$2 want=$3
  [ "$got" = "$want" ] || {
    printf '%s:\n%s\nexpected:\n%s\n' "$label" "$got" "$want"; exit 1; }
}

# No comment: X3's call is total alone, and it fails. M1's call fails too.
expect 'the fixture as it stands' "$(run plain)" 'alone: fails NullPointerException
afterPut: answers 1.0
fromRecord: fails NullPointerException
namesValue: omits alpha'

# With the ordering in a comment: X3's call runs clean, M1's still fails.
expect 'a comment stating the ordering — X3 clears, M1 does not' "$(run commented with-comment)" \
'alone: fails NullPointerException
afterPut: answers 1.0
fromRecord: answers 1.0
namesValue: omits alpha'

expect "after X1's change — X1 clears, M1 does not" "$(run named)" \
'alone: fails NoSuchElementException
afterPut: answers 1.0
fromRecord: fails NoSuchElementException
namesValue: names alpha'

# The clearing change: the signature admits the call that used to fail.
build=$(javac -d "$tmp/optional" "$tmp/optional/Ledger.java" 2>&1) || {
  printf 'javac failed on the Optional variant: %s\n' "$build"; exit 1; }
cat >"$tmp/OptionalProbe.java" <<'EOF'
public class OptionalProbe {
    public static void main(String[] a) {
        try { System.out.println("alone: answers " + new Ledger.Store().total("alpha")); }
        catch (Throwable t) { System.out.println("alone: fails " + t.getClass().getSimpleName()); }
    }
}
EOF
build=$(javac -cp "$tmp/optional" -d "$tmp/optional" "$tmp/OptionalProbe.java" 2>&1) || {
  printf 'javac failed on the Optional probe: %s\n' "$build"; exit 1; }
expect 'after total returns Optional<Double> — the row clears' \
  "$(java -cp "$tmp/optional" OptionalProbe 2>&1)" 'alone: answers Optional.empty'

# The row's silence in the same tree: seven caller-chosen parameters, called alone.
cat >"$tmp/WideProbe.java" <<'EOF'
public class WideProbe {
    public static void main(String[] a) {
        // What the row turns on is that the call answers at all, not how it formats.
        try {
            String row = new Ledger().renderRow("a", 1.0, "kg", 2, "right", 10, '.');
            System.out.println("renderRow: answers width=" + row.length());
        } catch (Throwable t) { System.out.println("renderRow: fails " + t); }
    }
}
EOF
build=$(javac -cp "$tmp/plain" -d "$tmp/plain" "$tmp/WideProbe.java" 2>&1) || {
  printf 'javac failed on the wide-signature probe: %s\n' "$build"; exit 1; }
expect 'renderRow, seven caller-chosen parameters, called alone' \
  "$(java -cp "$tmp/plain" WideProbe 2>&1)" 'renderRow: answers width=10'
