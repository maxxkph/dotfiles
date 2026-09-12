# 🛠️ Dotfiles

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
  .claude/           settings.json, statusline.sh, themes/ (4)
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

Claude Code takes a single theme string, so it cannot switch between two custom
themes on its own; `.claude/themes/` holds all four flavours and `/theme` picks
one. Its statusline *does* follow the appearance, since that is a script.

**Changing the dark flavour** means three files that have to agree with each
other, plus `/theme` for Claude Code, which is set on its own:

- `home/.config/ghostty/config` — uncomment one of the alternatives. All four
  flavours ship with Ghostty, so there is nothing to install.
- `home/.config/nvim/lua/plugins/theme.lua` — the `LazyVim` `opts.colorscheme`
  *and* the `auto-dark-mode` callback. LazyVim applies its one at startup, before
  auto-dark-mode's first poll, so a mismatch shows the wrong theme briefly and
  then swaps.
- `home/.gitconfig` — the `[delta "catppuccin-…"]` blocks, plus the names
  `delta-auto` chooses between.

Nothing in nvim hardcodes a colour. The Snacks indent and diff highlights
(`lua/config/options.lua`) and the buffer tabs (`lua/plugins/bufferline.lua`) are
both derived from groups the active theme defines, re-running on every
`ColorScheme` event; `lua/config/palette.lua` holds the shared helpers. The diff
backgrounds are the theme's own green and red mixed into its background at 0.20,
and `home/.gitconfig` gives delta the same values, so a diff looks the same in
the pager as in the editor.

**maxx-mellow**, the previous colorscheme, is still present:
`colors/maxx-mellow{,-dawn}.lua` alias `oldworld.nvim`, which stays installed.
Going back is a change to `theme.lua` and nothing else.

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

ghostty uses `Osaka` from this repo. Note that `Osaka` does not appear in
`ghostty +list-fonts`, because that listing only surfaces families flagged monospace
and this face is not (`post.isFixedPitch = 0`) — naming it explicitly still resolves,
which `ghostty +show-face --string=A` confirms.

zed deliberately sets no `buffer_font_family` and falls back to its own default.

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

[LazyVim](https://lazyvim.org) on lazy.nvim. `init.lua` is one line,
`require("config.lazy")`, which bootstraps lazy.nvim, imports `lazyvim.plugins`, then
imports `lua/plugins/` on top — so everything here is an *override* of a LazyVim
default rather than a config from scratch.

```
lua/config/     lazy.lua (bootstrap), options, keymaps, autocmds, palette
lua/plugins/    theme, bufferline, dashboard, snacks, example
colors/         maxx-mellow, maxx-mellow-dawn
cheatsheet.txt  keymap notes
```

`lua/plugins/example.lua` is LazyVim's shipped sample. It starts with
`if true then return {} end`, so it loads nothing — it is kept as a reference for the
override syntax.

Pickers are **snacks.nvim**, not telescope: `<leader><space>` smart-find,
`<leader>ff`/`fg`/`fb` files/grep/buffers, `<leader>g*` for git. Sessions come from
`persistence.nvim` (`<leader>qs` restores). `obsidian.nvim` points at `~/obsdn` with
its inline markdown rendering off, matching `conceallevel = 0` in
`lua/config/options.lua`.

### Keymaps

`lua/config/keymaps.lua` adds only what LazyVim does not already provide. The
navigation keys append `zz`, so the cursor stays centred:

| | |
|---|---|
| `<C-u>` `<C-d>` `{` `}` `G` `gg` `<C-i>` `<C-o>` `*` `#` | move, then centre |
| `<Tab>` / `<S-Tab>` | next / previous buffer |
| `H` / `L` | start / end of line, in normal and visual |
| `U` | redo |
| `jj` `JJ` | leave insert mode |
| `<A-j>` / `<A-k>` (visual) | move the selection, keeping it selected |
| `<leader>no` `<leader>=` `<leader>ss` | clear search, equalise splits, spelling |

`H`/`L` take over LazyVim's `<S-h>`/`<S-l>` buffer navigation, which `<Tab>` and
`<S-Tab>` replace; `[b` and `]b` still work too. `n`/`N` are deliberately left
alone — LazyVim already remaps them to append `zv`, which opens folds, and
overriding that to `zz` would trade one behaviour for the other.

Note `<Tab>` and `<C-i>` are the same byte on a classic terminal, so the buffer
mapping can swallow the centred `<C-i>`. Ghostty tells them apart via the kitty
keyboard protocol and Neovim keeps them as separate keymap entries, so both work
here; somewhere that is not true, `<C-i>` would switch buffers.

## Git

`delta` is the pager, wired up in `home/.gitconfig`. `home/.local/bin/delta-auto`
is a small wrapper that resolves the catppuccin flavour from the macOS appearance
and then execs it, so diffs follow the light/dark switch.

git runs `core.pager` through a shell and could do that inline, but lazygit
invokes a pager on its own terms, so the resolution lives in the wrapper where
every caller reaches it.

**lazygit does not use `core.pager`**, so it names the wrapper again in its own
config. That file lives at `home/Library/Application Support/lazygit/config.yml`,
because that is where lazygit looks on macOS unless `XDG_CONFIG_HOME` is set —
and setting that would move the config path for every other tool honouring it.
Its shape is version-specific: 0.58 takes a list under `git.pagers`, and older
guides showing `git.paging.pager` are silently ignored.

`merge.conflictstyle` is `zdiff3`, which keeps the common ancestor's version in a
conflict so it is clear what each side actually changed.
