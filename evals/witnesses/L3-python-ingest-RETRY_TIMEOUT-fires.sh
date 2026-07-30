#!/usr/bin/env bash
# L3 fires on python/ingest.py RETRY_TIMEOUT: no entry point in the tree reaches it, and
# deleting it leaves every module importable with every answer unchanged. The 30-second
# fact it names keeps two live homes in the same tree, so S1 fires here too and deleting
# the constant is not S1's repair.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -r python "$tmp/tree" || exit 1
rm -rf "$tmp/tree/__pycache__"

readers=$(grep -rn 'RETRY_TIMEOUT' "$tmp/tree") || {
  printf 'RETRY_TIMEOUT is not in the tree at all\n'; exit 1; }
[ "$(printf '%s\n' "$readers" | grep -c '')" = 1 ] || {
  printf 'RETRY_TIMEOUT is named more than once in the tree, so an entry point reaches it:\n%s\n' \
    "$readers"; exit 1; }

cat >"$tmp/probe.py" <<'EOF'
import billing
import ingest
import report

print(ingest.process('{"id": "a", "amount": 2}'))
print(ingest.process('{"amount": 2}'))
print(ingest.handle_event({"type": "quux"}))
print(ingest.validate_record({"id": "a", "amount": 1}))
print(report.classify(report.Interval(0, 60), 120, set()))
print(report.render_row("a", report.Interval(0, 60), "m", 0, "right", 12, "."))
print(billing.invoice_total([billing.Line(1, 100)]))
EOF

run() {
  (cd "$tmp/tree" && for m in *.py; do python3 -m py_compile "$m" || return 1; done) >/dev/null 2>&1 || return 1
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$tmp/tree" python3 "$tmp/probe.py" 2>&1
}

before=$(run) || { printf 'the tree does not run clean before the deletion:\n%s\n' "$(run)"; exit 1; }

grep -v '^RETRY_TIMEOUT = 30$' "$tmp/tree/ingest.py" >"$tmp/stripped" &&
  mv "$tmp/stripped" "$tmp/tree/ingest.py"
grep -q 'RETRY_TIMEOUT' "$tmp/tree/ingest.py" && {
  printf 'the deletion did not remove the definition\n'; exit 1; }

after=$(run) || { printf 'the tree stopped running after the deletion:\n%s\n' "$(run)"; exit 1; }
[ "$before" = "$after" ] || {
  printf 'the rerun changed after the deletion:\n%s\n---\n%s\n' "$before" "$after"; exit 1; }

homes=$(grep -rnE '\b30\b' "$tmp/tree" --include='*.py' | grep -c '')
[ "$homes" -ge 2 ] || {
  printf 'the 30-second deadline no longer has a second home in the tree (%s), so S1 does not stand beside this row\n' \
    "$homes"; exit 1; }
