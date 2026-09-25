"""Structural validation of Phase 163 findings data; not product proof."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


class ContractError(ValueError):
    pass


HEADERS = ["Claim", "Job", "Classification", "Evidence and limits", "Decision relevance", "Finding", "Qualification"]
CLASSES = {"no-new-observation", "evidence-gap", "observation", "product-opportunity", "material-defect", "material-risk"}
MATERIAL = {"material-defect", "material-risk"}
RANKS = {"Critical", "High", "Medium-leverage", "Low"}
F_FIELDS = {"Claims", "Job", "Scrypath boundary", "Evidence", "Impact", "Frequency/exposure", "Confidence", "Compatibility risk", "Security risk", "Privacy risk", "Data-integrity risk", "Operational risk", "Implementation cost", "Regression cost", "Recurring verification cost", "Rank", "Rank rationale", "Disposition", "Disposition basis", "Risk state", "Owner", "Decision evidence", "Revisit trigger", "Route"}
P_FIELDS = {"User outcome", "Boundary", "Exclusions", "Fixture", "Oracle", "Layer", "Command", "Environment/versions", "Receipt", "Invalidation trigger", "Timeout", "Diagnostics", "Isolation", "Cleanup", "CI posture", "CI economics"}
K_FIELDS = {"Name", "Findings", "Outcome", "Evidence", "Owner boundary", "Scope authority", "Exclusions", "Route", "Route rationale", "Work units", "Value/cost rationale", "Acceptance claims"}


def _fail(identifier: str, field: str, reason: str) -> None:
    raise ContractError(f"{identifier} — {field}: {reason}")


def _table_rows(lines: list[str], source: Path) -> list[list[str]]:
    ix = next((i for i, line in enumerate(lines) if line.startswith("| Claim |")), None)
    if ix is None:
        _fail("FINDINGS", "Claim triage", "table not found")
    header = [x.strip() for x in lines[ix].strip().strip("|").split("|")]
    if header != HEADERS:
        _fail("FINDINGS", "Claim triage header", "expected exact seven-column contract")
    rows = []
    for line in lines[ix + 2:]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(cells) != len(HEADERS):
            _fail("FINDINGS", "Claim triage row", f"expected seven columns, got {len(cells)}")
        rows.append(cells)
    if not rows:
        _fail("FINDINGS", "Claim triage", "empty inventory")
    return rows


def _local_links(text: str, path: Path, root: Path, identifier: str) -> None:
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", text):
        if target.startswith(("https://", "http://", "mailto:", "#")):
            continue
        local = target.split("#", 1)[0]
        if not local:
            continue
        p = Path(local)
        if p.is_absolute():
            _fail(identifier, "link", f"absolute local link is forbidden: {target}")
        resolved = (path.parent / p).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError:
            _fail(identifier, "link", f"local link escapes repository: {target}")
        if not resolved.is_file():
            _fail(identifier, "link", f"unresolved local link: {target}")


def _cards(lines: list[str], heading: str, prefix: str) -> dict[str, dict[str, str]]:
    start = next((i for i, line in enumerate(lines) if line == heading), None)
    if start is None:
        _fail("FINDINGS", heading, "section missing")
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ") and lines[i] != heading), len(lines))
    section = lines[start + 1:end]
    cards: dict[str, dict[str, str]] = {}
    current = None
    for line in section:
        match = re.fullmatch(r"#{3,4} (" + prefix + r"-\d{2})\b.*", line)
        if match:
            current = match.group(1)
            if current in cards:
                _fail(current, "ID", "duplicate card ID")
            cards[current] = {}
        elif current and line.startswith("- ") and ":" in line:
            key, value = line[2:].split(":", 1)
            if key in cards[current]:
                _fail(current, key, "duplicate field")
            cards[current][key.strip()] = value.strip()
    return cards


def _nested_cards(lines: list[str], prefix: str) -> dict[str, dict[str, str]]:
    cards: dict[str, dict[str, str]] = {}
    current = None
    for line in lines:
        match = re.fullmatch(r"#{3,4} (" + prefix + r"-\d{2})\b.*", line)
        if match:
            current = match.group(1)
            if current in cards:
                _fail(current, "ID", "duplicate card ID")
            cards[current] = {}
        elif current and line.startswith("- ") and ":" in line:
            key, value = line[2:].split(":", 1)
            if key in cards[current]:
                _fail(current, key, "duplicate field")
            cards[current][key.strip()] = value.strip()
    return cards


def _baseline_ids(path: Path, root: Path) -> set[str]:
    ids: set[str] = set()
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
        if target.startswith(("https://", "http://", "mailto:", "#")):
            continue
        resolved = (path.parent / target.split("#", 1)[0]).resolve()
        if resolved.is_file() and "162-BASELINE.md" in resolved.name:
            ids.update(re.findall(r"(?m)^\|\s*(C-\d{2}[A-Z]?)\s*\|", resolved.read_text(encoding="utf-8")))
    if not ids:
        _fail("FINDINGS", "baseline", "no linked canonical baseline claim IDs found")
    return ids


def validate_document(path: Path, root: Path, claims: list[str] | None = None, stage: str = "triage") -> dict[str, object]:
    """Validate selected records and their connected cards without executing content."""
    if stage not in {"triage", "dispositions", "complete"}:
        _fail("INPUT", "stage", "expected triage, dispositions, or complete")
    if claims is not None and (not claims or any(not re.fullmatch(r"C-\d{2}[A-Z]?", c) for c in claims)):
        _fail("INPUT", "claims", "selection must contain one or more exact C-IDs")
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    _local_links(text, path, root, "FINDINGS")
    rows = _table_rows(lines, path)
    found: dict[str, list[str]] = {}
    for cells in rows:
        m = re.search(r"\b(C-\d{2}[A-Z]?)\b", cells[0])
        if not m:
            _fail("?", "Claim", "claim cell must include stable C-ID")
        cid = m.group(1)
        if cid in found:
            _fail(cid, "Claim", "duplicate claim ID")
        found[cid] = cells
        if not re.search(r"\]\([^)]*162-BASELINE\.md#[^)]+\)", cells[0]):
            _fail(cid, "Claim", "requires a link to the canonical baseline")
        if cells[2] not in CLASSES:
            _fail(cid, "Classification", f"invalid classification {cells[2]!r}")
        _local_links(" ".join(cells), path, root, cid)
    baseline = _baseline_ids(path, root)
    selected = set(claims) if claims is not None else set(found)
    if claims is None and selected != baseline:
        missing = sorted(baseline - selected)
        _fail(missing[0] if missing else "FINDINGS", "Claim triage", "missing baseline claim from full inventory")
    for cid in selected:
        if cid not in found:
            _fail(cid, "Claim", "selected ID is missing or unknown")
    if claims is None and stage == "complete" and selected != baseline:
        missing = sorted(baseline - selected)
        _fail(missing[0] if missing else "FINDINGS", "Claim triage", "missing baseline claim from full inventory")
    findings = _cards(lines, "## Material findings", "F")
    candidates = _cards(lines, "## Follow-up candidates", "K")
    proofs = _nested_cards(lines, "P")
    referenced_f: set[str] = set()
    referenced_k: set[str] = set()
    referenced_p: set[str] = set()
    for cid in selected:
        cells = found[cid]
        refs = set(re.findall(r"\bF-\d{2}\b", cells[5]))
        if cells[2] in MATERIAL and not refs:
            _fail(cid, "Finding", "material classification requires a finding card")
        if cells[2] not in MATERIAL and refs:
            _fail(cid, "Classification", "nonmaterial evidence gap/observation cannot carry a material rank")
        if cells[6].startswith("review-required") and stage != "triage":
            _fail(cid, "Qualification", "review-required is not final")
        if cells[6].startswith("not-qualifying") and "—" not in cells[6]:
            _fail(cid, "Qualification", "nonqualification requires a reason")
        referenced_f |= refs
        for fid in refs:
            if fid not in findings:
                _fail(cid, "Finding", f"unknown finding card {fid}")
            if cid not in re.findall(r"\bC-\d{2}[A-Z]?\b", findings[fid].get("Claims", "")):
                _fail(fid, "Claims", f"missing reverse reference to {cid}")
    for fid, fields in findings.items():
        if set(fields) < F_FIELDS:
            _fail(fid, "fields", "missing " + ", ".join(sorted(F_FIELDS - set(fields))))
        if fields["Rank"] not in RANKS:
            _fail(fid, "Rank", "invalid rank")
        if fields["Disposition"] not in {"closed", "accepted", "deferred", "rejected"}:
            _fail(fid, "Disposition", "invalid disposition")
        if fields["Disposition"] == "deferred" and not fields["Revisit trigger"].strip():
            _fail(fid, "Revisit trigger", "deferred risk requires an event trigger")
        for key, value in fields.items():
            if not value:
                _fail(fid, key, "blank field")
            if value.lower().startswith("unknown") and "—" not in value:
                _fail(fid, key, "unknown value requires a reason")
        if fields["Risk state"] not in {"resolved", "accepted", "unresolved", "not-substantiated"}:
            _fail(fid, "Risk state", "invalid risk state")
        if fields["Disposition"] == "closed":
            if fields["Risk state"] != "resolved":
                _fail(fid, "Risk state", "closed finding requires resolved risk")
            ps = re.findall(r"\bP-\d{2}\b", fields["Evidence"])
            if not ps:
                _fail(fid, "Evidence", "closed finding requires a linked claim-specific proof")
            referenced_p.update(ps)
        if fields["Disposition"] == "accepted" and not re.search(r"\[[^]]+\]\([^)]+\)", fields["Decision evidence"]):
            _fail(fid, "Decision evidence", "accepted risk requires a linked decision source")
        if fields["Disposition"] == "accepted" and (fields["Risk state"] != "accepted" or fields["Owner"].lower().startswith("unknown")):
            _fail(fid, "Owner", "accepted risk requires a real owner and accepted risk state")
        if fields["Disposition"] == "deferred" and (fields["Risk state"] != "unresolved" or fields["Owner"].lower().startswith("unknown")):
            _fail(fid, "Owner", "deferred work requires an accountable owner and unresolved risk")
        if fields["Disposition"] == "rejected":
            basis = fields["Disposition basis"].lower()
            if "asserted finding" not in basis and "proposed remedy" not in basis:
                _fail(fid, "Disposition basis", "rejection must say whether the finding or remedy is rejected")
            if fields["Risk state"] not in {"unresolved", "not-substantiated"}:
                _fail(fid, "Risk state", "rejected finding must retain unresolved risk or mark not-substantiated")
        for kid in re.findall(r"\bK-\d{2}\b", fields["Route"]):
            if kid not in candidates:
                _fail(fid, "Route", f"orphan candidate {kid}")
            referenced_k.add(kid)
        for pid in re.findall(r"\bP-\d{2}\b", fields["Evidence"]):
            if pid not in proofs:
                _fail(fid, "Evidence", f"orphan proof card {pid}")
            referenced_p.add(pid)
    for kid, fields in candidates.items():
        if set(fields) < K_FIELDS:
            _fail(kid, "fields", "missing " + ", ".join(sorted(K_FIELDS - set(fields))))
        if kid not in referenced_k:
            _fail(kid, "Findings", "orphan candidate has no finding owner reference")
        if not re.findall(r"\bF-\d{2}\b", fields.get("Findings", "")):
            _fail(kid, "Findings", "candidate requires a material finding")
        for fid in re.findall(r"\bF-\d{2}\b", fields["Findings"]):
            if fid not in findings:
                _fail(kid, "Findings", f"unknown finding {fid}")
            if findings[fid].get("Rank") not in RANKS:
                _fail(kid, "Findings", f"candidate owner {fid} is not material")
    for pid, fields in proofs.items():
        if not fields.get("Oracle", "").strip():
            _fail(pid, "Oracle", "proof card requires an oracle")
        if set(fields) < P_FIELDS:
            _fail(pid, "fields", "missing " + ", ".join(sorted(P_FIELDS - set(fields))))
        if pid not in referenced_p:
            _fail(pid, "Oracle", "orphan proof card has no finding owner reference")
    if stage in {"dispositions", "complete"} and claims is None:
        _fail("FINDINGS", "Disposition summary", "global disposition summary is required")
    if stage == "complete" and claims is None and "## Phase 164 handoff" not in lines:
        _fail("FINDINGS", "Phase 164 handoff", "complete mode requires the handoff section")
    return {"claims": sorted(selected), "findings": len(referenced_f), "candidates": len(candidates), "proofs": len(proofs)}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--claims", help="comma-separated exact C-ID subset")
    ap.add_argument("--stage", choices=["triage", "dispositions", "complete"], default="complete")
    ap.add_argument("--file", type=Path, default=Path(__file__).with_name("163-FINDINGS.md"))
    args = ap.parse_args(argv)
    try:
        claims = args.claims.split(",") if args.claims is not None else None
        result = validate_document(args.file, Path(__file__).resolve().parents[3], claims, args.stage)
    except (OSError, ContractError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    ids = ",".join(result["claims"])
    if claims is not None or args.stage != "complete":
        print(f"PARTIAL: findings structural contract; stage={args.stage}; claims={ids}")
    else:
        print(f"PASS: findings structural contract; claims={len(result['claims'])}; material={result['findings']}; candidates={result['candidates']}; proofs={result['proofs']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
