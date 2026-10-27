---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T19:57:33Z
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
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
source_sha: e6c330fe99427a71220a6dd66d7c9465caf0bb95
implementation_source_sha: ec248fd2f7eea9314e600bcc10262729d2cce69e
review_base: ba624a7452e717c335a26369b8db8523d2551ee9
review_boundary: final root source review; implementation tree matches the accepted source; not human approval
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T19:57:33Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found
**Source SHA:** `e6c330fe99427a71220a6dd66d7c9465caf0bb95`
**Implementation SHA:** `ec248fd2f7eea9314e600bcc10262729d2cce69e`
**Scope:** Explicit 24-file Phase 182 source scope compared with `ba624a7452e717c335a26369b8db8523d2551ee9`.

## Summary

The final source tree contains three blockers in preview-target refusal, required browser-case coverage, and BEAM lock-invalidation proof, plus a warning in route readiness detection. The supplied acceptance record reports 189 first-attempt cases and six exact-source hosted runs; those results do not close the source-level gaps in the guard and acceptance predicates. The known deep-quality dependency audit remains Phase 184 work and is not represented here as green.

I reviewed the source and phase artifacts without running tests, dispatching CI, or using the retained preview. The current repository HEAD is `e6c330fe99427a71220a6dd66d7c9465caf0bb95`; the reviewed implementation files match the accepted implementation tree at `ec248fd2f7eea9314e600bcc10262729d2cce69e`. The worktree also has unrelated planning edits, which are outside this report's owned file.

## Narrative Findings (AI reviewer)

### Critical Issues

### CR-01: IPv6 loopback bypasses retained-preview refusal — BLOCKER

**File:** `examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs:1,19`
**Issue:** The guard only recognizes `localhost` and `127.0.0.1`. `new URL("http://[::1]:4002").hostname` is `"[::1]"`, so an IPv6 loopback preview on port 4002 returns no refusal reason and `guardVerificationTarget` runs the action. Both `ui_followup.spec.ts` and `ui_iteration3.spec.ts` use this guard before their scenario setup, leaving the retained-preview safety boundary bypassable by that loopback address.
**Fix:** Normalize hostnames and use an IP parser to reject every loopback address on port 4002, including `::1` and IPv4 loopback aliases. Add a guard regression proving the refusal callback runs and the action does not run for IPv6 loopback.

### CR-02: Lock-change proof passes on a forced cache miss — BLOCKER

**File:** `scripts/ci/phase182_acceptance.cjs:297-304,1182-1192`
**Issue:** `beamPlanForProbe` appends a unique run/attempt suffix to the resolved key and clears the resolved restore prefix for both fallback and lock-change probes. This guarantees a miss regardless of whether the lock-derived cache identity changed. The validator only requires differing raw `resolved_lock_before`/`resolved_lock_after` hashes and a resolved miss; it never checks that the lock-derived identity/key changed. The regression fixture demonstrates the gap: `phase182_acceptance.test.cjs:251-272` uses identity lock digest `d…d`, raw lock hashes `d…d`/`e…e`, and the test accepts that proof at `:329-335`. This can certify CACHE-02 lock invalidation without demonstrating that lock identity invalidates resolved state.
**Fix:** Record and validate the canonical lock-derived digest/key for both the baseline and changed lock, and require the changed lock to produce a different resolved identity. Do not use a per-run forced miss as evidence of lock invalidation; preserve a compatible download fallback while demonstrating the exact changed-lock key misses.

### CR-03: Mandatory inventory accepts one case from each required suite — BLOCKER

**File:** `scripts/ci/ecommerce_evidence.cjs:250-264`
**Issue:** `mandatoryInventoryReasons` checks only that the inventory contains at least one case from each required filename and both Phase 173 entrypoints. The later report reconciliation proves only that every case still present in the inventory ran. If most or all intended `ui_followup` or `ui_iteration3` cases are removed or disabled, the reduced inventory and its matching report can still be eligible. This does not enforce D-06's requirement that every intended follow-up/iteration case execute.
**Fix:** Validate the required composite identities or stable required title-path set for both suites, including applicable entrypoints, against the inventory before reconciling results. Add a regression that removes or disables one intended case and requires ineligibility; keep the requirement identity-based rather than relying on historical total counts.

### Warnings

### WR-01: Fixture route readiness treats redirects as success — WARNING

**File:** `examples/scrypath_ecommerce/docker-playwright.sh:143-153,173-180`
**Issue:** `curl --fail` rejects HTTP errors but returns success for 3xx responses, and this request does not follow redirects or inspect the final status. A health route redirected to a login or fallback page is therefore recorded as ready; `--readiness-only` can exit successfully without observing a successful health response from the intended route.
**Fix:** Capture the response status and require the intended 2xx response for each route. If redirects are expected, follow them with a bounded redirect count and validate the final URL and status.

### Earlier Finding Disposition

The findings in the prior report at source SHA `7f8c4592d92507b05c47d36c8436a87545bdcc0b` were rechecked and remain fixed in the current source: validation CLI namespace forwarding; cache namespace binding; browser workflow-ref binding; selected-run/job/artifact readiness snapshot; full aggregate eligibility read from its parsed receipt; direct REST job-log transport and timestamp parsing; and separation of import-only observation from strict warm-cache acceptance. The findings above are new gaps in different predicates and boundaries.

---

_Reviewed: 2026-10-27T19:57:33Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
