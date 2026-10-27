---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T15:44:20Z
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
  warning: 0
  info: 0
  total: 0
status: clean
source_sha: 8c2f1f3875643e6a5f42b2913dfd42dac50654ed
review_base: ba624a7452e717c335a26369b8db8523d2551ee9
review_boundary: early internal source review; not phase completion or human approval
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T15:44:20Z  
**Depth:** standard  
**Files Reviewed:** 24  
**Status:** clean  
**Source SHA:** `8c2f1f3875643e6a5f42b2913dfd42dac50654ed`  
**Scope:** Explicit 24-file Phase 182 source scope, compared with `ba624a7452e717c335a26369b8db8523d2551ee9`.  
**Boundary:** Early internal source review before another hosted acceptance batch. This is not phase completion or human approval; full and mode-specific hosted evidence remains pending.

## Summary

The full-mode aggregate blocker found at `c0cbfa2777eafc4268f9e09b9552bf21b1a25bd1` remains fixed: validation checks `receipt.browser.eligible` on the parsed receipt paired with each manifest entry. The latest transport delta replaces whole-run `gh run view --log` with the selected job's REST log endpoint and accepts timestamp-prefixed REST output in the BuildKit parser while retaining the original log string for hashing. Regression coverage exercises the public collector path and REST timestamp parsing. The supplied RED/GREEN and historical replay evidence are consistent with the inspected change; the replay is not evidence for this source SHA. I did not run tests or perform live Docker, browser, or hosted CI operations during this follow-up.

## Narrative Findings (AI reviewer)

No open findings at source SHA `8c2f1f3875643e6a5f42b2913dfd42dac50654ed` in the explicit 24-file scope.

## Prior finding disposition

- **CR-01 (namespace lost by the validation CLI): Fixed.** `main` forwards `flags["probe-namespace"]` to `validateFlags`; the namespace regression covers the non-empty value.
- **WR-01 (cache proof namespace binding): Fixed.** `validateCacheAcceptance` checks the session namespace, derives Docker scopes from `cacheScopeFor` and effective workflow inputs, and derives BEAM keys from recorded cache identity. Session, receipt, and aggregate identity retain the namespace, including the empty value.
- **WR-02 (browser workflow ref binding): Fixed.** The browser receipt's workflow metadata is carried into the aggregate and checked against `refs/heads/<selected branch>`; manifest validation checks the archived aggregate ref again.
- **Readiness finding (run/job/artifact endpoint timing): Fixed.** The collector pins the run ID, waits within a bounded timeout for selected-attempt jobs and named artifacts, preserves terminal failure and duplicate/ownership/digest checks, and uses the same selected snapshot downstream.
- **CR-02 (full aggregate reads browser eligibility from receipt path): Fixed at `scripts/ci/phase182_acceptance.cjs:1748`.** The filter now destructures `{ entry, receipt }` and checks `receipt.browser?.eligible`. Regression coverage is added at `scripts/ci/phase182_acceptance.test.cjs:1220`.
- **Transport delta: Fixed.** `getJobLog` requests `/repos/<repo>/actions/jobs/<selected-job-id>/logs` through `gh api --allow-escape-sequences` and treats the response as data, avoiding the whole-run ZIP transport. `parseBuildKitCacheProgress` accepts REST timestamp-only lines and existing `gh run view` tab-prefixed lines; hashing still uses the unnormalized log text. Regressions cover collector transport selection and timestamped parser input. The reported RED/GREEN run and 109 passing CI Node tests were not rerun for this review; the supplied real historical replay is not new-source hosted acceptance.

---

_Reviewed: 2026-10-27T15:44:20Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
