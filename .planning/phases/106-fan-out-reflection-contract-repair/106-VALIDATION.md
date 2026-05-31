---
phase: 106
slug: fan-out-reflection-contract-repair
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 106 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/schema_test.exs test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` |
| **Full suite command** | `mix verify.phase106` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/schema_test.exs test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs`
- **After every plan wave:** Run `mix verify.phase106`
- **Before `$gsd-verify-work`:** `mix verify.phase106` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 106-01-01 | 01 | 1 | FAN-01 | T-106-001 | Ordinary schemas expose only declared fan-out metadata through `__scrypath__(:fan_outs)` | unit | `mix test test/scrypath/schema_test.exs` | ✅ | ✅ green |
| 106-01-02 | 01 | 1 | FAN-01, FAN-02 | T-106-002 | Inline and Oban paths consume declared fan-out metadata without bypass helpers | unit | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ | ✅ green |
| 106-01-03 | 01 | 1 | FAN-01, FAN-02 | T-106-003 | Focused phase gate runs only deterministic service-free proof | task | `mix verify.phase106` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. ExUnit, fake backends, and Oban job struct coverage already exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | FAN-01, FAN-02 | All phase behaviors have automated verification. | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved after retroactive Nyquist audit

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |

Resolved gaps:

- `test/scrypath/sync/related_test.exs` now proves the fake Oban adapter receives insert calls for both hand-written and generated fan-out enqueue paths.
- `test/scrypath/sync/related_worker_test.exs` now fails explicitly if `Oban.Worker` is unavailable instead of compiling to zero worker contract tests.
- `lib/mix/tasks/verify.phase106.ex` validates the no-argument contract before `app.start`.
