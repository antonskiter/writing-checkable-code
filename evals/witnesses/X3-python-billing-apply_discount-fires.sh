#!/usr/bin/env bash
# X3 fires on python/billing.py apply_discount: the comment does not say pct is a
# fraction, so a call written from it alone, apply_discount(100, 20), returns -1900.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import billing

doc = " ".join((billing.apply_discount.__doc__ or "").split())
print("doc=%s" % doc)
try:
    print("result=%r" % (billing.apply_discount(100, 20),))
except Exception as exc:
    print("result=refused %s: %s" % (type(exc).__name__, exc))
RUN
)

doc=$(printf '%s\n' "$out" | sed -n 's/^doc=//p')
result=$(printf '%s\n' "$out" | sed -n 's/^result=//p')
[ -n "$result" ] || { printf 'the run produced no result:\n%s\n' "$out"; exit 1; }
lower=$(printf '%s' "$doc" | tr '[:upper:]' '[:lower:]')
for scale in fraction ratio percent % /100 "0 and 1" "[0, 1]" "[0,1]" 0.0 1.0; do
  case $lower in
    *"$scale"*) printf 'the comment now states the scale of pct (%s): %s\n' "$scale" "$doc"; exit 1 ;;
  esac
done
[ "$result" = -1900 ] || {
  printf 'apply_discount(100, 20) gave %s, so pct on its documented reading is not wrong\n' \
    "$result"; exit 1; }
