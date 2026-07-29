# Fixture map

Bait code with known verdicts, anchored to function names. An edit to a SKILL.md
check is validated by re-running it here: every "fires" entry must still fire,
every "silent" entry must stay silent.

Every fixture parses or compiles clean under its own toolchain — the bait is
valid code, not broken code. Toolchains used: python3, go, tsc --strict,
lua5.4, node, bash -n with shellcheck, swiftc -typecheck, javac 21, kotlinc 2.1.

## python/ingest.py + worker.py

Fires:
- S1 — `RETRY_TIMEOUT` vs the literal 30s deadline in `fetch_with_retry` and the
  `PERSIST_TIMEOUT` default; the id-required rule in both `validate_record` and `_persist`
- M2 — `PERSIST_TIMEOUT` read inside `_persist`, below the entry point
- M3 — `fetch_with_retry` reaches `requests` and the clock; `stamp` reaches the clock
- M4, T3 — `handle_event`: elif chain on `event["type"]`, no declared extension point
- T1 — `{"type": "quux"}` constructs and reaches `_on_created`
- T2 — `validate_record` returns bool; `_persist` accepts the same raw dict
- N1 — `process`, `stamp`
- X1 — `process` returns None for a bad record; "bad record" omits the value;
  unknown kind produces `{"status": "ok"}`
- X4 — `stamp` embeds the clock
- L1 — `except Exception: pass` in `process`
- L2 — `handle_event` else-branch routes to `_on_created`

Silent:
- S2 — `_on_created`/`_on_updated`/`_on_deleted`: identical bodies free to diverge
- L6 — `RETRY_TIMEOUT` and `log` are never reassigned or mutated

## python/report.py + test_report.py

Fires:
- T1 — `Interval(60, 0)` constructs; the value reaches `render_row` arithmetic
- X2 — all three tests pass after their subjects' bodies are deleted
- X1, L2 — `render_row` silently left-aligns any `align` other than `"right"`

Silent:
- T3, M4 — `classify`: unrelated predicates, no kind, no cases
- S3 — report → orders only; both units take numbers

## go/store.go + handler.go

Fires:
- S1 — `RequestTimeout` has no reader; 30s recurs as literals in `Fetch` and `Handle`
- M3 — `Fetch` builds its own `http.Client`; `Handle` reads the clock
- T1, T2 — `Record{Amount: -5}` constructs and is stored; `validate`'s verdict is discarded
- X1 — `Put` says "invalid record" without the value; `Fetch` returns `(nil, nil)`
- X4 — `Summarise` returns map keys in iteration order
- L1 — `_ = validate(r)`; error converted to `(nil, nil)` in `Fetch`
- L2 — `Describe` default returns `"text"`, aliasing a real case
- L5 — `//nolint:errcheck` with no owner or expiry
- L6 — `region` reassigned in `init` and `SetRegion`; `cache` mutated by `Put`

Silent:
- S3 — store.go level 1, handler.go level 2, no cycle

## ts/orders.ts + report.ts

Fires:
- S1 + N2 — `RETRY_LIMIT` and `MAX_RETRIES`: one fact in two homes, two names for
  one concept; one defect under the convergence rule
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
- S3 — `RETRY_LIMIT` is a global, reachable and writable from any unit
- M3 — `persist` and `stamp` reach `os.time`
- M4, T3 — `handle`: if/elseif on `entry.kind`, no declared extension point
- T1, T2 — `validate` returns a boolean and accepts `amount = -5`; `persist`
  takes the same raw table
- N1 — `process` names no operation; `ids` returns keys in hash order
- X1 — `process` returns nil for bad input; "bad record" omits the value
- X4 — `ids` differs across fresh processes (executed: `theta,eta,zeta,…` then
  `alpha,theta,beta,…`); `stamp` embeds the clock
- L1 — `pcall` result discarded in `process`, error never read
- L2 — `handle` else-branch routes an unknown kind to `on_created`
- L6 — `RETRY_LIMIT` global; `cache` and `region` reassigned by `set_region`

Silent:
- S2 — `on_created` and `on_updated`: identical bodies free to diverge

## bash/deploy.sh

Fires:
- S1 — 30s appears in `fetch_manifest`'s `--max-time` and `run`'s deadline
- M3 — `fetch_manifest` reaches the network; `run` and `stamp` read the clock
- M4, T3 — `handle_target`: if/elif on `$target`
- N1 — `fetch_manifest` writes a file and echoes it; `run` retries nothing
- X1 — executed: `fetch_manifest` against an unreachable host exits 0, the
  failure swallowed by `return 0`; "bad manifest" omits the value
- X4 — executed: `stamp x` twice gives `x@1785346174` / `x@1785346175`
- L1 — `curl` failure converted to `return 0`; `$?` read after a pipeline whose
  exit status was already consumed
- L2 — executed: `handle_target quux` routes to `deploy_staging`
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
- X1 — executed: `ingest("{{{")` and `ingest("{}")` both return null;
  `load("{\"a\":1}")` returns the object itself despite an array contract
- X4 — `stamp` embeds the clock; `totals` returns integer-like keys first
  (executed: ids `b,10,a,2` come back as `2,10,b,a`)
- L1 — `catch {}` in `ingest`; `catch (e) {}` in `load`
- L2 — executed: `handle({kind:"deleted"})` returns `"ok"` from the default arm
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
- T4 — executed: `CappedStore` fails the `Store` put-then-get contract
  (`Store: true`, `CappedStore: false`)
- N1 — `fetch` hides a 30-second busy-wait; `apply` always returns `"ok"`
- X1 — `store`'s `catch` returns `"ok"` on failure; `"bad input"` omits the
  value; `total(for:)` force-unwraps
- X4 — `ids()` returns dictionary keys in per-process hash order
- L1 — `try?` in `decode` discards the error; `catch { return "ok" }`
- L2 — `decode` returns `.created` for any object carrying an id
- L5 — `// swiftlint:disable:next force_try` with no owner or expiry
- L6 — `static var region`

Silent:
- T3 — `apply`'s `switch` over `Entry` is an exhaustive match over a closed sum

## java/Ledger.java

Fires:
- S1 — `RETRY_LIMIT` has no reader
- M4, T3 — `handle`: if/else-if on `entry.kind`
- T1, T2 — `Entry` is a mutable bag of public fields; `validate` returns a
  boolean and `persist` takes the same raw `Entry`
- T4 — executed: `CappedStore` fails the `Store` put-then-get contract
  (`Store: true`, `CappedStore: false`)
- N1 — `process` names no operation; `total` throws rather than reporting
- X1 — executed: `process` with a null id prints "bad record" and returns null;
  `Store.total("missing")` raises `NullPointerException` naming a Map internal,
  not the id; `renderRow(align="up")` silently left-aligns
- X4 — `stamp` embeds the clock; `ids()` returns `HashMap` key order
- L1 — `catch (Exception e) {}` in `process`
- L2 — `handle` else-branch routes an unknown kind to `onCreated`
- L6 — `static String region` reassigned by `setRegion`

Silent:
- S2 — `onCreated` and `onUpdated`: identical bodies free to diverge

## kotlin/Ledger.kt

Fires:
- S1 — `RETRY_LIMIT` has no reader; 30_000 is a literal in `fetchDeadline`
- M3 — `stamp` and `fetchDeadline` reach `Instant.now`
- M4, T3 — `handle`: if/else-if on a `String` kind, beside a sealed class that
  already models the same domain
- T4 — executed: `CappedStore` fails the `Store` put-then-get contract
  (`Store: true`, `CappedStore: false`)
- N1 — `process` names no operation
- X1 — executed: `process(null, 5.0)` prints "bad record" and returns null;
  `renderRow(align="up")` silently left-aligns; `require` message omits the id
- X4 — `stamp` embeds the clock; `ids()` returns map key order
- L1 — `catch (e: Exception) { null }` in `process`
- L2 — `handle` else-branch routes an unknown kind to `onCreated`
- L6 — top-level `var region`

Silent:
- T3 — `apply`'s `when` over the sealed `Entry` is exhaustive over a closed sum
- N2 — `Store.ids` and `Ledger` names map one-to-one
