#!/usr/bin/env bash
# X3 fires on python/ingest.py process: nothing states that raw is JSON text rather than
# the record itself, nor that the returned mapping carries a timeout taken from the
# environment. A call written from the signature alone is refused, and the answer to a
# correct one holds a field the signature never mentions.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 PERSIST_TIMEOUT=7 python3 - <<'RUN' 2>&1
import inspect
import ingest

src = inspect.getsource(ingest).splitlines()
line = next(i for i, l in enumerate(src) if l.startswith("def process("))
print("doc=%r" % (ingest.process.__doc__,))
print("above=%r" % (src[line - 1].strip(),))
print("sig=%s" % (inspect.signature(ingest.process),))
try:
    ingest.process({"id": "a", "amount": 1})
    print("record=accepted")
except Exception as exc:
    print("record=%s: %s" % (type(exc).__name__, exc))
print("text=%r" % (ingest.process('{"id": "a", "amount": 1}'),))
RUN
)

field() { printf '%s\n' "$out" | sed -n "s/^$1=//p"; }
[ -n "$(field text)" ] || { printf 'the run produced no answer:\n%s\n' "$out"; exit 1; }

[ "$(field doc)" = None ] || {
  printf 'process now carries an interface comment: %s\n' "$(field doc)"; exit 1; }
case $(field above) in
  "'#"*) printf 'process now carries a comment above it: %s\n' "$(field above)"; exit 1 ;;
esac

# A call written from the signature alone, passing the record the parameter names.
case $(field record) in
  *TypeError*JSON*) ;;
  accepted) printf 'process now accepts the record itself, so the signature no longer misleads\n'; exit 1 ;;
  *) printf 'the signature-faithful call answered %s; expected a refusal naming JSON\n' "$(field record)"; exit 1 ;;
esac

# The answer to a correct call carries a field taken from the environment.
[ "$(field text)" = "{'id': 'a', 'amount': 1, 'timeout': 7}" ] || {
  printf 'process answered %s; expected a mapping carrying the environment timeout 7\n' \
    "$(field text)"; exit 1; }
