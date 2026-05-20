# Rubric — Correctness (shared, language-agnostic)

Logic bugs, error handling, race conditions. Always loaded. Language-specific patterns (null/undefined, async, error idioms) live in sibling files (`ts.md`, etc.).

---

## Blockers

### Swallowed error in a side-effecting path

A `try/catch` (or equivalent) around code that mutates state, moves money, sends external requests, or writes to a queue — where the catch block does nothing or logs without re-raising / compensating.

If the catch is intentional, it must (a) log with context (IDs, operation name, error details) **and** (b) propagate or compensate. A bare `catch {}` over a side-effecting op is a Blocker regardless of language.

### Wrong condition / inverted logic

- A boolean condition flipped relative to the surrounding intent (`if (!user)` when context demands `if (user)`).
- A loop terminator that never fires under the new control flow.
- Off-by-one on a slice/range that affects observable output.

### Race conditions

- Read-modify-write on a shared row without a transaction, lock, or optimistic-concurrency check.
- Concurrent writes to overlapping keys / rows where ordering is required.
- Caches updated after the authoritative read returns, leaving a window where readers see stale data tied to a decision.

### Error log without context

```
// BLOCK
logger.error(err);

// OK
logger.error({ err, deliveryId, jobId }, "delivery dispatch failed");
```

Always include relevant IDs so errors are traceable. (Cross-references `~/.config/ai/CONVENTIONS.md` § "Error Handling".)

---

## High

### Log-level misuse

- `error` for expected business outcomes (no rows found, validation failed, feature disabled) — should be `warn` or `info`.
- New `error`-level logs introduced for normal control flow.

### Returning a non-uniform result type

A function that returns `User` in some branches and `null` / `undefined` / a default-shaped object in others, where callers don't disambiguate.

### Date/time math without timezone awareness

Arithmetic on dates that cross timezones (deliveries, schedules, business-day calculations) without an explicit timezone or library that handles DST.

### Numeric ops on currency without integer cents / Decimal

Floating-point arithmetic on monetary values. Cross-language footgun.

---

## Medium

- Returning `undefined` implicitly from some branches but a typed value from others.
- Mutating an input parameter that the caller is expected to keep using.
- Duplicating a small calculation in two places that drift independently.

---

## Do NOT flag

- Theoretical race conditions with no realistic trigger in the system as built.
- Missing exhaustive default cases when the type system enforces exhaustiveness.
- Defensive checks that duplicate framework guarantees (re-checking `req.user` after an auth middleware that already 401s).
- "What if the API returns null?" when the typed contract says it can't.

---

## Suggested-fix style

Prefer the smallest diff that's correct. Don't rewrite the function around the bug.
