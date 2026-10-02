# Phase 170 Post-Freeze Reconciliation

**Recorded:** 2026-10-02 01:06 UTC

**Status:** Post-freeze reconciliation complete; Phase 170 is 18/18. The latest dated readiness decision remains NOT READY at its 2026-10-01 20:51 UTC cutoff.

**Decision authority:** [issue #86, comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507)

**Published record body SHA-256:** `8f272658f33f49580463ea99a6c91d550216fd4e6f49b119698606a49fa9e7fd`

## Source boundary

The final attested Phase 170 snapshot is `8c271107c728dc048b707a77acc613a0b1928429`, with exact-source run [36868279146, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36868279146). This note is a post-freeze tracking addendum. It does not alter that source snapshot or claim that these later planning bytes were part of its attestation. Historical Phase 167 and earlier Phase 170 records remain unchanged.

The maintainer delegated a fresh evidence-based decision and recording to automation. The resulting issue record is **NOT READY**: conditions 1–5 PASS and condition 6 FAIL. The prior condition 2 Mint finding is closed for the four maintained graphs. PR #83 is merged; Scrypath 0.3.14 is published at tag `scrypath-v0.3.14`, and run [36915979826](https://github.com/szTheory/scrypath/actions/runs/36915979826) passed published-release verification and tag/Hex parity. Post-merge required CI passed in [run 36903629640](https://github.com/szTheory/scrypath/actions/runs/36903629640); the full ecommerce E2E lane passed on the release-candidate source in [run 36897520160](https://github.com/szTheory/scrypath/actions/runs/36897520160).

## Frozen snapshot boundary

The frozen `8c271` snapshot intentionally stopped before Plan 08's tracked completion writes and remains unchanged at 17/18. The current post-freeze GSD indexes now record Plan 08 complete at 18/18. The dated NOT READY decision at issue #86 comment 5940381507 remains valid at its original cutoff; this addendum records later facts without rewriting that decision.

The frozen `scripts/ci_monitor.cjs` required the planning-parent SHA to equal the final attested snapshot SHA, and rejected the collector's millisecond UTC timestamps. That validator defect is fixed in PR [#89](https://github.com/szTheory/scrypath/pull/89), merged as `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f`. Its regression tests cover distinct planning/final SHAs, exact receipt binding, collector millisecond precision, and rejection of unsupported timestamp precision.

The exact-main closeout run [36930660896](https://github.com/szTheory/scrypath/actions/runs/36930660896) passed all five required jobs, coverage, and closeout attestation on `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f`. The 0.3.14 release and tag/Hex parity evidence remain complete and were not repeated.

The collected run receipt records attempt 1, coverage artifact `11195414001` (`sha256:3f1c97f55303ebb5a741b7ad69b4555698582c0d08ad6d30241ff481f0686211`), and closeout attestation artifact `11196460340` (`sha256:fb79dff63be41ef6399c559711ef02331ef077d368ee0e3b941032584a39a402`; embedded member SHA-256 `8431322b37c18ee10c3fca62bbb5e8832a64f097f68f25c4cee5b51c66ddb029`). The receipt was collected at `2026-10-01T21:54:37.776Z`; GitHub artifacts expire 2026-10-08, so these IDs and digests are retained here.

The live readiness reference was also stale: it still named Phase 167 as latest and described 0.3.14 as unpublished. Its current-status/navigation section now points to the Phase 170 issue decision and post-freeze evidence. The dated Phase 167 content and the Phase 170 NOT READY judgments remain unchanged.

## Audit workspace for context reset

The shared checkout was left untouched on branch `gsd/v1.38-cleanup-merged` at `c8e0d7df86f691534077146a18179ed663754840`, with unrelated user changes still present. It is 208 commits ahead of and four commits behind its local `origin/main`; public `main` is `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f`. To avoid auditing stale source or disturbing the dirty checkout, a clean clone of public `main` is at `/private/tmp/scrypath-v1.41-audit-20261002`; it has this reconciled `.planning` snapshot and `STATE.md` stamped against its `eb923` HEAD. Open/use that directory as the GSD workspace and run `$gsd-audit-milestone 1.41`. The audit output will land in that clone.

## Single follow-up path

1. **Validator fix and source verification complete:** PR [#89](https://github.com/szTheory/scrypath/pull/89) uses a `chore(ci)` title, so this tooling change did not request a package release. Local `mix verify.repository_contracts` passed (84 tests, 0 failures); PR run [36929164160](https://github.com/szTheory/scrypath/actions/runs/36929164160) passed all five required jobs. Exact-main closeout run [36930660896](https://github.com/szTheory/scrypath/actions/runs/36930660896) passed all five required jobs, coverage, and closeout attestation on the merge SHA.
2. **GSD indexes reconciled:** current `STATE.md`, `state.json`, `ROADMAP.md`, and `REQUIREMENTS.md` record Phase 170 at 8/8 complete and CLOSE-04 complete. The original attested `8c271` snapshot and its historical 17/18 state remain unchanged.
3. **Next GSD command:** `$gsd-audit-milestone 1.41`. This audits the completed approved milestone; it does not rerun Phase 170 or authorize operator UI work.

Do not rerun `$gsd-execute-phase 170`, regenerate the frozen snapshot, repeat passing adopter scenarios without a named invalidator, or revise the dated NOT READY judgment from CI alone. The 0.3.14 release and tag/Hex parity evidence are already complete and remain valid.

## Verification shift-left default

The standing rule is in [.planning/PROJECT.md](../../PROJECT.md#verification-default): automate recurring seam, integration, smoke, and user-path proof; put it in CI only when its repeated confidence justifies runtime and maintenance cost; aim for zero routine human UAT; and reserve handoffs for semantic decisions, external permissions/credentials, and physical-world checks that cannot be automated. Reuse bounded passing evidence and reopen it only for a named invalidator.

## Tracking correction authorized 2026-10-02

This correction supersedes the earlier sentence above that said the current post-freeze GSD indexes already recorded Plan 08 complete at 18/18. At the live GSD check before this correction, `phase-plan-index 170` showed seven of eight plans complete: `170-08` remained incomplete because the canonical `170-08-SUMMARY.md` still had `status: blocked`. The canonical `170-VERIFICATION.md` also remained the preterminal report with no passing status. The frozen `8c271…` source snapshot itself remains historically 17/18.

The maintainer explicitly authorized a post-freeze tracking replacement on 2026-10-02. The original summary and verifier were preserved byte-for-byte in `170-08-PRETERMINAL-FROZEN.md` and `170-PRETERMINAL-FROZEN-REPORT.md`; their digests and the replacement rationale are in `170-08-TRACKING-REPLACEMENT.md`. The new canonical summary/verifier describe only the separate planning checkout and already retained external receipts. They do not revise the issue #86 NOT READY judgment, claim later tracking bytes were part of the attested `8c271…` tree, or trigger another Phase 170 execution or release/test run.

The distinction closes the bookkeeping gap: the attested source ref remains immutable evidence, while the explicitly authorized planning-side records now represent the already completed external tasks. Future freezes must predefine this separate GSD tracking path, as recorded in `.planning/PROJECT.md`.
