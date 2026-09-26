#!/usr/bin/env python3
"""Structural checks for the Phase 162 evidence index (not a product test)."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASELINE = Path(__file__).with_name("162-BASELINE.md")
HEADER = ["ID", "Dimension", "Role", "User job", "Stage", "Seam", "Claim", "Source", "Observed result", "Date", "Receipt/SHA", "Environment/versions", "Evidence layer/CI posture", "What it proves", "Proof boundary", "Limitation", "Assessment", "Freshness", "Invalidator/next question"]
DIMENSIONS = set("1234567")
ROLES = {"integrator", "feature owner", "operator", "maintainer"}
STAGES = {"first-hour setup", "indexing", "search", "failure diagnosis", "recovery", "upgrade", "release"}
STAGE_ORDER = ["first-hour setup", "indexing", "search", "failure diagnosis", "recovery", "upgrade", "release"]
ASSESSMENTS = {"supported", "insufficiently supported", "unknown"}
FRESHNESS = {"current", "reusable within its stated boundary", "stale after a relevant invalidator", "unknown"}
PLACEHOLDER = re.compile(r"\b(TODO|TBD|FIXME|XXX|placeholder|fill me|pending evidence)\b", re.I)


def fail(cid: str, field: str, reason: str) -> None:
    print(f"{cid} — {field}: {reason}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--through", type=int)
    ap.add_argument("--full-coverage", action="store_true")
    args = ap.parse_args()
    if not BASELINE.is_file():
        fail("BASELINE", "artifact", f"missing {BASELINE}")
    lines = BASELINE.read_text(encoding="utf-8").splitlines()
    header_ix = next((i for i, line in enumerate(lines) if line.startswith("| ID |")), None)
    if header_ix is None:
        fail("BASELINE", "header", "claim matrix header not found")
    header = [v.strip() for v in lines[header_ix].strip().strip("|").split("|")]
    if header != HEADER:
        fail("BASELINE", "header", f"expected {len(HEADER)} exact columns in the documented order")
    separator_ix = header_ix + 1
    if separator_ix >= len(lines):
        fail("BASELINE", "header separator", "missing Markdown table separator")
    separator = [v.strip() for v in lines[separator_ix].strip().strip("|").split("|")]
    if len(separator) != len(HEADER) or any(not re.fullmatch(r":?-+:?", cell) for cell in separator):
        fail("BASELINE", "header separator", f"expected {len(HEADER)} Markdown separator cells")
    rows: list[tuple[str, list[str]]] = []
    for line in lines[header_ix + 2:]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [v.strip() for v in line.strip().strip("|").split("|")]
        if cells and re.fullmatch(r":?-+:?", cells[0]):
            continue
        cid = cells[0] if cells else "?"
        if len(cells) != len(HEADER):
            fail(cid, "column count", f"expected {len(HEADER)}, got {len(cells)}")
        rows.append((cid, cells))
    if not rows:
        fail("BASELINE", "matrix", "no claim rows found")

    seen: set[str] = set()
    assertions: dict[str, str] = {}
    base_counts: dict[int, int] = {}
    orderable: list[tuple[int, int, str]] = []
    dims, roles, stages = set(), set(), set()
    for cid, c in rows:
        if not re.fullmatch(r"C-\d{2}(?:[A-Z])?", cid):
            fail(cid, "ID", "expected C-NN with an optional stable suffix")
        base = int(cid[2:4])
        if args.through is not None and base > args.through:
            continue
        if cid in seen:
            fail(cid, "ID", "duplicate claim ID")
        seen.add(cid)
        if re.fullmatch(r"C-\d{2}", cid):
            base_counts[base] = base_counts.get(base, 0) + 1
        for name, value in zip(HEADER[1:], c[1:]):
            if not value:
                fail(cid, name, "blank cell")
            if PLACEHOLDER.search(value):
                fail(cid, name, "placeholder text is not an assessment")
        if c[1] not in DIMENSIONS:
            fail(cid, "Dimension", f"invalid dimension {c[1]!r}")
        if c[2] not in ROLES:
            fail(cid, "Role", f"invalid role {c[2]!r}")
        if c[4] not in STAGES:
            fail(cid, "Stage", f"invalid stage {c[4]!r}")
        orderable.append((int(c[1]), STAGE_ORDER.index(c[4]), cid))
        if c[16] not in ASSESSMENTS:
            fail(cid, "Assessment", f"invalid assessment {c[16]!r}")
        if c[17] not in FRESHNESS:
            fail(cid, "Freshness", f"invalid freshness {c[17]!r}")
        dims.add(c[1]); roles.add(c[2]); stages.add(c[4])
        claim = re.sub(r"\W+", " ", c[6].lower()).strip()
        if claim in assertions:
            fail(cid, "Claim", f"duplicate assertion also appears in {assertions[claim]}")
        assertions[claim] = cid
        links = re.findall(r"\[[^]]+\]\(([^)]+)\)", c[7])
        no_proof = "No direct proof" in c[7]
        if not links and not no_proof:
            fail(cid, "Source", "requires a source link or reason-bearing 'No direct proof'")
        if "No observed result" in c[8] and (len(c[8]) < len("No observed result — ") + 8):
            fail(cid, "Observed result", "absent result must include a reason")
        if "No direct proof" in c[7] and len(c[7]) < len("No direct proof — ") + 8:
            fail(cid, "Source", "absent proof must include a reason")
        if "No direct proof" in c[7] and "No observed result" not in c[8]:
            fail(cid, "Observed result", "when direct proof is absent, state 'No observed result' and give the reason")
        if c[16] == "supported":
            if no_proof or "No observed result" in c[8] or not links:
                fail(cid, "Assessment", "supported requires direct linked proof and observed result")
            if not re.search(r"20\d\d-\d\d-\d\d", c[9]):
                fail(cid, "Date", "supported requires a dated result")
        if c[9].lower().startswith(("unknown", "not applicable")) and "—" not in c[9]:
            fail(cid, "Date", "unknown/not applicable metadata must include a reason")
        if c[10].lower().startswith(("unknown", "not applicable")) and "—" not in c[10]:
            fail(cid, "Receipt/SHA", "unknown/not applicable metadata must include a reason")
        if c[11].lower().startswith(("unknown", "not applicable")) and "—" not in c[11]:
            fail(cid, "Environment/versions", "unknown/not applicable metadata must include a reason")
        for target in links:
            if target.startswith(("http://", "https://", "mailto:")) or target.startswith("#"):
                continue
            local = target.split("#", 1)[0]
            if Path(local).is_absolute():
                fail(cid, "Source", f"absolute local link is not portable: {target!r}")
            resolved = (BASELINE.parent / local).resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                fail(cid, "Source", f"local link resolves outside repository: {target!r}")
            if not resolved.exists():
                fail(cid, "Source", f"unresolved local link {target!r}")
    if orderable != sorted(orderable):
        fail("BASELINE", "row order", "rows must be ordered by dimension, lifecycle stage, then claim ID")
    if args.through is not None:
        for n in range(1, args.through + 1):
            if base_counts.get(n, 0) != 1:
                fail(f"C-{n:02d}", "ID", f"base ID must occur exactly once (found {base_counts.get(n, 0)})")
    if args.full_coverage:
        if dims != DIMENSIONS:
            fail("BASELINE", "Dimension", f"missing values {sorted(DIMENSIONS-dims)}")
        if roles != ROLES:
            fail("BASELINE", "Role", f"missing values {sorted(ROLES-roles)}")
        if stages != STAGES:
            fail("BASELINE", "Stage", f"missing values {sorted(STAGES-stages)}")
    print(f"PASS: {len(seen)} claim rows checked" + (f" through C-{args.through:02d}" if args.through else "") + (" with full coverage" if args.full_coverage else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
