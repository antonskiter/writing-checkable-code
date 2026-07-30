#!/usr/bin/env bash
# Checks the shape of SKILL.md's rule blocks. In the table layout a rule missing
# its check was a visibly empty cell; in the block layout it is invisible, so it
# is checked here instead.
#
# Every "### <id> · <group>" block carries a Contract line and a Check line, and
# each of those carries text. A label with nothing after it is the case this
# exists to catch.
cd "$(dirname "$0")/.." || exit 1

status=0
fail() { printf '%s\n' "$@"; status=1; }

empty=$(grep -nE '^\*\*(Contract|Check)\.\*\* *$' SKILL.md)
[ -n "$empty" ] && fail "field label with no text:" "$empty"

# The trailing sentinel closes the last block, so one rule set covers them all.
missing=$({ cat SKILL.md; printf '### . .\n'; } | awk '
  /^### / { if (id != "" && (c == 0 || k == 0)) print id; id = $2; c = 0; k = 0; next }
  /^\*\*Contract\.\*\* *[^[:space:]]/ { c++ }
  /^\*\*Check\.\*\* *[^[:space:]]/    { k++ }
')
[ -n "$missing" ] && fail "missing Contract or Check: $(printf '%s' "$missing" | tr '\n' ' ')"

dupes=$(grep -oE '^### [A-Z][0-9]' SKILL.md | sort | uniq -d | grep -oE '[A-Z][0-9]')
[ -n "$dupes" ] && fail "duplicate id: $(printf '%s' "$dupes" | tr '\n' ' ')"

# Every id calibration.md cites exists in SKILL.md, as a block for the contract
# rows and as a bullet for the mechanical ones.
for id in $(grep -oE '^- \[[A-Z][0-9]' references/calibration.md | grep -oE '[A-Z][0-9]'); do
  grep -qE "^(### $id |- \*\*$id\*\*)" SKILL.md || fail "calibration.md cites $id, absent from SKILL.md"
done

[ $status -eq 0 ] && printf '%s rule block(s), each with a Contract and a Check\n' "$(grep -c '^### ' SKILL.md)"
exit $status
