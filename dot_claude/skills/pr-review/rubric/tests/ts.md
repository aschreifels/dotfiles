# Rubric — Tests (TypeScript / JavaScript — Jest / Vitest / Mocha)

Loaded when the diff touches `.ts` / `.tsx` / `.js` / `.jsx` test files. Builds on [_shared.md](_shared.md).

---

## Blockers

### Async test that doesn't await the assertion

```ts
test("creates order", () => {
  createOrder(input);            // returns a promise — not awaited
  expect(db.orders.length).toBe(1);   // runs before createOrder resolves
});
```

The test passes for the wrong reason. Always `async/await` or return the promise.

### `forEach(async ...)` in test bodies

Same root cause as the production rule: fire-and-forget. The test ends before the async work resolves, and assertions may not run.

### `jest.mock` of a module that's the subject of the test

```ts
jest.mock("./order-service");
import { createOrder } from "./order-service";

test("createOrder works", () => {
  createOrder(input);   // the mocked version, not the real one
});
```

---

## High

### `expect.assertions(n)` missing on an async test that branches

When a test has conditional `expect` calls inside async control flow, `expect.assertions(n)` is the only way to verify all expected assertions ran. Worth requesting on complex async tests.

### `jest.useFakeTimers` set up without teardown

Fake timers leak into subsequent tests and cause flakes far from the cause. Pair with `jest.useRealTimers()` in `afterEach`.

### Snapshot of an entire component tree

Brittle on every styling tweak. Prefer asserting on the few elements that matter.

### Manual mocking of Prisma in an integration-style test (Curri)

Curri integration tests hit a real DB via `rush docker:services:start`. Mocking Prisma in a test that's structurally integration-style → flag.

---

## Medium

### `describe` block with one `it`

The wrapping `describe` adds no value. Inline the test.

### `beforeAll` that mutates module-level state

State leaks across tests in the file. Prefer `beforeEach` unless the setup is genuinely expensive.

### `as any` in a test to satisfy a type

Often masks a real shape mismatch. Suggest a typed fixture builder instead.

---

## Low

- Test file naming inconsistency in a directory that's otherwise uniform.
- Importing the testing framework when globals are configured.
- `it.only` / `describe.only` / `test.only` left in committed code (CI catches this — see false positives).

---

## Do NOT flag

- `it.only` left in code — CI's `--forbid-only` flag catches it; don't duplicate.
- `any` in test fixtures clearly typed as "shape doesn't matter."
- Style of `expect(...).toEqual` vs `toStrictEqual` unless the test would pass on the wrong value with the looser variant.
- Mocking external HTTP (axios, fetch) — that's correct, not a smell.
