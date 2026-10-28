---
name: routine
description: "Run the four-pass pre-merge routine on an api_request_helper_flutter branch or PR — /simplify, /code-review, the CI gates locally, and a consumer-impact check across the apps and their domain packages — triaging every finding and committing each pass separately. Stops at the human review gate; never merges. Use for: the routine, run the routine, quality passes, pre-merge checks, has this done the routine."
---

# Pre-merge routine (library edition)

A trimmed port of chargeplus_customer's five-pass routine. The app-only
passes (`driver-critic`, `deep-review`, `verify-sim`) don't apply to an
HTTP library; the consumer-impact pass replaces them, because this library
sits under every network call the fleet makes (CLAUDE.md, blast-radius
rules).

Run all four passes on every PR that touches `lib/`. Docs-, test- or
config-only PRs: pass 3 only — CI covers the rest.

## Order

**`/simplify` → `/code-review` → gates → consumer impact.**

The two passes that change code run first; the gates and the impact check
then judge the code that will actually merge. Never run passes in parallel.

## Preflight

```bash
git fetch origin develop --quiet
git diff origin/develop...HEAD --stat     # scope
git status --short                        # must be clean; never stash
flutter pub get                           # a fresh worktree needs it
```

## Triage rule

Every finding is **applied** or **skipped with a concrete, checkable
reason** — never "I disagree". Roughly a third of agent findings are wrong:
verify before applying, and prove the skip when you can (a throwaway test,
then delete it).

**Fix, don't just report.** Commit each pass separately (Conventional
Commits — CI checks the PR title too) and push it in the same pass. A pass
is not finished while its accepted findings sit uncommitted.

## Pass 3 — gates

The CI gates (`./script.sh` option 3), run locally before pushing:

```bash
dart format --line-length 80 --set-exit-if-changed lib test
flutter analyze lib test
very_good test -j 4 --coverage --test-randomize-ordering-seed random
```

Then confirm the PR's CI (`gh pr checks <n>`) is green: coverage floor 30%,
and the markdown spell check — a new word in any `.md` goes in
`.github/cspell.json` `words`, not a misspelling. A change to logging needs
a test proving every new sensitive value is redacted (CLAUDE.md; the
redaction is shallow).

## Pass 4 — consumer impact

1. List both kinds of change:
   - **Signature**: exports in `lib/api_request_helper_flutter.dart`
     (`ApiRequestHelper`, `RequestFunctions`, `ContentType` today), public
     methods/params (removed, renamed, now required, changed default or
     type), enum values, any new exported type.
   - **Behavior**: retries (count, delay, what retries), default or merged
     headers, status-code → `ServiceException` mapping, response parsing,
     timeouts, logging. Per CLAUDE.md these are breaking even when every
     signature is unchanged.
2. Find the callers on each consumer's `develop` without touching their
   working trees (sibling checkouts). The apps' domain packages live under
   `packages/`, which `git grep` covers:

   ```bash
   for c in chargeplus_customer chargeplus_partner chargeplus_customer_web; do
     git -C ../$c fetch -q origin develop
     git -C ../$c grep -n '<symbol>' origin/develop -- '*.dart'
   done
   ```

   For a behavior change, search for code that depends on the old
   behavior too (e.g. a caller catching a specific `code`, or setting a
   header the library now sets). A missing sibling checkout → mark the
   pass ⚠️ partial and name it.
3. Verdict, one of:
   - **Additive** — a new optional param or method, and no behavior
     change. Say so with the grep evidence.
   - **Breaking** — any signature break or behavior change. List every
     affected call site per app; link the consumer PRs, or mark the pass
     ❌ blocked with what is missing.

## Update the PR after every pass

Keep the routine's state in the PR body, in one marked block that a re-run
replaces:

```
<!-- routine:status -->
### Quality routine

| Pass | Status | Findings | Commit |
| --- | --- | --- | --- |
| /simplify | ✅ done | 3 → 2 applied, 1 skipped | `abc1234` |
| /code-review | ✅ done | 1 → applied | `def5678` |
| gates | ✅ green | format · analyze · test · CI | — |
| consumer impact | ✅ additive | 0 call sites break (customer 26 packages, partner 9, web 3) | — |

<what was skipped and why — one line each>
<!-- /routine:status -->
```

Read the body first (`gh pr view <n> --json body`), replace between the
markers if present, otherwise append; never clobber the template sections.
Write the body to a scratchpad file and `gh pr edit <n> --body-file <file>`.
Mark a pass ⚠️ partial or ❌ blocked with its reason — a table of green
ticks where one pass proved nothing is worse than no routine.

## Report

Per pass: findings, applied, skipped **and why**; the gate results; the
consumer-impact verdict with call-site counts; the PR URL. **Never merge —
stop at the human review gate**, even if asked to "finish it".
