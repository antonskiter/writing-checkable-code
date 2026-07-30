#!/usr/bin/env bash
# T1 fires on python/ingest.py: validate_record names the non-numeric amount, yet
# _persist({"id": "x", "amount": "oops"}) reaches the work and returns the record.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 env -u PERSIST_TIMEOUT python3 - <<'RUN' 2>&1
import ingest

bad = {"id": "x", "amount": "oops"}
print("named=%r" % (ingest.validate_record(dict(bad)),))
try:
    print("persist=%r" % (ingest._persist(dict(bad)),))
except Exception as exc:
    print("persist=refused %s: %s" % (type(exc).__name__, exc))
RUN
)

named=$(printf '%s\n' "$out" | sed -n 's/^named=//p')
persist=$(printf '%s\n' "$out" | sed -n 's/^persist=//p')
[ -n "$persist" ] || { printf '_persist produced no answer:\n%s\n' "$out"; exit 1; }
[ "$named" = False ] || {
  printf 'validate_record answered %s for a non-numeric amount: no site names the state\n' \
    "$named"; exit 1; }
[ "$persist" = "{'id': 'x', 'amount': 'oops', 'timeout': 30}" ] || {
  printf '_persist answered %s: the named state does not reach the work\n' "$persist"; exit 1; }
