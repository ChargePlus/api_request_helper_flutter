# api_request_helper_flutter

Private HTTP-layer library (`publish_to: none`) wrapping GET / POST /
PUT / DELETE over `package:http` with retries. Consumed via UNPINNED git
URL by all three apps and dozens of their local domain packages (26
in the ChargePlus Customer app alone) — and consumers gitignore `pubspec.lock`, so
whatever lands on `main` reaches the whole fleet on their next
`pub get`. Depends on `exceptions_flutter` (also unpinned git) for
`ServiceException`.

## Blast-radius rules

- Breaking public-API changes only when the same piece of work updates
  every consumer in lockstep — call sites number in the dozens.
- This library sits under EVERY network call the fleet makes: behavior
  changes (retries, headers, status-to-exception mapping) are de facto
  breaking even when signatures don't change.

## Logging and secrets (recent hardening — don't regress)

- Request/response logging is gated behind `kDebugMode` and redacts
  sensitive keys. The redaction contract is SHALLOW — a new nested
  secret field needs its own handling; when touching logging, extend
  the sensitive-key list and add a test proving the value is redacted.

## Verify (CI mirrors `./script.sh` option 3)

- `dart format --line-length 80 --set-exit-if-changed lib test`
- `flutter analyze lib test`
- `very_good test -j 4 --coverage --test-randomize-ordering-seed random`
- CI = VeryGood `flutter_package` workflow with `min_coverage: 30`,
  plus semantic PR titles and a spell check over ALL markdown files —
  a typo in any `.md` fails the build.

## Releases and repo facts

- Git Flow release: version bump on `release/X.Y.Z`, merge to
  main + develop, bare-semver tag (currently 1.7.x).
- Pubspec floor is `flutter >=3.38.1` — mind it when adding deps.
- The MIT badge in the README is stale — no LICENSE file exists.
