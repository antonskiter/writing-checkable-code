---
name: writing-checkable-code
description: Use when writing or reviewing code and a design decision is in play — splitting a module, naming a thing, designing a failure path or swallowing an error, raising an error, placing a constant or a setting, removing dead code, writing a comment; when a conditional chain, a duplicated fact, a copied block, a cached or derived value, or a subtype appears; when a case is added to a dispatch; when a test, linter, or checker reports success; and on "refactor", "code review", "clean up this function", "is this good code", "DRY", "SOLID", "LSP", "code smell".
---

# Code Contracts

| | Contract | Check |
|---|---|---|
| **S1** System | Every fact — value, rule, decision — has one home (Hunt & Thomas, DRY). | Change the one home: anything still behaving by the old value has a second. A test restating the value to assert behaviour is the check, not a second home. |
| **S2** System | A rule has one implementation (Beck, once and only once). | Change the rule at one copy: a second copy that must change identically is one rule in two homes; copies free to diverge are alike by coincidence, and fusing them welds two units into one (Yourdon & Constantine, coincidental cohesion). |
| **S3** System | Dependencies point one way: every unit takes a level number (Parnas; Lakos, levelization). | Number each unit one above the highest unit it uses: a unit in a cycle takes no number, and neither unit in it can be tested alone. Where layers are declared, a number above the declared layer is a misplaced unit. |
| **M1** Module | A simple interface over substantial work (Parnas; Ousterhout, deep modules). | List what a caller must know: anything on the list the caller cannot choose is a leak. |
| **M2** Module | Configuration and collaborators arrive resolved, assembled at the entry point. | Trace a setting to its use: a read below the entry point is a second home. |
| **M3** Module | Clock, network, filesystem and randomness arrive as parameters (Feathers, seams). | Read the signature: a clock, socket, path or seed the body reaches for and the signature does not name is a missing seam. |
| **M4** Module | A new case is a new unit (Wadler, expression problem; Meyer, open–closed). | Add the case and diff: every changed line lands in the new unit or in an extension point declared before the change — a sum type with its matches, a table, a registry, a schema. A chain of unrelated predicates hosts no cases. |
| **T1** Type | A state that must not occur cannot be constructed (Minsky, illegal states unrepresentable; Meyer). | Write the line that constructs it, then follow the value: if it reaches the work that must not run on it, the type is not carrying the constraint. |
| **T2** Type | A successful check returns a type the raw input cannot inhabit, and downstream code takes that type (King, parse don't validate). | Obtain that type without running the check: if you can, the type carries no proof. Name the signature downstream that takes it: with none, the work still runs on raw input. |
| **T3** Type | A chain dispatching on one value's kind becomes polymorphism (Fowler) or a table keyed by that value (McConnell, table-driven methods). | Name the single value every branch tests: with one, the branches are cases of a type the code has not declared. Unrelated predicates encode no type; an exhaustive match over a closed sum is already the table. |
| **T4** Type | What holds of a type holds of its subtypes (Liskov & Wing, behavioral subtyping). | Run the supertype's tests, parameterized over the constructor, against each subtype; a promise of immutability needs a mutation probe. With no such suite the subtype is unverified, not passing. |
| **F1** Function | One level of abstraction per body (Martin). | Name each statement's operation: a body holding a domain step and the arithmetic that implements it has two levels. |
| **F2** Function | Each body stays inside a complexity budget. | Checker in CI: over McCabe's 10 fails. A flat dispatch on one value is exempt; a cascade of unrelated conditions is not. |
| **F4** Function | Branches that can both match state which wins. | Permute the branches and rerun: an input whose result changes was decided by position, not by its condition. Guards that all reject the input are exempt. |
| **F3** Function | A derived value is computed at need, stored with its derivation asserted, or a snapshot with a declared bound (Fowler, replace derived variable with query; Codd). | Change the source data and read the derived value: a stale read with no failing assertion and no declared bound is a second home for the source fact. |
| **N1** Name | The name is the contract. | Compare the name against what the body does: an effect the body has and the name does not state is a wrong name. |
| **N2** Name | Names and concepts map one-to-one across the codebase (Deißenböck & Pizka). | Compare symbols by contract: two sharing a name with different effects are a homonym; two interchangeable contracts under different names are synonyms. |

## Cross-cutting

| | Contract | Check |
|---|---|---|
| **X1** Failure | A violated condition stops the work where it is violated and names the offending value; an unknown value is an error (Shore, fail fast; Meyer). | Feed every input a wrong value: anything that still produces output, and any message that omits the offending value, is a silent failure. |
| **X2** Evidence | A claim about code is made by something that runs. | Break what the check protects and confirm the check fails. Delete its subject and rerun: still passing means it proved nothing. With nothing that runs, every claim is unverified. |
| **X3** Record | An interface comment states what the signature does not give — what the unit does, argument meaning, ordering, edge behaviour (Ousterhout). | Call the unit using only its signature and comment: anything you must read the body to get right is missing from the comment. |
| **X4** Determinism | The same inputs produce the same output. | Run it twice in fresh processes, from different directories, and diff. |

Rows firing on the same lines are one defect: report it once, under the row whose remedy repairs the rest.

## Mechanical

Fail the build on:

- **L1** an error discarded, or turned into a null, a default or a crash without being read
- **L2** a fallback returned for an unrecognised kind
- **L3** an unexported symbol with no caller — delete it, rebuild, nothing changes
- **L4** a comment containing *we decided*, *we considered*, *used to*, *for now*
- **L5** a suppressed or disabled check with no owner and expiry at the site
- **L6** a binding outside any function that is reassigned or mutated
