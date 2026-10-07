---
phase: 173
source_review: 173-REVIEW.md
source_reviewed_at: 2026-10-07T01:19:41Z
status: fixes_applied
---

# Phase 173 Code Review Fixes

These are orchestrator-applied corrections to the independent review, not a simulated second review. Full root verification passed on `53b5d37ca8283c35d63a14a669ac1094d25a146e`: four properties and 661 tests, zero failures; full Ops passed two doctests and 246 tests. Final browser regression and re-review remain separate checks.

## Fixed Issues

### CR-01: Empty Oban history is reported as unavailable

`ca0232d` makes a successful Oban inspection observed even when its returned list is empty. Root regression in `0981b58` failed on the original empty-history assertion and passes after the fix. An empty history has zero counts and no observed success, rather than unavailable counts.

### WR-01: Queue inspection failure marks the successful backend observation unavailable

`ca0232d` adds an internal, `@doc false` operator presentation projection that preserves backend and queue outcomes independently. `Scrypath.sync_status/2` retains its all-or-error public contract. The Posture projection retains only the failed source's previous state/reference, reports its reason, and displays current successful-source counts. The partial-error Ops assertion failed before implementation and passes afterward. The expanded browser regression caught a bare DateTime passed into OpsTime; `da8df9c` restores the full observation reference so retained relative ages stay stable.

### WR-02: Timed-out schema scans lose the schema key needed to retain its last success

`ca0232d` explicitly uses ordered async results and pairs each result with its allowlisted input schema. Timeout rows retain that schema's identity and prior evidence, while successful neighbors advance their observations. `bbc358c` exercises the actual 15-second timeout with a 16-second delay; this assertion failed before the correction and the focused/full Ops suites pass afterward. The earlier draft test had an invalid option/setup failure and is not counted as valid RED evidence.

## Evidence

Actual regression logs are preserved outside the source checkout at `/private/tmp/scrypath-phase173-20261006-155750/`: `review-core-red.log`, `review-ops-timeout-red.log`, `review-ops-green2.log`, `phase173-review-core.log`, `phase173-review-ops.log`. The combined browser run at `53b5d37` honestly failed seven cases (27 passed), exposing the retained-age rendering regression and a stale mounted picker selector; its log, native report and traces remain preserved.
