# Verdict corpus

Development apparatus, not part of the skill. `evals/` is excluded when the
skill is packaged (`package_skill.py` strips it at the root) and by
`.gitattributes export-ignore` from release archives; a `git clone` still
carries it. The usage-time half of this file — where each row must stay silent —
is kept as `references/calibration.md`, which ships.

Bait code with known verdicts, anchored to function names. An edit to a SKILL.md
check is validated by re-running it here: every "fires" entry must still fire,
every "silent" entry must stay silent.

Each section below is one tree under review, and the rows that search a tree —
S1, S2, L3, N2 — are decided within it. The nine language directories are
unrelated programs that share a parent, so a fact recurring across two of them
is not a second home: the 30-second deadline is eight separate S1 findings, one
per tree, not one fact in twelve homes.

An entry that names a witness — `(witness: X4-bash-stamp-fires)` — is decided by
`./witness.sh`, which runs that script and fails when the verdict stops holding.
An entry naming no witness was decided by hand and can go stale silently. The
value a verdict turns on lives in the witness, which asserts it against the
fixture; this file records which rule, which symbol and which verdict, and does
not restate the value.

Every fixture parses or compiles clean under its own toolchain — the bait is
valid code, not broken code. Toolchains used: python3, go, tsc --strict,
lua5.4, node, bash -n, swiftc -typecheck, javac 21, kotlinc 2.1.

`lint.sh` runs each language's standard linter over these files. **Every finding
it prints is intentional bait, listed below under the rule it baits.** A finding
absent from this file is a defect in the fixture and is fixed there, not
recorded. The same findings are checked in as `(linter, code)` pairs in
`lint.baseline`, and `lint.sh` exits non-zero unless the run reproduces that
multiset exactly — a new finding and a bait that stopped firing both fail, with
a diff. Regenerate the baseline with `./lint.sh --update-baseline` when a
fixture changes on purpose, and update the table below to match. Missing linters
are reported as SKIPPED with a non-zero exit, never passed over in silence;
their baseline entries are excluded from the diff, so an absent toolchain is not
misreported as fixture drift.

What the linters find, and what they miss:

| linter | code | rule it corroborates |
|---|---|---|
| ruff | `S110`, `BLE001` | L1 (`except Exception: pass`) |
| eslint | `no-empty`, `no-unused-vars` | L1 (`catch (e) {}`) |
| luacheck | `W111` setting non-standard global | L6 (`RETRY_LIMIT`) |
| luacheck | `W231` variable `region` is never accessed | L3 (dead write) |
| luacheck | `W212` unused argument `entry` ×2 | none — a side effect of S2's stub handlers, which must keep identical bodies |
| shellcheck | `SC2034` ×2 | L3 (`RETRY_LIMIT`, `REGION` unused) |

`go vet`, `swiftc`, `javac -Xlint:all` and `kotlinc` report nothing on these
files at all. The go fixtures are a bare package with no module file, so
`lint.sh` vets them in GOPATH mode (`GO111MODULE=off`); in module mode `go vet`
aborts before analysing anything. No linter in any of the nine languages finds S1, S2, S3, M1, M2,
M4, T1, T2, T4, F3, F4, N1, N2, X1, X2 or X4 — the bait for those rules compiles
and lints clean, which is the case for the document existing.

Ruff also reports `PLR0917` (7 positional arguments) on `render_row` under
`--select ALL`. No rule covers parameter count: two attempts at one failed
testing and are recorded in `references/rejected.md`.

## python/ingest.py + worker.py

Fires:
- S1 — `RETRY_TIMEOUT` vs the literal 30s deadline in `fetch_with_retry` and the
  `PERSIST_TIMEOUT` default. Not the id-required rule: a rule is S2's
- S2 — the id-required rule in both `validate_record` and `_persist`: requiring a
  non-empty id at `validate_record` alone gives one record two answers, because
  `_persist` still stores what `process` refuses
  (witness: S2-python-ingest-validate_record-fires)
- M2 — `PERSIST_TIMEOUT` read inside `_persist`, below the entry point
- M3 — `fetch_with_retry` reaches `requests` and the clock; `stamp` reaches the clock
- M4, T3 — `handle_event`: elif chain on `event["type"]`, no declared extension point
- F2 — silent per body: the elif chain is a flat dispatch on one value. No
  complexity checker is installed, so the absence itself is the finding
- T1 — `validate_record` names non-numeric amounts, yet `_persist` takes one,
  reaches the work and returns the record
  (witness: T1-python-ingest-_persist-fires). (The `"quux"` event is not T1 bait —
  the else branch handles it, so no site names it. It fires L2 and T3/M4.)
- T2 — `validate_record` returns bool; `_persist` accepts the same raw dict
- N1 — `process`, `stamp`
- X1 — `process` completes normally for a bad record and the message it logs omits
  the offending value (witness: X1-python-ingest-process-fires); unknown kind
  produces `{"status": "ok"}`
- X4 — `stamp` embeds the clock
- L1 — `except Exception: pass` in `process` discards the error and the caller
  receives None (witness: L1-python-ingest-process-fires)
- L2 — `handle_event` else-branch routes to `_on_created`

Silent:
- S2 — `_on_created`/`_on_updated`/`_on_deleted`: identical bodies free to diverge
- L6 — `RETRY_TIMEOUT` and `log` are never reassigned or mutated

## python/report.py + test_report.py

Fires:
- T1 — `Interval(60, 0)` constructs; the value reaches `render_row` arithmetic
- X2 — executed: 5 of 5 mutants survive the suite (`rjust`->`ljust`, span sign
  flip, `"holiday"`->`"past"`, `>`->`>=`, `<=`->`<`). Body deletion is not
  decisive here: stubbing to a same-typed constant leaves all three tests green,
  stubbing to `None` fails two — which is why X2 checks mutants
- X1, L2 — `render_row` silently left-aligns any `align` other than `"right"`

- F4 — `classify` tests `start > now` before `start in holidays`, so a future
  holiday never classifies as a holiday; permuting the two branches changes the
  answer for an interval that satisfies both
  (witness: F4-python-report-classify-fires)

Silent:
- T3, M4 — `classify`: unrelated predicates, no kind, no cases
- S3 — no cycle; both units take numbers. Placement is unverified: no layer map exists

## go/store.go + handler.go

Fires:
- S1 — `RequestTimeout` has no reader; 30s recurs as literals in `Fetch` and `Handle`
- M3 — `Fetch` builds its own `http.Client`; `Handle` reads the clock
- T1, T2 — `Record{Amount: -5}` constructs and is stored; `validate`'s verdict is discarded
- X1 — `Put` says "invalid record" without the value; `Fetch` answers an
  unreachable address with no response and no error
  (witness: X1-go-Put_Fetch-fires)
- X4 — `Summarise` returns map keys in iteration order, which Go randomises per
  process (witness: X4-go-Summarise-fires)
- L1 — `_ = validate(r)` in `Handle` discards a verdict that is really there, so a
  rejected record is stored and reported as a success
  (witness: L1-go-Handle-fires); `Fetch` converts its error away
- L2 — `Describe` default returns `"text"`, aliasing a real case
  (witness: L2-go-Describe-fires)
- L5 — `//nolint:errcheck` with no owner or expiry
- L6 — `region` reassigned in `init` and `SetRegion`; `cache` mutated by `Put`

Silent:
- S3 — store.go level 1, handler.go level 2, no cycle. Placement unverified: no layer map

## ts/orders.ts + report.ts

Fires:
- S1 + N2 + X5 — `RETRY_LIMIT` and `MAX_RETRIES`: one fact in two homes, two names
  for one concept, reported at S1. X5 groups them: deleting the second home clears
  both, and no smaller change clears N2 alone
- M3 — `stamp` reaches `Date.now`; `retry` reaches `fetch`
- T2 — `isOrder` returns boolean; `ingest` casts `as Order`
- T3 — `handle` dispatches on `event.kind`; the `default` arm defeats exhaustiveness
- X1 — "bad order" omits the value; `load` returns `[]` for malformed input
- X4 — `stamp` embeds the clock
- L1 — `catch {}` in `ingest`; `catch (e) {}` in `load`
- L2 — `handle` default returns `"ok"`
- L5 — `@ts-ignore` in `retry` with no owner or expiry
- L6 — `currentRegion` reassigned by `setRegion`

Silent:
- M1 — `renderRow`: every listed item is caller-chosen

## lua/ledger.lua

Fires:
- S1 — the 30s deadline as a literal in `persist`, unrelated to `RETRY_LIMIT`
- M3 — `persist` and `stamp` reach `os.time`
- M4, T3 — `handle`: if/elseif on `entry.kind`, no declared extension point
- T1, T2 — `validate` returns a boolean and accepts `amount = -5`; `persist`
  takes the same raw table
- N1 — `stamp` mutates its argument. (`ids` returning hash order is X4's subject,
  not a write the name omits)
- X1 — `process` returns nil for bad input; "bad record" omits the value
  (witness: X1-lua-process-fires)
- X4 — `ids` returns table hash order, which Lua reseeds per process, so fresh
  runs disagree (witness: X4-lua-ids-fires); `stamp` embeds the clock
- L1 — `pcall` result discarded in `process`, error never read
  (witness: L1-lua-process-fires)
- L2 — `handle` else-branch routes an unknown kind to `on_created`
  (witness: L2-lua-handle-fires)
- L6 — `RETRY_LIMIT` global; `cache` and `region` reassigned by `set_region`

Silent:
- S2 — `on_created` and `on_updated`: identical bodies free to diverge

## bash/deploy.sh

Fires:
- S1 — 30s appears in `fetch_manifest`'s `--max-time` and `run`'s deadline
- M3 — `fetch_manifest` reaches the network; `run` and `stamp` read the clock
- M4, T3 — `handle_target`: if/elif on `$target`
- N1 — `fetch_manifest` writes `/tmp/manifest.json`. (`run` retrying nothing is a
  promise the name makes, which this check does not reach)
- X1 — executed: `fetch_manifest` against an unreachable host exits 0, the
  failure swallowed by `return 0`; "bad manifest" omits the value
- X4 — `stamp` embeds the clock, so two runs of the same argument differ
  (witness: X4-bash-stamp-fires)
- L1 — `curl` failure converted to `return 0`; `$?` read after a pipeline whose
  exit status was already consumed
- L2 — an unrecognised target routes to `deploy_staging` rather than being refused
  (witness: L2-bash-handle_target-fires)
- L6 — `REGION` reassigned by `set_region`

Silent:
- S2 — `deploy_staging` and `deploy_prod`: identical bodies free to diverge

Note: shellcheck flags `RETRY_LIMIT` and `REGION` as unused (SC2034), which is
L3's finding arriving from the toolchain rather than the rule.

## js/orders.js

Fires:
- M3 — `stamp` reaches `Date.now`; `retry` reaches `fetch` and the clock
- M4, T3 — `handle` switches on `event.kind` with a `default` arm
- T2 — `isOrder` returns a boolean; `persist` takes the same raw object
- N1 — `retry` performs one fetch per loop with no backoff; `persist` mutates a
  module-level `Map` and returns a rounded copy
- X1 — malformed and structurally wrong input both come back from `ingest` as null
  with a "bad order" warning that omits the value; `load` returns a non-array
  despite an array contract (witness: X1-js-ingest_load-fires)
- X4 — `stamp` embeds the clock. `totals` reorders integer-like keys first but does
  so identically in every fresh process, so X4 is silent on it and N1 carries it
  (witness: X4-js-totals-silent)
- L1 — `catch {}` in `ingest`; `catch (e) {}` in `load`
- L2 — an unrecognised kind reaches the `default` arm and is given a real case's
  answer (witness: L2-js-handle-fires)
- L6 — `currentRegion` reassigned by `setRegion`; `cache` mutated by `persist`

Silent:
- M1 — `totals`: every listed item is caller-chosen

## swift/Ledger.swift

Fires:
- S1 — `requestTimeout` has no reader; 30 recurs as a literal in `fetch`
- M3 — `stamp` and `fetch` reach `Date()`; `fetch` reaches the network
- T1 — `Entry.created(id:amount:)` takes a raw `Decimal`, so a negative amount
  constructs and reaches `store.put`; `Amount` is on no path
- T2 — `Amount` is unobtainable without its failable init, but no signature
  downstream takes it
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-swift-CappedStore-fires)
- N1 — `fetch` hides a 30-second busy-wait; `apply` always returns `"ok"`
- X1 — `store`'s `catch` returns `"ok"` on failure; `"bad input"` omits the
  value; `total(for:)` force-unwraps
- X4 — `ids()` returns dictionary keys in per-process hash order
- L1 — `try?` in `decode` discards the error; `catch { return "ok" }`
- L2 — `decode` returns `.created` for any object carrying an id
- L5 — `// swiftlint:disable:next force_try` with no owner or expiry
- L6 — `static var region`

Silent:
- T3 — `apply`'s `switch` over `Entry` is an exhaustive match over a closed sum:
  adding a member breaks the build (witness: T3-swift-apply-silent)

## java/Ledger.java

Fires:
- L3 — `RETRY_LIMIT` has no reader: deleting it rebuilds clean under
  `javac -Xlint:all` (witness: L3-java-RETRY_LIMIT-fires). Not S1 —
  within this tree nothing else states 3, so changing the one home changes
  nothing and the fact has no second home
- M4, T3 — `handle`: if/else-if on `entry.kind`
- T1, T2 — `Entry` is a mutable bag of public fields; `validate` returns a
  boolean and `persist` takes the same raw `Entry`
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-java-CappedStore-fires)
- N1 — `renderRow` pads by grapheme count, not display width. (`total` throwing is
  neither a write nor a wait)
- X1 — `process` with a null id completes normally, printing "bad record"; a total
  for an absent id raises `NullPointerException` naming a Map internal, not the id
  (witness: X1-java-process-fires); an unknown `align` is silently left-aligned
  rather than refused (witness: X1-java-renderRow-fires)
- X4 — `stamp` embeds the clock. (`ids()` does not fire: its `HashMap` key order is
  stable across fresh JVMs) (witness: X4-java-ids-silent)
- L1 — `catch (Exception e) {}` in `process`
- L2 — `handle` else-branch routes an unknown kind to `onCreated`
- L6 — `static String region` reassigned by `setRegion`

Silent:
- S2 — `onCreated` and `onUpdated`: identical bodies free to diverge

## kotlin/Ledger.kt

Fires:
- S1 — 30_000 is a literal in `fetchDeadline`
- L3 — `RETRY_LIMIT` has no reader: deleting it rebuilds clean under `kotlinc`
  (witness: L3-kotlin-RETRY_LIMIT-fires). Not S1 — nothing else in this tree
  states 3
- M3 — `stamp` and `fetchDeadline` reach `Instant.now`
- M4, T3 — `handle`: if/else-if on a `String` kind, beside a sealed class that
  already models the same domain
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-kotlin-CappedStore-fires)
- N1 — `process` names no operation
- X1 — `process` with a null id completes normally, printing "bad record", and
  `persist`'s `require` message omits the id (witness: X1-kotlin-process-fires); an
  unknown `align` is silently left-aligned rather than refused
  (witness: X1-kotlin-renderRow-fires)
- X4 — `stamp` embeds the clock. (`ids()` does not fire: `mutableMapOf` is a
  `LinkedHashMap`, so key order is stable across fresh JVMs)
  (witness: X4-kotlin-ids-silent)
- L1 — `catch (e: Exception) { null }` in `process`
- L2 — `handle` else-branch routes an unknown kind to `onCreated`
- L6 — top-level `var region`

Silent:
- T3 — `apply`'s `when` over the sealed `Entry` is exhaustive over a closed sum
- N2 — `Store.ids` and `Ledger` names map one-to-one

## python/billing.py

Bait for the four rules the corpus did not reach. Fires:
- L4 — three comments whose subject is not the current code: a former version
  ("used to round each line"), a rejected alternative ("we considered ... but
  rejected it"), and a schedule ("TODO: ... next quarter")
- F1 — `invoice_total` reaches `line_total` directly and through `subtotal`, a
  level it had already delegated
  (witness: F1-python-billing-invoice_total-fires)
- F3 — `Cart.total` is derived and stored; adding to the cart moves the source
  while `read()` still answers from the stored copy, with no assertion and no
  bound (witness: F3-python-billing-Cart-fires)
- X3 — `Cart`'s comment says "whole cents", yet a call written from that comment
  alone is accepted with fractional amounts
  (witness: X3-python-billing-Cart-fires); `apply_discount`'s comment does not say
  `pct` is a fraction, so a call written from it alone inverts the sign
  (witness: X3-python-billing-apply_discount-fires)
- T1 — negative and non-numeric amounts construct and reach the arithmetic

Silent:
- F4 — `invoice_total`'s two branches cannot both match
- S1 — `TAX_RATE` has one home: nothing else in the tree states the rate, and
  changing that home changes every dependent behaviour
  (witness: S1-python-billing-TAX_RATE-silent)
