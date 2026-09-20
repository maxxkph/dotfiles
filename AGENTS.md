# AGENTS.md

Dotfiles for one macOS machine. `home/` is a GNU Stow package that mirrors onto
`$HOME`, so a file's path in this repo is its path in `$HOME`. The `dot` script
is the only entry point.

There is no `CLAUDE.md` here on purpose. Claude Code reads this file instead from
version 2.1.277 on, but only when a folder has no `CLAUDE.md`, so adding one
would hide this file from every other agent.

## Ground rules

- macOS only. No Linux branch exists in the tooling, so do not add one.
- Bash 3.2, which is what macOS ships. No `declare -A`, no `${var,,}`, no
  `readarray`. Guard `${arr[@]}` on possibly-empty arrays or `set -u` aborts.
- Every mutating action goes through `run()` so `dot --dry-run` stays honest. A
  message describing what `run()` just did goes through `say()`, which stays
  quiet under `--dry-run`.
- `set -euo pipefail` is on in `dot`. Commands that may fail need `|| true`.

## Where things go

| Path | Holds |
| ---- | ----- |
| `dot` | the CLI, argument parsing and command dispatch |
| `lib/common.sh` | logging, dry-run, symlink helpers, `shared_dirs()` |
| `lib/stow.sh` | link, unlink, prune, restore, cleanup |
| `lib/packages.sh` | Homebrew, the Brewfile, fonts |
| `lib/doctor.sh` | the health check |
| `home/` | the stow package, mirrored onto `$HOME` |
| `packages/Brewfile` | every formula, cask and npm global |

## Agent skills

The skills themselves live in `home/.agents/skills/<name>/SKILL.md`, which lands
at `~/.agents/skills/`, the cross-client path from the
[Agent Skills spec](https://agentskills.io/specification). Claude Code reads only
`~/.claude/skills/`, so `home/.claude/skills/<name>` is a relative symlink to
`../../.agents/skills/<name>`. Both paths reach the same file.

Adding a skill takes two steps:

```sh
mkdir -p home/.agents/skills/<name>          # then write SKILL.md
ln -s ../../.agents/skills/<name> home/.claude/skills/<name>
dot link
```

The `name` in the frontmatter has to match the directory name. Never edit a file
through `home/.claude/skills/`; edit the real copy under `home/.agents/skills/`.

## Verifying a change

```sh
./dot --dry-run link    # what linking would do, changes nothing
./dot link              # idempotent
./dot doctor            # links, tools, fonts, backups, repo state
bash -n lib/*.sh dot    # syntax
```

`dot relink` after moving files in the repo. `shared_dirs()` in `lib/common.sh`
lists the directories stow must descend into rather than fold into one symlink.
Any directory that other software writes into belongs on that list, or that
software's writes land inside this repo.
