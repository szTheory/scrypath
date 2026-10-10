# Phase 175 Verification Evidence

This record binds the local Phase 175 repair/browser proof to the source and disposable resources used by the executor. It is local evidence only; hosted exact-SHA CI and OPUX requirement closeout remain pending.

## Browser source and run

- **Source SHA:** `51bc2016371f375e6d0a756f04b6a2ae17044748`
- **Worktree diff SHA-256 at run:** `f9faad04b165d98b7a99668b527f0d86b37ce686105303b7b2c4a8883d18f435`
- **Runner:** `bash examples/scrypath_ecommerce/scripts/verify-phase175.sh repair`
- **Evidence directory:** `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/final`
- **Result:** 3 browser cases, 0 failures, 0 skipped, 0 retries. Mounted swap verification, standalone exact-UID timeout recheck, and standalone state matrix all passed.
- **Scenario states rendered:** queued, processing, succeeded, failed, cancelled, wrong UID, malformed response, timeout, delayed task read, backend/queue errors, configuration mismatch/error, promotion blocked, removed schema, and no schemas configured.
- **Mounted proof:** one deliberate confirmation click returned the rendered task UID; the exact task, live/target pair, and active-index marker document were verified with `probeSwapEvidence`.
- **Standalone proof:** Check swap status re-read fake UID `17501`; the outcome stayed unconfirmed and no second swap was represented. The test-only ExUnit fixture additionally asserts that the swap POST count remains one.
- **UI states:** the browser checks the advanced disclosure across a LiveView refresh, the confirmation cancel/focus-return and tab cycle, the delayed-read busy state, retained task identity, and the read-only configuration/error boundaries.

## Screenshots

There are 14 PNG captures in `final/test-results/phase175-captures/`. Twelve are **before/after interaction** captures of the mounted Sync and drift screen at 390, 768, and 1440 pixels in Light and Dark appearances. One records the confirmation modal at 1440 pixels in Light; one records System appearance in Dark with reduced motion enabled. These are interaction-state screenshots from this run, not source-before/source-after captures. No Phase 174 screenshots are reused.

The Playwright run also verifies page overflow at all six width/theme combinations and applies a synthetic long technical value to the rendered inline-code style at 390 pixels. The clipboard API is unavailable on the stack's HTTP origin; the test verifies exact UID selection and sends `Control+C`, but does not claim clipboard readback.

## Verification commands

| Check | Result |
|---|---|
| `MIX_ENV=dev mix assets.build` in `scrypath_ops` | Passed (exit 0) |
| `mix precommit` in `scrypath_ops` | Passed: 332 tests, 0 failures |
| `mix verify.ops_ui` with `PGHOST=127.0.0.1`, `PGPORT=52706`, `MIX_TEST_PARTITION=175_owned` | Passed: 332 tests, 0 failures |
| `make contrast` in `examples/scrypath_ecommerce` | Passed: 0 AA failures; 36 AAA advisories |
| `mix verify.core --exclude integration --exclude docs_contract` | Passed: 661 tests, 0 failures; standard maturity gate passed |

The contrast report is copied to `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/contrast-report.token.json` (SHA-256 `082e411fe6d6292ea354e9472cb2e2a4fc04ffcbd8064ae4843463520abb9070`). The AAA results are advisories; no Phase 175 color-token source changed.

## Resource and preservation record

- Disposable Compose project: `scrypath_phase175_51bc201637_repair_79686`.
- `cleanup_status=0`; its containers, volumes, and network were removed. A follow-up label query found zero resources for this project.
- Ops test database partition `175_owned` at port `52706` was parent-owned and only used by the prescribed Ops gate; it remains available to later waves.
- The retained previews were not targeted. Post-run inspection showed `scrypath-ui-v142-web-1` still serving port 4012 and `scrypath_phase174_d4395f2_review-web-1` still serving port 4014.
- The original checkout was not edited; post-run HEAD remained `368abcc5f0309cb0e154739c1e52916478283b90`. The frozen Phase 173 baseline directory remained present.

## Limits and remaining closeout

The approved UI spec contains 68 applicable element/category pairs in eight groups. This browser scope supplies executable evidence across all eight groups, while the full Ops test suite supplies the detailed rendered-state, authorization, stale-context, and no-resubmit assertions. It is not a one-test-per-pair 68-case Playwright matrix. System appearance has a Dark/reduced-motion capture; there is no separate Light/System screenshot. Source-diff screenshots are not included. No hosted CI result, reviewer approval, merge, release, or OPUX-20–22 requirement completion is claimed here.

## Validation gap closeout

The expanded run at source `724c5acfddec11494c83d0eef8df4dfb9da416f7` plus the recorded worktree diff passed seven browser cases with zero failures/skips/retries. Retained receipt: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/post-audit-final/`; its `worktree-diff-sha256.txt` identifies the uncommitted changes used by the run. Exact delete proof also correlates the opaque receipt, source failure, replacement job/attempt and task UID before checking active-index absence. New checks include upsert handoff, double submission, mutation-time prerequisites, connected sudo return, and System Light/reduced motion. Full Ops gate subsequently passed 333 tests and 2 doctests. Failed gap-fill attempts remain in `nyquist-final/`. Hosted evidence and recovery callback current-runtime verification remain pending.
