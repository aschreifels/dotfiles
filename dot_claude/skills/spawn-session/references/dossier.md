# The _plan/ dossier

Layout and templates for the session dossier. The dossier replaces the old single
PLAN.md: it is the canonical planning artifact, the review surface the user opens in
their own tools, and the raw material the wrap-session harvest promotes into the KB.

**Physical layout:** the dossier's real home is `${dossier_dir:-~/dossiers}/<repo>/<worktree-name>/`,
symlinked into the worktree as `_plan` (see SKILL.md Phase 4). Everything addresses it
as `_plan/` from the worktree root; the central home exists so dossier tooling — an
Obsidian vault rooted at the dossier dir, Bases, CLI scans — indexes only dossiers,
never worktree code. Never committed — the `_plan` symlink is excluded via the main
repo's `info/exclude`.

```
_plan/
  MANIFEST.md                 # living index — the ONLY file that gets edited in place
  plans/
    001-initial.md            # frozen snapshots — new file per revision, never edited
    002-post-review.md
  adr/
    001-<kebab-title>.md      # one pattern / structural decision per doc
  contracts/
    <seam-name>.md            # one seam per doc
  chunks/
    01-brief.md               # written by the orchestrator (Phase 6)
    01-report.md              # written by the executor
  handoff/
    wrap.md                   # close-out summary; harvest input for wrap-session
```

Editing rules:

- **`MANIFEST.md`** is living state — edit freely, keep in lockstep with TodoWrite.
- **`plans/`** is append-only. A revision = a new numbered file. The user reviews plans
  as whole documents, not as edits to a previous one. **One sanctioned in-place edit:**
  answers to open questions get inlined below their question in the *current* snapshot
  (by the user directly, or by the session relaying a chat answer) — answering resolves
  a plan, it doesn't revise it. Only a scope-changing answer triggers a new version.
- **`adr/` and `contracts/`** may be amended during planning; once execution starts they
  only change through the orchestrator (a contract amendment is a deliberate act that
  pauses dependent chunks — never a drive-by edit).
- The user may edit any dossier file directly from their own editor. When told to
  "re-read the dossier", diff against what you last wrote and fold the deltas in.
- **Dossier-internal cross-references are always relative markdown links, never plain
  text.** Every mention of another dossier doc — a plan's `Supersedes:` line, the chunk
  map's Refs column (`[adr/001](adr/001-….md)`), MANIFEST's Documents section, a brief's
  pointers — is a real relative link. Obsidian (and editors) resolve these into
  backlinks and the graph for free; plain-text mentions produce nothing. Do **not** use
  `[[wikilinks]]` in the dossier: every session has a `MANIFEST.md` and a
  `001-initial.md`, so filename-based resolution is ambiguous across worktrees in a
  shared vault — relative paths are unambiguous everywhere. (Exception: executor briefs
  keep absolute worktree paths in their "Held to" section — executor correctness beats
  graph aesthetics.)
- **Code refs are clickable links, everywhere.** Any dossier doc that mentions code
  (open questions, ADR context, contract landing sites, chunk scopes) links it as
  `[<repo-rel-path>:<line>](<path relative to the doc>)` — e.g. from
  `plans/001-initial.md`: `[users.ts:42](../../packages/api/src/users.ts:42)`. The
  visible text stays repo-relative for readability; the target resolves from the
  doc's own location so it's click-to-jump in Zed/editors and in chat. Never a bare
  "in the delivery resolver" — name the file and line.
- **Flavors adapt rendering to the user's review tool.** When `[review] flavor` is
  set in spawn.toml, also apply the matching section of `references/flavors.md`
  (callouts, inline code embeds, mermaid diagrams, transclusion, chat deep links for
  `obsidian`). Flavors are strictly additive — canonical links, frontmatter, and
  markers always remain.
- **Every dossier doc carries frontmatter.** MANIFEST's block is specified in its
  template below; plans carry `dossier: plan` + `version`; ADRs carry `dossier: adr`
  + `status` + `promotion`; contracts carry `dossier: contract` + `seam`. This is
  core structure, not flavor: dashboards (Obsidian Bases), `yq`-based CLI tooling,
  and the wrap-session harvest all read the same fields.

---

## MANIFEST.md template

The frontmatter is machine-readable session state — keep it current as part of the
write-MANIFEST-first rule (a state transition updates the frontmatter *and* the body).
It's what dashboard tooling queries: an Obsidian **Base** filtering
`dossier = manifest` and `state != wrapped` over a worktrees-rooted vault is a live
board of every session on the machine; `yq`/CLI tools read the same fields.

```markdown
---
dossier: manifest
feature: {feature-name}
ticket: {TICKET-HANDLE or null}
branch: {branch-name}
state: planning   # planning | awaiting-signoff | executing | behavioral | integrating | wrapped
chunks_total: 0
chunks_accepted: 0
questions_open: 0
updated: {YYYY-MM-DD}
---

# {feature-name} — session manifest

**Ticket:** {TICKET-HANDLE or "none"}
**Branch:** {branch-name}
**Worktree:** {absolute worktree path}
**Started:** {YYYY-MM-DD}
**Current plan:** plans/{NNN-current}.md

## Chunk map (live)

| # | Chunk | Files (scope) | Depends on | Parallel group | Refs | Status |
|---|-------|---------------|------------|----------------|------|--------|
| 0 | Contracts | ... | — | — (barrier: blocks all) | contracts/* | pending |
| 1 | ... | ... | 0 | A | adr/001, contracts/x | pending |

Status values: `pending → briefed → executing → in-review → revising → accepted (commit <sha>)`,
or `escalated` / `absorbed-inline`.

## Documents

- Plans: {links, newest first}
- ADRs: {one line each}
- Contracts: {one line each}

## Open questions

{count unanswered} — see current plan. List any answered-since-last-version here.

## Serialized-ops ledger

Chronological log of orchestrator-only ops run at accept time (gen, deps, migrations,
integration runs) — so the session can be replayed mentally from this file alone.
```

---

## Plan snapshot template (`plans/NNN-<slug>.md`)

```markdown
---
dossier: plan
version: {NNN}
updated: {YYYY-MM-DD}
---

# Plan {NNN} — {feature-name}

**Supersedes:** [{NNN-1}]({NNN-1 filename}) {or "none (initial)"}
**What changed since last version:** {1–3 bullets; omit for 001}

## Summary of proposed changes

Plain-English. What's changing and why. Aim for something you'd paste into the PR
body later.

## Chunk map (as of this version)

{Same table shape as MANIFEST — this copy is frozen; MANIFEST carries live status.}

## Risks

- Migration concerns, perf implications, cross-cutting effects, coverage gaps.

## Open questions

### Q1: {question}
**Refs:** [{file}:{line}]({relative link}), [{file}:{line}]({relative link})
[ANSWER NEEDED]

{Every question carries Refs — links to the code that motivated it, so the user can
click through and do a cursory review before answering. A question with no code
anchor is usually a requirements question; say so instead of omitting the line.
When answered — in chat or in-file — inline the answer below the question. Keep the
question. Carry unanswered questions forward into the next version.}
```

---

## ADR template (`adr/NNN-<kebab-title>.md`)

One pattern or structural decision per doc. The Shape section is the contract sub-agents
are held to — pseudo-code beats prose.

```markdown
---
dossier: adr
status: proposed        # proposed | hardened | amended
promotion: session-only # kb-pattern | kb-decision | project-agent-docs | session-only
updated: {YYYY-MM-DD}
---

# ADR {NNN}: {title}

## Context

Why this decision exists. What existing code/pattern it relates to — cite example
files by path when following an established repo pattern.

## Decision

The call, in a sentence or two.

## Shape

```pseudo
// Pseudo-code dictating signatures, file layout, naming, data flow.
// This is what executors are reviewed against — be concrete.
```

## Consequences

What this buys, what it costs, what it forecloses.
```

The `promotion` frontmatter field is the harvest hint for wrap-session: `kb-*` docs are written
into the knowledge base (generalized, project-agnostic where possible),
`project-agent-docs` docs graduate into the repo's agent docs via the PR,
`session-only` dies with the worktree.

---

## Contract template (`contracts/<seam-name>.md`)

One seam per doc. These become real code in chunk 0.

```markdown
---
dossier: contract
seam: {seam-name}
updated: {YYYY-MM-DD}
---

# Contract: {seam name}

**Between:** {chunk/package A} ⇄ {chunk/package B}
**Landed in chunk 0 as:** {file path(s) once committed}

## Types & signatures

```typescript
// The actual interfaces/types/SDL/schema — written here first, hardened with the
// user, then landed verbatim in chunk 0.
```

## Invariants

Behavioral promises the types can't express (ordering, idempotency, nullability
semantics, error contracts). These feed the behavioral specs in Phase 7.

## Gen implications

Codegen this triggers (Prisma, GraphQL, etc.) — the orchestrator runs it at chunk-0
accept (serialized-ops lane); executors never run gen themselves.
```
