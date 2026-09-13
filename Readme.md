# Dotfiles

Configs for **Ghostty**, **Neovim**, **Zed**, **tmux**, **zsh**, **git** and
**Claude Code**, with one CLI to set up a fresh Mac. **macOS only** — there is no
Linux branch anywhere in the tooling.

## Install

One line on a fresh machine — installs git, clones to `~/dotfiles`, runs the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/maxxkph/dotfiles/main/dot | bash -s -- install
```

Already cloned:

```sh
~/dotfiles/dot install     # every step, in order
~/dotfiles/dot doctor      # verify
```

## The `dot` CLI

```
Setup
  dot install [--work]   run every step below, in order
  dot retry-failed       re-run only the steps that failed last time
  dot gen-ssh-key [mail] create an SSH key and add it to GitHub
  dot link               stow the configs into place (idempotent)
  dot unlink             remove the symlinks stow created
  dot relink             unlink + link — use after moving files in the repo
  dot fonts              fetch the private font repo over SSH and install it

Packages
  dot packages [--work]  install from packages/Brewfile
  dot packages --dump    rewrite packages/Brewfile from what is installed
  dot package-add <name> [--cask|--tap|--npm]
  dot package-remove <name>
  dot package-list       what the Brewfile holds
  dot check-packages     drift between the Brewfile and what is installed

Maintenance
  dot doctor             health check — links, tools, fonts, backups, repo
  dot update             git pull, then packages + relink
  dot revert             unlink and restore the backups install made
  dot cleanup            delete backups, where linking succeeded
  dot benchmark-shell [n]  time zsh startup over n runs (default 10)
  dot edit               open the repo in $EDITOR
  dot completions        print a zsh completion for dot
```

Every command takes `--dry-run` (or `DRY_RUN=1`) and changes nothing when given.

`dot install` walks a registry of steps (`install_steps()` in `dot`), each marked
required or optional. Optional steps that fail are recorded to `.dot-state/failed`
and `dot retry-failed` re-runs just those; a required step aborts the run.

## Layout

```
dot                  the CLI
lib/
  common.sh          logging, dry-run, paths, symlink + state helpers
  stow.sh            link / unlink / prune / restore / cleanup
  packages.sh        Homebrew, the Brewfile, the font
  setup.sh           gen-ssh-key, benchmark-shell, edit, completions
  doctor.sh          health check

home/                the stow package -> ~
  .claude/           settings.json, statusline.sh, skills/, agents/, themes/ (4)
  .config/
    ghostty/         config (themes come from Ghostty's bundled Catppuccin set)
    nvim/            LazyVim + lua/config, lua/plugins, colors/
    zed/             settings.json, keymap.json
  .local/bin/
    delta-auto       delta, with the flavour picked from the OS appearance
  Library/
    Application Support/
      lazygit/       config.yml -- where lazygit looks on macOS
  .gitconfig
  .tmux.conf
  .zshrc

packages/
  Brewfile           formulae, casks, npm globals
```

Fonts are not in this repo — see [Fonts](#fonts).

## How linking works

GNU Stow mirrors `home/` onto `~`, so a file's path in the repo *is* its path in
`$HOME`. One package, because `$HOME` is now the only target.

`dot link` does three things before handing over to stow:

**Prunes orphans.** `stow --delete` only removes links whose source it still finds
in the package, so deleting a file from the repo would otherwise leave a dangling
symlink in `$HOME` forever. A symlink pointing into this repo at a path that no
longer exists is unambiguously ours and unambiguously stale, so it goes — along with
the directory that held it, if that is now empty.

**Keeps shared directories real.** Stow folds a directory into a single symlink when
the target does not exist. That is wanted where the repo owns the whole directory —
`~/.config/nvim` is one link, so anything added there is instantly tracked. It is
dangerous where the directory is shared: on a machine with no `~/.config` yet, stow
would make `~/.config` itself a symlink into this repo and every other tool's config
would be written inside it. `shared_dirs()` lists the four that must stay real
(`.config`, `.claude`, `.local`, `.local/bin`); `dot link` pre-creates them so stow
has to descend.

**Clears only genuinely stale links.** A link already pointing at the right source is
left for `stow --restow`; deleting and recreating all of them every run would churn
every file and leave a window with nothing linked if stow then failed. A real file in
the way is moved to `<name>.bak` (or `<name>.bak-<timestamp>`, so a backup is never
clobbered). A symlink pointing *outside* the repo is left alone and reported.

`dot revert` undoes it and restores the newest backup. `dot cleanup` drops backups,
but only where the link actually landed.

`home/.stow-local-ignore` replaces stow's default ignore list, which would otherwise
skip `README.*`, `LICENSE.*` and `.gitignore` — all of which legitimately belong
inside `home/.config/nvim`.

## Themes

Catppuccin everywhere, following the macOS appearance: **Frappé** when the system
is dark, **Latte** when it is light. Every tool switches on its own, so there is
nothing to run when the appearance changes.

| | dark | light | how |
|---|---|---|---|
| ghostty | `Catppuccin Frappe` | `Catppuccin Latte` | native `theme = light:…,dark:…` |
| nvim | `catppuccin-frappe` | `catppuccin-latte` | `auto-dark-mode.nvim` swaps the colorscheme |
| git diffs | frappé | latte | `delta-auto` resolves the flavour per invocation |
| Claude Code | `catppuccin-frappe` | | one string in `.claude/settings.json` |
| tmux | — | — | inherits the terminal (`bg=default,fg=default`) |

## Fonts

The editor font is licensed, so it lives in a **private** repo. `dot fonts` clones it
over SSH into a temp directory, copies every `.otf`/`.ttf` into `~/Library/Fonts`, and
deletes the clone — so adding weights to that repo needs no change here.

```sh
dot gen-ssh-key      # once, on a new machine
dot fonts
```

Family names for configs: **`MonoLisa Nerd Font Mono`** and **`Osaka`**.

It needs `~/.ssh/id_ed25519` to exist and be registered with GitHub, which is what
`dot gen-ssh-key` sets up (it also writes a `github.com` block into `~/.ssh/config`
with `UseKeychain`, and copies the public key to the clipboard). Without a key,
`dot fonts` warns and skips rather than failing the whole install.

## Packages

`packages/Brewfile` is the source of truth — `brew bundle` handles formulae, casks and
npm globals from that one file.

```sh
dot package-add ripgrep           # or --cask / --tap / --npm
dot package-remove k6
dot check-packages                # drift, both directions
dot packages --dump               # adopt whatever is installed
```

`check-packages` compares the two directions against different lists on purpose:
*installed but unlisted* uses `brew leaves`, so hundreds of transitive dependencies
are not reported as things you forgot to write down; *listed but missing* uses
`brew list --formula`, because a formula can arrive as another package's dependency
and so never appear in `leaves` — `tmux` is one here, arriving as a dependency
rather than being requested directly.

Two entries are load-bearing and easy to lose in a prune: **stow** (`dot link` needs
it) and **starship** (`home/.zshrc` initialises it).

## Neovim

[LazyVim](https://lazyvim.org) on lazy.nvim, so everything in `lua/plugins/` is an
override of a LazyVim default rather than a config from scratch. Custom keymaps are
in `lua/config/keymaps.lua`, notes on them in `cheatsheet.txt`. Format-on-save is
off, `<leader>cf` formats on request.

## Git

`delta` is the pager, via `home/.local/bin/delta-auto`, a wrapper that picks the
catppuccin flavour from the macOS appearance. lazygit ignores `core.pager`, so it
names the wrapper again in its own config.

## Claude Code

`home/.claude/` holds the settings, statusline, themes and 22 skills vendored from
[mattpocock/skills](https://github.com/mattpocock/skills) and
[cursor/plugins](https://github.com/cursor/plugins).
[`home/.claude/README.md`](home/.claude/README.md) says which skill to type, and when.
