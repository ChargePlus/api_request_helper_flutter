---
name: review-gates
description: "The single entry point for api_request_helper_flutter's review gates. Run it before pstack's Opening a PR playbook (which ends every playbook), and when asked to gate, review or check a branch or PR. Scopes the diff against develop, runs the gates in .claude/extensions/review/gates.md whose trigger the diff meets, in its order, and writes the PR body's ## Review gates section that CI checks. Use for: review gates, gate this, review this PR, check this branch, pre-merge checks, is this ready to open."
---

# review-gates: api_request_helper_flutter

The gates live in `.claude/extensions/review/gates.md`. It is the source
of truth; this skill only sequences them and writes the record. Do not
copy its table here.

1. **Scope.** `git fetch origin develop --quiet`, then
   `git diff --name-only origin/develop...HEAD`. A diff confined to the
   `proseOnly` paths in `.github/review-gates.json` (`README.md`) runs CI
   and Public repo only, and the section is the single line
   `None: prose-only`.
2. **Pick.** Each gate in gates.md's table whose *Runs when* the diff
   meets. A gate you skip is `n/a: <missing trigger>`.
3. **Run.** In gates.md's **Order**, each seeing the fixes of the ones
   before it. Cleanup is the `deslop` skill's first three passes: cite it
   if it ran on this head. CI and Tests run on every head you push.
4. **Triage.** gates.md's *Triage rule*: every finding applied or skipped
   with a checkable reason, each gate's fixes in their own commit. Behavior
   and Breaking stop for Ezra (`.claude/extensions/pstack.md`, hard stop 1).
5. **Open the PR.** pstack's Opening a PR, with the body from
   `.github/PULL_REQUEST_TEMPLATE.md` (hard stop 6) and the section filled
   in except the verdict.
6. **Independent verdict.** A fresh agent runs the `control-cli` skill on
   the PR head. It goes last, so it covers the code that will merge.
7. **Record.** Fill the `## Review gates` section in the shape gates.md
   gives (*The Review gates block*), keep the template's other sections,
   and write it with `gh pr edit <n> --body-file <file>`. Check the body
   first with the CI script:
   ```bash
   jq -n --rawfile body <file> --arg head "$(git rev-parse HEAD)" \
     --arg base "$(git rev-parse origin/develop)" \
     '{pull_request: {body: $body, head: {sha: $head}, base: {sha: $base}}}' > <scratchpad>/event.json
   GITHUB_EVENT_PATH=<scratchpad>/event.json python3 .github/scripts/review_gates_check.py
   ```

CI's **Review gates** check (`.github/workflows/review-gates.yaml`,
config `.github/review-gates.json`) fails the PR while the section is
missing, a line is unfilled (a `<…>` placeholder, or `pending` as a gate's
first or last word; put the word in backticks inside a description), or
the verdict is not `PASS` / `PASS+NOTES` on the current head SHA. A push
after the verdict moves the head: re-run the gates it affects and get a
re-verdict.

This skill never merges and stops at Ezra's review.
