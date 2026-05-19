# Rubric — UI / Frontend (gated)

**Triggers:** changes to `*.tsx` / `*.jsx`, files under `apps/*app*/`, `apps/*admin*/`, `mobile/*/`, component packages, CSS / styled-components files.

Skip if no changed files match.

**Important:** Alex reviews UI changes visually. Do NOT spin up preview tools to self-screenshot. Focus this pack on correctness, accessibility, performance, and React/state-management hygiene that aren't obvious from a screenshot.

---

## Blockers

### Hook rules violation

- A hook called conditionally (inside `if` / `&&` / early return).
- A hook called in a loop.
- A hook called from a non-component non-hook function.

### Stale closure on stale state in a callback

A `useEffect` / `useCallback` / `useMemo` that reads `state` / `props` but doesn't include them in the dependency array — and the missing dep matters for correctness, not just lint.

### Infinite render loop

A `setState` called unconditionally in render, or in a `useEffect` whose deps include the state it sets.

### XSS via uncontrolled HTML

`dangerouslySetInnerHTML` with content sourced from the network / user input without sanitization. (Cross-listed with security.)

---

## High

### Accessibility regressions

- New interactive element with no role / `aria-label` / keyboard handler (button-as-div without `onKeyDown`).
- Image without `alt` (decorative images should explicitly have `alt=""`).
- Color contrast change that fails WCAG AA on a known-checked surface — flag for visual review by Alex.
- Focus trap removed from a modal / dialog.

### Render perf regressions

- A large list rendered without virtualization where the list is known to grow.
- A new context provider whose value is a fresh object literal on every render (forces all consumers to re-render).
- `useMemo` / `useCallback` removed from a hot path that demonstrably needed it.

### Form state correctness

- Controlled input losing its value on parent re-render.
- Form submission handler that doesn't `preventDefault` and relies on browser nav.
- Async submission with no loading / disabled state — double-submit possible.

---

## Medium

- New component without a clear single responsibility (UI + data fetching + business logic all in one).
- Inline styles that duplicate existing design tokens / styled-components.
- New state lifted higher than it needs to be (or kept lower than the consumers it has).

---

## Do NOT flag

- Visual / layout / spacing / color choices — those are for Alex's visual review.
- Component naming preferences.
- "I'd structure this with composition instead of props" without a concrete reason.
- Tailwind class ordering / shorthand preferences.

---

## Voice

Visual findings go in the review *summary* as "please eyeball X in your visual pass." Numbered findings should be things that aren't obvious from looking at the UI — hook bugs, perf issues, a11y misses.
