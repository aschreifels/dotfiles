# Rubric — Core

Universal scoring and behaviour for the `pr-review` skill. Always loaded. Other packs build on these definitions; overlays can tighten or override them for specific repos.

---

## Severity tiers

| Tier | ID prefix | Meaning |
|------|-----------|---------|
| Blocker | `B` | Must fix before merge. If shipped, this causes an incident, security breach, data loss, or violates a hard project rule. Be conservative — a false-positive blocker erodes trust faster than a missed medium. |
| High | `H` | Should fix before merge. Real bug, real risk, or clear convention violation, but the consequence is recoverable. |
| Medium | `M` | Worth addressing. Design smell, maintainability problem, missing edge-case handling that's unlikely but plausible. |
| Low / Nit | `L` | Optional. Style, naming, comment wording, micro-readability. Default to *not flagging* unless it's egregious or sets a bad precedent. |
| Question | `Q` | Not a finding — a clarification request for the author. Use sparingly. |

## Confidence (separate axis)

Score every finding 0–100 on how sure you are it's a real problem on a line the PR actually changed:

- **< 50** — drop silently.
- **50–69** — drop unless tier is Blocker; then keep as a `Q` and explain the uncertainty.
- **70–89** — keep.
- **90–100** — keep, speak with conviction in the suggested fix.

Multiple sub-agents raising the same issue is *not* extra confidence — they may share a blind spot. Verify by reading the code yourself before promoting.

## Category taxonomy

Each finding gets exactly one primary category. Multi-category findings pick the dominant axis.

| Category | Pack |
|----------|------|
| `security` | [security/](security/) — `_shared.md` + per-language slices |
| `db` | [db.md](db.md) |
| `performance` | [performance/](performance/) — `_shared.md` + per-language slices |
| `correctness` | [correctness/](correctness/) — `_shared.md` + per-language slices |
| `conventions` | [conventions.md](conventions.md) |
| `maintainability` | [maintainability.md](maintainability.md) |
| `tests` | [tests/](tests/) — `_shared.md` + per-language slices |
| `ui` | [ui.md](ui.md) |
| `api` | [api.md](api.md) |
| `style` | (covered in [conventions.md](conventions.md)) |

Packs that are directories (`security/`, `correctness/`, `performance/`, `tests/`) split into a language-agnostic `_shared.md` plus per-language slices (`ts.md`, `py.md`, `go.md`, etc.). The skill's router loads `_shared.md` always, then any language slices matching languages detected in the diff. New languages get added by dropping a new file into the relevant directory — no other registration needed.

---

## Universal false-positive list — do NOT flag

These apply across every pack and every overlay:

- **CI-caught issues**: lint, typecheck, formatting, missing imports, broken tests, prettier nits.
- **Pre-existing issues** on lines the PR didn't touch.
- **Pedantic style** not explicitly called out by a pack or overlay.
- **General security / test-coverage / docs gaps** not tied to a specific rule.
- **Intentional functional changes** that match the PR's stated purpose.
- **Issues silenced by a deliberate ignore comment** (`lint-disable`, `ts-expect-error` with context).
- **Stylistic preferences** — Alex doesn't want "I'd name this differently" findings.
- **Backwards-compat scaffolding deletions** — if the PR removes `_var` renames or `// removed` comments, that matches CONVENTIONS; don't ask to keep it.

Each pack may add its own false-positive list for its domain.

---

## Voice for posted comments

When a finding gets posted to GitHub:

- One or two sentences. The diff explains the *what* — focus on *why this matters*.
- No emojis.
- No throat-clearing ("Great work, but…", "Nit:"). State the finding directly.
- Cite the rule when invoking one: `agent_docs/08-review-rules.md` § "<section>", `overlays/curri.md` § "<section>", etc.
- Suggest a fix when it's a clear one-liner. Skip the suggestion if the right fix needs context not in the diff.
- Permalink to code with the head commit's full SHA, never a branch name.

---

## How packs and overlays compose

1. **Core** (this file) is always loaded.
2. **Always-on packs** run on every PR: `security`, `correctness`, `conventions`, `maintainability`, `performance`.
3. **Gated packs** run only when changed files match their triggers: `db`, `api`, `ui`, `tests`. Triggers are listed at the top of each pack.
4. **Overlays** (under `overlays/`) declare `applies_when` in their frontmatter. The skill checks the current repo and loads any matching overlay. Overlays *augment* or *override* specific pack rules — they never replace the core.

When an overlay rule and a pack rule conflict, the overlay wins (overlays are repo-specific intent).
