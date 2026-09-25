# Phase 163: Findings and Bounded Follow-up - Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 6 planned or conditionally modified artifacts  
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/163-findings-and-bounded-follow-up/163-FINDINGS.md` | maintainer documentation / findings-disposition index | evidence aggregation and decision flow | `.planning/reference/QUALITY-LEDGER.md` | role-match |
| `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` | utility / documentation-contract checker | transform / batch validation | `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` | exact role and flow |
| focused negative fixtures embedded in `check_findings.py` or a phase-local fixture directory | test | batch validation | `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` | role-match; the closest checker already exercises fail-closed input cases inline |
| `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` (only if later receipt changes a claim assessment) | maintainer documentation / canonical evidence index | evidence aggregation | `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` | exact role and flow |
| `.planning/phases/163-findings-and-bounded-follow-up/163-VALIDATION.md` | validation documentation / configuration | requirement-to-proof mapping | `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-VALIDATION.md` | exact role and flow |
| Phase 163 `*-PLAN.md` and `*-SUMMARY.md` artifacts | plan / execution documentation | request-response handoff | `.planning/phases/162-whole-product-evidence-baseline/162-03-PLAN.md` | role-match |

`163-FINDINGS.md` is the primary new output. It must cross-reference Phase 162 claim IDs and existing receipts, rather than copy them into a second evidence ledger. The possible baseline amendment is conditional: reconcile C-21's later remediation receipt and any narrowly verified C-17 receipt, but do not make a broad evidence refresh.

## Pattern Assignments

### `.planning/phases/163-findings-and-bounded-follow-up/163-FINDINGS.md` (maintainer documentation, evidence aggregation and decision flow)

**Primary analog:** `.planning/reference/QUALITY-LEDGER.md` (tracked)

**Scoped ledger and independent factors pattern** (lines 3-14):

```markdown
**Scope:** v1.37 Code Quality Ratchet (non-UI)
**Closed:** 2026-08-26

This ledger records evidence, expected benefit, implementation churn, verification,
and final disposition.

| Rank | Finding and evidence | Impact / benefit | Churn | Verification | Disposition |
```

Copy the compact, source-backed card/table approach, but replace historical `Churn` with separate implementation cost, regression cost, and recurring verification cost. Add the locked factors that this older ledger lacks: classification, affected named job, exposure, confidence, applicable risk categories, qualitative rationale, owner, revisit event, and candidate route.

**Evidence-linked disposition pattern** (lines 16-26):

```markdown
| 1 | `Scrypath.Meilisearch.Client.create_or_update_index/3` deletes ... | Reduces ... | Focused change ... | ... | Fixed. ... |
| 2 | `Scrypath.Runtime` can ... | Tests the ... | No implementation change. | ... | Retained. ... |
```

Use a baseline claim ID such as `C-21` in every triage row. Classify missing/stale proof as `evidence gap` or `observation`, give it no severity, and state why it does or does not change a decision. Material Scrypath-owned findings alone receive `Critical`, `High`, `Medium-leverage`, or `Low` and one of `closed`, `accepted`, `deferred`, or `rejected`. An accepted risk needs an actual linked owner decision; a deferred finding needs both owner and event-based revisit trigger. Neither disposition decides Phase 164 readiness.

**Qualification boundary pattern** (lines 28-45):

```markdown
| 3 | ... | ... | ... | ... | Retained ... |

## Diminishing-return boundary

No separate cleanup phase is proposed. ... No evidence supports further
small-scope cosmetic cleanup as a high-value release concern.
```

Use the same explicit non-candidate conclusion when no finding qualifies. Do not create a speculative backlog. A selected candidate must instead name its adopter/operator outcome, scope authority and exclusions, source finding(s), owner boundary, focused-patch versus milestone rationale, and claim-local automated proof.

**Supporting analog:** `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VALIDATION.md` (tracked), lines 16-27:

```markdown
| Behavior | Requirement | Test Type | Automated Command / Evidence | Coverage Status | Acceptance Status |
| ... | PKG-01 | Unit | `mix test ...` — 11 tests, 0 failures | ✅ Covered | ✅ Green |
| ... | PKG-01 | Integration | Exact-SHA run ...; ... PASS markers below | ✅ Covered by hosted package run | ✅ Green |
```

For each selected candidate claim, use this concise behavior-to-command layout, expanded only with the locked claim-proof fields: user outcome, boundary/exclusions, fixture and oracle, layer, environment/version, receipt or explicit future state, invalidator, timeout, diagnostics, isolation/cleanup, and CI economics. Select the cheapest reliable layer; an exact-SHA hosted receipt is only needed where the claim crosses that boundary.

---

### `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` (utility, batch documentation-contract validation)

**Analog:** `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` (tracked)

**Imports and fixed-artifact pattern** (lines 1-18):

```python
#!/usr/bin/env python3
"""Structural checks for the Phase 162 evidence index (not a product test)."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASELINE = Path(__file__).with_name("162-BASELINE.md")
```

Keep the checker standard-library only and phase-local. Change the docstring and constants for `163-FINDINGS.md`; it must not be a generic audit framework or an expansion of the Phase 162 grammar. Resolve local links from the phase artifact and reject absolute/out-of-repository links.

**Fail-closed error pattern** (lines 22-24):

```python
def fail(cid: str, field: str, reason: str) -> None:
    print(f"{cid} — {field}: {reason}", file=sys.stderr)
    raise SystemExit(1)
```

Use this single failure form for missing claim coverage, invalid classifications/ranks/dispositions, missing linked baseline ID, accepted risk without decision evidence, deferral without owner or event trigger, orphan candidate, and proof card without oracle.

**Table parsing and exact-header pattern** (lines 36-55):

```python
header_ix = next((i for i, line in enumerate(lines) if line.startswith("| ID |")), None)
if header_ix is None:
    fail("BASELINE", "header", "claim matrix header not found")
header = [v.strip() for v in lines[header_ix].strip().strip("|").split("|")]
if header != HEADER:
    fail("BASELINE", "header", f"expected {len(HEADER)} exact columns in the documented order")
```

Define a compact, stable row contract before implementing the checker. Parse only the finite triage and candidate/proof sections declared by Phase 163. Validate all Phase 162 baseline IDs are represented exactly once in the triage index, but leave semantic truth to the cited sources and actual owner decision.

**Vocabulary and link-boundary checks** (lines 112-148):

```python
if c[16] not in ASSESSMENTS:
    fail(cid, "Assessment", f"invalid assessment {c[16]!r}")
...
for target in links:
    if target.startswith(("http://", "https://", "mailto:")) or target.startswith("#"):
        continue
    local = target.split("#", 1)[0]
    if Path(local).is_absolute():
        fail(cid, "Source", f"absolute local link is not portable: {target!r}")
```

Mirror the constrained-enum and portable-link checks. Add Phase 163's allowed classifications, ranks, and dispositions as separate enums. Do not infer severity from confidence or costs, and do not treat a structural pass as product/recovery proof.

**Focused negative fixtures:** Use tiny in-memory Markdown strings or a dedicated tracked fixture directory only if it improves clarity. Cover the discriminating cases named in research: omitted baseline claim, evidence gap with a rank, accepted risk without a decision link, deferred finding without revisit event, candidate without linked finding, and proof card without oracle. Invoke the checker against every negative fixture and require failure, then against the real artifact and require success.

---

### `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` (conditional canonical-index amendment, evidence aggregation)

**Analog:** `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` (tracked)

**Canonical-source and chronology boundary pattern** (lines 1-7, 64-80):

```markdown
# Phase 159 Canonical Requirement-to-Evidence Matrix

This Markdown document is the sole canonical D-13 evidence source ...
Later phase-local retrospective files are indexes that link here; they must not
duplicate or replace these rows.
...
Fresh results cited above are limited to their exact SHA, date, and environment.
They never prove an earlier development action. Phase-local retrospective records
must link to this matrix rather than copy its rows.
```

Amend only the affected Phase 162 row when an existing later receipt changes that row's assessment, observed result, freshness, limitation, or next question. For C-21, record Phase 161's audit/remediation receipt and retain its root-graph/historical-advisory boundary. For C-17, amend only after tracing a matching exact-SHA mounted run to the source and fixture. Retain the baseline's 19-column header, deterministic ordering, and single canonical-index status.

**Required verification:** rerun `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24 --full-coverage` only if this file changes. The checker is structural evidence-index validation; it is not proof of defect materiality or a readiness verdict.

---

### `.planning/phases/163-findings-and-bounded-follow-up/163-VALIDATION.md` and phase plan/summary artifacts (validation and execution documentation)

**Primary analog:** `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-VALIDATION.md` (tracked)

**Test infrastructure and task-evidence mapping pattern** (lines 12-27):

```markdown
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit and GitHub Actions |
| **Exact-SHA helper** | `node scripts/ci_monitor.cjs closeout ...` |

## Task Evidence

| Plan/task | Requirement | Command or authority | Result |
```

Retain the Phase 163 validation map's existing Python framework and proposed focused command. Once the artifact/checker layout is final, map FIND-01 through CLOSE-02 to the checker and actual evidence sources. Preserve the distinction between automated document acceptance and manual owner decisions; owner decisions must link to their real source and cannot be simulated as UAT.

**Exact-SHA and no-human-UAT pattern** (lines 32-63, 76-83):

```markdown
- Required jobs: `core (required)`, ... — all successful.
- Advisory lanes: ... — all successful.
...
No human-facing UAT was needed. Maintainer merge authorization was the only
external decision; all software acceptance and publication checks ran automatically.
```

Plan phase closeout through the repository's existing candidate/final exact-SHA procedure. Do not add a recurring CI lane for the findings checker unless the recorded regression risk, reliability, diagnostic value, and runtime/maintenance comparison justify it. Do not dispatch closeout per documentation edit.

**Plan action and verification pattern:** `.planning/phases/162-whole-product-evidence-baseline/162-03-PLAN.md` (tracked), lines 69-79. Follow its concrete `files`, `action`, `verify`, and explicit boundary structure: each task should name the artifact, preserve the no-new-scorecard/no-broad-rerun constraints, and have an automated checker command or an explicit Wave 0 dependency.

## Shared Patterns

### Canonical evidence, not duplicated receipts

**Sources:** `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` (tracked), `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` (tracked), lines 1-7 and 78-80.

`163-FINDINGS.md` carries classification and disposition; Phase 162 remains the canonical claim/evidence index. Link C-IDs and retained receipt locations. Preserve exact SHA/date/environment and scenario boundaries when evidence is reused.

### Structural checks have limited authority

**Source:** `.planning/phases/162-whole-product-evidence-baseline/check_baseline.py` (tracked), lines 66-148.

Structural validation can establish finite coverage, required cells, values, and link portability. It cannot establish factual materiality, recovery behavior, risk acceptance, or readiness. Use source-backed reconciliation for those judgments.

### Cheapest claim-specific automated proof

**Source:** `.planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-VALIDATION.md` (tracked), lines 16-61.

Map each selected claim to unit/contract/seam proof before using package, service, browser, or exact-SHA hosted proof. Preserve fixture/oracle and the observed boundary. An existing test that clicks retry but accepts a remaining failed state does not prove repaired search.

### Risk attribution and readiness boundary

**Sources:** Phase 163 CONTEXT D-01 through D-15; `.planning/reference/QUALITY-LEDGER.md` (tracked), lines 3-45.

Attribute only confirmed Scrypath-owned defects or substantiated affected risks to material findings. Host authorization policy and generic opportunities retain their explicit owner/boundary. Phase 163 records disposition and follow-up qualification; Phase 164 makes the six-condition readiness decision.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Phase 163 negative fixtures | test | batch validation | No tracked standalone Python fixture suite exists for planning-document contracts. Reuse `check_baseline.py`'s fail-closed parsing style and keep fixtures deliberately small. |

## Metadata

**Analog search scope:** tracked Phase 162 evidence artifacts/checker, Phase 159 canonical matrix, Phase 160 package-proof validation, Phase 161 closeout validation, and the quality ledger.  
**Files scanned:** 5 detailed tracked analogs after tracked-source verification.  
**Pattern extraction date:** 2026-09-25.
