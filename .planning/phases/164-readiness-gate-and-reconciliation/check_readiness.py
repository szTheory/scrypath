#!/usr/bin/env python3
"""Check Phase 164 readiness-record structure, not the truth of its evidence."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


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


class ContractError(ValueError):
    """A structural invariant in the readiness record is missing or malformed."""


def fail(message: str) -> None:
    raise ContractError(message)


def assessment_section(text: str) -> str:
    lines = text.splitlines()
    start = next(
        (index for index, line in enumerate(lines) if line.startswith("## Phase 164 dated assessment")),
        None,
    )
    if start is None:
        fail("Phase 164 dated assessment heading not found")
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
        if target.startswith(("https://", "http://", "mailto:", "#")):
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
        if not DATE.fullmatch(evidence_date) or not DATE.fullmatch(assessment_date):
            fail(f"condition {expected_number} must have ISO evidence and assessment dates")
        if evidence_date == assessment_date:
            fail(f"condition {expected_number} must distinguish evidence date from assessment date")
        if not LINK.search(evidence):
            fail(f"condition {expected_number} needs a dated linked evidence reference")
        if not limit.strip() or limit.strip() in {"—", "-", "N/A"}:
            fail(f"condition {expected_number} needs an explicit limit or freshness rationale")

    decision, findings = decision_and_findings(section)
    all_pass = all(status == "PASS" for status in statuses)
    no_gate_rank_finding = findings.casefold().startswith(("none", "no unresolved"))
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

    cleanup_heading = "## Phase 164 cleanup and verification inventory"
    if cleanup_heading not in text:
        fail("Phase 164 cleanup and verification inventory heading not found")
    cleanup_start = text.index(cleanup_heading) + len(cleanup_heading)
    following_heading = re.search(r"^## ", text[cleanup_start:], re.MULTILINE)
    cleanup = text[cleanup_start : cleanup_start + following_heading.start()] if following_heading else text[cleanup_start:]
    for surface in ("branch", "generated", "temporary", "services", "verification", "unrelated"):
        if surface not in cleanup.casefold():
            fail(f"cleanup inventory does not record the {surface} surface")
    if "#phase-164-cleanup-and-verification-inventory" not in cleanup_evidence:
        fail("condition 6 evidence must link the Phase 164 cleanup and verification inventory")
    if statuses[5] == "PASS":
        cleanup_text = cleanup.casefold()
        if "no phase-owned debt remains" not in cleanup_text:
            fail("condition 6 cannot pass without an explicit no-owned-debt inventory result")
        if any(marker in cleanup_text for marker in ("pending", "incomplete", "remains to be completed")):
            fail("condition 6 cannot pass while the cleanup or verification inventory is pending")


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
