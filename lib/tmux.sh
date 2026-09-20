#!/usr/bin/env bash
# tmux plugins. Sourced by `dot` — never run directly.
#
# home/.tmux.conf loads catppuccin with a plain `run`, not TPM: one plugin does
# not justify a plugin manager, and pinning the tag here keeps the status bar
# from moving under us when upstream changes its option names (v1 -> v2 renamed
# most of them).

TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
CATPPUCCIN_REPO="https://github.com/catppuccin/tmux.git"
CATPPUCCIN_TAG="v2.3.0"

# do_tmux_plugins — clone catppuccin at the pinned tag, or move an existing
# clone onto it. Idempotent: re-running on an already-correct checkout is a
# no-op.
do_tmux_plugins() {
  bold "tmux plugins"
  have git || die "git not installed"

  local dest="$TMUX_PLUGIN_DIR/tmux"

  if [[ -d "$dest/.git" ]]; then
    # Already cloned — only fetch when the checkout is off the pinned tag, so
    # the common case costs nothing and works offline.
    #
    # Compared by commit, not by `describe`: upstream also publishes a moving
    # `latest` tag on the same commit, and describe picks that name over the
    # version one, which would make every run look like a mismatch.
    local head want
    head="$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)"
    want="$(git -C "$dest" rev-parse "$CATPPUCCIN_TAG^{commit}" 2>/dev/null || true)"
    if [[ -n "$head" && "$head" == "$want" ]]; then
      ok "catppuccin $CATPPUCCIN_TAG"
      return 0
    fi
    info "catppuccin ${head:0:7} -> $CATPPUCCIN_TAG"
    run git -C "$dest" fetch --tags --quiet origin
    run git -C "$dest" checkout --quiet "$CATPPUCCIN_TAG"
    say ok "catppuccin $CATPPUCCIN_TAG"
    return 0
  fi

  # A non-repo directory here means something else put it there; back it up
  # rather than clobbering it, the same way `dot link` treats real files.
  [[ -e "$dest" ]] && back_up "$dest"

  run mkdir -p "$TMUX_PLUGIN_DIR"
  info "cloning catppuccin $CATPPUCCIN_TAG"
  run git clone --depth=1 --branch "$CATPPUCCIN_TAG" --quiet \
      "$CATPPUCCIN_REPO" "$dest"
  say ok "catppuccin $CATPPUCCIN_TAG -> $dest"
}

# do_tmux_plugins_remove — drop the clone. `dot revert` calls this; the conf
# itself is a stow link and comes out with the rest.
do_tmux_plugins_remove() {
  bold "tmux plugins"
  local dest="$TMUX_PLUGIN_DIR/tmux"
  if [[ ! -d "$dest" ]]; then
    ok "nothing to remove"
    return 0
  fi
  run rm -rf "$dest"
  say ok "removed $dest"
}
