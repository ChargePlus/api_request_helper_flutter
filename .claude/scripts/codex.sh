#!/usr/bin/env bash
# Hand work to Codex (the builder) from a Claude session (the lead).
# Optional: whenever Codex can't take the work, the script exits 3 with the
# reason on stderr, and the Claude session does it itself. See
# .claude/skills/codex/SKILL.md.
#
#   codex.sh available                                   exit 0 if Codex can take work here
#   codex.sh start  <feature|bugfix> <name> <brief.md> [--from <base>]
#                                                        new git-flow branch + worktree, Codex builds
#   codex.sh resume <name> <feedback.md>                 same Codex thread, more instructions
#   codex.sh review <name>                               Codex reviews the branch vs its base
#   codex.sh ask    <brief.md>                           read-only question on the main checkout
#   codex.sh status <name>                               run state + Codex's last message
#
# Exit 3 (every mode, available included): Codex can't take the work here
# (not installed, logged out, repo not trusted in Codex, or the branch has no
# secrets sandbox config). Exit 4: the Codex run failed (see the report).
# Exit 2: bad arguments, or Codex touched its own sandbox/guard files.
#
# Repo specifics (base branch, worktree path, gates) live in
# .codex/delegate.conf; the secrets sandbox and hooks in .codex/config.toml
# and .codex/hooks.json. Runs are logged under <git-common-dir>/codex-runs/
# (outside every worktree). Only Codex's final message is printed.
set -euo pipefail

common=$(git rev-parse --path-format=absolute --git-common-dir)
main_root=$(dirname "$common")
runs="$common/codex-runs"
src=$(cd "$(dirname "$0")/../.." && pwd) # the checkout this script lives in

# Defaults; .codex/delegate.conf (beside this script) overrides.
BASE=""          # start point; empty = --from is required
WORKTREE='$main_root/.worktrees/$type/$name'
WRITE_DIRS=()    # extra writable dirs for builds (caches outside the worktree)
DENY_PATHS=()    # secrets outside the run's workspace, beyond the guard's --key-dirs
GUARD=""         # .claude/hooks/<guard>: the hooks' guard, and it answers --key-dirs
GATES="Run the repo's analyze, format and test commands for what you touched."
# shellcheck source=/dev/null
[ -f "$src/.codex/delegate.conf" ] && . "$src/.codex/delegate.conf"

usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 2; }
stamp() { echo "$(date +%Y%m%d-%H%M%S)-$$"; }

profile_of() { sed -n 's/^default_permissions *= *"\(.*\)"/\1/p'; } # stdin: a .codex/config.toml
extends_of() { # <profile> <config.toml>: the profile it extends
  awk -v want="[permissions.$1]" '$0 == want { hit = 1; next } /^\[/ { hit = 0 }
    hit && /^extends *=/ { sub(/^extends *= *"/, ""); sub(/".*/, ""); print; exit }' "$2"
}

trusted() {
  awk -v want="[projects.\"$main_root\"]" '
    $0 == want { hit = 1; next }
    /^\[/ { hit = 0 }
    hit && /^trust_level *= *"trusted"/ { found = 1 }
    END { exit !found }' "${CODEX_HOME:-$HOME/.codex}/config.toml" 2>/dev/null
}

unavailable() { echo "$1. Do this work in Claude instead." >&2; exit 3; }

require_codex() {
  command -v codex >/dev/null 2>&1 || unavailable "Codex is not installed"
  codex login status >/dev/null 2>&1 || unavailable "Codex is not logged in"
  # Project .codex/ layers load only for a repo trusted in the user's own
  # config (a -c override does not count); a worktree inherits its main
  # checkout's trust. Untrusted, the profile is missing and Codex fails closed.
  trusted || unavailable "Codex has not trusted $main_root yet, so its secrets sandbox would not load. One-time fix: run \`codex\` in $main_root and accept the trust prompt"
}

# Each run gets a "delegate-run" profile extending the repo's: <name>
# (read-only + secret denies) for ask/review, <name>-build (adds worktree
# writes + network) for builds. On top go absolute paths the repo config
# cannot name: DENY_PATHS (secrets in the main checkout, which a worktree's
# sandbox would otherwise read) and, for builds, WRITE_DIRS (caches outside
# the worktree; a profile ignores --add-dir). One inline table, so any path
# survives (-c keeps quotes in dotted keys).
# Codex can write its worktree, including the files that sandbox it. Each run
# executes a guard copied from this script's checkout (outside the workspace,
# via CODEX_GUARD in .codex/hooks.json), and a resume/review refuses to load a
# worktree whose sandbox or guard Codex has changed.
untampered() { # <dir>
  local changed
  changed=$(git -C "$1" status --porcelain -- .codex .claude/hooks 2>/dev/null)
  [ -z "$changed" ] && return 0
  echo "Codex changed its own sandbox or guard files in $1 — inspect them before going on:" >&2
  echo "$changed" >&2
  exit 2
}

ARGS=()
guard_args() { # <dir> [read-only]
  local dir=$1 f parent profile entries=""
  profile=$(profile_of <"$dir/.codex/config.toml" 2>/dev/null || true)
  [ -n "$profile" ] || unavailable "$dir has no .codex/config.toml secrets sandbox (a branch cut before it landed)"
  ARGS=(--dangerously-bypass-hook-trust)
  if [ "${2:-}" = read-only ]; then
    # The build profile extends the read-only one (see .codex/config.toml).
    parent=$(extends_of "$profile" "$dir/.codex/config.toml")
    case "$parent" in "" | :*) unavailable "$dir/.codex/config.toml: $profile does not extend a read-only repo profile" ;; esac
    ARGS+=(-c 'approval_policy="never"')
  else
    parent=$profile
    for f in ${WRITE_DIRS[@]+"${WRITE_DIRS[@]}"}; do
      [ -d "$f" ] && entries+="\"$f\"=\"write\","
    done
    ARGS+=(-c 'approval_policy="on-request"' -c 'approvals_reviewer="auto_review"')
  fi
  # The guard's own list of key folders (one source), then the repo's extras.
  while IFS= read -r f; do
    [ -e "$f" ] && entries+="\"$f\"=\"deny\","
  done < <({ [ -f "$src/.claude/hooks/$GUARD" ] && python3 "$src/.claude/hooks/$GUARD" --key-dirs "$main_root"
             printf '%s\n' ${DENY_PATHS[@]+"${DENY_PATHS[@]}"}; } 2>/dev/null)
  ARGS+=(-c "permissions.delegate-run.extends=\"$parent\"" -c 'default_permissions="delegate-run"')
  [ -n "$entries" ] && ARGS+=(-c "permissions.delegate-run.filesystem={${entries%,}}")
  return 0
}

preamble() {
  cat <<EOF
You are the BUILDER. A Claude session is the lead: it wrote this brief, will
review your diff, and commits/ships. Read AGENTS.md and CLAUDE.md first and
obey them.

Hard rules:
- NEVER read, list, search or copy secret files (API keys, .env, config with
  credentials) that CLAUDE.md or AGENTS.md name. The sandbox and hooks block
  them; do not try to work around a block — report it.
- Do not commit, push, merge, rebase, or touch other branches/worktrees.
  Leave all changes uncommitted in this worktree.
- Gates before finishing: $GATES Fix what you broke.

Finish with this report as your FINAL message (it is all the lead sees):
## Done
<what changed, file by file, one line each>
## Gates
<each command run + pass/fail; paste failing test NAMES>
## Open questions / risks
<anything you could not verify or decided on the lead's behalf; "none" if none>

--- BRIEF ---
EOF
}

run_codex() { # <dir> <logdir> <codex args...>
  local dir=$1 log=$2
  shift 2
  mkdir -p "$log/guard"
  rm -f "$log/last.md"
  : >"$log/events.jsonl"
  : >"$log/stderr.txt"
  echo "running" >"$log/state"
  [ -n "$GUARD" ] && cp "$src/.claude/hooks/$GUARD" "$log/guard/$GUARD"
  if (cd "$dir" && CODEX_GUARD=${GUARD:+$log/guard/$GUARD} codex exec "$@" --json -o "$log/last.md" \
      >>"$log/events.jsonl" 2>>"$log/stderr.txt" </dev/null); then
    echo "done" >"$log/state"
  else
    echo "failed ($?)" >"$log/state"
  fi
  if [ ! -s "$log/thread_id" ]; then
    { grep -m1 '"thread.started"' "$log/events.jsonl" || true; } |
      sed -E 's/.*"thread_id":"([^"]+)".*/\1/' >"$log/thread_id"
  fi
  report "$log"
  case "$(cat "$log/state")" in failed*) exit 4 ;; esac
}

report() {
  local log=$1
  [ -f "$log/state" ] || { echo "no Codex run at $log" >&2; exit 2; }
  echo "state: $(cat "$log/state")"
  echo "log:   $log"
  if [ -s "$log/last.md" ]; then
    echo "----- Codex final message -----"
    cat "$log/last.md"
  else
    echo "(no final message) Codex error:"
    { grep -E '"type":"(error|turn.failed)"' "$log/events.jsonl" 2>/dev/null || true; } | tail -1 | cut -c1-500
    tail -20 "$log/stderr.txt" 2>/dev/null || true
    echo "A transient error (capacity, network) is worth one retry with resume; otherwise do the work in Claude."
  fi
}

need_file() { [ -f "$1" ] || { echo "no such file: $1" >&2; exit 2; }; }
need_run() { [ -f "$runs/$1/branch" ] || { echo "no Codex branch named '$1' (see $runs)" >&2; exit 2; }; }
field() { sed -n "$2p" "$runs/$1/branch"; } # <name> <line>: 1 branch, 2 worktree, 3 base

cmd=${1:-}
shift || true
case "$cmd" in
  available)
    require_codex
    echo "codex: available ($(codex --version 2>/dev/null))"
    ;;
  start)
    [ $# -ge 3 ] || usage
    type=$1 name=$2 brief=$3
    shift 3
    if [ $# -gt 0 ]; then
      [ "$1" = --from ] && [ $# -eq 2 ] || usage # a typo must not fall back to the default base
      BASE=$2
    fi
    [[ $type == feature || $type == bugfix ]] || { echo "type must be feature|bugfix" >&2; exit 2; }
    [[ $name =~ ^[A-Za-z0-9_-]+$ ]] || { echo "name must be camelCase letters/digits (got '$name')" >&2; exit 2; }
    [ -n "$BASE" ] || { echo "this repo needs an explicit base: --from <branch> (ask the user)" >&2; exit 2; }
    need_file "$brief"
    # Everything that could stop Codex is checked BEFORE the branch exists.
    require_codex
    git -C "$main_root" fetch -q origin || echo "warning: git fetch failed; using the local $BASE" >&2
    [ -n "$(git -C "$main_root" show "$BASE:.codex/config.toml" 2>/dev/null | profile_of)" ] ||
      unavailable "$BASE has no .codex/config.toml secrets sandbox yet"
    wt=$(eval "echo \"$WORKTREE\"") # name is validated above
    log="$runs/$name"
    [ -e "$wt" ] && { echo "worktree $wt already exists — use resume" >&2; exit 2; }
    git -C "$main_root" flow "$type" start "$name" "$BASE" --worktree-path "$wt" --no-cd -q --no-fetch || {
      echo "git flow could not create $type/$name (another start holding a git lock? retry)" >&2
      exit 2
    }
    rm -rf "$log" # a reused name must not inherit an old thread
    mkdir -p "$log"
    printf '%s\n%s\n%s\n' "$type/$name" "$wt" "$BASE" >"$log/branch"
    cp "$brief" "$log/brief.md"
    guard_args "$wt"
    run_codex "$wt" "$log" -C "$wt" "${ARGS[@]}" "$(preamble; cat "$brief")"
    ;;
  resume)
    [ $# -ge 2 ] || usage
    name=$1 feedback=$2
    need_run "$name"
    need_file "$feedback"
    require_codex
    log="$runs/$name"
    wt=$(field "$name" 2)
    untampered "$wt"
    guard_args "$wt"
    if [ -s "$log/thread_id" ]; then
      run_codex "$wt" "$log" resume "${ARGS[@]}" "$(cat "$log/thread_id")" \
        "Lead feedback — address all of it, re-run the gates, end with the same report format:
$(cat "$feedback")"
    else # the first run died before Codex started a thread: start one
      run_codex "$wt" "$log" -C "$wt" "${ARGS[@]}" "$(preamble; cat "$log/brief.md")

--- LEAD FEEDBACK ---
$(cat "$feedback")"
    fi
    ;;
  review)
    [ $# -ge 1 ] || usage
    name=$1
    need_run "$name"
    require_codex
    wt=$(field "$name" 2)
    untampered "$wt"
    # Codex leaves its work uncommitted; review diffs against the base, which
    # skips untracked files unless they are intent-to-add. Undone afterwards.
    untracked=$(git -C "$wt" ls-files --others --exclude-standard)
    [ -n "$untracked" ] && printf '%s\n' "$untracked" | git -C "$wt" add --intent-to-add --pathspec-from-file=-
    log="$runs/$name/review-$(stamp)"
    guard_args "$wt" read-only
    rc=0
    (run_codex "$wt" "$log" review "${ARGS[@]}" --base "$(field "$name" 3)") || rc=$?
    [ -n "$untracked" ] && printf '%s\n' "$untracked" | git -C "$wt" reset -q --pathspec-from-file=-
    exit "$rc"
    ;;
  ask)
    [ $# -ge 1 ] || usage
    brief=$1
    need_file "$brief"
    require_codex
    log="$runs/ask-$(stamp)"
    guard_args "$main_root" read-only
    run_codex "$main_root" "$log" -C "$main_root" "${ARGS[@]}" \
      "Read-only investigation for the lead Claude session: change no files. Never read the secret files CLAUDE.md names. Answer concisely with file:line references.

$(cat "$brief")"
    ;;
  status)
    [ $# -ge 1 ] || usage
    report "$runs/$1"
    ;;
  *)
    usage
    ;;
esac
