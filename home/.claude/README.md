# Agent skills

Quick reference: what to type, and when. Adapted from
[mattpocock/skills](https://github.com/mattpocock/skills) and
[cursor/plugins](https://github.com/cursor/plugins) (the `pstack` skill set).

## The spec → ticket → build chain

| Type this                  | When                                                                |
| -------------------------- | ------------------------------------------------------------------- |
| `/setup-agent-conventions` | First time using these skills in a repo (once)                      |
| `/grill-with-docs`         | You have a rough idea and want it interrogated into something solid |
| `/to-spec`                 | The idea's solid — turn the conversation into a written spec        |
| `/to-tickets`              | You have a spec/plan — break it into buildable tickets              |
| `/implement`               | You have a spec or tickets — build it                               |
| `/diff-review`             | Review a diff before committing                                     |
| `/tdd`                     | Build test-first, one seam at a time                                |

```
setup (once) → grill-with-docs → to-spec → to-tickets → implement
```

`implement` calls `/tdd` and `/diff-review` on its own — you usually don't
need to run those two by hand, only reach for them directly for a one-off.

## Other tools

| Type this                        | When                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------ |
| `/triage`                        | Sort an incoming issue or PR into a triage state before it's spec'd            |
| `/wayfinder`                     | The work is too big for one session — plan it as a map of tickets              |
| `/improve-codebase-architecture` | Scan a codebase for design improvements, then grill through one                |
| `/codebase-design`               | Deciding a module's interface or where a seam goes                             |
| `/diagnosing-bugs`               | A hard bug or perf regression needs a disciplined diagnosis loop               |
| `/resolving-merge-conflicts`     | Mid merge/rebase, working conflicts hunk by hunk                               |
| `/prototype`                     | Sanity-check a UI or state model with a throwaway build                        |
| `/research`                      | Hand off reading/API research to a background agent                            |
| `/wizard`                        | Generate a walkthrough for steps only a human can do (credentials, dashboards) |
| `/wait-what`                     | My last answer missed the point — re-pitch it plainly                          |

## Writing & review

From `cursor/plugins`, not the mattpocock chain above.

| Type this             | When                                                                     |
| ---------------------- | ------------------------------------------------------------------------ |
| `/unslop`              | Cut AI writing tells (jargon, em dashes, filler) from any text           |
| `/technical-writing`   | Writing or reviewing docs, RFCs, readmes, PR descriptions, commit messages |
| `/no-comments`         | Sweep a diff for dead/workaround comments, fix what's accepted           |

`no-comments` spawns a custom subagent, **Comment Sicko**
(`home/.claude/agents/comment-sicko.md`), to do the actual comment audit.
That file has to exist for the skill to work, it isn't optional. It also
leans on `/architect`, `/how`, and `/why` for judgment calls mid-flow.
None of those three are installed, so it just reasons those steps out
directly instead of skipping them.

## Notes

- Model-invocable on trigger phrasing, not just typed: `grilling`,
  `domain-modeling`, `tdd`, `diff-review`, `codebase-design`,
  `resolving-merge-conflicts`, `diagnosing-bugs`, `research`, `wizard`,
  `prototype`. Everything else is manual-only.
- `diff-review` is Matt Pocock's `code-review`, renamed — `/code-review`
  already belongs to a different plugin on this machine.
- Full detail lives in each skill's own file. The real copy is
  `home/.agents/skills/<name>/SKILL.md` in the dotfiles repo, which lands at
  `~/.agents/skills/<name>/`, the cross-client path other agents read.
  `~/.claude/skills/<name>` is a symlink to it, because Claude Code only scans
  its own directory. Edit the copy under `.agents/`, never the symlink.
- These skills are not Claude-only. Cursor, Codex, Gemini CLI, opencode and Amp
  read `~/.agents/skills/` too, so anything written here works in all of them.
  Wording that names Claude specifically will read oddly elsewhere.
