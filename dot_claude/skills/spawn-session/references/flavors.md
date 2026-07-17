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

1. **The code-ref link itself opens the editor** (when `[review] editor_open_command_id`
   is set — the normal obsidian-flavor case). Visible text is `file.ts:line`; the
   **href is the Shell Commands editor-open URI** (item 3 below), so clicking the
   filename jumps straight into the editor. Do **not** emit a separate `✎` pencil and do
   **not** point the href at a relative path — under the `~/dossiers` layout the code is
   outside the vault, so a `../../…` target resolves into the dossier tree, not the code
   (dead link). Example:
   `[users.ts:42](obsidian://shell-commands/?vault=dossiers&execute={id}&_file=%2FUsers%2F…%2Fusers.ts&_line=42)`
   - **Fallback when `editor_open_command_id` is unset:** render the portable relative
     link `[users.ts:42](../../packages/api/src/users.ts:42)` instead — it resolves when
     the dossier is opened *through* the worktree `_plan` symlink. Never leave a ref as
     bare prose; one of the two forms always applies.
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
3. **The editor-open URI** (the href used by item 1) fires the Shell Commands plugin
   against the **main checkout** (`{projects_dir}/{repo}/…`, default `~/projects`),
   never the worktree:
   `obsidian://shell-commands/?vault={vault}&execute={editor_open_command_id}&_file={enc-abs-path}&_line={line}`
   (note the `/?` — that's the scheme Obsidian's Shell Commands actually emits)
   - `_file` = the absolute main-checkout path, **percent-encoded as a whole URI
     component** (`encodeURIComponent` semantics — every `/`→`%2F`, space→`%20`, etc.;
     the emitted value must contain **no literal `/`**). Raw slashes are the #1 failure
     here — a path like `_file=/Users/…/x.ts` silently fails to open; the working form
     is `_file=%2FUsers%2F…%2Fx.ts`. `_line` = the line number as its **own** var so the
     path never carries a `:line` suffix the shell would mis-split. Custom URI vars must
     start with `_`.
   - **One-time Obsidian setup (both steps required, or the URI is rejected):**
     (a) Shell Commands → **Custom variables** → declare `_file` and `_line`
     (they must be pre-declared; a URI referencing an undeclared `_var` fails with
     "custom variables don't exist", which also masks the `execute` param). (b) Create
     the command mirroring `[review] editor` — default `editor = "zed {file}:{line}"`
     → command `/usr/local/bin/zed "{{!_file}}:{{!_line}}"`. Two non-obvious musts:
     the **`!` prefix** (`{{!_file}}`, not `{{_file}}`) — the plugin otherwise
     backslash-escapes every non-`[A-Za-z0-9_]` char, so `.` and `/` in the path get
     mangled and the editor opens an empty buffer at a nonexistent path; and the
     **absolute binary path** (the plugin runs with a minimal PATH). The `"…"` quotes
     stay for space-safety. Its generated id goes in `editor_open_command_id`.
   - **Never** point at the worktree — it's ephemeral; the main checkout is the durable
     edit target.

The default for an existing-code ref is **filename→editor link + GitHub embed** (item
1's href is item 3's URI). Drop to the relative-link href when `editor_open_command_id`
is unset, and to the static-excerpt fallback only when there's no remote to embed from.

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
