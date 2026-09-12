#!/usr/bin/env bash
# One-off machine setup and utility commands.

# ---------------------------------------------------------------- ssh key ----

# do_gen_ssh_key [email] — the private font repo is reached over SSH, so this
# is a prerequisite for `dot fonts` on a fresh machine.
do_gen_ssh_key() {
  local email="${1:-}" key="$SSH_KEY"

  bold "SSH key"
  if [[ -f "$key" ]]; then
    ok "already present at $key"
  else
    if [[ -z "$email" ]]; then
      email="$(git config --file "$DOTFILES/home/.gitconfig" user.email 2>/dev/null || true)"
      [[ -n "$email" ]] && info "using $email from home/.gitconfig"
    fi
    [[ -n "$email" ]] || die "usage: dot gen-ssh-key <email>"
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
    run ssh-keygen -t ed25519 -C "$email" -f "$key" -N ""
    ok "generated $key"
  fi

  # Persist the key in the keychain so it survives reboots.
  if ! grep -q "UseKeychain" "$HOME/.ssh/config" 2>/dev/null; then
    if [[ -n "$DRY_RUN" ]]; then
      info "would append a github.com Host block to ~/.ssh/config"
    else
      cat >> "$HOME/.ssh/config" <<EOF

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $key
  IdentitiesOnly yes
EOF
      ok "added a github.com block to ~/.ssh/config"
    fi
  else
    ok "~/.ssh/config already configured"
  fi
  run ssh-add --apple-use-keychain "$key" 2>/dev/null || true

  [[ -n "$DRY_RUN" ]] && return 0

  bold "Add it to GitHub"
  pbcopy < "$key.pub" 2>/dev/null && ok "public key copied to the clipboard" \
                                  || cat "$key.pub"
  echo "      https://github.com/settings/ssh/new"
  confirm "Added it?" "n" || { warn "skipped — 'dot fonts' will fail until you do"; return 0; }

  # ssh -T against GitHub exits 1 even on success, so match the greeting.
  if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
    ok "GitHub authentication works"
  else
    warn "GitHub did not confirm the key yet"
    return 1
  fi
}

# ------------------------------------------------------------- benchmark -----

# do_benchmark_shell [runs] — time an interactive zsh startup.
do_benchmark_shell() {
  local runs="${1:-10}" i t
  have zsh || die "zsh not found"
  bold "Shell startup — $runs runs of 'zsh -i -c exit'"

  local times=() total=0
  local TIMEFORMAT='%3R'        # bash builtin, millisecond resolution
  for (( i = 1; i <= runs; i++ )); do
    t=$( { time zsh -i -c exit >/dev/null 2>&1; } 2>&1 )
    times+=("$t")
    printf '  run %-2d  %sms\n' "$i" "$(_ms "$t")"
  done

  # sort numerically for min/median/max
  local sorted; sorted=$(printf '%s\n' "${times[@]}" | sort -n)
  local min max med n
  min="$(printf '%s' "$sorted" | head -1)"
  max="$(printf '%s' "$sorted" | tail -1)"
  n=$(( (runs + 1) / 2 ))
  med="$(printf '%s' "$sorted" | sed -n "${n}p")"
  echo
  printf '  min     %sms\n  median  %sms\n  max     %sms\n' \
    "$(_ms "$min")" "$(_ms "$med")" "$(_ms "$max")"
  echo
  if [[ "${med%%.*}" -ge 1 ]]; then
    warn "over 1s — something in ~/.zshrc is slow"
  else
    ok "under 1s"
  fi
}

# _ms <seconds-with-decimals> -> integer milliseconds
_ms() { printf '%.0f' "$(echo "$1" | awk '{print $1 * 1000}')"; }

# ------------------------------------------------------------------ misc ------

do_edit() { run "${EDITOR:-nvim}" "$DOTFILES"; }

# do_completions — print a zsh completion for dot itself.
do_completions() {
  cat <<'COMP'
#compdef dot
# zsh completion for dot. Install with:
#   mkdir -p ~/.local/share/zsh/site-functions
#   dot completions > ~/.local/share/zsh/site-functions/_dot
# and make sure that directory is on your fpath, in ~/.zshrc, before compinit:
#   fpath=(~/.local/share/zsh/site-functions $fpath)

_dot() {
  local -a commands
  commands=(
    'install:packages, fonts, then link everything'
    'link:stow the configs into place'
    'unlink:remove the symlinks stow created'
    'relink:unlink + link'
    'packages:install from packages/Brewfile'
    'package-add:add an entry to the Brewfile'
    'package-remove:remove an entry from the Brewfile'
    'package-list:list what the Brewfile holds'
    'check-packages:report drift against what is installed'
    'fonts:fetch + install the private font'
    'gen-ssh-key:generate an SSH key and add it to GitHub'
    'benchmark-shell:time zsh startup'
    'doctor:health check'
    'update:git pull, then packages + relink'
    'retry-failed:re-run the install steps that failed'
    'revert:unlink and restore backups'
    'cleanup:delete backups'
    'edit:open the repo in $EDITOR'
    'completions:print this completion script'
    'help:usage'
  )
  _arguments -C \
    '(--dry-run)--dry-run[print what would happen, change nothing]' \
    '1: :->command' \
    '*:: :->args'

  case $state in
    command) _describe -t commands 'dot command' commands ;;
    args)
      case $words[1] in
        package-add)    _arguments '2:formula:' '3: :(--brew --cask --tap --npm)' ;;
        package-remove) _alternative "entries:brewfile:($(dot package-list 2>/dev/null | sed 's/^  //'))" ;;
        packages)       _arguments '--dump[rewrite the Brewfile from what is installed]' '--work[also install the work Brewfile]' ;;
      esac
      ;;
  esac
}

_dot "$@"
COMP
}
