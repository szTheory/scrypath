---
phase: 147
slug: ecommerce-mounted-ops-remediation-and-closure-evidence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-25
---

# Phase 147 — Validation Strategy

> Per-phase validation contract for ecommerce dependency remediation and four-graph closure evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix; Playwright for advisory browser proof |
| **Config file** | `examples/scrypath_ecommerce/mix.exs`; `playwright.config.ts` |
| **Quick run command** | `cd examples/scrypath_ecommerce && mix test <focused-existing-test>` (exact test selected during planner inspection) |
| **Full suite command** | `cd examples/scrypath_ecommerce && mix precommit` plus the required root suite from `CONTRIBUTING.md` |
| **Estimated runtime** | To be measured and recorded with the closure receipts |

---

## Sampling Rate

- **After every dependency edit:** Inspect the ecommerce manifest/lock diff and run isolated checked-lock and mounted-path receipts.
- **Before the ecommerce commit:** Run the complete deterministic gate bundle and stop on any drift or failure.
- **After the ecommerce commit:** Run exact-SHA detached proof, validate safe cleanup, then capture the four-graph same-window closure rows.
- **Before `$gsd-verify-work`:** Required deterministic and service evidence must pass; browser evidence must be classified truthfully as passed, failed, or unavailable.
- **Max feedback latency:** Record measured command durations; no three consecutive implementation tasks may lack automated evidence.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 147-01-01 | 01 | 1 | SEC-04 | T-147-01, T-147-02 | Approved bounds resolve without advisories and mounted dependencies resolve to the intended local sources | resolver/integration | Isolated `mix deps.get`, range assertion, `Mix.Project.deps_paths/0`, and `mix hex.audit` | ❌ W0 receipt commands | ⬜ pending |
| 147-01-02 | 01 | 1 | COMPAT-01 | T-147-01 | Ecommerce compile, focused regression, and precommit checks pass before commit | integration/regression | `mix compile --warnings-as-errors`, selected focused test, and `mix precommit` in `examples/scrypath_ecommerce` | ✅ commands exist | ⬜ pending |
| 147-02-01 | 02 | 2 | COMPAT-03 | T-147-03 | Browser proof is reported separately and never upgraded from unavailable to passing | browser/manual classification | `npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1` when prerequisites exist | ✅ specs/config exist | ⬜ pending |
| 147-02-02 | 02 | 2 | EVID-01 | T-147-03, T-147-05 | Each graph has a dated checked-lock/audit row with selected versions and honest outcome | evidence | `mix deps.get --check-locked && mix hex.audit` in root, legacy Phoenix, ScrypathOps, and ecommerce | ❌ W0 ledger | ⬜ pending |
| 147-02-03 | 02 | 2 | EVID-02 | T-147-03, T-147-04 | Ordered graph-local commits and causal manifest/lock changes are auditable without unsafe cleanup | repository/evidence | `git diff`, `git diff-tree`, `git merge-base --is-ancestor`, exact-SHA detached proof, and cleanup assertions | ❌ W0 ledger | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Define a non-persistent receipt block that exports both isolation variables for every ecommerce proof command.
- [ ] Define a compact, redacted four-graph closure matrix and ordered-batch topology ledger in phase evidence.
- [ ] Inspect existing ecommerce tests and select the narrowest route/asset/link regression command; do not create a speculative test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser proof classification | COMPAT-03 | Browser and service prerequisites may be absent in the execution environment | Record prerequisites and command; classify the outcome as passed, failed, or unavailable without treating unavailable as required proof passing |
| Four-graph closure review | EVID-01, EVID-02 | Maintainer must audit graph-local history and the explanation for each causal manifest/lockfile change | Review dated rows, lock hashes, selected versions, audit output, four ordered commits, and the before-next-batch gate evidence |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing receipt and ledger references
- [ ] No watch-mode flags
- [ ] Feedback latency is measured and acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
