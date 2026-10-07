---
phase: 173
source_review: 173-REVIEW.md
source_reviewed_at: 2026-10-07T01:35:36Z
status: fixes_applied
---

# Phase 173 Re-review Fix

The independent 43-file re-review confirms the three initial findings are fixed and reports a new warning under reused ID WR-01. The original review/fix identities remain in git and `173-REVIEW-FIX.iter1.md`; they are not treated as the new finding.

## Fixed Issues

### WR-01: Whole-schema errors hide retained queue evidence

`3adccd9` preserves both source error reasons in the internal presentation projection, even when both fail. Its public sync_status all-or-error contract remains unchanged. Whole-schema timeouts render separate backend and queue unavailable groups; inline/manual modes retain explicit Queue not used copy. Retained states use the complete previous observation reference, preserving source-local ages and exact timestamps.

The focused LiveView regression failed on prior source and then passed after this fix: `review2-ops-red3.log` (one test, one assertion failure for missing queue exact evidence) and `review2-ops-green2.log` (one test, zero failures). Earlier draft selectors targeted a copy button as though it contained exact evidence and are not counted as valid RED. The corrected assertion was rerun against the prior source before restoring the fix. Both fixture providers and the connected browser status case now exercise backend+queue failure together, retaining backend 3-day and queue 2-day evidence independently. Final combined browser and full gates remain separate checks.

## Evidence

All native logs and source backups are outside the checkout under `/private/tmp/scrypath-phase173-20261006-155750/`. The earlier `da8df9c` browser run honestly passed 32 of 34 cases: the remaining two asserted absence of disclosure across an entire schema row even when its independent queue observation succeeded. The corrected assertions constrain absence to the unavailable backend and also require the valid queue's current 3-day timestamp/ISO, preserving the intended per-source contract.
