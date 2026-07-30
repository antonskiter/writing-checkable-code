#!/usr/bin/env bash
# S2 fires on python/ingest.py: with the id rule tightened at validate_record alone,
# {"id": "", "amount": 1} gets two answers — process refuses it, _persist stores it.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp python/ingest.py "$tmp/ingest.py" || exit 1

python3 - "$tmp/ingest.py" <<'PATCH' || exit 1
import sys

path = sys.argv[1]
src = open(path).read()
loose = '    if "id" not in record:\n        return False\n    return isinstance('
tight = '    if not record.get("id"):\n        return False\n    return isinstance('
if loose not in src:
    sys.exit("validate_record's id guard is not the text this witness tightens")
open(path, "w").write(src.replace(loose, tight, 1))
PATCH

out=$(cd "$tmp" && PYTHONDONTWRITEBYTECODE=1 env -u PERSIST_TIMEOUT python3 - <<'RUN' 2>&1
import logging

import ingest

logging.disable(logging.CRITICAL)
print("process=%r" % (ingest.process('{"id": "", "amount": 1}'),))
try:
    print("persist=%r" % (ingest._persist({"id": "", "amount": 1}),))
except Exception as exc:
    print("persist=refused %s: %s" % (type(exc).__name__, exc))
RUN
)

process=$(printf '%s\n' "$out" | sed -n 's/^process=//p')
persist=$(printf '%s\n' "$out" | sed -n 's/^persist=//p')
[ -n "$process" ] && [ -n "$persist" ] || {
  printf 'the patched module did not answer both entry points; it emitted:\n%s\n' "$out"; exit 1; }
[ "$process" = None ] || {
  printf 'process answered %s, not None: the tightened rule did not reach it\n' "$process"; exit 1; }
[ "$persist" = "{'id': '', 'amount': 1, 'timeout': 30}" ] || {
  printf '_persist answered %s; with process answering None that is one answer, not two\n' "$persist"; exit 1; }
