# Rubric — Maintainability (always-on)

Long-tail health of the codebase: duplication, dead code, premature abstraction, sprawl. Runs on every PR.

---

## High

### Function doing two unrelated things

A function that mixes I/O + business logic + formatting, where the next reader will struggle to figure out the seam. Flag when the responsibilities have clearly distinct callers or test surfaces.

### Premature abstraction

A new interface / generic / factory with exactly one implementation, no clear second caller in sight. Three similar lines is better than a wrong abstraction. Flag as `M` with a "inline this for now" suggestion.

### Half-finished implementation

New code paths that throw `NotImplementedError`, return `null` with a `// TODO`, or short-circuit with a comment. If the PR claims to ship the feature, this is `H`. If the PR's stated scope explicitly says "scaffolding only", drop to `M`.

---

## Medium

### Dead code introduced

A new helper that no caller uses. Unused exports. New constants no one references. Flag the *new* dead code — don't drag in pre-existing.

### Copy-paste of a known bad pattern

Code that looks like neighbouring code, where the neighbouring code is something the team has agreed to migrate away from. Flag with a pointer to the better pattern.

### Comment that explains *what* instead of *why*

```ts
// Increments counter
counter++;
```

Default position: delete these. Alex's CONVENTIONS: "Don't explain WHAT the code does." Flag as `L`.

---

## Low

- Long parameter list (> 5 positional) where an options object would help.
- Single-letter variable name in a non-trivial scope.
- Inconsistent ordering of similar fields across two adjacent definitions.

---

## Do NOT flag

- "I would have structured this differently" without a concrete rule or recurring pattern violation.
- Functions over N lines as a hard threshold — measure complexity, not length.
- Pre-existing dead code that the PR didn't introduce.
- Comments the author wrote to explain a non-obvious *why* — those are exactly the comments to keep.

---

## Spawn-task signal

If you find a meaningful but out-of-scope cleanup (dead config option, stale README badge, real `TODO` worth filing), mention it as a `Q` in the review with the note "out of scope; worth a separate cleanup." Do not pad the review with these.
