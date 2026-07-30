#!/usr/bin/env bash
# Runs the witnesses in witnesses/. One witness per recorded verdict: it exits 0
# when the verdict reproduces and non-zero when it does not.
#
# CORPUS.md records what a check returned when it was last run by hand. A stored
# observation with nothing asserting it against the fixture goes stale silently,
# so the observations that can be re-executed live here as scripts instead.
#
# Naming: <RULE>-<fixture>-<symbol>-<fires|silent>.sh. A witness that needs a
# toolchain it cannot find exits 77 and is reported SKIP, which fails the run.
cd "$(dirname "$0")" || exit 1
export GO111MODULE=off

pass=0 fail=0 skip=0
only=${1:-}

for w in witnesses/*.sh; do
  name=$(basename "$w" .sh)
  case $name in *"$only"*) ;; *) continue ;; esac
  out=$("$w" 2>&1); rc=$?
  case $rc in
    0)  printf 'PASS %s\n' "$name"; pass=$((pass + 1)) ;;
    77) printf 'SKIP %s — %s\n' "$name" "$out"; skip=$((skip + 1)) ;;
    *)  printf 'FAIL %s\n' "$name"; printf '%s\n' "$out" | sed 's/^/       /'; fail=$((fail + 1)) ;;
  esac
done

printf '\n%s passed, %s failed, %s skipped\n' "$pass" "$fail" "$skip"
[ "$fail" -eq 0 ] && [ "$skip" -eq 0 ] && [ "$pass" -gt 0 ]
