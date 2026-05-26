#!/usr/bin/env bash

# Catppuccin Macchiato colors
LAVENDER="\033[38;2;183;189;248m"
MAUVE="\033[38;2;198;160;246m"
PEACH="\033[38;2;245;169;127m"
GREEN="\033[38;2;166;218;149m"
RED="\033[38;2;237;135;150m"
SKY="\033[38;2;145;215;227m"
MAROON="\033[38;2;238;153;160m"
SURFACE2="\033[38;2;91;96;120m"
SUBTEXT1="\033[38;2;184;192;224m"
OVERLAY1="\033[38;2;128;135;162m"
RESET="\033[0m"

# Read JSON input
input=$(cat)

# Extract values
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
session_name=$(echo "$input" | jq -r '.session_name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
context_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
model_id=$(echo "$input" | jq -r '.model.id')

# Directory basename
dir_name=$(basename "$cwd")

# Git branch and status (skip optional locks)
git_branch=""
git_status_str=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || echo "")
    if [ -n "$git_branch" ]; then
        # Git status counts
        staged=$(git -C "$cwd" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        modified=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

        status_parts=""
        [ "$staged" -gt 0 ] && status_parts="${status_parts}${GREEN}+${staged}${RESET} "
        [ "$modified" -gt 0 ] && status_parts="${status_parts}${PEACH}!${modified}${RESET} "
        [ "$untracked" -gt 0 ] && status_parts="${status_parts}${LAVENDER}?${untracked}${RESET} "

        git_status_str="$status_parts"
    fi
fi

# Abbreviate model name
model_short=$(echo "$model_id" | sed 's/us\.anthropic\.claude-//' | sed 's/opus-4-6.*/opus/' | sed 's/sonnet-4-5.*/sonnet/' | sed 's/haiku.*/haiku/')

# Build status line parts
parts=""

# Directory
parts="${parts}${LAVENDER}${dir_name}${RESET}"

# Git
if [ -n "$git_branch" ]; then
    parts="${parts} ${SURFACE2}│${RESET} ${MAUVE} ${git_branch}${RESET}"
    [ -n "$git_status_str" ] && parts="${parts} ${git_status_str}"
fi

# Session name
if [ -n "$session_name" ]; then
    parts="${parts} ${SURFACE2}│${RESET} ${SKY}${session_name}${RESET}"
fi

# Vim mode (only show NORMAL)
if [ "$vim_mode" = "NORMAL" ]; then
    parts="${parts} ${SURFACE2}│${RESET} ${SUBTEXT1}NORMAL${RESET}"
fi

# Context remaining (only below 50%)
if [ -n "$context_remaining" ]; then
    remaining_int=$(printf "%.0f" "$context_remaining")
    if [ "$remaining_int" -lt 50 ]; then
        parts="${parts} ${SURFACE2}│${RESET} ${OVERLAY1}${remaining_int}%${RESET}"
    fi
fi

# Model
parts="${parts} ${SURFACE2}│${RESET} ${OVERLAY1}${model_short}${RESET}"

# Output with printf to handle color codes
printf "${parts}\n"
