# The .plan/ dossier

Layout and templates for the session dossier. The dossier replaces the old single
PLAN.md: it is the canonical planning artifact, the review surface the user opens in
their own tools, and the raw material the wrap-session harvest promotes into the KB.

Never committed — excluded via the main repo's `info/exclude` (see SKILL.md Phase 4).

```
.plan/
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
  as whole documents, not as edits to a previous one.
- **`adr/` and `contracts/`** may be amended during planning; once execution starts they
  only change through the orchestrator (a contract amendment is a deliberate act that
  pauses dependent chunks — never a drive-by edit).
- The user may edit any dossier file directly from their own editor. When told to
  "re-read the dossier", diff against what you last wrote and fold the deltas in.

---

## MANIFEST.md template

```markdown
# {feature-name} — session manifest

**Ticket:** {TICKET-HANDLE or "none"}
**Branch:** {branch-name}
**Worktree:** {absolute worktree path}
**Started:** {YYYY-MM-DD}
**Current plan:** plans/{NNN-current}.md

## Chunk map (live)

| # | Chunk | Files (scope) | Depends on | Parallel group | Refs | Status |
|---|-------|---------------|------------|----------------|------|--------|
| 0 | Contracts | ... | — | — (orchestrator, inline) | contracts/* | pending |
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
# Plan {NNN} — {feature-name}

**Supersedes:** {NNN-1 or "none (initial)"}
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
[ANSWER NEEDED]

{When answered — in chat or in-file — inline the answer below the question. Keep the
question. Carry unanswered questions forward into the next version.}
```

---

## ADR template (`adr/NNN-<kebab-title>.md`)

One pattern or structural decision per doc. The Shape section is the contract sub-agents
are held to — pseudo-code beats prose.

```markdown
# ADR {NNN}: {title}

**Status:** proposed | hardened (user-approved) | amended
**Promotion candidate:** kb-pattern | kb-decision | project-agent-docs | session-only

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

`Promotion candidate` is the harvest hint for wrap-session: `kb-*` docs are written
into the knowledge base (generalized, project-agnostic where possible),
`project-agent-docs` docs graduate into the repo's agent docs via the PR,
`session-only` dies with the worktree.

---

## Contract template (`contracts/<seam-name>.md`)

One seam per doc. These become real code in chunk 0.

```markdown
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

Codegen this triggers (Prisma, GraphQL, etc.) — chunk 0 runs it; executors never do.
```
