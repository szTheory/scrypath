---
phase: "182"
slug: "reliable-full-browser-verification-and-ci-caches"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 182 — Validation Strategy

Planning contract only; no implementation, test pass, cache hit or hosted acceptance is claimed.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit repository contracts, Node built-in checks and Playwright Chromium |
| Config | `mix.exs`, `test/test_helper.exs`, `examples/scrypath_ecommerce/playwright.config.ts` |
| Quick command | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs` |
| Full contract command | `MIX_ENV=test mix verify.repository_contracts` |
| Browser command | `make -C examples/scrypath_ecommerce verify-e2e` |
| Estimated runtime | Measure during execution; hosted full job including finalization must stay within 1,800 seconds |

Use the configured BEAM tuple explicitly if the shell has no active tool version. The researcher observed Docker availability but no selected local Elixir/Mix version. Tool availability is separate from passing verification.

## Sampling Rate

- After each task, run its focused behavior checks and compile changed test infrastructure with warnings as errors.
- After each wave, run `MIX_ENV=test mix verify.repository_contracts`.
- Before phase completion, run the CONTRIBUTING warning-as-error suite and affected canonical gates, plus the real Docker and exact-source hosted acceptance below.
- Target fast contract feedback within 120 seconds; measure actual runtime. Long browser/cache runs are explicit integration acceptance, never substitutes for quick contracts.
- Every task must have an automated check and stated observable failure signal. No three consecutive tasks may lack fast feedback.

## Per-Task Verification Map

The planner must replace these requirement-level seed rows with actual plan/task IDs, waves, commands and unique threat references before plan verification.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Seed BROW-01 | pending | pending | BROW-01 | pending register | Owned disposable stack; bounded routes and cleanup | Contract + Docker | Focused ExUnit command above; canonical full and mounted Docker verifiers | Existing harness; new cases required | pending |
| Seed BROW-02 | pending | pending | BROW-02 | pending register | Preview refusal before mutations; complete case identities | Contract + browser | Guard truth-table and synthetic inventory checks; canonical full verifier | New behavior cases required | pending |
| Seed BROW-03 | pending | pending | BROW-03 | pending register | Strict run-owned receipt and exact source/image joins | Contract + hosted | Synthetic missing/malformed/retry/skip/copy-failure checks; successful changed-SHA full hosted run | New behavior cases required | pending |
| Seed CACHE-01 | pending | pending | CACHE-01 | pending register | Trusted exports; source/model/image parity | Contract + Docker/hosted | Build graph/handoff checks; real warm export/import and fresh-builder import-disabled build | New proof required | pending |
| Seed CACHE-02 | pending | pending | CACHE-02 | pending register | ABI/environment/graph-scoped outputs; download-only fallback | Contract + hosted | Cache key invalidation/fallback tests; representative cold-cache job | New behavior cases required | pending |

## Wave 0 Requirements

- Extend existing repository-contract infrastructure with behavior tests for full/focused scope, route readiness, preview refusal, original exit preservation, copy errors and owned cleanup.
- Add small synthetic inventory/report fixtures for missing/duplicate identities, empty/malformed reports, expected-failure masking, retries and reasoned skips.
- Add executable cache boundary checks over graph/manifests/locks, exact tuple, environment, target/profile, source refresh and trusted writer policy.
- Use existing test frameworks and lanes. Do not relocate maintainer tasks, install a cache abstraction, change support tuples or activate the paid judge.

## Integration Acceptance

All behaviors have executable acceptance; none relies on post-implementation human UAT.

- Full Docker verification exercises mounted and standalone fixture routes and intended follow-up/iteration-3 cases. Focused verification retains its existing service scope.
- Changed-source scheduled/manual hosted full verification completes within the 30-minute total budget, with raw verifier success, complete inventory reconciliation and required bounded artifacts, seven-day retention, image/checkout/event identity and successful owned cleanup.
- Docker warm restore/export and a genuinely fresh builder with cache import disabled produce separate receipts. BEAM compatible download fallback, lock invalidation and representative cold execution produce separate receipts. Shared caches are not deleted.
- A retry pass is not clean stability evidence. Advisory job conclusions, synthetic reports and cache configuration alone cannot establish these integration claims.

## Validation Sign-Off

- [ ] Actual task IDs, waves and threat references mapped after planning
- [ ] All tasks have automated verification and immediate failure signals
- [ ] New behavior checks exist before dependent implementation tasks
- [ ] No three consecutive tasks lack automated feedback
- [ ] Full inventory, hosted proof and separate warm/cold acceptance are executable
- [ ] No watch-mode commands or pending UAT used as completion evidence
- [ ] Actual runtime measured and feedback/deadline margins recorded
- [ ] `nyquist_compliant: true` set only after validation confirms compliance

**Approval:** pending; this draft records no maintainer approval or independent review.
