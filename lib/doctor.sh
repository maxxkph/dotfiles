#!/usr/bin/env bash
# `dot doctor` — report what is wired up and what is not. Read-only.

DOCTOR_FAIL=0

_pass() { printf '\033[32m ✓\033[0m %s\n' "$*"; }
_fail() { printf '\033[31m ✗\033[0m %s\n' "$*"; DOCTOR_FAIL=1; }
_note() { printf '\033[33m !!\033[0m %s\n' "$*"; }

do_doctor() {
  bold "Environment"
  _pass "macOS $(sw_vers -productVersion) ($(uname -m))"
  _pass "repo: $DOTFILES"
  have brew && _pass "brew $(brew --version | head -1 | awk '{print $2}')" \
            || _fail "brew not installed"
  have stow && _pass "stow $(stow --version | head -1 | awk '{print $NF}')" \
            || _fail "stow not installed — 'dot link' cannot run"

  # Homebrew shared between accounts is a real failure mode on this machine:
  # a directory owned by another user makes every `brew install` die.
  if have brew; then
    local prefix; prefix="$(brew --prefix)"
    if [[ -d "$prefix" && ! -w "$prefix" ]]; then
      _fail "$prefix is not writable by $(whoami) — try: sudo chmod -R g+w $prefix"
    fi
  fi

  bold "Links"
  local pkg target rel dest linked missing foreign
  while IFS=$'\t' read -r pkg target; do
    linked=0; missing=0; foreign=0
    while IFS= read -r rel; do
      [[ -n "$rel" ]] || continue
      dest="$target/$rel"
      if is_linked_here "$dest" "$target"; then
        linked=$((linked + 1))
      elif [[ -L "$dest" ]]; then
        foreign=$((foreign + 1))
      else
        missing=$((missing + 1))
      fi
    done < <(pkg_files "$pkg")
    if (( missing == 0 && foreign == 0 )); then
      _pass "$pkg: $linked/$linked linked -> $target"
    else
      _fail "$pkg: $linked linked, $missing missing, $foreign foreign -> $target"
    fi
  done < <(stow_packages)

  # A shared directory that got folded into a symlink means everything another
  # tool writes there lands inside this repo.
  bold "Shared directories kept real"
  local d any=0
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    any=1
    if [[ -L "$HOME/$d" ]]; then
      _fail "~/$d is a symlink into the repo — other tools would write inside it"
    elif [[ -d "$HOME/$d" ]]; then
      _pass "~/$d"
    else
      _note "~/$d does not exist yet"
    fi
  done < <(shared_dirs home)
  (( any )) || _note "none declared"

  bold "Tools the configs depend on"
  local t
  for t in nvim git starship rg fd fzf tmux stow; do
    have "$t" && _pass "$t" || _fail "$t missing"
  done

  bold "SSH key (needed for the private font repo)"
  if [[ -f "$SSH_KEY" ]]; then
    _pass "$SSH_KEY"
  else
    _note "no key at $SSH_KEY — 'dot gen-ssh-key' creates one"
  fi

  bold "Fonts"
  if [[ ! -f "$SSH_KEY" ]]; then
    _note "skipped — no SSH key to reach the font repo"
  else
    local name want=0 got=0
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      want=$((want + 1))
      [[ -e "$FONT_DIR/$name" ]] && got=$((got + 1))
    done < <(repo_font_names)
    if (( want == 0 )); then
      _note "could not list the font repo — is the key added to GitHub?"
    elif (( got == want )); then
      _pass "$got/$want installed in $FONT_DIR"
    else
      _note "$got/$want installed in $FONT_DIR — run 'dot fonts'"
    fi
  fi

  bold "Leftover backups"
  local n=0 bak
  while IFS=$'\t' read -r pkg target; do
    while IFS= read -r rel; do
      [[ -n "$rel" ]] || continue
      while IFS= read -r bak; do
        [[ -n "$bak" ]] && { _note "$bak"; n=$((n + 1)); }
      done < <(backups_for "$target/$rel")
    done < <(pkg_files "$pkg")
  done < <(stow_packages)
  (( n == 0 )) && _pass "none" || _note "$n backup(s) — 'dot cleanup' removes them"

  bold "Failed install steps"
  local failed; failed="$(state_failed)"
  if [[ -n "$failed" ]]; then
    _note "$(printf '%s' "$failed" | wc -l | tr -d ' ') recorded — 'dot retry-failed' re-runs them:"
    printf '%s\n' "$failed" | sed 's/^/      /'
  else
    _pass "none"
  fi

  bold "Repo"
  if [[ -n "$(git -C "$DOTFILES" status --porcelain)" ]]; then
    _note "uncommitted changes: $(git -C "$DOTFILES" status --porcelain | wc -l | tr -d ' ') file(s)"
  else
    _pass "clean"
  fi

  echo
  (( DOCTOR_FAIL )) && { bold "Some checks failed."; return 1; }
  bold "All good."
}
