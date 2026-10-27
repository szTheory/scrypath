---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T23:34:55Z
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

**Reviewed:** 2026-10-27T23:34:55Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed all 24 in-scope files against base `ba624a7452e717c335a26369b8db8523d2551ee9`; the scoped implementation diff contains 9,155 insertions and 411 deletions. The current repository HEAD is `c9d778bd40e37a05c32d82f46003bd99b5b61ef6`, and its non-planning source is byte-identical to the accepted assertion source `1c72637038f2c225d56e2311678b05f912b014f3`. The only implementation delta from the previously accepted `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` is the one settings-assertion line in `admin_screenshots.spec.ts`.

The full-phase review's WR-02 numeric-locator defect is fixed by `30becbc45616d957678c9a0051a1299e0800203b`. The source-derived RED check reproduced the numeric-`0` locator, and GREEN verifies that both intended status strings match while numeric text does not. The recorded 115 Node behavior checks passed with zero skips.

Current-source evidence at `1c72637038f2c225d56e2311678b05f912b014f3` is now complete for the changed browser input. The local full archive validated at 189 cases in 189 first attempts. The current hosted session validated two eligible invocations: strict Docker warm run [40597095307](https://github.com/szTheory/scrypath/actions/runs/40597095307) and full browser run [40598906757](https://github.com/szTheory/scrypath/actions/runs/40598906757), each with 189 first attempts and no skips, retries or flakes. Strict warm proof recorded imports, useful hits and exports for all three targets. Maximum browser-end-to-upload time was 22 seconds; with the required 60-second margin this remains within the 300-second reserve.

The complete five-mode cache cohort remains bound to `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8`: seven recorded invocations, six eligible, with the initial no-hit producer preserved as ineligible. The new current-source warm refresh covers the changed browser image input. Cold and BEAM evidence retain their earlier source cutoff; cache code/configuration, Dockerfiles, locks and BEAM source inputs are unchanged. Reconstructed BEAM identity from current bytes matches the original hosted identity, and the changed spec is excluded from all four BEAM graphs. No mixed-SHA aggregate or current-SHA five-mode cache claim is made.

Child documentation closeout at `04e9a8809f3dcd4b590a30dee8301086a8122597` passed run 40600930723: all five required jobs, coverage, immutable attestation and raw full 189/189. Its default-policy import-only observation is not strict warm-cache acceptance. Fresh merged checks passed 115 Node tests, 961 Elixir tests plus five properties, 98 repository contracts, formatting, actionlint and documentation checks. All 16 Nyquist tasks are covered and 20 authored L1 security controls are closed; all six UI applicability checks remain N/A because this correction only changes a test assertion. These records do not establish independent human approval or phase completion. Known deep-quality dependency-audit debt remains assigned to Phase 184.

## Narrative Findings (AI reviewer)

## Warnings

### WR-03: Artifact uploads reuse names on workflow reruns

**Severity:** WARNING
**Disposition:** Deferred in the canonical disposition ledger; this is a baseline-only limitation, not a Phase 182 source regression.
**File:** `.github/workflows/ci.yml:573,622`
**Issue:** Coverage and closeout-attestation artifact names contain only `github.sha`; upload-artifact does not overwrite an existing immutable artifact name by default, so rerunning the same workflow run at the same SHA can collide with the prior attempt. These names are unchanged from base `ba624a74`. The supported closeout collector dispatches a fresh run, Phase 182 browser/cache artifacts bind run and attempt, and retries are ineligible as clean proof, so this does not block the current closeout path. The deferred disposition is not human risk approval.
**Fix:** When adding same-run rerun support, include `${{ github.run_id }}-${{ github.run_attempt }}` in both names and update `ci_monitor` artifact selection/consumers and their tests together.

#### Closed historical findings (preserved disposition; not open)

- **WR-02 — Settings screenshot assertion targets numeric text:** fixed by `30becbc4`; RED/GREEN evidence is recorded in `assertion-selector-red.log` and `assertion-selector-green.log`.
- **CR-01 — IPv6 loopback bypasses retained-preview refusal:** fixed by `b6bf7bf0` with executable regression coverage.
- **CR-02 — Lock-change proof passes on a forced cache miss:** fixed by `01d1f871` with exact-byte, canonical-identity and natural-key checks.
- **CR-03 — Mandatory inventory accepts one case from each required suite:** fixed by `edd47eee` with all required stable UI identities enforced.
- **WR-01 — Fixture route readiness treats redirects as success:** fixed by `2f615705` with 2xx-only readiness checks.

The five findings above are historical closed/deferred dispositions and are not open findings under new IDs. This report does not claim all advisory CI jobs are green.

---

_Reviewed: 2026-10-27T23:34:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
