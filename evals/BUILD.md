# Building the distributable

Package from a clean export, never from the working tree:

```sh
rm -rf /tmp/clean && mkdir -p /tmp/clean/writing-checkable-code
git archive HEAD | tar -x -C /tmp/clean/writing-checkable-code
python -m scripts.package_skill /tmp/clean/writing-checkable-code /tmp/dist
```

`package_skill.py` excludes `__pycache__` and `node_modules` and, at the skill
root only, `evals/`. It does **not** exclude `.git`, so packaging this directory
directly writes the whole repository — history, objects and remote config — into
the `.skill` archive: 134 files and 154 KB, against 4 files and 15 KB from a
clean export.

`git archive` also applies `.gitattributes export-ignore`, so `evals/` is dropped
before the packager runs and again by the packager's own rule.

A correct build contains exactly:

```
writing-checkable-code/SKILL.md
writing-checkable-code/README.md
writing-checkable-code/references/calibration.md
writing-checkable-code/.gitignore
```

Validate before packaging — `scripts/quick_validate.py` checks the frontmatter
against the spec: `name` kebab-case and at most 64 characters, `description` at
most 1024 and free of angle brackets, no unexpected top-level keys.
