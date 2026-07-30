#!/usr/bin/env bash
# X3 fires on ts/report.ts load: its signature promises Order[] and nothing states what a
# JSON document that is not an array becomes. A call written from the signature alone —
# map over the rows it returns — is answered with the parsed object and throws.
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

# There is no interface comment above load to write the call from.
doc=$(awk '/^export function load\(/ { print prev } { prev = $0 }' "$tmp/report.ts")
case $doc in
  '//'*|'*'*|'*/'*) printf 'load now carries an interface comment: %s\n' "$doc"; exit 1 ;;
esac

cat >"$tmp/run.mjs" <<'EOF'
const r = await import("./report.ts");
const object = r.load('{"id":"a","amount":1}');
let mapped;
try {
  mapped = JSON.stringify(r.load('{"id":"a","amount":1}').map((o) => o.id));
} catch (e) {
  mapped = "threw " + e.constructor.name;
}
console.log([Array.isArray(object), JSON.stringify(object), mapped,
  JSON.stringify(r.load("not json"))].join("|"));
EOF
out=$(cd "$tmp" && node run.mjs 2>&1) || { printf 'the probe failed: %s\n' "$out"; exit 1; }

[ "$out" = 'false|{"id":"a","amount":1}|threw TypeError|[]' ] || {
  printf 'load answered %s; expected a non-array from a JSON object, a throw from mapping it, and [] from malformed text\n' \
    "$out"; exit 1; }
