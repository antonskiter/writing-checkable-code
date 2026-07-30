#!/usr/bin/env bash
# F4 fires on python/report.py classify: permuting the future and holiday branches turns
# Interval(500, 600) with now=100 and holidays={500} from "future" into "holiday".
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
cp python/report.py "$tmp/report.py" || exit 1

python3 - "$tmp/report.py" "$tmp/permuted.py" <<'PATCH' || exit 1
import ast
import sys

tree = ast.parse(open(sys.argv[1]).read())
fn = next((n for n in tree.body
           if isinstance(n, ast.FunctionDef) and n.name == "classify"), None)
if fn is None:
    sys.exit("report.py declares no classify to permute")
at = [i for i, stmt in enumerate(fn.body) if isinstance(stmt, ast.If)]
if len(at) != 3:
    sys.exit("classify holds %d if-statements, not the 3 this witness permutes" % len(at))
first, second = at[1], at[2]
fn.body[first], fn.body[second] = fn.body[second], fn.body[first]
open(sys.argv[2], "w").write(ast.unparse(ast.fix_missing_locations(tree)))
PATCH

out=$(cd "$tmp" && PYTHONDONTWRITEBYTECODE=1 python3 - <<'RUN' 2>&1
import permuted
import report

case = (report.Interval(500, 600), 100, {500})
print("as-written=%s" % report.classify(*case))
print("permuted=%s" % permuted.classify(*case))
RUN
)

written=$(printf '%s\n' "$out" | sed -n 's/^as-written=//p')
permuted=$(printf '%s\n' "$out" | sed -n 's/^permuted=//p')
[ -n "$written" ] && [ -n "$permuted" ] || {
  printf 'classify did not answer both orderings; the run emitted:\n%s\n' "$out"; exit 1; }
[ "$written" = future ] && [ "$permuted" = holiday ] || {
  printf 'as written %s, permuted %s: the result does not turn on branch position\n' \
    "$written" "$permuted"; exit 1; }
