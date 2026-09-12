#!/bin/bash

# Claude Code statusline.
#
# Colours are ANSI 16 only, never hex. Those sixteen slots are defined by the
# terminal theme, so this follows ghostty's catppuccin light/dark switch -- and
# any other theme -- without knowing anything about either.
#
# Bold is deliberately not used as a colour. Most terminals, ghostty included,
# render "bold + colour" as the *bright* palette slot, and in catppuccin those
# are the harsher, more saturated variants (bright cyan #5abfb5 against normal
# #81c8be). Everything here used to be bold, which meant the whole line was
# drawn in the loud half of the palette.
#
# Colour carries meaning rather than decoration: separators and labels are
# dimmed so they recede, a zero count stays dim instead of shouting, and the
# percentages shade from green to red as they fill.

input=$(cat)

cwd=$(echo "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p')

# Session-level segments: context window + rate limits (nested JSON, needs jq)
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Truncate to whole numbers via parameter expansion (no subshell per value)
ctx_pct=${ctx_pct%%.*}
five_pct=${five_pct%%.*}
week_pct=${week_pct%%.*}

dim=$'\033[90m'
cyan=$'\033[36m'
green=$'\033[32m'
yellow=$'\033[33m'
red=$'\033[31m'
reset=$'\033[0m'

sep="${dim} | ${reset}"

# heat <pct> -> colour for a fill percentage, green through red
heat() {
  if [ "$1" -ge 85 ]; then
    printf '%s' "$red"
  elif [ "$1" -ge 60 ]; then
    printf '%s' "$yellow"
  else
    printf '%s' "$green"
  fi
}

# gauge <label> <pct> -> "Label: 42%" with the number shaded by severity
gauge() {
  printf '%s%s:%s %s%s%%%s' "$dim" "$1" "$reset" "$(heat "$2")" "$2" "$reset"
}

# tally <label> <count> -> dim when zero, so only real work draws the eye
tally() {
  if [ "$2" -gt 0 ]; then
    printf '%s%s:%s %s%s%s' "$dim" "$1" "$reset" "$yellow" "$2" "$reset"
  else
    printf '%s%s: %s%s' "$dim" "$1" "$2" "$reset"
  fi
}

out=""

if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  repo_name="${cwd##*/}"
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

  staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  unstaged=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  out="${cyan}${repo_name}${reset}${dim}@${reset}${green}${branch}${reset}"
  out="${out}${sep}$(tally S "$staged")"
  out="${out}${sep}$(tally U "$unstaged")"
  out="${out}${sep}$(tally A "$untracked")"
else
  out="${cyan}${cwd}${reset}"
fi

[ -n "$ctx_pct" ] && out="${out}${sep}$(gauge Ctx "$ctx_pct")"
[ -n "$five_pct" ] && out="${out}${sep}$(gauge 5h "$five_pct")"
[ -n "$week_pct" ] && out="${out}${sep}$(gauge Wk "$week_pct")"

printf '%s' "$out"
