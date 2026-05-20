# Rubric — Correctness (TypeScript / JavaScript / Node)

Loaded when the diff touches `.ts` / `.tsx` / `.js` / `.jsx` / `.mjs` / `.cjs`. Builds on [_shared.md](_shared.md).

---

## Blockers

### Forgotten `await`

```ts
// BLOCK — fire-and-forget, next line uses stale state
saveOrder(order);
return order;
```

If the surrounding code expects the operation to complete before the next line, the missing `await` is a Blocker.

### `forEach(async ...)` where ordering / completion matters

```ts
// BLOCK — fire-and-forget; outer scope continues immediately
items.forEach(async (i) => { await persist(i); });
return "done";
```

If the caller depends on completion, switch to `for...of` (sequential) or `Promise.all(items.map(...))` (parallel, ok when writes don't overlap).

### Non-null assertion (`!`) where the array can be empty

```ts
const user = users.find((u) => u.id === id)!;
```

Blocker when `users` can be empty and the consumer dereferences `user` without checking.

### Promise constructor swallowing throws

```ts
new Promise((resolve, reject) => {
  doSync(); // if this throws, nothing catches it
  resolve();
});
```

Throws inside the executor are not caught by `.catch`. Wrap the body in try/catch and call `reject`.

---

## High

### Optional chain followed by a call that explodes if it resolved undefined

```ts
const result = maybe?.compute();
result.toString(); // crashes when maybe was undefined
```

### `JSON.parse` on a field that may be missing / malformed

Without a try/catch, this turns a malformed payload into an unhandled exception. A crash in a request handler is a denial-of-service primitive.

### `Promise.all` with writes to overlapping rows / keys

When two parallel branches both write to the same resource, last-writer-wins silently. Sequence them (`for...of` + `await`) or shard by key.

### Pino log level misuse (Curri context, Node ecosystem)

- `logger.error` for expected business outcomes → should be `logger.warn`.
- New `error`-level logs for control flow.

Always include IDs in the log object: `{ deliveryId, jobId, userId }`.

### `Date` arithmetic without timezone

`new Date().getHours()` in a service that runs in UTC but reasons about user local time. Use `date-fns-tz` / `Temporal` (when available) / explicit IANA zone strings.

---

## Medium

### Mutating an input parameter

```ts
function attachMeta(order: Order) {
  order.processedAt = new Date(); // caller may not expect this
  return order;
}
```

Prefer `return { ...order, processedAt: new Date() }`.

### `as` cast that crosses a trust boundary

```ts
const body = req.body as CreateOrderInput;
```

If the input isn't parsed through a runtime validator (Zod, Joi, etc.) first, the cast is wishful thinking. Flag as Medium; promote to High if the body is then used in a DB write.

### Conditional `await` in a loop hiding sequential work

```ts
for (const item of items) {
  if (item.needsCheck) await verify(item);
}
```

Often fine, but worth verifying it isn't an N+1 in disguise (see `db/ts.md`).

---

## Low

- `console.log` left in committed code (pino / structured logger is the convention).
- Unused `async` keyword on a function that never `await`s.
- `try/catch` that re-throws unchanged — drop the wrapper.

---

## Do NOT flag

- `as` casts inside `*.test.*` for fixture shaping.
- Optional chaining on results from typed ORM queries that the type system already narrows.
- `Date` arithmetic in scripts/CLIs running in a fixed environment.
- Defensive `?? defaultValue` on optional fields with sensible defaults.
