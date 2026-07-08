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

Assumes the user's vault is rooted at the **worktrees parent dir** (`worktree_dir`,
e.g. `~/worktrees`), so worktree code and dossiers are both vault-internal. Relevant
plugins: Bases (core), Embed Code File, Advanced URI, Shell commands, Code Styler.

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

### Inline code embeds

In addition to (never instead of) every canonical code-ref link, emit an
[Embed Code File](https://github.com/almariah/embed-code-file) block so the
referenced code renders inline and live-updates as executors change it:

````markdown
```embed-typescript
PATH: "vault://{repo}/{worktree-name}/{repo-rel-path}"
LINES: "{start}-{end}"
TITLE: "{repo-rel-path}:{line}"
```
````

`PATH` is vault-relative from the worktrees parent. Pull a few lines of surrounding
context, not just the single line. Language suffix matches the file type.

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
- No `.obsidian/`-dependent behavior (themes, CSS snippets, hotkeys) — the user's
  vault config is theirs.
