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
S1, S2, L3, N2 — are decided within it. The language directories and `service/`
are unrelated programs that share a parent, so a fact recurring across two of them
is not a second home: the 30-second deadline is eight separate S1 findings, one
per tree, not one fact in twelve homes.

Two verdicts are the repository's rather than any section's, and are recorded here
once because they hold for every fixture alike: **F2** — no complexity checker is
configured anywhere in this repository, so nothing measures a body and the absent
checker is one finding about the build (witness: F2-tree-bodies-silent; installed
for the run, a McCabe gate at 10 fails no body in `python/`, `go/` or `files/`) —
and **S3** — no layer map is declared anywhere in it, so placement is unverified
over all 11 units of those three trees, every one of which takes a number with no
cycle (witness: S3-tree-placement-silent). Neither is restated per section: a
finding a reviewed file cannot decide is reported once, under the repository.

**X6** and **X7** have no site outside `service/`. No other tree starts work
against an owner it closes, holds a connection or opens a transaction: `go Fetch`
returns its response to the caller, `js retry` and `ts retry` hand back the
promise they create, and the swift, bash and lua fetches block until they answer.
Both rows are silent in every other section, and are not restated there.

Two clauses rest on comparison alone, with no witness: X2's test of a built
artifact, and X7's interleaving of two read-modify-write transactions. No tree
carries a test of a built artifact, or a store whose snapshot a run can
interleave.

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
M4, T1, T2, T4, T5, F3, F4, N1, N2, X1, X2, X4, X6 or X7 — the bait for those rules compiles
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
- T1 — `validate_record` names non-numeric amounts, yet `_persist` takes one,
  reaches the work and returns the record
  (witness: T1-python-ingest-_persist-fires). (The `"quux"` event is not T1 bait —
  the else branch handles it, so no site names it. It fires L2 and T3/M4.)
- T2 — `validate_record` returns bool; `_persist` accepts the same raw dict
- N1 — `process`, `stamp`
- X1 — `process` completes normally for a bad record and the message it logs omits
  the offending value (witness: X1-python-ingest-process-fires); unknown kind
  produces `{"status": "ok"}`
- X3 — the answer is a record, which a typed dict or a dataclass carries, and
  `process`'s signature does not type it: the mapping a correct call answers with
  carries a `timeout` the signature never mentions, taken from the environment.
  That `raw` is JSON text is a fact no type carries, so it belongs in the comment,
  and there is none: a call written from the signature alone passes the record the
  parameter names and is refused (witness: X3-python-ingest-process-fires)
- X4 — `stamp` embeds the clock
- L1 — `except Exception: pass` in `process` discards the error and the caller
  receives None (witness: L1-python-ingest-process-fires)
- L2 — `handle_event` else-branch routes to `_on_created`
- L3 — `RETRY_TIMEOUT` has no reader: deleting it leaves every module in the tree
  importable and every answer unchanged
  (witness: L3-python-ingest-RETRY_TIMEOUT-fires). S1 above is a second defect at
  the same constant, not this one under another name: the deletion this row asks
  for leaves the deadline stated twice, and wiring one literal to the constant
  clears this row while S1 keeps firing

Silent:
- S2 — `_on_created`/`_on_updated`/`_on_deleted`: identical bodies free to diverge
- F2 — silent per body: `handle_event`'s elif chain is a flat dispatch on one
  value, and with a gate installed at 10 no body in this tree is over budget. The
  absent checker is the repository's finding above, not this file's
- L6 — `RETRY_TIMEOUT` and `log` are never reassigned or mutated
- T5 — unverified rather than silent: no signature in these files carries
  parameter types

## python/report.py + test_report.py

Fires:
- T1 — `Interval(60, 0)` constructs; the value reaches `render_row` arithmetic
- T2 — `classify`'s refusal of an interval that ends before it starts is the check,
  and it hands back a string: the refused value is obtainable without running it,
  and `render_row` takes the same raw `Interval` and computes a negative span
  (witness: T2-python-report-Interval-fires)
- X2 — executed: 5 of 5 mutants survive the suite (`rjust`->`ljust`, span sign
  flip, `"holiday"`->`"past"`, `>`->`>=`, `<=`->`<`). Body deletion is not
  decisive here: stubbing to a same-typed constant leaves all three tests green,
  stubbing to `None` fails two — which is why X2 checks mutants
- X1, L2 — `render_row` silently left-aligns any `align` other than `"right"`
- X3 — `classify`'s signature carries no type for `now`, though the standard
  library has time types that carry a unit; the unit is stated only in
  `Interval`'s comment, so one situation answers `future` under minutes since
  midnight and `past` under a clock reading of the same moment
  (witness: X3-python-report-classify-fires)

- F4 — `classify` tests `start > now` before `start in holidays`, so a future
  holiday never classifies as a holiday; permuting the two branches changes the
  answer for an interval that satisfies both
  (witness: F4-python-report-classify-fires)

Silent:
- M1 — `render_row`: seven parameters, every one the caller's own value, and the
  call answers with nothing else of the module having run
  (witness: M1-python-render_row-silent). The witness asserts the same of
  `files/render.py` `render_cell`, which carries an interface docstring — the row's
  verdict is the same with it and without it
- T3, M4 — `classify`: unrelated predicates, no kind, no cases
- S3 — no cycle; `report.py` takes 1 and `test_report.py` 2, so nothing here is
  above a layer. Placement unverified is the repository's verdict above, stated
  once, not this file's finding (witness: S3-tree-placement-silent)
- F2 — no body in this tree is over budget under a gate installed at 10; the
  absent checker is the repository's finding above
  (witness: F2-tree-bodies-silent)
- T5 — unverified rather than silent: `classify` and `render_row` carry no
  parameter types

## go/store.go + handler.go

Fires:
- S1 — `RequestTimeout` has no reader; 30s recurs as literals in `Fetch` and `Handle`
- M2 — `Put` writes into a package-level map rather than a store it receives: two
  runs in one process share it, and no caller outside the package can supply
  another, the assignment being module-private (witness: M2-go-Put-fires)
- M3 — `Fetch` builds its own `http.Client`; `Handle` reads the clock
- M4, T3 — `Describe`: a type switch on one value whose `default` arm forfeits
  exhaustiveness, so a member added to the kinds it dispatches on builds clean and
  is answered by a real case instead of breaking the build, and a duplicated case
  has nowhere to land but the body of `Describe` itself
  (witnesses: T3-go-Describe-fires, M4-go-Describe-fires)
- T1, T2 — `Record{Amount: -5}` constructs and is stored; `validate`'s verdict is discarded
- N1 — `Handle` writes the decoded record into the package store
  (witness: N1-go-Handle-fires)
- X1 — `Put` says "invalid record" without the value; `Fetch` answers an
  unreachable address with no response and no error
  (witness: X1-go-Put_Fetch-fires)
- X3 — `Fetch` answers an unreachable address with a nil response and a nil
  error. No type carries that pair, so it belongs in the comment, and `Fetch` has
  none: a call written from the signature alone — a nil error, therefore a usable
  response — dereferences nil (witness: X3-go-Fetch-fires)
- X4 — `Summarise` returns map keys in iteration order, which Go randomises per
  process (witness: X4-go-Summarise-fires)
- L1 — `_ = validate(r)` in `Handle` discards a verdict that is really there, so a
  rejected record is stored and reported as a success
  (witness: L1-go-Handle-fires); `Fetch` converts its error away
- L2 — `Describe` default returns `"text"`, aliasing a real case
  (witness: L2-go-Describe-fires)
- L3 — `RequestTimeout` has no reader: deleting it vets clean with every answer
  unchanged (witness: L3-go-RequestTimeout-fires). S1 above is a second defect at
  the same constant, not this one under another name: the deletion this row asks
  for leaves the deadline stated twice, and wiring one literal to the constant
  clears this row while S1 keeps firing
- L5 — `//nolint:errcheck` with no owner or expiry
- L6 — `region` reassigned in `init` and `SetRegion`; `cache` mutated by `Put`

Silent:
- S3 — store.go level 1, handler.go level 2, no cycle, so no unit here is above a
  layer. Placement unverified is the repository's verdict above, stated once, not
  this package's finding (witness: S3-tree-placement-silent)
- F2 — `Describe` is the worst body in this package at McCabe 5 under a gate
  installed at 10; the absent checker is the repository's finding above
  (witness: F2-tree-bodies-silent)
- T5 — `Put` and `validate` return the refusal as an error; `Handle` answers a
  malformed payload with a nil slice its type admits, which X1 and L1 carry;
  `Fetch`'s unreachable address is the I/O edge

## ts/orders.ts + report.ts

Fires:
- S1 + N2 + X5 — `RETRY_LIMIT` and `MAX_RETRIES`: one fact in two homes, two names
  for one concept, reported at S1. X5 groups them: deleting the second home clears
  both, and no smaller change clears N2 alone
- M2 — `retry` spends a module-level retry budget rather than one it receives: two
  runs in one process spend the same 3, and the binding refuses a second value
  (witness: M2-ts-retry-fires)
- M3 — `stamp` reaches `Date.now`; `retry` reaches `fetch`
- T1 — the state `isOrder` names inhabits `Order` all the same, through `load`'s
  cast, and reaches the arithmetic in `totals` and `persist`
  (witness: T1-ts-load-fires)
- T2 — `isOrder` returns boolean; `ingest` casts `as Order`
- T3 — `handle` dispatches on `event.kind`; the `default` arm defeats exhaustiveness
- X1 — "bad order" omits the value; `load` returns `[]` for malformed input
- X3 — `load` answers a JSON document that is not an array with something other
  than `Order[]`; the language carries that answer in a type — a union with the
  parsed value, a result — and the signature does not: it is answered
  with the parsed object itself, so mapping over the rows it returns throws
  (witness: X3-ts-load-fires)
- X4 — `stamp` embeds the clock
- L1 — `catch {}` in `ingest`; `catch (e) {}` in `load`
- L2 — `handle` default returns `"ok"`
- L5 — `@ts-ignore` in `retry` with no owner or expiry
- L6 — `currentRegion` reassigned by `setRegion`

Silent:
- M1 — `renderRow`: every parameter is caller-chosen, and the one argument another
  unit produces is typed — `ingest` returns `Order`, which is what `renderRow`
  takes, so the composition is writable from the signatures alone. Executed under
  `tsc --strict` and run: no witness, because the run needs a compiler `witness.sh`
  cannot assume
- T5 — `ingest` declares the refusal in `Order | null`; `load` answers malformed
  text with an empty array its type admits, which X1 carries; `retry`'s rejection
  is the I/O edge

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
- T5 — unverified: no signature carries types

## bash/deploy.sh

Fires:
- S1 — 30s appears in `fetch_manifest`'s `--max-time` and `run`'s deadline;
  separately, `/tmp/manifest.json` is one path in three homes — the redirect
  `fetch_manifest` writes, the `cat` that reads it back, and the argument `run`
  validates — and moving the redirect alone breaks the run while the other two keep
  stating the old path (witness: S1-bash-manifest_path-fires)
- M1 — `validate_manifest` reaches what `fetch_manifest` produced only through
  `/tmp/manifest.json`, a value `fetch_manifest` neither takes nor returns: the url
  it takes and the bytes it returns both make `validate_manifest` answer 1
  (witness: M1-bash-validate_manifest-fires). Declaring the path as a constant and
  pairing the calls in a wrapper leaves both answers at 1, so the row does not
  clear on a name; it clears when `fetch_manifest` takes the destination and
  returns it. Not grouped under X5 with the S1 finding above at the same value, and
  not with N1's: S1's smaller change — one home for the path — is the constant this
  witness applies, and it clears S1 while leaving this row firing; N1's write is
  still unstated by the name after the change that does clear this row
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
- T5 — unverified: no function declares parameters

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
- M1 — `totals`: every parameter is caller-chosen, it answers called alone, and
  what `ingest` returns goes straight into it. `persist`'s product, the module-level
  `cache`, is reached by no argument at all (witness: M1-js-totals-silent)
- T5 — unverified: no signature carries types

## swift/Ledger.swift

Fires:
- S1 — `requestTimeout` has no reader; 30 recurs as a literal in `fetch`
- M1 — `Store.total(for:)` traps until `put` has run, ending the process on
  SIGILL or SIGTRAP depending on the architecture
  (witness: M1-swift-Store_total-fires). `entries` being visible in the module is a
  way to discover which ids are present, not a signature that makes the correct
  order the only writable call. Not grouped with X1 below under X5, though a
  `Decimal?` return clears both: executed, the smaller change — `guard let` with a
  message naming the id — clears X1 and leaves this row firing, and X5's clause is
  that a finding a smaller change clears alone was never one of the group
- M3 — `stamp` and `fetch` reach `Date()`; `fetch` reaches the network
- T1 — `Entry.created(id:amount:)` takes a raw `Decimal`, so a negative amount
  constructs and reaches `store.put`; `Amount` is on no path
- T2 — `Amount` is unobtainable without its failable init, but no signature
  downstream takes it
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-swift-CappedStore-fires)
- T5 — `Store.total(for:)` answers an absent id, which `String` permits, with a
  trap the signature does not declare (the trap is asserted by witness:
  M1-swift-Store_total-fires)
- N1 — `fetch` hides a 30-second busy-wait; `apply` always returns `"ok"`
- X1 — `store`'s `catch` returns `"ok"` on failure; `"bad input"` omits the
  value; `total(for:)` force-unwraps; an unknown `align` is silently left-aligned
  by `renderRow` rather than refused (witness: X1-swift-renderRow-fires)
- X4 — `ids()` returns dictionary keys in per-process hash order
- L1 — `try?` in `decode` discards the error; `catch { return "ok" }`
- L2 — `decode` returns `.created` for any object carrying an id
- L5 — `// swiftlint:disable:next force_try` with no owner or expiry
- L6 — `static var region`

Silent:
- T3 — `apply`'s `switch` over `Entry` is an exhaustive match over a closed sum:
  adding a member breaks the build (witness: T3-swift-apply-silent)
- T5 — `decode` and `fetch` declare the absent case as an optional, and
  `Amount`'s failable initializer does the same

## java/Ledger.java

Fires:
- L3 — `RETRY_LIMIT` has no reader: deleting it rebuilds clean under
  `javac -Xlint:all` (witness: L3-java-RETRY_LIMIT-fires). Not S1 —
  within this tree nothing else states 3, so changing the one home changes
  nothing and the fact has no second home
- M1 — `Store.total(id)` fails until `put` has run, and neither its signature nor
  any type makes the correct order the only writable call
  (witness: M1-java-Store_total-fires). It clears when `total` returns
  `Optional<Double>`, so the call alone answers. Not grouped with X1 below under
  X5, although that one change clears both: executed, the smaller change — throw,
  naming the offending id — clears X1 and leaves this row firing, and X5's clause
  is that a finding a smaller change clears alone was never one of the group. The
  exception that change throws is unchecked, so T5 keeps firing beside this row.
  Also distinct from X3, which an interface comment stating the ordering clears while
  this row still fires
- M4, T3 — `handle`: if/else-if on `entry.kind`
- T1, T2 — `Entry` is a mutable bag of public fields; `validate` returns a
  boolean and `persist` takes the same raw `Entry`
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-java-CappedStore-fires)
- T5 — `Store.total(id)` answers an absent id, which `String` permits, with a
  `NullPointerException` the signature does not declare (the exception is
  asserted by witness: X1-java-process-fires)
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
- T5 — `persist` refuses an `Entry` whose `id` is null, a predicate over the
  argument alone, so the refusal is a precondition and X1's

## kotlin/Ledger.kt

Fires:
- S1 — 30_000 is a literal in `fetchDeadline`
- L3 — `RETRY_LIMIT` has no reader: deleting it rebuilds clean under `kotlinc`
  (witness: L3-kotlin-RETRY_LIMIT-fires). Not S1 — nothing else in this tree
  states 3
- M1 — `Store.total(id)` fails until `put` has run
  (witness: M1-kotlin-Store_total-fires). Exporting `ids()` beside it is a way for
  a caller to discover which ids are present, not a signature that makes the
  correct order the only writable call, so the row fires here as it does in java
  and swift — the three are one shape, not three accidents of visibility
- M3 — `stamp` and `fetchDeadline` reach `Instant.now`
- M4, T3 — `handle`: if/else-if on a `String` kind, beside a sealed class that
  already models the same domain
- T4 — `CappedStore` fails the `Store` put-then-get contract that `Store` passes,
  the suite parameterized over the constructor
  (witness: T4-kotlin-CappedStore-fires)
- T5 — `Store.total(id)` answers an absent id with a `NoSuchElementException`
  its signature does not declare (asserted by witness:
  M1-kotlin-Store_total-fires)
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
- T5 — `process` declares its refusal in `Double?`; `persist`'s `require` on an
  empty id is a predicate over the argument alone, a precondition X1 decides

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
- X3 — whole cents is a fact an integer type carries, yet `Cart`'s signature
  carries no type and only its comment states it, so a call written from them is
  accepted with fractional amounts (witness: X3-python-billing-Cart-fires); no
  type of the language or its standard library carries a fraction of one, so
  `apply_discount`'s comment is the place, and it does not say `pct` is one: a
  call written from it alone inverts the sign
  (witness: X3-python-billing-apply_discount-fires)
- T1 — negative and non-numeric amounts construct and reach the arithmetic

Silent:
- F4 — `invoice_total`'s two branches cannot both match
- S1 — `TAX_RATE` has one home: nothing else in the tree states the rate, and
  changing that home changes every dependent behaviour
  (witness: S1-python-billing-TAX_RATE-silent)
- T5 — unverified: no signature carries types

## service/

Python bait for T5, X6 and X7, and for clauses of S1, S2, M2, M3, F3, N1, X3 and X4
that no other tree reaches. Fires:
- S1 — `data_dir` tries the configured folder and then a fallback under the home
  folder: configured anew with a folder not yet on disk, it still answers the
  old folder
  (witness: S1-service-paths-data_dir-fires)
- L1 — the same fallback turns the absent configured folder into the default one
  (witness: S1-service-paths-data_dir-fires). One defect with S1 under X5:
  refusing a configured folder that is absent clears both, and no smaller change
  clears either
- S2 — `split_query` restates the rule the standard library documents as
  `parse_qsl`; the two homes agree on a plain query and answer differently once
  a value is percent- or plus-encoded
  (witness: S2-service-query-split_query-fires)
- M2 — `run_child` starts its child with a stripped environment and passes it
  nothing, so two values of the setting answer the same
  (witness: M2-service-runner-run_child-fires)
- M3 — `day_label` takes its time zone from the process environment: the same
  instant labels as two different days under two zones, and the process
  environment is the only lever
  (witness: M3-service-stamp-day_label-fires)
- T5 + X3 + X5 — `Catalog.find` answers an absent key, which its signature
  permits, with the subscript's `KeyError` passed through, which its `-> int` does
  not declare, though `in` answers absence first: absence depends on the unit's
  state, not the argument alone (witness: T5-service-catalog-find-fires). A call
  written from the signature alone does not expect the error, which is X3's
  absent input. Declaring `int | None`, as `lookup` does, clears both
  (witness: T5-service-catalog-lookup-silent), and no smaller change clears
  either alone
- F3 — `Results` keys every value by one version counter: a write to an input
  `total` does not read leaves the value `total` served no longer readable as last
  known, erased with `label`'s (witness: F3-service-derived-Results-fires)
- N1 — `Catalog.get_item` reorders the recency list `recent` answers from, a write
  its name does not state, so the same lookups in another order leave the object
  answering differently (witness: N1-service-catalog-get_item-fires)
- X3 — `deadline` carries no type, and only its comment supplies the unit: a call
  written from the signature alone in milliseconds is accepted, where a
  standard-library time type refuses it
  (witness: X3-service-timer-deadline-fires)
- X4 — `build` into a location holding an earlier build keeps a file the source no
  longer has (witness: X4-service-build-build-fires)
- X6 — `Session.close` returns with submitted work in flight, the work then writes
  to the released connection, and `notify` after close opens a second one. The
  work runs on a timer nothing awaits and nothing owns
  (witness: X6-service-session-Session-fires)
- X7 — `transfer` maps the store's conflict refusal to `"conflict"` instead of
  running the transaction again, so a transfer the retry would complete is lost
  (witness: X7-service-store-transfer-fires); `load_all` issues its queries at
  once, putting more than one statement in flight on one connection
  (witness: X7-service-store-load_all-fires)

Silent:
- S1 — `default_dir` applies its default only when nothing is configured and
  probes no folder, so a configured folder moves the answer, and the default
  folder's name has one home, `DEFAULT_NAME`
  (witness: S1-service-paths-default_dir-silent)
- T5 — `Catalog.lookup` and `Catalog.get_item` declare the absent key in
  `int | None` (witness: T5-service-catalog-lookup-silent). Every other unit
  here carries no parameter types, so the row is unverified there
- N1 — `Results.value` writes only the derived value it stores, which is F3's,
  and the formula log `computed`, a diagnostic; every value it stores equals a
  recompute from the live inputs (witness: N1-service-derived-Results_value-silent); `Store.query` writes only
  `in_flight` and `peak`, which nothing but a probe reads
