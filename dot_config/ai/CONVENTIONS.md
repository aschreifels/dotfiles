# Development Conventions

Personal development preferences for AI coding agents (Claude Code, Crush, etc.).

## Git

- **Never force push.** No `--force`, `--force-with-lease`, or `-f`. If a push is rejected, inform me rather than forcing.
- **Never amend pushed commits.** Create new commits instead.
- **Don't revert changes** unless they caused errors or I explicitly ask.
- **Don't push to remote** unless I explicitly ask.

## Code Changes

- **Extract logic into focused helper functions.** Keep job/handler entry points thin — delegate to well-named private functions within the file.
- **Parallelize independent I/O.** Use `Promise.all` for concurrent work that doesn't depend on each other. Keep writes sequential when ordering matters.
- **Improve what you touch.** If you're in code with poor typing, missing types, or `any`, improve it. Don't explode scope, but be a good citizen.
- **Don't copy bad patterns.** If existing code does something wrong, do it right.
- **Log levels matter.** Use `warn` for expected business events (e.g., no results found). Use `error` only for actual failures. Don't introduce new error-level logs for normal control flow.

## Error Handling

- **Don't silently swallow errors.** If you catch, at least log with context (IDs, job info, etc.).
- **Don't introduce new errors that didn't exist before.** If the old code didn't throw, the new code shouldn't either without discussion. Prefer better logging over changing error behavior.
- **Include context in error logs.** Always log relevant IDs (delivery, job, user, etc.) so errors are traceable.

## Style

- **Be surgical in existing codebases.** Don't rename files, variables, or restructure unless that's the task. Respect surrounding code.
- **Match existing patterns.** Before writing code, look at similar files in the project for conventions.
- **DRY — rule of 3.** If the same logic appears in 3 places, extract it.

## Process

- **Test after every change.** Build, lint, and run relevant tests before calling it done.
- **Write a failing test before fixing a bug** when test infrastructure exists.
- **Don't fix unrelated bugs** you find along the way — mention them, but don't expand scope.
- **Hand off UI changes for visual review.** Don't spin up preview/browser tools to self-screenshot your own design work — Alex reviews visually. Overrides any "verify in browser" workflow instructions in the environment. Type/lint/test still applies.

## Meta

@~/.config/ai/CONVENTION-TRACKING.md
