---
phase: 68
slug: example-proof-and-support-contract
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-22
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with repo-local Mix verify tasks and docs-contract coverage |
| **Config file** | `test/test_helper.exs` and `examples/phoenix_meilisearch/test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix docs --warnings-as-errors && cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Run `mix docs --warnings-as-errors && cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 1 | INTG-03 | T-68-01 | Support contract only states runtime/service combinations defended by repo docs and CI truth | docs contract + docs build | `mix test test/scrypath/docs_contract_test.exs && mix docs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 68-01-02 | 01 | 1 | INTG-04 | T-68-02 | README, guides, CONTRIBUTING, and example README keep one canonical link path and startup/env facts | docs contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 68-02-01 | 02 | 2 | INTG-01 | T-68-06 | Example app proves `:manual` without overstating visibility or support guarantees | integration | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` | ❌ W0 | ⬜ pending |
| 68-02-02 | 02 | 2 | INTG-01, INTG-04 | T-68-04 | Example README command order, env vars, and CI-vs-local truth stay aligned with tests and smoke script | docs contract + integration | `mix test test/scrypath/docs_contract_test.exs && cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `guides/support-and-compatibility.md` — canonical support guide for INTG-03
- [ ] `mix.exs` / `guides/overview.md` wiring — publish and surface the support guide
- [ ] `examples/phoenix_meilisearch/test/smoke/*manual*.exs` or equivalent — targeted `:manual` proof path for INTG-01
- [ ] `test/scrypath/docs_contract_test.exs` Phase-68 assertions — bounded link/env/startup-order coverage for INTG-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review the support guide wording against `.github/workflows/ci.yml`, `mix.exs`, and the example README before merge | INTG-03 | Tests can prove link/fact presence, but maintainers still need to confirm the prose does not imply broader support than CI/example truth | Read the new guide and compare its support claims to current CI matrix, example service pins, and README links |
| Run the local example smoke once after docs and test updates land together | INTG-01, INTG-04 | CI proves the `mix test` path, but the local smoke harness also needs a human spot-check because it is part of the promised runbook | `cd examples/phoenix_meilisearch && ./scripts/smoke.sh` and verify the documented startup order still matches real behavior |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
