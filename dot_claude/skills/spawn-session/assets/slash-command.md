<!--
Slash command template for the spawn-session skill.

Copy this file to one of:
  - ~/.claude/commands/spawn.md     (global)
  - .claude/commands/spawn.md       (per-project)

Rename the file to whatever you want the slash command to be called
(e.g. `start.md` if you prefer `/start`).
-->

Use the spawn-session skill to kick off a new coding session in this worktree.

Arguments: $ARGUMENTS

Parse the arguments as:
- First positional arg: feature name (kebab-case, required)
- Second positional arg (optional): ticket handle, e.g. `ENG-1234`
- `--draft`: create a new draft ticket in the default project
- `--team <TEAM>`: override the default project for `--draft` (e.g. `--team SERV`). Implies `--draft`. Mutually exclusive with a passed ticket handle.
- `--kb <ref>`: pull session context from a knowledge-base article (slug, title, or query — resolved via qmd)
- `--solo`: execute chunks inline instead of delegating to sub-agents
- `--init`: run interactive config setup instead of the normal flow

Then follow the skill's flow end-to-end. Do not skip the dossier phase. Do not start coding until I've signed off on the plan, and land the contracts (chunk 0) before any fan-out.
