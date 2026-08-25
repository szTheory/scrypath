---
phase: 145-legacy-phoenix-and-ecto-decimal-remediation
reviewed: 2026-08-22T21:15:19Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - examples/phoenix_meilisearch/mix.exs
  - examples/phoenix_meilisearch/mix.lock
  - examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs
  - examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 145: Code Review Report

**Reviewed:** 2026-08-22T21:15:19Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the legacy Phoenix dependency cohort, its generated lock, and the new
Postgres/endpoint compatibility tests. The focused and complete example suites
pass, and the listener uses loopback, a dynamic port, `start_supervised!/1`, a
unique telemetry handler, and `on_exit` cleanup. However, the manifest breaks
the specified dependency-ownership boundary by promoting Plug to a new direct
runtime dependency.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Plug has been promoted from a transitive dependency to a fifth direct owner

**Classification:** WARNING

**File:** `examples/phoenix_meilisearch/mix.exs:43`

**Issue:** The phase contract requires exactly four direct compatibility bounds
(Phoenix, Bandit, Ecto SQL, and Postgrex) and explicitly keeps Plug transitive.
Adding `{:plug, "~> 1.19.5"}` makes the example own Plug's version policy in
production, contradicts that boundary, and makes future Plug upgrades require
an unrelated manifest edit instead of flowing through Phoenix/Bandit/Req. The
lock's current Plug version can still be verified without declaring Plug
directly.

**Fix:** Remove the direct Plug row, regenerate the lock using only the four
approved direct cohort constraints, and retain a lock/dependency-tree assertion
that confirms Plug resolves within `>= 1.19.5 and < 1.20.0` transitively.

---

_Reviewed: 2026-08-22T21:15:19Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
