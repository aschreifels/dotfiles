---
name: wrap-session
description: Close down and clean up a coding session started by the spawn-session skill. Runs safety checks for uncommitted or unpushed work, finalizes the associated ticket in the connected project-management MCP (Linear/Notion/Jira) with a summary of what was actually built, removes the git worktree, and optionally deletes the branch. Use this skill whenever the user runs /wrap-session or /wrap, or says things like "wrap up this session", "clean up the worktree for X", "close out this feature", "remove the worktree", or otherwise signals they're done with a feature and want to tear down. Runs from either inside the worktree (auto-detect) or from anywhere when given a feature name. This is the canonical session-closing ritual and the companion to spawn-session — fire it at the end of every session the user wraps up.
---

# wrap-session

Bookend to `spawn-session`. Tears down a coding session: safety checks → ticket finalization → worktree removal → optional branch deletion.

Shares the same config file as `spawn-session`: `$XDG_CONFIG_HOME/ai/spawn.toml` (fall back to `~/.config/ai/spawn.toml`). See `spawn-session` for the full config schema. If the config file is missing, tell the user to run `/spawn-session --init` first — don't initialize it from the wrap flow.

---

## Arguments

```
[feature-name-or-path] [--delete-branch | -D] [--force | -f]
```

- `[feature-name-or-path]` — optional. If omitted, auto-detect the current worktree from `cwd`. If provided, treat as either a worktree path (if it looks like a path) or a feature name (look up in `git worktree list`).
- `--delete-branch` / `-D` — also delete the git branch after removing the worktree.
- `--force` / `-f` — skip safety prompts and proceed even with uncommitted or unpushed changes. Use sparingly.

Honor natural language equivalents. "Wrap up this session and delete the branch" → auto-detect + `--delete-branch`. "Clean up my-cool-feature" → positional arg `my-cool-feature`.

---

## Flow

### Phase 1 — Identify the worktree

**If a name/path was given:**
- Looks like a path (starts with `/`, `.`, or `~`): resolve it and verify it's a worktree via `git worktree list`.
- Otherwise: treat as a feature name and match against `git worktree list` — look for a worktree whose branch ends in `_<name>` or equals `<prefix>/<name>`.

**If nothing was given:**
```bash
git rev-parse --show-toplevel
git worktree list
```
Confirm the current directory is inside a worktree (not the main checkout). If it's the main checkout, stop and ask the user which worktree they meant — don't guess.

**From the resolved worktree, derive:**
- `worktree_path` — absolute path
- `branch_name` — from `git -C <path> rev-parse --abbrev-ref HEAD`
- `feature_name` — the tail of the branch after the last `/` and (if present) `_`
- `ticket_handle` — the `TEAM-1234` segment if the branch matches `*/TEAM-NNNN_*`, else none

### Phase 2 — Safety checks

Run inside the worktree:

```bash
git -C <worktree_path> status --porcelain
git -C <worktree_path> log @{u}.. --oneline 2>/dev/null
```

If either has output, show the user exactly what's uncommitted/unpushed and ask what to do: stash, commit, push, or abort. **Do not proceed until resolved**, unless `--force` was passed.

Even with `--force`, call out the dirty state in the final report so the user knows what got left behind.

### Phase 3 — Ticket finalization

Skip this phase entirely unless all three are true:
- A `ticket_handle` was parsed from the branch name
- `project_management.provider` is configured and not `none`
- The corresponding MCP is connected and available

Read `PLAN.md` from the worktree (if still present) for context on what was planned vs. built. Also skim recent git log for the branch.

Use the finalize prompt (below, or config override) to update the ticket. The prompt handles two sub-cases via the model's own judgment:

- **Drafted ticket** (was created at session start by `spawn-session --draft`): rewrite title, description, and acceptance criteria to reflect what was actually built. This fulfills the commitment in the original create prompt.
- **Fetched ticket** (was pre-existing): add a completion comment summarizing changes and referencing the branch — do NOT overwrite the existing description.

Tell-tales: a drafted ticket typically has a minimal initial description with a trail of mid-session updates; a fetched ticket has richer pre-existing content.

#### Default finalize prompt

> Finalize the {{provider}} issue {{ticket}} using the {{provider}} MCP tools. Read the ticket's current state first to determine whether it was drafted at session start or pre-existing. If drafted (minimal initial description, session updates visible): finalize its title, description, and acceptance criteria based on what was actually built — consult PLAN.md and the git log on branch {{branch}} for details. If pre-existing (rich description already present): add a completion comment summarizing changes and referencing the branch `{{branch}}`. Do not overwrite pre-existing ticket content.

Config override: set `[project_management.prompts] finalize = "..."` in `spawn.toml`.

Placeholders: `{{provider}}`, `{{ticket}}`, `{{branch}}`.

### Phase 4 — Preview shutdown

Before touching the worktree, tear down any running preview environment so no dev server is left pointing at a directory that's about to disappear.

1. Call `mcp__Claude_Preview__preview_list` to see what's running.
2. For any preview whose working directory is inside `<worktree_path>` (or whose identity matches the worktree/feature), call `mcp__Claude_Preview__preview_stop` on it.
3. If the Preview MCP isn't connected or returns no matching previews, skip silently — don't error.

Do this before Phase 5 regardless of whether you personally started the preview this session; a prior turn may have.

### Phase 5 — Worktree removal

If the current working directory is inside the worktree being removed, `cd` to the main repo first — you can't remove the worktree you're sitting in.

```bash
cd <main_repo_path>
git worktree remove <worktree_path>
```

If `git worktree remove` refuses (e.g. still has uncommitted state despite Phase 2), surface the error to the user and let them decide. Don't silently add `--force` to this command — Phase 2 is the right place for that override.

### Phase 6 — Branch deletion (optional)

Only if `--delete-branch` / `-D` was passed, OR the user explicitly confirmed in conversation.

```bash
git branch -D <branch_name>
```

Use `-D` (force) rather than `-d` — the branch may not be merged yet, and the user asked to delete it.

### Phase 7 — Report

Summarize in a tight block:

- **Worktree:** removed at `<path>`
- **Branch:** deleted / kept (`<branch>`)
- **Ticket:** finalized / comment posted on `<TICKET>` / skipped (reason)
- **Warnings:** anything left behind (e.g. stashed changes, unpushed commits user chose to leave, etc.)

Keep it to 4–6 lines. No celebratory emoji spam.

---

## Notes on intent

- **PLAN.md dies with the worktree.** That's the design. Its purpose was the session; its insights move to the ticket via Phase 3. If a user wants PLAN.md preserved, they should copy it out before running this skill.
- **No PR creation.** That happens during the session (via GitHub MCP, `gh`, or manually) or is the user's responsibility. This skill is strictly closure.
- **Fail safe, not fast.** Unlike the legacy cwt tool, this skill does not parallelize removal. The safety-first tradeoff matters more than saving a second on teardown.

---

## References

- `assets/slash-command.md` — template to drop into `.claude/commands/wrap-session.md`
