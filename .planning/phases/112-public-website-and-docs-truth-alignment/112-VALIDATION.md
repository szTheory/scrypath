---
phase: 112
slug: public-website-and-docs-truth-alignment
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
updated: 2026-06-01
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
| 112-01-01 | 01 | 1 | WEB-01, SCOPE-01 | T-112-01, T-112-02, T-112-03 | Canonical scope-and-reopen policy is published through ExDoc and contains the exact trigger and out-of-scope contract tokens | docs-contract | `mix docs --warnings-as-errors`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-01-02 | 01 | 1 | WEB-01, SCOPE-01 | T-112-01, T-112-02 | README, support guidance, and outside-adopter intake route scope pressure to the canonical policy owner without duplicating policy bodies | docs-contract | `mix docs --warnings-as-errors`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-02-01 | 02 | 2 | WEB-01, WEB-02, SCOPE-01 | T-112-04 | Guide map and sync-semantics surfaces use the Ecto-native claim envelope and route feature-scope pressure to the policy guide | docs-contract | `mix docs --warnings-as-errors`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-02-02 | 02 | 2 | WEB-01, WEB-02, SCOPE-01 | T-112-05 | Operator-support and JTBD docs preserve done posture and the exact three-trigger reopen rule | docs-contract | `mix docs --warnings-as-errors`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-03-01 | 03 | 2 | WEB-01, WEB-02 | T-112-06, T-112-07, T-112-08 | Homepage and docs map keep route-first website copy, canonical README/scope-policy routes, and package routes through the shared layout | website-contract | `npm --prefix website run build && npm --prefix website run check`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-03-02 | 03 | 2 | WEB-01, WEB-02, SCOPE-01 | T-112-06, T-112-08 | Evaluate and operators pages preserve visibility honesty and evidence-gated scope routing while avoiding runbook-depth tokens | website-contract | `npm --prefix website run build && npm --prefix website run check`; `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-04-01 | 04 | 3 | WEB-01, WEB-02, SCOPE-01 | T-112-09 | Focused Phase 112 contract tests cover claim envelope, route-map links, misleading-claim negatives, and website runbook-depth boundaries | docs-contract | `mix test test/scrypath/phase112_contract_test.exs` | Yes | covered |
| 112-04-02 | 04 | 3 | WEB-01, WEB-02, SCOPE-01 | T-112-10, T-112-11 | `mix verify.phase112` runs the focused proof without services, rejects args, and is discoverable from preferred envs and CONTRIBUTING | mix-task | `mix test test/mix/tasks/verify.phase112_test.exs && mix verify.phase112` | Yes | covered |

---

## Wave 0 Requirements

- [x] `test/scrypath/phase112_contract_test.exs` - focused public truth and route-map contract tests for WEB-01, WEB-02, and SCOPE-01.
- [x] `lib/mix/tasks/verify.phase112.ex` - service-free phase verification task.
- [x] `test/mix/tasks/verify.phase112_test.exs` - task wiring proof.
- [x] `mix.exs` - preferred environment registration for `verify.phase112` if needed by local task conventions.

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

**Approval:** approved after retroactive Nyquist validation audit on 2026-06-01.

## Validation Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Audit Evidence

- `mix test test/scrypath/phase112_contract_test.exs` - 4 tests, 0 failures
- `mix test test/mix/tasks/verify.phase112_test.exs` - 4 tests, 0 failures
- `mix verify.phase112` - 8 tests, 0 failures
- `npm --prefix website run build && npm --prefix website run check` - passed
- `mix docs --warnings-as-errors` - passed
