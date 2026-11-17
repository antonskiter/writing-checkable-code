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
- **`however the predicates are spelled`** alone in T3. Broadened "the single
  value every branch tests" to any value appearing in every branch, so a chain
  comparing one value against three different others became a kind dispatch;
  it also disagreed with M4, which had kept the older wording. Both rows now
  say a value compared against different others tests no kind.
- **`every body is unmeasured, not passing`** in F2. Reached before the
  exemption, so with no complexity checker installed the row returned a finding
  on every body in every fixture. The absence of the checker is one finding
  about the build.
- **`written anywhere but its declaration`** in L6. Undecidable between "state
  that anyone writes" and "the write is the offence", so a body merely reading
  `os.environ` sat between L6 and M2 with no rule deciding which.
- **Comment line cap** ("at most one line"). A count with no passing number: on
  `files/render.py` it fires on `render_cell`'s docstring, every line of which
  names one parameter's meaning, while M1 and X3 already decide that docstring by
  a run. The length of a comment follows from X3 placing in the signature what a
  type can carry. A body comment kept "only for a failure a reader would otherwise
  hit" is a reader-dependent check, rejected above.
- **Whole-data-set store clause** in F3 ("a value derived over the whole data
  set is stored, not recomputed per read"). A count of passes over the source
  with no passing number: a sum computed at need over a three-entry collection
  fires it, while the same Contract names computing at need as its first form.
- **Enumerated code and label source** in T5 ("its code a member of one
  enumeration and its text taken from one label source"). No run decides it at
  the unit: a lookup answering an absent key with a declared null carries no
  code and no text, and fired where the Check stayed silent, while a message
  built in place passed the Check. A label's text is one fact, and S1 decides
  where it lives.
- **"A unit named or called as a query states none"** in N1. Fired on every
  read-through cache, the stored derived value F3 allows included, and on a read
  counter the same Check exempts as a diagnostic. A narrower query sentence, a
  write changing what another entry point answers, decided nothing the first
  sentence did not: a unit's own object is an argument, so every such write is
  already a write the name does not state.
- **Key "taken from the declared inputs as data"** in F3. No run decides it: a
  key hand-listing exactly the inputs read passes every leg, so the clause could
  not fire.
- **"A recompute is a key coarser than its inputs"** in F3. Fired on a value
  computed at need, the Contract's own first form, and on correct conservative
  keys — a store-wide generation, a whole-file hash — that recompute more often
  and serve nothing wrong. The leg now fires only when a write to an unread input
  leaves a value the unit served unreadable.
- **"A name added beside an existing one … whichever came first"** in N2. The
  comparison is over the tree at one revision, so order never decided a verdict,
  and "interchangeable contracts under different names" already covers it.
- **"A missing dependency"** among T5's refusals. No argument provokes it; it is
  the I/O edge the same Contract exempts.
- **"Unless the parameter is typed as the standard library's own interfaces type
  that quantity"** in X3. No run decides it: no tree carries a parameter typed
  that way, and a float of seconds beside a time type that carries the unit is
  the case the same Check fires on.
- **"Own code probing which of several defaults exists"** in S1. No witness
  decides it, and its wording fires on a search order the platform documents and
  on an upward search for a marker file, where no setting is overridden. The fallback that answers while a
  location is configured remains.
- **"A unit that takes the output location's prior content as an input"** as an
  X4 exemption. No witness decides it, and it would silence the build that keeps
  a file its source no longer has (witness: X4-service-build-build-fires). The
  reused-location run now applies only where the signature or doc makes the
  output a function of the inputs alone, so an appender is never compared there.
- **"Conflicting"** among T5's refusals. A conflict between arguments alone is a
  precondition, which the same Check hands to X1.
