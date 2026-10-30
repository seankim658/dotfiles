#!/usr/bin/env python3
"""Find, list and check the [ID] definition tags in engineering specs.

An ID such as ARCH-01 is defined once, by writing it in square brackets at the
start of a paragraph or in the first cell of a table row. Every other mention is
the bare ID. Fenced code blocks and inline code spans are ignored, so examples
never count as definitions or mentions.
"""

from __future__ import annotations

import argparse
import re
import signal
import sys
from dataclasses import dataclass
from pathlib import Path

ID_PATTERN = r"[A-Z][A-Z0-9]*-\d{2,}"
TAG = re.compile(r"\[(" + ID_PATTERN + r")\]")
MENTION = re.compile(r"(?<![\w\[\-])(" + ID_PATTERN + r")(?![\w\]\-])")
PARAGRAPH_START = re.compile(r"^\s*\[(" + ID_PATTERN + r")\]\s")
TABLE_START = re.compile(r"^\s*\|\s*\[(" + ID_PATTERN + r")\]\s*\|")
INLINE_CODE = re.compile(r"`[^`]*`")
FENCE = re.compile(r"^\s*(```|~~~)")


@dataclass(frozen=True)
class Line:
    path: Path
    number: int
    text: str


@dataclass(frozen=True)
class Definition:
    id: str
    path: Path
    line: int
    text: str
    withdrawn: bool


@dataclass(frozen=True)
class Problem:
    path: Path
    line: int
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.message}"


def read_lines(path: Path) -> list[Line]:
    """Return the lines outside fenced code, with inline code removed."""
    lines: list[Line] = []
    in_fence = False
    for number, raw in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if FENCE.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        lines.append(Line(path, number, INLINE_CODE.sub("", raw)))
    return lines


def definition_text(lines: list[Line], index: int) -> str:
    """Return the paragraph or table row that a tag on lines[index] defines."""
    first = lines[index].text.strip()
    if first.startswith("|"):
        cells = [cell.strip() for cell in first.strip("|").split("|")]
        return " | ".join(cells[1:])
    parts = [TAG.sub("", first, count=1).strip()]
    for line in lines[index + 1 :]:
        if not line.text.strip() or line.number != lines[index].number + len(parts):
            break
        parts.append(line.text.strip())
    return " ".join(parts)


def scan_file(
    path: Path,
) -> tuple[list[Definition], list[Problem], list[tuple[str, Line]]]:
    """Return a file's definitions, misplaced tags, and bare mentions."""
    lines = read_lines(path)
    definitions: list[Definition] = []
    problems: list[Problem] = []
    mentions: list[tuple[str, Line]] = []
    for index, line in enumerate(lines):
        definitions.extend(definitions_on(lines, index, problems))
        for match in MENTION.finditer(line.text):
            mentions.append((match.group(1), line))
    return definitions, problems, mentions


def definitions_on(
    lines: list[Line], index: int, problems: list[Problem]
) -> list[Definition]:
    """Return the definition on lines[index], recording any tag out of place."""
    line = lines[index]
    tags = TAG.findall(line.text)
    if not tags:
        return []
    start = PARAGRAPH_START.match(line.text) or TABLE_START.match(line.text)
    if start is None or len(tags) > 1:
        problems.append(
            Problem(
                line.path,
                line.number,
                f"tag {tags} must be alone at a paragraph start or a first table cell",
            )
        )
        return []
    text = definition_text(lines, index)
    withdrawn = text.lstrip("*_").lower().startswith("withdrawn")
    return [Definition(start.group(1), line.path, line.number, text, withdrawn)]


def collect(
    paths: list[Path],
) -> tuple[list[Definition], list[Problem], list[tuple[str, Line]]]:
    definitions: list[Definition] = []
    problems: list[Problem] = []
    mentions: list[tuple[str, Line]] = []
    for path in paths:
        file_definitions, file_problems, file_mentions = scan_file(path)
        definitions.extend(file_definitions)
        problems.extend(file_problems)
        mentions.extend(file_mentions)
    return definitions, problems, mentions


def duplicate_problems(definitions: list[Definition]) -> list[Problem]:
    first_seen: dict[str, Definition] = {}
    problems: list[Problem] = []
    for definition in definitions:
        earlier = first_seen.get(definition.id)
        if earlier is None:
            first_seen[definition.id] = definition
            continue
        problems.append(
            Problem(
                definition.path,
                definition.line,
                f"{definition.id} is already defined at {earlier.path}:{earlier.line}",
            )
        )
    return problems


def undefined_mention_problems(
    definitions: list[Definition], mentions: list[tuple[str, Line]]
) -> list[Problem]:
    """Report mentions of undefined IDs whose prefix has at least one definition."""
    defined = {definition.id for definition in definitions}
    prefixes = {definition.id.rsplit("-", 1)[0] for definition in definitions}
    problems: list[Problem] = []
    for mention, line in mentions:
        if mention in defined or mention.rsplit("-", 1)[0] not in prefixes:
            continue
        problems.append(
            Problem(line.path, line.number, f"{mention} is mentioned but never defined")
        )
    return problems


def run_check(paths: list[Path]) -> int:
    definitions, problems, mentions = collect(paths)
    problems += duplicate_problems(definitions)
    problems += undefined_mention_problems(definitions, mentions)
    for problem in sorted(problems, key=lambda p: (str(p.path), p.line)):
        print(problem)
    print(f"{len(definitions)} definitions, {len(problems)} problems", file=sys.stderr)
    return 1 if problems else 0


def run_list(paths: list[Path]) -> int:
    definitions, _, _ = collect(paths)
    for definition in definitions:
        flag = "withdrawn" if definition.withdrawn else ""
        print(
            f"{definition.id}\t{definition.path}\t{definition.line}\t{flag}\t{definition.text}"
        )
    return 0


def run_show(wanted: str, paths: list[Path]) -> int:
    definitions, _, _ = collect(paths)
    for definition in definitions:
        if definition.id == wanted:
            print(f"{definition.path}:{definition.line}")
            print(definition.text)
            return 0
    print(
        f"{wanted} is not defined in {', '.join(str(p) for p in paths)}",
        file=sys.stderr,
    )
    return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser(
        "check", help="Report misplaced tags, duplicates and undefined mentions."
    )
    check.add_argument("files", nargs="+", type=Path)
    listing = commands.add_parser(
        "list", help="Print every definition as tab-separated fields."
    )
    listing.add_argument("files", nargs="+", type=Path)
    show = commands.add_parser("show", help="Print one definition in full.")
    show.add_argument("id")
    show.add_argument("files", nargs="+", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(signal, "SIGPIPE"):
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = build_parser().parse_args(argv)
    if args.command == "check":
        return run_check(args.files)
    if args.command == "list":
        return run_list(args.files)
    return run_show(args.id, args.files)


if __name__ == "__main__":
    sys.exit(main())
