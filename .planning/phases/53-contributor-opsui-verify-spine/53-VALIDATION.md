---
phase: 53
slug: contributor-opsui-verify-spine
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / OTP 28 per CI) |
| **Config file** | `test/test_helper.exs` (project default) |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | docs_contract only ~10–30s; full suite minutes |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Same, plus `mix format --check-formatted` when Elixir sources change
- **Before `/gsd-verify-work`:** `mix test` green at least once on the branch
- **Max feedback latency:** ~120s for targeted path

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | VRFY-04 | T-53-01 | No secrets in @moduledoc | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 53-02-01 | 02 | 1 | VRFY-04 | T-53-02 | No third-party URLs in new README line | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 53-03-01 | 03 | 2 | VRFY-03, VRFY-04 | T-53-03 | Hygiene: no `VRFY-` in published md | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements — no new test harness.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix help` lists `verify.opsui` | VRFY-04 | Mix CLI output varies by terminal | After Plan 01: run `mix help` from repo root; visually confirm `verify.opsui` line present. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify via docs_contract or format check
- [ ] Sampling continuity: doc-contract run after each wave
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
