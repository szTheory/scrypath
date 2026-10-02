# Phase 164: Readiness Gate and Reconciliation — Pattern Map

**Mapped:** 2026-09-25  
**Files analyzed:** 3 planned or conditional artifacts  
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/reference/PRE-OPERATOR-UI-READINESS.md` (dated assessment update) | canonical maintainer decision record | evidence aggregation and decision flow | `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` | role-match; scoped evidence and dated closeout |
| `.planning/phases/164-readiness-gate-and-reconciliation/check_readiness.py` (if implemented) | utility / Markdown contract checker | transform / batch validation | `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` | exact role and flow |
| `.planning/phases/164-readiness-gate-and-reconciliation/test_check_readiness.py` or focused inline fixtures (if needed) | test / contract fixtures | batch validation | `.planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py` | role-match |

The canonical readiness page is the only definite source change. RESEARCH recommends a targeted structural/link check but permits equivalent deterministic assertions; checker and fixture files are therefore conditional implementation choices, not additional gate authorities. Phase plan, validation, and summary artifacts are normal GSD workflow outputs and are not separate product/runtime deliverables.

## Pattern Assignments

### `.planning/reference/PRE-OPERATOR-UI-READINESS.md` (canonical decision record, evidence aggregation)

**Primary analog:** `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` (tracked)

**Dated, scoped result pattern** (lines 1–4, 7–18):

```markdown
## Disposition

**Shipped as Scrypath 0.3.13 on 2026-09-25.** The release was merged through the Release Please PR and published by the repository's credential-scoped workflow. Main CI, Hex visibility, versioned HexDocs, consumer compile, and package-to-tag parity all passed.

## Merge and exact-SHA evidence

| Gate | Evidence | Result |
|-------|----------|--------|
| Main after Phase 161 merge | [Run 36081908742](...) | Success on merge commit `465aef9...`. |
```

Carry forward a dated disposition followed by evidence rows with linked receipt, result, SHA/version, and explicit scope. For Phase 164, keep evidence date separate from assessment date, record all six approved conditions independently as `PASS`, `FAIL`, or `UNKNOWN`, and state each source's freshness and limit. Preserve the current readiness status unless the approved condition and finding rules are all met.

**Cleanup ownership pattern** (lines 28–34):

```markdown
## Ownership and workspace cleanup

- The Phase 161 cleanup inventory found no milestone-owned temporary worktree or service stack. Package-proof temp paths and generated ExDoc output were removed; other projects' containers and temporary directories were preserved.
- The original worktree's unrelated modified ... files ... were preserved.
```

Use an explicit Phase 164-owned cleanup/verification inventory. State “none” only after inspecting the actual execution workspace. Keep unrelated pre-existing changes out of task-owned debt, and link the final exact-SHA closeout evidence after the last tracked edit, following `CONTRIBUTING.md` lines 67–82.

**Authority and non-authorization pattern:** `.planning/reference/PRE-OPERATOR-UI-READINESS.md` (tracked), lines 47–67, is itself the controlling contract. Retain its six condition meanings verbatim, report readiness separately from any strategic recommendation, and keep maintainer availability and UI-start authorization separate. Do not duplicate baseline claim rows or Phase 163 dispositions; link to their canonical files.

### `.planning/phases/164-readiness-gate-and-reconciliation/check_readiness.py` (conditional structural checker)

**Analog:** `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` (tracked)

**Data-only contract and failure pattern** (lines 1–24, 27–46):

```python
"""Structural validation of Phase 163 findings data; not product proof."""
from __future__ import annotations

class ContractError(ValueError):
    pass

def _fail(identifier: str, field: str, reason: str) -> None:
    raise ContractError(f"{identifier} — {field}: {reason}")

def _table_rows(lines: list[str], source: Path) -> list[list[str]]:
    ix = next((i for i, line in enumerate(lines) if line.startswith("| Claim |")), None)
    if ix is None:
        _fail("FINDINGS", "Claim triage", "table not found")
```

Follow the standard-library, data-only checker convention. Check finite record invariants (six unique condition rows, only the three allowed statuses, dated evidence and assessment, required links/limits, fail-closed final status, and conditional recommendation language). Never execute Markdown commands or claim that a structural PASS establishes evidence truth or readiness. Keep any checker local to this record; do not add recurring CI infrastructure without demonstrated value.

**Local-link validation pattern** (lines 49–65):

```python
for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", text):
    if target.startswith(("https://", "http://", "mailto:", "#")):
        continue
    resolved = (path.parent / target.split("#", 1)[0]).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError:
        _fail(identifier, "link", f"local link escapes repository: {target}")
    if not resolved.is_file():
        _fail(identifier, "link", f"unresolved local link: {target}")
```

Reuse the relative-link containment and existence checks if the readiness check validates local evidence links. Keep hosted URLs syntactically linked only; a link checker cannot certify the hosted receipt's meaning, freshness, or exact-SHA scope.

### `.planning/phases/164-readiness-gate-and-reconciliation/test_check_readiness.py` (conditional fixtures)

**Analog:** `.planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py` (tracked; see `.planning/phases/163-findings-and-bounded-follow-up/163-VALIDATION.md` lines 39–58)

Use small standard-library fixtures for the decision boundaries that can regress: missing/duplicate condition, invalid status, UNKNOWN or FAIL cannot yield READY, unresolved gate-rank finding prevents READY, and a recommendation is rejected unless all six conditions pass. The predecessor validation strategy describes these as positive/adversarial contract fixtures and labels checker output structural only. Prefer inline fixtures only if they provide the same discriminating coverage without obscuring the contract.

## Shared Patterns

### Canonical evidence with explicit provenance and limits

**Sources:** Phase 162 baseline (`.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md`, tracked) and Phase 161 release receipt above.

Link to canonical claim rows, finding dispositions, release receipts, support/CI sources, and planning state rather than copying their data into another ledger. Preserve exact date, SHA/run, environment, named scenario, freshness decision, and limitation. A bounded successful receipt supports only the claim it actually exercises.

### Structural validation is not semantic approval

**Source:** `.planning/phases/163-findings-and-bounded-follow-up/163-VALIDATION.md` (tracked), lines 45–58.

```markdown
Structural success is not product proof, source-truth certification, owner approval, or readiness.
```

Keep machine-checkable document shape separate from human/source-backed evidence judgment. Unknown or stale evidence must not be promoted to PASS; zero Phase 163 findings/candidates remains a disposition result, not proof that the six conditions pass.

## No Analog Found

None. The conditional checker and fixture shape have direct Phase 163 predecessors. No application runtime, API, UI, database, or CI implementation is in scope.

## Metadata

**Analog search scope:** tracked readiness reference, phase evidence/checker artifacts, validation documents, and release closeout receipts.  
**Tracked-source check:** all named analog paths verified with `git ls-files`.  
**Pattern extraction date:** 2026-09-25.
