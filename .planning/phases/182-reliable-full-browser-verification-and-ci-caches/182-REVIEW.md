---
phase: 182-reliable-full-browser-verification-and-ci-caches
reviewed: 2026-10-27T20:12:14Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - CONTRIBUTING.md
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs
  - scripts/ci/ecommerce_evidence.cjs
  - scripts/ci/ecommerce_evidence.test.cjs
  - scripts/ci/ecommerce_lifecycle.test.cjs
  - scripts/ci/ecommerce_target.test.cjs
  - scripts/ci/phase182_acceptance.cjs
  - scripts/ci/phase182_acceptance.test.cjs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
source_sha: 762baf3004a7b4be32975d0031cdae6e0947d6b3
implementation_source_sha: 01d1f87167a984e708bfa45326a12ea05a225427
review_base: 5918efd30c4364c1607e0757a2344a252665eb01
review_boundary: correction review before renewed acceptance; not phase completion or human approval
---

# Phase 182: Correction Review Report

**Reviewed:** 2026-10-27T20:12:14Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** clean for the four repaired findings
**Source SHA:** `762baf3004a7b4be32975d0031cdae6e0947d6b3`
**Implementation fix SHA:** `01d1f87167a984e708bfa45326a12ea05a225427`
**Scope:** The four findings from the prior review and their source/test corrections since `5918efd30c4364c1607e0757a2344a252665eb01`.

## Summary

All four findings from the prior review are fixed in the current source and have focused regression coverage. I found no remaining correctness or security defect in these corrections.

This review covers the correction diff and the related Phase 182 requirements. It does not establish fresh local or hosted acceptance at this source. The phase records correctly say those runs and final closeout remain pending; historical EC receipts do not prove the corrected source. The provided 115-test CI log was not rerun or independently verified here. No CI was dispatched, no preview was used, and no source file was changed.

The finding counts above are open findings after correction review. The closed prior findings below retain their canonical IDs and classifications for disposition tracking.

## Narrative Findings (AI reviewer)

No open findings in the four repaired areas.

## Prior Finding Disposition

### CR-01: IPv6 loopback bypasses retained-preview refusal — BLOCKER — FIXED

**Disposition:** Fixed at `b6bf7bf0f951870514720fcabc24a056262d99df`.
**Review:** `isLoopback` strips URL brackets and a trailing dot, uses `node:net` IP parsing, rejects `localhost`, all numeric IPv4 `127/8` addresses, IPv6 `::1`, and IPv4-mapped `127/8` addresses. The shared guard still permits the Docker hostname and explicitly isolated local ports. The updated target test verifies refusal callback execution and that the mutation action does not execute for expanded IPv6, mapped IPv4, IPv4 shorthand, and trailing-dot localhost forms.

### CR-02: Lock-change proof passes on a forced cache miss — BLOCKER — FIXED

**Disposition:** Fixed at `01d1f87167a984e708bfa45326a12ea05a225427`.
**Review:** The lock-change mode no longer adds a per-run key suffix or disables its resolved restore prefix. `writeBeamProbeProof` derives canonical lock identities from the exact source and probe lock bytes, checks both against `beamCache.hashPaths` on their actual checkouts, and requires the plan's natural resolved key to match the changed-lock identity. Acceptance verifies the base64 bytes, run-bound comment-only mutation, raw digests, before/after identities, and distinct natural resolved keys. Regressions reject the former mismatched-identity fixture, exercise a temporary Git lock copy, and reject a producer plan that uses the original lock identity. Fallback mode retains its separate forced miss.

### CR-03: Mandatory inventory accepts one case from each required suite — BLOCKER — FIXED

**Disposition:** Fixed at `edd47eee6a0acadc78db8e097039069eefde40c0`.
**Review:** The evidence validator now requires all thirteen intended `ui_followup` and `ui_iteration3` composite identities, including project, title path, and inferred entrypoint. Bare Playwright spec filenames normalize to the same repository-relative identity as `e2e/<file>`. The regression removes or renames each required case from both inventory and results and requires rejection. This enforces the D-06 intended-case contract without using historical total counts.

### WR-01: Fixture route readiness treats redirects as success — WARNING — FIXED

**Disposition:** Fixed at `2f615705e1771a2f0efe15bd7b402f05774e6c46`.
**Review:** The shared route probe now captures the HTTP status and accepts only 2xx responses. The lifecycle regression injects a 302 from each mounted and standalone health route and confirms the browser is not invoked.

---

_Reviewed: 2026-10-27T20:12:14Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
