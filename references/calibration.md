# Where the rows must stay silent

Each entry is a shape a row is drawn to and must not fire on, with the clause
that spares it. Every one was reached by executing the check, and every one was
a false positive at some point in the rows' history. Consult the row you doubt;
the rest of the file is not needed.

## Contents

- [S1 — a value with one home](#s1)
- [S2 — copies that are alike by coincidence](#s2)
- [S3 — an acyclic codebase with no declared layers](#s3)
- [M1 — a wide signature that leaks nothing](#m1)
- [T3, M4 — one value compared against different others](#t3-m4)
- [T3 — an exhaustive match over a closed sum](#t3)
- [F2 — a body in a build with no complexity checker](#f2)
- [F4 — branches that cannot both match](#f4)
- [N2 — distinct names for distinct contracts](#n2)
- [L6 — a binding nothing writes after start-up](#l6)
- [X5 — findings one change clears together](#x5)

## S1

A constant read by the code and by nothing else, restated nowhere — not in a
sibling module, not in a schema, manifest or another language's source. Changing
it changes every behaviour that depends on it. **Silent.**

## S2

Sibling handlers with byte-identical bodies, one per case of a dispatch — three
stubs that each `return {"status": "ok"}`. The clause: *copies no single input
reaches are alike by coincidence*. No input reaches two of them, so changing one
changes only the case it serves. Fusing them would weld unrelated cases into one
unit. **Silent** — and folding them is the defect, not the fix.

## S3

Two or more units, dependencies acyclic, every unit taking a number, and no
layer map anywhere in the repository. **Not a pass and not a fire:** the row
reports *placement unverified*, because levelization detects cycles only and any
acyclic graph passes, including an upside-down one.

That verdict is the repository's, not a file's: with no map declared anywhere, the
same *placement unverified* holds for every file in the tree, so it is reported
once under the repository rather than restated in each file's findings. Executed
over the three trees the rows were calibrated against: 11 units, every one
numbered, no cycle, and no declared map in any form a tree can carry one — an
import contract, a layered architecture rule, a path restriction, a checked-in
layer list. **Silent per file**, and silence about a file is not a pass for it.
The cycle half still fires per file: a unit in a cycle takes no number, and that
finding is the file's.

## M1

A formatting function taking seven parameters — label, value, unit, precision,
alignment, width, fill. Wide, but every one of the seven is a value the caller
chooses and can supply without knowing anything about the module. **Silent.** No
row counts parameters: two rules that did were tried, failed testing and were
removed, one measuring literal frequency across call sites and one asking whether
a caller would pass a different value.

## T3, M4

A body whose branches test one value against several different others — an
interval's start against its end, against a clock, against a set of holidays.
One value recurs, so this reads like a kind dispatch and is not: nothing tests
its *kind*. The clause: *branches comparing one value against different others
test no kind*, and *host no cases*. **Silent for both rows.** Forcing a table
here reintroduces the ordering as data — see F4, which is the row that does fire
on this shape.

## T3

A `switch` or `when` over a sealed type or discriminated union, every member
enumerated, no fallback arm. The clause: *an exhaustive match over a closed sum
is already the table*. **Silent** — and dissolving it into polymorphism destroys
the compiler's exhaustiveness guarantee, so the refactor makes the code worse.

The exemption is narrow: *exhaustive means adding a member breaks the build*. A
`default` or `else` arm forfeits exactly that, so a switch carrying one is not
exhaustive and T3 fires.

## F2

Any body at all, in a repository whose build configures no complexity checker —
no `max-complexity`, no `C901`, no `gocyclo`, no gate in CI. **Silent per body**,
and per file: nothing measured this body, and the clause is *one finding, not one
per body*. What remains is a verdict about the build, reported once under the
repository and not among a file's findings, as the reporting rule after X5
directs. Executed over the three trees the rows were calibrated against: a McCabe
gate installed at 10 for the run fails no body in any of them — 0 findings, where
the same gate at 1 reports 12 — so the absent checker separated no body and no
file from any other, which is what makes it the build's finding and not theirs.
Silence about a body is not a pass for it.

## F4

A body with two branches whose conditions no single input satisfies together —
one testing a value against a threshold, the other against its own upper bound.
The clause: *with none the branches are exempt*. **Silent**, because permuting
them cannot change a result.

Also exempt: a run of guards whose rejections differ in nothing but the message.
Guards whose rejections differ in code, kind, or side effect are not — ordering
decides which fires.

## N2

Two symbols with similar names in different modules whose contracts differ in
effect and return shape, and no two interchangeable contracts under different
names. **Silent.** The row compares contracts, not spellings, so a shared verb
across genuinely distinct operations is not a homonym.

## L6

A module-level constant and a module-level logger handle, neither reassigned nor
mutated after the module loads. **Silent.** The rule's subject is state written
after start-up; a binding merely *read* by a body belongs to M2 and M3.

## X5

Several rows firing at one site, all of them cleared by one change. An elif chain
on an event kind hosts M4, T3 and L2; replacing it with a table and a strict
lookup clears all three. **Silent as a grouping.** Executed: the table alone
leaves L2 firing — an unknown kind still routes to a real case — and a strict
`else: raise` alone leaves M4 and T3 firing, the chain intact. Two smaller
changes each clear part of the set, so the clause *no smaller change clears any
of them alone* holds, and these are two defects reported separately.

One site is not the test, and neither is one file. Two homes of a value in
separate modules — `RETRY_LIMIT` beside `MAX_RETRIES`, firing S1 and N2 — are one
defect: deleting the second home clears both, and no smaller change clears N2
alone. Two absent build gates — no complexity checker and no layer map, firing F2
and S3 — are two, because installing either clears its row by itself.
