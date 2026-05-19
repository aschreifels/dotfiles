# Rubric — Tests (gated)

**Triggers:** changes to `*.test.*` / `*.spec.*` / `__tests__/` / `e2e/` / `cypress/` / `playwright/`. Also runs when the PR's stated purpose is a **bug fix** — Alex's CONVENTIONS require a failing test first.

---

## Blockers

### Bug fix with no regression test

If the PR description / branch / commits indicate a bug fix and there's no new test that would have failed before the fix — flag. Per `~/.config/ai/CONVENTIONS.md`: "Write a failing test before fixing a bug when test infrastructure exists."

Exception: the codebase has no test infrastructure for that area (verify by looking for sibling tests). Mention it but don't block.

### Test that mocks the thing under test

A test of function `f` where `f` itself is mocked, or where the only assertion is on the mock's behaviour. The test is asserting on the test setup, not on the code.

### Deleted test coverage without a replacement

A test file or test case removed in a PR that doesn't appear to obsolete the behaviour — verify the behaviour is still covered elsewhere or flag.

---

## High

### Mock that hides real behaviour

- A mocked DB in an integration test where Alex's CONVENTIONS prefer real DB ("integration tests must hit a real database").
- A mock that returns canned data the real call never would (e.g., always-truthy `isAuthorized` mock).
- A spy on a private method whose existence isn't part of the public contract.

### Brittle assertion

- Snapshot of a large object with no clear behavioural intent.
- Asserting on log strings character-for-character.
- Asserting on date / timestamp values without a clock fix.

### Missing assertion

A test that calls the function and stops — no `expect`. Often happens when async without `await` resolves before the test ends.

---

## Medium

- Test name that doesn't describe the behaviour ("works", "test 1", "happy path" with no detail).
- Setup duplicated across many tests where a `beforeEach` or fixture helper would clarify.
- Test order dependence — tests pass when run together but fail when run alone.

---

## Do NOT flag

- "Could use more edge cases" without naming one.
- Coverage-percentage observations.
- Snapshot tests that are clearly intentional for the surface (e.g., generated output stability).
- Style of testing library calls (`expect(x).toBe(y)` vs `assert.equal`).

---

## Voice

When flagging a missing regression test for a bug fix, point to the file the test should live in and sketch the assertion in one line.
