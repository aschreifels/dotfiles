# Rubric — Performance (shared, non-DB, language-agnostic)

DB perf lives in [../db.md](../db.md). Language-specific footguns (event loop, GIL, goroutine leaks, etc.) live in sibling files.

---

## Blockers

### Unbounded memory growth

- A `Map` / `Set` / dict / cache written to but never bounded or evicted, with keys that grow with traffic.
- An array accumulated in module-scope state across requests.
- A streaming consumer that buffers the entire stream into memory before processing.

### Synchronous work blocking concurrency primitives

The shape depends on the runtime (event loop, GIL, fiber scheduler, etc.) — see language-specific files. The pattern is: a single long-running synchronous operation in a code path that's expected to be concurrent / responsive.

---

## High

### N-of-something hidden behind parallelism

`Promise.all(items.map(callExternalApi))`, `asyncio.gather(*[fetch(i) for i in items])`, etc. Concurrent ≠ free — if N grows with input, this is a rate-limit / quota problem. Look for a batch endpoint on the upstream API.

(For DB-specific N+1, see [../db.md](../db.md).)

### Missing pagination on a non-DB endpoint

An API returning "everything matching X" with no `limit` / `cursor`. Even if the underlying query is fine, the wire payload is the concern.

### Repeated work that should be memoized

The same expensive computation called inside a render loop, hot request path, or worker tick — with stable inputs and no memoization. Be conservative: confirm it's hot.

---

## Medium

- Encoding/decoding round-trips that cancel out (`parse(stringify(x))` as a clone — suggest `structuredClone` / equivalent).
- `Array.from(new Set(...))` over a large array when a single pass would do.
- Concatenating into a large string with `+=` in a tight loop.

---

## Do NOT flag

- Micro-optimizations without a measured hot path.
- "O(n) instead of O(n log n)" on small fixed-size inputs.
- Memoization opportunities on already-cheap operations.
- Style choices that *look* slow but compile to the same code.

---

## Suggested-fix style

Name the trigger (input size, request rate, deployment context). "This is slow when X" is useful; "this is slow" is not.
