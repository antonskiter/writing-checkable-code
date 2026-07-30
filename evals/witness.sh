#!/usr/bin/env bash
# Runs the witnesses in witnesses/. One witness per recorded verdict: it exits 0
# when the verdict reproduces and non-zero when it does not.
#
# VERDICTS.md names the witness that decides each verdict it can. The value a
# verdict turns on lives here, in the script that asserts it against the fixture,
# so it cannot go stale unnoticed the way a recorded observation could.
#
# Naming: <RULE>-<fixture>-<symbol>-<fires|silent>.sh. A witness that needs a
# toolchain it cannot find exits 77 and is reported SKIP, which fails the run.
#
# Witnesses are independent, so they run concurrently: serially the kotlin ones
# alone take over two minutes of compilation. Each writes its own report file so
# a failure stays attached to the witness that produced it. Pass a substring to
# run a subset, e.g. ./witness.sh python.
cd "$(dirname "$0")" || exit 1
export GO111MODULE=off

reports=$(mktemp -d); trap 'rm -rf "$reports"' EXIT
export reports

one() {
  local w=$1 name out rc
  name=$(basename "$w" .sh)
  out=$("$w" 2>&1); rc=$?
  {
    case $rc in
      0)  printf 'PASS %s\n' "$name" ;;
      77) printf 'SKIP %s — %s\n' "$name" "$out" ;;
      *)  printf 'FAIL %s\n' "$name"; printf '%s\n' "$out" | sed 's/^/       /' ;;
    esac
  } >"$reports/$name"
}
export -f one

find witnesses -name "*${1:-}*.sh" -print0 |
  xargs -0 -P "$(nproc)" -I{} bash -c 'one "$@"' _ {}

for r in "$reports"/*; do cat "$r"; done
printf '\n%s passed, %s failed, %s skipped\n' \
  "$(grep -lc '^PASS ' "$reports"/* 2>/dev/null | wc -l)" \
  "$(grep -lc '^FAIL ' "$reports"/* 2>/dev/null | wc -l)" \
  "$(grep -lc '^SKIP ' "$reports"/* 2>/dev/null | wc -l)"

! grep -q '^FAIL \|^SKIP ' "$reports"/* && [ -n "$(ls -A "$reports")" ]
