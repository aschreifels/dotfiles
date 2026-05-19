# Rubric — Conventions (always-on)

Project / repo rule adherence. Runs on every PR. Overlays inject repo-specific rules (e.g., Curri's "no direct Prisma outside `@curri/db`").

---

## How to apply

1. The skill must have already fetched the root `AGENTS.md` / `CLAUDE.md` and any per-directory ones for the changed files.
2. When you cite a rule, **quote the relevant line and link the file**. Don't paraphrase — the author should be able to click through to the rule.
3. If a rule exists in `AGENTS.md` but the code has a deliberate exception (`// ts-expect-error: …`, `// codeowner approved: …`), don't flag.

---

## Generic patterns to watch for (no overlay needed)

### Log-level misuse

`error` for normal business outcomes is wrong. Use `warn` for expected-but-notable events ("no results found", "skipping disabled feature"), `error` only for actual failures.

### Rule-of-3 duplication

If the same logic appears in **three** places, it's time to extract. Flag the third occurrence as `M` with a pointer to the other two. Don't flag the second occurrence — twice is fine.

### Scope creep / unrelated refactor

If the PR's stated purpose is "fix bug X" but the diff also renames variables, restructures a file, or upgrades a dependency unrelated to X — flag the unrelated changes. Alex's CONVENTIONS: "Be surgical in existing codebases."

### Comment rot

A comment that contradicts the code it sits next to. Flag as `M` with a one-line suggestion.

### Backwards-compat shims that aren't needed

Renamed `_unused` vars, re-exported types kept "for compatibility", `// removed: …` placeholders. Alex's CONVENTIONS: "Avoid backwards-compatibility hacks." Flag deletions of this scaffolding *positively* — i.e., don't object to its removal.

### File / project-name violations

If the repo has a naming scheme for projects (e.g., `@curri/`), flag new packages or imports that don't follow it.

### Branch / commit hygiene

These aren't post-worthy findings, but if the PR title or branch name diverges sharply from convention, mention it in the review summary (not as a numbered finding).

---

## Do NOT flag

- Style preferences not in any `AGENTS.md` / `CLAUDE.md`.
- A pattern the codebase uses inconsistently — pick the dominant pattern, but don't flag for the minority unless a rule explicitly mandates the dominant one.
- A `TODO` / `FIXME` comment the author added with context — that's already self-aware.
- Linter-enforceable rules (let lint do it).

---

## Voice

When citing a rule:

> `agent_docs/08-review-rules.md` § "Direct Prisma Client Usage Outside `@curri/db`" — all database access must go through `@curri/db`.

Not:

> You should always use `@curri/db` for database access.
