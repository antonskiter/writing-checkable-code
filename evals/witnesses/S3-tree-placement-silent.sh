#!/usr/bin/env bash
# S3 returns no finding about any file under review: in python/, go/ and files/
# every unit takes a level number and no dependency cycle exists, and no layer map
# is declared anywhere in the repository, so nothing can be above its declared
# layer. What remains — placement unverified — is one verdict about the
# repository that holds for all 11 files alike, not a finding about any of them.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# 0. An absence is only evidence if the probe can find a map that is there: the
# same pattern must match an import-linter contract.
maps='importlinter|import-linter|import_linter|layeredArchitecture|ArchTest|depguard|no-restricted-paths|no-restricted-imports|allowed_layers|layers *=|= *layers'
printf '[importlinter:contract:1]\ntype = layers\nlayers =\n    handler\n    store\n' \
  >"$tmp/contract.toml"
grep -qniE "$maps" "$tmp/contract.toml" || {
  printf 'the probe does not recognise a declared layer map, so its silence proves nothing\n'
  exit 1; }

# 1. The artifact the row needs is absent: no declared layer map in any form the
# tree could carry one — an import-linter or tach contract, an ArchUnit layered
# rule, a depguard or eslint path restriction, a checked-in layer list.
map=$(grep -rniE "$maps" .. \
  --exclude-dir=.git --exclude-dir=__pycache__ --exclude-dir=.ruff_cache \
  --exclude-dir=witnesses \
  --include='*.toml' --include='*.cfg' --include='*.ini' --include='*.yml' \
  --include='*.yaml' --include='*.json' --include='*.mjs' --include='*.sh' \
  --include='*.mod' --include='*.gradle' --include='*.java' --include='*.kt')
[ -z "$map" ] || {
  printf 'a layer map is declared after all, so the row can place units:\n%s\n' "$map"
  exit 1; }
listfile=$(find .. -name '.git' -prune -o \( -iname 'layers*' -o -iname 'LAYERS*' \
  -o -iname '*.importlinter' -o -iname 'tach.toml' \) -print)
[ -z "$listfile" ] || {
  printf 'the repository carries a layer list this witness did not read:\n%s\n' "$listfile"
  exit 1; }

# 2. Number every unit in each tree, one above the highest unit it uses. A unit in
# a cycle takes no number, and that is the finding the row does return per file.
out=$(python3 - <<'RUN' 2>&1
import ast
import os
import re
import sys


def python_edges(directory):
    units = sorted(f for f in os.listdir(directory) if f.endswith(".py"))
    names = {f[:-3]: f for f in units}
    uses = {f: set() for f in units}
    for f in units:
        tree = ast.parse(open(os.path.join(directory, f)).read())
        for node in ast.walk(tree):
            mods = []
            if isinstance(node, ast.Import):
                mods = [a.name.split(".")[0] for a in node.names]
            elif isinstance(node, ast.ImportFrom) and node.module:
                mods = [node.module.split(".")[0]]
            for m in mods:
                if m in names and names[m] != f:
                    uses[f].add(names[m])
    return uses


DECL = re.compile(
    r"^(?:func\s+(?:\([^)]*\)\s*)?(\w+)|type\s+(\w+)|var\s+(\w+)|const\s+(\w+))")


def declared(body):
    names = set()
    for line in body.splitlines():
        found = DECL.match(line)
        if found:
            names.update(g for g in found.groups() if g)
    return names


def go_edges(directory):
    units = sorted(f for f in os.listdir(directory) if f.endswith(".go"))
    declares, text = {}, {}
    for f in units:
        body = open(os.path.join(directory, f)).read()
        text[f] = body
        declares[f] = declared(body)
    uses = {f: set() for f in units}
    for f in units:
        for other in units:
            if other == f:
                continue
            for name in declares[other] - declares[f]:
                if re.search(r"\b%s\b" % re.escape(name), text[f]):
                    uses[f].add(other)
                    break
    return uses


def number(uses):
    level, visiting = {}, set()

    def walk(unit):
        if unit in level:
            return level[unit]
        if unit in visiting:
            raise ValueError("cycle reaching %s" % unit)
        visiting.add(unit)
        below = [walk(u) for u in sorted(uses[unit])]
        visiting.discard(unit)
        level[unit] = 1 + max(below, default=0)
        return level[unit]

    for unit in sorted(uses):
        walk(unit)
    return level


total = 0
for directory, edges in (("python", python_edges), ("go", go_edges),
                         ("files", python_edges)):
    uses = edges(directory)
    try:
        level = number(uses)
    except ValueError as exc:
        print("%s: %s" % (directory, exc))
        sys.exit(1)
    unnumbered = [u for u in uses if u not in level]
    if unnumbered:
        print("%s: unnumbered %s" % (directory, unnumbered))
        sys.exit(1)
    total += len(level)
    print("%s: %s" % (directory,
                      ", ".join("%s=%d" % (u, level[u]) for u in sorted(level))))
print("units numbered: %d" % total)
RUN
)
rc=$?
printf '%s\n' "$out"
[ $rc -eq 0 ] || { printf 'a tree did not number, so S3 has a per-file finding\n'; exit 1; }

units=$(printf '%s\n' "$out" | sed -n 's/^units numbered: //p')
[ "$units" = 11 ] || {
  printf 'the trees hold %s units, not the 11 this witness numbers\n' "$units"; exit 1; }

# 3. What the row returns, per file and for the repository.
printf 'layer map declared in the tree: none\n'
printf 'S3 findings about a reviewed file: 0 — no cycle, every unit numbered\n'
printf 'S3 findings about the repository: 1 — placement unverified over %s units in 3 trees\n' \
  "$units"
