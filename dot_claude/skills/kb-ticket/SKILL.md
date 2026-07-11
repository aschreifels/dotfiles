---
name: kb-ticket
description: Manage KB-native tickets — markdown ticket files in the knowledge base (tickets/<project>/HANDLE_slug.md) that back the spawn/wrap rituals when spawn.toml sets project_management.provider = "kb". Verbs: create, fetch, update, finalize, list. Use whenever the user says "create a ticket", "file a ticket for X", "ticket NKB-3", "show the backlog", "what's on the board", "move NKB-2 to active", or when spawn-session/wrap-session delegate ticket operations under the kb provider. This skill is the single source of truth for handle allocation, ticket file layout, and the KB landing pass — other skills compose it rather than reimplementing it.
---

# kb-ticket

KB-native ticketing: tickets are markdown articles in the knowledge base — qmd-searchable,
wikilinked, git-audited, surfaced by `Tickets.base` (board) and kb-pulse. No MCP, no
network. This skill owns the mechanics; `spawn-session` Phase 2 and `wrap-session`
Phase 3 delegate here when `provider = "kb"`. Eventual successor: the mindmeld MCP
server, which makes ticket ops a uniform MCP provider alongside Linear/Notion — until
then, this skill is that seam.

## Config

From `~/.config/ai/mindmeld.toml` (`$XDG_CONFIG_HOME` honored; legacy fallback
`spawn.toml` with `kb_root` under `[project_management]`):

```toml
[kb]
root = "~/projects/necro-kb"   # the knowledge base — tickets/ and templates/ live here

[project_management]
provider = "kb"
```

"Available" = `[kb].root` exists. If provider isn't `kb`, this skill still works when the
user explicitly asks for a KB ticket — provider only controls what the rituals default to.

**Template resolution:** `create` seeds new tickets from `{kb.root}/templates/ticket.md`
when it exists (user-editable), falling back to the shape in this skill + the KB schema.
Frontmatter keys and status enums are contract — overrides restyle the body only.

## The entity

Schema authority is the KB's own `CLAUDE.md` (type-specific fields → **ticket**). Recap:
`{kb_root}/tickets/<project>/<HANDLE>_<slug>.md`, frontmatter `type: ticket`,
`ticket: <HANDLE>`, `project`, `status: backlog | active | in-review | done | dropped`,
`priority: p1|p2|p3`, plus the standard required fields. Body: problem, acceptance
criteria, `- [ ]` sub-items (Tasks plugin granularity). Wikilink the related KB docs.

## Handle allocation (single source of truth)

- **Prefix**: initials of the project's hyphenated segments (`necro-kb` → `NKB`);
  single segment ≤4 chars → uppercase whole (`cvc` → `CVC`); single long segment →
  first 3 letters uppercased (`momentaria` → `MOM`).
- **Sequence**: `rg -o 'ticket: <PREFIX>-\d+' {kb_root}/tickets/ | max + 1`. Zero
  existing → 1.
- Collision paranoia is unwarranted (single-user KB), but never reuse a handle — even
  from `dropped` tickets.

## Verbs

**create** `<project> <title>` (`--priority p1|p2|p3`, default p2; `--status`, default
`backlog` — the rituals pass `active` for session-drafted tickets):
allocate handle → write the file (frontmatter per schema, body seeded with problem +
acceptance-criteria skeleton) → landing pass → report the handle.

**fetch** `<HANDLE>`: read the match for `{kb_root}/tickets/**/<HANDLE>_*.md`; follow
wikilinks central to the work (one hop). No match → say so, don't guess.

**update** `<HANDLE>`: append progress to the body (files changed, decisions, chunk
status), check off completed sub-items, bump `updated:`. Never rewrite history —
append. Status moves (`backlog → active`, etc.) update frontmatter. Landing pass.

**finalize** `<HANDLE>`: the wrap-session semantic. Rewrite the description to what was
actually built (drafted ticket) or append an Outcome section (pre-existing ticket —
never overwrite prior content), check off done sub-items, link branch/PR and successor
KB articles, flip `status: done` (or `in-review` with remaining scope noted if a PR is
still open). Landing pass.

**list** (`[project]`, `--status <s>`): table of matching tickets (handle, title,
status, priority) from frontmatter — `rg` the `tickets/` tree; point at `Tickets.base`
for the visual board.

## Landing pass (single source of truth)

After any write: `scribe lint --changed` → `scribe sync --reindex` → `scribe commit`
(from `kb_root`). This keeps the board, kb-pulse, and qmd search live — a ticket that
isn't reindexed doesn't exist to the rituals.

## Composition contract

- `spawn-session` Phase 2: **fetch** (handle passed) or **create** (`--draft`, status
  `active`, project = current repo unless `--team` overrides). The handle rides the
  branch name — that's spawn's job, not this skill's.
- `wrap-session` Phase 3: **finalize**.
- Mid-session progress: **update** as chunks land.
- Changes to handle rules, layout, or the landing pass happen HERE and nowhere else.
