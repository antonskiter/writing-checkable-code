---
name: writing-checkable-code
description: Use when writing or reviewing code and a design decision is in play — splitting a module, naming a module, type or function, designing a failure path or swallowing an error, raising an error, placing a constant or a setting, removing dead code, writing an interface comment; when a conditional chain, a duplicated fact, a copied block, a cached or derived value, or a subtype appears; when a case is added to a dispatch; when a passing suite or a clean checker is offered as evidence that code is correct; and on "refactor", "code review", "clean up this function", "is this good code", "DRY", "SOLID", "LSP", "code smell".
---

# Code Contracts

A declaration is an artifact a run can contradict — a type, a schema, a
registry, a test, a build gate. A comment asserting one is not a declaration.

A search for a second home, a reader or an entry point is over the whole tree
the build reads at the revision under review — every language, schema, manifest
and generated source — never the diff alone.

### S1 · System

**Contract.** Every fact — a value, a decision — has one home (Hunt & Thomas, DRY). A rule is S2's.

**Check.** Change the one home: anything still behaving by the old value, or still stating it, has a second. Search what the build ships but never runs — schema, manifest, another language's source. A test restating the value is the check, not a second home, provided it runs, fails when the one home changes, and does not supply the value to the code under test. A second home decides the row wherever it was found; one home is a claim over the whole tree, and without that search the fact is unverified, not single-homed.

### S2 · System

**Contract.** A rule has one implementation (Beck, once and only once).

**Check.** Change the rule at one copy, then feed one input the change affects to every entry point that must answer it: two answers is one rule in two homes. Copies no single input reaches are alike by coincidence, and fusing them welds two units into one (Yourdon & Constantine, coincidental cohesion). The entry points that must answer it are the whole tree's, not the diff's: two answers from any two of them is the finding, and without reaching the rest the rule is unverified beyond those exercised.

### S3 · System

**Contract.** Dependencies point one way: every unit takes a level number (Parnas; Lakos, levelization).

**Check.** Number each unit one above the highest unit it uses: a unit in a cycle takes no number, and neither unit in it can be tested alone. Against a declared layer map, a number above the declared layer is a misplaced unit; with no map, only cycles are checked and placement is unverified.

### M1 · Module

**Contract.** An interface gives the caller everything a call needs and nothing the caller must learn from inside the module (Parnas, information hiding; Ousterhout, information leakage).

**Check.** Call each unit the module offers, writing every argument from the signatures alone: one that fails until another unit of this module has run leaks an ordering requirement, and one that reaches what another unit produced only by passing a value that unit neither took nor returned leaks that value. Neither is a leak where a type leaves the correct call as the only one writable — the earlier unit returns what the later one takes. No count of parameters is a leak, and neither is a parameter whose value the caller chooses, however many there are and however narrow the set the body honours. The row clears when the leaking call can no longer be written, not when the module adds a name for the leaked value.

### M2 · Module

**Contract.** Configuration and collaborators arrive resolved, assembled at the entry point.

**Check.** Run the unit twice in one process under two values of the setting: if the second cannot reach it except by mutating the environment, a global or a cache, the setting is not resolved at the entry point.

### M3 · Module

**Contract.** Clock, network, filesystem, randomness and environment arrive as parameters (Feathers, seams).

**Check.** Run the unit twice in one process against two clocks, sockets, paths, seeds or environments: if the only lever is patching a module, a global or a private field, the seam is missing; if there is no lever at all, it is missing and unreachable from a test.

### M4 · Module

**Contract.** A new case is a new unit (Wadler, expression problem; Meyer, open–closed).

**Check.** Duplicate an existing case under a new key and diff: every changed line lands in the new unit or in an extension point that already existed — a sum type with its matches, a table, a registry, a schema. Branches comparing one value against different others host no cases.

### T1 · Type

**Contract.** A state that must not occur cannot be constructed (Minsky, illegal states unrepresentable; Meyer).

**Check.** Take the states the code already names — a guard, a raise, a validator's failure branch, a value the type permits and no branch handles. Construct one and follow it: if it reaches the work that must not run on it, the type is not carrying the constraint. With no such site the constraint is undeclared, not absent.

### T2 · Type

**Contract.** A successful check returns a type the raw input cannot inhabit, and downstream code takes that type (King, parse don't validate).

**Check.** Obtain that type without running the check: if you can, the type carries no proof. Name the signature downstream that takes it: with none, the work still runs on raw input. With no check between the input and the work, the input reaches it unproven.

### T3 · Type

**Contract.** A chain dispatching on one value's kind becomes polymorphism (Fowler) or a table keyed by that value (McConnell, table-driven methods).

**Check.** Name the value whose kind every branch tests: with one, the branches are cases of a type the code has not declared, however the predicates are spelled. Branches comparing one value against different others test no kind; an exhaustive match over a closed sum is already the table — exhaustive means adding a member breaks the build, so an arm matching anything else is not.

### T4 · Type

**Contract.** What holds of a type holds of its subtypes (Liskov & Wing, behavioral subtyping).

**Check.** Run the supertype's tests, parameterized over the constructor, against every declared or structural subtype, each built by the suite's own factory; a promise of immutability needs a mutation probe. With no such suite the subtype is unverified, and that is the finding.

### F1 · Function

**Contract.** One level of abstraction per body (Martin).

**Check.** List the body's callees and their callees: a callee the body reaches both directly and through another is a level the body has already delegated.

### F2 · Function

**Contract.** Each body stays inside a complexity budget.

**Check.** Checker in CI: over McCabe's 10 fails. A flat dispatch on one value is exempt, flat meaning each arm is a single call or return. With no checker in the build, the absent checker fires against the build — one finding, not one per body, and not unverified.

### F3 · Function

**Contract.** A derived value is computed at need, stored with its derivation asserted against the live source, or a snapshot whose bound the read enforces (Fowler, replace derived variable with query; Codd).

**Check.** Name every write of a derived value, change its source, and read that store back: a stale read with no failing assertion, and no bound the read refuses to serve past, is a second home for the source fact. A store nothing reads back is unverified.

### F4 · Function

**Contract.** Branches that can both match state which wins.

**Check.** Find an input satisfying two branch conditions: with none the branches are exempt, and so are guards whose rejections differ in nothing but the message. With one, permute the branches: a result that changes was decided by position, not by its condition.

### N1 · Name

**Contract.** The name is the contract.

**Check.** Compare the name against the body's writes — to an argument, a global, a file, a socket, the returned value — and its waits: a write the name does not state is a wrong name. Diagnostics are exempt.

### N2 · Name

**Contract.** Names and concepts map one-to-one across the codebase (Deißenböck & Pizka).

**Check.** Compare symbols by contract: two sharing a name with different effects are a homonym; two interchangeable contracts under different names are synonyms.

## Cross-cutting

### X1 · Failure

**Contract.** A violated condition stops the work where it is violated and names the offending value; an unknown value is an error (Shore, fail fast; Meyer).

**Check.** Feed a wrong value to every parameter and to every source the body reads: anything that completes normally, and any message that omits the offending value, is a silent failure. A unit that returns nothing is judged at its effect.

### X2 · Evidence

**Contract.** A claim about code is made by something that runs.

**Check.** Mutate the subject — each literal, comparison and branch — and rerun: a surviving mutant is a fact the check does not cover. Delete the subject: still passing means it proved nothing. With nothing that runs, every claim is unverified.

### X3 · Record

**Contract.** An interface comment states what the signature does not give — what the unit does, argument meaning, ordering, edge behaviour (Ousterhout).

**Check.** Write a call from the signature and comment alone, then run it: a wrong result, or a detail you had to take from the body — units, ordering, empty or absent input — is missing from the comment.

### X4 · Determinism

**Contract.** The same inputs produce the same output.

**Check.** Run it twice in fresh processes, from different directories, and diff what each emits: return value, stdout, files written, bytes sent. A unit emitting nothing observable is unverified.

### X5 · Convergence

**Contract.** Findings are one defect where one change clears every one of them and no smaller change clears any of them alone (Zeller & Hildebrandt, 1-minimality).

**Check.** Apply the change as a diff, then re-decide each row by its own check — a run where the check runs, the comparison the check names where it does not — recording what each returns per site, before and after. A site no longer named is cleared; a row moving from firing to unverified is not. A site still named is a separate defect; a row that begins firing is a defect the change introduced; a finding some smaller change clears alone was never one of the group. Removing a unit instead of repairing it is L3's finding, not a change. An unapplied change, or an untried smaller one, groups nothing: the grouping is unverified and each finding is reported alone.

Report each group at the row whose check the change answers, naming its sites.
Order what remains by consequence: a wrong answer, then a state that produces
one, then a missing seam, then missing evidence.

A finding the reviewed file cannot decide — F2's absent complexity checker, S3's
undeclared layer map — is the repository's and not the file's: the same one holds
for every file in the tree. Report it once, under the repository, after the file's
findings and not among them, naming the absent artifact. Restated per file, per
body or per unit it is still one finding, and the number of files it is restated
in says nothing about any of them. Its absence from a file's findings is not a
pass for that file.

## Mechanical

Fail the build on:

- **L1** an error discarded, or turned into a null, a default or a crash — logging it is discarding it; it is read only where its value reaches the caller or selects the recovery
- **L2** a value produced for an unrecognised kind — returned, dispatched to, substituted before the branch, or left to a missing arm
- **L3** a symbol no entry point reaches — delete it together with everything only it reaches, rebuild and rerun, nothing changes. A test-only caller is not reachability. Entry points are the tree's, not the diff's: without that rebuild over the tree, reachability is unverified and the symbol is not reported dead. Nothing to rerun is X2's finding, not a reason to withhold this one
- **L4** a comment whose subject is not the current code — a former version, a rejected alternative, or a schedule
- **L5** a suppressed, disabled or cast-away check with no owner, or with an expiry absent or already past — at the site, or in the configuration exempting the site
- **L6** mutable state a body reaches without receiving it — a module or static binding, a cell held by a module-level closure, a singleton behind an accessor, the environment — that any code writes after start-up

## When a verdict is unclear

`references/calibration.md` records, per row, the shape it is drawn to and must
not fire on, with the clause that spares it. Read the entry for the row in
doubt; each one was a false positive before it was a clause. A resemblance to a
recorded shape never stands in for running the check.

## Keywords

Defaults while writing, before any row can fire:

- **separate logic / config / data / content** — config is one enumerable
  surface resolved at the entry point; state lives under XDG paths; no
  deployment fact inside logic
- **standard unix log** — diagnostics to stderr with severity, verbosity a
  config lever; stdout carries only the data asked for
- **no hardcoded values** — a literal that is a decision is a named setting
- **sync by notification, not by sleep** — the ready party signals, the
  waiter blocks on the trigger
- **timeouts detect faults** — a wait bounds failure loudly; it is never the
  mechanism that makes a thing work
- **dispatch, not elif** — a new case is a unit, a table entry, or a sum-type
  arm
- **established lib first** — stdlib or a proven library before hand-rolling
  a parser, retry, cache, or algorithm
