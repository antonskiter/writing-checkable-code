#!/usr/bin/env bash
# F1 fires on python/billing.py invoice_total: it reaches line_total directly and
# again through subtotal, a level it had already delegated.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd python && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import sys

import billing

reached = []
real = billing.line_total


def probe(line):
    names = []
    frame = sys._getframe(1)
    while frame is not None:
        names.append(frame.f_code.co_name)
        if frame.f_code.co_name == "invoice_total":
            break
        frame = frame.f_back
    reached.append(tuple(names))
    return real(line)


billing.line_total = probe
billing.invoice_total([billing.Line(1, 10), billing.Line(1, 20)])
direct = [p for p in reached if p[:1] == ("invoice_total",)]
through = [p for p in reached if "subtotal" in p and "invoice_total" in p]
print("callers=%s" % (reached,))
print("direct=%d through_subtotal=%d" % (len(direct), len(through)))
RUN
)

counts=$(printf '%s\n' "$out" | sed -n 's/^direct=//p')
[ -n "$counts" ] || { printf 'the probe did not report; the run emitted:\n%s\n' "$out"; exit 1; }
direct=${counts%% *}
through=${counts##*through_subtotal=}
[ "$direct" -ge 1 ] && [ "$through" -ge 1 ] || {
  printf 'line_total reached directly %s time(s) and through subtotal %s time(s); %s\n' \
    "$direct" "$through" "$(printf '%s\n' "$out" | sed -n 's/^callers=//p')"; exit 1; }
