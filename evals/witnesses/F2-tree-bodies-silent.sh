#!/usr/bin/env bash
# F2 returns no finding about any file under review: no complexity checker is
# configured anywhere in this repository, so nothing measured any body, and the
# absent checker is one verdict about the build. Executed here by installing a
# McCabe gate at 10 for the run — python/report.py, python/ingest.py,
# files/shipping.py and go/ all pass it, so the finding separates none of them,
# which is what makes it the build's rather than any file's.
cd "$(dirname "$0")/.." || exit 1
command -v ruff >/dev/null 2>&1 || { printf 'ruff not installed\n'; exit 77; }
command -v go >/dev/null 2>&1 || { printf 'go not installed\n'; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
export GO111MODULE=off

# 1. The artifact the row needs is absent from the whole tree the build reads:
# no gate in a build file, a linter configuration or a CI workflow. witnesses/ is
# excluded because a gate this script installs for one run is not in the build.
gate=$(grep -rniE 'max-complexity|mccabe|C901|gocyclo|cyclomatic' .. \
  --exclude-dir=.git --exclude-dir=__pycache__ --exclude-dir=.ruff_cache \
  --exclude-dir=witnesses \
  --include='*.toml' --include='*.cfg' --include='*.ini' --include='*.yml' \
  --include='*.yaml' --include='*.json' --include='*.mjs' --include='*.sh' \
  --include='*.mod' --include='*.gradle' --include='Makefile')
[ -z "$gate" ] || {
  printf 'a complexity gate is configured after all, so the row measures bodies:\n%s\n' \
    "$gate"; exit 1; }
ci=$(find .. -name '.git' -prune -o \( -name '.github' -o -name '.gitlab-ci.yml' \
  -o -name 'Makefile' -o -name 'tox.ini' -o -name '.pre-commit-config.yaml' \) -print)
[ -z "$ci" ] || {
  printf 'the build has configuration this witness did not read:\n%s\n' "$ci"; exit 1; }

# 2. Install a gate at McCabe 10 and run it over three of the trees. A pass here
# is only evidence if the gate can fail, so the same gate at 1 must report.
python_files='python/report.py python/ingest.py files/shipping.py files/render.py files/discount.py'
# shellcheck disable=SC2086  # the list is a fixed set of paths, split on purpose
at10=$(ruff check --no-cache --isolated --select C901 \
  --config 'lint.mccabe.max-complexity=10' --output-format concise $python_files 2>&1)
# shellcheck disable=SC2086
at1=$(ruff check --no-cache --isolated --select C901 \
  --config 'lint.mccabe.max-complexity=1' --output-format concise $python_files 2>&1)
overbudget=$(printf '%s\n' "$at10" | grep -c 'C901' || true)
control=$(printf '%s\n' "$at1" | grep -c 'C901' || true)
[ "$control" -gt 0 ] || {
  printf 'the installed gate reported nothing even at 1, so it did not run:\n%s\n' "$at1"
  exit 1; }
[ "$overbudget" -eq 0 ] || {
  printf 'a python body is over budget, so F2 does have a per-body finding:\n%s\n' "$at10"
  exit 1; }

# The go tree has no gate available either; install one, as gocyclo does, by
# counting decision points per function over go/ast.
cat >"$tmp/mccabe.go" <<'GOTOOL'
package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
)

func main() {
	fset := token.NewFileSet()
	for _, path := range os.Args[1:] {
		f, err := parser.ParseFile(fset, path, nil, 0)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		for _, d := range f.Decls {
			fn, ok := d.(*ast.FuncDecl)
			if !ok || fn.Body == nil {
				continue
			}
			c := 1
			ast.Inspect(fn.Body, func(n ast.Node) bool {
				switch x := n.(type) {
				case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.CaseClause, *ast.CommClause:
					c++
				case *ast.BinaryExpr:
					if x.Op == token.LAND || x.Op == token.LOR {
						c++
					}
				}
				return true
			})
			fmt.Printf("%d %s %s\n", c, path, fn.Name.Name)
		}
	}
}
GOTOOL
(cd "$tmp" && go build -o mccabe mccabe.go) || {
  printf 'the go gate did not build\n'; exit 1; }
measured=$("$tmp/mccabe" go/store.go go/handler.go) || {
  printf 'the go gate did not run\n'; exit 1; }
bodies=$(printf '%s\n' "$measured" | grep -c '')
worst=$(printf '%s\n' "$measured" | sort -rn | head -1)
[ "$bodies" -gt 0 ] || { printf 'the go gate measured no body\n'; exit 1; }
[ "$(printf '%s' "$worst" | cut -d' ' -f1)" -le 10 ] || {
  printf 'a go body is over budget: %s\n' "$worst"; exit 1; }

# 3. What the row returns, per file and for the repository. The per-file count is
# what the reporting rule removes; the repository count is the information kept.
per_file=$overbudget
repository=1
printf 'gate configured in the tree: none\n'
printf 'installed at 10: %s python findings, %s go bodies measured, worst %s\n' \
  "$overbudget" "$bodies" "$(printf '%s' "$worst" | cut -d' ' -f1)"
printf 'installed at 1 (control): %s findings\n' "$control"
printf 'F2 findings about a reviewed file: %s\n' "$per_file"
printf 'F2 findings about the repository: %s — the absent complexity checker\n' "$repository"
[ "$per_file" -eq 0 ] && [ "$repository" -eq 1 ]
