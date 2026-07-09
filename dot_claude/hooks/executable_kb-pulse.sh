#!/bin/bash
# kb-pulse — SessionStart hook: push the KB's pulse into new sessions.
# The recall flow of the continuity architecture (necro-kb
# research/continuity-architecture.md): capture is automated, recall shouldn't
# depend on remembering to ask. Compact by design; silent when there's nothing.
KB="${NECRO_KB:-$HOME/projects/necro-kb}"
[ -d "$KB" ] || exit 0
command -v rg >/dev/null 2>&1 || exit 0

# Open work: any article with status: active (kb-open semantics), capped at 6.
open=$(rg -l --glob '!raw/**' --glob '!output/**' --glob '!wiki/_*' \
    '^status:[[:space:]]*active' "$KB" 2>/dev/null | head -6 | \
  while IFS= read -r f; do
    t=$(rg -m1 -or '$1' '^title:[[:space:]]*"?([^"]*?)"?[[:space:]]*$' "$f" 2>/dev/null)
    printf -- '- %s — %s\n' "${t:-$(basename "$f" .md)}" "${f#"$KB"/}"
  done)

# Hot threads: scribe's hot cache, minus its "No activity" placeholders.
hot=$(awk '/^- /{ if ($0 !~ /^- (No|None)/) print }' "$KB/wiki/_hot.md" 2>/dev/null | head -5)

[ -z "$open" ] && [ -z "$hot" ] && exit 0

echo "## necro-kb pulse"
if [ -n "$open" ]; then
  echo "Open work (status: active):"
  echo "$open"
fi
if [ -n "$hot" ]; then
  echo "Hot threads:"
  echo "$hot"
fi
echo "Recall: \`qmd query \"<question>\"\` · board: $KB/Open Work.base · map: research/continuity-architecture.md"
exit 0
