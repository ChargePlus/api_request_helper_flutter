"""Check the review evidence recorded in a pull request body.

Shared by the ChargePlus repos. Each repo's `.github/review-gates.json`
names its own fields and prose-only paths; without it the defaults below
apply. A PR opened by a bot account (Dependabot and the like) is skipped.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

FIELDS = ("Gates run", "Independent verdict", "Driver critics", "Verification-blocked")
PROSE_FILES = ("HANDOFF.md",)
PROSE_PREFIXES = ("docs/briefs/", "docs/notes/")
CONFIG = Path(".github/review-gates.json")
SHA = re.compile(r"[0-9a-fA-F]{40}")
VERDICT_SHA = re.compile(r"(?<!\w)[0-9a-fA-F]{40}(?!\w)")
# `<…>` template text; an autolink such as <https://…> (a scheme, no spaces) is not one.
PLACEHOLDER = re.compile(r"<(?![a-zA-Z][\w+.-]*:[^\s<>]*>)[^<>\n]+>")
PASS = re.compile(r"^`?(?:PASS\+NOTES|PASS)`?(?=\s|·|$)")


def changed_files(base, head):
    # Treat renames as deletion plus addition so both paths count.
    output = subprocess.check_output([
        "git", "diff", "--name-only", "-z", "--no-renames", f"{base}...{head}", "--",
    ])
    return [os.fsdecode(path) for path in output.split(b"\0") if path]


def load_config(path=CONFIG):
    """Return (fields, prose files, prose prefixes) from the repo's config."""
    if not path.exists():
        return FIELDS, PROSE_FILES, PROSE_PREFIXES
    data = json.loads(path.read_text(encoding="utf-8"))
    fields = tuple(data.get("fields", FIELDS))
    if "Gates run" not in fields or "Independent verdict" not in fields:
        raise ValueError("review-gates.json fields must include Gates run and Independent verdict")
    prose = data.get("proseOnly", {})
    return fields, tuple(prose.get("files", PROSE_FILES)), tuple(prose.get("prefixes", PROSE_PREFIXES))


def problems(body, head, files, config=None):
    """Return the problems in the Review gates section."""
    fields_, prose_files, prose_prefixes = config or (FIELDS, PROSE_FILES, PROSE_PREFIXES)
    body = (body or "").replace("\r\n", "\n")
    body = re.sub(r"<!--.*?(?:-->|\Z)", "", body, flags=re.DOTALL)
    body = re.sub(
        r"^ {0,3}(`{3,}|~{3,})[^\n]*\n.*?(?:^ {0,3}\1[`~]*[ \t]*$|\Z)",
        "", body, flags=re.MULTILINE | re.DOTALL,
    )
    sections = re.split(r"^ {0,3}(#{1,2})[ \t]+([^\n]*)\n?", body, flags=re.MULTILINE)
    for level, heading, section in zip(sections[1::3], sections[2::3], sections[3::3]):
        if level == "##" and heading.strip() == "Review gates":
            break
    else:
        return ["Missing ## Review gates section."]

    if section.strip() in ("None: prose-only", "- None: prose-only"):
        if files and all(
            path in prose_files or path.startswith(prose_prefixes)
            for path in files
        ):
            return []
        allowed = ", ".join((*prose_prefixes, *prose_files))
        return [f"None: prose-only requires changes confined to {allowed}."]

    labels = "|".join(re.escape(name) for name in fields_)
    fields = re.finditer(
        rf"^ {{0,3}}(?:[-*+] +)?\*\*({labels}):\*\*([^\n]*)", section, re.MULTILINE,
    )
    values = {}
    rest = section
    for field in fields:
        continuation = re.match(r"(?:\n[ \t]+[^\n]*)*", section[field.end():])[0]
        values.setdefault(field[1], []).append((field[2].strip(), continuation))
        rest = rest.replace(field[0] + continuation, "", 1)

    errors = []
    for name in fields_:
        rows = values.get(name, [])
        if not rows:
            errors.append(f"Missing {name} line.")
            continue
        if len(rows) > 1:
            errors.append(f"Multiple {name} lines.")
            continue
        value, continuation = rows[0]
        if not (value or continuation.strip()) or PLACEHOLDER.search(prose(value + continuation)):
            errors.append(f"Fill in the {name} line.")
        elif name != "Independent verdict" and pending(prose(value + continuation)):
            errors.append(f"Finish the {name} line: a gate is still pending.")
        if name != "Independent verdict":
            continue
        if not PASS.match(value) or re.search(r"\bpending\b", value, re.IGNORECASE):
            errors.append("Independent verdict must be PASS or PASS+NOTES.")
        verdict = value + continuation
        coverage = re.search(r"\bcovers\s+[`\[]?", verdict)
        if coverage:
            sha = VERDICT_SHA.match(verdict, coverage.end())
        else:
            sha = VERDICT_SHA.search(verdict)
        if sha is None:
            errors.append("Independent verdict needs a full 40-character head SHA.")
        elif sha[0].lower() != head.lower():
            errors.append(f"The verdict covers {sha[0]}, head is {head}: re-run or re-check the verdict.")
    # Anywhere else in the section: text after a blank line or after the
    # four lines.
    for line in prose(rest).splitlines():
        if PLACEHOLDER.search(line):
            errors.append(f"Fill in the placeholder: {line.strip()}")
        elif pending(line):
            errors.append(f"A gate is still pending: {line.strip()}")
    return errors


def pending(text):
    """Whether a gate's status is pending: the first word after a gate's
    label, the last word of a gate or of its label, or `(pending)`, in any
    line or `;`, `·` or `|` part. A word inside a description ("the Leave
    pending/hide gap") is not."""
    for part in re.split(r"[\n;·|]", text):
        if re.search(r"\(\W*pending\W*\)", part, re.IGNORECASE):
            return True
        part = re.sub(r"\([^()\n]*\)", " ", part)
        *labels, _ = part.split(":")
        words = re.findall(r"\w[\w/-]*", part.partition(":")[2] or part)
        if words and "pending" in (words[0].lower(), words[-1].lower()):
            return True
        for label in labels:
            label_words = re.findall(r"\w[\w/-]*", label)
            if label_words and label_words[-1].lower() == "pending":
                return True
    return False


def prose(text):
    """Text outside code spans, which may hold generics such as `Future<void>`."""
    return re.sub(r"`[^`\n]*`", "", text)


def main():
    try:
        event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text(encoding="utf-8"))
        pr = event["pull_request"]
        if (pr.get("user") or {}).get("type") == "Bot":
            print(f"Review gates skipped: opened by the bot {pr['user'].get('login')}.")
            return 0
        config = load_config()
        base, head = pr["base"]["sha"], pr["head"]["sha"]
        if not SHA.fullmatch(base) or not SHA.fullmatch(head):
            raise ValueError("expected full base and head SHAs")
        errors = problems(pr["body"], head, changed_files(base, head), config)
    except (AttributeError, KeyError, OSError, TypeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Review gates setup error: {error}", file=sys.stderr)
        return 2
    for error in errors:
        print(error)
    if not errors:
        print(f"Review gates pass for PR head {head}.")
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
