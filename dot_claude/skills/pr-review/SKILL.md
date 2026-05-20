---
name: pr-review
description: Collaborative, in-depth pull request review. Fetches a PR (by URL, `owner/repo#N`, `#N`, or current branch), routes to domain-specific rubric packs (db, api, ui, tests) plus always-on packs (security, correctness, conventions, maintainability, performance), applies any matching repo overlay (e.g., Curri's blocking rules), and presents findings grouped by severity with stable numeric IDs so Alex can quickly drop, keep, edit, or expand specific comments before anything is posted. Use this skill whenever Alex says "review this PR", "review PR <url>", "/pr-review", "code review this branch", or otherwise asks for a structured pre-post review pass on a pull request. Never post comments to GitHub without explicit confirmation.
---

# pr-review

A two-phase, human-in-the-loop PR review:

1. **Analyze** — fetch the PR, route to the rubric packs and overlays that apply, run focused sub-agents, dedupe.
2. **Iterate** — present findings as a numbered, severity-grouped list. Alex drops / keeps / edits / expands.
3. **Optionally post** — only on explicit confirmation, with a final preview step.

The default posture is *do not post*. Posting is a separate, explicit step. Treat this skill as a sparring partner that produces a polished review draft, not an autonomous commenter.

---

## Repo layout

```
~/.claude/skills/pr-review/
  SKILL.md                  ← you are here
  rubric/
    _core.md                ← severity, confidence, false positives, voice (always loaded)
    security/               ← always-on, language-split
      _shared.md            ← language-agnostic security rules
      ts.md                 ← TS/JS/Node-specific
      # py.md, go.md, ... drop a file in to add a language
    correctness/            ← always-on, language-split
      _shared.md
      ts.md
    performance/            ← always-on, language-split (non-DB)
      _shared.md
      ts.md
    tests/                  ← gated, language-split
      _shared.md
      ts.md
    conventions.md          ← always-on, language-agnostic
    maintainability.md      ← always-on, language-agnostic
    db.md                   ← gated: SQL / Prisma / migrations
    api.md                  ← gated: backend handlers / services
    ui.md                   ← gated: React / .tsx
  overlays/
    README.md               ← how overlays work
    curri.md                ← Curri (teamcurri/curri) blocking rules
```

Add a new repo's rules by creating a file in `overlays/`. See [overlays/README.md](overlays/README.md). Add a new language slice by dropping a `<lang>.md` into any language-split pack — no registration needed.

---

## Phases

```
parse → fetch → detect-langs → route → analyze → present → iterate ⇄ refine → (optional) preview → post
                                                            ↑              |
                                                            └──────────────┘
```

### 1. Parse the invocation

Accept any of:

- Full PR URL: `https://github.com/teamcurri/curri/pull/21473`
- Shorthand: `teamcurri/curri#21473`
- Repo-relative: `#21473` (assumes current repo via `gh repo view`)
- Bare number: `21473` (same as `#21473`)
- No argument → review the current branch's diff against `master` (local-branch mode).

If no arg and the current branch has an open PR, look it up via `gh pr view --json number,url,title,headRefName`.

If the ref can't be resolved unambiguously, ask once for clarification.

### 2. Fetch context

In parallel:

- PR metadata: `gh pr view <ref> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,labels,isDraft,state,reviews,headRefOid,nameWithOwner`
- Full diff: `gh pr diff <ref>` (capture the unified diff — needed for line-anchored inline comments later)
- File list with stats: `gh pr view <ref> --json files`
- Existing review comments: `gh api repos/<owner>/<repo>/pulls/<n>/comments` + top-level review bodies (avoid duplicating other reviewers)
- Linked ticket if the PR body or branch name references one
- Relevant `AGENTS.md` / `CLAUDE.md`: the root one and any in the directories of changed files

Bail early — and tell Alex — if:

- PR is closed/merged (ask "still review?")
- PR is a draft (note it, continue)
- We've already reviewed this exact head SHA this session (offer to skim only new commits)

For **local-branch mode**, use `git diff master...HEAD`, `git log master..HEAD --oneline`, and `git remote get-url origin` for the repo slug. Skip the `gh api` calls.

### 3a. Detect languages

Build the set of languages touched by the diff. Source of truth is the changed-file list from `gh pr view --json files` (or `git diff --name-only` in local mode).

| Language | Extensions / paths |
|----------|--------------------|
| `ts` | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs` |
| `py` | `.py`, `.pyi` |
| `go` | `.go` |
| `rb` | `.rb`, `Gemfile`, `*.gemspec` |
| `rs` | `.rs`, `Cargo.toml` |
| `java` | `.java`, `.kt`, `.kts`, `.gradle` |
| `sql` | `.sql` (also triggers the `db` pack) |
| `sh` | `.sh`, `.bash`, `.zsh` |

A PR can touch multiple languages — load every matching slice. Ignore extensions that aren't security/correctness/perf-relevant (`.md`, `.json`, `.yaml`, `.lock`, generated files).

**Adding a new language:** drop a `<lang>.md` into the relevant language-split pack and add the row above. Nothing else to register.

### 3b. Route — pick packs, slices, and overlays

Always load (language-agnostic):

- [rubric/_core.md](rubric/_core.md)
- [rubric/conventions.md](rubric/conventions.md)
- [rubric/maintainability.md](rubric/maintainability.md)

Always load (language-split — `_shared.md` + slices for each detected language):

- [rubric/security/](rubric/security/) → `_shared.md` + every `<lang>.md` for `<lang>` in the detected set, **if the slice exists**
- [rubric/correctness/](rubric/correctness/) → same composition rule
- [rubric/performance/](rubric/performance/) → same composition rule

If a language slice doesn't exist for a detected language, fall back to `_shared.md` for that pack and continue — but mention it in the routing line so Alex knows coverage is partial (e.g., `correctness/py.md missing — _shared only`).

Gated packs — load only if a changed file matches:

| Pack | Triggers |
|------|----------|
| [rubric/db.md](rubric/db.md) | `prisma/`, `*.prisma`, `*.sql`, `*/migrations/*`, files importing a Prisma client, files containing `findMany` / `$queryRaw` / `$executeRaw` |
| [rubric/api.md](rubric/api.md) | `apps/*api*/`, `services/*/src/`, route handlers, GraphQL schemas / resolvers, worker job handlers |
| [rubric/ui.md](rubric/ui.md) | `*.tsx`, `*.jsx`, `apps/*app*/`, `apps/*admin*/`, `mobile/*/`, component packages, CSS / styled-components files |
| [rubric/tests/](rubric/tests/) | `*.test.*`, `*.spec.*`, `__tests__/`, `e2e/`, `cypress/`, `playwright/`, `tests/`, `test/`, **or** the PR is a bug fix. Also language-split — same composition rule. |

Overlays — read every file under `overlays/*.md`, parse `applies_when:`, load any that match the current repo. Predicate semantics:

- `repo: owner/name` — exact match against `nameWithOwner` (case-insensitive)
- `repo_regex: ^pattern$` — regex match
- `file_exists: path/to/marker` — also requires this file to exist in the checkout
- Multiple conditions in one overlay are **AND**-ed.

Echo to Alex the routing decision in one line. Example:

```
Langs: ts · Loaded: core, conventions, maintainability, security{_shared,ts}, correctness{_shared,ts}, performance{_shared,ts}, db, api, ui, tests{_shared,ts} · overlay: curri
```

If multi-language:

```
Langs: ts, py · Loaded: …, security{_shared,ts,py}, correctness{_shared,ts} (py slice missing — _shared only), …
```

### 4. Analyze

Launch parallel sub-agents (`general-purpose` or `Explore`). One sub-agent per loaded **pack** (not per slice — a sub-agent for `security` sees `_shared.md` plus all the loaded language slices for that pack as a single bundle of guidance). Each sub-agent gets:

- The unified diff
- The pack's loaded files concatenated: `_shared.md` first, then each language slice — so the agent reads universal rules then language footguns
- Any overlay sections that augment that pack
- The list of detected languages (so the agent can scope its scan)
- The relevant `AGENTS.md` / `CLAUDE.md` contents
- Standing instructions: report each finding as `{ category, severity, title, file, lines, evidence_snippet, explanation, suggested_fix, confidence }`

After agents return, the main thread:

1. **Dedupes** near-identical findings from different packs — keep the strongest explanation.
2. **Filters by confidence**: < 50 silently dropped; 50–69 dropped unless Blocker (then kept as a `Q` with uncertainty); ≥ 70 kept.
3. **Sanity-checks every Blocker** by reading the surrounding code yourself. A false-positive Blocker erodes trust faster than a missed Medium.
4. **Scopes to changed lines** — drop findings on lines the PR didn't touch unless they directly govern the change's correctness.

### 5. Present

Write the review to `.claude-review/PR-<num>.md` (or `.claude-review/branch-<branch>.md` in local mode) in the current working directory so Alex reads diffs in Zed. Create the directory if needed. Append `.claude-review/` to `.gitignore` if it isn't already there.

Then output the same content to chat. Format:

```markdown
# PR Review — <title> (#<num>)

<one paragraph: what the PR does, scope, risk profile, headline call>

**Verdict:** <Block | Request changes | Approve with nits | Approve>
**Routing:** <packs loaded · overlay>
**Findings:** B:<n>  H:<n>  M:<n>  L:<n>  Q:<n>

---

## Blockers (B) — must fix before merge

### B1 — <title>
- **File:** `path/to/file.ts:42-58`
- **Pack:** db (overlay: curri)
- **Confidence:** 92
- **Why it blocks:** <one or two sentences citing the rule>
- **Evidence:**
  ```ts
  <minimal snippet from the diff>
  ```
- **Suggested fix:** <one or two sentences, or a small code suggestion>

### B2 — ...

---

## High (H) — should fix before merge
...

## Medium (M) — worth addressing
...

## Low / Nits (L)
...

## Questions (Q) — clarifying with the author
...
```

#### ID rules — memorize these

- IDs are assigned at present-time in scan order within each severity: `B1, B2, B3, …`, `H1, H2, …`, etc.
- **IDs are stable for the life of the session.** Dismissing `H3` does *not* renumber `H4` to `H3`. Renumbering breaks Alex's mental model.
- New findings (from `re-scan` or `add a finding: …`) get the next free number in their severity — never a reused one.

After the listing, show the command footer:

```
Refine with natural language, e.g.
  drop B2, H1, H3
  drop all L
  keep only blockers
  edit H2: <new wording or fix>
  expand M1
  merge B2 into B1
  add a finding: <freeform>
  re-scan          (author pushed new commits)
  preview post     (show exactly what will be sent to GitHub)
  post             (post the current set — will confirm first)
```

### 6. Iterate

Parse Alex's commands liberally — natural language wins:

| Command | Effect |
|---------|--------|
| `drop B2` / `drop B2 H1 H3` / `drop B2, H1, H3` | Mark those findings dismissed |
| `drop all L` / `drop M*` / `drop nits` | Bulk dismiss by severity |
| `keep only B` / `keep only blockers and H` | Invert the dismissal |
| `restore H2` | Undo a dismissal |
| `edit H2: <text>` | Replace H2's body (or just its suggested fix, if obvious). Ask if ambiguous. |
| `expand M1` | Re-read with wider context, deeper rationale, possibly re-rank. Show the diff. |
| `merge B2 into B1` | Fold B2 into B1, keep B1's ID, dismiss B2 |
| `add a finding: <freeform>` | Alex dictates a new one; pick the next ID in the right severity |
| `re-scan` / `refresh` | Re-fetch + re-analyze. Preserve dismissals on findings whose evidence is unchanged. Call out new findings. |

After every iteration command:

- Rewrite `.claude-review/PR-<num>.md` (active findings only; append a "Dismissed" section at the bottom for traceability).
- Echo the delta and current counts: `B:n  H:n  M:n  L:n  Q:n`. Don't re-print the entire listing unless asked.

### 7. Preview post

When Alex says `preview post` or `post`, **do not call `gh` yet**. Render the exact payload first:

```
TARGET: <owner/repo> PR #<num>  (commit <short sha>)
EVENT:  COMMENT   (use APPROVE or REQUEST_CHANGES only on explicit instruction)

REVIEW BODY:
---
<2–4 sentence narrative. Reference counts. No emojis.>

<optional "Notes" section for findings that can't be anchored to a diff line>
---

INLINE COMMENTS (n):

[1] path/to/file.ts:48
    <B1's body, in posted form>

[2] path/to/file.ts:120-124
    <H1's body>

…
```

Construction rules:

- An inline comment is built from a finding whose `file` + `lines` overlap lines actually added/modified in the captured diff. Use `headRefOid` for line refs.
- Findings that can't anchor go into the review body's Notes section.
- Apply [`rubric/_core.md`](rubric/_core.md) § "Voice for posted comments": no emojis, terse, cite the rule, permalink with full SHA.

Ask: "Send this? (yes / edit / cancel)"

### 8. Post

Only after explicit confirmation:

```bash
gh api --method POST repos/<owner>/<repo>/pulls/<n>/reviews --input payload.json
```

Where `payload.json` is:

```json
{
  "commit_id": "<full sha>",
  "body": "<review body>",
  "event": "COMMENT",
  "comments": [
    { "path": "...", "line": 48, "side": "RIGHT", "body": "..." },
    { "path": "...", "start_line": 120, "line": 124, "side": "RIGHT", "body": "..." }
  ]
}
```

- If `gh api` returns 422 on a line anchor (line not in the diff), move that comment into the review body's Notes section and retry once.
- After a successful post, echo the review URL and append `Posted at <ISO timestamp>` to `.claude-review/PR-<num>.md`.
- Never use `--approve` or `event=APPROVE` without an explicit "approve" instruction. Default is `COMMENT`.

---

## Behavioural rules

- **Don't post unprompted.** Even on "looks great, ship it" — confirm "post the review?" before calling `gh`.
- **Don't invent findings.** Short and honest beats padded.
- **Don't re-flag CI-caught issues** (lint, typecheck, formatting, imports, broken tests).
- **Cite the rule.** When invoking an `AGENTS.md` or overlay rule, quote or link it.
- **Confidence threshold matters.** When in doubt about a Blocker, downgrade to High and say what would raise confidence.
- **Respect scope.** Findings on unchanged lines only if they directly govern the change.
- **No emojis in posted text** (chat is fine).
- **Don't open browser / preview tools for UI review** — Alex reviews visually himself. Surface UI findings that aren't obvious from a screenshot (hooks, perf, a11y).

---

## File layout written into the worktree

```
.claude-review/
  PR-<num>.md      (or branch-<branch>.md for local mode)
```

This file is the source of truth for the current state of the review between turns. The chat is for the live conversation; the file is for Zed reading and re-opening sessions.

---

## Adding rules

- **A rule that applies to every repo, every language** — edit the relevant pack's `_shared.md` (for language-split packs) or `<pack>.md` (for flat packs).
- **A rule that applies to every repo, one language** — edit the language slice (`<pack>/<lang>.md`).
- **A rule that applies to one repo** — add or extend an overlay in `overlays/`. See [overlays/README.md](overlays/README.md).
- **A new language** — drop `<lang>.md` into the relevant language-split pack and add the row to the "Detect languages" table above.

After any edit, `chezmoi add ~/.claude/skills/pr-review/...` to persist to dotfiles.
