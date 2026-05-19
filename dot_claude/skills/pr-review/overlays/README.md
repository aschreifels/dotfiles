# Overlays

Overlays inject **repo-specific** rules on top of the universal packs in `rubric/`. They let you encode "in *this* codebase, X is a Blocker" without polluting the generic rubric.

## How overlays are loaded

At review time, the skill:

1. Resolves the current repo (`gh repo view --json nameWithOwner` for a PR, or `git remote get-url origin` parsed for the local-branch case).
2. Reads every `*.md` file in this directory, parses the frontmatter `applies_when:` predicate.
3. Loads any overlay whose predicate matches the current repo.
4. Hands the overlay's rule sections to the relevant sub-agents alongside the base pack.

If no overlay matches, only the universal packs run — the skill still works fine, just without local flavour.

## Overlay file format

```markdown
---
name: my-repo
description: One-line summary of what this overlay adds.
applies_when:
  # any of the following may be set; ALL set conditions must match
  repo: owner/name              # exact GitHub slug match (case-insensitive)
  repo_regex: ^owner/.*$        # alternative — regex match
  file_exists: path/to/marker   # also requires this file to exist in the checkout
---

# Overlay body follows the same structure as a rubric pack:
# - "Blockers" / "High" / "Medium" sections, severity-prefixed
# - Explicit "augments:" pointers naming which packs this overlay adds to
# - A "Do NOT flag" section if needed
# - Examples and citations to in-repo rule files
```

## Authoring tips

- **Cite, don't paraphrase.** Each overlay rule should link to the in-repo doc (e.g., `agent_docs/08-review-rules.md`). The overlay file is a *pointer*, not a duplicate.
- **Augment, don't replace.** If your repo has a stricter version of a universal rule, write the stricter version in the overlay and reference the universal pack — don't disable the universal rule entirely.
- **Keep it short.** Overlays should be 50–200 lines. Long policy docs belong in the repo itself; the overlay just tells the reviewer where to look and what to insist on.
- **One overlay per repo (usually).** If you have a multi-repo policy (e.g., "all my company repos require EXPLAIN ANALYZE"), it's fine to use `repo_regex:` and a single overlay.

## Example overlays

- [`curri.md`](curri.md) — the Curri monorepo (`teamcurri/curri`). Pinned rules for Prisma scoping, JWT types, dangerous migrations, secret patterns.

## Adding a new overlay

1. Copy `curri.md` as a starting skeleton.
2. Change `name`, `description`, and `applies_when` in the frontmatter.
3. Replace the rule sections with the rules that matter for your repo.
4. Save. The skill picks it up on the next invocation — no registration needed.
5. `chezmoi add ~/.claude/skills/pr-review/overlays/<your-overlay>.md` to persist it.
