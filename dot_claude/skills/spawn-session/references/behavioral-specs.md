# Behavioral specs (Phase 7)

The closing bookend to contracts-first: contracts open the session by defining the
seams; behavioral specs close it by proving the promised behavior holds under
prod-shaped conditions. Part of **every** session, sized to the session.

## What makes a spec "behavioral"

It's the shape of the test, not the runner:

- **Multi-step interaction, driven the way prod drives it** — an actor performs the
  feature's flow (create → act → advance → observe), not a function called with a
  fixture. For bug fixes, the fixed path exercised end-to-end, generalizing the
  failing-test-first repro.
- **Real resources** — real datastores (Postgres/Redis/etc.) at minimum; real service
  seams to the **edge of the packages**. Mock only beyond the repo boundary (external
  SaaS, third-party APIs). No browser required — this tier stops at the package edge,
  below e2e.
- **Asserts observable behavior at the seams the contracts defined** — API responses,
  persisted state, emitted events; the contracts' *Invariants* sections are the
  checklist. Never asserts implementation details.
- **Pins behavior we commit to maintaining.** These are keepers: committed with the
  PR, run in CI, maintained like production code — because they are the executable
  statement of what the feature promises.

## Hard requirements

1. **CI-runnable.** A spec that only runs against a hand-booted local stack will rot
   within a month. If the substrate can't run it in CI, either fix the substrate or
   pick a substrate that can — "runs on my machine" specs don't count as landed.
2. **Deterministic.** No sleeps-and-hope; wait on observable state. A flaky behavioral
   spec is worse than none — it trains people to ignore the tier.
3. **Cheap enough to keep.** Prefer extending an existing scenario/suite over
   authoring new harness machinery. Small sessions might add three assertions to an
   existing flow; that's a complete behavioral pass.

## The substrate (per-project, recorded once)

The skill is project-agnostic; the substrate isn't. At Phase 7:

1. **Look up the recorded substrate** — query the KB (`qmd query "<project> behavioral
   test substrate"`) and check the project's agent docs for a testing guide.
2. **If found:** use it. The spec brief names it; specs land where that suite lives.
3. **If absent:** hardening a substrate **with the user** is a first-class deliverable
   of this session — pick the lightest existing layer that satisfies the hard
   requirements (real datastores, package-edge seams, CI-runnable), or extend one
   until it does. Afterward, record the decision: KB for the reusable reasoning,
   project agent docs for the how-to. Future sessions inherit it; the tier gets
   cheaper every session that feeds it.

Substrate selection guidance: prefer an in-process harness with real datastores over
a boot-the-stack HTTP framework when the feature's edge is the API; escalate to the
heavier actor/scenario framework only when the behavior genuinely crosses service
boundaries (workers, event buses, webhooks). Heaviness is usually a bootstrapping
cost — the per-session spec habit is exactly what amortizes it.

**Framework vs. runtime — record both, couple specs only to the first.** The
*framework* is what specs are written in (harness, actor SDK) and what CI must be able
to execute — spec code targets it and takes endpoints/connection info as config, never
hardcoded. The *runtime* is where a session actually runs the suites: if the project
has a per-worktree stack tool (isolated per-branch DB/services, one-shot command
execution inside the stack), use it — it removes cross-session contention from the
serialized-ops lane, and a fast DB-reset-from-template primitive gives prod-shaped
specs (no transaction rollback) a clean-slate determinism story. The substrate record
names both halves; a spec that only runs under the local runtime and not in CI still
fails the CI-runnable requirement.

## Who writes the specs

- **Default:** a dedicated Sonnet spec agent with an orchestrator-written brief.
  Spec-writing is well-bounded work once the brief carries the contracts.
- **Inline** for small sessions (extending an existing scenario) or when the substrate
  is being hardened for the first time (that's judgment work — keep it with the
  orchestrator + user).
- **Review bar: the highest of the session.** A wrong behavioral spec pins wrong
  behavior and outlives the session. The orchestrator reviews the spec diff against
  the contracts' invariants line by line; when in doubt, surface the spec's assertion
  list to the user before accepting.

## Spec-agent brief template

Template resolution: `{kb.root}/templates/dossier/spec-brief.md` first (user-editable),
this packaged copy as fallback. Same standing constraints as any executor brief
(worktree path, no gen/lockfile/migrations/commits, report format), plus:

```markdown
# Chunk S: behavioral specs — {feature-name}

## What to pin

For each contract, the invariants to prove:
- {worktree}/_plan/contracts/{seam}.md — Invariants section is your assertion list
- Happy path(s): {enumerate the prod-shaped flows, step by step}
- {For bug sessions: the fixed path — generalize the repro test at
  {path-to-failing-test}}

## Substrate

- Framework/harness: {name + entry point, e.g. the project's integration harness}
- Example to imitate: {path to an existing spec of the right shape}
- Where specs live: {directory, per the project's test-layout conventions}
- Runner: {command} — must pass locally against `{services-up command}` and be picked
  up by CI

## Rules

- Real datastores; mock only beyond the repo boundary.
- Assert observable outcomes (responses, persisted state, emitted events) — never
  internals.
- Deterministic waits only.
- Extend existing scenarios where one covers adjacent flow; create new files only
  when no scenario fits.
```
