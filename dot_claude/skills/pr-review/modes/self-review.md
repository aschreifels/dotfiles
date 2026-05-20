# Mode — self-review

A delta on top of the PR-review flow in [`../SKILL.md`](../SKILL.md). Everything not mentioned here is identical to PR mode.

The audience for the rendered review is **Alex himself, mid-flight**. The voice is notes-to-self, not comments-to-author. Fixes are something the skill can *apply*, not just suggest.

---

## When this mode runs

Mode is selected per the detection list in [`README.md`](README.md). Typical triggers:

- "review my branch", "review my changes", "self-review", "review what I've done"
- `--self` flag
- No PR ref provided and the current branch has no open PR

---

## Phase deltas

### 1. Parse — additional flags

In addition to the PR-mode invocation forms, self-review accepts:

- `--committed` (default) — review committed work on the branch: `git diff <base>...HEAD`
- `--uncommitted` — review only working-tree changes: `git diff HEAD`
- `--staged` — review only the staging area: `git diff --cached`
- `--all` — committed + working-tree: `git diff <base>` (no `...`)
- `--base <ref>` — override the base branch (default is the repo's default branch, then `master`, then `main`)

Honor natural-language equivalents: "self-review including my unstaged changes" → `--all`. If ambiguous, announce the chosen scope ("Scope: committed work since master") and continue.

### 2. Fetch — local sources only

Skip every `gh` call. Replace with:

- Base branch resolution:
  1. `gh repo view --json defaultBranchRef` if `gh` is available, else
  2. Check for `master` → `main` → first remote head from `git remote show origin`.
  3. The user-passed `--base` always wins.
- Divergence point: `git merge-base HEAD <base>`.
- Diff: per scope flag above.
- File list: `git diff --name-only <scope>`.
- Branch metadata: `git rev-parse --abbrev-ref HEAD` for the branch name, `git log <base>..HEAD --oneline` for commit context.
- Linked ticket (best effort): parse the branch name (Alex's convention is `as/TICKET-ID_…`) — if there's a Linear MCP available, fetch the ticket for context. Otherwise skip silently.
- Existing review comments — N/A, skip.
- `AGENTS.md` / `CLAUDE.md` — same as PR mode (root + per-directory of changed files).

If `git status --porcelain` shows uncommitted changes and the user did NOT pick a scope flag, surface it once before analysis:

```
Working tree has uncommitted changes (N files). Default scope is committed work only.
Add --all / --uncommitted to include them, or proceed as-is.
```

Don't block — proceed with the default scope after surfacing.

### 3. Detect-langs, route — unchanged

Same detection table, same loading rules. Overlays still apply (the repo is the same).

### 4. Analyze — unchanged

Same sub-agent fan-out. The agents don't know the difference between PR and self-review mode — they only see the diff and the rubric.

### 5. Present — voice and format shift

Write to `.claude-review/branch-<branch-slug>.md` (not `PR-<num>.md`).

Format:

```markdown
# Branch self-review — `<branch>`

<one paragraph: what the branch is doing, scope, where you are in the work>

**Status:** <Ship-ready | Needs work | Don't ship yet | Early — too soon to tell>
**Scope:** committed work since <base>  (N commits, +X / -Y)
**Routing:** <packs loaded · overlay>
**Findings:** B:<n>  H:<n>  M:<n>  L:<n>  Q:<n>

---

## Blockers (B) — fix before this is ready

### B1 — <title>
- **File:** `path/to/file.ts:42-58`
- **Pack:** db (overlay: curri)
- **Confidence:** 92
- **Why it matters:** <one or two sentences — direct, second-person>
- **Evidence:**
  ```ts
  <minimal snippet>
  ```
- **Fix:** <concrete one-liner or short suggested diff>

### B2 — ...
```

Field renames vs PR mode:

| PR mode | Self-review mode |
|---------|------------------|
| Verdict: Block / Request changes / Approve | Status: Ship-ready / Needs work / Don't ship yet / Early |
| "Why it blocks" | "Why it matters" |
| "Suggested fix" | "Fix" |

Voice rules:

- Second person. "You have an N+1 here" beats "this PR introduces an N+1."
- No throat-clearing, no citations-for-the-author. Citations to AGENTS.md / overlays are still useful for *yourself* — keep them.
- Same severity tiers, same IDs (`B1, H1, M1, …`), same stability rules.

### 6. Iterate — same grammar, plus `fix` and `commit`

All existing commands work: `drop B2`, `drop all L`, `keep only B`, `restore H2`, `edit H2: …`, `expand M1`, `merge B2 into B1`, `add a finding: …`, `re-scan`.

**New commands in self-review mode:**

| Command | Effect |
|---------|--------|
| `fix B1` | Propose the concrete Edit (read the file, write the new content, show a diff). Ask "apply? (yes / edit / skip)". On `yes`, apply via Edit, then mark B1 as `fixed`. Do NOT re-scan automatically — Alex re-runs `re-scan` when ready. |
| `fix all B` | Bulk-fix Blockers. One preview per fix, with a "apply all / apply this / skip / cancel" prompt at each step (and a "apply remaining without prompting" escape hatch). |
| `fix all H` / `fix all M` etc. | Same for other severities. |
| `commit` | Draft a commit message from `git diff <base>...HEAD`. Show the message, ask "commit? (yes / edit / cancel)". Use Alex's commit conventions (no force, no amend of pushed, concise summary). Do NOT push. |

**Commands NOT available in self-review mode:**

- `post`, `preview post`, `approve`, `request changes` — there's no PR to post to. If Alex asks, respond: "self-review mode — no PR target. Open a PR first, or switch with `--pr <ref>`."

### 7. Re-scan — preserve state across edits

Re-scan is especially relevant in self-review (Alex fixes and re-runs).

- Re-fetch the diff from the same scope.
- Re-run sub-agents.
- For each pre-existing finding, check if its `file:lines` evidence is unchanged. If so, preserve its ID and status (active / dismissed / fixed). If changed (line moved, evidence rewritten), re-evaluate from scratch with a new ID.
- New findings get fresh IDs in their severity (never reuse).
- After re-scan, surface the delta:

```
Re-scan:  +2 new (H4, M3)   -3 fixed (B1, H1, M1)   -1 dismissed earlier (L2)
B:0  H:3  M:2  L:1  Q:0
```

### 8. No post phase

Self-review ends when Alex either:

- `commit`s — the skill drafts and (with confirmation) commits.
- Says "done" / "ship it" / similar — the skill confirms there are no remaining active Blockers and exits.
- Walks away — the `.claude-review/branch-<branch-slug>.md` file persists; next invocation can pick up where it left off if Alex asks.

---

## Behavioural rules (overrides)

- **Don't auto-fix.** Even on `fix B1`, show the diff and wait for "yes" before calling Edit.
- **Don't commit unprompted.** `commit` is a verb Alex types.
- **Don't push.** Ever. Per CONVENTIONS.
- **Don't run tests / lint / build during analysis.** The skill is a reading pass, not a verification pass. Alex runs his own `rush lint:fix` / `rushx build` / tests.
- **Working-tree state is information.** If `git status` shows untracked files that look like the work-in-progress (new component file, new test) — mention them in the summary even if they're outside the diff scope. Don't analyze them; just note their existence so Alex can decide whether to widen scope.

---

## Voice contrast — same finding, two modes

PR mode (posted to GitHub, author is someone else):

> **Why it blocks:** This is an N+1 — the `findMany` inside the loop hits the DB once per user, which on this code path scales with team size. `agent_docs/08-review-rules.md` § "N+1 Queries" requires batching.
>
> **Suggested fix:** Move to a single `findMany({ where: { userId: { in: userIds } } })` and group results in memory.

Self-review mode (notes to yourself):

> **Why it matters:** You're hitting the DB once per user in the loop at L42 — that scales with team size and there's a team with 800+ members. Curri "N+1 Queries" rule.
>
> **Fix:** Batch with `findMany({ where: { userId: { in: userIds } } })`, then group in memory.
