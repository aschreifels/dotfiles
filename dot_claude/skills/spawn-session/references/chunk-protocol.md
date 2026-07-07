# Chunk protocol

The full contract between the orchestrator (session model) and executors (Sonnet
sub-agents, spawned via the Agent tool with `model: sonnet`, in the background).
Applies equally when executing inline (`--solo` / below the delegation threshold) —
the brief just becomes the orchestrator's own spec.

## Chunk map spec

Every chunk row carries:

| Field | Meaning |
|---|---|
| `#` | Chunk id. `0` is always contracts (orchestrator-inline, lands first). |
| Files (scope) | **Explicit** file list or tight glob. This is the write-boundary. |
| Depends on | Chunk ids that must be *accepted and committed* first. |
| Parallel group | Chunks in the same group may run concurrently — only if their file sets are provably disjoint **and** none touch shared generated files (codegen output, lockfiles). When in doubt, sequence. |
| Refs | ADR / contract docs the chunk is held to. |
| Done-criteria | Scoped verify commands (typecheck, lint, unit; chunk-scoped integration only when it won't contend for shared services). |

Carving guidance: file-disjointness is a design forcing-function, not just a safety
rule — if two chunks can't be carved apart, the seam between them probably wants a
contract. Prefer more, smaller, disjoint chunks over fewer overlapping ones.

## Executor brief (`chunks/NN-brief.md`)

Curated, self-contained, pointed — the executor gets *this*, never "read the plan and
do chunk N".

```markdown
# Chunk {NN}: {title}

**Worktree (work here, nowhere else):** {absolute worktree path}
**Branch (verify before editing):** {branch-name}

## Objective

What this chunk delivers, in a paragraph.

## Scope

Files you may create/modify (exhaustive):
- {path}

**Do not touch:** anything outside the list above. Especially not: {generated files,
neighboring chunks' files, schema, lockfiles}.

## Held to

Read before writing code:
- {worktree}/.plan/adr/{NNN}.md — follow its Shape exactly
- {worktree}/.plan/contracts/{seam}.md — the types are already committed; code against them

## Done-criteria

Run and pass before reporting:
- {scoped typecheck command}
- {scoped lint command}
- {scoped unit test command}

## Standing constraints

- No codegen, no lockfile ops (`rush add`/`update`), no migrations, no `git commit`,
  no pushes. If you need any of these, list it under **Needs** in your report and stop
  at the point of need.
- Verify `git rev-parse --show-toplevel` matches the worktree path above before your
  first edit.
- Match surrounding code conventions; when the ADR Shape and local idiom conflict,
  follow the Shape and flag it as a deviation note.

## Report

Write {worktree}/.plan/chunks/{NN}-report.md in the report format (below), and return
its content as your final message.
```

## Executor report (`chunks/NN-report.md`)

```markdown
# Chunk {NN} report

## Synopsis
{3–6 sentences: what was built, how it follows the Shape.}

## Files changed
{Exhaustive list — must be a subset of the brief's scope. Anything outside scope is
automatically a deviation.}

## Deviations from brief
{Anything done that the brief didn't specify, or specified differently — with the
reason. "None" is an acceptable and common answer. Honesty here is the contract.}

## Needs (serialized ops)
{Codegen / deps / migrations / integration runs required to finish or verify. "None"
if self-contained.}

## Open questions
{Judgment calls deferred to the orchestrator.}

## Verification output
{Command + tail of output for each done-criteria run.}
```

## The review loop (orchestrator)

Per chunk, on report:

1. **Read the report, then review the actual diff** — `git diff` scoped to the chunk's
   files — against the ADR Shape and contracts. The synopsis is a claim; the diff is
   the evidence. Check the scope boundary: writes outside the brief's file list are
   deviations even if the report omits them (`git status` catches these).
2. **Accept:** run the chunk's *Needs* list (serialized-ops lane, below), re-verify,
   commit — one commit per accepted chunk. Update MANIFEST status + TodoWrite. Relay a
   one-line synopsis to the user.
3. **Revise:** send focused notes to the *same* agent via SendMessage — its context is
   warm; a respawn pays rediscovery cost. **Max 2 revision rounds.** Notes name the
   Shape/contract clause being violated, not just the symptom.
4. **Escalate** after 2 failed rounds, an executor reporting blocked, or a scope-
   boundary violation that suggests the carve was wrong: the orchestrator absorbs the
   chunk inline, or surfaces to the user when it's a judgment call. Record the outcome
   in MANIFEST (`escalated` / `absorbed-inline`) — repeated escalations are a signal
   about brief quality or chunk sizing worth noting in the wrap handoff.
5. **Deviations get adjudicated, never absorbed silently:** adopt (fold into the
   ADR/contract so subsequent chunks inherit the improvement) or revert. If adopted
   mid-flight, notify executors of in-progress chunks whose briefs it affects.

## Serialized-ops lane

Orchestrator-only, strictly sequential, run at accept time (or, for a paused chunk, at
the point of need). Log each run in MANIFEST's serialized-ops ledger.

- Codegen (`rush gen`, Prisma generate, GraphQL codegen)
- Dependency changes (`rush add` / `rush update` — anything touching the lockfile)
- Database migrations
- Integration-test suite runs (shared docker services contend under parallel runs)
- Anything else mutating state shared across chunks

A chunk needing a *contract* change is a special case: pause the chunk, amend the
contract (with the user when it's a judgment call), land + gen + commit the amendment,
then resume the chunk with a brief addendum.

## Parallelism decision

Spawn a parallel group only when **all** hold:

1. File sets pairwise disjoint (compare the briefs' scope lists literally).
2. No member's Needs are anticipated to touch shared generated files mid-flight.
3. No dependency edges between members.

Otherwise sequence. Sequencing is never wrong — parallelism is an optimization, and a
merge conflict in a shared worktree costs more than it saves. (Agent-level worktree
isolation exists but the merge-back friction isn't worth it; disjoint-files-in-shared-
worktree is the model.)
