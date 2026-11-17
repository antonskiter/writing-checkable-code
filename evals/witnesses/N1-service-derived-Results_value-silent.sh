#!/usr/bin/env bash
# N1 stays silent on service/derived.py Results.value.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import copy

import derived

formulas = {"total": (("a", "b"), lambda a, b: a + b)}
r = derived.Results({"a": 1, "b": 2}, formulas)
before = copy.deepcopy(vars(r))
r.value("total")
after = vars(r)
print("written=%s" % ",".join(sorted(k for k in after if after[k] != before[k])))
reads, formula = formulas["total"]
recomputed = formula(*(after["_inputs"][n] for n in reads))
print("matches=%s" % all(v == recomputed for _, v in after["_values"].values()))
RUN
)

written=$(printf '%s\n' "$out" | sed -n 's/^written=//p')
matches=$(printf '%s\n' "$out" | sed -n 's/^matches=//p')
[ -n "$matches" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$written" = _values,computed ] || {
  printf 'value wrote %s; expected only the stored derived value and the formula log\n' "$written"
  exit 1; }
[ "$matches" = True ] || { printf 'value stored a value a recompute does not give\n'; exit 1; }
