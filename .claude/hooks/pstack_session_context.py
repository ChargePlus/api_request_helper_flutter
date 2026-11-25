#!/usr/bin/env python3
"""SessionStart hook: tell each new Claude session that pstack is the base
process here and our gates add on top.

Prints SessionStart additionalContext (about 200 words) with the resolved
path of the pinned pstack install, because pstack's skills are slash-only:
the Skill tool can't start them, so an agent runs one by reading its
SKILL.md. Never fails the session: any problem becomes a one-line note.
Stdlib only, no network; reads only Claude's plugin records and this
checkout's settings.
"""

import json
import os
import sys

ROOT = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
CONFIG = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
# The gates named in the session note; .claude/extensions/review/gates.md has the full table.
GATES = "CI green, tests, cleanup, code review, interrogate, API compatibility, consumer impact, fuzz, security, public-API docs, public repo, agent instructions"


def pinned_ref():
    try:
        with open(os.path.join(ROOT, ".claude", "settings.json")) as f:
            src = json.load(f)["extraKnownMarketplaces"]["cursor-plugins"]["source"]
        return src.get("ref")
    except (OSError, KeyError, ValueError):
        return None


def install_path(ref):
    try:
        with open(os.path.join(CONFIG, "plugins", "installed_plugins.json")) as f:
            records = json.load(f)["plugins"].get("pstack@cursor-plugins", [])
    except (OSError, KeyError, ValueError):
        return None
    for r in records:
        # A project-scoped record counts only for the checkout it was made in.
        if r.get("scope") == "project" and os.path.realpath(r.get("projectPath") or "") != ROOT:
            continue
        p = r.get("installPath", "")
        if r.get("gitCommitSha") == ref and os.path.isfile(os.path.join(p, "skills", "poteto-mode", "SKILL.md")):
            return p
    return None


def main():
    ref = pinned_ref()
    if not ref:
        return  # this checkout predates pstack: say nothing
    p = install_path(ref)
    if not p:
        text = (
            f"pstack is the base process in this repo (.claude/extensions/pstack.md), but the pinned pstack "
            f"({ref[:12]}) is not installed for this checkout. Tell the user to trust the folder or run "
            "`claude plugin marketplace update cursor-plugins && claude plugin install pstack@cursor-plugins --scope project`; "
            "until then follow CLAUDE.md as usual, and run the review gates' interrogate panel by hand "
            "(.claude/extensions/review/gates.md, \"When pstack is not installed\"), and run the review-gates skill before opening a PR."
        )
    else:
        skills = os.path.join(p, "skills")
        text = (
            "pstack is the only process in this repo; our review gates add on top. For non-trivial work, "
            f"follow poteto-mode in full: read {skills}/poteto-mode/SKILL.md and run its playbook, plus the "
            "add-on gates and hard stops in .claude/extensions/pstack.md (gates, in .claude/extensions/review/gates.md: "
            f"{GATES}, an independent verifier's PASS/FAIL; hard stops: approvals, no merge, no destructive git, "
            "secrets and the public repo, the PR body). Run the review-gates skill before pstack's Opening a PR playbook: the PR body's ## Review gates section is required and the Review gates CI check reads it. "
            "/deslop and control-cli are this repo's skills of those names (a control-ui step uses control-cli). "
            "This is a library that every app pulls unpinned, so a "
            "change here is a change to every consumer. Codex is a subagent (subagent_type \"codex\") wherever a role names it. "
            f"pstack skills are slash-only: run one by reading {skills}/<name>/SKILL.md "
            f"(adapter: {p}/docs/harness/claude-code.md). Every agent brief you write starts with "
            f"`Read {skills}/poteto-mode/worker.md before anything else.` then "
            "`Then read .claude/extensions/pstack.md: its add-on gates are part of your bar, and its hard stops (approvals, no merge, no destructive git, secrets and the public repo, the PR body) override worker.md.`"
        )
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": text}}))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a hook must never block a session
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                                 "additionalContext": f"pstack context hook failed: {e}"}}))
    sys.exit(0)
