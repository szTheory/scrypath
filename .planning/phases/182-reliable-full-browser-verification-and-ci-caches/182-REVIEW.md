---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T14:51:43Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - .dockerignore
  - .github/workflows/ci.yml
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
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-27T14:51:43Z  
**Depth:** standard  
**Files Reviewed:** 13  
**Status:** issues_found  
**Source:** `5f250d1f020672787e82fc27e98928172562c1ae` (`worktree-agent-p182-08-1793071051075`)  
**Boundary:** Early internal source review before the next hosted acceptance batch. Hosted full-browser and cache evidence remains pending; this review does not claim phase completion or human approval.

## Summary

Reviewed the explicit 13-file source scope, including the pinned-run readiness flow, cache modes and keys, Docker handoff, evidence collection, archive validation, and cleanup deadlines. The new readiness loop waits on the selected attempt and preserves that snapshot. Two evidence-validation gaps remain: the collector does not bind cache proof keys/scopes to the requested namespace, and it does not bind the browser receipt's workflow ref to the selected branch.

## Warnings

### WR-01: Cache proof is not checked against the requested cache namespace

**Classification:** WARNING  
**File:** `scripts/ci/phase182_acceptance.cjs:1490-1498`  
**Issue:** The collector checks a downloaded cache proof's mode, repository, branch, source SHA, run ID, and attempt, then validates only that Docker scopes are syntactically valid/distinct and that BEAM keys have the expected broad relationships. It never compares the proof's scopes or keys with `flags.probeNamespace`. If workflow output wiring drops the requested namespace, a probe can use the production namespace and still be accepted as evidence for the isolated namespace requested by the collector.  
**Fix:** Pass the validated namespace into `validateProbeArtifact` and `validateCacheAcceptance`; derive the expected per-target Docker scopes and BEAM key/restore prefixes from the base scopes plus that namespace, and reject mismatches (including the empty namespace case).

### WR-02: Browser acceptance does not bind the recorded workflow ref to the selected branch

**Classification:** WARNING  
**File:** `scripts/ci/phase182_acceptance.cjs:817-825`  
**Issue:** Browser aggregate validation joins repository, SHA, run ID, attempt, and event, but ignores the aggregate's recorded `workflow.ref`. The evidence producer requires a non-empty ref, but neither it nor this collector checks that the ref identifies the selected branch. A receipt with a correct SHA and run identity but a different or stale ref can therefore be accepted, despite the workflow ref being part of the required provenance.  
**Fix:** In `validateBrowserArchive`, compare `validation.receipt.workflow.ref` to the selected run's full branch ref (for this dispatch path, `refs/heads/${identity.branch}`), and preserve that validated ref in the aggregate proof.

---

_Reviewed: 2026-10-27T14:51:43Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
