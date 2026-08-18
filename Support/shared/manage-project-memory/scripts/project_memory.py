#!/usr/bin/env python3
"""Initialize, synchronize, and audit the Lexvora project-management scaffold."""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from urllib.parse import unquote


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCAFFOLD_ROOT = SKILL_ROOT / "assets" / "support-scaffold"

PLAN_START = "<!-- lexvora-plan-index:start -->"
PLAN_END = "<!-- lexvora-plan-index:end -->"
RESEARCH_START = "<!-- lexvora-research-index:start -->"
RESEARCH_END = "<!-- lexvora-research-index:end -->"

PROFILE_VALUES = {
    "structure": {"strict", "hybrid", "preserve-existing"},
    "rigor": {"lean", "standard", "high-assurance"},
    "planning_horizon": {"task", "milestone", "release"},
    "evidence_gate": {"build", "tested", "click-tested", "measured", "released"},
    "decision_style": {"lightweight", "adr"},
    "asset_policy": {"simple", "provenance-tracked"},
    "automation": {"manual", "generated-indexes", "ci-enforced"},
}

REQUIRED_FILES = (
    "Support/project-system.yaml",
    "Support/README.md",
    "Support/context/README.md",
    "Support/context/rules.md",
    "Support/context/architecture.md",
    "Support/context/requirements.md",
    "Support/context/current-context.md",
    "Support/research/README.md",
    "Support/worklog/README.md",
    "Support/worklog/Project-Plan.md",
    "Support/worklog/Verification.md",
    "Support/shared/README.md",
)

CHECKBOX = re.compile(r"^\s*-\s*\[([ xX])\]\s+(.+?)\s*$")
TITLE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)
METADATA = re.compile(r"^\*\*(?P<key>[^*]+):\*\*\s*(?P<value>.+?)\s*$", re.MULTILINE)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
ANONYMOUS_ASSET = re.compile(
    r"^(?:image|img|screenshot|screen[-_ ]?shot|final[-_ ]?final)(?:[-_ ]?\d+)?\.[^.]+$",
    re.IGNORECASE,
)
UUID_NAME = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.[^.]+$",
    re.IGNORECASE,
)
SPECULATIVE_TASK = re.compile(r"\b(?:decide whether|maybe|possibly|consider whether)\b", re.IGNORECASE)


@dataclass(frozen=True)
class Finding:
    level: str
    path: Path
    message: str


def repository_root(value: str) -> Path:
    root = Path(value).expanduser().resolve()
    if not root.is_dir():
        raise argparse.ArgumentTypeError(f"repository root is not a directory: {root}")
    return root


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.lexvora-tmp")
    temporary.write_text(text, encoding="utf-8")
    os.replace(temporary, path)


def metadata_for(text: str) -> dict[str, str]:
    return {match.group("key").strip().lower(): match.group("value").strip() for match in METADATA.finditer(text)}


def title_for(path: Path, text: str) -> str:
    match = TITLE.search(text)
    return match.group(1) if match else path.stem


def checkbox_counts(text: str) -> tuple[int, int]:
    done = pending = 0
    for line in text.splitlines():
        match = CHECKBOX.match(line)
        if not match:
            continue
        if match.group(1).lower() == "x":
            done += 1
        else:
            pending += 1
    return done, pending


def status_for(done: int, pending: int, declared: str | None = None) -> str:
    if declared:
        return declared
    if done + pending == 0:
        return "Index only"
    if pending == 0:
        return "Complete"
    if done == 0:
        return "Proposed"
    return "Active"


def render_plan_index(root: Path) -> str:
    worklog = root / "Support" / "worklog"
    plans = sorted(worklog.glob("Plan-*.md"), key=lambda item: item.name.casefold())
    if not plans:
        return "\n".join((PLAN_START, "", "*No area plans.*", "", PLAN_END))

    rows = [
        PLAN_START,
        "",
        "| Plan | Status | Done | Pending |",
        "| --- | --- | ---: | ---: |",
    ]
    total_done = total_pending = 0
    for path in plans:
        text = read_text(path)
        meta = metadata_for(text)
        done, pending = checkbox_counts(text)
        total_done += done
        total_pending += pending
        rows.append(
            f"| [{title_for(path, text)}]({path.name}) | "
            f"{status_for(done, pending, meta.get('status'))} | {done} | {pending} |"
        )
    rows.extend(
        (
            f"| **All plans** | **{status_for(total_done, total_pending)}** | "
            f"**{total_done}** | **{total_pending}** |",
            "",
            PLAN_END,
        )
    )
    return "\n".join(rows)


def render_research_index(root: Path) -> str:
    research = root / "Support" / "research"
    topics = sorted(
        (path for path in research.glob("*.md") if path.name != "README.md"),
        key=lambda item: item.name.casefold(),
    )
    if not topics:
        return "\n".join((RESEARCH_START, "", "*No research topics.*", "", RESEARCH_END))

    rows = [
        RESEARCH_START,
        "",
        "| Topic | Question | Stage | Opened |",
        "| --- | --- | --- | --- |",
    ]
    for path in topics:
        text = read_text(path)
        meta = metadata_for(text)
        rows.append(
            f"| [{title_for(path, text)}]({path.name}) | {meta.get('question', '—')} | "
            f"{meta.get('stage', '—')} | {meta.get('opened', '—')} |"
        )
    rows.extend(("", RESEARCH_END))
    return "\n".join(rows)


def splice_generated(path: Path, start: str, end: str, rendered: str) -> tuple[str, str]:
    current = read_text(path)
    if start not in current or end not in current:
        raise ValueError(f"missing generated markers in {path}")
    head, remainder = current.split(start, 1)
    _, tail = remainder.split(end, 1)
    return current, head + rendered + tail


def synchronized_texts(root: Path) -> list[tuple[Path, str, str]]:
    profile = root / "Support" / "project-system.yaml"
    names = profile_name_map(profile) if profile.exists() else {}
    plan_index = root / names.get("Support/worklog/Project-Plan.md", "Support/worklog/Project-Plan.md")
    targets = (
        (
            plan_index,
            PLAN_START,
            PLAN_END,
            render_plan_index(root),
        ),
        (
            root / "Support" / "research" / "README.md",
            RESEARCH_START,
            RESEARCH_END,
            render_research_index(root),
        ),
    )
    results: list[tuple[Path, str, str]] = []
    for path, start, end, rendered in targets:
        if not path.exists():
            raise ValueError(f"missing index file: {path}")
        current, updated = splice_generated(path, start, end, rendered)
        results.append((path, current, updated))
    return results


def profile_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in read_text(path).splitlines():
        if line.startswith((" ", "\t")) or ":" not in line:
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"\'')
    return values


def profile_name_map(path: Path) -> dict[str, str]:
    """Read the profile's `names:` block: Lexvora role file -> this repository's file.

    `structure: preserve-existing` is a documented mode, so a repository that grew its own
    entry-point names must be able to declare them rather than either renaming its files or
    living with permanent audit errors. Only the mapped roles move; everything else is still
    required at its standard path.
    """
    mapping: dict[str, str] = {}
    inside = False
    for line in read_text(path).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not line.startswith((" ", "\t")):
            inside = stripped == "names:"
            continue
        if inside and ":" in stripped:
            role, actual = stripped.split(":", 1)
            mapping[role.strip().strip("\"'")] = actual.strip().strip("\"'")
    return mapping


def exact_case_exists(path: Path) -> bool:
    if not path.exists():
        return False
    current = Path(path.anchor)
    for part in path.parts[1:]:
        try:
            names = {entry.name for entry in current.iterdir()}
        except OSError:
            return False
        if part not in names:
            return False
        current /= part
    return True


def local_link_target(source: Path, raw_target: str) -> Path | None:
    target = raw_target.strip()
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    elif " \"" in target or " '" in target:
        target = target.split(" ", 1)[0]
    if not target or target.startswith(("#", "http://", "https://", "mailto:", "data:")):
        return None
    target = unquote(target.split("#", 1)[0])
    if not target:
        return None
    return (source.parent / target).resolve()


def audit_repository(root: Path) -> list[Finding]:
    findings: list[Finding] = []

    profile = root / "Support" / "project-system.yaml"
    names = profile_name_map(profile) if profile.exists() else {}

    for relative in REQUIRED_FILES:
        path = root / names.get(relative, relative)
        if not path.exists():
            detail = "required scaffold file is missing"
            if relative in names:
                detail += f" (mapped from {relative})"
            findings.append(Finding("ERROR", path, detail))

    if profile.exists():
        values = profile_values(profile)
        if values.get("system") != "lexvora-project-management":
            findings.append(Finding("ERROR", profile, "system must be lexvora-project-management"))
        if values.get("attribution") != "Lexvora Consulting":
            findings.append(Finding("ERROR", profile, "method attribution must be Lexvora Consulting"))
        for key, allowed in PROFILE_VALUES.items():
            value = values.get(key)
            if value not in allowed:
                findings.append(Finding("ERROR", profile, f"{key} must be one of: {', '.join(sorted(allowed))}"))

    research = root / "Support" / "research"
    if research.exists():
        for path in sorted(research.glob("*.md")):
            if path.name == "README.md":
                continue
            text = read_text(path)
            meta = metadata_for(text)
            for key in ("stage", "opened", "question"):
                if key not in meta:
                    findings.append(Finding("ERROR", path, f"research metadata is missing: {key}"))
            for number, line in enumerate(text.splitlines(), start=1):
                if CHECKBOX.match(line):
                    findings.append(Finding("ERROR", path, f"research contains a task checkbox at line {number}"))

    worklog = root / "Support" / "worklog"
    duplicate_tasks: dict[str, list[Path]] = {}
    if worklog.exists():
        for path in sorted(worklog.glob("Plan-*.md")):
            text = read_text(path)
            if not TITLE.search(text):
                findings.append(Finding("ERROR", path, "plan has no H1 title"))
            if not re.search(r"^>\s+.*\bOwns\b", text, re.MULTILINE | re.IGNORECASE):
                findings.append(Finding("ERROR", path, "plan has no opening ownership boundary"))
            for heading in ("## Work plan", "## Tracking"):
                if heading not in text:
                    findings.append(Finding("ERROR", path, f"plan is missing {heading}"))
            for number, line in enumerate(text.splitlines(), start=1):
                match = CHECKBOX.match(line)
                if not match:
                    continue
                task = re.sub(r"\s+", " ", match.group(2).strip().casefold())
                duplicate_tasks.setdefault(task, []).append(path)
                if SPECULATIVE_TASK.search(match.group(2)):
                    findings.append(Finding("WARN", path, f"task may be unapproved speculation at line {number}"))

    for task, paths in duplicate_tasks.items():
        owners = sorted({path for path in paths}, key=str)
        if len(owners) > 1:
            rendered = ", ".join(str(path.relative_to(root)) for path in owners)
            findings.append(Finding("WARN", root / "Support" / "worklog", f"duplicate task '{task}' in {rendered}"))

    support = root / "Support"
    if support.exists():
        for path in sorted(support.rglob("*.md")):
            text = read_text(path)
            for match in MARKDOWN_LINK.finditer(text):
                target = local_link_target(path, match.group(1))
                if target is None:
                    continue
                if not target.exists():
                    findings.append(Finding("ERROR", path, f"broken local link: {match.group(1)}"))
                elif not exact_case_exists(target):
                    findings.append(Finding("ERROR", path, f"link casing does not match disk: {match.group(1)}"))

        asset_extensions = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".pdf", ".mov", ".mp4", ".webp"}
        for path in sorted(item for item in support.rglob("*") if item.is_file()):
            if path.suffix.casefold() not in asset_extensions:
                continue
            if ANONYMOUS_ASSET.match(path.name) or UUID_NAME.match(path.name):
                findings.append(Finding("WARN", path, "asset filename does not communicate purpose or ownership"))

    # A repository that already generates its own indexes owns that job; the skill defers to it
    # rather than demanding a second set of markers. The profile has to name the generator, and
    # it has to exist, so "we have our own" cannot become "nobody checks".
    generator = profile_values(profile).get("generator") if profile.exists() else None
    if generator:
        if not (root / generator).exists():
            findings.append(Finding("ERROR", root / generator, "profile names a generator that does not exist"))
    else:
        try:
            for path, current, updated in synchronized_texts(root):
                if current != updated:
                    findings.append(Finding("ERROR", path, "generated index is stale; run sync"))
        except ValueError as error:
            findings.append(Finding("ERROR", root / "Support", str(error)))

    return findings


def replace_profile_value(text: str, key: str, value: str) -> str:
    return re.sub(rf"^{re.escape(key)}:.*$", f"{key}: {value}", text, flags=re.MULTILINE)


def command_init(args: argparse.Namespace) -> int:
    root: Path = args.root
    support = root / "Support"
    if support.exists() and not args.fill_missing:
        print(
            f"error: {support} already exists; use adopt mode or rerun with --fill-missing after review",
            file=sys.stderr,
        )
        return 2

    project = (args.project or root.name).replace("\\", "\\\\").replace('"', '\\"')
    replacements = {"{{PROJECT_NAME}}": project, "{{DATE}}": date.today().isoformat()}
    created: list[Path] = []
    skipped: list[Path] = []

    for template in sorted(SCAFFOLD_ROOT.rglob("*.tmpl")):
        relative = template.relative_to(SCAFFOLD_ROOT).with_suffix("")
        destination = root / relative
        if destination.exists():
            skipped.append(destination)
            continue
        text = read_text(template)
        for token, value in replacements.items():
            text = text.replace(token, value)
        if destination.name == "project-system.yaml":
            for key in PROFILE_VALUES:
                value = getattr(args, key)
                text = replace_profile_value(text, key, value)
        atomic_write(destination, text)
        created.append(destination)

    (root / "Support" / "context" / "decisions").mkdir(parents=True, exist_ok=True)

    try:
        for path, current, updated in synchronized_texts(root):
            if current != updated:
                atomic_write(path, updated)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    print(f"Initialized Lexvora project management for {project}.")
    print(f"Created {len(created)} file(s); skipped {len(skipped)} existing file(s).")
    for path in created:
        print(f"  created {path.relative_to(root)}")
    for path in skipped:
        print(f"  preserved {path.relative_to(root)}")
    print("Review every placeholder against repository evidence, then run audit.")
    return 0


def command_sync(args: argparse.Namespace) -> int:
    try:
        targets = synchronized_texts(args.root)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    stale = [path for path, current, updated in targets if current != updated]
    if args.check:
        if stale:
            for path in stale:
                print(f"stale: {path.relative_to(args.root)}", file=sys.stderr)
            return 1
        print("Lexvora plan and research indexes are current.")
        return 0

    for path, current, updated in targets:
        if current == updated:
            continue
        atomic_write(path, updated)
        print(f"Updated {path.relative_to(args.root)}")
    if not stale:
        print("Lexvora plan and research indexes are already current.")
    return 0


def command_audit(args: argparse.Namespace) -> int:
    findings = audit_repository(args.root)
    for finding in findings:
        try:
            path = finding.path.relative_to(args.root)
        except ValueError:
            path = finding.path
        print(f"{finding.level}: {path}: {finding.message}")

    errors = sum(finding.level == "ERROR" for finding in findings)
    warnings = sum(finding.level == "WARN" for finding in findings)
    if not findings:
        print("Lexvora project-memory audit passed with no findings.")
    else:
        print(f"Audit result: {errors} error(s), {warnings} warning(s).")
    return 1 if errors or (args.strict and warnings) else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="create the standard Support scaffold")
    init_parser.add_argument("--root", type=repository_root, default=Path.cwd(), help="repository root")
    init_parser.add_argument("--project", help="project display name; defaults to the directory name")
    init_parser.add_argument("--fill-missing", action="store_true", help="add missing files without overwriting existing ones")
    for key, allowed in PROFILE_VALUES.items():
        default = {
            "structure": "hybrid",
            "rigor": "standard",
            "planning_horizon": "milestone",
            "evidence_gate": "tested",
            "decision_style": "adr",
            "asset_policy": "provenance-tracked",
            "automation": "generated-indexes",
        }[key]
        init_parser.add_argument(f"--{key.replace('_', '-')}", choices=sorted(allowed), default=default)
    init_parser.set_defaults(handler=command_init)

    sync_parser = subparsers.add_parser("sync", help="regenerate plan and research indexes")
    sync_parser.add_argument("--root", type=repository_root, default=Path.cwd(), help="repository root")
    sync_parser.add_argument("--check", action="store_true", help="report stale indexes without writing")
    sync_parser.set_defaults(handler=command_sync)

    audit_parser = subparsers.add_parser("audit", help="validate the standard Support scaffold")
    audit_parser.add_argument("--root", type=repository_root, default=Path.cwd(), help="repository root")
    audit_parser.add_argument("--strict", action="store_true", help="treat warnings as failures")
    audit_parser.set_defaults(handler=command_audit)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.handler(args)


if __name__ == "__main__":
    raise SystemExit(main())
