#!/usr/bin/env bash
# Shared helpers. Sourced by `dot` and everything under lib/ — never run directly.
#
# macOS only. Paths like ~/Library/Fonts are assumed, not branched on.

# ------------------------------------------------------------------ output ---

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '\033[34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m !!\033[0m %s\n' "$*"; }
die()  { printf '\033[31m ✗\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------- dry run -----
# Every mutating action goes through run() so `dot --dry-run` is honest.

DRY_RUN="${DRY_RUN:-}"
run() {
  if [[ -n "$DRY_RUN" ]]; then info "would: $*"; else "$@"; fi
}

# say <fn> <args...> — a past-tense message describing what a preceding run()
# just did. Suppressed under --dry-run, where nothing happened and run() has
# already printed its own "would: ..." line. Keeps dry-run output from claiming
# credit for work it did not do.
say() { [[ -n "$DRY_RUN" ]] || "$@"; }

# confirm <prompt> [default y|n] -> 0 on yes
confirm() {
  local prompt="$1" default="${2:-n}" reply hint="[y/N]"
  [[ "$default" == "y" ]] && hint="[Y/n]"
  if [[ -n "$DRY_RUN" ]]; then info "would ask: $prompt"; return 0; fi
  if [[ ! -r /dev/tty ]]; then
    warn "$prompt — no terminal, assuming $default"
    [[ "$default" == "y" ]]; return
  fi
  read -rp "$(printf '\033[34m::\033[0m %s %s ' "$prompt" "$hint")" reply </dev/tty
  reply="${reply:-$default}"
  [[ "$reply" == [yY]* ]]
}

# ------------------------------------------------------------------ paths ----

FONT_DIR="$HOME/Library/Fonts"

# stow_packages -> tab-separated "package<TAB>target" lines.
# Single source of truth: link, unlink, cleanup and doctor all read this.
# One package now that the VS Code config is gone — it was the only target that
# was not $HOME itself.
stow_packages() {
  printf '%s\t%s\n' "home" "$HOME"
}

# shared_dirs <pkg> -> paths, relative to that package's target, that must stay
# REAL directories rather than being folded into a symlink.
#
# Stow folds a directory into one symlink when the target does not yet exist.
# That is what we want where this repo owns the whole directory (~/.config/nvim
# is a single link, so anything added there is instantly tracked). It is
# dangerous where the directory is shared with other software: on a machine with
# no ~/.config yet, stow would make ~/.config itself a symlink into this repo,
# and every other tool's config would then be written inside it. Same for
# ~/.claude, which Claude Code fills with projects/, history and memory.
#
# dot link pre-creates these so stow has to descend instead of folding.
shared_dirs() { # <pkg>
  case "$1" in
    home) printf '%s\n' ".config" ".claude" ".local" ".local/bin" ;;
    *)    : ;;
  esac
}

# --------------------------------------------------------------- symlinks ----

# _norm <path> -> lexically collapse . and .. — no filesystem access, so it
# works on dangling links too. Written for bash 3.2 (macOS ships that).
_norm() {
  local p="$1" out="" part
  while [[ -n "$p" ]]; do
    part="${p%%/*}"
    if [[ "$p" == */* ]]; then p="${p#*/}"; else p=""; fi
    case "$part" in
      ''|.) ;;
      ..)   out="${out%/*}" ;;
      *)    out="$out/$part" ;;
    esac
  done
  printf '%s\n' "${out:-/}"
}

# link_target <dest> -> the symlink's target as a normalized absolute path
link_target() {
  local target; target="$(readlink "$1")"
  [[ "$target" != /* ]] && target="$(dirname "$1")/$target"
  _norm "$target"
}

# is_our_link <dest> -> true if dest is a symlink pointing anywhere inside the
# repo, including a dangling one.
is_our_link() {
  local dest="$1" target
  [[ -L "$dest" ]] || return 1
  target="$(link_target "$dest")"
  [[ "$target" == "$DOTFILES" || "$target" == "$DOTFILES"/* ]]
}

# is_linked_here <dest> <root> -> true if dest, or any ancestor up to root, is
# a symlink into the repo. Stow folds whole directories when it can, so a file
# at ~/.config/nvim/lua/plugins/theme.lua is linked by way of ~/.config/nvim
# being the symlink — its own parents are ordinary directories.
is_linked_here() {
  local p="$1" root="$2"
  while [[ -n "$p" && "$p" != "/" && "$p" != "$root" ]]; do
    is_our_link "$p" && return 0
    p="$(dirname "$p")"
  done
  return 1
}

# backups_for <dest> -> existing backup paths, oldest first
backups_for() {
  local dest="$1" b
  shopt -s nullglob
  [[ -e "$dest.bak" ]] && printf '%s\n' "$dest.bak"
  for b in "$dest".bak-*; do printf '%s\n' "$b"; done
  shopt -u nullglob
}

newest_backup() { backups_for "$1" | tail -n1; }

# back_up <path> — move it aside, never clobbering an older backup
back_up() {
  local dest="$1" bak="$1.bak"
  [[ -e "$bak" ]] && bak="$dest.bak-$(date +%Y%m%d-%H%M%S)"
  run mv "$dest" "$bak"
  say warn "backed up $dest -> ${bak##*/}"
}

# ------------------------------------------------------------------ state ----
# `dot install` records the steps that failed so `dot retry-failed` can re-run
# just those. Kept out of the repo proper — see .gitignore.

STATE_DIR="$DOTFILES/.dot-state"
FAILED_FILE="$STATE_DIR/failed"

state_reset()  { run rm -f "$FAILED_FILE"; }
state_record() { # <step-fn>
  [[ -n "$DRY_RUN" ]] && return 0
  mkdir -p "$STATE_DIR"
  grep -qxF "$1" "$FAILED_FILE" 2>/dev/null || printf '%s\n' "$1" >> "$FAILED_FILE"
}
state_failed() { [[ -f "$FAILED_FILE" ]] && cat "$FAILED_FILE" || true; }
