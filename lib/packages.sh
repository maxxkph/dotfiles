#!/usr/bin/env bash
# Homebrew, the Brewfile, and the font. macOS only.

BREWFILE="$DOTFILES/packages/Brewfile"

# The font is licensed, so it lives in a private repo rather than in here.
# Every .otf/.ttf in that repo gets installed, so adding weights there needs no
# change on this side.
FONT_REPO="git@github.com:maxxkph/mono-lisa.git"
SSH_KEY="$HOME/.ssh/id_ed25519"

# --------------------------------------------------------------- homebrew ----

do_homebrew() {
  bold "Homebrew"
  if have brew; then ok "already installed"; return 0; fi
  info "installing Homebrew"
  run /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# do_packages [--work]
do_packages() {
  local work="${1:-}"
  have brew || die "Homebrew not installed — run 'dot install' or 'dot packages' after installing it"
  bold "Packages"
  run brew bundle install --file="$BREWFILE" ${DRY_RUN:+--dry-run}
  if [[ "$work" == "--work" && -f "$BREWFILE.work" ]]; then
    bold "Packages (work)"
    run brew bundle install --file="$BREWFILE.work" ${DRY_RUN:+--dry-run}
  fi
}

# do_packages_dump — rewrite the Brewfile from what is actually installed
do_packages_dump() {
  have brew || die "Homebrew not installed"
  bold "Dumping Brewfile"
  run brew bundle dump --force --file="$BREWFILE"
  ok "packages/Brewfile rewritten — review the diff before committing"
}

# --------------------------------------------------- Brewfile management ------

# _brew_line <name> -> the Brewfile line for an entry, whichever kind it is
_brew_line() { grep -nE "^(brew|cask|tap|vscode|npm) \"$1\"$" "$BREWFILE" | head -1; }

# do_package_add <name> [--cask|--tap|--npm]
do_package_add() {
  local name="$1" kind="${2:---brew}" entry
  [[ -n "$name" ]] || die "usage: dot package-add <name> [--cask|--tap|--npm]"
  case "$kind" in
    --brew) entry="brew" ;;
    --cask) entry="cask" ;;
    --tap)  entry="tap" ;;
    --npm)  entry="npm" ;;
    *)      die "unknown kind: $kind (use --brew|--cask|--tap|--npm)" ;;
  esac
  if [[ -n "$(_brew_line "$name")" ]]; then
    warn "$name is already in the Brewfile"; return 0
  fi
  # Insert after the last line of the same kind so the file stays grouped.
  local last; last="$(grep -n "^$entry \"" "$BREWFILE" | tail -1 | cut -d: -f1)"
  if [[ -n "$DRY_RUN" ]]; then
    info "would add: $entry \"$name\""; return 0
  fi
  if [[ -n "$last" ]]; then
    awk -v n="$last" -v line="$entry \"$name\"" \
        'NR==n {print; print line; next} {print}' "$BREWFILE" > "$BREWFILE.tmp"
    mv "$BREWFILE.tmp" "$BREWFILE"
  else
    printf '%s "%s"\n' "$entry" "$name" >> "$BREWFILE"
  fi
  ok "added $entry \"$name\" to the Brewfile"
  info "run 'dot packages' to install it"
}

# do_package_remove <name>
do_package_remove() {
  local name="$1" found
  [[ -n "$name" ]] || die "usage: dot package-remove <name>"
  found="$(_brew_line "$name")"
  [[ -n "$found" ]] || { warn "$name is not in the Brewfile"; return 0; }
  local n="${found%%:*}"
  if [[ -n "$DRY_RUN" ]]; then info "would remove line $n: ${found#*:}"; return 0; fi
  # Drop the entry and the description comment immediately above it, if any.
  awk -v n="$n" 'NR==n-1 && /^#/ {skip=1; next} NR==n {next} {print}' \
      "$BREWFILE" > "$BREWFILE.tmp"
  mv "$BREWFILE.tmp" "$BREWFILE"
  ok "removed ${found#*:} from the Brewfile"
  info "it is still installed — 'brew uninstall $name' to actually remove it"
}

# do_package_list
do_package_list() {
  local kind
  for kind in tap brew cask npm; do
    bold "$kind"
    grep "^$kind \"" "$BREWFILE" | sed "s/^$kind \"/  /; s/\"$//" || true
  done
}

# do_check_packages — drift between the Brewfile and what is installed
do_check_packages() {
  have brew || die "Homebrew not installed"
  local drift=0

  bold "Formulae"
  # The two directions need different reference lists:
  #   installed-but-unlisted -> `brew leaves`, so the hundreds of transitive
  #     dependencies are not reported as things you forgot to write down;
  #   listed-but-missing     -> `brew list --formula`, because a formula can be
  #     installed as another package's dependency and so never appear in
  #     `leaves` (tmux arrives via tmuxp, for one).
  local only_installed only_file
  only_installed="$(comm -13 \
    <(grep '^brew "' "$BREWFILE" | sed 's/^brew "//; s/"$//' | sort -u) \
    <(brew leaves | sort -u))"
  only_file="$(comm -23 \
    <(grep '^brew "' "$BREWFILE" | sed 's/^brew "//; s/"$//' | sort -u) \
    <(brew list --formula | sort -u))"
  if [[ -n "$only_installed" ]]; then
    warn "installed but not in the Brewfile:"; echo "$only_installed" | sed 's/^/      /'; drift=1
  fi
  if [[ -n "$only_file" ]]; then
    warn "in the Brewfile but not installed:"; echo "$only_file" | sed 's/^/      /'; drift=1
  fi
  [[ -z "$only_installed$only_file" ]] && ok "in sync"

  bold "Casks"
  only_installed="$(comm -13 \
    <(grep '^cask "' "$BREWFILE" | sed 's/^cask "//; s/"$//' | sort -u) \
    <(brew list --cask | sort -u))"
  only_file="$(comm -23 \
    <(grep '^cask "' "$BREWFILE" | sed 's/^cask "//; s/"$//' | sort -u) \
    <(brew list --cask | sort -u))"
  if [[ -n "$only_installed" ]]; then
    warn "installed but not in the Brewfile:"; echo "$only_installed" | sed 's/^/      /'; drift=1
  fi
  if [[ -n "$only_file" ]]; then
    warn "in the Brewfile but not installed:"; echo "$only_file" | sed 's/^/      /'; drift=1
  fi
  [[ -z "$only_installed$only_file" ]] && ok "in sync"

  echo
  (( drift )) && { info "'dot packages --dump' adopts what is installed"; return 1; }
  bold "No drift."
}

# ------------------------------------------------------------------ fonts ----

# font_gate -> 0 when the SSH key needed for the private font repo exists
font_gate() {
  if [[ ! -f "$SSH_KEY" ]]; then
    warn "no SSH key at $SSH_KEY — run 'dot gen-ssh-key' first"
    return 1
  fi
  return 0
}

# do_fonts — clone the private font repo over SSH, copy the faces out, bin the
# clone. Matches how the repo is reached everywhere else (git over SSH) and
# needs no gh CLI.
do_fonts() {
  bold "Fonts"
  font_gate || return 0
  [[ -d "$FONT_DIR" ]] || run mkdir -p "$FONT_DIR"

  local tmp; tmp="$(mktemp -d)"
  if [[ -n "$DRY_RUN" ]]; then
    info "would: git clone --depth=1 $FONT_REPO"
    info "would: copy every .otf/.ttf into $FONT_DIR"
    rmdir "$tmp"; return 0
  fi

  info "cloning $FONT_REPO"
  if ! GIT_SSH_COMMAND="ssh -i '$SSH_KEY' -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
       git clone --depth=1 --quiet "$FONT_REPO" "$tmp" 2>/dev/null; then
    warn "clone failed — is $SSH_KEY added to your GitHub account? ('dot gen-ssh-key' prints it)"
    rm -rf "$tmp"
    return 1
  fi

  local count=0 f
  while IFS= read -r f; do
    cp "$f" "$FONT_DIR/"
    ok "$(basename "$f")"
    count=$((count + 1))
  done < <(find "$tmp" -type f \( -name '*.otf' -o -name '*.ttf' \))
  rm -rf "$tmp"

  if (( count == 0 )); then
    warn "no .otf/.ttf found in the repo"
    return 1
  fi
  ok "$count font file(s) -> $FONT_DIR"
}

# repo_font_names -> the font filenames the repo holds (one clone, for doctor)
repo_font_names() {
  [[ -f "$SSH_KEY" ]] || return 0
  local tmp; tmp="$(mktemp -d)"
  if GIT_SSH_COMMAND="ssh -i '$SSH_KEY' -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
     git clone --depth=1 --quiet "$FONT_REPO" "$tmp" 2>/dev/null; then
    find "$tmp" -type f \( -name '*.otf' -o -name '*.ttf' \) -exec basename {} \;
  fi
  rm -rf "$tmp"
}

# do_fonts_remove
do_fonts_remove() {
  bold "Fonts"
  local name count=0
  while IFS= read -r name; do
    [[ -n "$name" && -e "$FONT_DIR/$name" ]] || continue
    run rm "$FONT_DIR/$name"
    count=$((count + 1))
  done < <(repo_font_names)
  ok "$count font file(s)$([[ -n "$DRY_RUN" ]] && echo " would be removed from" || echo " removed from") $FONT_DIR"
}
