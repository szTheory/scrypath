# Phase 07: Verification Backfill and Milestone Traceability Repair - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/01-core-contracts-and-api-shape/01-VERIFICATION.md` | test | transform | `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md` | exact |
| `.planning/phases/03-search-query-api-and-hydration/03-VERIFICATION.md` | test | transform | `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |
| `.planning/v1.0-MILESTONE-AUDIT.md` | config | batch | `.planning/v1.0-MILESTONE-AUDIT.md` | exact |

Notes:
- `01-VERIFICATION.md` and `03-VERIFICATION.md` are explicit outputs in the research recommendation and audit gap list.
- `REQUIREMENTS.md` and `ROADMAP.md` are explicit repair targets in the phase goal and success criteria.
- `STATE.md` is implied by the research open question and current contradictions with the roadmap.
- `v1.0-MILESTONE-AUDIT.md` is implied by the success criterion requiring refreshed milestone-facing evidence that separates runtime gaps from evidence gaps.

## Pattern Assignments

### `.planning/phases/01-core-contracts-and-api-shape/01-VERIFICATION.md` (test, transform)

**Primary analog:** `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md`

**Front matter + report header pattern** (lines 1-15):
```md
---
phase: 02-meilisearch-core-sync
verified: 2026-04-15T23:53:43Z
status: passed
score: 17/17 must-haves verified
overrides_applied: 0
---

# Phase 2: Meilisearch Core Sync Verification Report

**Phase Goal:** Make Scrypath useful end to end for one real backend by delivering safe core indexing flows.
**Verified:** 2026-04-15T23:53:43Z
**Status:** passed
**Re-verification:** No - initial verification
```

**Observable truths table pattern** (lines 18-40):
```md
### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A developer can synchronize searchable records to Meilisearch on insert and update. | ✓ VERIFIED | ... |
...

**Score:** 17/17 truths verified
```

**Required artifacts table pattern** (lines 42-61):
```md
### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Req/Jason transport deps for Meilisearch runtime | ✓ VERIFIED | ... |
| `lib/scrypath.ex` | Public sync/delete facade | ✓ VERIFIED | ... |
...
```

**Behavioral spot-checks + requirements coverage pattern** (lines 86-103):
```md
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 2 sync/backend contract tests pass | `mix test ...` | `26 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `BACK-01` | `02-02`, `02-03`, `02-04` | ... | ✓ SATISFIED | ... |
```

**Supporting analog for concise "no gaps" close-out:** `.planning/phases/05-reindexing-and-operational-workflows/05-VERIFICATION.md` lines 89-104
```md
### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME placeholders, empty implementations, or hardcoded hollow data found in Phase 5 artifacts. | - | No blocking anti-patterns detected. |
```

**Apply to Phase 1 backfill**
- Keep the same section order as `02-VERIFICATION.md`.
- Replace truth rows with `SCMA-01`, `SCMA-02`, `SCMA-03`, and `BACK-02` evidence from `lib/scrypath/schema.ex`, `lib/scrypath/projection.ex`, `lib/scrypath/backend.ex`, `lib/scrypath.ex`, and their tests.
- Include focused `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs` commands in Behavioral Spot-Checks.

---

### `.planning/phases/03-search-query-api-and-hydration/03-VERIFICATION.md` (test, transform)

**Primary analog:** `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md`

**Link verification pattern** (lines 63-75):
```md
### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scrypath.ex` | `Scrypath.Sync` | public sync/delete delegates | ✓ WIRED | ... |
| `lib/scrypath/sync.ex` | backend write path | shared upsert/delete orchestration | ✓ WIRED | ... |
...
```

**Data-flow trace pattern** (lines 77-84):
```md
### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scrypath/sync.ex` | `documents` | ... | Yes | ✓ FLOWING |
```

**Requirements coverage pattern** (lines 92-103):
```md
### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `BACK-01` | `02-02`, `02-03`, `02-04` | ... | ✓ SATISFIED | ... |
...
```

**Supporting analog for mixed verification + regression note:** `.planning/phases/06-phoenix-ergonomics-and-public-facing-polish/06-VERIFICATION.md` lines 97-101
```md
### Gaps Summary

The previous Phase 6 blocker is closed. ...
Quick regression checks on the previously passing Phoenix docs surface also held: ...
```

**Apply to Phase 3 backfill**
- Reuse the same verification doc skeleton.
- Anchor link/data-flow rows on `lib/scrypath.ex`, `lib/scrypath/search.ex`, `lib/scrypath/query.ex`, `lib/scrypath/search_result.ex`, `lib/scrypath/hydration.ex`, and `lib/scrypath/meilisearch.ex`.
- Use requirement rows for `SRCH-01` through `SRCH-06`.
- Include focused commands from research: `mix test test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs`.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**Requirement checkbox block pattern** (lines 8-48):
```md
### Schema Declaration

- [ ] **SCMA-01**: Developer can declare a searchable Ecto schema with a small, explicit `use Scrypath` configuration.
...

### Backend Foundation

- [x] **BACK-01**: Developer can use Scrypath with Meilisearch as the supported public backend in v1.
- [ ] **BACK-02**: The internal architecture preserves a path to future backend support without forcing a premature public abstraction.
```

**Traceability table pattern** (lines 76-103):
```md
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCMA-01 | Phase 7 | Pending |
...
| PHNX-02 | Phase 6 | Complete |
```

**Footer metadata pattern** (lines 105-112):
```md
**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-04-15*
*Last updated: 2026-04-16 after phase 4 plan 04-03 execution*
```

**Apply in this phase**
- Preserve the existing section order and checkbox list format.
- Update `SCMA-*`, `BACK-02`, and `SRCH-*` checkboxes to closed only after `01-VERIFICATION.md` and `03-VERIFICATION.md` exist.
- Repoint traceability rows from `Phase 7 / Pending` to original shipped phases (`Phase 1` and `Phase 3`) with `Complete`.
- Research also shows `OPER-01..03` and `OPER-05` are stale and should likely be aligned with verified Phase 5 status.

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md`

**Top-level metadata + overview table pattern** (lines 1-19):
```md
# Roadmap: Scrypath

**Created:** 2026-04-15
**Project:** Scrypath
**Total phases:** 6
**v1 requirements:** 24
**Coverage:** 100%

## Overview

| # | Phase | Goal | Requirements | UI Hint |
|---|-------|------|--------------|---------|
| 1 | Core Contracts and API Shape | ... | SCMA-01, SCMA-02, SCMA-03, BACK-02 | No |
...
| 7 | Verification Backfill and Milestone Traceability Repair | ... | SCMA-01, ... SRCH-06 | No |
```

**Per-phase detail pattern** (lines 138-152):
```md
### Phase 7: Verification Backfill and Milestone Traceability Repair

**Goal:** Close the v1.0 audit evidence gaps by recreating missing verification artifacts and reconciling milestone planning files with what the codebase actually ships.

**Requirements:** SCMA-01, SCMA-02, SCMA-03, BACK-02, SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06

**Gap Closure:** Closes gaps from audit

**Success criteria:**
1. Phase 1 has a verification artifact ...
...
```

**Dependency notes pattern** (lines 154-162):
```md
## Dependency Notes

- Phase 1 is foundational for every later phase.
...
- Phase 7 depends on completed milestone code being present in Phases 1 through 6 and exists only to repair milestone audit evidence and traceability.
```

**Apply in this phase**
- Keep the same header and phase-detail formatting.
- Repair contradictory bookkeeping first: `**Total phases:** 6` must align with the presence of Phase 7.
- Preserve historical ownership language in Phase 1 and Phase 3 sections; Phase 7 should stay framed as repair work, not feature delivery.

---

### `.planning/STATE.md` (config, transform)

**Analog:** `.planning/STATE.md`

**YAML state header pattern** (lines 1-18):
```yaml
---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 06
current_phase_name: phoenix-ergonomics-and-public-facing-polish
current_plan: Completed
status: completed
...
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 22
  completed_plans: 22
  percent: 100
---
```

**Current Position / Status summary pattern** (lines 29-38, 81-100):
```md
## Current Position

Phase: 06 (phoenix-ergonomics-and-public-facing-polish) — COMPLETE
...

## Current Status

- Project initialized
- Research completed
...
- Phase 4 requirement closed: OPER-04
```

**Apply in this phase**
- Preserve YAML-first structure.
- If Phase 7 updates `ROADMAP.md`, reflect the same phase count and current phase bookkeeping here so the state file does not contradict milestone metadata.
- Keep the accumulated-context style as-is; only repair fields that are now false because Phase 7 exists.

---

### `.planning/v1.0-MILESTONE-AUDIT.md` (config, batch)

**Analog:** `.planning/v1.0-MILESTONE-AUDIT.md`

**Audit front matter pattern** (lines 1-18):
```yaml
---
milestone: v1.0
audited: 2026-04-16T16:40:00Z
status: gaps_found
scores:
  requirements: 14/24
  phases: 4/6
  integration: 6/6
  flows: 6/6
gaps:
  requirements:
    - id: "SCMA-01"
      status: "orphaned"
      ...
---
```

**Phase coverage + requirements audit pattern** (lines 118-141):
```md
## Phase Coverage

| Phase | Plans | Summaries | Verification | Status |
|-------|-------|-----------|--------------|--------|
| 1 | 3/3 | 3/3 | missing | gap |
...

## Requirements Audit

| Requirement Set | Final Status | Basis |
|-----------------|-------------|-------|
| Phase 2 requirements (`BACK-01`, `SYNC-01..04`, `SYNC-06`) | satisfied | Verified in `02-VERIFICATION.md` |
...
| Phase 1 requirements (`SCMA-01..03`, `BACK-02`) | orphaned | Completed in summaries, but no Phase 1 verification artifact exists |
```

**Critical gaps + recommendation pattern** (lines 160-205):
```md
## Critical Gaps

1. **Missing Phase 1 verification artifact**
...

## Recommendation

Do not archive `v1.0` yet.

The milestone appears functionally complete in code, but the audit fails on missing verification evidence and stale requirements tracking. The shortest clean path is:

1. Create milestone gap-closure work for missing Phase 1 and Phase 3 verification artifacts.
2. Repair stale `REQUIREMENTS.md` and roadmap bookkeeping for Phase 3 and Phase 5.
...
```

**Apply in this phase**
- If refreshed, keep the same machine-readable front matter plus human-readable audit sections.
- Change status language from "orphaned" to satisfied only when the corresponding verification artifacts exist on disk and planning files are repaired.
- Preserve the distinction already present in this audit between code/runtime integrity and evidence/bookkeeping gaps.

## Shared Patterns

### Verification Report Shape
**Sources:** `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md:1-15`, `.planning/phases/02-meilisearch-core-sync/02-VERIFICATION.md:18-103`, `.planning/phases/05-reindexing-and-operational-workflows/05-VERIFICATION.md:89-104`

Apply to:
- `.planning/phases/01-core-contracts-and-api-shape/01-VERIFICATION.md`
- `.planning/phases/03-search-query-api-and-hydration/03-VERIFICATION.md`

Reuse these sections in order:
```md
### Observable Truths
### Required Artifacts
### Key Link Verification
### Data-Flow Trace (Level 4)
### Behavioral Spot-Checks
### Requirements Coverage
### Anti-Patterns Found
### Gaps Summary
```

### Requirement Closure Discipline
**Sources:** `.planning/REQUIREMENTS.md:76-112`, `.planning/v1.0-MILESTONE-AUDIT.md:111-141`, `.planning/ROADMAP.md:138-150`

Apply to:
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/v1.0-MILESTONE-AUDIT.md`

Concrete rule to preserve:
```md
Verification artifact exists on disk -> requirement can move to Complete
Summary-only history with no verification artifact -> remains an evidence gap
```

### Historical Ownership Preservation
**Sources:** `.planning/ROADMAP.md:13-19`, `.planning/ROADMAP.md:23-35`, `.planning/ROADMAP.md:63-84`, `.planning/ROADMAP.md:138-150`

Apply to:
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/v1.0-MILESTONE-AUDIT.md`

Concrete rule to preserve:
```md
Phase 1 owns SCMA-01..03 and BACK-02
Phase 3 owns SRCH-01..06
Phase 7 repairs evidence and bookkeeping; it does not become the shipping phase for those features
```

### Cross-File Consistency Pattern
**Sources:** `.planning/ROADMAP.md:3-19`, `.planning/STATE.md:1-18`, `.planning/v1.0-MILESTONE-AUDIT.md:118-141`

Apply to:
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/v1.0-MILESTONE-AUDIT.md`

Concrete fields to keep aligned:
```md
phase count
current/completed phase bookkeeping
verification presence by phase
requirement satisfaction counts
```

## No Analog Found

None. Every target file has a direct in-repo analog or is itself the authoritative pattern source for this artifact type.

## Metadata

**Analog search scope:** `.planning/`, especially existing `*-VERIFICATION.md` artifacts plus milestone bookkeeping files  
**Files scanned:** 8 artifact files (`07-RESEARCH.md`, `02-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `v1.0-MILESTONE-AUDIT.md`)  
**Pattern extraction date:** 2026-04-16
