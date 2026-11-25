# AGENTS.md

Instructions for AI coding agents (Codex and others) working in
api_request_helper_flutter.

`CLAUDE.md` is the single source of truth for this repo: what the package
is, who consumes it, the blast-radius rules, conventions and how to verify a
change. Read it in full before editing anything, and obey it.

pstack is the process here: `.claude/extensions/pstack.md` has the hard
stops, `.claude/extensions/review/gates.md` the review gates. When a Claude
session hands you a build through `.claude/scripts/codex.sh`, you are the
builder: the brief and the hard rules at the top of your prompt (no
commits, the gates, the final report format) override anything here except
pstack.md's hard stops. An `ask` or review run is read-only.
