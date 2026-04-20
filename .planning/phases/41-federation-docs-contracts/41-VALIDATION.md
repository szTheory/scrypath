---
phase: 41
slug: federation-docs-contracts
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix verify.phase41` |
| **Full suite command** | `mix test --exclude integration` |
| **Estimated runtime** | ~30–90 seconds (depends on focused file list) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.phase41`
- **After every plan wave:** Run `mix verify.phase41`
- **Before `/gsd-verify-work`:** `mix test --exclude integration` green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | FED-03 | — | N/A (build-only) | compile | `mix compile --warnings-as-errors` | ✅ | ✅ green |
| 41-01-02 | 01 | 1 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-01-03 | 01 | 1 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-01-04 | 01 | 1 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-01-05 | 01 | 1 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-02-01 | 02 | 2 | FED-03 | T-41-02-01 | Honest docs — no executable boundary | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-02-02 | 02 | 2 | FED-03 | T-41-02-01 | Honest docs | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-02-03 | 02 | 2 | FED-03 | — | N/A (markdown) | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-02-04 | 02 | 2 | FED-03 | — | N/A (`@doc`) | compile | `mix compile --warnings-as-errors` | ✅ | ✅ green |
| 41-02-05 | 02 | 2 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ✅ green |
| 41-02-06 | 02 | 2 | FED-03 | — | N/A (`.planning/`) | unit | `mix verify.phase41` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Primary automated surface: `test/scrypath/docs_contract_test.exs` (via `mix verify.phase41` focused list in `lib/mix/tasks/verify.phase41.ex`).

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc readability | FED-03 | Not asserted in CI | `mix docs && open doc/index.html` optional |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-04-20 — retroactive close after `mix verify.phase41` (40 tests, 0 failures) and plan/summary review.

---

## Validation Audit 2026-04-20

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

*Notes: Prior map listed a non-existent plan `03` (`41-03-01`); replaced with eleven rows aligned to `41-01-PLAN.md` and `41-02-PLAN.md` tasks. No new ExUnit files required — coverage already shipped in phase execution.*
