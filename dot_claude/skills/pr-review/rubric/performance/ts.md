# Rubric — Performance (TypeScript / JavaScript / Node)

Loaded when the diff touches `.ts` / `.tsx` / `.js` / `.jsx` / `.mjs` / `.cjs`. Builds on [_shared.md](_shared.md).

The dominant footgun in Node is **blocking the event loop**. Almost all language-specific findings here trace back to that.

---

## Blockers

### Sync work blocking the event loop

- `JSON.parse` on a multi-MB payload inside a request handler with no streaming.
- Synchronous crypto (`crypto.scryptSync`, `crypto.pbkdf2Sync`, large-key `createHmac` over big buffers) in a request path.
- `fs.readFileSync` / `fs.writeFileSync` in a hot path.
- `Buffer.alloc(n)` with caller-controlled `n` (memory amplification primitive).
- Heavy `array.map(...).filter(...).reduce(...)` chains over unbounded input.

### Module-scope state that accumulates across requests

```ts
const recentRequests: Request[] = [];   // grows forever
export function handler(req: Request) { recentRequests.push(req); ... }
```

Unbounded growth in a long-lived process. Blocker.

### Unawaited microtask flood

```ts
for (const item of stream) {
  process(item);   // returns a promise — fire-and-forget at unbounded fan-out
}
```

If `process` returns a promise and `stream` is large, this spawns N concurrent operations with no backpressure. Use `for await` or a bounded concurrency primitive (`p-limit`, etc.).

---

## High

### `Promise.all` over a large unbounded input

```ts
await Promise.all(rows.map(callApi));   // N concurrent calls
```

Use bounded concurrency when `rows` is large or external rate limits matter.

### Regex compiled inside a hot function

```ts
function isValid(s: string) {
  return /^[a-z0-9-]+$/.test(s);   // OK; literal is hoisted
}

function isValidDynamic(s: string, pat: string) {
  return new RegExp(pat).test(s);   // compiled every call — move to module scope or cache
}
```

### Large object spread in a render path (React/JSX)

`<Component {...hugeObject} />` re-creates the props object every render and invalidates downstream memoization.

### Context value as a fresh object literal each render

```tsx
<Ctx.Provider value={{ user, settings }}>   // new object every render
```

Forces all consumers to re-render. Wrap in `useMemo`.

---

## Medium

### `JSON.parse(JSON.stringify(x))` as a clone

Suggest `structuredClone(x)` (Node 17+).

### `Array.prototype.indexOf` on a hot lookup

If the array is large and queried in a loop, switch to `Set` for O(1) lookups.

### Awaiting independent promises sequentially

```ts
const a = await fetchA();
const b = await fetchB();   // no dependency on a
```

Use `const [a, b] = await Promise.all([fetchA(), fetchB()])`. (Curri-relevant: Alex's CONVENTIONS say "Parallelize independent I/O.")

---

## Low

- Repeated `Date.now()` calls in a hot loop where one snapshot would do.
- `console.log` in a hot path (synchronous on TTY, async elsewhere — but cheap to remove).

---

## Do NOT flag

- `Promise.all` over small fixed arrays (config bootstrapping, etc.).
- `JSON.parse` on a known-small payload from a typed source.
- Re-render concerns on leaf components that don't re-render often.
- `useMemo` / `useCallback` *removed* where the previous use was cargo-culted (no measured benefit).
