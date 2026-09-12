#!/bin/bash

# Claude Code statusline.
#
#   Opus 5 │ main +42/-7 │ dotfiles │ ▓▓░░░░░░░░ 230k/1000k │ $86.43
#          │ 5h 9% ·2h14m │ 7d 16% ·4d │ high │ v2.1.263
#
# Catppuccin, in 24-bit colour. The palette is picked from the macOS appearance
# so it follows ghostty's `light:Catppuccin Latte,dark:Catppuccin Frappe`; the
# dark half is exactly the frappe palette. The `defaults read` costs about 6ms.

CURRENCY='$'         # symbol to print (e.g. '$', '€', '£', '¥')
CURRENCY_CODE='USD'  # ISO 4217 code for the rate lookup; 'USD' skips it entirely
EXCHANGE_RATE=1      # fallback when the API cannot be reached

CACHE_DIR="${HOME}/.cache/cc-status-line"
CACHE_FILE="${CACHE_DIR}/exchange-rate.json"
CACHE_MAX_AGE=86400  # 24h

# get_exchange_rate -> USD->CURRENCY_CODE rate, cached for a day.
get_exchange_rate() {
  # Spelled out as an `if` for legibility; the original one-liner was correct
  # (&& and || are equal precedence and left-associative, so it grouped as
  # `(empty || USD) && echo && return`), just hard to read at a glance.
  if [ -z "$CURRENCY_CODE" ] || [ "$CURRENCY_CODE" = "USD" ]; then
    echo "1"
    return
  fi

  if [ -f "$CACHE_FILE" ]; then
    local mtime age cached
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$((NOW - mtime))
    if [ "$age" -lt "$CACHE_MAX_AGE" ]; then
      cached=$(jq -r --arg c "$CURRENCY_CODE" '.rates[$c] // empty' "$CACHE_FILE" 2>/dev/null)
      [ -n "$cached" ] && echo "$cached" && return
    fi
  fi

  mkdir -p "$CACHE_DIR"
  local fresh
  fresh=$(curl -sf --max-time 2 "https://api.frankfurter.app/latest?from=USD&to=${CURRENCY_CODE}" 2>/dev/null)
  if [ -n "$fresh" ]; then
    printf '%s' "$fresh" > "$CACHE_FILE"
    jq -r --arg c "$CURRENCY_CODE" '.rates[$c] // empty' <<< "$fresh" 2>/dev/null && return
  fi

  echo "$EXCHANGE_RATE"
}

data=$(cat)
NOW=$(date +%s)

# One jq call for everything. `version` and `effort.level` come from the payload
# too -- shelling out to `claude --version` would spawn node on every render.
#
# Split on a unit separator rather than a tab: tab counts as IFS *whitespace*,
# so `read` collapses runs of it and a single empty field silently shifts every
# later value one slot left. U+001F is not whitespace, so empty fields survive.
IFS=$'\x1f' read -r model cwd max_ctx used_pct cost_usd \
  five_pct five_reset week_pct week_reset effort fast_mode cc_version <<< "$(
  echo "$data" | jq -r '[
    (.model.display_name // .model.id // "unknown"),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.context_window_size // 200000),
    (.context_window.used_percentage // ""),
    (.cost.total_cost_usd // 0),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.effort.level // ""),
    (.fast_mode // false),
    (.version // "")
  ] | map(tostring) | join("\u001f")'
)"

folder="${cwd##*/}"
[ -z "$folder" ] && folder="?"

# Git: branch, plus uncommitted line churn against HEAD.
#
# Note this is `git diff`, which does not see untracked files -- a brand-new
# file registers as nothing until it is staged. That is a deliberate trade for
# one cheap call; `status --porcelain` would catch it, but only as a boolean.
branch=""
added=0
removed=0
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ "${#branch}" -gt 20 ]; then
    branch="${branch:0:19}…"
  fi
  # numstat prints "-" for binary files, which awk reads as 0.
  read -r added removed <<< "$(
    git -C "$cwd" --no-optional-locks diff --numstat HEAD 2>/dev/null |
      awk '{a += $1; d += $2} END {print a + 0, d + 0}'
  )"
  added=${added:-0}
  removed=${removed:-0}
fi

# Catppuccin, 24-bit. Dark is frappe, light is latte.
if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  BLUE='\033[38;2;140;170;238m'      # context bar, low
  RED='\033[38;2;231;130;132m'       # context bar high, deletions
  TEAL='\033[38;2;129;200;190m'      # folder
  MAUVE='\033[38;2;202;158;230m'     # git branch
  LAVENDER='\033[38;2;186;187;241m'  # model
  PEACH='\033[38;2;239;159;118m'     # fast mode
  GREEN='\033[38;2;166;209;137m'     # cost, insertions, healthy gauges
  YELLOW='\033[38;2;229;200;144m'    # gauges filling up
  OVERLAY='\033[38;2;115;121;148m'   # separators, empty bar
  SUBTEXT='\033[38;2;165;173;206m'   # secondary text
else
  BLUE='\033[38;2;30;102;245m'
  RED='\033[38;2;210;15;57m'
  TEAL='\033[38;2;23;146;153m'
  MAUVE='\033[38;2;136;57;239m'
  LAVENDER='\033[38;2;114;135;253m'
  PEACH='\033[38;2;254;100;11m'
  GREEN='\033[38;2;64;160;43m'
  YELLOW='\033[38;2;223;142;29m'
  OVERLAY='\033[38;2;156;160;176m'
  SUBTEXT='\033[38;2;108;111;133m'
fi
RESET='\033[0m'

SEP=" ${OVERLAY}│${RESET} "

# Context bar: ten blocks, blue until 60% then red.
if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
  context_info="${OVERLAY}░░░░░░░░░░${RESET}"
else
  pct=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "$used_pct")
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100

  used_k=$((max_ctx * pct / 100 / 1000))
  max_k=$((max_ctx / 1000))
  filled=$((pct / 10))

  [ "$pct" -gt 60 ] && COLOR="$RED" || COLOR="$BLUE"

  bar=""
  for i in 0 1 2 3 4 5 6 7 8 9; do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}${COLOR}▓${RESET}"
    else
      bar="${bar}${OVERLAY}░${RESET}"
    fi
  done

  context_info="${bar} ${SUBTEXT}${used_k}k/${max_k}k${RESET}"
fi

# until_reset <epoch> -> compact time remaining ("2h14m", "4d"), empty when the
# window has passed or the field is missing. Coarsens as it grows: minutes under
# an hour, then hours, then days -- the exact minute stops mattering once it is
# days away.
until_reset() {
  local at="$1" left d h m
  if [ -z "$at" ] || [ "$at" = "null" ] || [ "$at" = "0" ]; then return; fi
  left=$((at - NOW))
  [ "$left" -le 0 ] && return
  if [ "$left" -ge 86400 ]; then
    d=$((left / 86400))
    h=$(((left % 86400) / 3600))
    if [ "$h" -gt 0 ]; then printf '%dd%dh' "$d" "$h"; else printf '%dd' "$d"; fi
  elif [ "$left" -ge 3600 ]; then
    h=$((left / 3600))
    m=$(((left % 3600) / 60))
    if [ "$m" -gt 0 ]; then printf '%dh%dm' "$h" "$m"; else printf '%dh' "$h"; fi
  else
    m=$((left / 60))
    [ "$m" -lt 1 ] && m=1
    printf '%dm' "$m"
  fi
}

# gauge <label> <pct> <resets_at> -> "5h 9% ·2h14m", shaded green->yellow->red
gauge() {
  local label="$1" raw="$2" reset="$3" p colour left
  if [ -z "$raw" ] || [ "$raw" = "null" ]; then return; fi
  p=$(printf "%.0f" "$raw" 2>/dev/null || echo 0)
  if [ "$p" -ge 85 ]; then
    colour="$RED"
  elif [ "$p" -ge 60 ]; then
    colour="$YELLOW"
  else
    colour="$GREEN"
  fi
  printf '%s%s%s %s%s%%%s' "$OVERLAY" "$label" "$RESET" "$colour" "$p" "$RESET"
  left=$(until_reset "$reset")
  [ -n "$left" ] && printf ' %s·%s%s' "$OVERLAY" "$left" "$RESET"
}

# Cost, converted out of USD if a currency is configured.
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ] && [ "$cost_usd" != "null" ]; then
  rate=$(get_exchange_rate)
  cost_converted=$(echo "$cost_usd * $rate" | bc -l 2>/dev/null || echo "$cost_usd")
  cost_fmt=$(printf "%.2f" "$cost_converted" 2>/dev/null || echo "0.00")
  cost_display="${GREEN}${CURRENCY}${cost_fmt}${RESET}"
else
  cost_display="${OVERLAY}${CURRENCY}0.00${RESET}"
fi

output="${LAVENDER}${model}${RESET}"

if [ -n "$branch" ]; then
  output="${output}${SEP}${MAUVE}${branch}${RESET}"
  if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
    output="${output} ${GREEN}+${added}${RESET}${OVERLAY}/${RESET}${RED}-${removed}${RESET}"
  fi
fi

output="${output}${SEP}${TEAL}${folder}${RESET}"
output="${output}${SEP}${context_info}"
output="${output}${SEP}${cost_display}"

five_seg=$(gauge 5h "$five_pct" "$five_reset")
week_seg=$(gauge 7d "$week_pct" "$week_reset")
[ -n "$five_seg" ] && output="${output}${SEP}${five_seg}"
[ -n "$week_seg" ] && output="${output}${SEP}${week_seg}"

if [ -n "$effort" ] && [ "$effort" != "null" ]; then
  output="${output}${SEP}${SUBTEXT}${effort}${RESET}"
  # Fast mode rides alongside effort, and only when it is actually on.
  [ "$fast_mode" = "true" ] && output="${output} ${PEACH}⚡${RESET}"
fi

[ -n "$cc_version" ] && [ "$cc_version" != "null" ] && output="${output}${SEP}${SUBTEXT}v${cc_version}${RESET}"

printf '%b\n' "$output"
