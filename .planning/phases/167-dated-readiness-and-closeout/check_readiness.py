#!/usr/bin/env python3
"""Validate Phase 167 evidence structure and immutable historical inputs."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime
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


def validate_https(value: object, label: str) -> None:
    require(isinstance(value, str), f"{label} must be a URL")
    try:
        parsed = urlsplit(value)
        host = parsed.hostname
    except ValueError as error:
        raise ContractError(f"{label} is malformed") from error
    require(parsed.scheme == "https" and bool(host), f"{label} must be an HTTPS URL with a hostname")


def validate_evidence(root: Path, record_path: Path, *, require_all_claims: bool = False) -> dict:
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
        require(claim.get("result") in {"pass", "fail", "unknown"}, f"{claim_id}.result must be pass, fail, or unknown")
        require(isinstance(claim.get("skipped"), bool), f"{claim_id}.skipped must be a boolean")
        source_sha = claim.get("source_sha")
        require(isinstance(source_sha, str) and SHA.fullmatch(source_sha), f"{claim_id}.source_sha must be a full commit SHA")
        require(isinstance(claim.get("run_id"), int) and claim["run_id"] > 0, f"{claim_id}.run_id must be a positive integer")
        require(isinstance(claim.get("run_attempt"), int) and claim["run_attempt"] > 0, f"{claim_id}.run_attempt must be a positive integer")
        require(isinstance(claim.get("job_id"), int) and claim["job_id"] > 0, f"{claim_id}.job_id must be a positive integer")
        receipt_path, fragment = resolve_receipt(root, claim.get("canonical_receipt"))
        canonical = read_json(receipt_path, f"canonical receipt for {claim_id}")
        executions = canonical.get("executions")
        require(isinstance(executions, list), f"canonical receipt for {claim_id} has no executions array")
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
            require(claim.get(field) == actual, f"{claim_id}.{field} does not match canonical execution {fragment}")
        require(execution.get("job_conclusion") == "success", f"{claim_id} canonical job did not conclude success")
        log_id = execution.get("log_excerpt_id")
        log_excerpt = canonical.get("log_excerpts", {}).get(log_id) if isinstance(log_id, str) else None
        require(isinstance(log_excerpt, dict) and isinstance(log_excerpt.get("lines"), list), f"{claim_id} canonical hosted log excerpt is missing")
        require(any(claim.get("oracle") in line for line in log_excerpt["lines"]), f"{claim_id} oracle marker is absent from canonical log excerpt")
        validate_https(claim.get("log_reference"), f"{claim_id}.log_reference")
        source_check = claim.get("source_verification")
        require(isinstance(source_check, dict), f"{claim_id}.source_verification must record the inspection method")
        for field in ("method", "observed_result", "limitations"):
            require(isinstance(source_check.get(field), str) and source_check[field].strip(), f"{claim_id}.source_verification.{field} must be non-empty")

    if require_all_claims:
        missing = REQUIRED_CLAIMS - covered
        require(not missing, f"required milestone software claims are missing: {', '.join(sorted(missing))}")

    identities = record.get("release_identities")
    require(isinstance(identities, list), "release_identities must be an array")
    constraints = record.get("inherited_constraints")
    require(isinstance(constraints, dict), "inherited_constraints must be an object")
    for field in ("source", "edge_probe_ids", "prohibition_ids"):
        require(field in constraints, f"inherited_constraints.{field} is required")
    return record


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--scope", choices=("evidence",), required=True)
    parser.add_argument("--evidence", type=Path, required=True)
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
        validate_evidence(root, resolved_evidence, require_all_claims=args.require_all_claims)
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
