---
phase: 105
slug: hermetic-e2e-pipeline
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-30
---

# Phase 105 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + Playwright (`@playwright/test`) |
| **Config file** | `examples/scrypath_ecommerce/config/test.exs`; planned `examples/scrypath_ecommerce/playwright.config.ts` |
| **Quick run command** | `cd examples/scrypath_ecommerce && mix test` |
| **Full suite command** | `mix verify --exclude integration` plus the Phase 105 E2E lane command created by this phase |
| **Estimated runtime** | ~300 seconds after the E2E lane exists |

---

## Sampling Rate

- **After every task commit:** Run the focused command named by the task, preferring `cd examples/scrypath_ecommerce && npx playwright test <focused spec>` once Playwright exists.
- **After every plan wave:** Run the full Phase 105 lane with Postgres, Meilisearch, Oban drain, Phoenix server, and Playwright enabled.
- **Before `$gsd-verify-work`:** Full suite must be green, including the advisory E2E lane.
- **Max feedback latency:** 300 seconds for the focused path; full lane runtime may exceed this only when service startup dominates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 105-01-01 | 01 | 0 | E2E-01 | T-105-01 / T-105-03 | Playwright is project-local and no production test bypass is introduced | config/e2e | `cd examples/scrypath_ecommerce && npx playwright test --list` | No W0 | pending |
| 105-01-02 | 01 | 0 | E2E-02 | T-105-03 | CI uses observable service readiness instead of fixed sleeps | CI integration | GitHub Actions Phase 105 lane or documented local equivalent | No W0 | pending |
| 105-02-01 | 02 | 1 | E2E-03 | T-105-02 | Storefront search assertions remain scoped to seeded tenant fixtures | e2e | `cd examples/scrypath_ecommerce && npx playwright test e2e/storefront.spec.ts` | No W0 | pending |
| 105-02-02 | 02 | 1 | E2E-04 | T-105-02 / T-105-03 | Related-data sync waits for queue and Meilisearch terminal state before browser assertions | e2e + backend helper | `cd examples/scrypath_ecommerce && npx playwright test e2e/storefront.spec.ts -g related` | No W0 | pending |
| 105-03-01 | 03 | 2 | E2E-05 | T-105-01 / T-105-02 | Failure injection remains test/dev-only and operator triage does not expose cross-tenant data | e2e + backend helper | `cd examples/scrypath_ecommerce && npx playwright test e2e/operator.spec.ts -g triage` | No W0 | pending |
| 105-04-01 | 04 | 2 | E2E-06 | T-105-02 / T-105-03 | Zero-downtime swap proof checks operator UI and stable backend outcome | e2e + backend helper | `cd examples/scrypath_ecommerce && npx playwright test e2e/operator.spec.ts -g swap` | No W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `examples/scrypath_ecommerce/package.json` — scripts and local dependency for Playwright.
- [ ] `examples/scrypath_ecommerce/playwright.config.ts` — baseline config with Phoenix server wiring and artifact policy.
- [ ] `examples/scrypath_ecommerce/e2e/storefront.spec.ts` — storefront and related-data placeholders or first passing slice.
- [ ] `examples/scrypath_ecommerce/e2e/operator.spec.ts` — operator triage and swap placeholders or first passing slice.
- [ ] `.github/workflows/ci.yml` or a dedicated workflow — advisory E2E lane with real Postgres and Meilisearch services plus artifact upload on failure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub-hosted lane stability before required-gate promotion | E2E-02 | Promotion policy needs observed CI history, not a single local command | Confirm the advisory lane has repeated green runs with failure artifacts available before making it required. |

---

## Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-105-01 | Test-only routes, hooks, or shortcuts exposed outside dev/test | Guard all E2E-only helpers with `Mix.env() in [:dev, :test]` or equivalent compile/runtime checks. |
| T-105-02 | Cross-tenant or cross-fixture search assertions hiding data leakage | Seed scoped fixtures and assert tenant-specific visible results and non-results. |
| T-105-03 | Flaky readiness producing false negatives or false greens | Use observable readiness: service health, committed fixtures, Oban drain, Meilisearch terminal task/search state, then Playwright expectations. |

---

## Validation Sign-Off

- [x] All tasks have automated verify targets or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution
