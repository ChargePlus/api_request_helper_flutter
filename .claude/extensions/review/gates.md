# Review gates

pstack is the process (`.claude/extensions/pstack.md`). These are the gates
it runs on top before a PR goes to Ezra. A gate never replaces a pstack
step.

This library has no screen and no end user. Its users are the apps
(chargeplus_customer, chargeplus_partner, chargeplus_customer_web) and the
domain packages under their `packages/`, which pull it by unpinned git URL
with gitignored lock files. So the gates ask two questions of every diff:
is the code right, and what does it do to every consumer on its next
`pub get`. CI answers what a machine answers the same way every time; these
gates keep the judgement.

## The gates

| Gate | Runs when | How |
| --- | --- | --- |
| CI | every PR | `gh pr checks <n>` green on the head: `build` (format, analyze, tests, coverage floor 30%), `semantic_pull_request` (the title) and `spell-check` (every `.md`, `.claude/` included: a new word goes in `.github/cspell.json`). |
| Tests | any change under `lib/` or `test/` | see [Tests](#tests) |
| Cleanup | any change under `lib/` or `test/` | `/pstack:no-comments`; the built-in `/simplify` too when the diff changes over ~100 lines under `lib/` |
| Code review | any change under `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml` or `.github/` | the built-in `/code-review` (it also checks CLAUDE.md rules), plus the [repo traps](#repo-traps) |
| Adversarial review | any change under `lib/` | `/pstack:interrogate`, Codex as its non-Claude seat. Each adversary gets the [lenses](#edge-case-lenses) and the repo traps as its starting brief. See [Adversarial review](#adversarial-review). |
| API compatibility | any change under `lib/` or to `pubspec.yaml` | classify the diff as **Additive**, **Behavior** or **Breaking** and name the bump: see [API compatibility](#api-compatibility) |
| Consumer impact | the classification is Behavior or Breaking, or the diff changes any exported symbol | see [Consumer impact](#consumer-impact) |
| Fuzz | the diff changes `RequestFunctions.getResponse`, `getException`, `redactSensitive` or `_isSensitiveKey`, header building (`_createHeaders`), or any other path that reads a response body | a seeded fuzz test: see [Fuzz](#fuzz) |
| Security | the diff touches headers or the host check that decides whether they are sent, `userToken`, the `XAPI_KEY` or `XAPITOKEN_ENCRYPTION_KEY` reads, logging or redaction, retries, timeouts or abort, multipart file paths, a dependency, or `.github/workflows/` | the built-in `/security-review`, plus the questions in [Security](#security) |
| Public-API docs | the diff adds or changes an exported symbol, or changes what one does | the dartdoc of each one states the contract it now has: what it returns, what it throws, defaults, and how it treats headers, retries and logging. CI's `public_member_api_docs` lint only proves a doc exists. Update `README.md` when its usage example no longer compiles or no longer describes the behavior. |
| Public repo | every PR | read the diff, the commit messages and the PR body for anything that must not be public: see [Public repo](#public-repo) |
| Agent instructions | the diff touches `CLAUDE.md`, `AGENTS.md`, `.claude/` or `.codex/` | a fresh agent reads every rule the diff adds or changes against `CLAUDE.md`, `.claude/extensions/pstack.md`, this file and every file the rule names (the skill, agent, hook or script it edits or points to), and quotes each conflict: two rules that disagree, a rule a later line undoes, a step that names a tool or path that does not exist, or anything that weakens a hard stop. Fix each one before the PR goes to Ezra. |
| Independent verdict | every PR except prose-only | pstack Shipping step 1, with a scratch consumer standing in for the app: see [Independent verdict](#independent-verdict) |

Prose-only changes (only the `proseOnly` paths in `.github/review-gates.json`,
today `README.md`) run CI and Public repo only, and their Review gates
section is `None: prose-only`. Any other `.md` runs the gates its path
triggers (`CLAUDE.md`, `AGENTS.md` and `.claude/` the agent instructions
gate, `.github/` code review).

**Order:** cleanup → code review → interrogate → API compatibility →
consumer impact → fuzz → security → public-API docs → public repo → agent
instructions → independent verdict. CI and Tests run on every head you
push: fix them before the verdict. Run the gates in sequence so each sees
the fixes from the ones before it. A fix that moves HEAD re-runs the gates
it affects.

## Triage rule

Every finding is **applied** or **skipped with a concrete, checkable
reason**. Never "I disagree". Roughly a third of agent findings are wrong:
verify before applying, and prove the skip when you can (a throwaway test,
then delete it).

**Fix them, do not just report them.** Commit each gate's fixes
separately in Conventional Commits (`refactor(scope): …` for cleanup,
`test(scope): …` or `fix(scope): …` for review and fuzz findings) and push
them in the same pass. A gate is not finished while its accepted findings
sit uncommitted. A gate that finds nothing says so; no empty commit.

Escalate instead of deciding alone when a fix would change intended
behavior, reach well outside the diff, or need a product call. Report it
as a finding you deliberately did not take, with the reason.

## Tests

Run `very_good test -j 4 --coverage --test-randomize-ordering-seed random`
on every head you push and diff the failing **name set** against
`origin/develop`, never the count. Identical sets mean no regression.

For a bug fix, RED then GREEN must be on **the test that ships**, not a
scratch probe: copy the fixed `lib/` files to the scratchpad, put the merge
base's version in place (`git show $(git merge-base origin/develop HEAD):<path>`;
swap every `lib/` file in the diff together, or the test fails to compile
instead of failing on the defect), confirm the test fails, restore,
confirm it passes. Quote the failure message. Never stash.

`ApiRequestHelper` reads `PackageInfo.fromPlatform()`: a test that reaches
it sets `PackageInfo.setMockInitialValues` first.

## Adversarial review

Codex takes interrogate's non-Claude seat as the `codex` subagent with
`Mode: ask` (`.claude/agents/codex.md`). Put every adversary's findings
through interrogate's Verify step: a finding a run proves is confirmed, one
a run disproves is dropped with the output, and one that cannot be run here
is recorded as **verification-blocked** and triaged, never counted as
clean.

**When pstack is not installed in the checkout** (the SessionStart hook
says so), ask Ezra to install it or trust the folder. Until it loads, do
not skip the gate: run the panel by hand, one fresh subagent per entry of
the `interrogate reviewers` line in `.claude/rules/pstack-models.md`, all
in one message, each with the diff, the lenses, the repo traps and the
instruction to break the change and prove each finding with a run. The
Codex seat's brief skips the worker.md pair; a `CODEX UNAVAILABLE` reply
drops the seat with a note. Write "interrogate (panel run by hand: pstack
not installed)" in the Review gates block. `/pstack:no-comments` and
`/pstack:unslop` have no hand-run form: mark it ❌ blocked with the reason.

### Edge-case lenses

Keep only the rows the diff reaches, and add the ones no lens names.

- **Body shape:** not JSON, empty, JSON that is not an object (array,
  string, number, `null`), an envelope with no `result`, a `result` that is
  not a map, `status` absent, a string or a number, `message` or `msg`
  absent or not a string, a very large body.
- **Status:** each 2xx the switch accepts (200, 203, 204, 214) and one it
  does not, 3xx, 401, 403, 404, 5xx, and an HTTP 200 whose body `status`
  disagrees.
- **Transport:** `SocketException`, `TimeoutException`, an
  `http.ClientException` (not retried), retries exhausted, an abort before
  the request is sent, while it is in flight, and after the response.
- **Headers:** `userToken` null or set, `extraHeaders` that clash with a
  default, the ChargePlus host against a third-party host in a release
  build, `ContentType` each value.
- **Platform:** web. chargeplus_customer_web consumes this library, and
  `dart:io` (`Platform`, `SocketException`, `File`) does not exist there:
  any new `dart:io` use needs a `kIsWeb` guard or a web-safe path.
- **Logging:** a sensitive key at the top level, nested in a map, inside a
  list of maps, with a non-string key, in the response as well as the
  request, and a release build (nothing logged).

## API compatibility

List every change to what a consumer can see, then classify the PR by the
most severe one:

- **Additive** (minor bump): a new exported type, method, or optional
  parameter whose default keeps today's behavior. Nothing a consumer does
  today behaves differently.
- **Behavior** (minor at least; Ezra decides): no signature breaks, but a
  consumer gets a different result. CLAUDE.md treats these as breaking
  here: retry count, delay or what retries, a default or merged header,
  status-code to `ServiceException` mapping, what `isResult` returns,
  response parsing, timeouts, the `statusCode` stream, what is logged, a
  new exception type escaping a method.
- **Breaking** (major bump): an export removed or renamed, a parameter
  removed, renamed, made required or retyped, a changed default, a new enum
  value a consumer's exhaustive `switch` must handle, a raised `sdk` or
  `flutter` floor, or a dependency range that drops a version a consumer
  resolves today.
- **Internal** (patch): none of the above (tests, docs, a private
  refactor proven to change no result).

Diff the exported surface, not only `lib/api_request_helper_flutter.dart`:
`git diff origin/develop...HEAD -- lib/ pubspec.yaml`. Behavior and
Breaking are hard stops for Ezra (`pstack.md`, hard stop 1). A Breaking
change ships as add-new, migrate-callers, delete-old across releases
(`/pstack:principle-migrate-callers-then-delete-legacy-apis`) unless Ezra
says otherwise.

## Consumer impact

1. Find the callers of every changed symbol on each consumer's `develop`,
   without touching their working trees. `git grep` covers their
   `packages/`:

   ```bash
   for c in chargeplus_customer chargeplus_partner chargeplus_customer_web; do
     git -C ../$c fetch -q origin develop
     git -C ../$c grep -n '<symbol>' origin/develop -- '*.dart'
   done
   ```

   For a Behavior change, also search for code that depends on the old
   behavior: a caller that catches a specific `code`, sets a header the
   library now sets, reads `statusCode`, or retries on its own on top of
   ours. Stay out of every key file while you search. A missing sibling
   checkout marks the gate ⚠️ partial, naming it.
2. Run `/pstack:blast-radius` on the one or two facts the change's safety
   rests on, and take each as far down its "how sure are you" ladder as is
   cheap.
3. **Behavior or Breaking:** prove it against a real consumer. In a
   throwaway detached worktree of each affected consumer at
   `origin/develop` (`git -C ../<c> worktree add --detach <scratch> origin/develop`),
   point the affected package at this checkout with an uncommitted
   `pubspec_overrides.yaml` (`dependency_overrides:
   api_request_helper_flutter: {path: <this worktree>}`), run `flutter pub
   get`, `flutter analyze` and the tests of the packages that import the
   changed symbols, then remove the worktree. Never commit in a
   consumer, and never run anything there that needs its API keys.
4. Verdict: **Additive** with the grep evidence, or the list of call sites
   per app that break or behave differently, with the consumer PRs linked
   or the gate ❌ blocked naming what is missing.

## Fuzz

A seeded random-input test in `test/src/`, extended before a new one is
written: fixed seeds in the suite, and the failing seed and input printed
on failure. Generate bodies and maps from the lenses above (random nesting
of maps, lists, strings, numbers, `null` and booleans; random status codes;
sensitive keys at random depths and in random case and separator styles).
Its invariants:

- `getResponse` returns, or throws a `ServiceException` or a
  `FormatException`. Never an `Error` (`TypeError`, `RangeError`,
  `NoSuchMethodError`): an `Error` escapes every `on Exception` arm in the
  apps and leaves the caller waiting.
- A thrown `FormatException` carries no part of the body.
- `redactSensitive` leaves no sensitive value at any depth, never redacts
  a value the redaction tests keep (such as `phoneNumber`), and never
  changes its input.

Each invariant is seen failing once against a minimal mutation of the line
it guards (copy the file to the scratchpad first, never stash), and the
failure is quoted in the PR.

## Security

Beyond `/security-review`, answer each that the diff reaches, with the
line that proves it:

- Are the API key, the API token and `Authorization` still sent only to
  the ChargePlus host outside debug and profile builds, on every method,
  including a new one?
- Can a secret reach a log, an exception message, a `FormatException`, a
  crash report or the `statusCode` stream? Logging stays behind
  `kDebugMode`, and every new sensitive field has a redaction test.
- Can a retry repeat a request that is not safe to repeat (a POST, a
  payment)? Can a timeout or retry change multiply load from every app at
  once?
- Can a caller's input pick the host, a header name, or a file path the
  multipart upload reads?
- Is a new dependency maintained, and is a new or changed workflow action
  pinned to a full SHA, with `permissions:` no wider than the job needs?

A finding that is a vulnerability goes to Ezra in chat, not into the PR or
a commit message: this repository is public.

## Public repo

This repository is public on GitHub. The diff, the commit messages and the
PR body carry no:

- key, token, password, dart-define value or `.env` content, real or
  realistic-looking (fixtures use obvious fakes such as `test-token`);
- hostname, URL or endpoint path beyond those the code already names;
- customer data: names, emails, phone numbers, plates, card details or
  IDs, even in a fixture or a log excerpt;
- private ticket text, internal incident details, or a description of an
  unfixed vulnerability.

A hit is fixed before the push. One already pushed goes to Ezra at once:
the history needs a rewrite he must approve, and the secret needs rotating.

## Independent verdict

pstack Shipping step 1: a fresh agent that did not write the code runs the
change the way a consuming app would, parent against head, and posts `PASS`,
`PASS+NOTES` or `FAIL` on the PR with the full head SHA.

There is no app here, so the agent writes a scratch consumer in the
scratchpad (never committed): a Dart test that depends on this checkout by
path and calls the changed public API the way the apps call it, against a
local `HttpServer` from `dart:io` bound to `127.0.0.1` that serves the
discriminating responses (the status, body shape, delay or dropped
connection the change is about). It runs the same calls against the merge
base and against the head, and the verdict quotes the difference. Before
building, it asks whether this harness can tell fixed from broken. When it
cannot (a behavior that only shows on a real device, the web build, or the
production host), it posts `PASS+NOTES (partial: <reason>)`, never a plain
`PASS`.

A diff with nothing for a consumer to call (only `.claude/`, `.codex/`,
`.github/`, `CLAUDE.md`, `AGENTS.md` or a script) has no scratch
consumer. The agent runs each changed hook, script, workflow step or
skill command the way its caller does, on a scratch directory, at the
merge base and at the head, with one input that should change behavior
and one that should not (a hook gets its event's JSON on stdin). A
`pull_request` workflow that cannot run from the branch is
`PASS+NOTES (partial: <reason>)`. The `control-cli` skill runs this gate.

### Re-verdicts

A verdict covers one head SHA:

- **Same patch** (a rebase, or a merge-forward whose changed lines match):
  `git diff $(git merge-base origin/develop <sha>) <sha> | git patch-id --stable`
  prints the same ID for both heads. Post a re-check comment with both SHAs
  and the ID.
- **Fix commit:** after the gates the fix affects, a fresh agent checks
  only `git diff <verified head> <new head>` the way the full verdict ran,
  and posts a delta verdict that links the full one.
- **Anything else:** rerun the verdict.

## Repo traps

Interrogate adversaries and `/code-review` check the diff against these.
Each one has shipped or nearly shipped here. A trap that can become a
lint, test or CI check should become one (`/pstack:correct`), then leave
this list.

- **Casts on the body throw `Error`s.** Reading a body field with `as`
  turned a malformed or proxy error body into a `TypeError` that no
  `on Exception` arm catches, so no `ServiceException` was raised (#34).
  Read every body field with an `is` check.
- **A `FormatException` keeps its `source`,** and prints it. Throw one
  without the body (#34).
- **Extra headers must not override the defaults.** A caller's
  `extraHeaders` once replaced the default headers on a clash (#35). The
  defaults win; a test pins it.
- **Redaction misses nesting and variants.** Secrets nested in maps, in
  lists of maps and in the response leaked until #27. New sensitive keys go
  in `_sensitiveKeys` with a test at depth, and `phoneNumber` style fields
  stay readable.
- **Logging outside debug.** `dart:developer` `log()` still reaches the
  device log in release builds; every log call stays behind `kDebugMode`.
- **The host gate on headers.** Every method sends the default headers to
  the ChargePlus host only, outside debug and profile. A new method copies
  that gate.
- **Retries.** Only `get` retries (`maxAttempts`), and only on
  `SocketException` and `TimeoutException`. Do not add retries to a
  request that changes server state without an idempotency key.
- **`dart:io` on the web.** See the Platform lens: a new `dart:io` use
  breaks chargeplus_customer_web at compile or run time.
- **The `statusCode` stream** is single-subscription: a second listener
  throws. Do not add one inside the library, and keep `dispose` closing
  the controller.
- **The 200 envelope.** An HTTP 200 whose body `status` is not 200 takes
  the body's status. Changing that is a Behavior change.
- **`exceptions_flutter` is unpinned too.** A change there (a field, the
  `props` list) changes this library's exceptions and tests on the next
  `pub get`.

## The Review gates block

The PR body's `## Review gates` section, between the
`<!-- review-gates -->` markers that `.github/PULL_REQUEST_TEMPLATE.md`
carries. The `review-gates` skill writes it, the **Review gates** CI
check (`.github/scripts/review_gates_check.py`, its fields in
`.github/review-gates.json`) fails the PR until it is filled in, and
`cut-release` reads it. Read the body first
(`gh pr view <n> --json body`), replace between the markers, never
clobber the sections above it, and write it with
`gh pr edit <n> --body-file <file>`.

```
<!-- review-gates -->
## Review gates

- **Gates run:**
  - **<gate>:** ✅ / ⚠️ partial / ❌ blocked / n/a · <commit, test name, link or reason>
- **Independent verdict:** PASS / PASS+NOTES / FAIL · <comment link> · covers <full 40-character head SHA>
- **API change:** Additive / Behavior / Breaking / Internal → patch / minor / major
- **Verification-blocked:** none, or each check that could not run here and why
<!-- /review-gates -->
```

One **Gates run** sub-line per gate, in the order above, and `n/a` with
the missing trigger for a gate the diff does not reach. Mark a gate ⚠️
partial or ❌ blocked with its reason whenever it could not do its job.
**Verification-blocked** names those gates and every finding recorded as
verification-blocked, or says `none`. A green result needs evidence. A
prose-only change writes `None: prose-only` as the whole section.

The check fails on a `<…>` left in, a gate still `pending` (as a gate's
first or last word: inside a description, put the word in backticks),
a verdict other than `PASS` or `PASS+NOTES`, or a verdict SHA that is
not the PR head. A push after the verdict needs a re-verdict.
If the PR title no longer covers what the branch does, retitle it.

## Report

Per gate: findings, what was applied, what was skipped and why. Then the
API classification, the consumer-impact verdict with call-site counts, CI
and test results, the RED then GREEN failure message, the independent
verdict, and the PR URL. **Never merge.** Stop at Ezra's review, even if
asked to "finish it".

## Rejected gates

- **Design laws, mockups, UI critics, accessibility:** no UI.
- **User critics:** no end user. Consumer impact stands in for the
  developer who calls the API.
- **i18n:** no user-facing copy. `displayMessageKey` passes through
  untranslated, and the apps own the strings.
- **Firebase cost:** no Firebase.
- **Golden tests:** nothing renders.
- **Perf as its own gate:** no benchmark harness, and the one real perf
  risk, load multiplied by retries and timeouts, is a Behavior change the
  API compatibility and security gates already weigh.
- **Formal verification, saved state, release build:** no state machine,
  no persisted state, no app build. The apps' own gates cover the release
  build that ships this code.
