#!/usr/bin/env bash
# M1 stays silent on python/report.py render_row: seven parameters, every one a
# value the caller chooses, and the call answers with nothing else of the module
# having run. The one argument another unit of the module could produce — an
# Interval — the caller builds from two integers of its own, so no value the
# producer neither took nor returned is in play.
#
# The same assertion over the eval sandbox's formatter, files/render.py
# render_cell: seven caller-chosen parameters and a docstring, still silent. The
# docstring changes nothing either way, which is the point — the row reads
# signatures, X3 reads the comment.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(python3 - <<'PY' 2>&1
import sys
sys.path[:0] = ["python", "files"]
import report, render


def outcome(label, call):
    try:
        print(f"{label}: answers width={len(call())}")
    except Exception as exc:
        print(f"{label}: fails {type(exc).__name__}")


# Arguments written from the signature alone, nothing else of the module run.
outcome("render_row", lambda: report.render_row(
    "a", report.Interval(0, 60), "m", 2, "right", 10, "."))
outcome("render_cell", lambda: render.render_cell("a", 1.0, "kg", 2, "right", 10, "."))

# Both formatters take seven parameters. Counting is not the subject.
import inspect
for name, fn in (("render_row", report.render_row), ("render_cell", render.render_cell)):
    print(f"{name}: {len(inspect.signature(fn).parameters)} parameters")

# render_cell carries a docstring; render_row does not. Same verdict.
print("render_cell docstring:", "yes" if render.render_cell.__doc__ else "no")
print("render_row docstring:", "yes" if report.render_row.__doc__ else "no")
PY
)

[ "$out" = 'render_row: answers width=10
render_cell: answers width=10
render_row: 7 parameters
render_cell: 7 parameters
render_cell docstring: yes
render_row docstring: no' ] || {
  printf 'the probe reported:\n%s\nexpected both formatters to answer alone, at seven parameters, with and without a docstring\n' "$out"
  exit 1; }
