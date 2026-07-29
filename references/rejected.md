# Rejected rules

Rules tried against the fixtures and removed, with the evidence. Re-adding one
requires new evidence against its entry.

- **Clone-fragment build gate** ("a fragment repeated verbatim or with only
  identifiers renamed"). Fails idiomatic error handling — 2,285 verbatim
  `if err != nil` bodies in the Go standard library — and the per-case stubs M4
  mandates; no fragment size is selective. Duplication is governed by S2's
  change test.
- **Parameter-ownership row** ("each parameter carries a decision only the
  caller can make"). Two check forms failed: literal-frequency across call sites
  false-fires on injected seams (M3's subjects) and degenerates at zero or one
  call site; "name a caller that would pass a different value" is satisfiable
  for any parameter, so it fires on nothing.
- **Open/Closed file-count check** ("add one variant, count files edited").
  Yields a measurement with no passing number, and contradicts T3 on chains of
  unrelated predicates. Superseded by M4's extension-point diff.
- **Exemption-report row** ("a summary says n exempt, never clean").
  Presupposes a reporting harness no rule requires to exist; produces no
  verdict. Superseded by L5.
- **Decision-record row** (Nygard ADRs). On a codebase without records it fires
  on every decision equally, which carries the same information as firing on
  none. Interface comments remain X3.
- **"Bare catch" wording.** The term of art excludes `except Exception: pass`,
  so the worst case passes; Go has no catch at all and Swift's `try?` is not
  one. Superseded by L1's error-value form.
- **"Different iteration order" clause** in X4's check. Names a knob that is
  `PYTHONHASHSEED` in Python, absent in Go and JavaScript, inverted in Swift.
  The fresh-process diff remains.
- **Principle of Least Astonishment.** No primary source: zero hits across 60
  Jargon File editions; the 1972 "Law of Least Astonishment" is quoted from
  nobody. Naming agreement between two people is under 20% (Furnas 1987), so no
  check is possible.
- **"In the vocabulary of its altitude"** qualifier on N1. A sub-rule no check
  decided.
- **Reader-dependent checks** ("show a reader", "read it aloud", "name what
  each call site means"). The reviewer authors the missing object — reader,
  meaning, concept — and therefore authors the verdict. Each was replaced by a
  comparison against an artifact that exists independently: the body, the
  signature, the contract, the diff, a run.
- **Wordings that accept prose as the artifact.** Six rules were escapable by
  the author writing a claim rather than an artifact: a "declared bound" as a
  comment, a "declared extension point" naming the whole module, "declared
  layers" deleted so nothing can be misplaced, an owner and expiry already
  past, "free to diverge" asserted about future requirements. The document now
  fixes the term once: a declaration is an artifact a run can contradict.
- **`without being read`** as L1's qualifier. Satisfied by logging the error
  and swallowing it, which is worse than the discard it was written to catch —
  the marker is consumed and the failure still reaches no caller.
- **`exhaustive`** unqualified in T3's exemption. A `switch` with a `default`
  arm is exhaustive at runtime, so the exemption covered the shape it exists to
  exclude; verified with `tsc --strict`, where adding a union member to such a
  switch compiles clean while a `never`-checked match fails the build.
- **Deletion as X2's only probe.** A body stubbed to a same-typed constant
  keeps type-shaped assertions green, while stubbing to null fails them, so the
  same subject passes or fails on how the deletion is spelled. Mutation decides
  it: on `fixtures/python`, 5 of 5 mutants survive a suite that deletion rates
  as evidence.
