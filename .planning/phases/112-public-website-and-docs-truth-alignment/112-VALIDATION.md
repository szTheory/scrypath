---
phase: 112
slug: public-website-and-docs-truth-alignment
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-01
---

# Phase 112 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/phase112_contract_test.exs test/mix/tasks/verify.phase112_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds for focused tests, project-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/phase112_contract_test.exs`
- **After every plan wave:** Run `mix verify.phase112`
- **Before `$gsd-verify-work`:** `mix verify.phase112` and relevant focused tests must be green
- **Max feedback latency:** 30 seconds for focused contract proof

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | WEB-01 | T-112-01 | Public claim envelope stays precise and misleading hosted/AI/magic/public-multi-backend/immediate-visibility claims are rejected | docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | No - Wave 0 | pending |
| 112-01-02 | 01 | 1 | WEB-02 | T-112-02 | Website remains route-map/front-door copy and routes users to canonical README, guides, examples, Hex, and GitHub surfaces | docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | No - Wave 0 | pending |
| 112-01-03 | 01 | 1 | SCOPE-01 | T-112-03 | Reopen policy authority states the three allowed triggers and preserves current out-of-scope classes | docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | No - Wave 0 | pending |
| 112-02-01 | 02 | 2 | WEB-01, WEB-02, SCOPE-01 | T-112-04 | Service-free verification command runs the focused contract proof without live services, browser automation, or external credentials | mix-task | `mix test test/mix/tasks/verify.phase112_test.exs && mix verify.phase112` | No - Wave 0 | pending |

---

## Wave 0 Requirements

- [ ] `test/scrypath/phase112_contract_test.exs` - focused public truth and route-map contract tests for WEB-01, WEB-02, and SCOPE-01.
- [ ] `lib/mix/tasks/verify.phase112.ex` - service-free phase verification task.
- [ ] `test/mix/tasks/verify.phase112_test.exs` - task wiring proof.
- [ ] `mix.exs` - preferred environment registration for `verify.phase112` if needed by local task conventions.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final copy quality review | WEB-01, WEB-02, SCOPE-01 | Automated tests can prove guardrails and links, but cannot fully judge tone and usefulness | Read changed public copy in README, website pages, and `guides/scope-and-reopen-policy.md`; confirm it is concise, plain, and does not duplicate guide bodies |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target < 30s for focused contract proof
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
