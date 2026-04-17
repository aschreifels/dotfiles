<!--
Slash command template for the wrap-session skill.

Copy this file to one of:
  - ~/.claude/commands/wrap-session.md   (global)
  - .claude/commands/wrap-session.md     (per-project)

Rename if you want a different slash command name (e.g. `wrap.md` for `/wrap`).
-->

Use the wrap-session skill to close down and clean up the current coding session.

Arguments: $ARGUMENTS

Parse the arguments as:
- Optional positional: feature name or worktree path (auto-detect from cwd if omitted)
- `--delete-branch` / `-D`: also delete the git branch
- `--force` / `-f`: skip safety prompts and proceed even with uncommitted/unpushed changes

Then follow the skill's flow end-to-end. Do not skip the safety checks in Phase 2 unless `--force` was explicitly passed.
