#!/usr/bin/env python3
"""Find, list and check the [ID] definition tags in engineering specs.

An ID such as ARCH-01 is defined once, by writing it in square brackets at the
start of a paragraph or in the first cell of a table row. Every other mention is
the bare ID. Fenced code blocks and inline code spans are ignored, so examples
never count as definitions or mentions. When a spec has a prefix table, the
check also warns about prefixes missing from it or listed without definitions.
"""

from __future__ import annotations

import argparse
import json
import re
import signal
import sys
from dataclasses import dataclass, field
from pathlib import Path

COMPARISON_VERSION = 1
ID_PATTERN = r"[A-Z][A-Z0-9]*-\d{2,}"
TAG = re.compile(r"\[(" + ID_PATTERN + r")\]")
TAG_FIRST = re.compile(r"^\s*\[" + ID_PATTERN + r"\]")
MENTION = re.compile(r"(?<![\w\[\-])(" + ID_PATTERN + r")(?![\w\]\-])")
PARAGRAPH_START = re.compile(r"^\s*\[(" + ID_PATTERN + r")\]\s")
TABLE_START = re.compile(r"^\s*\|\s*\[(" + ID_PATTERN + r")\]\s*\|")
INLINE_CODE = re.compile(r"`[^`]*`")
FENCE_OPEN = re.compile(r"^\s*(`{3,}|~{3,})")
HEADING = re.compile(r"^#{1,6} ")
CELL_DIVIDER = re.compile(r"(?<!\\)\|")
PREFIX_NAME = re.compile(r"[A-Z][A-Z0-9]*")
PREFIX_TABLE_HEADER = ["prefix", "area", "section"]


class SpecError(Exception):
    """A spec file could not be read."""


@dataclass(frozen=True)
class Line:
    path: Path
    number: int
    text: str
    # The text with inline code spans removed, used for matching tags and mentions.
    code_free: str


@dataclass(frozen=True)
class Definition:
    id: str
    path: Path
    line: int
    end_line: int
    kind: str
    text: str
    withdrawn: bool

    def to_json(self) -> dict[str, object]:
        return {
            "id": self.id,
            "file": str(self.path),
            "line": self.line,
            "end_line": self.end_line,
            "kind": self.kind,
            "withdrawn": self.withdrawn,
            "text": self.text,
        }


@dataclass(frozen=True)
class Problem:
    path: Path
    line: int
    severity: str
    rule: str
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.severity}[{self.rule}]: {self.message}"

    def to_json(self) -> dict[str, object]:
        return {
            "file": str(self.path),
            "line": self.line,
            "severity": self.severity,
            "rule": self.rule,
        }


@dataclass
class SpecSet:
    paths: list[Path]
    definitions: list[Definition] = field(default_factory=list)
    misplaced: list[Problem] = field(default_factory=list)
    mentions: list[tuple[str, Line]] = field(default_factory=list)
    prefix_rows: list[tuple[str, Line]] = field(default_factory=list)


def read_text(path: Path) -> str:
    """Return a file's text, without a leading byte order mark."""
    try:
        return path.read_bytes().decode("utf-8-sig")
    except OSError as error:
        raise SpecError(f"{path}: cannot read file ({error.strerror})") from error
    except UnicodeDecodeError as error:
        raise SpecError(
            f"{path}: file must be UTF-8, invalid byte at offset {error.start}"
        ) from error


def split_lines(text: str) -> list[str]:
    """Split at LF and CRLF only, so line numbers match what editors show."""
    lines = text.split("\n")
    if lines[-1] == "":
        lines.pop()
    return [line.removesuffix("\r") for line in lines]


def opening_fence(text: str) -> str | None:
    match = FENCE_OPEN.match(text)
    return match.group(1) if match else None


def closes_fence(text: str, fence: str) -> bool:
    """Return whether a line repeats the fence's character at least as many times."""
    run = text.strip()
    return len(run) >= len(fence) and run == fence[0] * len(run)


def read_lines(path: Path) -> list[Line]:
    """Return the lines outside fenced code."""
    lines: list[Line] = []
    fence: str | None = None
    for number, text in enumerate(split_lines(read_text(path)), start=1):
        if fence is not None:
            if closes_fence(text, fence):
                fence = None
            continue
        fence = opening_fence(text)
        if fence is None:
            lines.append(Line(path, number, text, INLINE_CODE.sub("", text)))
    return lines


def split_cells(text: str) -> list[str]:
    """Split a table row at unescaped pipes, as GitHub Flavored Markdown does."""
    row = text.strip().removeprefix("|")
    if row.endswith("|") and not row.endswith("\\|"):
        row = row[:-1]
    return [cell.strip() for cell in CELL_DIVIDER.split(row)]


def ends_paragraph(line: Line) -> bool:
    text = line.text.strip()
    return (
        not text
        or HEADING.match(line.text) is not None
        or text.startswith("|")
        or TAG_FIRST.match(line.code_free) is not None
    )


def paragraph_span(lines: list[Line], index: int) -> list[Line]:
    """Return the tag line and the lines that continue its paragraph."""
    span = [lines[index]]
    for line in lines[index + 1 :]:
        if line.number != span[-1].number + 1 or ends_paragraph(line):
            break
        span.append(line)
    return span


def make_definition(
    identifier: str, span: list[Line], kind: str, text: str
) -> Definition:
    withdrawn = text.lstrip("*_").lower().startswith("withdrawn")
    first, last = span[0], span[-1]
    return Definition(
        identifier, first.path, first.number, last.number, kind, text, withdrawn
    )


def paragraph_definition(lines: list[Line], index: int, identifier: str) -> Definition:
    span = paragraph_span(lines, index)
    parts = [line.text.strip() for line in span]
    parts[0] = TAG.sub("", parts[0], count=1).strip()
    text = " ".join(part for part in parts if part)
    return make_definition(identifier, span, "paragraph", text)


def row_definition(line: Line, identifier: str) -> Definition:
    text = " | ".join(split_cells(line.text)[1:])
    return make_definition(identifier, [line], "row", text)


def misplaced_tag(line: Line, tags: list[str]) -> Problem:
    listed = ", ".join(tags)
    message = (
        f"tag {listed} must be alone at a paragraph start or in a first table cell"
    )
    return Problem(line.path, line.number, "error", "misplaced-tag", message)


def scan_tag(lines: list[Line], index: int) -> Definition | Problem | None:
    """Return the definition a line starts, or the problem with its tags."""
    line = lines[index]
    tags = TAG.findall(line.code_free)
    if not tags:
        return None
    row = TABLE_START.match(line.code_free)
    paragraph = PARAGRAPH_START.match(line.code_free)
    if len(tags) > 1 or not (row or paragraph):
        return misplaced_tag(line, tags)
    if row:
        return row_definition(line, row.group(1))
    return paragraph_definition(lines, index, tags[0])


def tables(lines: list[Line]) -> list[list[Line]]:
    """Group consecutive lines that start with a pipe into tables."""
    groups: list[list[Line]] = []
    previous: Line | None = None
    for line in lines:
        if not line.text.strip().startswith("|"):
            previous = None
            continue
        if previous is None or line.number != previous.number + 1:
            groups.append([])
        groups[-1].append(line)
        previous = line
    return groups


def is_prefix_table(table: list[Line]) -> bool:
    header = [cell.lower() for cell in split_cells(table[0].text)[:3]]
    return header == PREFIX_TABLE_HEADER


def listed_prefixes(lines: list[Line]) -> list[tuple[str, Line]]:
    """Return each prefix table row's prefix, skipping placeholder rows."""
    rows: list[tuple[str, Line]] = []
    for table in tables(lines):
        if not is_prefix_table(table):
            continue
        for line in table[1:]:
            name = split_cells(line.text)[0]
            if PREFIX_NAME.fullmatch(name):
                rows.append((name, line))
    return rows


def scan_file(lines: list[Line], spec: SpecSet) -> None:
    for index, line in enumerate(lines):
        found = scan_tag(lines, index)
        if isinstance(found, Definition):
            spec.definitions.append(found)
        elif isinstance(found, Problem):
            spec.misplaced.append(found)
        for match in MENTION.finditer(line.code_free):
            spec.mentions.append((match.group(1), line))
    spec.prefix_rows.extend(listed_prefixes(lines))


def collect(paths: list[Path]) -> SpecSet:
    spec = SpecSet(paths)
    for path in paths:
        scan_file(read_lines(path), spec)
    return spec


def prefix_of(identifier: str) -> str:
    return identifier.rsplit("-", 1)[0]


def duplicate_problems(definitions: list[Definition]) -> list[Problem]:
    first_seen: dict[str, Definition] = {}
    problems: list[Problem] = []
    for definition in definitions:
        earlier = first_seen.setdefault(definition.id, definition)
        if earlier is definition:
            continue
        message = f"{definition.id} is already defined at {earlier.path}:{earlier.line}"
        problems.append(
            Problem(definition.path, definition.line, "error", "duplicate-id", message)
        )
    return problems


def undefined_mention_problems(spec: SpecSet) -> list[Problem]:
    """Report mentions of undefined IDs whose prefix has at least one definition."""
    defined = {definition.id for definition in spec.definitions}
    prefixes = {prefix_of(definition.id) for definition in spec.definitions}
    problems: list[Problem] = []
    for mention, line in spec.mentions:
        if mention in defined or prefix_of(mention) not in prefixes:
            continue
        message = f"{mention} is mentioned but never defined"
        problems.append(
            Problem(line.path, line.number, "error", "undefined-id", message)
        )
    return problems


def first_listings(rows: list[tuple[str, Line]]) -> dict[str, Line]:
    """Return each listed prefix's first row, ignoring later repeats."""
    listed: dict[str, Line] = {}
    for name, line in rows:
        listed.setdefault(name, line)
    return listed


def first_definitions(definitions: list[Definition]) -> dict[str, Definition]:
    """Return each used prefix's first definition."""
    used: dict[str, Definition] = {}
    for definition in definitions:
        used.setdefault(prefix_of(definition.id), definition)
    return used


def unlisted_prefix(prefix: str, definition: Definition) -> Problem:
    message = (
        f"prefix {prefix} is used by {definition.id} but missing from the prefix table"
    )
    return Problem(
        definition.path, definition.line, "warning", "unlisted-prefix", message
    )


def unused_prefix(prefix: str, line: Line) -> Problem:
    message = f"prefix {prefix} is in the prefix table but has no definitions"
    return Problem(line.path, line.number, "warning", "unused-prefix", message)


def prefix_table_problems(spec: SpecSet) -> list[Problem]:
    """Warn when the prefix table and the defined prefixes disagree."""
    listed = first_listings(spec.prefix_rows)
    if not listed:
        return []
    used = first_definitions(spec.definitions)
    problems = [
        unlisted_prefix(prefix, definition)
        for prefix, definition in used.items()
        if prefix not in listed
    ]
    problems += [
        unused_prefix(prefix, line)
        for prefix, line in listed.items()
        if prefix not in used
    ]
    return problems


def file_order(paths: list[Path]) -> dict[Path, int]:
    order: dict[Path, int] = {}
    for index, path in enumerate(paths):
        order.setdefault(path, index)
    return order


def all_problems(spec: SpecSet) -> list[Problem]:
    """Return every problem, ordered by file as given and then by line."""
    problems = (
        spec.misplaced
        + duplicate_problems(spec.definitions)
        + undefined_mention_problems(spec)
        + prefix_table_problems(spec)
    )
    order = file_order(spec.paths)
    return sorted(problems, key=lambda problem: (order[problem.path], problem.line))


def run_check(paths: list[Path]) -> int:
    spec = collect(paths)
    problems = all_problems(spec)
    for problem in problems:
        print(problem)
    errors = sum(1 for problem in problems if problem.severity == "error")
    warnings = len(problems) - errors
    print(
        f"{len(spec.definitions)} definitions, {errors} errors, {warnings} warnings",
        file=sys.stderr,
    )
    return 1 if errors else 0


def run_list(paths: list[Path]) -> int:
    for definition in collect(paths).definitions:
        flag = "withdrawn" if definition.withdrawn else ""
        print(
            f"{definition.id}\t{definition.path}\t{definition.line}\t{flag}\t{definition.text}"
        )
    return 0


def run_show(wanted: str, paths: list[Path]) -> int:
    for definition in collect(paths).definitions:
        if definition.id == wanted:
            print(f"{definition.path}:{definition.line}")
            print(definition.text)
            return 0
    print(
        f"{wanted} is not defined in {', '.join(str(path) for path in paths)}",
        file=sys.stderr,
    )
    return 1


def run_json(paths: list[Path]) -> int:
    spec = collect(paths)
    report = {
        "comparison_version": COMPARISON_VERSION,
        "definitions": [definition.to_json() for definition in spec.definitions],
        "problems": [problem.to_json() for problem in all_problems(spec)],
    }
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser(
        "check",
        help="Report misplaced tags, duplicates, undefined IDs and prefix table gaps.",
    )
    check.add_argument("files", nargs="+", type=Path)
    listing = commands.add_parser(
        "list", help="Print every definition as tab-separated fields."
    )
    listing.add_argument("files", nargs="+", type=Path)
    show = commands.add_parser("show", help="Print one definition in full.")
    show.add_argument("id")
    show.add_argument("files", nargs="+", type=Path)
    report = commands.add_parser(
        "json", help="Print definitions and problems as JSON for comparing tools."
    )
    report.add_argument("files", nargs="+", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(signal, "SIGPIPE"):
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = build_parser().parse_args(argv)
    try:
        if args.command == "show":
            return run_show(args.id, args.files)
        runners = {"check": run_check, "list": run_list, "json": run_json}
        return runners[args.command](args.files)
    except SpecError as error:
        print(error, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
