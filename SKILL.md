---
name: writing-checkable-code
description: Use when writing or reviewing code and a design decision is in play — splitting a module, naming a module, type or function, designing a failure path or swallowing an error, raising an error, placing a constant or a setting, removing dead code, writing an interface comment; when a conditional chain, a duplicated fact, a copied block, a cached or derived value, or a subtype appears; when a case is added to a dispatch; when a passing suite or a clean checker is offered as evidence that code is correct; and on "refactor", "code review", "clean up this function", "is this good code", "DRY", "SOLID", "LSP", "code smell".
---

# Code Contracts

A declaration is an artifact a run can contradict — a type, a schema, a
registry, a test, a build gate. A comment asserting one is not a declaration.

| | Contract | Check |
|---|---|---|
| **S1** System | Every fact — value, rule, decision — has one home (Hunt & Thomas, DRY). | Change the one home: anything still behaving by the old value, or still stating it, has a second. Search what the build ships but never runs — schema, manifest, another language's source. A test restating the value is the check, not a second home, provided it runs, fails when the one home changes, and does not supply the value to the code under test. |
| **S2** System | A rule has one implementation (Beck, once and only once). | Change the rule at one copy, then feed one input the change affects to every entry point that must answer it: two answers is one rule in two homes. Copies no single input reaches are alike by coincidence, and fusing them welds two units into one (Yourdon & Constantine, coincidental cohesion). |
| **S3** System | Dependencies point one way: every unit takes a level number (Parnas; Lakos, levelization). | Number each unit one above the highest unit it uses: a unit in a cycle takes no number, and neither unit in it can be tested alone. Against a declared layer map, a number above the declared layer is a misplaced unit; with no map, only cycles are checked and placement is unverified. |
| **M1** Module | A simple interface over substantial work (Parnas; Ousterhout, deep modules). | Read the signature and its comment: a parameter, field or ordering requirement whose value the caller can obtain only from this module is a leak. |
| **M2** Module | Configuration and collaborators arrive resolved, assembled at the entry point. | Run the unit twice in one process under two values of the setting: if the second cannot reach it except by mutating the environment, a global or a cache, the setting is not resolved at the entry point. |
| **M3** Module | Clock, network, filesystem, randomness and environment arrive as parameters (Feathers, seams). | Run the unit twice in one process against two clocks, sockets, paths, seeds or environments: if the only lever is patching a module, a global or a private field, the seam is missing; if there is no lever at all, it is missing and unreachable from a test. |
| **M4** Module | A new case is a new unit (Wadler, expression problem; Meyer, open–closed). | Duplicate an existing case under a new key and diff: every changed line lands in the new unit or in an extension point that already existed — a sum type with its matches, a table, a registry, a schema. Branches comparing one value against different others host no cases. |
| **T1** Type | A state that must not occur cannot be constructed (Minsky, illegal states unrepresentable; Meyer). | Take the states the code already names — a guard, a raise, a validator's failure branch, a value the type permits and no branch handles. Construct one and follow it: if it reaches the work that must not run on it, the type is not carrying the constraint. With no such site the constraint is undeclared, not absent. |
| **T2** Type | A successful check returns a type the raw input cannot inhabit, and downstream code takes that type (King, parse don't validate). | Obtain that type without running the check: if you can, the type carries no proof. Name the signature downstream that takes it: with none, the work still runs on raw input. With no check between the input and the work, the input reaches it unproven. |
| **T3** Type | A chain dispatching on one value's kind becomes polymorphism (Fowler) or a table keyed by that value (McConnell, table-driven methods). | Name the value whose kind every branch tests: with one, the branches are cases of a type the code has not declared, however the predicates are spelled. Branches comparing one value against different others test no kind; an exhaustive match over a closed sum is already the table — exhaustive means adding a member breaks the build, so an arm matching anything else is not. |
| **T4** Type | What holds of a type holds of its subtypes (Liskov & Wing, behavioral subtyping). | Run the supertype's tests, parameterized over the constructor, against every declared or structural subtype, each built by the suite's own factory; a promise of immutability needs a mutation probe. With no such suite the subtype is unverified, and that is the finding. |
| **F1** Function | One level of abstraction per body (Martin). | List the body's callees and their callees: a callee the body reaches both directly and through another is a level the body has already delegated. |
| **F2** Function | Each body stays inside a complexity budget. | Checker in CI: over McCabe's 10 fails. A flat dispatch on one value is exempt, flat meaning each arm is a single call or return. With no checker in the build, that absence is the finding, not each body. |
| **F3** Function | A derived value is computed at need, stored with its derivation asserted against the live source, or a snapshot whose bound the read enforces (Fowler, replace derived variable with query; Codd). | Name every write of a derived value, change its source, and read that store back: a stale read with no failing assertion, and no bound the read refuses to serve past, is a second home for the source fact. A store nothing reads back is unverified. |
| **F4** Function | Branches that can both match state which wins. | Find an input satisfying two branch conditions: with none the branches are exempt, and so are guards whose rejections differ in nothing but the message. With one, permute the branches: a result that changes was decided by position, not by its condition. |
| **N1** Name | The name is the contract. | Compare the name against the body's writes — to an argument, a global, a file, a socket, the returned value — and its waits: a write the name does not state is a wrong name. Diagnostics are exempt. |
| **N2** Name | Names and concepts map one-to-one across the codebase (Deißenböck & Pizka). | Compare symbols by contract: two sharing a name with different effects are a homonym; two interchangeable contracts under different names are synonyms. |

## Cross-cutting

| | Contract | Check |
|---|---|---|
| **X1** Failure | A violated condition stops the work where it is violated and names the offending value; an unknown value is an error (Shore, fail fast; Meyer). | Feed a wrong value to every parameter and to every source the body reads: anything that completes normally, and any message that omits the offending value, is a silent failure. A unit that returns nothing is judged at its effect. |
| **X2** Evidence | A claim about code is made by something that runs. | Mutate the subject — each literal, comparison and branch — and rerun: a surviving mutant is a fact the check does not cover. Delete the subject: still passing means it proved nothing. With nothing that runs, every claim is unverified. |
| **X3** Record | An interface comment states what the signature does not give — what the unit does, argument meaning, ordering, edge behaviour (Ousterhout). | Write a call from the signature and comment alone, then run it: a wrong result, or a detail you had to take from the body — units, ordering, empty or absent input — is missing from the comment. |
| **X4** Determinism | The same inputs produce the same output. | Run it twice in fresh processes, from different directories, and diff what each emits: return value, stdout, files written, bytes sent. A unit emitting nothing observable is unverified. |

Rows firing on the same lines are one defect only where one row's remedy repairs
the rest; report it there, and report the others separately. Order what remains by
consequence: a wrong answer, then a state that produces one, then a missing seam,
then missing evidence.

## Mechanical

Fail the build on:

- **L1** an error discarded, or turned into a null, a default or a crash — logging it is discarding it; it is read only where its value reaches the caller or selects the recovery
- **L2** a value produced for an unrecognised kind — returned, dispatched to, substituted before the branch, or left to a missing arm
- **L3** a symbol no entry point reaches — delete it together with everything only it reaches, rebuild and rerun, nothing changes. A test-only caller is not reachability
- **L4** a comment whose subject is not the current code — a former version, a rejected alternative, or a schedule
- **L5** a suppressed, disabled or cast-away check with no owner, or with an expiry absent or already past — at the site, or in the configuration exempting the site
- **L6** mutable state a body reaches without receiving it — a module or static binding, a cell held by a module-level closure, a singleton behind an accessor, the environment — that any code writes after start-up
