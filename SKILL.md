---
name: writing-checkable-code
description: Use when writing or reviewing code and a design decision is in play — splitting a module, naming a thing, designing a failure path or swallowing an error, raising an error, placing a constant or a setting, removing dead code, writing a comment; when a conditional chain or a duplicated fact appears; when a test, linter, or checker reports success; and on "refactor", "code review", "clean up this function", "is this good code".
---

# Code Contracts

| | Contract | Check |
|---|---|---|
| **System** | Every fact — value, rule, decision — has one home (Hunt & Thomas). | Change the one home: anything still behaving by the old value has a second. A test restating the value to assert behaviour is the check, not a second home. |
| **System** | Dependencies point one way. | Build the import graph: in a cycle neither unit can be tested alone. |
| **Module** | A simple interface over substantial work (Parnas; Ousterhout). | List what a caller must know: anything on the list the caller cannot choose is a leak. |
| **Module** | Configuration and collaborators arrive resolved, assembled at the entry point. | Trace a setting to its use: a read below the entry point is a second home. |
| **Module** | Clock, network, filesystem and randomness arrive as parameters. | Read the signature: a clock, socket, path or seed the body reaches for and it does not name is a missing seam. |
| **Type** | A state that must not occur cannot be constructed (Yaron Minsky; Meyer). | Write the line that constructs it, then follow the value: if it reaches the work that must not run on it, the type is not carrying the constraint. |
| **Type** | A successful check returns a type the raw input cannot inhabit, and downstream code takes that type (King). | Obtain that type without running the check: if you can, the type carries no proof. Name the signature downstream that takes it: with none, the work still runs on raw input. |
| **Type** | A chain dispatching on one value's kind becomes polymorphism (Fowler) or a table keyed by that value (McConnell). | Name the single value every branch tests: with one, the branches are cases of a type the code has not declared. Unrelated predicates encode no type; an exhaustive match over a closed sum is already the table. |
| **Function** | One level of abstraction per body (Martin). | Name each statement's operation: a body holding a domain step and the arithmetic that implements it has two levels. |
| **Function** | Each body stays inside a complexity budget. | Checker in CI: over McCabe's 10 fails; a single flat multiway decision is exempt. |
| **Name** | The name is the contract, in the vocabulary of its altitude. | Compare the name against what the body does: an effect the body has and the name does not state is a wrong name. |

## Cross-cutting

| | Contract | Check |
|---|---|---|
| **Failure** | A violated condition stops the work where it is violated and names the offending value; an unknown value is an error (Shore; Meyer). | Feed every input a wrong value: anything that still produces output is a silent failure. Every message names the offending value. |
| **Evidence** | A claim about code is made by something that runs. | Break what the check protects and confirm the check fails. Delete its subject and rerun: still passing means it proved nothing. With nothing that runs, every claim is unverified. |
| **Record** | An interface comment states what the signature does not give — what the unit does, argument meaning, ordering, edge behaviour (Ousterhout). | Call the unit using only its signature and comment: anything you must read the body to get right is missing from the comment. |
| **Determinism** | The same inputs produce the same output. | Run it twice in fresh processes, from different directories, and diff. |

## Mechanical

Linter rules. Fail the build on:

- an error discarded, or turned into a null, a default or a crash without being read
- a fallback returned for an unrecognised kind
- an unexported symbol with no caller — delete it, rebuild, nothing changes
- a comment containing *we decided*, *we considered*, *used to*, *for now*
- a suppressed or disabled check with no owner and expiry at the site
- a binding outside any function that is reassigned or mutated
