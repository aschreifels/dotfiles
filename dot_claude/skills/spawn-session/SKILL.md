---
name: spawn-session
description: Kick off a new coding session inside a freshly-opened git worktree. Check out a correctly-named feature branch, optionally fetch context from a ticket (Linear/Notion/Jira via MCP) or create a draft ticket, then collaboratively build a PLAN.md before writing any code. Use this skill whenever the user runs /spawn or /start, or says anything like "let's start work on X", "spawn a session for X", "new feature X", "kick off [TICKET-123]", or otherwise signals they're beginning a fresh piece of work in a worktree. This is the canonical session-opening ritual — fire it aggressively at session starts, even when the user phrases it loosely. If the user says "--init" or the config file is missing, run the interactive setup flow instead.
---

# spawn-session

Starts a new coding session inside a Claude Code worktree. The worktree itself is already created by the desktop app — this skill handles everything from "I'm in the worktree" onward: branch checkout, ticket integration, and the PLAN.md ritual.

The session has four phases: **parse → ticket → branch → PLAN.md → execute**. The PLAN.md phase is the heart of this skill. Do not skip it. Do not start coding until the user has signed off on the plan.

---

## Arguments

Invocation shape:

```
<feature-name> [TICKET-HANDLE] [--draft] [--team <TEAM>]
```

- `<feature-name>` — required. kebab-case short name, e.g. `my-cool-feature`.
- `[TICKET-HANDLE]` — optional. Existing ticket handle like `ENG-1234`. Triggers the **fetch** flow.
- `--draft` — optional. Creates a new ticket in the configured default project. Mutually exclusive with a passed ticket handle. Triggers the **create** flow.
- `--team <TEAM>` — optional. Override `project_management.default_project` for the **create** flow (e.g. `--team SERV` to draft in the SERV team even when the config default is `DEST`). **Implies `--draft`** if not already passed. Mutually exclusive with a ticket handle (the handle's prefix already encodes the team).
- `--init` — special. Skip the normal flow and walk the user through setting up the config file.

Honour natural-language equivalents too. "Let's start work on my-cool-feature, ticket ENG-1234" parses to `my-cool-feature ENG-1234`. "Spawn a draft session for new-dashboard" parses to `new-dashboard --draft`. "Draft a SERV ticket for new-dashboard" parses to `new-dashboard --draft --team SERV`.

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

**Model check (first thing, before anything else):** Phases 1–4 are discovery and planning — that's peak Opus territory. If the current model is not an Opus-class model, suggest switching:

> "We're about to do discovery, architecture, and planning — if you want, switch to an Opus-class model first (`/model claude-opus-4-7`). I can continue on whatever you're on; just flagging that the planning phase benefits most from the highest-tier model."

Mention it once, non-blocking — never stop waiting for a switch. Skip the suggestion if the model already looks Opus-tier.

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

**C. Neither** → Skip Phase 2 entirely.

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

Run:

```bash
git checkout -b {branch_name} {base_branch}
```

If the branch already exists, check it out instead (`git checkout {branch_name}`) and tell the user.

After checkout, **verify** the worktree is on the feature branch and not the base branch:

```bash
git rev-parse --abbrev-ref HEAD   # must equal {branch_name}, not {base_branch}
```

### Phase 4 — PLAN.md (the planning ritual)

**This is the heart of the session. Do not skip it. Do not start coding until the user has signed off.**

Create `PLAN.md` at the repo root using the skeleton in `references/plan-template.md`.

#### Rules

1. **PLAN.md is never committed.** Add it to the repo's local exclude file — do **not** edit `.gitignore`. Resolve the path with `git rev-parse --git-path info/exclude` so it works correctly in both regular checkouts and worktrees (worktrees have a `.git` *file*, not a directory, and the worktree's own `info/exclude` is **not** consulted by git — exclusions must live in the main repo's `.git/info/exclude`). Append idempotently:
   ```bash
   EXCLUDE="$(git rev-parse --git-path info/exclude)"
   mkdir -p "$(dirname "$EXCLUDE")"; touch "$EXCLUDE"
   grep -qxF "PLAN.md" "$EXCLUDE" || echo "PLAN.md" >> "$EXCLUDE"
   ```
   Verify with `git status` — `PLAN.md` should not appear as untracked.
2. **PLAN.md is a living document.** It evolves as understanding improves. Update it as the session progresses.
3. **The Plan/Todo section stays in sync with the TodoWrite tool.** Every time you update TodoWrite, mirror the change into PLAN.md's todo list. Every time you revise the plan, update TodoWrite. This way, if the session is lost, PLAN.md alone is enough to resume.
4. **Open questions get explicit answers.** Mark each open question `[ANSWER NEEDED]`. When the user answers, inline the answer directly below the question — don't just delete the question.
5. **Pause before execution.** Once the first full draft is complete, stop and hand off to the user for review.

#### Draft the plan

Work through the sections in order. It's fine to come back and revise earlier sections as later ones clarify things.

- **Architecture & Design** — how the solution fits into the existing system. Key modules, data flow, interfaces. ASCII sketches welcome.
- **Summary of Proposed Changes** — plain-English summary. What's changing and why. Files touched at a high level.
- **Plan / Todo** — the concrete, ordered list of steps. Mirrored with TodoWrite.
- **Risks** — migration concerns, perf implications, cross-cutting effects, coverage gaps. Things that could go sideways.
- **Open Questions** — questions for the user. Mark each `[ANSWER NEEDED]` until answered.

#### The pause ritual

After the first complete draft, stop. **Always render the full contents of `PLAN.md` back to the user inline in the chat** — don't just point at the file path. The user shouldn't have to open the file in another pane to review the plan; the conversation itself should carry the plan. Then say something like:

> "Plan is drafted — also written to `PLAN.md` at the repo root so it survives session loss. Please review, especially the open questions. Give me the word when you want to execute, and flag anything you want reworked."

Wait for the user. **Do not write any production code yet.** If the user answers open questions, update both PLAN.md *and* the in-chat rendering (re-output the affected sections so the user can see the current state without leaving chat), then wait again.

#### Model switch for execution

Once open questions are resolved and the user is about to greenlight execution, suggest downshifting to Sonnet:

> "If you started this session on Opus, now is a good time to switch to Sonnet (`/model claude-sonnet-4-6`) for execution — it's faster and cheaper for follow-the-plan work, and the heavy thinking is behind us."

Mention it once, right before Phase 5. Don't repeat it mid-execution. Skip if the user is already on Sonnet.

### Phase 5 — Execute

**Precondition — verify location and branch before writing a single line of code.** This is the
last gate before edits start; don't skip it even if Phase 3 already checked. Run:

```bash
git rev-parse --show-toplevel    # must be the worktree path
git rev-parse --abbrev-ref HEAD  # must be the feature branch, not the base branch
```

If either is wrong, **stop and fix it before editing** — do not start execution from the main
checkout or the base branch.

**Translate agent-reported paths.** Explore/research agents, `qmd`, and necro-kb report absolute
paths rooted at the *main checkout* (e.g. `~/projects/<repo>/<rel>`). Before editing any such
path, rewrite it to the worktree (`<worktree>/<rel>`). Editing the reported path as-is is the
single most common way work lands on master by mistake.

**If you discover edits already landed in the main checkout**, relocate them with a shared stash
(stashes live in the common git dir and are visible from every worktree):

```bash
# from the main checkout (only your feature changes should be present):
git stash push --include-untracked -m "<ticket> <feature>"
# from the worktree:
git stash pop
```

Then re-verify the main checkout is clean and the worktree holds the changes.

Once the user gives the go-ahead:

1. Work through the Plan/Todo in order.
2. Keep TodoWrite and PLAN.md's Plan/Todo in lockstep — when one changes, the other changes.
3. If scope changes mid-session, update PLAN.md **first**, then act.
4. If new risks or questions emerge, add them to PLAN.md and raise them with the user.
5. Never commit PLAN.md. Never push it.

If this session was started with `--draft`, remember to update the draft ticket's description incrementally as work progresses, and finalize it at the end (per the create prompt).

---

## References

- `references/plan-template.md` — skeleton for PLAN.md
- `assets/slash-command.md` — template to drop into `.claude/commands/spawn.md` for slash-command invocation
