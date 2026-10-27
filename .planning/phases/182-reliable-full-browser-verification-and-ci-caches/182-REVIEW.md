---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T22:32:06Z
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
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T22:32:06Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed all 24 in-scope files against base `ba624a7452e717c335a26369b8db8523d2551ee9` at current `HEAD` `b5c41c6d56389fb9c388309d3380aedecc6609ea` (9,154 insertions and 410 deletions in the scoped diff). The implementation source matches frozen accepted source `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8`; the review found two warnings in the current files: a screenshot assertion that resolves to a numeric text locator, and artifact names that collide on workflow reruns.

The source-bound evidence remains valid for the frozen implementation: the seven-invocation cohort has six eligible runs, each with 189 first-attempt cases and complete artifacts; both aggregate validators passed. The later closeout at documentation head `cac118591f41feb5199e9ab3d1499d6e1c3a01e6` passed the five required jobs, coverage, attestation, and default-policy 189/189 browser run. This review did not dispatch CI or rerun acceptance. The default-policy run is not strict warm-cache proof. Deep-quality dependency-audit debt remains assigned to Phase 184; this report does not claim all advisory jobs are green, independent human approval, or phase completion.

## Narrative Findings (AI reviewer)

## Warnings

### WR-02: Settings screenshot assertion targets numeric text

**Severity:** WARNING
**File:** `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts:67`
**Issue:** The expression closes the first regular expression before `|` and starts a second one. JavaScript evaluates this as bitwise OR between two `RegExp` objects, coercing the result to `0`; Playwright therefore searches for text `0`, not “Meilisearch settings match” or “Meilisearch settings differ.” The screenshot journey can pass without verifying that the settings status is rendered.
**Fix:** Use one regular expression with alternation inside it:

```ts
await expect(page.getByText(/Meilisearch settings (match|differ)/).first()).toBeVisible();
```

### WR-03: Artifact uploads reuse names on workflow reruns

**Severity:** WARNING
**File:** `.github/workflows/ci.yml:573,622`
**Issue:** The coverage and closeout-attestation artifact names contain only `github.sha`. `actions/upload-artifact` uses immutable artifacts and does not overwrite an existing name by default. Rerunning the same workflow run at the same SHA can therefore collide with artifacts from the prior attempt and fail the coverage or attestation job, blocking otherwise valid closeout evidence.
**Fix:** Include the workflow run and attempt in both names (for example, `${{ github.sha }}-${{ github.run_id }}-${{ github.run_attempt }}`), keeping the attestation's recorded attempt aligned with its artifact identity.

#### Closed historical findings (preserved disposition; not open)

- **CR-01 — IPv6 loopback bypasses retained-preview refusal:** fixed by `b6bf7bf0` with executable regression coverage.
- **CR-02 — Lock-change proof passes on a forced cache miss:** fixed by `01d1f871` with exact byte, canonical identity, and natural-key checks.
- **CR-03 — Mandatory inventory accepts one case from each required suite:** fixed by `edd47eee` with all required stable UI identities enforced.
- **WR-01 — Fixture route readiness treats redirects as success:** fixed by `2f615705` with 2xx-only readiness checks.

The correction review at `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` closed those four findings. They remain historical dispositions and are not reused as current findings.

---

_Reviewed: 2026-10-27T22:32:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
