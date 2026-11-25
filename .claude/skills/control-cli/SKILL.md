---
name: control-cli
description: "pstack's control-cli step (Shipping step 1, Feature step 5) in api_request_helper_flutter (cursor-team-kit's control-cli does not exist in Claude Code): run a change the way a consuming app would and give PASS, PASS+NOTES or FAIL. Runs the independent-verdict procedure in .claude/extensions/review/gates.md. Use when a pstack playbook says control-cli or control-ui, or for the Independent verdict line of the PR's Review gates section."
---

# control-cli: the independent verdict

pstack's Shipping step 1 and Feature step 5 call `control-cli` (or
`control-ui`; this library has no UI, so both land here). In this repo it
is the **Independent verdict** gate. The procedure is in
`.claude/extensions/review/gates.md` → *Independent verdict* and
*Re-verdicts*: read it and follow it. This skill adds nothing to it.

1. **Who.** A fresh agent that did not write the code. The author never
   gives its own verdict.
2. **The run.** For a `lib/` or `pubspec.yaml` change, the scratch
   consumer: a Dart test in the scratchpad that depends on this checkout
   by path and calls the changed API against a local `HttpServer` on
   `127.0.0.1`, at the merge base and at the head. For a change with no
   consumer to stand in for (`.claude/`, `.codex/`, `.github/`, `CLAUDE.md`, `AGENTS.md`, `script.sh`), run
   each changed command the way its caller does, parent against head, as
   gates.md says. First ask whether the run can tell fixed from broken;
   if it cannot, the verdict is `PASS+NOTES (partial: <why>)` at best.
3. **What it cannot run.** A real device, the web build, the production
   host: list it on the **Verification-blocked** line, never as clean.
4. **The verdict.** Post `PASS`, `PASS+NOTES` or `FAIL` as a PR comment
   with the full 40-character head SHA it covers and the quoted
   difference, then put the same on the PR body's Independent verdict
   line: `PASS · <comment link> · covers <sha>`. A newer head needs a
   re-verdict (gates.md, *Re-verdicts*), or the Review gates check stays
   red.

Nothing from the scratch consumer is committed. This repo is public: no
real host, key or customer data in the comment.
