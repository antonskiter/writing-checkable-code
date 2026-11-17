#!/usr/bin/env bash
# T5 fires on service/catalog.py Catalog.find.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))' || {
  printf 'python3 older than 3.10 cannot read the annotations\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import typing

import catalog

hints = typing.get_type_hints(catalog.Catalog.find)
print("key=%s" % hints["key"].__name__)
print("returns=%s" % hints["return"].__name__)
print("probe=%s" % ("b" in catalog.Catalog({"a": 1})))
try:
    print("absent=answered %r" % (catalog.Catalog({"a": 1}).find("b"),))
except Exception as exc:
    print("absent=raised %s" % type(exc).__name__)
RUN
)

key=$(printf '%s\n' "$out" | sed -n 's/^key=//p')
returns=$(printf '%s\n' "$out" | sed -n 's/^returns=//p')
absent=$(printf '%s\n' "$out" | sed -n 's/^absent=//p')
probe=$(printf '%s\n' "$out" | sed -n 's/^probe=//p')
[ -n "$absent" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$key" = str ] || { printf 'find takes %s, so "b" is no longer an argument it permits\n' "$key"; exit 1; }
[ "$returns" = int ] || {
  printf 'find now declares %s, which may carry the refusal\n' "$returns"; exit 1; }
[ "$probe" = False ] || { printf 'the membership probe answered %s\n' "$probe"; exit 1; }
[ "$absent" = "raised KeyError" ] || {
  printf 'an absent key gave %s, not an undeclared exception\n' "$absent"; exit 1; }
