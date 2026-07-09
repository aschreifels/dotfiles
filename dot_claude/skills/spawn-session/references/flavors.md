# Dossier flavors

A **flavor** adapts how the dossier is *written* to the review tool the user reads it
in — configured via `[review] flavor` in `spawn.toml`. Ground rules, regardless of
flavor:

1. **Additive only, never instead of.** The canonical dossier format (relative
   markdown links, plain tables, fenced code, frontmatter) works in every editor,
   in chat, in glow, and on GitHub. A flavor layers presentation on top; it never
   replaces or degrades the canonical form. A dossier written with a flavor must
   remain fully usable with the flavor's tool absent.
2. **Structure is core; rendering is flavor.** Frontmatter fields, link discipline,
   template sections, and status semantics are the same in every flavor — tools and
   scripts depend on them. Flavors only choose *how* content is dressed: callouts,
   embeds, diagram syntax, deep links.
3. **One flavor per session**, read once at Phase 4. No flavor configured → write
   the canonical form only.

Currently defined: `obsidian`. Adding a flavor = a new `## <name>` section here plus
recognizing the value in the config.

---

## obsidian

Assumes the user's vault is rooted at the **dossier dir** (`dossier_dir`, e.g.
`~/dossiers`) — dossiers only; worktree code is deliberately *outside* the vault.
Never point the vault (or any indexer) at a working tree: every ecosystem carries
dependency/build blobs — `node_modules`, Elixir `deps/`+`_build/`, Rust `target/`,
venvs, `dist/` — and exclusion lists lose to new tools; an allowlist-by-construction
vault can't bloat (measured before the split: 95% of vault markdown was dependency
READMEs, 7.5M files watched). Relevant plugins: Bases (core), Code Styler,
Advanced Tables, Advanced URI, Shell Commands, Embed Code File.

### Properties (Bases)

The core frontmatter on every dossier doc is the contract; keep it current
(write-MANIFEST-first extends to frontmatter). Obsidian surfaces it as Properties
and Bases feed on it. Useful Bases the user may have built against these fields —
don't rename fields without flagging it:

- **Sessions board:** `dossier == "manifest" && state != "wrapped"`
- **ADR promotion queue:** `dossier == "adr" && promotion != "session-only"`
- **Plan lineage:** `dossier == "plan"` grouped by folder, sorted by `version`

### Callouts

Render recurring semantic blocks as callouts — native in Obsidian, graceful
blockquotes everywhere else:

| Content | Callout |
|---|---|
| Open question (unanswered) | `> [!question] Q{n}: {title}` — Refs + `[ANSWER NEEDED]` inside |
| Answered question | flip to `> [!success]- Q{n}: {title}` (folded; answer inside) |
| Risk | `> [!warning]` |
| Deviation (executor report / review outcome) | `> [!note]` |
| Blocked / escalated chunk | `> [!failure]` |

Use the folded form (`[!x]-`) for anything long — the reader unfolds on demand.

### Code references

The vault can't read the worktree (Obsidian sandboxes plugins to vault files) and the
worktree is deleted at wrap — so a dossier never points *live* at worktree code. Which
axis a code block falls on decides how it renders:

**Code we author here** — ADR **Shape** pseudo-code, contract types/SDL. Plain fenced
blocks; **Code Styler** dresses them (line numbers, header, language tag). This code
doesn't exist on disk yet, so there's nothing to embed or jump to — it *is* the source.

**References to existing main/production code** — open-question Refs, ADR context,
contract landing sites. Pin these to durable homes, never the ephemeral worktree:

1. **Canonical relative link, always** —
   `[users.ts:42](../../packages/api/src/users.ts:42)`. Visible text is repo-relative;
   the target resolves when the dossier is opened *through* the worktree symlink
   (Zed, editors). The portable fallback that survives every renderer.
2. **Live inline render via GitHub (Embed Code File)** — directly under the Refs line,
   for code that's actually on the remote. Resolve `{owner}/{repo}` from
   `git remote get-url origin`; pin the ref to the base commit the worktree was cut
   from (a SHA — so the embed can't drift), falling back to `base_branch`:
   ````markdown
   ```embed-typescript
   PATH: "https://raw.githubusercontent.com/{owner}/{repo}/{sha}/packages/api/src/users.ts"
   LINES: "40-46"
   TITLE: "users.ts:40-46"
   ```
   ````
   No fetchable remote (unpushed base, a private repo without one) → skip the embed and
   fall back to a **static excerpt**: a plain fenced block of the referenced lines,
   written at dossier-write time, refreshed if the code changes under the ref during
   review. (Code Styler renders it too.)
3. **Jump-to-edit in the local editor (Shell Commands)** — when
   `[review] editor_open_command_id` is set, render an "open in editor" link whose href
   fires the plugin against the **main checkout** (`{projects_dir}/{repo}/…`, default
   `~/projects`) — durable, never the worktree:
   `[open in editor](obsidian://shell-commands?vault={vault}&execute={editor_open_command_id}&_abs=/Users/…/projects/{repo}/packages/api/src/users.ts:42)`.
   The paired command is `zed "{{_abs}}"` (Zed opens `path:line`; swap for the user's
   editor). Custom URI variables must start with `_`. The command + its id are user-side
   config (see the vault README); the dossier only emits the link. Unset → omit the link.

The default for an existing-code ref is **relative link + GitHub embed + editor link**;
drop to the static-excerpt fallback only when there's no remote to embed from.

### Diagrams

Architecture and data-flow sketches in ADRs/plans use fenced `mermaid` blocks
(flowchart/sequence) instead of ASCII art — Obsidian and GitHub both render them,
and they stay legible as plain text. ASCII remains fine for tiny sketches.

### Transclusion

Where the MANIFEST summarizes another doc's live section (typically the current
plan's open questions), embed it instead of duplicating:
`![Open questions](plans/{NNN-current}.md#Open%20questions)` — renders inline in
Obsidian, degrades to a link elsewhere. Never duplicate content a transclusion can
carry; duplication drifts.

### Deep links from chat

When `[review] vault` is set and Advanced URI is installed, the pause-ritual chat
digest links each open question directly to its heading:
`obsidian://adv-uri?vault={vault}&filepath={vault-rel plan path}&heading={heading}`
(URL-encode the heading). Same for "review the dossier" prompts — link the MANIFEST.

### What NOT to do

- No `[[wikilinks]]` — filename collisions across dossiers (every session has a
  `MANIFEST.md`) make them ambiguous vault-wide; relative paths resolve everywhere.
- No Obsidian-only syntax as the *sole* carrier of information (a callout may dress
  a question; the question text, Refs links, and `[ANSWER NEEDED]` marker must
  survive rendering as a plain blockquote).
- No Embed Code File `PATH:` pointing at the worktree or any absolute filesystem path
  — the plugin reads only `vault://` and remote `http(s)://`, so an external path
  silently renders nothing. Existing code embeds via the GitHub raw URL; local code
  is reached through the Shell Commands editor link, not an embed.
- No `.obsidian/`-dependent behavior (themes, CSS snippets, hotkeys) — the user's
  vault config is theirs.
