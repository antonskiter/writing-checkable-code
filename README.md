# writing-checkable-code

A skill for [Claude Code](https://claude.com/claude-code). Fifteen code contracts,
each paired with a check that decides it, plus six rules a linter can enforce.

Install into a user-scoped skill directory:

```
git clone https://github.com/antonskiter/writing-checkable-code \
  ~/.claude/skills/writing-checkable-code
```

The skill loads when a design decision is in play — splitting a module, naming a
thing, placing a setting, handling a failure — and when a conditional chain, a
duplicated fact, or a passing test suite appears.

`references/` ships with the skill: `calibration.md` records where each rule
must stay silent, which is where false positives come from.

`evals/` is development apparatus and is excluded from packaged builds and
release archives. It holds bait code in Python, Go, TypeScript, JavaScript, Lua,
Bash, Swift, Java and Kotlin with known verdicts per rule (`CORPUS.md`), the
linter harness (`lint.sh`), and `rejected.md` — rules tried and removed, with
the evidence. An edit to a check is validated by re-running it there.
