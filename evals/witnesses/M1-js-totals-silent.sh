#!/usr/bin/env bash
# M1 stays silent on js/orders.js totals: it answers called alone, and what the
# module's producer hands back — ingest's order — goes straight into it, so no
# value ingest neither took nor returned has to be passed. persist's product, the
# module-level cache, is reached by no argument at all.
cd "$(dirname "$0")/.." || exit 1
command -v node >/dev/null 2>&1 || { printf 'node not installed\n'; exit 77; }

out=$(node -e '
const o = require("./js/orders.js");
const outcome = (label, f) => {
  try { console.log(label + ": answers " + JSON.stringify(f())); }
  catch (e) { console.log(label + ": fails " + e.constructor.name); }
};
const raw = JSON.stringify({ id: "a", amount: 1 });
outcome("alone", () => o.totals([{ id: "a", amount: 1 }]));
outcome("fromProducer", () => o.totals([o.ingest(raw)]));
outcome("persistThenTotals", () => { o.persist({ id: "a", amount: 1 }); return o.totals([]); });
' 2>&1)

[ "$out" = 'alone: answers {"a":1}
fromProducer: answers {"a":1}
persistThenTotals: answers {}' ] || {
  printf 'the probe reported:\n%s\nexpected totals to answer alone and to take what ingest returns\n' "$out"
  exit 1; }
