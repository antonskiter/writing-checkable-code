#!/usr/bin/env bash
# X6 fires on service/session.py Session.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import threading

import session

failures = []
threading.excepthook = lambda args: failures.append(type(args.exc_value).__name__)
opened = []


def connect():
    opened.append(session.Connection())
    return opened[-1]


s = session.Session(connect)
s.submit("queued", 0.1)
s.close()
print("in_flight_at_close=%d" % (threading.active_count() - 1))
for t in threading.enumerate():
    if t is not threading.main_thread():
        t.join()
print("after_close=%s" % (",".join(failures) or "none"))
try:
    s.notify("late")
    print("late=accepted")
except Exception as exc:
    print("late=refused %s" % type(exc).__name__)
print("opened=%d" % len(opened))
RUN
)

flight=$(printf '%s\n' "$out" | sed -n 's/^in_flight_at_close=//p')
after=$(printf '%s\n' "$out" | sed -n 's/^after_close=//p')
late=$(printf '%s\n' "$out" | sed -n 's/^late=//p')
opened=$(printf '%s\n' "$out" | sed -n 's/^opened=//p')
[ -n "$opened" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$flight" = 1 ] || { printf 'close returned with %s task(s) in flight, expected 1\n' "$flight"; exit 1; }
[ "$after" = RuntimeError ] || {
  printf 'the queued work after close gave %s, not a write on the released connection\n' "$after"
  exit 1; }
[ "$late" = accepted ] && [ "$opened" = 2 ] || {
  printf 'a notification after close was %s with %s connection(s) opened\n' "$late" "$opened"
  exit 1; }
