#!/usr/bin/env bash
# F3 fires on python/billing.py Cart: total is derived and stored, and add(40) moves the
# source to 100 while read() still returns 60, with no failing assertion and no bound.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import billing

cart = billing.Cart([60])
print("initial=%r" % (cart.read(),))
try:
    cart.add(40)
    print("add=ok")
except Exception as exc:
    print("add=refused %s: %s" % (type(exc).__name__, exc))
print("source=%r" % (sum(cart._items),))
try:
    print("read=%r" % (cart.read(),))
except Exception as exc:
    print("read=refused %s: %s" % (type(exc).__name__, exc))
RUN
)

initial=$(printf '%s\n' "$out" | sed -n 's/^initial=//p')
add=$(printf '%s\n' "$out" | sed -n 's/^add=//p')
source=$(printf '%s\n' "$out" | sed -n 's/^source=//p')
readback=$(printf '%s\n' "$out" | sed -n 's/^read=//p')
[ -n "$readback" ] || { printf 'the run did not get as far as a read back:\n%s\n' "$out"; exit 1; }
[ "$initial" = 60 ] || { printf 'Cart([60]) read %s before the source moved\n' "$initial"; exit 1; }
[ "$add" = ok ] || { printf 'add(40) did not complete: %s\n' "$add"; exit 1; }
[ "$source" = 100 ] || { printf 'the source is %s after add(40), not 100\n' "$source"; exit 1; }
[ "$readback" = 60 ] || {
  printf 'read() returned %s against a source of %s: no stale read to find\n' "$readback" "$source"; exit 1; }
