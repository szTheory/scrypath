#!/usr/bin/env python3
"""Validate Phase 167 evidence structure and immutable historical inputs."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path
from urllib.parse import urlsplit


HISTORICAL_BASELINE_SHA = "b944c049854e65b41352eebc59a13f1774431e3c"
AUTHORITY_PATH = ".planning/reference/PRE-OPERATOR-UI-READINESS.md"
ARCHIVE_DIR = ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation"
REQUIRED_CLAIMS = {
    "API-01",
    "API-02",
    "HOST-01",
    "HOST-02",
    "PKG-04",
    "REPAIR-01",
    "REPAIR-02",
    "DELETE-01",
}
SHA = re.compile(r"^[0-9a-f]{40}$")
CONDITIONS = (
    "Every baseline dimension above has been assessed; evidence coverage and known limits are visible.",
    "Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.",
    "Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.",
    "Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.",
    "Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.",
    "Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.",
)
TABLE_HEADER = "| # | Approved condition | Status | Evidence date | Assessment date | Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |"
CLEANUP_SURFACES = (
    "branch/worktree",
    "generated outputs",
    "temporary files",
    "services",
    "verification",
    "unrelated state",
)
CLEANUP_HEADER = "| Surface | Inspection/result | Ownership/debt disposition |"
UTC_TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


class ContractError(ValueError):
    """A source, receipt, path, or history invariant is missing or malformed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def read_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ContractError(f"cannot read {label}: {error}") from error
    require(isinstance(value, dict), f"{label} must be a JSON object")
    return value


def git_bytes(root: Path, *args: str) -> bytes:
    try:
        result = subprocess.run(
            ["git", "-C", str(root), *args],
            check=False,
            capture_output=True,
        )
    except OSError as error:
        raise ContractError(f"cannot run git to verify history: {error}") from error
    require(result.returncode == 0, f"git {' '.join(args)} failed: {result.stderr.decode(errors='replace').strip()}")
    return result.stdout


def history_suffix(data: bytes, label: str) -> bytes:
    heading = b"## Phase 164 dated assessment"
    first = data.find(heading)
    require(first >= 0, f"Phase 164 dated assessment heading missing in {label}")
    require(data.find(heading, first + len(heading)) < 0, f"duplicate Phase 164 dated assessment heading in {label}")
    return data[first:]


def validate_history(root: Path, *, baseline_sha: str = HISTORICAL_BASELINE_SHA) -> None:
    """Compare the historical authority suffix and every archived byte to Git."""
    require(SHA.fullmatch(baseline_sha) is not None, "historical baseline must be a full commit SHA")
    baseline = git_bytes(root, "cat-file", "-e", f"{baseline_sha}^{{commit}}")
    del baseline
    current_authority = (root / AUTHORITY_PATH).read_bytes()
    baseline_authority = git_bytes(root, "show", f"{baseline_sha}:{AUTHORITY_PATH}")
    require(
        history_suffix(current_authority, AUTHORITY_PATH)
        == history_suffix(baseline_authority, f"{baseline_sha}:{AUTHORITY_PATH}"),
        "Phase 164 assessment bytes differ from the pinned historical baseline",
    )

    archive = root / ARCHIVE_DIR
    require(archive.is_dir(), f"archived Phase 164 directory missing: {ARCHIVE_DIR}")
    tracked = git_bytes(root, "ls-tree", "-r", "--name-only", baseline_sha, "--", ARCHIVE_DIR)
    baseline_paths = sorted(line.decode("utf-8") for line in tracked.splitlines() if line)
    require(bool(baseline_paths), "pinned baseline contains no files for the archived Phase 164 directory")
    current_paths = sorted(
        item.relative_to(root).as_posix()
        for item in archive.rglob("*")
        if item.is_file() or item.is_symlink()
    )
    require(current_paths == baseline_paths, "archived Phase 164 file set differs from the pinned baseline")
    for relative in baseline_paths:
        expected = git_bytes(root, "show", f"{baseline_sha}:{relative}")
        target = root / relative
        try:
            actual = target.read_bytes()
        except OSError as error:
            raise ContractError(f"archived Phase 164 file is missing: {relative}") from error
        require(actual == expected, f"archived Phase 164 bytes differ from the pinned baseline: {relative}")


def parse_utc(value: object, label: str) -> datetime:
    require(isinstance(value, str) and value.endswith("Z"), f"{label} must be an explicit UTC timestamp ending in Z")
    try:
        parsed = datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError as error:
        raise ContractError(f"{label} is not an ISO-8601 timestamp") from error
    return parsed


def visible_markdown(text: str) -> str:
    """Remove comments and fenced examples before structural row inspection."""
    text = re.sub(r"<!--.*?(?:-->|\Z)", "", text, flags=re.DOTALL)
    visible: list[str] = []
    fence_char = ""
    fence_size = 0
    for line in text.splitlines():
        fence = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if not fence_char:
            if fence:
                marker = fence.group(1)
                fence_char, fence_size = marker[0], len(marker)
                visible.append("")
            else:
                visible.append(line)
            continue
        if fence:
            marker = fence.group(1)
            if marker[0] == fence_char and len(marker) >= fence_size and not line[len(marker):].strip():
                fence_char, fence_size = "", 0
        visible.append("")
    return "\n".join(visible)


def utc_datetime(value: object, label: str) -> datetime:
    require(isinstance(value, str) and UTC_TIMESTAMP.fullmatch(value) is not None, f"{label} must be a second-precision UTC timestamp ending in Z")
    try:
        return datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError as error:
        raise ContractError(f"{label} is not a valid UTC timestamp") from error


def markdown_links(root: Path, base_dir: Path, text: str, label: str) -> list[str]:
    references = re.findall(r"\[[^]]+\]\(([^)]+)\)", text)
    require(bool(references), f"{label} must contain linked evidence")
    for reference in references:
        path_part = reference.split("#", 1)[0]
        target = Path(path_part)
        require(path_part and not target.is_absolute(), f"{label} contains a non-local or empty evidence path")
        resolved = (base_dir / target).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError as error:
            raise ContractError(f"{label} evidence link escapes the repository root") from error
        require(resolved.is_file(), f"{label} evidence link does not resolve: {path_part}")
    return references


def section_until(text: str, heading: str, next_heading: str) -> str:
    visible = visible_markdown(text)
    start = visible.find(heading)
    require(start >= 0 and visible.find(heading, start + len(heading)) < 0, f"expected exactly one {heading} section")
    end = visible.find(next_heading, start + len(heading))
    require(end >= 0, f"{next_heading} section is missing after {heading}")
    return visible[start:end]


def validate_assessment(root: Path, assessment_path: Path, evidence: dict) -> None:
    text = assessment_path.read_text(encoding="utf-8")
    source_sha = evidence.get("assessment_source_sha")
    require(isinstance(source_sha, str) and SHA.fullmatch(source_sha), "evidence assessment_source_sha must be a full SHA")
    section = section_until(text, "# Phase 167 dated assessment", "## Findings and decision")
    assessed_at = re.search(r"^assessed_at_utc:\s*(\S+)\s*$", section, re.MULTILINE)
    assessment_id = re.search(r"^assessment_id:\s*(\S+)\s*$", section, re.MULTILINE)
    source = re.search(r"^assessment_source_sha:\s*(\S+)\s*$", section, re.MULTILINE)
    require(assessed_at is not None, "assessment assessed_at_utc is required")
    cutoff = utc_datetime(assessed_at.group(1), "assessment assessed_at_utc")
    require(assessment_id is not None and assessment_id.group(1) == "Phase167-" + cutoff.strftime("%Y%m%dT%H%M%SZ"), "assessment_id must uniquely encode the UTC assessment timestamp")
    require(source is not None and source.group(1) == source_sha, "assessment source SHA must match the evidence index source")
    git_bytes(root, "cat-file", "-e", f"{source_sha}^{{commit}}")
    observations = [utc_datetime(claim.get("observed_at_utc"), f"{claim.get('id', 'claim')}.observed_at_utc") for claim in evidence.get("claims", []) if isinstance(claim, dict)]
    require(bool(observations) and all(value <= cutoff for value in observations), "an evidence observation occurs after the dated assessment cutoff")
    lines = section.splitlines()
    require(lines.count(TABLE_HEADER) == 1, "assessment must contain exactly one canonical six-condition table")
    rows = [line for line in lines if re.match(r"^\|\s*\d+\s*\|", line)]
    require(len(rows) == 6, "assessment must have exactly six visible condition rows")
    statuses: list[str] = []
    for number, (row, condition) in enumerate(zip(rows, CONDITIONS), start=1):
        cells = [cell.strip() for cell in row.strip().strip("|").split("|")]
        require(len(cells) == 7 and cells[0] == str(number), "condition rows must be complete, ordered, and unique")
        require(cells[1] == condition, f"condition {number} wording differs from the approved authority")
        require(cells[2] in {"PASS", "FAIL", "UNKNOWN"}, f"condition {number} status must be PASS, FAIL, or UNKNOWN")
        require(re.fullmatch(r"\d{4}-\d{2}-\d{2}", cells[3]) is not None, f"condition {number} evidence date must be explicit")
        try:
            date.fromisoformat(cells[3])
        except ValueError as error:
            raise ContractError(f"condition {number} evidence date is invalid") from error
        require(cells[4] == cutoff.date().isoformat(), f"condition {number} assessment date must match the UTC timestamp")
        markdown_links(root, assessment_path.parent, cells[5], f"condition {number}")
        require(cells[6].strip(), f"condition {number} must state its evidence boundary or limitation")
        statuses.append(cells[2])
    decision_section = section_until(text, "## Findings and decision", "## Probe ledgers")
    finding = re.search(r"^\*\*Gate-rank findings:\*\*\s*(.+?)\s*$", decision_section, re.MULTILINE)
    decision = re.search(r"^\*\*Decision:\*\*\s*(READY FOR OPERATOR UI|NOT READY)\.?\s*$", decision_section, re.MULTILINE)
    require(finding is not None and finding.group(1).strip(), "explicit gate-rank finding disposition is required")
    require(decision is not None, "an explicit readiness decision is required")
    clear = finding.group(1).strip().casefold() in {"none within the reviewed scope", "none — none within the reviewed scope", "none — no unresolved critical, high, or medium-leverage findings"}
    ready = all(status == "PASS" for status in statuses) and clear
    expected = "READY FOR OPERATOR UI" if ready else "NOT READY"
    require(decision.group(1) == expected, f"decision must be {expected} from condition statuses and gate-rank disposition")
    require("structural" in section.casefold() and "does not establish source truth" in section.casefold(), "assessment must state the structural checker limitation")


def validate_closeout(root: Path, closeout_path: Path, evidence: dict) -> None:
    text = visible_markdown(closeout_path.read_text(encoding="utf-8"))
    observed = re.search(r"^observed_at_utc:\s*(\S+)\s*$", text, re.MULTILINE)
    source = re.search(r"^inspected_source_sha:\s*(\S+)\s*$", text, re.MULTILINE)
    require(observed is not None, "closeout observed_at_utc is required")
    utc_datetime(observed.group(1), "closeout observed_at_utc")
    require(source is not None and source.group(1) == evidence.get("assessment_source_sha"), "closeout source SHA must match the evidence assessment source")
    require(text.count(CLEANUP_HEADER) == 1, "closeout must contain one six-surface ownership inventory")
    rows = [line for line in text.splitlines() if line.startswith("| ") and line.count("|") >= 4 and not line.startswith("| Surface ") and not line.startswith("|---")]
    require(len(rows) == len(CLEANUP_SURFACES), "closeout must contain exactly six inventory rows")
    observed_surfaces: list[str] = []
    for row in rows:
        cells = [cell.strip() for cell in row.strip().strip("|").split("|")]
        require(len(cells) == 3 and all(cells[1:]), "every closeout surface needs an inspection and ownership disposition")
        observed_surfaces.append(cells[0])
    require(tuple(observed_surfaces) == CLEANUP_SURFACES, "closeout surfaces must be present exactly once in canonical order")
    verification = next(row for row in rows if row.startswith("| verification |"))
    require(any(word in verification.casefold() for word in ("open", "pending", "outstanding")), "pending final verification must remain explicit at this cutoff")


def resolve_receipt(root: Path, reference: object) -> tuple[Path, str]:
    require(isinstance(reference, str) and reference.strip(), "canonical_receipt must be a non-empty repository-relative path and fragment")
    path_part, separator, fragment = reference.partition("#")
    require(separator == "#" and bool(fragment), "canonical_receipt must name an execution fragment")
    path = Path(path_part)
    require(not path.is_absolute(), "canonical_receipt must use a relative path")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as error:
        raise ContractError("canonical_receipt escapes the repository root") from error
    require(resolved.is_file(), f"canonical receipt does not resolve to a file: {path_part}")
    return resolved, fragment


def validate_local_claim(root: Path, claim: dict, receipt_path: Path, fragment: str) -> None:
    require(receipt_path.suffix.casefold() == ".md", f"{claim['id']} local-test receipt must be Markdown")
    receipt_text = receipt_path.read_text(encoding="utf-8")
    require(claim["source_sha"] in receipt_text, f"{claim['id']} source SHA is absent from its canonical receipt")
    require(claim["oracle"] in receipt_text, f"{claim['id']} oracle is absent from its canonical receipt")
    headings = {
        re.sub(r"[^a-z0-9 -]", "", match.group(1).strip().casefold()).replace(" ", "-")
        for match in re.finditer(r"^#{1,6}\s+(.+?)\s*#*\s*$", receipt_text, re.MULTILINE)
    }
    require(fragment in headings, f"{claim['id']} canonical Markdown anchor is missing: #{fragment}")
    require(claim["result"] == "pass" and claim["skipped"] is False, f"{claim['id']} local test evidence must be a non-skipped pass")


def validate_markdown_reference(root: Path, reference: object, label: str) -> None:
    require(isinstance(reference, str) and reference.strip(), f"{label} must be a local Markdown reference")
    path_part, separator, fragment = reference.partition("#")
    path = Path(path_part)
    require(not path.is_absolute(), f"{label} must be repository-relative")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as error:
        raise ContractError(f"{label} escapes the repository root") from error
    require(resolved.is_file() and resolved.suffix.casefold() == ".md", f"{label} must resolve to a Markdown file")
    if separator:
        text = resolved.read_text(encoding="utf-8")
        headings = {
            re.sub(r"[^a-z0-9 -]", "", match.group(1).strip().casefold()).replace(" ", "-")
            for match in re.finditer(r"^#{1,6}\s+(.+?)\s*#*\s*$", text, re.MULTILINE)
        }
        require(fragment in headings, f"{label} anchor does not exist: #{fragment}")


def validate_hosted_claim(root: Path, claim: dict, receipt_path: Path, fragment: str) -> None:
    canonical = read_json(receipt_path, f"canonical receipt for {claim['id']}")
    if fragment == "delete_receipt":
        delete = canonical.get("delete_receipt")
        require(isinstance(delete, dict), f"{claim['id']} canonical delete receipt is missing")
        historic = delete.get("historical_receipt")
        require(isinstance(historic, dict), f"{claim['id']} historical receipt identity is missing")
        expected = {
            "source_sha": delete.get("receipt_source_sha"),
            "scenario": historic.get("scenario"),
            "run_id": historic.get("run_id"),
            "job_id": historic.get("job_id"),
            "result": "pass" if historic.get("result") == "passed" else historic.get("result"),
            "skipped": False,
        }
        for field, actual in expected.items():
            require(claim.get(field) == actual, f"{claim['id']}.{field} does not match the historical hosted receipt")
        require(claim.get("run_attempt") == 1, f"{claim['id']} historical run attempt must be recorded as 1")
        require(claim.get("oracle") == historic.get("scenario"), f"{claim['id']} oracle does not identify the historical scenario")
        validate_https(claim.get("log_reference"), f"{claim['id']}.log_reference")
        return

    executions = canonical.get("executions")
    require(isinstance(executions, list), f"canonical receipt for {claim['id']} has no executions array")
    execution = next((item for item in executions if isinstance(item, dict) and item.get("id") == fragment), None)
    require(execution is not None, f"canonical receipt execution not found: {fragment}")
    for field, actual in (
        ("scenario", execution.get("scenario")),
        ("source_sha", execution.get("source_sha")),
        ("run_id", execution.get("run_id")),
        ("run_attempt", execution.get("run_attempt")),
        ("job_id", execution.get("job_id")),
        ("result", execution.get("result")),
        ("skipped", execution.get("skipped")),
    ):
        require(claim.get(field) == actual, f"{claim['id']}.{field} does not match canonical execution {fragment}")
    require(execution.get("job_conclusion") == "success", f"{claim['id']} canonical job did not conclude success")
    log_id = execution.get("log_excerpt_id")
    log_excerpt = canonical.get("log_excerpts", {}).get(log_id) if isinstance(log_id, str) else None
    require(isinstance(log_excerpt, dict) and isinstance(log_excerpt.get("lines"), list), f"{claim['id']} canonical hosted log excerpt is missing")
    require(any(claim.get("oracle") in line for line in log_excerpt["lines"]), f"{claim['id']} oracle marker is absent from canonical log excerpt")
    validate_https(claim.get("log_reference"), f"{claim['id']}.log_reference")


def compare_delete_freshness(root: Path, delete: dict, compare_source: str | None) -> None:
    target_sha = compare_source or delete.get("assessment_source_sha")
    require(isinstance(target_sha, str) and SHA.fullmatch(target_sha), "comparison source must be a full commit SHA")
    git_bytes(root, "cat-file", "-e", f"{target_sha}^{{commit}}")
    receipt_sha = delete.get("receipt_source_sha")
    require(isinstance(receipt_sha, str) and SHA.fullmatch(receipt_sha), "delete receipt source must be a full commit SHA")
    paths = delete.get("relevant_paths")
    require(paths == ["lib", "examples", "config", "test/support", ".github/workflows", "mix.exs", "mix.lock"], "C-09 relevant path roots differ from the approved set")
    changed = git_bytes(
        root,
        "diff",
        "--name-only",
        "--diff-filter=ACDMRTUXB",
        receipt_sha,
        target_sha,
        "--",
        *paths,
    )
    observed_paths = sorted(line.decode("utf-8") for line in changed.splitlines() if line)
    recorded_paths = delete.get("changed_paths")
    require(isinstance(recorded_paths, list) and all(isinstance(path, str) for path in recorded_paths), "C-09 changed_paths must be an explicit string array")
    disposition_reference = delete.get("canonical_receipt")
    receipt_path, fragment = resolve_receipt(root, disposition_reference)
    require(fragment == "delete_receipt", "C-09 semantic dispositions must reference the canonical delete receipt")
    canonical_delete = read_json(receipt_path, "canonical C-09 receipt").get("delete_receipt")
    require(isinstance(canonical_delete, dict), "canonical C-09 receipt is missing")
    dispositions = delete.get("changes", canonical_delete.get("changes"))
    require(isinstance(dispositions, list), "C-09 changes must record a semantic disposition for every relevant path")
    by_path: dict[str, dict] = {}
    for row in dispositions:
        require(isinstance(row, dict) and isinstance(row.get("path"), str), "C-09 path disposition has a missing path")
        require(row["path"] not in by_path, f"duplicate C-09 path disposition: {row['path']}")
        require(isinstance(row.get("invalidates"), bool), f"C-09 invalidates flag must be boolean for {row['path']}")
        require(isinstance(row.get("reason"), str) and row["reason"].strip(), f"C-09 semantic reason is required for {row['path']}")
        by_path[row["path"]] = row
    require(sorted(recorded_paths) == observed_paths, "C-09 changed_paths do not match the Git comparison")
    require(set(by_path) == set(observed_paths), "C-09 path dispositions do not cover the exact Git comparison")
    for path in observed_paths:
        reason = by_path[path]["reason"].casefold()
        require(not any(token in reason for token in ("todo", "unknown", "tbd", "not reviewed")), f"C-09 semantic disposition is unresolved for {path}")
    invalidates = any(row["invalidates"] for row in by_path.values())
    status = delete.get("status")
    require(status in {"reusable", "fresh", "unknown"}, "C-09 status must be reusable, fresh, or unknown")
    if invalidates:
        require(status != "reusable", "C-09 cannot be reused while a relevant path invalidates the bounded claim")
    freshness = delete.get("freshness")
    require(isinstance(freshness, dict), "C-09 freshness must state the comparison identity and outcome")
    if compare_source is None:
        require(freshness.get("compared_source_sha") == target_sha, "C-09 freshness does not name the checked assessment source")
    require(freshness.get("result") in {"reusable", "fresh-proof-required", "unknown"}, "C-09 freshness result is invalid")
    require(isinstance(freshness.get("reason"), str) and freshness["reason"].strip(), "C-09 freshness reason is required")
    if invalidates:
        require(freshness.get("result") != "reusable", "C-09 invalidator cannot be labeled reusable")


def validate_release_identities(root: Path, identities: object) -> None:
    require(isinstance(identities, list), "release_identities must be an array")
    expected = {
        "planning-tag": "dc400b2b57aec0ca6b0ef16c9477d266fd41a433",
        "closeout-run": "dc400b2b57aec0ca6b0ef16c9477d266fd41a433",
        "public-release": "28d3877a05479f2cc104754fc24ab0c9d545c01b",
        "local-artifact": "50d5c12d36ec560525e245bcb992c40e5927854f",
    }
    by_kind = {item.get("kind"): item for item in identities if isinstance(item, dict)}
    require(
        len(by_kind) == len(identities) and set(by_kind) == set(expected),
        "planning tag, closeout, public release, and local artifact identities must remain separate and unique",
    )
    for kind, sha in expected.items():
        item = by_kind[kind]
        require(item.get("source_sha") == sha, f"{kind} source SHA does not match its canonical identity")
        for field in ("reference", "canonical_receipt", "observed_at_utc", "result", "limits"):
            require(isinstance(item.get(field), str) and item[field].strip(), f"{kind}.{field} must be explicit")
        parse_utc(item["observed_at_utc"], f"{kind}.observed_at_utc")
        receipt_path, fragment = resolve_receipt(root, item["canonical_receipt"])
        if receipt_path.suffix.lower() == ".json":
            receipt = read_json(receipt_path, f"{kind} canonical receipt")
            if fragment:
                receipt = receipt.get(fragment)
            require(isinstance(receipt, dict), f"{kind} canonical receipt fragment must be an object")
            require(receipt.get("source_sha") == sha, f"{kind} canonical receipt source SHA does not match")
        else:
            validate_markdown_reference(root, item["canonical_receipt"], f"{kind}.canonical_receipt")
            receipt_text = receipt_path.read_text(encoding="utf-8")
            require(sha in receipt_text, f"{kind} canonical receipt does not name its source SHA")
            require(item["reference"] in receipt_text, f"{kind} canonical receipt does not name its reference")
    require(by_kind["planning-tag"].get("reference") == "v1.39", "planning tag reference must remain v1.39")
    require(by_kind["public-release"].get("reference") == "scrypath-v0.3.13", "public package release tag must remain scrypath-v0.3.13")


def validate_https(value: object, label: str) -> None:
    require(isinstance(value, str), f"{label} must be a URL")
    try:
        parsed = urlsplit(value)
        host = parsed.hostname
    except ValueError as error:
        raise ContractError(f"{label} is malformed") from error
    require(parsed.scheme == "https" and bool(host), f"{label} must be an HTTPS URL with a hostname")


def validate_evidence(root: Path, record_path: Path, *, require_all_claims: bool = False, compare_source: str | None = None) -> dict:
    record = read_json(record_path, "evidence record")
    require(record.get("schema") == 1, "evidence schema must be 1")
    assessment_sha = record.get("assessment_source_sha")
    require(isinstance(assessment_sha, str) and SHA.fullmatch(assessment_sha), "assessment_source_sha must be a full commit SHA")
    git_bytes(root, "cat-file", "-e", f"{assessment_sha}^{{commit}}")
    require(record.get("historical_baseline_sha") == HISTORICAL_BASELINE_SHA, "historical_baseline_sha must match the independently pinned checker baseline")
    parse_utc(record.get("observed_at_utc"), "observed_at_utc")

    claims = record.get("claims")
    require(isinstance(claims, list) and claims, "claims must be a non-empty array")
    identifiers: set[str] = set()
    covered: set[str] = set()
    for index, claim in enumerate(claims):
        label = f"claims[{index}]"
        require(isinstance(claim, dict), f"{label} must be an object")
        claim_id = claim.get("id")
        require(isinstance(claim_id, str) and claim_id.strip(), f"{label}.id must be a non-empty string")
        require(claim_id not in identifiers, f"duplicate claim id: {claim_id}")
        identifiers.add(claim_id)
        requirements = claim.get("requirement_ids")
        require(isinstance(requirements, list) and requirements, f"{claim_id}.requirement_ids must be a non-empty array")
        require(all(isinstance(item, str) and item.strip() for item in requirements), f"{claim_id}.requirement_ids contains a missing or null identity")
        require(len(set(requirements)) == len(requirements), f"{claim_id}.requirement_ids contains a duplicate identity")
        covered.update(requirements)
        for field in ("scenario", "oracle", "dependency_mode", "bounded_claim", "limits"):
            require(isinstance(claim.get(field), str) and claim[field].strip(), f"{claim_id}.{field} must be a non-empty string")
        parse_utc(claim.get("observed_at_utc"), f"{claim_id}.observed_at_utc")
        claim_freshness = claim.get("freshness")
        require(isinstance(claim_freshness, dict), f"{claim_id}.freshness must state its source freshness")
        require(claim_freshness.get("status") in {"exact-source", "reusable", "unknown"}, f"{claim_id}.freshness.status is invalid")
        require(isinstance(claim_freshness.get("reason"), str) and claim_freshness["reason"].strip(), f"{claim_id}.freshness.reason is required")
        require(claim.get("result") in {"pass", "fail", "unknown"}, f"{claim_id}.result must be pass, fail, or unknown")
        require(isinstance(claim.get("skipped"), bool), f"{claim_id}.skipped must be a boolean")
        source_sha = claim.get("source_sha")
        require(isinstance(source_sha, str) and SHA.fullmatch(source_sha), f"{claim_id}.source_sha must be a full commit SHA")
        try:
            git_bytes(root, "cat-file", "-e", f"{source_sha}^{{commit}}")
        except ContractError as error:
            raise ContractError(f"{claim_id}.source_sha cannot be resolved: {error}") from error
        receipt_path, fragment = resolve_receipt(root, claim.get("canonical_receipt"))
        evidence_kind = claim.get("evidence_kind", "hosted")
        if evidence_kind == "local-test":
            validate_local_claim(root, claim, receipt_path, fragment)
        elif evidence_kind in {"hosted", "historical-hosted"}:
            if evidence_kind == "hosted" or fragment != "delete_receipt":
                for field in ("run_id", "run_attempt", "job_id"):
                    require(isinstance(claim.get(field), int) and claim[field] > 0, f"{claim_id}.{field} must be a positive integer")
            validate_hosted_claim(root, claim, receipt_path, fragment)
        else:
            raise ContractError(f"{claim_id}.evidence_kind is unsupported")
        source_check = claim.get("source_verification")
        require(isinstance(source_check, dict), f"{claim_id}.source_verification must record the inspection method")
        for field in ("method", "observed_result", "limitations"):
            require(isinstance(source_check.get(field), str) and source_check[field].strip(), f"{claim_id}.source_verification.{field} must be non-empty")

    if require_all_claims:
        missing = REQUIRED_CLAIMS - covered
        require(not missing, f"required milestone software claims are missing: {', '.join(sorted(missing))}")

    validate_release_identities(root, record.get("release_identities"))
    delete = record.get("delete_receipt")
    require(isinstance(delete, dict), "delete_receipt must include the C-09 source comparison")
    compare_delete_freshness(root, delete, compare_source)
    constraints = record.get("inherited_constraints")
    require(isinstance(constraints, dict), "inherited_constraints must be an object")
    require(constraints.get("source") == ".planning/phases/166-host-tenant-and-repair-evidence/166-SOURCE-AUDIT.md", "inherited constraint source must remain canonical")
    validate_markdown_reference(root, constraints["source"], "inherited_constraints.source")
    expected_edges = {f"EA-166-{index:02d}" for index in range(1, 12)}
    expected_prohibitions = {"P-166-HOST-01", "P-166-HOST-02", "P-166-PKG-04", "P-166-REPAIR-01", "P-166-REPAIR-02", "P-166-DELETE-01"}
    for field, expected in (("edge_probe_ids", expected_edges), ("prohibition_ids", expected_prohibitions)):
        rows = constraints.get(field)
        require(isinstance(rows, list), f"inherited_constraints.{field} must be an array")
        observed = {row.get("id") for row in rows if isinstance(row, dict)}
        require(observed == expected, f"inherited_constraints.{field} must preserve every canonical ID")
        require(all(row.get("status") == "unresolved" for row in rows if isinstance(row, dict)), f"inherited_constraints.{field} must remain unresolved")
        require(all(row.get("descriptor") is None for row in rows if isinstance(row, dict)), f"inherited_constraints.{field} must retain descriptor-less status")
    debt = record.get("accepted_metadata_debt")
    require(isinstance(debt, list) and len(debt) == 3, "accepted Phase 163/164 planning metadata debt must remain explicit")
    mismatch = record.get("release_reference_mismatch")
    require(isinstance(mismatch, dict), "release_reference_mismatch disposition is required")
    for field in ("affected_files", "impact", "disposition", "revisit_trigger"):
        require(field in mismatch and mismatch[field], f"release_reference_mismatch.{field} is required")
    require(set(mismatch["affected_files"]) == {"mix.exs", "docs/releasing.md"}, "release-reference mismatch must identify the exact source/docs files")
    for row in debt:
        require(isinstance(row, dict), "accepted metadata debt rows must be objects")
        for field in ("source", "status", "disposition", "revisit_trigger"):
            require(isinstance(row.get(field), str) and row[field].strip(), f"accepted metadata debt {field} must be explicit")
        validate_markdown_reference(root, row["source"], "accepted_metadata_debt.source")
    return record


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--scope", choices=("evidence", "complete"), required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--assessment", type=Path)
    parser.add_argument("--closeout", type=Path)
    parser.add_argument("--require-all-claims", action="store_true")
    parser.add_argument("--compare-source")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    evidence_path = args.evidence if args.evidence.is_absolute() else root / args.evidence
    try:
        resolved_evidence = evidence_path.resolve()
        try:
            resolved_evidence.relative_to(root)
        except ValueError as error:
            raise ContractError("evidence record escapes the repository root") from error
        validate_history(root)
        evidence = validate_evidence(
            root,
            resolved_evidence,
            require_all_claims=args.require_all_claims or args.scope == "complete",
            compare_source=args.compare_source,
        )
        if args.scope == "complete":
            require(args.assessment is not None and args.closeout is not None, "complete scope requires --assessment and --closeout")
            assessment_path = args.assessment if args.assessment.is_absolute() else root / args.assessment
            closeout_path = args.closeout if args.closeout.is_absolute() else root / args.closeout
            for path, label in ((assessment_path, "assessment"), (closeout_path, "closeout")):
                try:
                    path.resolve().relative_to(root)
                except ValueError as error:
                    raise ContractError(f"{label} record escapes the repository root") from error
            validate_assessment(root, assessment_path.resolve(), evidence)
            validate_closeout(root, closeout_path.resolve(), evidence)
    except (OSError, ContractError) as error:
        print(f"STRUCTURAL CONTRACT FAIL: {error}", file=sys.stderr)
        return 1
    print(
        "STRUCTURAL CONTRACT PASS — structural validation does not establish source truth, "
        "semantic completeness, owner approval, or readiness."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
