#!/usr/bin/env bash
# X1 fires on python/ingest.py process: a record with a non-numeric amount completes
# normally as None, and the message it logs omits the offending value.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 env -u PERSIST_TIMEOUT python3 - <<'RUN' 2>&1
import logging

import ingest

said = []


class Collect(logging.Handler):
    def emit(self, record):
        said.append(record.getMessage())


ingest.log.addHandler(Collect())
ingest.log.setLevel(logging.DEBUG)
ingest.log.propagate = False
try:
    print("result=%r" % (ingest.process('{"id": "x", "amount": "oops"}'),))
except Exception as exc:
    print("result=raised %s: %s" % (type(exc).__name__, exc))
print("said=%s" % " | ".join(said))
RUN
)

result=$(printf '%s\n' "$out" | sed -n 's/^result=//p')
said=$(printf '%s\n' "$out" | sed -n 's/^said=//p')
[ -n "$result" ] || { printf 'process produced no answer:\n%s\n' "$out"; exit 1; }
[ "$result" = None ] || {
  printf 'process answered %s for a bad record, so it does not complete normally\n' "$result"; exit 1; }
[ -n "$said" ] || { printf 'process said nothing at all; X1 is judged at its effect here\n'; exit 1; }
case $said in
  *oops*) printf 'the message names the offending value: %s\n' "$said"; exit 1 ;;
esac
