# Fixture map

Bait code with known verdicts, anchored to function names. An edit to a SKILL.md
check is validated by re-running it here: every "fires" entry must still fire,
every "silent" entry must stay silent.

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
