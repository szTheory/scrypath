---
phase: 04
slug: oban-and-observability
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-15
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/sync_test.exs test/scrypath/telemetry_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 04-01 | 1 | SYNC-05 | T-04-01 / T-04-03 | Reject invalid Oban readiness/config before enqueue dispatch. | unit | `mix test test/scrypath/sync_test.exs` | ✅ | ⬜ pending |
| 04-01-02 | 04-01 | 1 | SYNC-05 | T-04-01 | Build only JSON-safe, string-keyed Oban payloads from projected docs and delete ids. | unit | `mix test test/scrypath/oban/payload_test.exs` | ❌ W0 | ⬜ pending |
| 04-02-01 | 04-02 | 2 | SYNC-05 | T-04-04 / T-04-05 | Enqueue durable batch jobs without forcing Oban on non-Oban users. | unit | `mix test test/scrypath/sync_test.exs test/scrypath/oban/enqueue_test.exs` | ❌ W0 | ⬜ pending |
| 04-02-02 | 04-02 | 2 | SYNC-05 | T-04-04 / T-04-06 | Workers validate persisted args and cancel terminal payload/config errors instead of retrying forever. | unit | `mix test test/scrypath/oban_test.exs test/scrypath/oban/worker_test.exs` | ❌ W0 | ⬜ pending |
| 04-03-01 | 04-03 | 3 | OPER-04 | T-04-07 | Common sync, search, and hydration spans emit low-cardinality metadata only. | unit | `mix test test/scrypath/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 04-03-02 | 04-03 | 3 | OPER-04 / SYNC-05 | T-04-08 / T-04-09 | Backend-specific spans and async docs preserve explicit queue and consistency semantics. | unit | `mix test test/scrypath/telemetry_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/oban/payload_test.exs` — payload contract coverage for `SYNC-05`
- [ ] `test/scrypath/oban/enqueue_test.exs` — enqueue contract coverage for `SYNC-05`
- [ ] `test/scrypath/oban_test.exs` — transactional helper coverage for `SYNC-05`
- [ ] `test/scrypath/oban/worker_test.exs` — worker retry/cancel coverage for `SYNC-05`
- [ ] `test/scrypath/telemetry_test.exs` — common and backend span coverage for `OPER-04`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Oban-backed sync lifecycle is explained clearly enough for operators to distinguish enqueue acceptance from search visibility. | SYNC-05 | Final wording quality and operational clarity live in docs, not only code. | Read README and ARCHITECTURE updates, then confirm they explicitly describe `inline`, `manual`, and `oban` guarantees plus `retrying` and `discarded` outcomes. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15
