#!/usr/bin/env bash
# Checks the shape of SKILL.md's rule blocks. In the table layout a rule missing
# its check was a visibly empty cell; in the block layout it is invisible, so it
# is checked here instead.
#
# Fails when a "### <ID> · <Group>" block does not carry exactly one
# "**Contract.**" and one "**Check.**", when an ID is duplicated, or when an ID
# cited by references/calibration.md has no block.
cd "$(dirname "$0")/.." || exit 1

skill=SKILL.md
status=0

report() { printf '%s\n' "$1"; status=1; }

# One line per block: <id> <contract-count> <check-count>
blocks=$(awk '
  /^### / { id = $2; seen[++n] = id; next }
  /^## /  { id = "" }
  id != "" && /^\*\*Contract\.\*\*/ { c[id]++ }
  id != "" && /^\*\*Check\.\*\*/    { k[id]++ }
  END { for (i = 1; i <= n; i++) print seen[i], c[seen[i]] + 0, k[seen[i]] + 0 }
' "$skill")

[ -z "$blocks" ] && { report "no rule blocks found in $skill"; exit 1; }

while read -r id contracts checks; do
  [ "$contracts" = 1 ] || report "$id: $contracts Contract field(s), expected 1"
  [ "$checks" = 1 ] || report "$id: $checks Check field(s), expected 1"
done <<<"$blocks"

dupes=$(printf '%s\n' "$blocks" | awk '{ print $1 }' | sort | uniq -d)
[ -n "$dupes" ] && report "duplicate rule id(s): $(printf '%s' "$dupes" | tr '\n' ' ')"

# Every ID cited by calibration.md must exist in SKILL.md, as a block for the
# contract rows and as a bullet for the mechanical ones.
have=$({ printf '%s\n' "$blocks" | awk '{ print $1 }'
         grep -oE '^- \*\*L[0-9]\*\*' "$skill" | grep -oE 'L[0-9]'; } | sort -u)
for id in $(grep -oE '^- \[[A-Z][0-9]' references/calibration.md | grep -oE '[A-Z][0-9]' | sort -u); do
  printf '%s\n' "$have" | grep -qx "$id" || report "calibration.md cites $id, absent from $skill"
done

n=$(printf '%s\n' "$blocks" | grep -c '')
[ $status -eq 0 ] && printf '%s rule block(s), each with one Contract and one Check\n' "$n"

exit $status
