---
phase: 159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov
reviewed: 2026-08-26T21:29:10Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .github/workflows/ci.yml
  - test/mix/tasks/workflow_wiring_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-26T21:29:10Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The coverage job correctly uses the scheduled/manual event guard, full checkout history, an immutable artifact-action pin, seven-day retention, and the current checkout default makes `github.sha` identify the tested commit. The added ExUnit contract, however, does not bind two key assertions to the artifact-upload step. It can therefore pass after changes that either skip the report on a failed coverage run or label an artifact with a SHA different from the checked-out source.

## Warnings

### WR-01: Coverage test does not require the artifact upload to run after a failed coverage command

**File:** `test/mix/tasks/workflow_wiring_test.exs:435-436`
**Issue:** The test independently checks for the upload step name and for `if: always()` anywhere in the job. A later edit can remove `if: always()` from the upload step (so a failed `mix verify.coverage` produces no hosted report) and add `if: always()` to any other coverage step; this test still passes. That makes the claimed failure-evidence contract a false positive.
**Fix:** Isolate the upload step (or parse the workflow YAML) and assert its own `if` expression. For example, extract the block beginning at `- name: Upload informational coverage report` through the next step and assert that block contains `if: always()`.

### WR-02: SHA-label assertion is not tied to the source that checkout tested

**File:** `test/mix/tasks/workflow_wiring_test.exs:441`
**Issue:** The test only searches for `coverage-report-${{ github.sha }}`. It still passes if the checkout step is later given `with.ref: main`, a tag, or another revision while the artifact retains the event SHA in its name. In that configuration the artifact label can assert evidence for one commit while `mix verify.coverage` ran against another—especially for a manually dispatched run on a non-default ref.
**Fix:** Assert the coverage checkout block has no `ref` override (or explicitly uses `${{ github.sha }}`), and assert the artifact name in the upload-step block. Parsing the YAML into a map and checking `jobs.coverage.steps` by `name` is more durable than independent substring checks.

---

_Reviewed: 2026-08-26T21:29:10Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
