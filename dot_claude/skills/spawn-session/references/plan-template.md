# PLAN.md Template

This is the skeleton for `PLAN.md`. Copy it to the repo root at the start of each session. Fill in placeholders in `{braces}`. Never commit this file.

---

```markdown
# PLAN.md — {feature-name}

<!-- Living planning document for this session. Do not commit. -->

**Ticket:** {TICKET-HANDLE or "none"}
**Branch:** {branch-name}
**Started:** {YYYY-MM-DD}

---

## Architecture & Design

<!--
How the solution fits into the existing system. Key modules, data flow,
interfaces between components. ASCII diagrams welcome.
-->

## Summary of Proposed Changes

<!--
Plain-English summary. What's changing and why. Files and modules
touched at a high level. Aim for something you'd paste into a PR body later.
-->

## Plan / Todo

<!--
Ordered, concrete steps. Kept in sync with the TodoWrite tool — every
update here mirrors an update there, and vice versa.
-->

- [ ] ...
- [ ] ...
- [ ] ...

## Risks

<!--
Things that could go sideways. Migration concerns, perf implications,
cross-cutting effects, coverage gaps, unknowns about third-party behavior.
-->

- ...
- ...

## Open Questions

<!--
Questions for the user. Mark each [ANSWER NEEDED] until answered, then
inline the answer directly below the question — don't delete the question.
-->

### Q1: {question}
[ANSWER NEEDED]

### Q2: {question}
[ANSWER NEEDED]
```

---

## Notes on sections

- **Architecture & Design** belongs first because everything downstream depends on it. If you can't sketch it, you don't understand the problem well enough to plan.
- **Summary of Proposed Changes** is the "commit message in advance." Keep it tight.
- **Plan / Todo** is the only section that should move fast during execution. Everything else stabilizes after the pause ritual.
- **Risks** and **Open Questions** are different: risks are things *you* see coming; open questions are things you *need the user to decide*.
