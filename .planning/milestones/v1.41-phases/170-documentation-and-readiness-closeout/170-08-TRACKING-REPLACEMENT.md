# Phase 170 Plan 08 Tracking Replacement

**Authorized:** 2026-10-02 by the maintainer, who approved either a post-freeze replacement or milestone completion and delegated the choice. The selected route was to preserve the frozen bytes, replace the canonical GSD tracking records, rerun the milestone audit, and complete v1.41 only if readiness passed.

## Preserved original bytes

The original preterminal files were copied byte-for-byte before the canonical replacements:

| Original canonical path | Preserved copy | SHA-256 | Result |
|---|---|---|---|
| `170-08-SUMMARY.md` | `170-08-PRETERMINAL-FROZEN.md` | `dec9a5f189622595db5e42f6cec0b8e11d20eb5f6844ce96c86f6ddde7a0f3af` | Match confirmed before replacement |
| `170-VERIFICATION.md` | `170-PRETERMINAL-FROZEN-REPORT.md` | `1ed89366cac973300ca943c0200615e2970cfdf53ae10063295a5bdcb3e88d20` | Match confirmed before replacement |

## Tracking discrepancy and resolution

The frozen `8c271107c728dc048b707a77acc613a0b1928429` snapshot correctly remains the historical 17/18 source snapshot. Its final exact-source attestation is run [36868279146, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36868279146). The shared planning checkout at `c8e0d7df86f691534077146a18179ed663754840` is a separate, later GSD control-plane view.

Before replacement, the live GSD phase-plan index listed Plan 08 as incomplete because the frozen canonical summary had `status: blocked`; Phase 170 had no current passing verifier. This was a tracker state, not missing external work. The receipt packet already recorded the attestation, durable issue decision, post-merge/release evidence, and exact-main closeout:

- Actual maintainer decision: issue [#86, comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507), conditions 1–5 PASS, condition 6 FAIL, overall **NOT READY** at its original cutoff.
- Published Scrypath 0.3.14 and tag/Hex parity: [run 36915979826](https://github.com/szTheory/scrypath/actions/runs/36915979826).
- Post-merge required CI: [run 36903629640](https://github.com/szTheory/scrypath/actions/runs/36903629640).
- Exact-public-main closeout after validator fix PR #89: [run 36930660896](https://github.com/szTheory/scrypath/actions/runs/36930660896) at `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f`.
- Final frozen-snapshot attestation and retained receipt IDs/digests: `170-POST-FREEZE-RECONCILIATION.md`.

The canonical summary now records Plan 08 complete, and the canonical Phase 170 verifier records the above bounded outcomes with an explicit maintainer-authorized tracking override. Neither file is claimed as part of `8c271…`; no change was made to the attested source identity or the terminal issue comment. No Phase 170 execution, product tests, release checks, or UAT were repeated.

## Freeze/tracking rule for future work

Treat the attested source ref and the GSD planning checkout as separate records. Before a terminal freeze, define where the later plan summary and phase verification will be recorded. If the attested ref must remain immutable, preserve its preterminal planning bytes and write a dated, authorized reconciliation in the separate planning checkout; never rerun an already completed external terminal flow merely to satisfy GSD indexing. The milestone verifier must distinguish the frozen source receipt from the current planning tracker.
