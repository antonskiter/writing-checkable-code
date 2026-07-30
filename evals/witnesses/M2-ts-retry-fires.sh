#!/usr/bin/env bash
# M2 fires on ts/orders.ts retry: the retry budget it spends is a module binding, not a
# parameter. Two runs in one process spend the same 3, and the only lever for a second
# value is a write the module binding refuses.
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

# The setting reaches retry by no parameter of its own.
grep -qxF 'export function retry(url: string): Promise<Response> {' "$tmp/orders.ts" || {
  printf 'retry no longer takes the url alone, so the setting may now arrive as a parameter\n'
  exit 1; }

cat >"$tmp/run.mjs" <<'EOF'
const o = await import("./orders.ts");
const spent = [];
globalThis.fetch = (url, options) => { spent.push(options.retries); return Promise.resolve("stub"); };
await o.retry("http://127.0.0.1:1/first");
let lever = "silently ignored";
try {
  o.RETRY_LIMIT = 9;
} catch (e) {
  lever = e.constructor.name;
}
await o.retry("http://127.0.0.1:1/second");
console.log([lever, spent.join(",")].join("|"));
EOF
out=$(cd "$tmp" && node run.mjs 2>&1) || { printf 'the probe failed: %s\n' "$out"; exit 1; }

[ "$out" = 'TypeError|3,3' ] || {
  printf 'the probe reported %s; expected the module binding to refuse the second value and both runs to spend 3\n' \
    "$out"; exit 1; }
