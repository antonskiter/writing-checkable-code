#!/usr/bin/env bash
# X3 fires on python/report.py classify: nothing states that now is measured in minutes
# since midnight, the unit only Interval's own comment gives. One situation therefore has
# two answers — future under the documented unit, past under a clock reading of "now".
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import inspect
import time

import report

src = inspect.getsource(report).splitlines()
line = next(i for i, l in enumerate(src) if l.startswith("def classify("))
print("doc=%r" % (report.classify.__doc__,))
print("above=%r" % (src[line - 1].strip(),))
interval = report.Interval(9 * 60, 10 * 60)      # 09:00-10:00, per Interval's comment
print("minutes=%s" % report.classify(interval, 8 * 60, set()))
print("clock=%s" % report.classify(interval, time.time(), set()))
RUN
)

field() { printf '%s\n' "$out" | sed -n "s/^$1=//p"; }
[ -n "$(field clock)" ] || { printf 'the run produced no answer:\n%s\n' "$out"; exit 1; }

[ "$(field doc)" = None ] || {
  printf 'classify now carries an interface comment: %s\n' "$(field doc)"; exit 1; }
case $(field above) in
  "'#"*) printf 'classify now carries a comment above it: %s\n' "$(field above)"; exit 1 ;;
esac

[ "$(field minutes)" = future ] || {
  printf 'the same interval under the documented unit answered %s, not future\n' "$(field minutes)"; exit 1; }
[ "$(field clock)" = past ] || {
  printf 'the same interval under a clock reading of now answered %s, not past: the unit is no longer a detail only the body gives\n' \
    "$(field clock)"; exit 1; }
