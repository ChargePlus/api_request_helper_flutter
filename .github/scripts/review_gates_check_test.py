"""Run with python3 -m unittest discover -s .github/scripts -p review_gates_check_test.py."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import unittest
from unittest import mock

import review_gates_check as check

HEAD = "abcdef0123456789abcdef0123456789abcdef01"
BASE = "b" * 40
BODY = f"""## What is the change about?
Check that PRs are ready for review.

## Review gates
<!-- Write "None: prose-only" for prose-only changes. -->

- **Gates run:**
  - **Tests:** 14 tests passed.
  - **Security:** no findings.
- **Independent verdict:** PASS · [comment](https://example.com/comment) · covers {HEAD}. The verifier ran the checker.
- **Driver critics:** n/a: nothing user-visible
- **Verification-blocked:** none
"""


class ReviewGatesTest(unittest.TestCase):
    def result(self, body=BODY, files=None):
        return check.problems(body, HEAD, ["lib/app.dart"] if files is None else files)

    def test_filled_body(self):
        self.assertEqual(self.result(), [])
        self.assertEqual(self.result(BODY.replace("\n", "\r\n")), [])

    def test_missing_section(self):
        for body in (None, BODY.replace("## Review gates", "### Review gates"), "<!--\n" + BODY + "-->"):
            with self.subTest(body=body):
                self.assertEqual(self.result(body), ["Missing ## Review gates section."])

    def test_missing_each_field(self):
        for field in check.FIELDS:
            with self.subTest(field=field):
                body = BODY.replace(f"**{field}:**", "**Other:**")
                self.assertIn(f"Missing {field} line.", self.result(body))

    def test_fields_outside_section_do_not_count(self):
        body = BODY.replace("- **Driver critics:**", "## Other\n- **Driver critics:**")
        self.assertIn("Missing Driver critics line.", self.result(body))

    def test_placeholder_in_each_field(self):
        for field in check.FIELDS:
            with self.subTest(field=field):
                body = BODY.replace(f"**{field}:**", f"**{field}:** <placeholder>")
                self.assertIn(f"Fill in the {field} line.", self.result(body))

    def test_placeholder_in_nested_gate(self):
        body = BODY.replace("no findings.", "<result>")
        self.assertIn("Fill in the Gates run line.", self.result(body))

    def test_placeholder_in_partial_verdict(self):
        body = BODY.replace("PASS ·", "PASS+NOTES (partial: <reason>) ·")
        self.assertIn("Fill in the Independent verdict line.", self.result(body))

    def test_code_span_generic_is_not_a_placeholder(self):
        body = BODY.replace("14 tests passed.", "14 tests passed; `Future<void>` returns.")
        self.assertEqual(self.result(body), [])
        body = BODY.replace("14 tests passed.", "<the gates>")
        self.assertEqual(self.result(body), ["Fill in the Gates run line."])

    def test_placeholder_or_pending_anywhere_in_section(self):
        cases = {
            "nested pending": BODY.replace("no findings.", "pending"),
            "after a blank line": BODY.replace("  - **Security:** no findings.", "\n  - **Security:** <result>"),
            "after the four lines": BODY + "\n<anything else>\n",
        }
        for label, body in cases.items():
            with self.subTest(label):
                self.assertEqual(len(self.result(body)), 1, self.result(body))

    def test_pending_as_a_gate_status(self):
        for status in (
            "pending",
            "⏳ Pending",
            "pending: device tier",
            "n/a; perf device tiers pending",
            "✅ · Perf device tiers: pending",
            "Perf device tiers ⏳ pending (no device)",
            "Perf (tier B, run 10:30): pending",
            "- pending on Pixel 3",
            "perf (pending)",
            "critic pending: agent still running",
        ):
            with self.subTest(status=status):
                body = BODY.replace("no findings.", status)
                self.assertEqual(self.result(body), ["Finish the Gates run line: a gate is still pending."])
        body = BODY.replace("  - **Security:** no findings.", "  - **Security** pending")
        self.assertEqual(self.result(body), ["Finish the Gates run line: a gate is still pending."])
        body = BODY + "| Perf device tiers | ⏳ | pending |\n"
        self.assertEqual(self.result(body), ["A gate is still pending: | Perf device tiers | ⏳ | pending |"])

    def test_pending_inside_a_description_is_not_a_status(self):
        # PR #2729 went red on the first of these.
        for text in (
            "the Leave pending/hide gap is now modelled.",
            "_pending stays shared across places.",
            "pendingLeave is cleared on sign-out.",
            "Leave counts itself pending before stopping the watch.",
            "Pending-leave race is covered by the model.",
        ):
            with self.subTest(text=text):
                self.assertEqual(self.result(BODY.replace("no findings.", text)), [])
        body = BODY.replace("**Security:** no findings.", "**Pending leave:** now modelled.")
        self.assertEqual(self.result(body), [])

    def test_pending_check_is_linear(self):
        started = time.monotonic()
        self.result(BODY.replace("no findings.", " " * 60000 + "x"))
        self.assertLess(time.monotonic() - started, 1)

    def test_autolink_is_not_a_placeholder(self):
        body = BODY.replace("[comment](https://example.com/comment)", "<https://example.com/comment>")
        self.assertEqual(self.result(body), [])

    def test_placeholder_with_a_colon_is_not_an_autolink(self):
        for text in ("<todo: what no run could prove>", "<partial: why>"):
            with self.subTest(text=text):
                self.assertEqual(self.result(BODY.replace("no findings.", text)), ["Fill in the Gates run line."])

    def test_wrapped_or_linked_coverage(self):
        for verdict in (
            f"PASS+NOTES · [comment](https://example.com/comment) ·\n  covers {HEAD}",
            f"PASS · [comment](https://example.com/comment) · covers [{HEAD}](https://example.com/commit/{HEAD})",
            f"PASS (supersedes the FAIL on {BASE}), covers {HEAD}",
        ):
            with self.subTest(verdict=verdict):
                body = re.sub(r"(?<=\*\*Independent verdict:\*\* )[^\n]*", verdict.replace("\\", "\\\\"), BODY)
                self.assertEqual(self.result(body), [])

    def test_fenced_field_does_not_count(self):
        body = BODY.replace("- **Verification-blocked:** none", "```\n- **Verification-blocked:** none\n```")
        self.assertIn("Missing Verification-blocked line.", self.result(body))

    def test_passing_verdicts(self):
        for verdict in ("PASS", "PASS+NOTES", "PASS+NOTES (partial: staging unavailable)"):
            with self.subTest(verdict=verdict):
                self.assertEqual(self.result(BODY.replace("PASS ·", verdict + " ·")), [])

    def test_invalid_verdicts(self):
        for verdict in ("FAIL", "pending", "PASS (pending)", "PASSING", "PASS+NOTES+"):
            with self.subTest(verdict=verdict):
                body = BODY.replace("PASS ·", verdict + " ·")
                self.assertIn("Independent verdict must be PASS or PASS+NOTES.", self.result(body))

    def test_missing_or_invalid_sha(self):
        for sha in ("", HEAD[:39], HEAD + "0", "z" + HEAD):
            with self.subTest(sha=sha):
                self.assertIn(
                    "Independent verdict needs a full 40-character head SHA.",
                    self.result(BODY.replace(HEAD, sha)),
                )

    def test_stale_sha(self):
        self.assertEqual(self.result(BODY.replace(HEAD, BASE)), [
            f"The verdict covers {BASE}, head is {HEAD}: re-run or re-check the verdict.",
        ])

    def test_explicit_coverage_takes_precedence_over_other_shas(self):
        body = BODY.replace("PASS ·", f"PASS · [commit](https://example.com/{HEAD}) ·")
        body = body.replace(f"covers {HEAD}", f"covers {BASE}")
        self.assertIn(f"The verdict covers {BASE}, head is {HEAD}: re-run or re-check the verdict.", self.result(body))

    def test_extra_row_does_not_fill_empty_field(self):
        body = BODY.replace("**Verification-blocked:** none", "**Verification-blocked:**\n- **CI note:** none")
        self.assertIn("Fill in the Verification-blocked line.", self.result(body))

    def test_prose_only_allowed_paths(self):
        self.assertEqual(self.result("## Review gates\nNone: prose-only", [
            "docs/briefs/sample.md", "docs/notes/sample.md", "HANDOFF.md",
        ]), [])

    def test_prose_only_rejects_other_paths(self):
        for files in ([], ["README.md"], ["docs/briefs-extra/a.md"], ["HANDOFF.md", "lib/app.dart"]):
            with self.subTest(files=files):
                self.assertTrue(self.result("## Review gates\nNone: prose-only", files))

    def test_diff_counts_both_paths_of_a_rename(self):
        with mock.patch.object(subprocess, "check_output", return_value=b"lib/example.dart\0docs/notes/example.md\0") as git:
            self.assertEqual(check.changed_files(BASE, HEAD), ["lib/example.dart", "docs/notes/example.md"])
            git.assert_called_once_with([
                "git", "diff", "--name-only", "-z", "--no-renames", f"{BASE}...{HEAD}", "--",
            ])

    def test_cli_exit_codes(self):
        with tempfile.TemporaryDirectory() as folder:
            payload = Path(folder) / "event.json"
            pr = {"body": BODY, "head": {"sha": HEAD}, "base": {"sha": BASE}}
            with mock.patch.dict(os.environ, {"GITHUB_EVENT_PATH": str(payload)}), mock.patch.object(
                check, "changed_files", return_value=["lib/app.dart"],
            ), mock.patch.object(
                check, "load_config", return_value=check.DEFAULTS,
            ), mock.patch("builtins.print") as report:
                for body, expected in ((BODY, 0), ("", 1)):
                    pr["body"] = body
                    payload.write_text(json.dumps({"pull_request": pr}))
                    self.assertEqual(check.main(), expected)
                report.assert_called_with("Missing ## Review gates section.")
                pr["head"]["sha"] = "not a sha"
                payload.write_text(json.dumps({"pull_request": pr}))
                self.assertEqual(check.main(), 2)
                self.assertIn("setup error", report.call_args.args[0])

    def test_custom_fields_and_prose_paths(self):
        config = check.Config(("Gates run", "Independent verdict", "Verification-blocked"), ("README.md",), ("docs/",))
        body = BODY.replace("- **Driver critics:** n/a: nothing user-visible\n", "")
        self.assertEqual(check.problems(body, HEAD, ["lib/app.dart"], config), [])
        self.assertIn("Missing Verification-blocked line.", check.problems(
            body.replace("- **Verification-blocked:** none\n", ""), HEAD, ["lib/app.dart"], config))
        self.assertEqual(check.problems("## Review gates\nNone: prose-only", HEAD, ["README.md", "docs/a.md"], config), [])
        self.assertTrue(check.problems("## Review gates\nNone: prose-only", HEAD, ["HANDOFF.md"], config))

    def test_load_config(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "review-gates.json"
            self.assertEqual(check.load_config(path), check.DEFAULTS)
            path.write_text(json.dumps({"fields": ["Gates run", "Independent verdict"], "proseOnly": {"prefixes": ["docs/"]}}))
            self.assertEqual(check.load_config(path), (("Gates run", "Independent verdict"), check.PROSE_FILES, ("docs/",)))
            for bad in (
                {"fields": ["Gates run"]},
                {"fields": "Gates run, Independent verdict"},
                {"proseOnly": {"prefixes": "docs/"}},
                {"proseOnly": {"prefixes": [""]}},
                {"proseOnly": {"files": [1]}},
                {"proseOnly": []},
                [],
            ):
                path.write_text(json.dumps(bad))
                with self.assertRaises(ValueError, msg=bad):
                    check.load_config(path)

    def test_config_sits_next_to_the_script(self):
        self.assertEqual(check.CONFIG, Path(check.__file__).resolve().parent.parent / "review-gates.json")
        if not check.CONFIG.is_file():
            self.skipTest(f"no {check.CONFIG} in this checkout")
        committed = json.loads(check.CONFIG.read_text(encoding="utf-8"))
        self.assertEqual(check.load_config().fields, tuple(committed.get("fields", check.FIELDS)))

    def test_only_dependabot_skips_the_check(self):
        with tempfile.TemporaryDirectory() as folder:
            payload = Path(folder) / "event.json"
            pr = {"body": "", "head": {"sha": HEAD}, "base": {"sha": BASE}}
            with mock.patch.dict(os.environ, {"GITHUB_EVENT_PATH": str(payload)}), mock.patch.object(
                check, "changed_files", return_value=["lib/app.dart"],
            ), mock.patch("builtins.print"):
                for login, expected in (("dependabot[bot]", 0), ("Copilot", 1), ("claude[bot]", 1)):
                    pr["user"] = {"type": "Bot", "login": login}
                    payload.write_text(json.dumps({"pull_request": pr}))
                    self.assertEqual(check.main(), expected, login)


if __name__ == "__main__":
    unittest.main()
