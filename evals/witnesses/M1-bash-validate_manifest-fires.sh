#!/usr/bin/env bash
# M1 fires on bash/deploy.sh: validate_manifest reaches what fetch_manifest
# produced only through /tmp/manifest.json, a value fetch_manifest neither takes
# nor returns. Every value its signature does give the caller — the url it takes,
# the bytes it returns — makes validate_manifest answer 1; the literal read out of
# its body answers 0.
#
# Second half: naming the value does not clear the row. With MANIFEST_PATH
# declared at the top of the file and a fetch_and_validate wrapper pairing the
# calls, the two signature-written calls still answer 1.
cd "$(dirname "$0")/.." || exit 1
command -v curl >/dev/null 2>&1 || { printf 'curl not installed\n'; exit 77; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
printf '{"version": "1.2.3"}' >"$tmp/served.json"
url="file://$tmp/served.json"

# The fixture writes /tmp/manifest.json, so the probe restores whatever was there.
saved=
[ -f /tmp/manifest.json ] && { saved=$tmp/saved; cp /tmp/manifest.json "$saved"; }
restore() {
  if [ -n "$saved" ]; then cp "$saved" /tmp/manifest.json; else rm -f /tmp/manifest.json; fi
  rm -rf "$tmp"
}
trap restore EXIT

rc_of() { ( set +e; "$@" >/dev/null 2>&1; echo $? ); }

probe() {
  local script=$1 lib
  lib=$tmp/lib.sh
  head -n -1 "$script" >"$lib"
  # shellcheck disable=SC1090
  ( set +e
    . "$lib"
    rm -f /tmp/manifest.json
    out=$(fetch_manifest "$url")
    printf 'fetched=%s\n' "$out"
    printf 'url=%s\n' "$(rc_of validate_manifest "$url")"
    printf 'returned=%s\n' "$(rc_of validate_manifest "$out")"
    printf 'body_literal=%s\n' "$(rc_of validate_manifest /tmp/manifest.json)"
  )
}

expect() {
  local label=$1 got=$2 want=$3
  [ "$got" = "$want" ] || {
    printf '%s:\n%s\nexpected:\n%s\n' "$label" "$got" "$want"; exit 1; }
}

expect 'deploy.sh as it stands' "$(probe bash/deploy.sh)" 'fetched={"version": "1.2.3"}
url=1
returned=1
body_literal=0'

# The change that does not clear the row: a name for the value plus a wrapper.
patched=$tmp/patched.sh
sed -e 's|^RETRY_LIMIT=3$|RETRY_LIMIT=3\nMANIFEST_PATH=/tmp/manifest.json|' \
    -e 's|> /tmp/manifest.json 2>/dev/null|> "$MANIFEST_PATH" 2>/dev/null|' \
    -e 's|^  cat /tmp/manifest.json$|  cat "$MANIFEST_PATH"|' \
    -e 's|^  validate_manifest /tmp/manifest.json$|  fetch_and_validate "https://example.test/manifest"|' \
    bash/deploy.sh >"$patched"
awk '/^handle_target\(\) \{$/ && !done {
       print "fetch_and_validate() {";
       print "  fetch_manifest \"$1\" >/dev/null || true";
       print "  validate_manifest \"$MANIFEST_PATH\"";
       print "}"; print ""; done = 1 }
     { print }' "$patched" >"$patched.tmp" && mv "$patched.tmp" "$patched"
bash -n "$patched" || { printf 'the patched fixture does not parse\n'; exit 1; }
grep -q 'MANIFEST_PATH=/tmp/manifest.json' "$patched" &&
  grep -q 'fetch_and_validate()' "$patched" || {
  printf 'the constant-plus-wrapper patch did not apply\n'; exit 1; }

expect 'after MANIFEST_PATH and fetch_and_validate' "$(probe "$patched")" 'fetched={"version": "1.2.3"}
url=1
returned=1
body_literal=0'

# The change that does clear it: fetch_manifest takes the destination and returns it.
fixed=$tmp/fixed.sh
python3 - "$fixed" <<'PY' || { printf 'python3 unavailable for the clearing case\n'; exit 77; }
import sys
src = open("bash/deploy.sh").read()
old = '''fetch_manifest() {
  local url="$1"
  curl -s --max-time 30 "$url" > /tmp/manifest.json 2>/dev/null
  if [ $? -ne 0 ]; then
    return 0
  fi
  cat /tmp/manifest.json
}'''
new = '''fetch_manifest() {
  local url="$1" dest="$2"
  curl -s --max-time 30 "$url" > "$dest" || return 1
  printf '%s\\n' "$dest"
}'''
assert old in src, "fetch_manifest is not the body this witness patches"
open(sys.argv[1], "w").write(src.replace(old, new))
PY
lib=$tmp/fixed-lib.sh; head -n -1 "$fixed" >"$lib"
cleared=$( set +e
  # shellcheck disable=SC1090
  . "$lib"
  dest=$(fetch_manifest "$url" "$tmp/caller-owned.json")
  printf 'returned=%s rc=%s\n' "$dest" "$(rc_of validate_manifest "$dest")"
)
expect 'after fetch_manifest returns the destination it took' "$cleared" \
  "returned=$tmp/caller-owned.json rc=0"
