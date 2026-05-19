# Rubric — Performance (always-on, non-DB)

Performance issues *outside* the database. DB perf lives in [db.md](db.md).

---

## Blockers

### Sync work blocking the event loop

- `JSON.parse` on a multi-MB payload inside a request handler with no streaming.
- Synchronous crypto (`crypto.scryptSync`) in a hot path.
- Large in-memory transforms on user-provided sizes (`array.map(...).filter(...).reduce(...)` over unbounded input).

### Unbounded memory growth

- A `Map` / `Set` / cache that's written to but never bounded or evicted, with keys that grow with traffic.
- Accumulating an array across requests in module-scope state.

---

## High

### Promise.all hiding N-of-something

Concurrent ≠ free. `Promise.all(items.map(callExternalApi))` is N parallel calls — if N grows with input, this is a rate-limit / quota problem. If the external API has a batch endpoint, flag.

(For DB-specific N+1, see [db.md](db.md).)

### Missing pagination on a non-DB endpoint

API endpoint that returns "everything matching X" without `limit` / `cursor`. Flag even if the underlying query is fine — the wire payload is the concern.

### Repeated work that should be memoized

The same expensive computation inside a render loop, hot request path, or worker tick — with stable inputs and no memoization.

---

## Medium

- Regex compiled inside a hot function (move to module scope).
- `Array.from(new Set(...))` over a large array when a single pass would do.
- Encoding/decoding round-trips that cancel out (`JSON.parse(JSON.stringify(x))` as a clone — flag, suggest `structuredClone`).

---

## Do NOT flag

- Micro-optimizations without a measured hot path.
- "This could be O(n) instead of O(n log n)" on small fixed-size inputs.
- Memoization opportunities on already-cheap operations.
- Style choices that *look* slow but compile to the same code (`map`/`filter`/`reduce` vs explicit loops).

---

## Suggested-fix style

If you flag a performance issue, name the trigger (input size, request rate, deployment context). "This is slow when X" is useful; "this is slow" is not.
