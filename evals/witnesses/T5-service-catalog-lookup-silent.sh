#!/usr/bin/env bash
# T5 stays silent on service/catalog.py Catalog.lookup.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))' || {
  printf 'python3 older than 3.10 cannot read the annotations\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import typing

import catalog

returns = typing.get_type_hints(catalog.Catalog.lookup)["return"]
print("declares_none=%s" % (type(None) in typing.get_args(returns)))
try:
    print("absent=answered %r" % (catalog.Catalog({"a": 1}).lookup("b"),))
except Exception as exc:
    print("absent=raised %s" % type(exc).__name__)
RUN
)

declares=$(printf '%s\n' "$out" | sed -n 's/^declares_none=//p')
absent=$(printf '%s\n' "$out" | sed -n 's/^absent=//p')
[ -n "$absent" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$declares" = True ] || { printf 'lookup no longer declares the absent case\n'; exit 1; }
[ "$absent" = "answered None" ] || {
  printf 'an absent key gave %s, outside what the signature declares\n' "$absent"; exit 1; }
