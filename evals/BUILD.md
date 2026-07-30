# Building the distributable

The packager and the frontmatter validator are not part of this repository. They
ship with the skill-creator plugin:

```
~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/scripts/
    package_skill.py
    quick_validate.py
```

`package_skill.py` imports `scripts.quick_validate`, so the module form runs from
that skill directory, not from this repository. Paths passed to it are absolute
or relative to that directory.

Package from a clean export, never from the working tree:

```sh
rm -rf /tmp/clean /tmp/dist && mkdir -p /tmp/clean/writing-checkable-code
git -C ~/.claude/skills/writing-checkable-code archive HEAD |
  tar -x -C /tmp/clean/writing-checkable-code
cd ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator
python3 scripts/quick_validate.py /tmp/clean/writing-checkable-code
python3 -m scripts.package_skill /tmp/clean/writing-checkable-code /tmp/dist
```

`quick_validate.py` checks the frontmatter against the spec: `name` kebab-case
and at most 64 characters, `description` at most 1024 and free of angle brackets,
no unexpected top-level keys. `package_skill.py` runs the same validation before
it writes the archive.

A correct build contains exactly these four files:

```
writing-checkable-code/SKILL.md
writing-checkable-code/README.md
writing-checkable-code/references/calibration.md
writing-checkable-code/.gitignore
```

The export step is what keeps that invariant. `package_skill.py` excludes
`__pycache__` and `node_modules` and, at the skill root only, `evals/`. It does
**not** exclude `.git`: packaging a repository directory directly writes the
whole repository — history, objects and remote config — into the `.skill`
archive, over 130 files against these four. `git archive` never emits `.git`, and
also applies `.gitattributes export-ignore`, which drops `evals/` before the
packager's own rule would.
