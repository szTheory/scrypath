# Phase 175 Verification Evidence

This record preserves successive source-bound execution and audit proofs. The latest local production source is `ce60384aa95235376fae8fe4381005c36ece3725`; earlier sections are historical and their limitations do not describe later runs. Hosted exact-SHA CI and OPUX requirement closeout remain pending.

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

## Current security-fix source proof

- Source SHA: `22089e9513a14d38a252e6dc59530b6d3698ef1d`.
- Worktree diff digest: `5f37ddf38b99c1db3d33f72cb24a93cd957b47101b5dcad985d34997abb8efa5`. Tracked source was committed; only the execution lock was untracked.
- Retained browser directory: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/security-fix-final`. JUnit: seven tests, zero failures/errors/skips; retries disabled. Cleanup status zero.
- Same-source canonical Ops: 334 tests + 2 doctests, zero failures; log `security-fix-ops.log`.
- Security recheck: zero blocking threats; one existing medium host-authorization advisory remains open without risk acceptance. Hosted CI remains pending.

## Final reviewed local implementation

- Source `ce60384aa95235376fae8fe4381005c36ece3725`: seven production browser cases, zero failures/errors/skips/retries; `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/final-ui-browser/test-results/phase175-repair.xml`. Exact swap pair/task/document, upsert and delete retry receipt/job/attempt/task/document, double submit, changed prerequisites, authorization return and same-UID read-only recheck are exercised.
- Final same-source Ops `mix precommit`: 334 tests + 2 doctests, zero failures; `evidence/phase175/final-ui-ops.log` in the external evidence root. Existing unrelated core compiler warnings remain recorded.
- Final browser captures include 390/768/1440 Light and Dark, System Light and Dark with reduced motion, and dialog confirmation. Keyboard initial focus, tab cycle, Escape and trigger return are executable assertions. The UID remains selectable; OS clipboard readback is unavailable on this HTTP origin. Long-text stress is a DOM layout assertion, not a maximal-value modal screenshot or full state/theme/viewport cross-product.
- Independent UI recheck: 23/24; neutral eligibility, visible refresh, typography, spacing and cancellation copy corrected. A minor outline-softening recommendation remains; no task-blocking UI defect or human acceptance gate. All 68 listed component-state pairs are mapped with bounded source/test/capture evidence in `175-UI-REVIEW.md`.
- Independent code review discovered development fixture exposure. `3417307` restricts destructive example E2E routes to test mode; the reviewer confirmed CR-01 fixed in `175-REVIEW-FIX.md`, and the canonical disposition gate records zero open findings. No advisory risk acceptance.
- Core regression at `209f3cb78e` (same production source plus disposition documentation): 735 tests + 4 properties, zero failures, 11 excluded; bounded gate log `regression-core.log`. Prior UI/browser regression subsequently passed 113 cases with zero failures/errors/skips/retries at `209f3cb78e15cfc9701b2af07901db20d65aad59`; `regression-browser/test-results/phase175-regression.xml` and cleanup status zero are retained outside the checkout.
- Latest repair runner cleanup: zero owned containers, volumes and networks remain for `scrypath_phase175_ce60384aa9_repair_96003`; `final-ui-browser/cleanup.txt` records status zero. Parent-owned test database remains for closeout checks. Retained previews and original workspaces were not seeded or modified.
