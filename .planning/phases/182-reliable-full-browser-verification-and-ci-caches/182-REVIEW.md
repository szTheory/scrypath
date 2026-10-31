---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T23:55:36Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - .dockerignore
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - examples/scrypath_ecommerce/compose.e2e.yaml
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs
  - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
  - examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts
  - examples/scrypath_ecommerce/playwright.config.ts
  - examples/scrypath_ecommerce/scripts/verify-e2e.sh
  - scripts/ci/beam_cache.cjs
  - scripts/ci/beam_cache.test.cjs
  - scripts/ci/ecommerce_build.cjs
  - scripts/ci/ecommerce_build.test.cjs
  - scripts/ci/ecommerce_evidence.cjs
  - scripts/ci/ecommerce_evidence.test.cjs
  - scripts/ci/ecommerce_lifecycle.test.cjs
  - scripts/ci/ecommerce_target.test.cjs
  - scripts/ci/phase105_evidence.sh
  - scripts/ci/phase182_acceptance.cjs
  - scripts/ci/phase182_acceptance.test.cjs
  - test/mix/tasks/workflow_wiring_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T23:55:36Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

The standard-depth review covers the original 24 non-planning files against base `ba624a7452e717c335a26369b8db8523d2551ee9`; the current scoped diff is 9,263 insertions and 411 deletions. This reconciliation reviews the subsequent assertion correction and the 108-line test-only addition to `scripts/ci/ecommerce_evidence.test.cjs`. At current `HEAD` `091e16c6ed7bb39577c0af6d3418a4e965653773`, that test is the only non-planning change since `1c72637038f2c225d56e2311678b05f912b014f3`; production code, workflow, browser/cache inputs and acceptance predicates are unchanged. No new review finding was found.

The three new behavior tests exercise the canonical evidence boundary with explicitly synthetic fixtures: approval-shaped input metadata is absent from the receipt and summary, a synthetic claim inserted into the stored receipt yields `receipt_mismatch`, and an appended claim in the Markdown summary yields `summary_mismatch`. The latter two cases verify both the validation API and CLI failure status. The focused suite passed 23/23 and the existing six-suite Node path passed 118/118, with no skips. These checks cover serialization and recomputation safeguards; they do not establish a real reviewer identity, independent human approval, or generalized LLM honesty.

Runtime evidence remains bound to its original cutoffs. Local full and hosted warm/full browser proof remain at `1c72637038f2c225d56e2311678b05f912b014f3` (189/189 first attempts); the five-mode cache cohort remains at `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` (seven invocations, six eligible, with the initial no-hit producer preserved); and child documentation closeout remains at `04e9a8809f3dcd4b590a30dee8301086a8122597`, run 40600930723. The test-only addition changes none of those proof inputs, and no new or mixed-SHA acceptance claim is made.

The prior native goal-verifier report remains `human_needed` because the test-tier prohibition against fabricated independent-review approval lacked an explicit wired assertion. The new tests directly cover that gap, but this report does not override or replace the verifier; its CLI-owned re-evaluation and covered-input fingerprint remain pending. No human approval or phase completion is claimed. WR-03 remains the one deferred baseline warning; known deep-quality dependency-audit debt remains assigned to Phase 184.

## Narrative Findings (AI reviewer)

## Warnings

### WR-03: Artifact uploads reuse names on workflow reruns

**Severity:** WARNING
**Disposition:** Deferred in the canonical disposition ledger; this is a baseline-only limitation, not a Phase 182 source regression.
**File:** `.github/workflows/ci.yml:573,622`
**Issue:** Coverage and closeout-attestation artifact names contain only `github.sha`; upload-artifact does not overwrite an existing immutable artifact name by default, so rerunning the same workflow run at the same SHA can collide with the prior attempt. These names are unchanged from base `ba624a74`. The supported closeout collector dispatches a fresh run, Phase 182 browser/cache artifacts bind run and attempt, and retries are ineligible as clean proof, so this does not block the current closeout path. The deferred disposition is not human risk approval.
**Fix:** When adding same-run rerun support, include `${{ github.run_id }}-${{ github.run_attempt }}` in both names and update `ci_monitor` artifact selection/consumers and their tests together.

#### Closed historical findings (preserved disposition; not open)

- **WR-02 — Settings screenshot assertion targets numeric text:** fixed by `30becbc4`; source-derived RED/GREEN evidence is recorded in `assertion-selector-red.log` and `assertion-selector-green.log`.
- **CR-01 — IPv6 loopback bypasses retained-preview refusal:** fixed by `b6bf7bf0` with executable regression coverage.
- **CR-02 — Lock-change proof passes on a forced cache miss:** fixed by `01d1f871` with exact-byte, canonical-identity and natural-key checks.
- **CR-03 — Mandatory inventory accepts one case from each required suite:** fixed by `edd47eee` with all required stable UI identities enforced.
- **WR-01 — Fixture route readiness treats redirects as success:** fixed by `2f615705` with 2xx-only readiness checks.

These five findings are closed or deferred in the canonical disposition; they are preserved as history and are not reopened or reused.

---

_Reviewed: 2026-10-27T23:55:36Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
