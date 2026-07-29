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
