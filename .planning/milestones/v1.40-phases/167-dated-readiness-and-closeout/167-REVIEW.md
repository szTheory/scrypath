---
phase: 167-dated-readiness-and-closeout
reviewed: 2026-09-27T20:57:11Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .planning/phases/167-dated-readiness-and-closeout/check_readiness.py
  - .planning/phases/167-dated-readiness-and-closeout/test_check_readiness.py
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
resolved_findings: 4
status: clean
---

# Phase 167: Code Review Report

**Reviewed:** 2026-09-27T20:57:11Z  
**Depth:** standard  
**Files Reviewed:** 2  
**Status:** clean after focused resolution review; initial findings retained below

## Summary

The initial review found four gaps in the fail-closed contract. A focused resolution review inspected the uncommitted checker and fixture diff: each gap now has a corresponding guard and regression case. The parent reports all 22 focused tests and the complete structural checker pass. Final-source attestation remains pending by design.

## Critical Issues

### CR-01: Boolean values pass as hosted receipt identifiers

**Severity:** BLOCKER  
**File:** `.planning/phases/167-dated-readiness-and-closeout/check_readiness.py:456-479`
**Issue:** Python treats `bool` as a subclass of `int`, so `run_id: true` and artifact `id: true` pass the positive-integer checks. A receipt with `run_id: true`, a matching `/actions/runs/True` URL, and boolean artifact IDs can therefore pass structural validation despite not containing numeric GitHub identities.
**Fix:** Require exact integers (`type(value) is int`) for `run_id` and artifact IDs, and apply the same check to run, attempt, job, and artifact identifiers elsewhere in the checker.

## Warnings

### WR-01: Future evidence dates pass a dated assessment

**Severity:** WARNING  
**File:** `.planning/phases/167-dated-readiness-and-closeout/check_readiness.py:203-220`
**Issue:** The checker bounds evidence observation timestamps by the assessment cutoff, but only checks that each table `Evidence date` is a valid calendar date. Changing that cell to a date after the cutoff still passes, allowing the dated assessment to cite evidence as current that postdates its own cutoff.
**Fix:** Reject evidence dates after `cutoff.date()`. Where the linked record exposes an observation date, also check that the table date agrees with that record.

### WR-02: Markdown evidence links accept nonexistent anchors

**Severity:** WARNING  
**File:** `.planning/phases/167-dated-readiness-and-closeout/check_readiness.py:165-178`
**Issue:** `markdown_links` drops everything after `#` and checks only that the target file exists. A Markdown link to an existing receipt with a misspelled or nonexistent execution heading is accepted, despite the phase contract requiring real links and anchors.
**Fix:** For Markdown targets, validate the fragment against their headings using the same slug rules as `validate_markdown_reference`; validate JSON fragments according to the JSON reference format instead of treating them as Markdown anchors.

### WR-03: Malformed release identity types raise an uncaught exception

**Severity:** WARNING  
**File:** `.planning/phases/167-dated-readiness-and-closeout/check_readiness.py:411, 648-650`
**Issue:** `validate_release_identities` uses each unvalidated `kind` as a dictionary key. A JSON identity such as `{"kind": []}` raises `TypeError` in the comprehension, which `main` does not catch, producing a traceback instead of the checker’s structural-contract diagnostic for malformed input.
**Fix:** Validate that every identity is an object with a non-empty string `kind` before building `by_kind`, and convert malformed-type failures into `ContractError` diagnostics.

## Resolution Review

**Reviewed:** 2026-09-27T21:03:09Z

All four findings are resolved in the current uncommitted diff:

- **CR-01 — RESOLVED.** Hosted, candidate, scenario, and artifact identifiers now require `type(value) is int`, rejecting JSON booleans. `test_boolean_hosted_identifiers_are_rejected` covers receipt, candidate, and scenario identifiers. The earlier red run recorded the prior acceptance.
- **WR-01 — RESOLVED.** Assessment evidence dates are parsed and rejected when later than the UTC cutoff date. `test_assessment_rejects_future_evidence_date` covers the regression. This bounds the date to the assessment cutoff; structural validation still does not certify the semantic accuracy of a source’s recorded date.
- **WR-02 — RESOLVED.** Non-empty Markdown fragments are checked against target headings, while JSON fragments must name an existing top-level key. `test_assessment_rejects_missing_markdown_and_json_fragments` covers both target types.
- **WR-03 — RESOLVED.** Release identity rows and their `kind` values are validated before dictionary construction, so malformed values produce `ContractError` and the CLI’s structural failure diagnostic. `test_release_identity_kind_malformed_types_use_contract_diagnostic` covers malformed values and asserts no traceback.

The parent reports 22 focused tests and the complete structural checker passed after these changes. The available pre-fix failure log is `/private/tmp/phase167-review-red.log`. This resolution review covers only the four original findings; the final external source gate is still pending by design.

---

_Reviewed: 2026-09-27T20:57:11Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
