#!/usr/bin/env bash
# S1 stays silent on python/billing.py TAX_RATE: nothing else in this tree states the
# rate, and changing the one home changes every behaviour that depends on it.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# The tree under review is python/, searched whole — every file the build reads, not
# billing.py alone. The rate stated as 0.2, as 20 percent or as the 1.2 multiplier.
elsewhere=$(grep -rEnI '0\.2|\b20\b|\b1\.2\b' python --exclude-dir=__pycache__ |
  grep -v '^python/billing\.py:[0-9]*:TAX_RATE = 0\.2$')
[ -z "$elsewhere" ] || {
  printf 'the rate is stated a second time in this tree:\n%s\n' "$elsewhere"; exit 1; }

readers=$(grep -rnI 'TAX_RATE' python --exclude-dir=__pycache__ | grep -cv 'TAX_RATE = 0\.2$')
[ "$readers" -ge 1 ] || {
  printf 'TAX_RATE has no reader, so changing it changes no behaviour and S1 is not the row\n'
  exit 1; }

sed 's/^TAX_RATE = 0\.2$/TAX_RATE = 0.5/' python/billing.py >"$tmp/billing_at_half.py"
grep -q '^TAX_RATE = 0\.5$' "$tmp/billing_at_half.py" || {
  printf 'the one home is not the line this witness changes\n'; exit 1; }

out=$(PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="python:$tmp" python3 - <<'RUN' 2>&1
import billing
import billing_at_half

lines = [billing.Line(1, 100)]
print("as-written=%r" % (billing.invoice_total(lines),))
print("at-half=%r" % (billing_at_half.invoice_total([billing_at_half.Line(1, 100)]),))
RUN
)

written=$(printf '%s\n' "$out" | sed -n 's/^as-written=//p')
half=$(printf '%s\n' "$out" | sed -n 's/^at-half=//p')
[ -n "$half" ] || { printf 'the two runs did not both answer:\n%s\n' "$out"; exit 1; }
[ "$written" = 120.0 ] && [ "$half" = 150.0 ] || {
  printf 'invoice_total answered %s at 0.2 and %s at 0.5: a dependent still behaves by the old value\n' \
    "$written" "$half"; exit 1; }
