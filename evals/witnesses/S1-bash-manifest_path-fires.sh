#!/usr/bin/env bash
# S1 fires on bash/deploy.sh: the manifest path is one fact in three homes — the redirect
# fetch_manifest writes, the cat that reads it back, and the argument run validates.
# Executed: the three moved together keep the run passing; the redirect moved alone breaks
# it, because the other two still state the old path.
cd "$(dirname "$0")/.." || exit 1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

homes=$(grep -c '/tmp/manifest\.json' bash/deploy.sh)
[ "$homes" = 3 ] || {
  printf 'the path is stated in %s place(s), not three: the fact may now have one home\n' "$homes"
  exit 1; }

# A curl that answers with a manifest, so the run reaches the deploy.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '{"version":"1.0"}\n'
EOF
chmod +x "$tmp/bin/curl"

# All three homes moved together, out of /tmp, so the run cannot read a stale file.
sed "s|/tmp/manifest\.json|$tmp/manifest.json|g" bash/deploy.sh >"$tmp/together.sh"
# The redirect alone moved: the write lands elsewhere, the read and the validation do not.
awk -v new="$tmp/other.json" '
  /curl -s --max-time/ { sub(/[^ ]*manifest\.json/, new) } { print }
' "$tmp/together.sh" >"$tmp/one.sh"

[ "$(grep -c "$tmp/manifest\.json" "$tmp/one.sh")" = 2 ] || {
  printf 'moving the redirect alone did not leave two homes stating the old path\n'; exit 1; }

rm -f "$tmp/manifest.json" "$tmp/other.json"
together=$(PATH="$tmp/bin:$PATH" bash "$tmp/together.sh" staging 2>&1); rc=$?
[ "$rc" = 0 ] && [ "$together" = '{"version":"1.0"}
deploy: ok' ] || {
  printf 'the three homes moved together did not deploy (exit %s):\n%s\n' "$rc" "$together"; exit 1; }

rm -f "$tmp/manifest.json" "$tmp/other.json"
one=$(PATH="$tmp/bin:$PATH" bash "$tmp/one.sh" staging 2>&1); rc=$?
[ "$rc" != 0 ] || {
  printf 'moving the redirect alone still deployed, so the other two are not second homes:\n%s\n' \
    "$one"; exit 1; }
case $one in
  *"$tmp/manifest.json: No such file or directory"*) ;;
  *) printf 'the run broke without naming the path the other homes still state:\n%s\n' "$one"; exit 1 ;;
esac
