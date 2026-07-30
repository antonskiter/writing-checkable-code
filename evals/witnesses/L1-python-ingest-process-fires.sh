#!/usr/bin/env bash
# L1 fires on python/ingest.py process: with _persist raising, the except Exception: pass
# discards the error and the caller receives None, so the failure reaches nobody.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 env -u PERSIST_TIMEOUT python3 - <<'RUN' 2>&1
import logging

import ingest

logging.disable(logging.CRITICAL)


def raising(record):
    raise RuntimeError("persist failed: disk full")


ingest._persist = raising
try:
    print("result=%r" % (ingest.process('{"id": "x", "amount": 1}'),))
except Exception as exc:
    print("result=raised %s: %s" % (type(exc).__name__, exc))
RUN
)

result=$(printf '%s\n' "$out" | sed -n 's/^result=//p')
[ -n "$result" ] || { printf 'process produced no answer:\n%s\n' "$out"; exit 1; }
[ "$result" = None ] || {
  printf 'the failing _persist reached the caller as %s, so the error is not discarded\n' \
    "$result"; exit 1; }
