#!/usr/bin/env bash
# T3 stays silent on swift/Ledger.swift apply: adding a member to Entry in a copy
# of the fixture breaks the build, which is what makes its switch an exhaustive
# match over a closed sum rather than a dispatch chain.
cd "$(dirname "$0")/.." || exit 1
command -v swiftc >/dev/null 2>&1 || { printf 'swiftc not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp swift/Ledger.swift "$tmp/Ledger.swift"

base=$(swiftc -typecheck "$tmp/Ledger.swift" 2>&1) && [ -z "$base" ] || {
  printf 'the fixture does not typecheck clean, so a later break proves nothing: %s\n' "$base"
  exit 1; }

marker='    case deleted(id: String)'
found=$(grep -cxF "$marker" "$tmp/Ledger.swift")
[ "$found" = 1 ] || {
  printf 'expected exactly one Entry member line "%s", found %s\n' "$marker" "$found"; exit 1; }
awk -v m="$marker" '{ print } $0 == m { print "    case reversed(id: String)" }' \
  "$tmp/Ledger.swift" >"$tmp/Extended.swift"

extended=$(swiftc -typecheck "$tmp/Extended.swift" 2>&1); rc=$?
[ "$rc" != 0 ] || {
  printf 'adding Entry.reversed still typechecks; apply is not an exhaustive match, so T3 has no exemption to be silent under\n'
  exit 1; }
case $extended in
  *'switch must be exhaustive'*) ;;
  *) printf 'adding Entry.reversed failed the build for another reason: %s\n' "$extended"; exit 1 ;;
esac
