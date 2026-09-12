#!/bin/bash

# Read JSON input
input=$(cat)

# Extract values from JSON (without jq)
cwd=$(echo "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p')

# Session-level segments: context window + rate limits (nested JSON, use jq)
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Round down to whole numbers, guarding against empty values
[ -n "$ctx_pct" ] && ctx_pct=$(echo "$ctx_pct" | cut -d. -f1)
[ -n "$five_pct" ] && five_pct=$(echo "$five_pct" | cut -d. -f1)
[ -n "$week_pct" ] && week_pct=$(echo "$week_pct" | cut -d. -f1)

esc_yellow=$'\033[01;33m'
esc_reset=$'\033[00m'

# Build the extra segment, only including pieces that are actually present
extra=""
[ -n "$ctx_pct" ] && extra="${extra:+$extra | }Ctx: ${esc_yellow}${ctx_pct}%${esc_reset}"
[ -n "$five_pct" ] && extra="${extra:+$extra | }5h: ${esc_yellow}${five_pct}%${esc_reset}"
[ -n "$week_pct" ] && extra="${extra:+$extra | }Wk: ${esc_yellow}${week_pct}%${esc_reset}"

# Git information (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  # Get repo name (basename of cwd)
  repo_name="${cwd##*/}"

  # Get branch
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

  # Count staged files
  staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  # Count unstaged files (modified + deleted, not untracked)
  unstaged=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')

  # Count untracked files
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  printf '\033[01;36m%s\033[00m@\033[01;32m%s\033[00m | S: \033[01;33m%s\033[00m | U: \033[01;33m%s\033[00m | A: \033[01;33m%s\033[00m' \
    "$repo_name" "$branch" "$staged" "$unstaged" "$untracked"
else
  # Not a git repo
  printf '\033[01;36m%s\033[00m' "$cwd"
fi

# Append session-level segments (context window / rate limits) if present
[ -n "$extra" ] && printf ' | %s' "$extra"
