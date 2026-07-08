---
name: spawn-session
description: Kick off a new coding session inside a freshly-opened git worktree. Check out a correctly-named feature branch, optionally fetch context from a ticket (Linear/Notion/Jira via MCP) or create a draft ticket, then collaboratively build a plan dossier (.plan/) — versioned plans, ADR-style pattern docs, typed contracts — before writing any code. Execution runs in orchestrator mode: the session model plans, carves parallelizable chunks, and delegates them to Sonnet sub-agents, reviewing each changeset before it lands. Use this skill whenever the user runs /spawn or /start, or says anything like "let's start work on X", "spawn a session for X", "new feature X", "kick off [TICKET-123]", or otherwise signals they're beginning a fresh piece of work in a worktree. This is the canonical session-opening ritual — fire it aggressively at session starts, even when the user phrases it loosely. If the user says "--init" or the config file is missing, run the interactive setup flow instead.
---

# spawn-session

Starts a new coding session inside a Claude Code worktree. The worktree itself is already created by the desktop app — this skill handles everything from "I'm in the worktree" onward: branch checkout, ticket integration, the dossier ritual, and orchestrated execution.

The session has eight phases: **parse → ticket → branch → dossier → contracts → orchestrate → behavioral pass → integrate & close**. The dossier phase is the heart of this skill. Do not skip it. Do not start coding until the user has signed off on the plan.

**Model posture (replaces all old model-switching advice):** the session model *is* the orchestrator and never changes. It owns discovery, planning, contract design, chunk carving, review, and anything cross-cutting. Execution chunks are delegated to Sonnet-class sub-agents via the Agent tool (`model: sonnet`). Never suggest a `/model` switch in either direction. If the harness has no Agent tool (or sub-agents are unavailable), fall back to executing chunks inline — the protocol below still applies, minus the delegation.

---

## Arguments

Invocation shape:

```
<feature-name> [TICKET-HANDLE] [--draft] [--team <TEAM>] [--kb <ref>] [--solo]
```

- `<feature-name>` — required. kebab-case short name, e.g. `my-cool-feature`.
- `[TICKET-HANDLE]` — optional. Existing ticket handle like `ENG-1234`. Triggers the **fetch** flow.
- `--draft` — optional. Creates a new ticket in the configured default project. Mutually exclusive with a passed ticket handle. Triggers the **create** flow.
- `--team <TEAM>` — optional. Override `project_management.default_project` for the **create** flow (e.g. `--team SERV` to draft in the SERV team even when the config default is `DEST`). **Implies `--draft`** if not already passed. Mutually exclusive with a ticket handle (the handle's prefix already encodes the team).
- `--kb <ref>` — optional. Pull session context from a knowledge-base article. `<ref>` is a slug, title fragment, or natural-language query resolved via qmd. Composes freely with the others: with `--draft`, the article seeds the draft ticket's title and description; with a ticket handle, both contexts load. See the KB flow in Phase 2.
- `--solo` — optional. Skip sub-agent delegation; the orchestrator executes chunks inline. The dossier, contracts-first, and behavioral phases still run — `--solo` only changes *who* types the code.
- `--init` — special. Skip the normal flow and walk the user through setting up the config file.

Honour natural-language equivalents too. "Let's start work on my-cool-feature, ticket ENG-1234" parses to `my-cool-feature ENG-1234`. "Spawn a draft session for new-dashboard" parses to `new-dashboard --draft`. "Draft a SERV ticket for new-dashboard" parses to `new-dashboard --draft --team SERV`. "Spawn a session for the scribe capture gap from the KB" parses to `scribe-capture-gap --kb "scribe capture gap"`.

If the feature name is missing or ambiguous, ask the user for it before doing anything else.

---

## Configuration

Read config from `$XDG_CONFIG_HOME/ai/spawn.toml` (fall back to `~/.config/ai/spawn.toml`).

Schema:

```toml
[defaults]
branch_prefix = "as"        # short prefix at the head of every branch
base_branch = "main"        # branch to create feature branches from

[project_management]
provider = "linear"         # linear | notion | jira | none
default_project = "ENG"     # used when --draft creates a ticket

# Optional — omit to use skill defaults
# [project_management.prompts]
# fetch = "..."
# create = "..."
```

### Interactive init

Run this flow if the config file doesn't exist, or if `--init` is passed. If the file already exists and `--init` is passed, show the current values and confirm before overwriting.

Ask one question at a time. Don't dump a form.

1. **Branch prefix** — short string that sits at the head of every branch name (e.g. your initials). Default: none, must be set.
2. **Base branch** — what to branch from. Default: `main`.
3. **Project management provider** — `linear`, `notion`, `jira`, or `none`.
4. If not `none`: **Default project** — project handle used when drafting tickets (e.g. `ENG`).

After collecting answers, write the TOML file. Create the directory if it doesn't exist. Confirm the final contents with the user.

---

## Flow

### Phase 1 — Parse & load

Parse the args. Load `spawn.toml`. If the file doesn't exist, run the interactive init first, then continue.

Validate:
- Feature name is kebab-case. If the user gave `My Cool Feature`, normalize to `my-cool-feature` and confirm.
- `--draft` and a ticket handle are mutually exclusive — if both are present, ask which one to honor.
- `--team <TEAM>` and a ticket handle are mutually exclusive — if both are present, ask which one to honor. (The ticket handle's prefix already determines the team.)
- If `--team <TEAM>` is present without `--draft`, treat it as `--draft --team <TEAM>` (the override only has meaning for the create flow).

### Phase 2 — Ticket integration (best effort)

Tickets are **best-effort**. If the MCP isn't available, note it to the user and continue without ticket context — never block the session on a missing integration.

Three cases:

**A. Ticket handle provided** → Fetch flow.
- Discover connected MCPs. Look for one matching `project_management.provider`.
- If found: render the fetch prompt (below) with `{{provider}}`, `{{ticket}}` filled in, and execute it. Read the ticket title, description, comments, and any linked documents.
- If not found: tell the user "No {provider} MCP is connected — continuing without ticket context." Skip to Phase 3.

**B. `--draft` flag** → Create flow.
- Discover connected MCPs for the configured provider.
- Resolve `{{project}}`: if `--team <TEAM>` was passed, use that; otherwise use `project_management.default_project` from `spawn.toml`. Announce which team the draft is being created in so the user can catch mistakes before the ticket is written.
- If found: render the create prompt with `{{provider}}`, `{{project}}`, `{{name}}` filled in, and execute it. Capture the newly-created ticket handle — it goes in the branch name.
- If not found: tell the user and proceed as if no ticket was specified.

**C. Neither ticket nor `--kb`** → Skip Phase 2 entirely.

**D. `--kb <ref>`** → KB context flow (composes with A or B; best-effort like tickets).
- Resolve the ref: try `qmd search "<ref>"` for an exact-ish match, fall back to `qmd query "<ref>"`. One clear winner → Read the article in full. Multiple plausible hits → show the candidates (title + one-liner) and ask which one. None → tell the user and continue without KB context.
- Treat the article as planning input with the same weight as a fetched ticket: it seeds the dossier — a handoff brief's work items typically become the first draft of the chunk map. Follow `[[wikilinks]]` central to the work (one hop).
- If `--draft` is also present, seed the draft ticket's title and description from the article instead of just the feature name.
- Note the article's path in `MANIFEST.md` as the originating brief — wrap-session's harvest closes it out (`status: completed` + Outcome section) when the work ships.
- If qmd is unavailable, fall back to `rg -il "<ref>" <kb-root>` over the KB and Read the best match; never block the session on the KB.

#### Default prompts

Use these unless the config overrides `[project_management.prompts]`:

**fetch:**
> Fetch the {{provider}} issue {{ticket}} using the {{provider}} MCP tools. Read through the ticket title, description, comments, and any linked issues or documents. Familiarize yourself with how this ticket relates to the codebase.

**create:**
> Create a draft {{provider}} issue in project {{project}} titled '{{name}}'. Use the {{provider}} MCP tools to create it. As work progresses, incrementally update the issue description with files changed, approach taken, and decisions made. At the end of the session, finalize the issue with a proper title, description, and acceptance criteria based on what was actually built.

### Phase 3 — Branch checkout

**First, confirm you're standing in the worktree — not the main checkout.** The desktop app
opens the session inside a dedicated worktree dir (e.g. `~/worktrees/<repo>/<name>`). The main
checkout (e.g. `~/projects/<repo>`) is a *separate* working tree, usually sitting on the base
branch. Editing there silently puts the whole feature diff on the wrong branch. This has bitten
us repeatedly — guard against it before doing anything else:

```bash
git rev-parse --show-toplevel   # must be the worktree path, NOT the main checkout
git rev-parse --abbrev-ref HEAD # the branch this worktree is on
```

If `--show-toplevel` points at the main checkout instead of the worktree, **stop** and tell the
user — do not create the branch or edit files. Run every git command and every file edit from
the worktree path for the rest of the session.

Naming rule:

| Case | Branch name |
|---|---|
| With ticket (fetched or drafted) | `{branch_prefix}/{TICKET}_{feature-name}` |
| Without ticket | `{branch_prefix}/{feature-name}` |

Examples: `as/ENG-1234_my-cool-feature`, `as/my-cool-feature`.

**The desktop app usually opens the worktree already on an auto-generated placeholder
branch** (e.g. `as/some-feature-ish-name-b0af7f`). That name is never canonical —
**rename it in place, every time, without asking**:

```bash
git branch -m {branch_name}
```

Renaming the current branch is safe in a worktree — the desktop's worktree mapping is
by *path*, not branch name. Do this after Phase 2 so a drafted ticket's handle makes it
into the name. Only two exceptions: the current branch already matches the canonical
name (nothing to do), or it has an upstream (`git rev-parse --abbrev-ref @{u}`
succeeds — already pushed / PR open; renaming would orphan the remote, so surface to
the user instead). "Keeping the placeholder and noting it as a deviation" is not an
option.

If the worktree is sitting on the **base branch** instead, create the feature branch:

```bash
git checkout -b {branch_name} {base_branch}
```

If the canonical branch already exists, check it out instead (`git checkout {branch_name}`) and tell the user.

After checkout, **verify** the worktree is on the feature branch and not the base branch:

```bash
git rev-parse --abbrev-ref HEAD   # must equal {branch_name}, not {base_branch}
```

### Phase 4 — The dossier (the planning ritual)

**This is the heart of the session. Do not skip it. Do not start coding until the user has signed off.**

Create the `.plan/` dossier at the repo root using the layout and templates in `references/dossier.md`:

```
.plan/
  MANIFEST.md      # the only living doc — session state, live chunk map, links
  plans/           # versioned plan snapshots — append-only, never edited in place
  adr/             # ADR-style pattern & architecture docs
  contracts/       # the typed seams — signatures, invariants, gen implications
  chunks/          # per-chunk briefs and reports (written during Phase 6)
  handoff/         # review notes, wrap handoff
```

#### Rules

1. **The dossier is never committed.** Exclude `.plan/` via the repo's local exclude file — do **not** edit `.gitignore`. Resolve the path with `git rev-parse --git-path info/exclude` (worktrees have a `.git` *file*, and the worktree's own `info/exclude` is **not** consulted — exclusions must live in the main repo's `.git/info/exclude`). Append idempotently:
   ```bash
   EXCLUDE="$(git rev-parse --git-path info/exclude)"
   mkdir -p "$(dirname "$EXCLUDE")"; touch "$EXCLUDE"
   grep -qxF ".plan/" "$EXCLUDE" || echo ".plan/" >> "$EXCLUDE"
   ```
   Verify with `git status` — nothing under `.plan/` should appear as untracked.
2. **Plans are versioned, never edited.** Each revision is a new file — `plans/001-initial.md`, `plans/002-post-review.md`. The user reviews plan *diffs as documents*; editing a plan in place destroys that. `MANIFEST.md` always points at the current version.
3. **MANIFEST.md is the living index.** It carries the live chunk map (with status), links to the current plan / ADRs / contracts, and the open-question count. Keep it in lockstep with the TodoWrite tool — chunk statuses and todos mirror each other, so the dossier alone is enough to resume a lost session.
4. **Patterns and architecture go in `adr/`, not in the plan.** Each significant pattern or structural decision is a discrete ADR-style doc with a **Shape** section — pseudo-code that dictates signatures, file layout, and naming. These are the docs sub-agents are held to, and the candidates the wrap-session harvest promotes to the KB or the project's agent docs. Cite existing repo patterns by example-file path; write new ones as pseudo-code and harden them with the user.
5. **Open questions get explicit answers — and code anchors.** Every question carries a **Refs:** line linking the code it's based on (clickable relative links per the convention in `references/dossier.md`), so the user can jump to the file and review before answering. Mark each `[ANSWER NEEDED]`. When the user answers — in chat *or* by editing the dossier file directly — inline the answer below the question; don't delete the question.
6. **Pause before execution.** Once the first full draft is complete, stop and hand off for review.

#### Draft the plan

Work through it in this order — it's fine to loop back as later sections clarify earlier ones:

1. **ADRs** (`adr/`) — how the solution fits the existing system; the patterns in play, each with its Shape pseudo-code.
2. **Contracts** (`contracts/`) — the typed seams between chunks and packages: types, signatures, schema/SDL changes, invariants. These are what you and the user harden *together* — they're the control surface for the shape of the code.
3. **Plan snapshot** (`plans/001-initial.md`) — summary of proposed changes, the chunk map (see below), risks, open questions.
4. **Chunk map** — carve execution into chunks: id, scope (explicit file list), depends-on, parallel-safe flag, ADR/contract refs, done-criteria (the scoped verify commands). Chunk 0 is always the contracts chunk (Phase 5). Chunks are parallel-safe **only** when their file sets are provably disjoint *and* they don't touch shared generated files. Mirror the map into `MANIFEST.md`.

#### The pause ritual

After the first complete draft, stop. **The dossier is canonical; chat gets a digest.** Post to chat:

- One short paragraph — what we're building and the pivot worth flagging.
- The chunk map as a compact table (id, title, parallel group).
- One-line-each list of ADRs and contracts, as clickable paths.
- **Open questions rendered inline in full, with their code refs as clickable links** — these block execution and deserve to be answered without opening a file, but the refs let the user jump to the code when an answer needs a look first.
- The dossier path, so the user can jump in with any tool.

Then say something like:

> "The dossier is drafted at `.plan/` — plan, ADRs, and contracts are ready for review in your editor of choice. Answer the open questions here or directly in the files (just tell me to re-read the dossier). Give me the word to start execution."

Wait for the user. **Do not write any production code yet.** When the user edits dossier files directly, re-read them, diff against what you wrote, and fold the deltas into a new plan version if they change scope. Answers to open questions get inlined per rule 5.

### Phase 5 — Contracts first (chunk 0)

**Invariant: every session lands its contracts before fan-out — even solo sessions, even single-chunk sessions.** The seams are where the user shapes the code; they get hardened with the user in Phase 4 and turned into real committed code here, so executors code against actual types rather than promises, and the type-checker — not the reviewer — enforces the shape.

Chunk 0 is executed **inline by the orchestrator** (never delegated) and contains:

- Shared types, interfaces, and the seams from `contracts/`.
- Schema changes: Prisma schema, GraphQL SDL, event payload types.
- Codegen runs for the above, plus any dependency additions (lockfile ops).
- A commit, once it type-checks: contracts land as the first commit on the branch.

After chunk 0, every executor's `typecheck` done-criteria doubles as contract enforcement — a chunk that violates its seam fails its own verification. If a mid-flight chunk discovers it needs a contract change, that's a *paused* chunk, not a licence to improvise: the orchestrator amends the contract (with the user if it's a judgment call), lands it, then resumes the chunk. Frequent mid-flight contract changes are a signal chunk 0 was under-designed — say so in the wrap handoff.

### Phase 6 — Orchestrated execution

**Precondition — verify location and branch before writing a single line of code.** Run:

```bash
git rev-parse --show-toplevel    # must be the worktree path
git rev-parse --abbrev-ref HEAD  # must be the feature branch, not the base branch
```

If either is wrong, **stop and fix it before editing**. Include the worktree path *explicitly* in every executor brief — sub-agents inherit the same footguns.

**Second precondition — the dossier records the transition before the work happens.** The moment the user signs off, flip `MANIFEST.md`'s State to executing — *before* writing any brief or code. From then on, every status change is **write-MANIFEST-first**: a chunk isn't briefed until its row says `briefed`, isn't running until it says `executing`, isn't done until it says `accepted (commit <sha>)`. Never batch status updates for later — a stale MANIFEST lies to the user mid-session and defeats the dossier's resume-after-loss purpose.

**Translate agent-reported paths.** Explore/research agents, `qmd`, and necro-kb report absolute
paths rooted at the *main checkout* (e.g. `~/projects/<repo>/<rel>`). Before editing any such
path — and before putting it in a brief — rewrite it to the worktree (`<worktree>/<rel>`).

**If you discover edits already landed in the main checkout**, relocate them with a shared stash
(stashes live in the common git dir and are visible from every worktree):

```bash
# from the main checkout (only your feature changes should be present):
git stash push --include-untracked -m "<ticket> <feature>"
# from the worktree:
git stash pop
```

#### The orchestration loop

Full protocol — brief template, report contract, review loop, serialized-ops lane — lives in `references/chunk-protocol.md`. The shape:

1. **Delegation is unconditional — there is no size threshold.** Every executor chunk goes to a Sonnet sub-agent, *including a chunk map of one*: the orchestrator's tokens are the expensive ones, executors are faster and cheaper, and delegating keeps the orchestrator's context clean for review. Do not weigh chunk count or diff size, and do not record a "session mode" — there is no mode decision to make. The orchestrator writes production code in exactly three cases: chunk 0 (contracts), absorbing a chunk after the revision cap / escalation, and `--solo`. On those inline paths the protocol still applies (briefs-as-specs, per-chunk commits, verification); the brief just becomes your own spec.
2. **Brief** each chunk (`chunks/NN-brief.md`): objective, explicit file list, *don't-touch* boundaries, pointers to the relevant ADRs/contracts (point, don't inline — executors can Read the dossier), done-criteria commands, the report format, and the standing constraints (no codegen, no lockfile ops, no migrations, no commits, work only in the worktree path given).
3. **Spawn** executors with the Agent tool, `model: sonnet`, in the background. Spawn a parallel group only when the chunks' file sets are disjoint; otherwise run in dependency order. Relay a one-line status to the user as each chunk lands.
4. **Review the diff, not the synopsis.** When an executor reports, read its report (`chunks/NN-report.md`), then review the actual `git diff` for the chunk's files against the ADR shapes and contracts. Executors over-claim; the diff doesn't.
5. **Accept → serialized ops → commit.** On accept, the orchestrator runs anything from the chunk's *needs* list (codegen, deps, migrations, integration-test runs — these are orchestrator-only, serialized, never parallel), verifies, and commits the chunk. One commit per accepted chunk — clean rollback, and round-2 reviews get a well-defined diff.
6. **Revise via SendMessage, max 2 rounds.** Revision notes go back to the *same* agent (its context is warm). After 2 failed rounds, or if the executor reports blocked: the orchestrator takes the chunk inline, or surfaces it to the user if it's a judgment call. Never let the loop grind.
7. **Deviations are review input.** Anything the executor did beyond its brief is either adopted (fold into the ADR/contract so later chunks inherit it) or reverted — never silently absorbed.
8. **Scope changes update the dossier first**, then the chunk map, then execution. New risks or questions go to `MANIFEST.md` and get raised with the user.

The orchestrator keeps for itself: chunk 0, cross-cutting changes, gnarly debugging, anything touching more files than a brief can bound, and the final integration pass.

If this session was started with `--draft`, update the draft ticket's description incrementally as chunks land, and finalize it at the end (per the create prompt).

### Phase 7 — Behavioral pass

After all chunks are accepted and committed, run the behavioral-spec pass — **part of every session**, sized to the session. Full definition, substrate rules, and the spec-agent brief template live in `references/behavioral-specs.md`. The essence:

- Behavioral specs are **interaction tests against real resources** — real datastores at minimum, real service seams to the edge of the packages — that pin the feature's expected happy paths (and, for bug fixes, the fixed path) the way prod will exercise them. They assert observable behavior at the seams the contracts defined: contracts open the session, behavioral specs prove them at close.
- Specs are **keepers**: committed, CI-runnable, maintained. A spec that only runs on a hand-booted stack will rot — CI-runnability is a hard requirement.
- Use the project's **recorded behavioral substrate** (check the KB and the project's agent docs). If the project has none, hardening one with the user is a first-class deliverable of this session — record it afterward so future sessions inherit it.
- Delegate spec-writing to a dedicated Sonnet agent with an orchestrator-written brief built from `contracts/` + the plan summary, or write them inline for small sessions. **Review specs at the highest bar** — a wrong spec pins wrong behavior. Small sessions extend an existing scenario rather than authoring a new suite.

### Phase 8 — Integration pass & close-out

The orchestrator's own final gate — chunk-scoped verification doesn't catch seam bugs between chunks:

1. Full lint + typecheck + unit across the touched surface; integration and behavioral suites against real services.
2. Reconcile `MANIFEST.md`: all chunks accepted, all questions answered, deviations documented.
3. Write `handoff/wrap.md`: what shipped vs. planned, deviations, ADRs worth promoting (the harvest input for wrap-session), follow-ups.
4. If `--draft`, finalize the ticket per the create prompt.

---

## References

- `references/dossier.md` — `.plan/` layout and templates (MANIFEST, plan snapshot, ADR, contract)
- `references/chunk-protocol.md` — chunk map spec, brief/report templates, review loop, serialized-ops lane
- `references/behavioral-specs.md` — behavioral pass definition, substrate rules, spec-agent brief
- `assets/slash-command.md` — template to drop into `.claude/commands/spawn.md` for slash-command invocation
