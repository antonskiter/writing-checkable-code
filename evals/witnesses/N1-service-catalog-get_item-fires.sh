#!/usr/bin/env bash
# N1 fires on service/catalog.py Catalog.get_item.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import catalog

c = catalog.Catalog({"a": 1, "b": 2})
print("before=%s" % ",".join(c.recent()))
print("answers=%r,%r" % (c.get_item("a"), c.get_item("b")))
print("after=%s" % ",".join(c.recent()))
RUN
)

before=$(printf '%s\n' "$out" | sed -n 's/^before=//p')
answers=$(printf '%s\n' "$out" | sed -n 's/^answers=//p')
after=$(printf '%s\n' "$out" | sed -n 's/^after=//p')
[ -n "$answers" ] || { printf 'the probe did not run:\n%s\n' "$out"; exit 1; }
[ "$answers" = 1,2 ] || { printf 'get_item answered %s\n' "$answers"; exit 1; }
[ "$before" != "$after" ] || {
  printf 'recent() answered %s before and after, so the query writes nothing\n' "$after"; exit 1; }
