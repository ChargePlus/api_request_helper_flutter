# pstack model configuration for api_request_helper_flutter. One line per role. Delete a line to fall back to the skill default.
# This project file is the pstack model rule for this repo and its worktrees. Where a user-level ~/.claude/rules/pstack-models.md also loads, these lines win.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Agent `model` and spawn `general-purpose`). Alias entries in a panel list still count toward its fan-out.
# Claude Code: a value `<model> <effort>` maps to Agent `model` and `effort`. `codex` = spawn subagent_type "codex" (no model); CODEX UNAVAILABLE falls back to opus at the role's effort (medium for code roles, low for swarm workers); a panel seat drops with a note instead. See .claude/extensions/pstack.md "Codex is a subagent".
# Swarm pacing: before every swarm, pick the workers' vendor by quota pace (pace = weekly % used / % of the week elapsed; above 1.0 means it will not last to the reset).
#   Codex pace: run `~/.claude/scripts/codex-pace.sh`. Claude pace: `mcp__ccd_session_mgmt__get_usage`, the "Weekly · all models" window (week = 7 days before resetsAt).
#   The Codex pace needs that script, which lives on the user's machine, not in this repo. Where it is missing, use the Claude pace alone: workers stay on Claude (the swarm workers value) and the halving rule applies when the Claude pace is above 1.0.
#   Workers go to the vendor with the lower pace: `codex`, or the swarm workers value below. If both are above 1.0, halve the worker count (at least 2) and say so.
#   State both paces and the choice in one line before spawning.
# defaults: 3
# budget: small (medium)
feature, refactoring: codex
bug-fix: codex
perf-issue: codex
hillclimb: codex
judgment and prose: opus medium
arena runners: fable low, opus low, codex
arena cross-judge pool: codex, opus low
swarm workers: opus low
interrogate reviewers: fable low, opus low, codex
