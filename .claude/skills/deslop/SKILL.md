---
name: deslop
description: "pstack's *Before commit → /deslop* step in api_request_helper_flutter (cursor-team-kit's /deslop does not exist in Claude Code). On the branch diff: /pstack:no-comments, /pstack:unslop on changed prose, the built-in /simplify, then the build gates (dart format, flutter analyze, very_good test). Use when a pstack playbook says /deslop, or before committing a change."
---

# deslop: clean the diff before commit

pstack's Opening a PR and poteto-mode say "Before commit → `/deslop`".
Here that is this skill. It runs on the branch diff
(`git diff origin/develop...HEAD`) plus the working tree, in this order.
Check `git status --short` first, and never stash.

1. **No comments.** Read `<pstack>/skills/no-comments/SKILL.md` and
   follow it on the changed code. `<pstack>` is the path the SessionStart
   hook printed (or the `installPath` of `pstack@cursor-plugins` in
   `~/.claude/plugins/installed_plugins.json`). Dartdoc on a public symbol
   is the API contract (`review/gates.md`, Public-API docs): keep it.
2. **Unslop.** Read `<pstack>/skills/unslop/SKILL.md` and apply it to the
   prose the diff changes: Markdown, skills, agent files, dartdoc, and
   the commit and PR text you are about to write.
3. **Simplify.** The built-in `/simplify` on the changed code under `lib/`
   and `test/`.
4. **Build gates.** The commands from CLAUDE.md (Verify), which CI's
   `build` job runs:
   ```bash
   dart format --line-length 80 --set-exit-if-changed lib test
   flutter analyze lib test
   very_good test -j 4 --coverage --test-randomize-ordering-seed random
   ```
   Diff the failing test **name set** against `origin/develop`, never the
   count (`review/gates.md`, Tests). A new word in any `.md` goes in
   `.github/cspell.json`.

Commit each pass's fixes separately in Conventional Commits
(`refactor(scope): …` for cleanup, `docs(scope): …` for prose), with an
explicit pathspec, ending with the `Co-Authored-By` trailer the repo's
history uses. A pass that changes nothing gets no commit: say so. A red
format, analyze or new failing test name stops the commit.

Report one line per pass: what it found, what you applied, what you
skipped and why.
