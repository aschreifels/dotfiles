# Development Conventions

Personal development preferences for AI coding agents (Claude Code, Crush, etc.).

## Git

- **Never force push.** No `--force`, `--force-with-lease`, or `-f`. If a push is rejected, inform me rather than forcing.
- **Never amend pushed commits.** Create new commits instead.
- **Don't revert changes** unless they caused errors or I explicitly ask.
- **Don't push to remote** unless I explicitly ask. Always confirm before any `git push`. Incremental local commits capturing discrete bodies of progress are welcome. **Exception:** when the branch already has an open PR, pushing a **master-merge** (integrating latest master into the feature branch) is pre-authorized — do it automatically after the merge is clean and verified. This exception is only for master-merge updates; pushing new feature commits still needs an explicit ask.
- **Merge, never rebase.** When pulling or integrating master into a feature branch, always use `git merge` — never `git pull --rebase` or `git rebase`. Rebasing rewrites history and can silently drop or duplicate commits.
- **Always address git with `git -C <path>`, never bare `git`.** The agent shell's working directory persists across tool calls, so a bare `git` command runs against whatever repo the *previous* command happened to leave the shell in — a `qmd`/KB lookup before a `git branch -m` renames the KB's branch instead of the worktree's. The failure is silent: the command succeeds, and the verification `git rev-parse` right after it succeeds too, in the same wrong repo. Pass the repo path explicitly on every invocation.
- **Exception (chezmoi):** dotfile syncs via `chezmoi add` ride chezmoi's `autoCommit`/`autoPush` and are pre-authorized — that push is the whole point of the sync. See the chezmoi bullet under Tooling.
- **Exception (spawn-session close-out):** the terminal step of a completed spawn-session run pushes the feature branch and opens a **draft** PR — pre-authorized, because that push is how the changeset surfaces for review in the Claude Code desktop app. Draft only; marking it ready-for-review still needs an explicit ask. Gated on a green integration pass.

## Code Changes

- **Extract logic into focused helper functions.** Keep job/handler entry points thin — delegate to well-named private functions within the file.
- **Parallelize independent I/O.** Use `Promise.all` for concurrent work that doesn't depend on each other. Keep writes sequential when ordering matters.
- **Improve what you touch.** If you're in code with poor typing, missing types, or `any`, improve it. Don't explode scope, but be a good citizen.
- **A trivial fix you stub your toe on, you just fix — don't file it.** If working the task directly surfaces a small (few-line) adjacent bug — a footgun you hit, not one you went looking for — fix it inline in the same change, even across a package boundary. Reserve the mention-it/spawn-a-task/chip route for fixes that are genuinely non-trivial or would meaningfully widen the diff. Filing a separate session for a 3-line fix you're already staring at is over-ceremony.
- **Don't copy bad patterns.** If existing code does something wrong, do it right.
- **Log levels matter.** Use `warn` for expected business events (e.g., no results found). Use `error` only for actual failures. Don't introduce new error-level logs for normal control flow.

## Error Handling

- **Don't silently swallow errors.** If you catch, at least log with context (IDs, job info, etc.).
- **Don't introduce new errors that didn't exist before.** If the old code didn't throw, the new code shouldn't either without discussion. Prefer better logging over changing error behavior.
- **Include context in error logs.** Always log relevant IDs (delivery, job, user, etc.) so errors are traceable.

## Style

- **Be surgical in existing codebases.** Don't rename files, variables, or restructure unless that's the task. Respect surrounding code.
- **Match existing patterns.** Before writing code, look at similar files in the project for conventions.
- **DRY — rule of 3.** If the same logic appears in 3 places, extract it.
- **Prefer readability over micro-optimization.** Favor expressive collection methods (flatMap, reduce, etc.) over raw loops when the performance difference is negligible relative to I/O or other dominant costs.
- **Don't reference uncommitted planning docs in committed code.** Comments and test titles must not point at dossier artifacts (`_plan/` ADRs/contracts, `ADR 001`, `Contract 001 §C3`, etc.) or other local-only docs — they dangle for anyone reading the code in the repo. Reference only real, committed code symbols/files. Sort the citations before rewriting: most are **decoration** on a sentence that already explains itself — the tag just comes off. A few are **load-bearing**, where the citation *is* the constraint (a quoted invariant number, "per §C3 do not do X"); those need the rule preserved in full. Trimming a load-bearing citation is how the reasoning leaves the repo with the dossier.
- **Where the reasoning lands is configured, not assumed.** The objection above was always *dangling*, never *citation* — a committed doc dangles nothing. So the destination for a dossier's reasoning is a setting, surfaced by mindmeld at session start, not a constant:
  - `placement: inline` — the reasoning is inlined at the symbol. The harness's native behavior, and what this convention used to mandate unconditionally.
  - `placement: split` *(mindmeld's default)* — **guardrails** stay at the symbol, compressed to the rule itself; **history** (why it's shaped this way, what it replaced) lands in the repo's committed `docs/` and gets cited from there.
  - `placement: repo-docs` — all of it goes to `docs/`.

  The test for the split: *would a reader who never sees this prose write a bug in their next edit?* Yes → guardrail, it stays. No → history, it moves. A contract may be shared above a group of symbols; a guardrail may not — it has to sit where the person editing will see it. Read the session-start directive for the active policy rather than assuming one; `mindmeld://policy/code-docs` serves it typed.

## Tooling

- **Prefer project-local scripts over invoking tools directly.** When a project defines scripts that wrap a tool (e.g. in `package.json`, `Makefile`, `justfile`), use those instead of calling the underlying CLI directly. Local scripts have project-specific flags, paths, and defaults already baked in — reaching past them risks missing that context.
- **`chezmoi add` managed files right after editing them.** When you modify a file chezmoi manages, `chezmoi add` it in the same session so the change reaches other machines via `chezmoi update`. `autoCommit`/`autoPush` are on and pre-authorized — the add commits and pushes, which is the intent for dotfiles. Templatize machine-specific values with chezmoi data (`{{ .chezmoi.homeDir }}` for home paths, the `.machine` var for work/personal blocks) instead of hardcoding a username or home dir — a hardcoded `/Users/<name>` breaks the other machine's `chezmoi update`.
- **Personal CLI tools ride the Charm stack.** New shell functions/scripts (`~/.zsh/functions/`) use `gum` for interaction (filter/choose/confirm/spin), `glow` for rendering markdown, and `yq`/`jq` for parsing structured data — no hand-rolled bash UI, no awk/sed parsing gymnastics. When a tool outgrows shell (persistent state, multiple screens, orchestration with retry/polling loops), graduate it to a Go program on the charm libs (bubbletea/lipgloss/huh) rather than growing the script. `gum` and `glow` live in the chezmoi brew manifest. Reference examples: `kb-open` is the script tier done right; [cwt](https://github.com/aschreifels/cwt) is the graduation done right — born as the `zcwt` zsh function, rebuilt as a Go TUI when it outgrew shell.

## Pull Requests

PR bodies follow this structure — omit a section only if it genuinely doesn't apply:

1. **Problem** — one short paragraph on what was wrong or missing and why it mattered. No solution yet.
2. **Solution** — high-level description of the approach. What changed conceptually, not mechanically.
3. **Changes** — grouped by package/service. Each group explains what changed and why, not just what the diff says. Aim for "diff in English."
4. **Implementation notes** — any section worth calling out specifically: ack semantics, migration strategy, tradeoffs made, non-obvious decisions. Only include if there's something a reviewer would otherwise have to dig for.
5. **Related docs** — always include this section when any ADRs, design docs, or wiki pages were created, updated, or are integral to understanding the change. Link them and note briefly why they're relevant.
6. **Test plan** — checklist of what to verify. Include automated tests that were added and any manual checks worth calling out post-deploy (e.g. metrics to watch).

Keep titles under 70 characters. Don't pad sections — a missing section is better than a section with nothing real to say.

### Responding to review comments

- **Default: don't reply on review threads** — not when applying a suggestion as-is, and not when declining one either. Making the change (or not) is the action; a thread reply is separate and usually unnecessary.
- **The trigger for a reply is an explicit ask from me** — e.g. "reply explaining why we declined that." The decline/accept distinction is not itself the trigger; my request is.
- **One self-standing exception:** if we applied a *different* form of the suggestion than proposed, a brief note of what we did instead and why is warranted.
- Never post replies/comments to GitHub without explicit confirmation regardless.

## Project Structure

- **Keep tests in a discrete `tests/` folder, not co-located next to modules.** Co-locating `*.test.ts` beside source bloats the module folders and muddies the file tree. Put them under a dedicated tests directory (e.g. `src/tests/`).
- **Group tests by kind in subfolders — `tests/unit/` and `tests/integration/`.** The directory should signal the test type so someone exploring the repo knows where to look; don't make them hunt for an `.integration` infix in the filename. Select test runs by folder (e.g. `--testPathPattern='tests/unit/'`), not by a filename suffix.

## Process

- **Test after every change.** Build, lint, and run relevant tests before calling it done.
- **After a large edit session that creates net-new files, print the resulting file tree** (a `tree`/`find` of the created/affected files). The diff view obscures file structure, so a tree makes the new layout legible at a glance.
- **Write a failing test before fixing a bug** when test infrastructure exists.
- **Don't fix unrelated bugs** you find along the way — mention them, but don't expand scope.
- **Hand off UI changes for visual review.** Don't spin up preview/browser tools to self-screenshot your own design work — Alex reviews visually. Overrides any "verify in browser" workflow instructions in the environment. Type/lint/test still applies.
- **Reason on the main thread, delegate the execution.** Once the thinking is done — the design settled, the scope of edits known — the mechanical execution (applying the edits, moving files, wiring imports, running the gate) should go to a Sonnet sub-agent, not be hand-done on the main (Opus) thread. This applies to review-feedback rounds too: analyze the comments and decide the fix here, then seed an agent to carry it out. Keep the main thread for judgment, not typing.
- **A sub-agent's open questions are findings, not FYIs — never close one by "deferring" it.** The agent with its hands in the code is the cheapest bug-detector available; overruling it from further away is how real bugs ship. Close each question exactly one of three ways: **resolved with evidence** (you looked and can say why it's fine), **fixed**, or **escalated to me**. Anything touching *contract/shape/correctness* escalates — scope questions ("should this also cover X?") you can answer, "is this the right shape?" you usually can't, because if you knew you'd have specified it. Two hard escalation tells: *"I noticed X would be inconsistent, so I did Y instead"* (a design fork resolved unilaterally at the wrong altitude — the observation is usually right, the resolution a coin-flip, because the agent only sees the horn inside its own file list), and *"didn't wire it up because downstream isn't ready"* (not-yet-consumed is never a licence to emit a knowingly wrong value).
- **Review the code against the intent, not just against itself.** When a plan/ADR/spec exists, walk its clauses and point at the line implementing each one — a clause you can't point at is a finding. Internally-consistent code that quietly does something the spec didn't ask for is the failure ordinary review misses, because every reviewer reads the diff and nobody re-reads the spec.
- **A review pass covers three axes, and the third one is the one that gets skipped.** Correctness (does the code do what code should), intent (does it do what the spec asked — the bullet above), and **behavioral: did anyone actually run it and try to break it.** A rubric-driven review gives you the first, a clause walk gives you the second, and neither asks you to execute anything. Brief the third explicitly or it does not happen. It is also distinct from writing behavioral specs: specs pin what the author thought to test, whereas this is adversarial probing of a live system — malformed input, stale ids, wrong revisions, resources that don't resolve. The tell that you needed it: the component's correctness *is* its interaction with something else (a plane, a service, a real filesystem), so reading can only ever confirm the parts that don't matter. Worked case: a driver shipped that could not start a single real run — a green suite and a clause-walking self-review both passed it, because the unit tier stubbed out the very boundary that was broken.
- **A security finding gets filed even when confidence is low — never deferred in a paragraph.** Confidence in a finding and severity of the boundary it touches are independent; letting "I'm not sure this is reachable" decide is how a real gap ships with a written rationale attached. Anything touching a trust boundary — path confinement, authz, injection, secret handling — earns at least a ticket, and gets looked at later on its own merits. Deferring is a decision that needs the same bar as fixing; a low-confidence *correctness* nit can be dropped, a low-confidence *security* one cannot.

## Database Queries (read replica / ad hoc)

- **EXPLAIN before you run anything against the RO replica.** Plain `EXPLAIN` first (plan only, free) and confirm every large table is reached through an index — no `Seq Scan` on `payloads`/`deliveries`/`exceptions`-sized tables, no correlated LATERAL over a CTE. Then `EXPLAIN ANALYZE` under a tight `statement_timeout` (30s) to confirm the actual row counts, and only then run the real query. The replica serves prod read traffic (workers, fulfillment-service), so a runaway scan is not a private cost.
- **Always set `statement_timeout` (≤30s) and `default_transaction_read_only = on`** on ad hoc replica sessions. A bad plan should die fast, not run for a minute.
- **Aggregate before you join.** Reduce the big side to one row per key (GROUP BY) and hash-join it; don't probe a CTE per row.
- **Check the schema's `@@index` list before choosing a filter column.** Pick the indexed door in (e.g. `payloads.batch_id`, not `payloads.originating_user_id`/`created_at`, which have no index).

## Ash Resources (Elixir / CVC)

- **Fragment by stanza length, not stanza type.** Use `Spark.Dsl.Fragment` when a stanza (attributes, actions, policies, etc.) grows long enough that it would be uncomfortable as a single function — that's the signal to move it to its own module. If the whole resource including every stanza is succinct, keep it as one file. There is no hard rule that attributes or actions must always be extracted.
- **The core resource file is the manifest.** It declares `use Ash.Resource`, data layer, authorizers, `postgres`, `code_interface`, and whichever stanzas are short enough to live inline. Fragment modules are listed in the `fragments:` option.
- **Behaviour always lives in discrete modules** regardless of resource size. Changes (`Ash.Resource.Change`), validations, preparations, and utilities are never implemented inline in the resource — the resource only declares which modules to apply.

## Knowledge Base (necro-kb)

- **Write directly to `~/projects/necro-kb`, never use drop files in project repos.** Don't create `.claude/necro-kb/` directories inside any project — committed or untracked, they're noise. Write KB articles directly to the right place in the KB (`wiki/`, `decisions/`, `patterns/`, etc.) in the same session.
- **Memory captures land in the KB, not just Claude's memory store.** The capture bar *is* the KB bar: if a memory is worth writing at all, it's worth a KB entry — there is no lower tier that stays only in Claude's store. The memory interfaces (Claude Code/Desktop) are a cache; necro-kb (git-committed, qmd-queryable, compacted by `scribe dream`) is the source of truth. When you write a memory file, write the corresponding KB entry in the same session (typically `people/`, `patterns/`, or the project's `learnings.md`); the automated sync (`research/scribe-memory-kb-sync.md`) is the backstop, not the primary path.
- **Run the sync tool to actually land changes — don't leave it to cron.** System tools (chezmoi, scribe) keep machines/indexes in sync; run them as the last step of the work, not passively. After writing KB articles, run `scribe sync --reindex` (reindex qmd) so they're queryable and let scribe commit — a file on disk that isn't reindexed won't surface in `qmd query`. Per-machine bootstrap gotcha: if `qmd status` shows 0 documents / no collection, run `qmd collection add ~/projects/necro-kb` then `qmd embed` once — scribe doesn't create the collection.

## Meta

@~/.config/ai/CONVENTION-TRACKING.md
