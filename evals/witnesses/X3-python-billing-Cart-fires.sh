#!/usr/bin/env bash
# X3 fires on python/billing.py Cart: the comment says totals are in whole cents, yet a
# call written from it alone, Cart([1.5, 2.25]), totals 3.75.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import billing

doc = " ".join((billing.Cart.__doc__ or "").split())
print("doc=%s" % doc)
try:
    print("total=%r" % (billing.Cart([1.5, 2.25]).read(),))
except Exception as exc:
    print("total=refused %s: %s" % (type(exc).__name__, exc))
RUN
)

doc=$(printf '%s\n' "$out" | sed -n 's/^doc=//p')
total=$(printf '%s\n' "$out" | sed -n 's/^total=//p')
[ -n "$total" ] || { printf 'the run produced no total:\n%s\n' "$out"; exit 1; }
case $(printf '%s' "$doc" | tr '[:upper:]' '[:lower:]') in
  *"whole cents"*) ;;
  *) printf 'the comment no longer claims whole cents; it reads: %s\n' "$doc"; exit 1 ;;
esac
[ "$total" = 3.75 ] || {
  printf 'Cart([1.5, 2.25]).read() gave %s, so the call written from the comment is not contradicted\n' \
    "$total"; exit 1; }
