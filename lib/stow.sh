#!/usr/bin/env bash
# Linking: GNU Stow drives it, with a preflight that clears the way first.

# pkg_files <pkg> -> paths inside the package, relative to the package root
pkg_files() {
  local pkg="$DOTFILES/$1"
  [[ -d "$pkg" ]] || return 0
  find "$pkg" \( -type f -o -type l \) \
       ! -name '.stow-local-ignore' ! -name '.DS_Store' -print \
    | sed "s|^$pkg/||"
}

# handle_ancestors <pkg> <root> <dest>
# Walks the directories above dest. Returns 0 when one of them is already the
# correct fold for this package (so dest needs no work at all), otherwise 1,
# having removed any ancestor that points into the repo but at the wrong place.
#
# _CLEARED keeps a folded directory from being reported once per file under it.
_CLEARED=""
handle_ancestors() {
  local pkg="$1" root="$2" dest="$3" acc="$2" p parts arel
  IFS='/' read -ra parts <<< "$(dirname "${dest#"$root"/}")"
  for p in "${parts[@]}"; do
    [[ "$p" == "." || -z "$p" ]] && continue
    acc="$acc/$p"
    is_our_link "$acc" || continue
    arel="${acc#"$root"/}"
    if [[ "$(link_target "$acc")" == "$DOTFILES/$pkg/$arel" ]]; then
      return 0                               # correct fold — leave it to --restow
    fi
    case "$_CLEARED" in *"|$acc|"*) continue ;; esac
    _CLEARED="$_CLEARED|$acc|"
    run rm "$acc"
    say warn "cleared stale link $acc"
  done
  return 1
}

# preflight <pkg> <target> — make every destination safe for stow to claim.
# Links that already point at the right source are left alone: `stow --restow`
# handles those, and deleting them first would churn every file on every run.
preflight() {
  local pkg="$1" target="$2" rel dest
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    dest="$target/$rel"

    handle_ancestors "$pkg" "$target" "$dest" && continue

    if is_our_link "$dest"; then
      [[ "$(link_target "$dest")" == "$DOTFILES/$pkg/$rel" ]] && continue
      run rm "$dest"                      # ours, but stale
      say warn "cleared stale link $dest"
    elif [[ -L "$dest" ]]; then
      warn "skip $dest — symlink points outside the repo ($(readlink "$dest"))"
    elif [[ -e "$dest" ]]; then
      back_up "$dest"                     # real file in the way
    fi
  done < <(pkg_files "$pkg")
}

# prune_orphans <target> <pkg>
# `stow --delete` only removes links whose source it still finds in the package,
# so deleting a file from the repo leaves a dangling symlink behind in $HOME
# forever. A symlink that points into this repo at a path which no longer
# exists is unambiguously ours and unambiguously stale, so drop it.
#
# Scanned bounded — $HOME itself at depth 1, plus the shared directories in
# full — rather than walking the whole home directory.
prune_orphans() {
  local target="$1" pkg="$2" l d pruned=0 seen="" parent
  local roots=("$target")
  while IFS= read -r d; do
    [[ -n "$d" && -d "$target/$d" ]] && roots+=("$target/$d")
  done < <(shared_dirs "$pkg")

  for d in "${roots[@]}"; do
    # $HOME itself only at depth 1; the shared directories in full. Nested
    # roots overlap (.local and .local/bin), hence the seen list.
    local depth=(); [[ "$d" == "$target" ]] && depth=(-maxdepth 1)
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      case "$seen" in *"|$l|"*) continue ;; esac
      seen="$seen|$l|"
      is_our_link "$l" || continue
      [[ -e "$l" ]] && continue          # resolves fine — not an orphan
      run rm "$l"
      say warn "pruned orphaned link $l"
      pruned=$((pruned + 1))
      # The directory that held it is often now empty (a whole tool's config
      # removed from the repo). rmdir only succeeds when it really is empty.
      parent="$(dirname "$l")"
      if [[ "$parent" != "$target" ]] && [[ -z "$(ls -A "$parent" 2>/dev/null)" ]]; then
        run rmdir "$parent" && say info "removed empty $parent"
      fi
    done < <(find "$d" "${depth[@]+${depth[@]}}" -type l 2>/dev/null)
  done
  (( pruned )) && info "$pruned orphaned link(s)$([[ -n "$DRY_RUN" ]] && echo " would be pruned" || echo " pruned")"
  return 0
}

# do_link
do_link() {
  local pkg target d
  have stow || die "stow not installed — run 'dot packages' first (or: brew install stow)"

  bold "Linking"
  _CLEARED=""
  while IFS=$'\t' read -r pkg target; do
    [[ -d "$DOTFILES/$pkg" ]] || { warn "no such package: $pkg"; continue; }
    [[ -d "$target" ]] || run mkdir -p "$target"

    # Pre-create the directories this repo must not own outright, so stow
    # descends into them instead of folding them into one symlink. Without
    # this, a fresh machine with no ~/.config ends up with ~/.config itself
    # pointing into the repo. See shared_dirs() in lib/common.sh.
    while IFS= read -r d; do
      [[ -n "$d" && ! -d "$target/$d" ]] || continue
      run mkdir -p "$target/$d"
      info "kept real: $target/$d"
    done < <(shared_dirs "$pkg")

    prune_orphans "$target" "$pkg"
    preflight "$pkg" "$target"
    # --restow makes this idempotent and prunes links whose source has moved
    run stow --dir="$DOTFILES" --target="$target" --restow ${DRY_RUN:+--simulate} "$pkg"
    ok "$pkg -> $target"
  done < <(stow_packages)
}

# do_unlink
do_unlink() {
  local pkg target
  have stow || die "stow not installed"

  bold "Unlinking"
  while IFS=$'\t' read -r pkg target; do
    [[ -d "$DOTFILES/$pkg" ]] || continue
    run stow --dir="$DOTFILES" --target="$target" --delete ${DRY_RUN:+--simulate} "$pkg"
    ok "$pkg unlinked from $target"
  done < <(stow_packages)
}

# do_restore — unlink, then put the newest backup back
do_restore() {
  local pkg target rel dest restore
  do_unlink

  bold "Restoring backups"
  while IFS=$'\t' read -r pkg target; do
    while IFS= read -r rel; do
      [[ -n "$rel" ]] || continue
      dest="$target/$rel"
      restore="$(newest_backup "$dest")"
      [[ -n "$restore" ]] || continue
      # Under --dry-run the unlink above only simulated, so our own links are
      # still on disk. Treat those as already gone, or every restore would be
      # reported as blocked by a file that a real run would have removed.
      if [[ -e "$dest" ]] && ! { [[ -n "$DRY_RUN" ]] && is_our_link "$dest"; }; then
        warn "skip $dest — something is already there"
        continue
      fi
      if [[ -n "$DRY_RUN" ]]; then
        info "would restore $dest  (from ${restore##*/})"
      else
        mv "$restore" "$dest"
        ok "restored $dest  (from ${restore##*/})"
      fi
    done < <(pkg_files "$pkg")
  done < <(stow_packages)
}

# do_cleanup — drop backups, but only where the link actually landed
do_cleanup() {
  local pkg target rel dest bak removed=0 kept=0
  bold "Removing backups"
  while IFS=$'\t' read -r pkg target; do
    while IFS= read -r rel; do
      [[ -n "$rel" ]] || continue
      dest="$target/$rel"
      while IFS= read -r bak; do
        [[ -n "$bak" ]] || continue
        if is_linked_here "$dest" "$target"; then
          if [[ -n "$DRY_RUN" ]]; then
            info "would remove ${bak##*/}"
          else
            rm -rf "$bak"; ok "removed ${bak##*/}"
          fi
          removed=$((removed + 1))
        else
          warn "kept ${bak##*/} — $dest is not linked to the repo"; kept=$((kept + 1))
        fi
      done < <(backups_for "$dest")
    done < <(pkg_files "$pkg")
  done < <(stow_packages)
  local suffix="" verb="removed"
  (( kept )) && suffix=", $kept kept"
  [[ -n "$DRY_RUN" ]] && verb="would be removed"
  bold "Done. $removed $verb$suffix."
}
