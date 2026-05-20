# Rubric — Tests (shared, language-agnostic)

**Triggers:** changes to `*.test.*` / `*.spec.*` / `__tests__/` / `e2e/` / `cypress/` / `playwright/` / `tests/` / `test/`. Also runs when the PR's stated purpose is a **bug fix** — Alex's CONVENTIONS require a failing test first.

Language-specific idioms (Jest, pytest, go test, etc.) live in sibling files.

---

## Blockers

### Bug fix with no regression test

If the PR description / branch / commits indicate a bug fix and no new test would have failed before the fix — flag.

Per `~/.config/ai/CONVENTIONS.md`: "Write a failing test before fixing a bug when test infrastructure exists."

Exception: the codebase has no test infrastructure for that area. Verify by looking for sibling tests in the same directory; if there are none, mention it but don't block.

### Test mocks the thing under test

A test of function `f` where `f` itself is mocked, or where the only assertion is on the mock's behaviour. The test is asserting on the test setup, not on the code.

### Deleted test coverage without a replacement

A test file or test case removed in a PR that doesn't appear to obsolete the behaviour. Verify the behaviour is still covered elsewhere or flag.

---

## High

### Mock that hides real behaviour

- A mocked DB in an integration test where the codebase convention is real-DB integration. (Curri: integration tests must hit a real database — per CONVENTIONS feedback memory.)
- A mock that returns canned data the real call never would (e.g., always-truthy `isAuthorized`).
- A spy on a private method whose existence isn't part of the public contract.

### Brittle assertion

- Snapshot of a large object with no clear behavioural intent.
- Asserting on log strings character-for-character.
- Asserting on `Date` / timestamp values without a clock fix.
- Asserting on the *order* of an unordered collection.

### Missing assertion

A test that calls the code and stops with no `expect` / `assert`. Often happens when an async test returns before the assertion runs.

---

## Medium

- Test name that doesn't describe the behaviour ("works", "test 1", "happy path" with no detail).
- Setup duplicated across many tests where a fixture / `beforeEach` would clarify.
- Test-order dependence (passes when run together, fails when run alone).
- New behaviour added with no test, when the surrounding behaviour has tests.

---

## Do NOT flag

- "Could use more edge cases" without naming a specific one.
- Coverage-percentage observations.
- Snapshot tests that are intentional for surface stability (codegen output, etc.).
- Style of testing library calls (`expect(x).toBe(y)` vs `assert.equal`).

---

## Voice

When flagging a missing regression test for a bug fix, point to the file the test should live in and sketch the assertion in one line.
