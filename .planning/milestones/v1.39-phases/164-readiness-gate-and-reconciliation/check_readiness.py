#!/usr/bin/env python3
"""Check Phase 164 readiness-record structure, not the truth of its evidence."""

from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit


CONDITIONS = (
    "Every baseline dimension above has been assessed; evidence coverage and known limits are visible.",
    "Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.",
    "Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.",
    "Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.",
    "Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.",
    "Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.",
)
TABLE_HEADER = (
    "| # | Approved condition | Status | Evidence date | Assessment date | "
    "Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |"
)
DATE = re.compile(r"\d{4}-\d{2}-\d{2}\Z")
LINK = re.compile(r"\[[^]]+\]\(([^)]+)\)")
CLEANUP_HEADER = "| Surface | Inspection/result | Ownership/debt disposition |"
CLEANUP_SURFACES = (
    "branch/worktree",
    "generated outputs",
    "temporary files",
    "services",
    "verification",
    "unrelated state",
)
CLEAR_FINDING_STATES = {
    "none",
    "none — phase 163 records no findings at these ranks within its bounded method",
}
BLOCK_HTML_TAG = re.compile(
    r"^ {0,3}</?(?:address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|meta|nav|noframes|ol|optgroup|option|p|param|search|section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)(?=\s|/?>|$)",
    re.IGNORECASE,
)


class ContractError(ValueError):
    """A structural invariant in the readiness record is missing or malformed."""


def fail(message: str) -> None:
    raise ContractError(message)


def visible_markdown(text: str) -> str:
    lines: list[str] = []
    fence_char = ""
    fence_length = 0
    for line in text.splitlines():
        fence = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if not fence_char:
            if fence:
                marker = fence.group(1)
                fence_char = marker[0]
                fence_length = len(marker)
                lines.append("")
            else:
                lines.append(line)
            continue

        if fence:
            marker, suffix = fence.groups()
            if marker[0] == fence_char and len(marker) >= fence_length and not suffix.strip():
                fence_char = ""
                fence_length = 0
        lines.append("")
    without_fences = "\n".join(lines)
    without_comments = re.sub(r"<!--.*?(?:-->|\Z)", "", without_fences, flags=re.DOTALL)
    raw_text_tag = re.compile(r"^ {0,3}<(script|pre|style|textarea)(?=\s|/?>|$)", re.IGNORECASE)
    visible_lines: list[str] = []
    in_html_block = False
    html_terminator: tuple[str, str] | None = None
    raw_text_opening_pending = False
    raw_text_opening_quote = ""
    paragraph_open = False
    for line in without_comments.splitlines():
        if not line.strip():
            paragraph_open = False
        if in_html_block:
            visible_lines.append("")
            if html_terminator is not None:
                kind, value = html_terminator
                if kind == "tag":
                    searchable = line
                    if raw_text_opening_pending:
                        end, raw_text_opening_quote = find_unquoted_tag_end(
                            line, raw_text_opening_quote
                        )
                        if end is None:
                            continue
                        raw_text_opening_pending = False
                        searchable = line[end:]
                    if re.search(rf"</{re.escape(value)}\s*>", searchable, re.IGNORECASE):
                        in_html_block = False
                        html_terminator = None
                        paragraph_open = False
                elif kind == "token" and value in line:
                    in_html_block = False
                    html_terminator = None
                    paragraph_open = False
            elif not line.strip():
                in_html_block = False
                paragraph_open = False
            continue
        tag_match = raw_text_tag.match(line)
        if tag_match:
            tag_name = tag_match.group(1)
            in_html_block = True
            html_terminator = ("tag", tag_name)
            end, raw_text_opening_quote = find_unquoted_tag_end(line[tag_match.end() :])
            raw_text_opening_pending = end is None
            if end is not None and re.search(
                rf"</{re.escape(tag_name)}\s*>", line[tag_match.end() + end :], re.IGNORECASE
            ):
                in_html_block = False
                html_terminator = None
            paragraph_open = False
            visible_lines.append("")
            continue
        if line.lstrip().startswith("<?"):
            in_html_block = "?>" not in line
            html_terminator = ("token", "?>") if in_html_block else None
            paragraph_open = False
            visible_lines.append("")
            continue
        if line.lstrip().upper().startswith("<![CDATA["):
            in_html_block = "]]>" not in line
            html_terminator = ("token", "]]>") if in_html_block else None
            paragraph_open = False
            visible_lines.append("")
            continue
        if re.match(r"^ {0,3}<![A-Z]", line):
            in_html_block = ">" not in line
            html_terminator = ("token", ">") if in_html_block else None
            paragraph_open = False
            visible_lines.append("")
            continue
        if BLOCK_HTML_TAG.match(line):
            in_html_block = True
            html_terminator = None
            paragraph_open = False
            visible_lines.append("")
            continue
        if is_complete_html_tag_line(line) and not paragraph_open:
            in_html_block = True
            html_terminator = None
            paragraph_open = False
            visible_lines.append("")
            continue
        visible_lines.append(line)
        if is_markdown_block_start(line):
            paragraph_open = False
        elif line.strip():
            paragraph_open = True
    return "\n".join(visible_lines)


def find_unquoted_tag_end(text: str, quote: str = "") -> tuple[int | None, str]:
    for index, char in enumerate(text):
        if quote:
            if char == quote:
                quote = ""
        elif char in {"'", '"'}:
            quote = char
        elif char == ">":
            return index + 1, ""
    return None, quote


def is_markdown_block_start(line: str) -> bool:
    indentation = len(line) - len(line.lstrip(" "))
    if indentation >= 4:
        return True
    content = line[indentation:]
    return bool(
        re.match(r"#{1,6}(?:\s|$)", content)
        or re.match(r">(?:\s|$)", content)
        or re.match(r"(?:[-+*](?:\s|$)|\d{1,9}[.)](?:\s|$))", content)
        or re.fullmatch(r"(?:\*\s*){3,}|(?:-\s*){3,}|(?:_\s*){3,}", content)
        or re.fullmatch(r"(?:=+|-+)\s*", content)
    )


def is_complete_html_tag_line(line: str) -> bool:
    indentation = len(line) - len(line.lstrip(" "))
    if indentation > 3:
        return False
    content = line[indentation:]
    tag = re.match(r"</?[A-Za-z][A-Za-z0-9-]*", content)
    if tag is None:
        return False
    rest = content[tag.end() :]
    if content.startswith("</"):
        return re.fullmatch(r"\s*>[ \t]*", rest) is not None

    quote = ""
    for index, char in enumerate(rest):
        if quote:
            if char == quote:
                quote = ""
        elif char in {"'", '"'}:
            quote = char
        elif char == "<":
            return False
        elif char == ">":
            return not rest[index + 1 :].strip(" \t")
    return False


def assessment_section(text: str) -> str:
    lines = visible_markdown(text).splitlines()
    starts = [
        index
        for index, line in enumerate(lines)
        if line.startswith("## Phase 164 dated assessment")
    ]
    if not starts:
        fail("Phase 164 dated assessment heading not found")
    if len(starts) != 1:
        fail(f"expected exactly one visible Phase 164 dated assessment heading, found {len(starts)}")
    start = starts[0]
    end = next(
        (index for index in range(start + 1, len(lines)) if lines[index].startswith("## ")),
        len(lines),
    )
    return "\n".join(lines[start:end])


def markdown_cells(line: str) -> list[str]:
    if not line.startswith("|") or not line.endswith("|"):
        return []
    return [cell.strip() for cell in line[1:-1].split("|")]


def local_links_are_safe(section: str, record_path: Path, root: Path) -> None:
    root = root.resolve()
    for target in LINK.findall(section):
        try:
            parsed = urlsplit(target)
            hostname = parsed.hostname
        except ValueError:
            fail(f"malformed evidence link: {target}")
        if parsed.scheme.casefold() == "http":
            fail(f"evidence links must use HTTPS: {target}")
        if parsed.scheme.casefold() == "https":
            if not hostname:
                fail(f"HTTPS evidence link must include a hostname: {target}")
            continue
        if parsed.scheme.casefold() == "mailto" or target.startswith("#"):
            continue
        path_part = target.split("#", 1)[0]
        if not path_part:
            continue
        link = Path(path_part)
        if link.is_absolute():
            fail(f"absolute local evidence link is not allowed: {target}")
        resolved = (record_path.parent / link).resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            fail(f"local evidence link escapes repository root: {target}")
        if not resolved.is_file():
            fail(f"unresolved local evidence link: {target}")


def has_qualifying_evidence_link(evidence: str, record_path: Path, root: Path) -> bool:
    root = root.resolve()
    for target in LINK.findall(evidence):
        try:
            parsed = urlsplit(target)
            hostname = parsed.hostname
        except ValueError:
            continue
        if parsed.scheme.casefold() == "https" and hostname:
            return True
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        path = Path(parsed.path)
        if path.is_absolute():
            continue
        resolved = (record_path.parent / path).resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            continue
        if resolved.is_file():
            return True
    return False


def cleanup_inventory(text: str) -> tuple[str, list[list[str]]]:
    text = visible_markdown(text)
    heading = "## Phase 164 cleanup and verification inventory"
    if heading not in text:
        fail("Phase 164 cleanup and verification inventory heading not found")
    cleanup_start = text.index(heading) + len(heading)
    following_heading = re.search(r"^## ", text[cleanup_start:], re.MULTILINE)
    cleanup = text[cleanup_start : cleanup_start + following_heading.start()] if following_heading else text[cleanup_start:]
    lines = cleanup.splitlines()
    if CLEANUP_HEADER not in lines:
        fail("cleanup inventory surface table header not found")
    header_index = lines.index(CLEANUP_HEADER)
    rows: list[list[str]] = []
    for line in lines[header_index + 1 :]:
        cells = markdown_cells(line)
        if not cells:
            if rows:
                break
            continue
        if all(set(cell) <= {"-", ":", " "} for cell in cells):
            continue
        rows.append(cells)
    if len(rows) != len(CLEANUP_SURFACES):
        fail(f"cleanup inventory must have exactly {len(CLEANUP_SURFACES)} surface rows, found {len(rows)}")
    for expected_surface, row in zip(CLEANUP_SURFACES, rows):
        if len(row) != 3 or row[0].casefold() != expected_surface:
            fail(f"cleanup inventory is missing or duplicating the {expected_surface} surface")
        if not row[1].strip() or row[1].strip() in {"—", "-", "N/A"}:
            fail(f"cleanup inventory must record the {expected_surface} inspection result")
        if not row[2].strip() or row[2].strip() in {"—", "-", "N/A"}:
            fail(f"cleanup inventory must record the {expected_surface} ownership/debt disposition")
    return cleanup, rows


def valid_iso_date(value: str) -> bool:
    if not DATE.fullmatch(value):
        return False
    try:
        return date.fromisoformat(value).isoformat() == value
    except ValueError:
        return False


def decision_and_findings(section: str) -> tuple[str, str]:
    decision_match = re.search(r"^\*\*Decision:\*\*\s*(.*?)\.?\s*$", section, re.MULTILINE)
    if decision_match is None:
        fail("overall Decision field not found")
    decision = decision_match.group(1).strip()
    if decision not in {"READY FOR OPERATOR UI", "NOT READY"}:
        fail(f"unsupported overall decision: {decision}")

    findings_match = re.search(
        r"^\*\*Unresolved (?:Critical, High, or Medium-leverage|gate-rank) findings:\*\*\s*(.*?)\.?\s*$",
        section,
        re.MULTILINE | re.IGNORECASE,
    )
    if findings_match is None:
        fail("unresolved gate-rank findings field not found")
    findings = findings_match.group(1).strip()
    if not findings:
        fail("unresolved gate-rank findings field is empty")
    return decision, findings


def validate(text: str, *, record_path: Path, root: Path) -> None:
    section = assessment_section(text)
    lines = section.splitlines()
    if TABLE_HEADER not in lines:
        fail("six-condition table header not found")

    header_index = lines.index(TABLE_HEADER)
    rows: list[list[str]] = []
    for line in lines[header_index + 1 :]:
        cells = markdown_cells(line)
        if not cells:
            if rows:
                break
            continue
        if all(set(cell) <= {"-", ":", " "} for cell in cells):
            continue
        rows.append(cells)

    if len(rows) != 6:
        fail(f"expected exactly six condition rows, found {len(rows)}")

    statuses: list[str] = []
    cleanup_evidence = ""
    for expected_number, (row, expected_condition) in enumerate(zip(rows, CONDITIONS), start=1):
        if len(row) != 7:
            fail(f"condition {expected_number} must have seven table cells")
        number, condition, status, evidence_date, assessment_date, evidence, limit = row
        if number != str(expected_number) or condition != expected_condition:
            fail(f"condition row {expected_number} is missing, duplicated, reordered, or reworded")
        if status not in {"PASS", "FAIL", "UNKNOWN"}:
            fail(f"condition {expected_number} has unsupported status: {status}")
        statuses.append(status)
        if expected_number == 6:
            cleanup_evidence = evidence
        if not valid_iso_date(evidence_date) or not valid_iso_date(assessment_date):
            fail(f"condition {expected_number} must have ISO evidence and assessment dates")
        if evidence_date == assessment_date:
            fail(f"condition {expected_number} must distinguish evidence date from assessment date")
        if not has_qualifying_evidence_link(evidence, record_path, root):
            fail(f"condition {expected_number} needs a dated linked evidence reference")
        if not limit.strip() or limit.strip() in {"—", "-", "N/A"}:
            fail(f"condition {expected_number} needs an explicit limit or freshness rationale")

    decision, findings = decision_and_findings(section)
    all_pass = all(status == "PASS" for status in statuses)
    no_gate_rank_finding = findings.casefold() in CLEAR_FINDING_STATES
    expected_decision = "READY FOR OPERATOR UI" if all_pass and no_gate_rank_finding else "NOT READY"
    if decision != expected_decision:
        fail(f"decision must be {expected_decision} from the six statuses and gate-rank finding state")

    recommendation = re.search(r"^\*\*ScrypathOps recommendation:\*\*", section, re.MULTILINE)
    if all_pass and no_gate_rank_finding:
        if recommendation is None:
            fail("a passing gate needs a ScrypathOps recommendation")
        recommendation_text = section[recommendation.start() :]
        for phrase in (
            "ScrypathOps",
            "does not authorize or start operator UI work",
            "maintainer availability is a separate constraint",
        ):
            if phrase.casefold() not in recommendation_text.casefold():
                fail(f"passing recommendation must state boundary: {phrase}")
    elif recommendation is not None:
        fail("ScrypathOps recommendation is allowed only after all six conditions pass")

    local_links_are_safe(section, record_path, root)

    cleanup, cleanup_rows = cleanup_inventory(text)
    cleanup_targets = {target.casefold() for target in LINK.findall(cleanup_evidence)}
    if "#phase-164-cleanup-and-verification-inventory" not in cleanup_targets:
        fail("condition 6 evidence must link the Phase 164 cleanup and verification inventory")
    if statuses[5] == "PASS":
        cleanup_text = cleanup.casefold()
        if "no phase-owned debt remains" not in cleanup_text:
            fail("condition 6 cannot pass without an explicit no-owned-debt inventory result")
        if any(marker in cleanup_text for marker in ("pending", "incomplete", "remains to be completed")):
            fail("condition 6 cannot pass while the cleanup or verification inventory is pending")
        allowed_dispositions = {"none", "unrelated; preserved"}
        if any(row[2].casefold() not in allowed_dispositions for row in cleanup_rows):
            fail("condition 6 cannot pass unless every inspected surface has a clear debt disposition")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("record", nargs="?", type=Path, default=Path(__file__).parents[2] / "reference" / "PRE-OPERATOR-UI-READINESS.md")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[3])
    args = parser.parse_args()
    try:
        text = args.record.read_text(encoding="utf-8")
        validate(text, record_path=args.record.resolve(), root=args.root)
    except (OSError, ContractError) as error:
        print(f"STRUCTURAL CONTRACT FAIL: {error}", file=sys.stderr)
        return 1
    print(
        "STRUCTURAL CONTRACT PASS — checks record shape only; it does not certify source truth, "
        "semantic finding judgment, owner approval, or readiness."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
