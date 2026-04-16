---
phase: 05
slug: reindexing-and-operational-workflows
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/meilisearch_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/meilisearch_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 05-01 | 1 | OPER-03 | T-05-01 / T-05-02 | Settings declarations and runtime options target the intended index and reject invalid operational config. | unit | `mix test test/scrypath/options_test.exs test/scrypath/meilisearch_test.exs` | ✅ | ⬜ pending |
| 05-02-01 | 05-02 | 1 | OPER-03 | T-05-01 | Meilisearch index lifecycle helpers create indexes and apply settings to the target index only. | unit | `mix test test/scrypath/meilisearch_test.exs` | ✅ | ⬜ pending |
| 05-03-01 | 05-03 | 2 | OPER-01 | T-05-03 / T-05-04 | Backfill batches records deterministically, preserves boundaries, and upserts projected documents without skipping rows. | unit | `mix test test/scrypath/backfill_test.exs` | ❌ W0 | ⬜ pending |
| 05-04-01 | 05-04 | 3 | OPER-02 | T-05-01 / T-05-02 / T-05-05 | Managed reindex creates target index, applies settings, backfills, and cuts over in the correct order. | unit | `mix test test/scrypath/reindex_test.exs` | ❌ W0 | ⬜ pending |
| 05-04-02 | 05-04 | 3 | OPER-05 | T-05-05 | Docs state drift, cutover, failure, and recovery semantics plainly enough to avoid false operator assumptions. | manual | `rg -n \"reindex|backfill|drift|recovery|cutover\" README.md ARCHITECTURE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/backfill_test.exs` — batch backfill coverage for `OPER-01`
- [ ] `test/scrypath/reindex_test.exs` — managed workflow coverage for `OPER-02`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drift, cutover, and recovery guidance is explicit enough for operators to understand what success does and does not guarantee. | OPER-05 | Final documentation quality depends on wording and operational clarity, not only code behavior. | Read the README and ARCHITECTURE updates and confirm they explicitly distinguish backfill, managed reindex, accepted backend work, cutover, drift, and recovery steps. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
