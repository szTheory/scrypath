---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T22:41:32Z
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

**Reviewed:** 2026-10-27T22:41:32Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed all 24 in-scope files against base `ba624a7452e717c335a26369b8db8523d2551ee9` at current `HEAD` `f83b84e94070f8cf848151cd83d64c9276931278` (9,155 insertions and 411 deletions in the scoped diff). The full-phase review's WR-02 settings-locator defect is fixed by `30becbc45616d957678c9a0051a1299e0800203b`. The only source change since accepted implementation `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` is that assertion line in `admin_screenshots.spec.ts`; its source-derived RED/GREEN reproduction confirms the numeric-locator failure is corrected. The 115 Node behavior tests also pass with zero skips.

Current-source browser acceptance at `f83b84e94070f8cf848151cd83d64c9276931278` is pending. The earlier 0b7 full-browser cohort remains bound to 0b7, not relabeled as proof for this assertion change. Its cache cohort remains bound to its original source; cache implementation/configuration, locks, Dockerfiles and BEAM graph inputs are unchanged, so the project’s named-invalidator policy retains that evidence at its recorded cutoff. The prior documentation-head closeout at `cac118591f41feb5199e9ab3d1499d6e1c3a01e6` passed the five required jobs, coverage, attestation and default-policy 189/189 browser run; that run was not strict warm-cache proof and predates this correction. Fresh local full, hosted warm/full proof and actual child/root closeouts remain pending. No CI was dispatched and the retained preview was not changed.

WR-03 remains visible as deferred. The two upload names are unchanged from the review base and do not block the current fresh-run closeout path; same-run rerun support will require coordinated changes to artifact names and `ci_monitor`.

## Narrative Findings (AI reviewer)

## Warnings

### WR-03: Artifact uploads reuse names on workflow reruns

**Severity:** WARNING
**Disposition:** Deferred; this is a baseline-only limitation, not a Phase 182 source regression.
**File:** `.github/workflows/ci.yml:573,622`
**Issue:** The coverage and closeout-attestation uploads use names containing only `github.sha`. Since upload-artifact does not overwrite an existing immutable artifact name by default, a rerun of the same workflow run at that SHA can collide with the previous attempt. Both names are identical at base `ba624a74`. Phase 182 browser/cache artifact identities already include run/attempt, closeout dispatches use fresh run IDs, and retries are not eligible as clean proof; therefore this does not block the supported closeout path. The canonical disposition keeps this issue deferred, not accepted as human risk approval.
**Fix:** When adding same-run rerun support, suffix both names with `${{ github.run_id }}-${{ github.run_attempt }}` and update `ci_monitor` artifact selection/consumers and their tests in the same change.

#### Closed historical findings (preserved disposition; not open)

- **WR-02 — Settings screenshot assertion targets numeric text:** fixed by `30becbc4`. RED reproduced the numeric-`0` locator failure; GREEN matched both intended status strings and rejected numeric text. See `assertion-selector-red.log` and `assertion-selector-green.log`.
- **CR-01 — IPv6 loopback bypasses retained-preview refusal:** fixed by `b6bf7bf0` with executable regression coverage.
- **CR-02 — Lock-change proof passes on a forced cache miss:** fixed by `01d1f871` with exact-byte, canonical-identity and natural-key checks.
- **CR-03 — Mandatory inventory accepts one case from each required suite:** fixed by `edd47eee` with all required stable UI identities enforced.
- **WR-01 — Fixture route readiness treats redirects as success:** fixed by `2f615705` with 2xx-only readiness checks.

These five findings are closed at this review’s source cutoff. The earlier full-browser and cache receipts remain tied to their recorded source cutoffs; this report makes no current-source browser-acceptance or phase-completion claim.

---

_Reviewed: 2026-10-27T22:41:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
