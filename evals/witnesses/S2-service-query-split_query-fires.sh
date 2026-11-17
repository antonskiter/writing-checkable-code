#!/usr/bin/env bash
# S2 fires on service/query.py split_query.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

out=$(cd service && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
from urllib.parse import parse_qsl

import query

for name, given in (("plain", "a=1&b=2"), ("percent", "q=a%20b"), ("plus", "q=a+b")):
    same = query.split_query(given) == parse_qsl(given, keep_blank_values=True)
    print("%s=%s" % (name, "same" if same else "differs"))
RUN
)

plain=$(printf '%s\n' "$out" | sed -n 's/^plain=//p')
percent=$(printf '%s\n' "$out" | sed -n 's/^percent=//p')
plus=$(printf '%s\n' "$out" | sed -n 's/^plus=//p')
[ -n "$plus" ] || { printf 'the comparison did not run:\n%s\n' "$out"; exit 1; }
[ "$plain" = same ] || {
  printf 'split_query and parse_qsl disagree on a plain query, so they are not one rule\n'; exit 1; }
[ "$percent" = differs ] && [ "$plus" = differs ] || {
  printf 'percent: %s, plus: %s; expected the second home to answer differently on both\n' \
    "$percent" "$plus"; exit 1; }
