---
name: wrap-session
description: Close down and clean up a coding session started by the spawn-session skill. Runs safety checks for uncommitted or unpushed work, finalizes the associated ticket in the connected project-management MCP (Linear/Notion/Jira) with a summary of what was actually built, removes the git worktree, and optionally deletes the branch. Use this skill whenever the user runs /wrap-session or /wrap, or says things like "wrap up this session", "clean up the worktree for X", "close out this feature", "remove the worktree", or otherwise signals they're done with a feature and want to tear down. Runs from either inside the worktree (auto-detect) or from anywhere when given a feature name. This is the canonical session-closing ritual and the companion to spawn-session — fire it at the end of every session the user wraps up.
---

# wrap-session

Bookend to `spawn-session`. Tears down a coding session: safety checks → ticket finalization → dossier harvest → worktree removal → optional branch deletion.

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
- The corresponding MCP is connected and available — **or** the provider is `kb` and
  `kb_root` exists (no MCP involved)

**KB provider (`provider = "kb"`):** delegate to the `kb-ticket` skill's **finalize**
verb (it owns the file mechanics, drafted-vs-fetched semantics, and the landing pass) —
feed it what was actually built from the dossier + git log as below. The
drafted-vs-fetched distinction applies the same way as for MCP tickets.

Read the `_plan/` dossier from the worktree (if still present) for context on what was planned vs. built — `handoff/wrap.md` and `MANIFEST.md` first, then the current plan version (legacy sessions may have the dossier at `.plan/` or a single `PLAN.md` instead — check those too). Also skim recent git log for the branch.

Use the finalize prompt (below, or config override) to update the ticket. The prompt handles two sub-cases via the model's own judgment:

- **Drafted ticket** (was created at session start by `spawn-session --draft`): rewrite title, description, and acceptance criteria to reflect what was actually built. This fulfills the commitment in the original create prompt.
- **Fetched ticket** (was pre-existing): add a completion comment summarizing changes and referencing the branch — do NOT overwrite the existing description.

Tell-tales: a drafted ticket typically has a minimal initial description with a trail of mid-session updates; a fetched ticket has richer pre-existing content.

#### Default finalize prompt

> Finalize the {{provider}} issue {{ticket}} using the {{provider}} MCP tools. Read the ticket's current state first to determine whether it was drafted at session start or pre-existing. If drafted (minimal initial description, session updates visible): finalize its title, description, and acceptance criteria based on what was actually built — consult PLAN.md and the git log on branch {{branch}} for details. If pre-existing (rich description already present): add a completion comment summarizing changes and referencing the branch `{{branch}}`. Do not overwrite pre-existing ticket content.

Config override: set `[project_management.prompts] finalize = "..."` in `spawn.toml`.

Placeholders: `{{provider}}`, `{{ticket}}`, `{{branch}}`.

### Phase 4 — Dossier harvest

The `_plan/` dossier dies with the worktree — this phase decides what outlives it.
Skip silently if the worktree has no dossier (legacy `PLAN.md`-only sessions included:
their insights move to the ticket in Phase 3 and that's enough).

1. Walk `_plan/adr/` and read each doc's `promotion` frontmatter field (legacy
   dossiers: a `**Promotion candidate:**` body line), plus any promotion notes in
   `handoff/wrap.md`.
2. Sort each ADR (and any contract doc whose reasoning generalizes):
   - **`kb-pattern` / `kb-decision`** → write directly into the knowledge base at
     `~/projects/necro-kb` (`patterns/` or `decisions/`), generalized — strip
     session-specific paths, keep the Shape pseudo-code and the reasoning.
     Project-agnostic phrasing wherever the pattern isn't inherently tied to the repo.
     Never use drop files.
   - **`project-agent-docs`** → these should have graduated into the repo's agent docs
     *via the PR during the session*. If one didn't, flag it to the user as a follow-up
     — don't commit new files to the repo from the wrap flow.
   - **`session-only`** → dies with the worktree, as designed.
3. Show the user the harvest manifest (what's going to the KB, one line each) before
   writing. They arbitrate; default to their call over the ADR's own hint.
4. **Close out any KB handoff doc that spawned this session.** If the session was
   kicked off from a KB article (an initiative/handoff brief with `status: active`),
   flip it to `status: completed` (or note remaining scope if partial), and add a
   short Outcome section linking to whatever the session produced — the successor
   articles, the PR, the agent-docs page. Don't delete it; the resolved brief is the
   future answer to "why did we do this". Eventual pruning belongs to the KB's own
   consolidation pipeline.
5. Keep it honest: harvest only docs with real reuse value. An empty harvest is a fine
   outcome — don't fabricate KB entries to make the phase look productive.

### Phase 4b — Pattern sweep (the librarian)

Phase 4 harvests what was *marked* (`promotion:` hints); this phase catches the
code-level patterns nobody marked — the idioms a reviewer would say "we always do it
this way" about. Skip silently when the session produced no code diff (docs/config-only
sessions have nothing to sweep).

1. **Sweep via a Sonnet sub-agent** (Agent tool, `model: sonnet`). Brief it with: the
   session's full diff (`git -C <worktree_path> diff <base_branch>...HEAD`), the list of
   existing pattern titles + `context_tags` from the KB's `patterns/` dir, and the
   pattern manifest schema from the KB's CLAUDE.md. Ask for candidate patterns only —
   each with: name, Shape (pseudo-code + the landed exemplar path), proposed `use_when`
   / `avoid_when` / `context_tags` (reuse existing tag vocabulary; flag any new tag it
   had to mint), and a one-line why-this-recurs argument. Extending an existing pattern
   article beats proposing a near-duplicate — the agent must check.
2. **Review gate — candidates are review input, never silent writes.** Show the user
   the candidate list (name + use_when, one line each). The user arbitrates; a wrong
   pattern pins wrong behavior forever, so when in doubt, drop it.
3. **Land accepted candidates** as `patterns/<slug>.md` in the KB with the full
   retrieval manifest, `maturity: candidate`, and `source_exemplar` pinned to the
   session's landing commit. New articles get an `_index.md` line. Language flavors are
   **not** generated at harvest — they're rendered lazily on first cross-language recall
   (don't pay for flavors nobody has needed).
4. **Run the landing pass** (same as any KB write): `scribe lint --changed`, tier fill,
   `scribe sync --reindex`, `scribe commit`.
5. An empty sweep is a fine outcome — same honesty rule as Phase 4.

### Phase 5 — Voice capture (lightweight)

Harvest voice signal from this session into the corpus — the raw pool that the
`voice-distill` skill later compresses into `~/.config/ai/VOICE.md`. This is
**capture, not distillation**: append a few high-signal observations and stop.
Never rewrite `VOICE.md` from here.

Append to **today's** capture log — `~/.config/ai/voice/corpus/<YYYY-MM-DD>.md`
(create the `corpus/` dir and the day's file if missing). Multiple sessions in
one day append to the same dated log. Capture only what genuinely helps write
prose *as* Alex:

- **Corrections (highest signal):** if Alex edited prose you wrote "in his
  voice" this session, record the before → after and what it reveals.
- **Vocabulary / framing he reached for** — distinctive words, phrasings, or
  framings from his own messages.
- **Structure / tone moves** worth reinforcing.

Rules:
- **Distill, don't dump.** A few bullets, never a transcript. Capture his words
  and instincts — *not* his loose chat style (typos, run-ons, interjections);
  those are not his artifact voice.
- **Skip silently when there's no real signal** (short or purely mechanical
  session). An empty capture beats noise.
- **Append only.** Add one `## <ticket/feature>` section to today's log (the date
  is the filename); do not touch `VOICE.md`, other days' logs, or prune anything
  — that's `voice-distill`'s job.
- The corpus is local working state; this skill does **not** commit it.

Entry shape (inside `corpus/2026-06-22.md`):

```markdown
## DEST-610 (marketplace domain pkg)
- vocab: "the go-to", "batteries included", "clean lines of separation"
- framing: leads with the north-star / how it'll be adopted, mechanics after
- correction: I wrote "provides a domain layer" → he'd cast it as "is the go-to for …"
```

### Phase 6 — Preview shutdown

Before touching the worktree, tear down any running preview environment so no dev server is left pointing at a directory that's about to disappear.

1. Call `mcp__Claude_Preview__preview_list` to see what's running.
2. For any preview whose working directory is inside `<worktree_path>` (or whose identity matches the worktree/feature), call `mcp__Claude_Preview__preview_stop` on it.
3. If the Preview MCP isn't connected or returns no matching previews, skip silently — don't error.

Do this before Phase 7 regardless of whether you personally started the preview this session; a prior turn may have.

### Phase 7 — Worktree removal

If the current working directory is inside the worktree being removed, `cd` to the main repo first — you can't remove the worktree you're sitting in.

```bash
cd <main_repo_path>
git worktree remove <worktree_path>
```

If `git worktree remove` refuses (e.g. still has uncommitted state despite Phase 2), surface the error to the user and let them decide. Don't silently add `--force` to this command — Phase 2 is the right place for that override.

**Then remove the dossier's central home** (the harvest in Phase 4 already extracted anything worth keeping): `rm -rf "${dossier_dir:-$HOME/dossiers}/<repo>/<worktree-dir-name>"`. Skip if it doesn't exist (legacy sessions kept the dossier inside the worktree, where it just died with it).

### Phase 8 — Branch deletion (optional)

Only if `--delete-branch` / `-D` was passed, OR the user explicitly confirmed in conversation.

```bash
git branch -D <branch_name>
```

Use `-D` (force) rather than `-d` — the branch may not be merged yet, and the user asked to delete it.

### Phase 9 — Report

Summarize in a tight block:

- **Worktree:** removed at `<path>`
- **Branch:** deleted / kept (`<branch>`)
- **Ticket:** finalized / comment posted on `<TICKET>` / skipped (reason)
- **Harvest:** N doc(s) promoted to the KB / flagged as follow-ups / skipped (nothing to promote)
- **Patterns:** N candidate(s) swept → N accepted to the library / skipped (no diff or no candidates)
- **Voice:** captured N note(s) to the corpus / skipped (no signal)
- **Warnings:** anything left behind (e.g. stashed changes, unpushed commits user chose to leave, etc.)

Keep it tight (5–7 lines). No celebratory emoji spam.

---

## Notes on intent

- **The dossier dies with the worktree — except what the harvest promotes.** That's the design: the `_plan/` folder's purpose was the session; its insights move to the ticket via Phase 3 and to the KB / agent docs via Phase 4. Anything not promoted is gone on purpose. (Legacy `PLAN.md` sessions: same rule, ticket-only.)
- **No PR creation.** That happens during the session (via GitHub MCP, `gh`, or manually) or is the user's responsibility. This skill is strictly closure.
- **Fail safe, not fast.** Unlike the legacy cwt tool, this skill does not parallelize removal. The safety-first tradeoff matters more than saving a second on teardown.

---

## References

- `assets/slash-command.md` — template to drop into `.claude/commands/wrap-session.md`
