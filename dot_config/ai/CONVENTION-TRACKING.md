# Convention Tracking

When the user states a development preference, corrects your approach, or establishes a pattern during a session, update `~/.config/ai/CONVENTIONS.md` to capture it.

## When to Update

- User corrects how you did something ("don't force push", "use warn not error for that")
- User states a preference ("I prefer extracting helpers", "always include the delivery ID in logs")
- A pattern is established through discussion that should apply going forward
- User explicitly asks to add a convention

## When NOT to Update

- Project-specific decisions that don't generalize (e.g., "use 60s lockDuration for this worker")
- One-off instructions for the current task
- Preferences already captured in the file

## How to Update

1. Read `~/.config/ai/CONVENTIONS.md` first to check for duplicates and find the right section
2. Add the new convention under the most appropriate existing heading, or create a new heading if none fit
3. Keep entries concise — one bullet point per convention
4. Use the same voice and format as existing entries
5. After editing, run `chezmoi add ~/.config/ai/CONVENTIONS.md` to persist to dotfiles

## Rules

- Don't ask permission to update — just do it and mention what you added
- Don't rewrite existing conventions — only append or refine
- Don't add conventions that contradict existing ones without discussing first
