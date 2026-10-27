---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T15:03:21Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .dockerignore
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - examples/scrypath_ecommerce/Makefile
  - examples/scrypath_ecommerce/compose.e2e.yaml
  - examples/scrypath_ecommerce/compose.phase173.yaml
  - examples/scrypath_ecommerce/compose.yaml
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/scripts/verify-e2e.sh
  - scripts/ci/beam_cache.cjs
  - scripts/ci/ecommerce_build.cjs
  - scripts/ci/ecommerce_evidence.cjs
  - scripts/ci/phase182_acceptance.cjs
  - scripts/ci/phase182_acceptance.test.cjs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T15:03:21Z  
**Depth:** standard  
**Files Reviewed:** 14  
**Status:** issues_found  
**Source:** `b35b04411f27eac8e8b0e7fed1f43e8ea1616192` (`worktree-agent-p182-08-1793071051075`)  
**Boundary:** Early internal source review before the next hosted acceptance batch. Hosted full-browser and cache evidence remains pending; this review does not claim phase completion or human approval.

## Summary

Re-reviewed the prior findings, namespace wiring changes, browser-ref propagation, and the pinned-run readiness delta. The cache namespace and browser-ref findings from the early review are fixed: namespace now joins the dispatch, session, receipt, and aggregate; cache scopes and BEAM keys are checked against the requested effective namespace; and browser workflow ref is carried into and checked in the aggregate. The collector now waits on one selected run while attempt jobs and named artifacts become available, then uses that same snapshot for validation.

One blocker remains: the documented `validate --probe-namespace` option is ignored, so aggregate validation fails for every non-empty namespace session.

## Narrative Findings (AI reviewer)

### CR-01: Aggregate validation discards the requested probe namespace

**Classification:** BLOCKER  
**File:** `scripts/ci/phase182_acceptance.cjs:1896`  
**Issue:** The CLI advertises `validate --probe-namespace`, and the contributor runbook requires passing the same namespace to both collection and validation. However, the `validate` handler hardcodes `probeNamespace: ""` instead of reading `flags["probe-namespace"]`. A session collected with a non-empty namespace stores that value in its manifest and receipts; `validateAggregate` then compares them against the empty namespace and rejects the session. Thus the documented namespaced cache acceptance flow cannot complete.  
**Fix:** Set `probeNamespace: flags["probe-namespace"] || ""` in `inputFlags` (or pass it directly to `validateFlags`) so the provided namespace is validated and used for aggregate identity checks.

## Prior finding disposition

- **WR-01 (cache proof namespace binding): Fixed.** `validateCacheAcceptance` reads the session namespace, derives each Docker scope from the exported `cacheScopeFor` helper and the effective per-job workflow inputs, and derives BEAM keys from the recorded cache identity. Session/receipt/aggregate identities retain the namespace, including the empty value.
- **WR-02 (browser workflow ref binding): Fixed.** `validateBrowserArchive` carries `receipt.workflow` into the proof aggregate, `validateBrowserAcceptance` checks `refs/heads/<selected branch>`, and manifest validation repeats the archive ref check.
- **Readiness delta:** The collector pins the selected run ID, polls attempt-specific job state and named artifacts up to its bounded timeout, and passes the same run/jobs/artifact snapshot to downstream validators. Terminal job failures and malformed or duplicate artifacts still fail closed.

---

_Reviewed: 2026-10-27T15:03:21Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
