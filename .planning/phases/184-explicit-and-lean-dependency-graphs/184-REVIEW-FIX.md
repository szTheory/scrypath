---
phase: "184"
status: fixed_pending_full_verification
fixed: 5
skipped: 0
source: 1b98eb1a9522c1e80c4cedff10409b681dad0dde
---

# Phase 184 — Review repairs

All five code-review findings have scoped repairs and passing targeted checks. The initial review remains in Git history; this report records actual actions and evidence, without granting final hosted acceptance or accepting the remaining dependency risks. Full canonical Ops verification and the merged root suite are running separately; terminal exact-source closeout remains required after tracked writes.

## Fixed Issues

### CR-01: A host with metrics but no poller cannot start ScrypathOps

Commit `bdf54f8e` requires both metrics and the poller before defining the diagnostic supervisor. The mounted consumer harness now includes a real metrics-only graph, explicitly loads its real metrics module, and checks the compile guard independently of dependency compiler ordering. Core Ops children start while the incomplete diagnostic module remains absent. The final regression failed on old source, then passed with the complete guard; all ordinary absent-dependency profiles also passed. Source contracts require both capabilities. Raw RED: `metrics-only-red-loaded.log`; GREEN: `metrics-only-green.log` (19 tests, zero failures). Two earlier fixture attempts did not expose the compiler-order case; their logs remain preserved, not relabeled failures.

### CR-02: Non-nil malformed identities authorize protected Sigra actions

Commit `a3bc5f5c` admits nonblank valid UTF-8 binary identities and positive integer identities, rejecting booleans, containers, atoms, nonpositive integers and floats. The regression exercises both identity fields across every protected action and includes supported integer and existing string positive paths. The actual old gate invoked the forbidden callback in RED; all gating cases passed in GREEN. Raw receipts: `identity-red.log`, `identity-green.log` and `denial-copy-green.log`.

### WR-01: Failed target-asset extraction leaves a container outside cleanup ownership

Commit `b7107ea2` registers the current target extraction container in shared EXIT-cleanup state immediately after creation, labels its run ownership and clears registration only after successful removal. Failure cleanup removes that exact owned ID. Four injected Docker failures cover both runtime targets and successful/failed removals: original copy status 42 is preserved, leftovers are explicit, and failed removal records cleanup_status 1. All four were RED on old source and GREEN after the repair; the complete Node suite passed (127 tests). Raw receipts: `container-cleanup-red.log`, `container-cleanup-green.log`, `review-fixes-node-tests.log`. Shell syntax and static output-only contracts also passed.

### WR-02: Startup accepts confirmation paths that crash the recovery navigation

Commit `fe0c04c4` rejects the unsafe characters rejected by the actual installed LiveView local-navigation API, including backslashes and control-character forms. Rejected paths now produce the startup configuration error. Accepted paths are passed through actual unconfirmed-operator LiveView navigation and cannot run the protected action. RED reproduced acceptance of an unsafe path; GREEN passed all 18 gating/path tests. Raw receipts: `confirmation-path-red.log`, `confirmation-path-green.log`; targeted formatting passed.

### WR-03: The standalone quickstart advertises a toolchain that cannot compile its default graph

Commit `fbadaefe` states Elixir 1.18+ for the default standalone checkout, which includes Sigra, while preserving the root library and mounted-without-Sigra 1.17 floor. Exact tuples remain centralized. The current support contract failed before the correction and passed afterward; ExDoc warnings-as-errors passed. Raw receipts: `quickstart-floor-red.log`, `quickstart-floor-green.log`.

## Skipped Issues

None.

## Additional UI repairs

Commit `fcbd30bb` restores the configured confirmation journey for otherwise valid operators with nil sudo state, without invoking any protected action. The malformed-timestamp test now constructs an actually malformed OperatorContext instead of normalizing its session input to nil. RED reproduced the lost redirect; actual-module GREEN passed all configured actions. Commit `57b674ae` adds plain recovery instructions to the denied-action messages; authentication/path tests and formatting still pass. No layout, theme, asset baseline or retained-preview change was made.

## Evidence and limits

All named raw logs are under `/private/tmp/scrypath-phase184-execution/`. Actual dependency beams and source were used for the authentication tests without starting an app, endpoint or database. Cold consumer tests used fresh independent dependency/build/Mix/Hex directories. Docker fault tests used an external-I/O double, not a live stack. The full Ops verifier uses its separately owned disposable Postgres, with lifecycle identity in `root-review-postgres.json`.

The two known Cloak/Cloak Ecto findings remain affected and unaccepted. Current rendered review of the source-stale retained preview remains unavailable; code-only review and browser receipts are not relabeled independent design approval. The final merged-branch source/artifact join remains open until canonical terminal closeout succeeds.

## Full-run reconciliation

The first post-review root fast run exposed a namespace-canary violation in the newly added navigation test. The test was moved into the existing Sigra integration test directory without widening the allowlist. The namespace canary and all actual authentication/navigation tests passed afterward; the full root suite is being rechecked. Its original failure remains in `review-fixes-root-fast.log`.

The first canonical Ops run passed its cold consumer boundary contract and reached the complete direct suite, where one old OnMount assertion expected the technical word “Sigra” rather than the newly actionable recovery feedback. The assertion now checks the recovery instruction, while preserving the forbidden-callback check. All 20 actual OnMount/gating/path tests pass. The first raw log, exit and successful owned Postgres disposal remain in `review-fixes-full-ops-first.log`, `review-fixes-full-ops-first.exit` and `root-review-postgres-first.json`. A fresh canonical rerun will establish its full result; the earlier failure is not relabeled.

The repaired merged root suite passed: 1,017 tests and five properties, zero failures (`review-fixes-root-fast-repaired.log`). The first canonical Ops boundary checks passed and its sole stale OnMount message assertion was corrected in `1b98eb1a`; all 20 actual authentication/lifecycle/navigation tests pass (`recovery-on-mount-green.log`). A fresh canonical full Ops run is in progress; its final receipt will retain owned cleanup status. The namespace relocation is committed as `5eb0ccd8`; the allowlist remains unchanged.
