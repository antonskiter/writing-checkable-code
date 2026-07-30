# Evaluation results

Iteration 1 of `evals.json`, scored by a grader that read the reviews and the
sources but not the rules, so it scored substance rather than vocabulary. One run
per cell.

## Score

| | eval 1 | eval 2 | eval 3 | total |
|---|---|---|---|---|
| with the skill | 6/6 | 5/5 | 5/5 | 16.0 / 16 |
| baseline | 4 pass, 1 partial, 1 fail | 4 pass, 1 partial | 5/5 | 14.0 / 16 |

Neither arm produced a false positive: every behavioural claim in all six reviews
reproduced when re-run.

## What the two points are, and what they are not

Twelve of sixteen expectations returned the same verdict from both arms, and on
all nine that ask for a defect to be reported the arms were identical. Recall is
not what separated them. Two things did.

**A forbidden refactor is refused on a different ground.** Both arms declined to
fold the three sibling label handlers. The skill's ground was a property of the
code as it stands — no single input reaches two of them. The baseline's ground was
a forecast, that the bodies are alike only because they are empty, which obliges
it to offer the merge if the forecast is wrong; it does offer it. A ground that
holds now and a ground that holds later behave differently under a reader who
disagrees about later.

**A finding whose check did not run is disposed of differently.** Both arms hit a
question the four-file sandbox cannot settle. One files it as unverified, the
other reports it as a live either/or with an unrun grep named as the way to
settle it.

Depth cut both ways. The larger mutant set found that `tier_for`'s answer is
decided by guard order — permuting the guards returns silver for a gold spend and
the suite still passes. The baseline found that the `// 10` and `// 20` divisors
are rates in disguise, that the rounding direction is undeclared, and that
`render.py` is two unrelated modules in one file, which is the most substantive
finding no expectation covers.

## The rubric does not discriminate, and here is what would

Nine of sixteen expectations ask for defects a competent reviewer finds by
reading. Five are negatives about two famous false smells that a competent
reviewer pre-empts by name. Two ask for evidence, and both arms ran code. A
rubric of this shape measures competence, which both arms have.

A discriminating case needs at least one of:

- **Matched pairs.** A wide interface that does leak an internal, beside one that
  does not, so silence is not automatically correct.
- **A refactor that is expensive to resist.** Sibling handlers carrying ten lines
  of identical non-trivial logic, with a caller that already dispatches on type,
  so reachability must be established rather than asserted and forecasting
  divergence cannot substitute for it.
- **A claim settleable only by constructing an input.** Two functions that agree
  on every value the suite feeds and disagree on one outside it.
- **A file with no defects**, scoring restraint. Both arms returned ten or more
  findings on thirty-one lines and neither was ever tested for stopping.
- **An expectation that penalises a finding this file cannot decide**, which
  catches both the build-level boilerplate and the unrun grep.
- **An explicit evidence bar** — every finding backed by a run or marked
  unverified. That is the rule which actually separated the arms, and it was not
  in the rubric.
