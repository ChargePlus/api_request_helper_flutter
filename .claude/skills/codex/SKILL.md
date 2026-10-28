---
name: codex
description: Optional Codex builder. Before implementation work in this package — build, implement, fix, add, refactor, write tests, investigate — check whether this machine has Codex (`.claude/scripts/codex.sh available`). If it does, Claude leads and Codex builds: Claude briefs, Codex (headless, its own git-flow worktree, sandboxed) codes and runs the gates, Claude reviews and ships. If it does not, Claude does the work itself as usual. Triggers: build, implement, fix, add, refactor, write tests, investigate, codex, delegate, offload.
---

# Optional: Claude leads, Codex builds

Codex is optional. Teammates with Codex installed and logged in get the work
split automatically; everyone else keeps the normal Claude-only flow, with
nothing to set up and nothing that breaks.

## 0. Is Codex here? (once per session)

```
.claude/scripts/codex.sh available
```

- **Exit 0**: delegate. Most of the load goes to Codex. Claude's tokens go to
  judgement: scoping, the brief, reviewing the diff, the consumer blast
  radius (CLAUDE.md), committing, the PR. Codex's go to reading code,
  editing, and running analyze/tests and fixing failures. Do it yourself
  only when that is faster than writing the brief (a one-line edit, a typo,
  a lookup you already know).
- **Non-zero**: work in Claude as you would without this skill. Don't
  mention Codex to the user unless they ask.
- Every other mode falls back the same way: **exit 3** with the reason on
  stderr (Codex logged out, the repo not trusted in Codex, or a base branch
  with no `.codex/config.toml` yet). If the reason is trust, tell the user
  once about the one-time fix it prints (run `codex` in the repo, accept the
  trust prompt), then carry on in Claude.

**Exit 4** means the Codex run itself failed: the report shows Codex's error. A
transient error (capacity, network) is worth one `resume`; otherwise do the
work in Claude. **Exit 2** from `resume`/`review` with "Codex changed its own
sandbox or guard files" is a security stop. Show the user the listed files and
don't continue that branch until they've looked.

Runs are long: launch `start`/`resume`/`review` with `run_in_background`
and wait for the notification; don't poll. Only Codex's final report is
printed. The full event log sits in `.git/codex-runs/<name>/`.

## 1. Brief (Claude)

Write the brief to the scratchpad. It is all Codex knows beyond AGENTS.md /
CLAUDE.md, so write it as a brief for a peer:

- **Goal**: the outcome for the consuming apps, and the issue/ticket if
  there is one.
- **Where**: files to start from, and the existing test to copy the
  pattern from.
- **Constraints**: public-API compatibility (CLAUDE.md blast-radius rules),
  dartdoc, what NOT to touch.
- **Acceptance**: the tests that must exist/pass, the states to cover.

The script prepends the hard rules (no commits, gates from
`.codex/delegate.conf`, report format), so don't repeat them.

## 2. Build (Codex)

```
.claude/scripts/codex.sh start feature|bugfix <camelCaseName> <brief.md> [--from <base>]
```

Fetches, runs `git flow <type> start <name> <base>` into the worktree path
from `.codex/delegate.conf`, and Codex works there. Codex leaves its
changes uncommitted. Independent features → several `start`s in parallel.

## 3. Review (Claude)

In the worktree, read `git diff` / `git status`: the actual code, not just
Codex's report. Check it against the brief and CLAUDE.md (public API
unchanged or every consumer planned, no silent behavior change in
retries, headers or status mapping, log redaction, tests).
Spot-check one gate yourself if the report looks thin. For a second
opinion, run `codex.sh review <name>` (read-only, against the branch's
base).

If there are problems, write feedback (file:line, what's wrong, what you expect) and run
```
.claude/scripts/codex.sh resume <name> <feedback.md>
```
This is the same Codex thread, so it keeps its context. Loop until clean. After three
rounds on the same issue, fix it yourself or ask the user.

## 4. Land (Claude)

Commit in the worktree (conventional message + attribution), push, and open
a PR into `develop`, then run the `routine` skill on it. Stop at the human
review gate; never merge. Codex can make the routine's fix-ups too: write the
triaged findings as feedback and run `resume`.

## Read-only questions

```
.claude/scripts/codex.sh ask <question.md>
```
For codebase sweeps ("where is X used", "how does Y flow"), run this on the main
checkout, read-only, instead of a long manual grep session or an
Explore agent.

## Sandbox

`.codex/config.toml` defines two permission profiles: a read-only one for
`ask`/`review`, and a `-build` one (the default) that adds worktree writes,
the pub/Flutter caches and network for `pub get`. Project `.codex/` config
loads only in a repo trusted in Codex (a worktree inherits its main
checkout's trust). Without it the profile is missing and Codex fails
closed, so the script checks first. `start` also needs the base branch to
carry `.codex/config.toml`; an older branch falls back to Claude.

`.claude/scripts/codex.sh` is shared verbatim with chargeplus_customer —
fix it there and copy it across rather than forking it.

## Housekeeping

- Never `resume`/`start` over another session's worktree. Codex worktrees
  belong to the session that started them.
- Clean up once the branch is merged or abandoned:
  `git worktree remove <worktree>` + `rm -rf .git/codex-runs/<name>`.
