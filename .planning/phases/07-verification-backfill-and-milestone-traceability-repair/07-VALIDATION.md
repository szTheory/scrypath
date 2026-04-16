---
phase: 07
slug: verification-backfill-and-milestone-traceability-repair
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | SCMA-01, SCMA-02, SCMA-03, BACK-02 | T-07-01 | Verification claims stay tied to current source and focused test results rather than summaries alone | unit | `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs` | ✅ | ⬜ pending |
| 07-01-02 | 01 | 1 | SCMA-01, SCMA-02, SCMA-03, BACK-02 | T-07-02 | Phase 1 verification wording stays audit-safe and keeps ownership on Phase 1 rather than Phase 7 | artifact review | `rg -n '## Goal Achievement|## Requirements Coverage|## Anti-Patterns Found|## Gaps Summary' .planning/phases/01-core-contracts-and-api-shape/01-VERIFICATION.md` | ✅ | ⬜ pending |
| 07-02-01 | 02 | 1 | SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | T-07-01 / T-07-02 | Search verification preserves option validation, pagination, raw-hit access, and missing-id visibility in evidence | unit | `mix test test/scrypath/search_test.exs test/scrypath/hydration_test.exs test/scrypath/meilisearch_test.exs` | ✅ | ⬜ pending |
| 07-02-02 | 02 | 1 | SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | T-07-05 / T-07-06 | Phase 3 verification wording stays audit-safe and keeps ownership on Phase 3 rather than Phase 7 | artifact review | `rg -n '## Goal Achievement|## Requirements Coverage|## Anti-Patterns Found|## Gaps Summary|### Data-Flow Trace' .planning/phases/03-search-query-api-and-hydration/03-VERIFICATION.md` | ✅ | ⬜ pending |
| 07-03-01 | 03 | 2 | SCMA-01, SCMA-02, SCMA-03, BACK-02, SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | T-07-03 | Requirement closure and milestone bookkeeping only move after verification artifacts exist and point back to original shipping phases | artifact review | `rg -n 'SCMA-01|SCMA-02|SCMA-03|BACK-02|SRCH-01|SRCH-02|SRCH-03|SRCH-04|SRCH-05|SRCH-06' .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/v1.0-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |
| 07-03-02 | 03 | 2 | SCMA-01, SCMA-02, SCMA-03, BACK-02, SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | T-07-08 / T-07-09 | Milestone audit scores and narratives reflect repaired evidence state without stale orphaned scores or false Phase 7 ownership | artifact review | `rg -n 'requirements: 24/24|phases: 6/6|01-VERIFICATION.md|03-VERIFICATION.md|evidence gap|bookkeeping' .planning/v1.0-MILESTONE-AUDIT.md && ! rg -n 'requirements: 14/24|phases: 4/6' .planning/v1.0-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verification and audit narratives accurately distinguish evidence gaps from runtime gaps | SCMA-01, SCMA-02, SCMA-03, BACK-02, SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05, SRCH-06 | Narrative truthfulness is document-level and needs human review in addition to grep/test proofs | Read `01-VERIFICATION.md`, `03-VERIFICATION.md`, and `.planning/v1.0-MILESTONE-AUDIT.md`; confirm they cite current code/tests and do not attribute shipped features to Phase 7 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-16
