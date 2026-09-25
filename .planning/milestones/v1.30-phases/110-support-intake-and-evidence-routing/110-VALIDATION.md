---
phase: 110
slug: support-intake-and-evidence-routing
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 110 - Validation Strategy

> Per-phase validation contract for support-intake and evidence-routing hardening.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scrypath/phase110_contract_test.exs` |
| **Full suite command** | `mix verify.adopter` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/phase110_contract_test.exs` once the test exists.
- **After every plan wave:** Run `mix verify.adopter`.
- **Before `$gsd-verify-work`:** `mix verify.adopter` must be green.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-01 | 01 | 1 | SUP-01 | T-110-01 | Non-owner docs route compatibility/readiness authority to `guides/support-and-compatibility.md` without duplicating tuple matrices. | contract | `mix test test/scrypath/phase110_contract_test.exs` | W0 | pending |
| 110-01-02 | 01 | 1 | SUP-02 | T-110-02 | Outside-adopter template captures Class A-D and finding bucket routing evidence without maintainer guessing. | contract | `mix test test/scrypath/phase110_contract_test.exs` | W0 | pending |
| 110-02-01 | 02 | 1 | SUP-02 | T-110-03 | `mix verify.adopter` includes Phase 110 service-free contract proof and rejects unsupported arguments. | integration | `mix verify.adopter` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `ExUnit` is already configured.
- `mix verify.adopter` already runs service-free support/readiness proof in fast mode.
- Existing support contract tests provide analog patterns for direct file-read assertions.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Human review should still confirm that the final wording stays concise and does not create a heavyweight support workflow.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 30s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-31
