#!/usr/bin/env bash
# T2 fires on python/report.py: the check is classify's refusal of an interval that ends
# before it starts, and it returns a string, not a type. The refused value is obtainable
# without running it, and render_row takes the same raw Interval and computes with it.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import inspect

import report

backwards = report.Interval(60, 0)
print("constructed=%r" % (backwards,))
try:
    report.classify(backwards, 0, set())
    print("check=accepted")
except Exception as exc:
    print("check=%s: %s" % (type(exc).__name__, exc))
print("returns=%s" % type(report.classify(report.Interval(0, 60), 120, set())).__name__)
print("downstream=%s" % (inspect.signature(report.render_row),))
print("rendered=%r" % (report.render_row("a", backwards, "m", 0, "right", 12, "."),))
RUN
)

field() { printf '%s\n' "$out" | sed -n "s/^$1=//p"; }
[ -n "$(field rendered)" ] || { printf 'the run produced no answer:\n%s\n' "$out"; exit 1; }

# The value the check refuses is obtainable without running the check.
[ "$(field constructed)" = "Interval(start=60, end=0)" ] || {
  printf 'Interval(60, 0) no longer constructs: %s\n' "$(field constructed)"; exit 1; }
case $(field check) in
  *ValueError*) ;;
  *) printf 'nothing refuses the value any more, so no check names the state: %s\n' "$(field check)"; exit 1 ;;
esac

# The check hands back no type, and the work downstream takes the raw one.
[ "$(field returns)" = str ] || {
  printf 'classify now returns %s, which may be the proof type\n' "$(field returns)"; exit 1; }
[ "$(field rendered)" = "'.......a-60m'" ] || {
  printf 'render_row answered %s for the refused interval; expected it to compute a negative span\n' \
    "$(field rendered)"; exit 1; }
