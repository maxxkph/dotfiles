# Agent skills

Quick reference: what to type, and when. Adapted from
[mattpocock/skills](https://github.com/mattpocock/skills).

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

## Notes

- Model-invocable on trigger phrasing, not just typed: `grilling`,
  `domain-modeling`, `tdd`, `diff-review`, `codebase-design`,
  `resolving-merge-conflicts`, `diagnosing-bugs`, `research`, `wizard`,
  `prototype`. Everything else is manual-only.
- `diff-review` is Matt Pocock's `code-review`, renamed — `/code-review`
  already belongs to a different plugin on this machine.
- Full detail lives in each skill's own file, `skills/<name>/SKILL.md`.
