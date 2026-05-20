# Modes

A "mode" tells the skill *what kind of diff it's reviewing and what the deliverable is*. The rubric (packs + overlays) stays the same across modes — only the surrounding flow changes.

## Available modes

| Mode | When to use | Deliverable |
|------|-------------|-------------|
| **pr** (default) | A pull request exists on GitHub. Input is a URL / `owner/repo#N` / `#N` / bare number. | A polished review draft, optionally posted to GitHub as a review with inline comments. |
| **self-review** | A local branch under active development, no PR (or PR not the focus). | A self-directed punch list. Supports applying fixes inline (`fix B1`) and drafting a commit message. No GitHub posting. |

PR mode is the default and is documented inline in [`../SKILL.md`](../SKILL.md). Self-review is a delta on top of PR mode — see [`self-review.md`](self-review.md) for what changes.

## Mode detection

The skill picks a mode at the start of every invocation:

1. **Explicit flag** — `--pr` / `--self` overrides everything.
2. **Explicit ref** — a PR URL / `owner/repo#N` / bare number → **pr**.
3. **"self-review"-shaped trigger phrases** ("review my branch", "review my changes", "self-review", "review what I've done", "/self-review") → **self-review**.
4. **No ref + current branch has an open PR** → **pr** (look it up via `gh pr view --json number`).
5. **No ref + no PR** → **self-review**.

If detection is ambiguous, announce the chosen mode in one line and proceed — Alex can redirect with `--self` / `--pr`.

## Adding a new mode

Drop a `<mode>.md` here describing the deltas from `pr` mode. Update the detection list above and the layout in `../SKILL.md`. Modes that need a totally different flow (not just deltas) should probably be a separate skill instead.
