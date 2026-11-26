# pstack in api_request_helper_flutter

pstack (Lauren Tan, MIT, `cursor/plugins`, `harness/pstack`) is the only
process here. Start non-trivial work with `/pstack:poteto-mode` and run its
playbooks, principles and skills in full. This repo adds no process of its
own, only quality gates on top. A gate never replaces a pstack step, and a
pstack step never skips a gate. pstack yields only at the hard stops below.

This is the HTTP layer under every network call the apps make, pulled by
unpinned git URL (CLAUDE.md). A change that lands on `main` reaches every
consumer on its next `pub get`, so the gates weigh the consumers as much as
the code.

Ezra's words in chat come first, and grant only what they name. "Keep
going", "run until done" or "be fully autonomous" is not approval for any
hard stop.

## Install and upgrade

- `.claude/settings.json` declares the `cursor-plugins` marketplace pinned
  to a commit and enables `pstack@cursor-plugins`. Trust the folder and the
  plugin installs on the next session, or run
  `claude plugin install pstack@cursor-plugins --scope project`. A
  SessionStart hook (`.claude/hooks/pstack_session_context.py`) then tells
  each session that pstack leads and gives it the resolved skill path.
- pstack skills are slash-only. An agent runs one by reading
  `<pstack>/skills/<name>/SKILL.md`, where `<pstack>` is the `installPath`
  of `pstack@cursor-plugins` in `~/.claude/plugins/installed_plugins.json`.
- The model roles live in the committed `.claude/rules/pstack-models.md`,
  which loads as a project rule in this repo and its worktrees only.
  `/pstack:setup-pstack` writes to the user-global `~/.claude/rules/`
  instead: after a re-run, move its output into the repo file and delete
  the global copy. The repo file puts `codex` in the code-writing roles and
  in the non-Claude seat of `arena runners`, `interrogate reviewers` and
  `arena cross-judge pool`.
- **Codex** is optional. Where it is installed, logged in and has trusted
  this repo (run `codex` once in the main checkout and accept the trust
  prompt), a role set to `codex` runs on it; see "Codex is a subagent".
  Anywhere else the role falls back to `opus` at the role's effort.
- Codex reads worker.md from a per-user cache,
  `${XDG_CACHE_HOME:-~/.cache}/chargeplus/pstack/<ref>/`, which
  chargeplus_customer's `scripts/install_pstack_codex.sh` fills. Without
  it, `codex.sh` sends no pstack kickoff and says so.
- **Upgrade:** change `ref` in `.claude/settings.json` to the new full
  commit SHA (never a branch), run `claude plugin marketplace update
  cursor-plugins`, then `claude plugin update pstack@cursor-plugins`. The
  marketplace pin is shared per machine, so bump the sibling ChargePlus
  repos in the same sitting. Read the upstream diff of
  `harness/pstack/claude-code/skills/` before you commit the bump.

## Hard stops (the only places pstack yields)

1. **Human approvals.** "Just do it" and *Never Block on the Human* cover
   everything except these, which stop for Ezra:
   - merging into `develop` or `main`, and cutting a release (Ezra invoking
     `cut-release` is the approval for that release; an agent never starts
     it on its own)
   - a change the review gates classify as **Behavior** or **Breaking**
     (`review/gates.md`, API compatibility): Ezra approves the plan and the
     consumer PRs before the library PR is merge-ready
   - raising the `sdk` or `flutter` floor in `pubspec.yaml`, a new
     dependency, or a narrower range on an existing one: each one lands in
     every consumer's dependency graph
2. **No merging.** Shipping and Autonomous-run playbooks stop at
   merge-ready. Never `gh pr merge`, never auto-merge, never self-approve.
   Every verification step before the merge still runs.
3. **No destructive git.** No force-push to a pushed branch
   (`--force-with-lease` included), no `reset --hard`, no `clean -f`, and
   **never `git stash`**: use `git show <ref>:<path>` or a throwaway
   worktree. When `develop` moves after the first push, merge it in.
4. **Forge and branches.** `git flow feature|bugfix start <camelCase>` from
   `develop` (base on `origin/develop` when the local branch is behind),
   PRs into `develop` with `gh pr create --base develop` (the GitHub
   default is `main` and nothing catches the mistake), and `gh` only. No
   stacked PRs on a base other than `develop` unless Ezra asks, which rules
   out Autopilot-stack.
5. **Secrets and the public repo.** This repository is public. Never commit
   a key, token, dart-define value, internal hostname beyond the ones the
   code already names, staging URL, customer data or private ticket text,
   in code, tests, fixtures, docs, commit messages or the PR body. Never
   read, list or copy a consumer's key files during a consumer sweep.
6. **The PR body.** `.github/PULL_REQUEST_TEMPLATE.md`, with its `## Review
   gates` section filled in (`review/gates.md`, The Review gates block).
   pstack's own headings (`Why`, `What changed`, `Scope`, `Tradeoffs`,
   `Blast Radius`, `Verification`) go as `###` headings inside the template's
   Description, not instead of it. The Review gates section is required on top of
   worker.md's heading list, and the **Review gates** CI check fails the PR
   without it. The PR title is a Conventional Commit, which CI checks.
   worker.md's 40-line cap counts the Description only, not the template
   or the Review gates section.
7. **Tools we don't have.** `/deslop`, `control-ui` and `control-cli` come
   from Cursor's `cursor-team-kit`. Here `/deslop` and `control-cli` are the
   repo skills of those names in `.claude/skills/`: `deslop` runs `/pstack:no-comments`,
   `/pstack:unslop`, the built-in `/simplify` and the build gates;
   `control-cli` runs the independent verdict from a scratch consumer
   (`review/gates.md`). There is no app, so a step that says `control-ui`
   uses `control-cli`. Skip Bugbot, Cursor automations and cloud agents
   with a one-line note; for a cloud verifier use a fresh local subagent.

## Add-on gates (run in addition to pstack's steps)

| Stage | Add-on |
| --- | --- |
| Design | For any change to a public symbol or to retries, headers, status mapping, parsing, timeouts or logging, classify it first (`review/gates.md`, API compatibility). A Breaking change follows `/pstack:principle-migrate-callers-then-delete-legacy-apis`: add the new API beside the old, migrate every consumer, delete the old one in a later release. |
| Build | pstack's code delegate is the `codex` subagent where Codex is available (Codex builds in its own worktree), else Claude. CLAUDE.md binds every delegate. A bug fix proves RED then GREEN on the test that ships. |
| Before commit | The `deslop` skill: cleanup, then `dart format --line-length 80 --set-exit-if-changed lib test`, `flutter analyze lib test` and `very_good test -j 4 --coverage --test-randomize-ordering-seed random` (CLAUDE.md, Verify). A new word in any `.md` goes in `.github/cspell.json`. |
| Review and verify | The `review-gates` skill: it runs the gates in `review/gates.md` that the diff triggers, in that file's order, and writes the PR body's Review gates section, which CI checks. |
| PR | The PR body (hard stop 6), `--base develop`, `--assignee @me`. |
| Release | `cut-release`: it checks every PR since the last tag carries a Review gates section, and takes the bump from their API change lines. |
| Evidence | `show-me-your-work` trails go to the scratchpad, linked or summarized in the PR. No scratch output is committed. |

## Playbooks: pstack steps + add-ons

| pstack playbook | Runs in full, plus |
| --- | --- |
| Feature, Bug fix, Refactoring | the API classification before design; the `review-gates` skill through the independent verdict (its verify step is `control-cli`) |
| Perf issue, Hillclimb, `benchmark-checklist` | the API compatibility gate: a retry, timeout or backoff change multiplies load across every app |
| Investigation | a `codex` subagent with `Mode: ask` for repo-wide sweeps; the consumer sweep in `gates.md` for "who calls this" |
| Opening a PR | runs as step 5 of the `review-gates` skill, after the branch is gated; hard stops 4 and 6 |
| Shipping | step 1, the independent verdict, is the `control-cli` skill; everything after it stops at merge-ready (hard stop 2) |
| Babysit | as written; it never rebases or merges. Take status from `gh pr checks <n>` and `gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision` where the watcher needs `bun` and it is missing. |
| Pause safely, Session pickup | as written. The resume note stays out of the repo (it is public): the scratchpad or an untracked file. |
| Autonomous run, Autopilot-full | hard stops 1 and 2 still stop the run (park the item, note the question, take the next one), and hard stop 3 holds: where the playbook rebases and force-pushes, merge `develop` in instead |
| `interrogate` | the lenses and repo traps in `gates.md` go into every adversary's brief; Codex is its non-Claude seat |
| `blast-radius` | the consumer-impact gate in `gates.md` (it names the consumers and how to search them) |
| `reflect`, `correct` | the lesson also becomes a lint, CI check or test where it can, then leaves the repo traps |
| `create-verification-skill`, `maintain-verification-skill` | none yet; the independent verdict's scratch consumer is the stand-in |

## Agent briefs and worker.md

Every agent brief starts with pstack's kickoff line, then ours:

```
Read <pstack>/skills/poteto-mode/worker.md before anything else.
Then read .claude/extensions/pstack.md: its add-on gates are part of your bar, and its hard stops (approvals, no merge, no destructive git, forge and branches, secrets and the public repo, the PR body) override worker.md.
```

The SessionStart hook prints both lines with the path filled in, and
`codex.sh` writes them into `start` and `resume` prompts when the pin is in
the Codex cache (Install and upgrade). An `ask` carries them in the lead's
brief; `review-diff` is Codex's own review and takes no kickoff. worker.md says the bar in the kickoff is the whole bar, and gives way
to a kickoff only when the kickoff says so in words. The second line is
what makes the gates and the hard stops part of that bar.

## Codex is a subagent

Codex runs as a pstack subagent, spawned with `subagent_type: "codex"`
(`.claude/agents/codex.md`). A Haiku relay runs `.claude/scripts/codex.sh`
inside the sandbox in `.codex/config.toml` and returns Codex's report.
Every pstack subagent rule applies to it:

- The kickoff starts with the `worker.md` pair above.
- It runs in the background.
- You own its work: read its diff and write your own summary.
- Parallel seats go in one message.
- Each new round is a fresh subagent. The one exception is `Mode: resume`
  for a Codex build, whose worktree and thread are costly to move.

**Roles.** Any role in `.claude/rules/pstack-models.md` may be `codex`.
Where Codex is available, the code-writing roles (`feature, refactoring`,
`bug-fix`, `perf-issue`, `hillclimb`) are `codex`, so pstack's "delegate
the code to a subagent" steps go to Codex. Swarm workers go to Codex or to
the `swarm workers` value, picked per swarm by the rule's swarm-pacing
note. Panels keep Codex as their non-Claude seat; Codex counts as a vendor
other than Claude, so it can be the cross-judge. `judgment and prose`
stays on Claude.

**Spawning.**

- Pass no `model`: the relay runs on Haiku, and Codex picks its own.
- Give the checkout's absolute path and a `Mode:` line (`build`, `resume`,
  `review` or `ask`).
- A build also needs `feature|bugfix`, a camelCase name and the base
  (`origin/develop`). Its output lands uncommitted in its own git-flow
  worktree (the `WORKTREE` in `.codex/delegate.conf`). The build's gates
  come from `GATES` in the same file.

**Replies.**

- `CODEX UNAVAILABLE` falls back to Claude: `opus` at the role's effort,
  or for a panel, the seat drops with a note.
- `SECURITY STOP` stops the run for Ezra.

**Limits.**

- A build needs `.codex/config.toml` on its base branch, and an `ask` with
  no `--in` runs on the main checkout, which needs it too.
- This repo has no key files, so the sandbox carries no denies of its own.
  Codex's read-only profile can still read sibling checkouts: a Codex
  consumer sweep briefs it to stay out of their key files.
- Codex leaves its work uncommitted. Claude reviews, commits and opens the
  PR.
