# Rubric — Correctness (always-on)

Logic bugs, null/undefined handling, race conditions, error handling. Runs on every PR.

---

## Blockers

### Swallowed errors in code paths that mutate state or move money

```ts
// BLOCK if the operation has side effects and the failure is silent
try {
  await chargeCustomer(order);
} catch {
  // nothing
}
```

If the catch is intentional, it must (a) log with context (IDs, operation, error) and (b) propagate or compensate. A bare `catch {}` over a side-effecting op is a Blocker.

### Wrong condition / inverted logic

- `if (!user)` where the intent was clearly the opposite given surrounding code.
- Loop terminator that never fires (`while(true)` with no break path on the new control flow).
- Off-by-one on a slice/range that affects the produced output.

### Race conditions

- Read-modify-write on a shared row without a transaction, lock, or optimistic concurrency.
- `Promise.all` with writes to overlapping keys / rows where the spec requires ordering.
- Caches updated after the DB read returns, leaving a window where readers see stale data tied to an authoritative decision.

---

## High

### Null / undefined handling

- Optional-chained call followed by `.something()` that explodes if the chain returns undefined.
- `JSON.parse` on a field that may be missing, with no try/catch.
- `array.find(...)!` (non-null assertion) where the array can be empty.

### Async correctness

- Forgotten `await` on a promise whose resolution is required for the next line.
- `forEach(async ...)` (fire-and-forget that the surrounding code expects to be serial).
- Promise constructor swallowing throws (`new Promise(() => { throw ... })`).

### Error log without context

```ts
// Flag
logger.error(err);

// Better
logger.error({ err, deliveryId, jobId }, "delivery dispatch failed");
```

Per `~/.config/ai/CONVENTIONS.md`: always log relevant IDs so errors are traceable.

### Log level misuse

`error` for expected business outcomes (no rows found, validation failed) — should be `warn` or `info`. New `error`-level logs introduced for normal control flow are a High.

---

## Medium

- Function that returns `undefined` implicitly in some branches but a typed value in others.
- Date math without timezone handling on data that crosses timezones (deliveries, schedules).
- Numeric ops on currency without integer cents or a Decimal type.

---

## Do NOT flag

- Theoretical race conditions with no realistic trigger in the system as built.
- Missing exhaustive `default:` in a switch when the type is a closed enum and CI typechecks it.
- "What if the API returns null?" when the typed contract says it can't.
- Defensive checks that duplicate framework guarantees (e.g. re-checking `req.user` after auth middleware that already 401s).

---

## Suggested-fix style

If you propose a fix, prefer the smallest diff that's correct. Don't rewrite the function around the bug.
