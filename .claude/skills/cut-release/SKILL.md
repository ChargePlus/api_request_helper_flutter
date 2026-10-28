---
name: cut-release
description: "Cut an api_request_helper_flutter release: confirm every PR since the last tag has had the routine, then git flow release start, bump the pubspec version, git flow release finish (pushes main, develop and the tag), and publish GitHub release notes. Use for: cut release, cut a release, release, new version, bump version, tag a release, /cut-release."
user-invocable: true
---

# Cut Release — api_request_helper_flutter

Routine done → `git flow release start` → `git flow release finish` →
push → release notes. That's all; invoking this skill is the authorization
to release.

Argument (optional): `patch` (default) | `minor` (new public API) |
`major` (breaking — consumer PRs ready, per CLAUDE.md) | `X.Y.Z`.

Conventions: release commit
`chore(release): bump version to X.Y.Z`; bare-semver tag `X.Y.Z`
(message `X.Y.Z`); build number = previous + 1.

## 1. The routine is done

```bash
git fetch origin --tags --prune
PREV=$(git describe --tags --abbrev=0 origin/main)
git log --first-parent --format=%s "$PREV..origin/develop"   # PR merges
```

Every PR merged since `$PREV` must carry a `<!-- routine:status -->`
block (`gh pr view <n> --json body`). If one doesn't, run the `routine`
on it before releasing — don't release over it.

## 2. Release

On a clean `develop` equal to `origin/develop`, with `main` equal to
`origin/main`. If the main checkout is busy on another branch, don't
switch it: `git worktree add --detach ../arh-release origin/develop`,
`git checkout develop` there, and remove the worktree afterwards.

```bash
git flow release start "$NEW"
# set pubspec.yaml `version:` to $NEW+$BUILD — that line only
git add pubspec.yaml                 # never commit -a
git commit -m "chore(release): bump version to $NEW"
git flow release finish "$NEW" --no-ff -m "$NEW" --push
```

`--no-ff` keeps the `Merge branch 'release/X.Y.Z'` commit on `main`;
`--push` pushes `main`, `develop` and the tag. If the push is refused,
stop and tell the user — never force.

## 3. Release notes

```bash
gh release create "$NEW" --title "$NEW" --generate-notes \
  --notes-start-tag "$PREV" --verify-tag --latest
```

Report `PREV → NEW+BUILD`, the release URL, and that the apps get it on
their next `pub get`.
