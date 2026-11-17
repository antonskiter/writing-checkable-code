#!/usr/bin/env bash
# F3 fires on service/derived.py Results.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import derived

r = derived.Results({"a": 1, "b": 2, "c": "x"},
                    {"total": (("a", "b"), lambda a, b: a + b),
                     "label": (("c",), str.upper)})
r.value("total")
r.value("label")
r.write("c", "y")
print("last_known=%r" % (r.last_known("total"),))
print("total=%r" % (r.value("total"),))
print("computed=%s" % ",".join(r.computed))
RUN
)

last=$(printf '%s\n' "$out" | sed -n 's/^last_known=//p')
total=$(printf '%s\n' "$out" | sed -n 's/^total=//p')
computed=$(printf '%s\n' "$out" | sed -n 's/^computed=//p')
[ -n "$computed" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$total" = 3 ] || { printf 'total read %s, not 3\n' "$total"; exit 1; }
[ "$last" = None ] || {
  printf 'total kept %s as last known after an unrelated write\n' "$last"; exit 1; }
