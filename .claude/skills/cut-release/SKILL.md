---
name: cut-release
description: "Cut an api_request_helper_flutter release with git flow: start release/X.Y.Z from develop, bump the pubspec version + build number, finish (merge to main, tag X.Y.Z, back-merge to develop), push main + develop + the tag, and publish GitHub release notes. Every consumer app picks the release up on its next pub get. Use for: cut release, cut a release, release, new version, bump version, tag a release, /cut-release."
user-invocable: true
---

# Cut Release — api_request_helper_flutter

develop → `release/X.Y.Z` → main + tag → develop. Adapted from
chargeplus_customer's `cut-release`.

**`main` is what ships.** The apps depend on this package by git URL with
no ref and gitignore `pubspec.lock`, so the push to `main` reaches every
app on its next `pub get` — there is no other release gate.
This library sits under every network call the apps make.
Only release what passed the `routine`.

Argument (optional):

- `patch` (default): dependency ranges, fixes, docs, tooling
- `minor`: new public method or param, with no behavior change
- `major`: breaking API, only with the consumer PRs ready (CLAUDE.md)
- an explicit `X.Y.Z`

## Repo conventions (match prior releases, e.g. 1.8.1)

| | |
|---|---|
| Release commit | `chore(release): bump version to X.Y.Z` — `pubspec.yaml` `version:` line only |
| Tag | bare semver (`1.8.1`), annotated, message `X.Y.Z` |
| Build number | previous + 1, always (even on minor/major) |
| Release notes | GitHub-generated (`--generate-notes`, PR list) |

Releasing several libraries together? Go in dependency order:
exceptions_flutter → api_request_helper_flutter → common_widgets_flutter.

## Steps

### 1. Preflight — stop on any failure

```bash
git fetch origin --tags --prune
git flow version                           # git-flow-next
git branch -a --list '*release/*' '*hotfix/*'   # must be empty
```

- **Where to cut:** in the main checkout if it is on `develop` and clean.
  If it is on another branch or dirty (often someone's work in progress),
  don't switch it — cut in a temporary worktree instead:
  `git worktree add --detach ../arh-release origin/develop`, then
  `git checkout develop` inside it, and remove it at the end.
- Local `develop` and `main` must equal `origin/develop` /
  `origin/main` (`git merge --ff-only` if behind; stop if diverged —
  another session may have landed work). `main` is not checked out, so
  `git branch -f main origin/main` after checking it is an ancestor.
- An existing `release/*` or `hotfix/*` branch: stop and ask — it may
  belong to another session.
- `git merge-base --is-ancestor origin/main origin/develop` — otherwise a
  hotfix wasn't back-merged; stop and ask.
- Commits to release:
  `git log --oneline --first-parent <prev-tag>..origin/develop` non-empty.
- Health: CI (`ci` workflow) runs on every push to `develop`. The latest
  run must be green **for `origin/develop`'s head SHA**:
  `gh run list -b develop -e push -L1 --json headSha,conclusion`. If it is
  missing or red, run the gates locally (`./script.sh` option 3:
  format, analyze, `very_good test`) and stop on any failure. Each merged
  PR should carry a routine status block — mention any that don't.

### 2. Compute the version

```bash
PREV=$(git describe --tags --abbrev=0 origin/main)
grep -n '^version:' pubspec.yaml
```

Bump `PREV` per the argument → `NEW`; build number → `N+1`. Confirm the
pubspec version name equals `PREV` (if not, say so and use the higher).
Show the user `PREV → NEW (+build)` and the PR list, then proceed unless
they object — invoking this skill is the authorization to release.

### 3. Start the release branch

```bash
git flow release start "$NEW"
```

Edit only the `version:` line of `pubspec.yaml` to `$NEW+$BUILD`, then
stage **only that file** — never `commit -a`: a tool on this machine
keeps leaving an uncommitted `analysis_options.yaml` edit in checkouts,
and `-a` sweeps it into the release:

```bash
git add pubspec.yaml
git diff --cached --name-only        # exactly: pubspec.yaml
git commit -m "chore(release): bump version to $NEW"
```

No other changes go on the release branch. Anything that must be fixed
first goes to develop via a normal PR (and the routine); then re-cut.

### 4. Finish

```bash
git flow release finish "$NEW" -m "$NEW" --no-ff --no-push
```

`--no-ff` is required: `main` is always an ancestor of `develop`, so
without it git flow fast-forwards and the `Merge branch 'release/X.Y.Z'`
commit is lost. On conflict: stop, show it, and resolve only with the user
(`--continue` / `--abort`).

Verify before pushing — any mismatch: nothing is pushed yet, so reset the
local branches to origin, delete the local tag, and redo:

```bash
git log -1 --format=%s main                     # Merge branch 'release/$NEW'
git rev-parse "$NEW^{commit}" main              # same SHA
git show --stat --format=%s "$NEW^2"            # chore(release): bump version to $NEW, pubspec.yaml only
git show "$NEW":pubspec.yaml | grep '^version:' # $NEW+$BUILD
git merge-base --is-ancestor "$NEW" develop     # back-merged
```

### 5. Push branches and tag

```bash
git push origin main develop "$NEW"
```

Push the tag by name (not `--tags`, so no stray local tag leaks). `main`
and `develop` are protected but don't enforce admins; this is a direct
admin push, as every previous release was. If the push is refused, stop
and tell the user — never force.

### 6. Publish release notes

```bash
gh release create "$NEW" --title "$NEW" --generate-notes \
  --notes-start-tag "$PREV" --verify-tag --latest
```

### 7. Report — and stop

`PREV → NEW+BUILD`, the tag, the main/develop SHAs pushed, the release
URL, and that consumers get it on their next `pub get`. Remove the
temporary worktree if you made one.

## Never

- Force-push main, develop or a tag; move or delete a pushed tag.
- Cut from a dirty tree, a stale develop, or over someone else's
  `release/*` / `hotfix/*` branch.
- Switch someone's checkout off their branch to cut a release.
- Put code changes on the release branch.
