#!/usr/bin/env bash
# T1 fires on ts/orders.ts: the state isOrder names — an id that is not a string, an amount
# that is not a number — inhabits Order all the same, because load casts the parsed
# document. Constructed that way it reaches the arithmetic in totals and persist.
cd "$(dirname "$0")/.." || exit 1
command -v node >/dev/null 2>&1 || { printf 'node not installed\n'; exit 77; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp ts/*.ts "$tmp/" || exit 1
printf 'const probe: number = 1;\nconsole.log(probe);\n' >"$tmp/probe.ts"
node "$tmp/probe.ts" >/dev/null 2>&1 || {
  printf 'this node cannot run TypeScript directly\n'; exit 77; }
# node erases type annotations without resolving imports, so the copy marks the tree's one
# type-only import as a type and names the file it resolves to. Nothing else is changed.
imports=$(grep -cF 'import { Order } from "./orders";' "$tmp/report.ts")
[ "$imports" = 1 ] || { printf 'expected one type-only import to adapt, found %s\n' "$imports"; exit 1; }
sed -i 's|import { Order } from "./orders";|import type { Order } from "./orders.ts";|' "$tmp/report.ts"

# The cast is what lets the named state inhabit the type.
grep -qF 'JSON.parse(raw) as Order[]' "$tmp/report.ts" || {
  printf 'load no longer casts the parsed document to Order[]\n'; exit 1; }

cat >"$tmp/run.mjs" <<'EOF'
const o = await import("./orders.ts");
const r = await import("./report.ts");
const rows = r.load('[{"id":1,"amount":"x"}]');
const summed = r.totals(rows);
console.log([o.isOrder(rows[0]), typeof Object.values(summed)[0],
  JSON.stringify(summed), o.persist(rows[0]).amount].join("|"));
EOF
out=$(cd "$tmp" && node run.mjs 2>&1) || { printf 'the probe failed: %s\n' "$out"; exit 1; }

[ "$out" = 'false|string|{"1":"0x"}|NaN' ] || {
  printf 'the probe reported %s; expected isOrder to reject the row, totals to answer a string where its type says number, and persist to answer NaN\n' \
    "$out"; exit 1; }
