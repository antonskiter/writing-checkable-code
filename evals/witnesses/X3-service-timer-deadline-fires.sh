#!/usr/bin/env bash
# X3 fires on service/timer.py deadline.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import datetime
import inspect

import timer

print("doc=%s" % " ".join((timer.deadline.__doc__ or "").split()))
print("annotated=%s" % any(p.annotation is not inspect.Parameter.empty
                           for p in inspect.signature(timer.deadline).parameters.values()))
print("milliseconds=%r" % (timer.deadline(0, 1500),))
try:
    datetime.datetime(1970, 1, 1) + 1500
    print("typed=accepted")
except TypeError:
    print("typed=refused")
RUN
)

doc=$(printf '%s\n' "$out" | sed -n 's/^doc=//p')
annotated=$(printf '%s\n' "$out" | sed -n 's/^annotated=//p')
ms=$(printf '%s\n' "$out" | sed -n 's/^milliseconds=//p')
typed=$(printf '%s\n' "$out" | sed -n 's/^typed=//p')
[ -n "$typed" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
case $doc in *seconds*) ;; *) printf 'the comment no longer states the unit: %s\n' "$doc"; exit 1 ;; esac
[ "$annotated" = False ] || { printf 'deadline now carries a type\n'; exit 1; }
[ "$ms" = 1500 ] || { printf 'deadline(0, 1500) gave %s\n' "$ms"; exit 1; }
[ "$typed" = refused ] || { printf 'the typed form accepts a bare number too\n'; exit 1; }
