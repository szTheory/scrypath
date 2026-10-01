# Phase 170 Preterminal Code and Evidence Review

**Review cutoff:** 2026-10-01
**Status:** No unresolved high-severity software finding in the completed Plans 01–06; release and terminal gates remain open.

## Reviewed surfaces

- PR #87's exact seven-file documentation/factual-tool candidate and merged public-main source.
- The isolated Release Please PR #83 package candidate and its live branch-policy/review state.
- The 24-claim readiness ledger, eight workflow rows, 58 invalidators, current source comparisons, and the four Plan 06 reports.
- Existing task-owned summaries and exact-source command receipts. Historical Phase 164 bytes and unrelated maintainer edits were treated as protected inputs.

## Findings and dispositions

| Finding | Severity | Disposition |
|---|---|---|
| Decision-comment text could be interpreted as Markdown/HTML; the collector had artifact digest and URL join mismatches; record nesting and issue identity needed stricter checks. | High before fix | Resolved in the delivered factual tooling. Rendering escapes supplied text and link data, REST/action identifiers are canonicalized and joined, record shapes and issue ownership/author/title/body/status are checked, and regressions are covered by the 15-test suite. |
| An out-of-allowlist documentation-contract path was included during candidate preparation. | Medium before correction | Restored before review; final PR #87 has exactly the seven declared paths. |
| PR #83 has an empty GitHub check rollup and no required approving review despite exact-head workflow check-runs succeeding. | Release gate | Open by repository policy. Do not merge or publish until an authorized reviewer approves and check recognition is refreshed. |
| Current-main full ecommerce E2E evidence is not fresh because the exact-main push skipped the path-scoped job. | Evidence limit | Accurately bounded in the input ledger and workflows. The last named full E2E run is on the prior SHA; the relevant PR #87 paths were unchanged. No claim of a fresh current-main full run is made. |
| P-170-DOC still asks for an accountable semantic review of documentation quality. | Judgment | Unresolved for the maintainer. Structural route assertions and a successful docs build cannot settle it. |
| A historical Phase 164 assessment suffix includes an absolute temporary-cache pathname. | Historical privacy debt | Its bytes are pinned and preserved. It is not a credential and is not repeated in current report text; changing it would rewrite the historical record. |

## Delivery and source review

PR #87 merged through the normal squash path at 87d74259a9f569c6b11c8d9481f5465a172c70ba. Exact-main run 36795877117 passed all five required jobs; deep-quality succeeded, and the path-scoped E2E job skipped. The documented limits remain consistent with those results.

PR #83 at 64963c7042c451f9d4932fee7850d8bf7ca93684 passed its package gate and exact-head required check-runs, but A 2026-10-01 02:05 UTC refresh confirms GitHub still reports BLOCKED because its required approving review is absent; the PR remains OPEN on the same head/base with empty reviews and status rollup. User authorization covers the normal release chain only when the repository gates are met. No merge, tag, release, or Hex publication occurred.

The input ledger preserves all 24 baseline claims and seven dimensions, the eight named adopter workflows, evidence freshness and source boundaries, the 0.3.13 published-package identity, and the blocked 0.3.14 candidate. It leaves all six readiness judgments unfilled and does not imply readiness from CI.

## Remaining review gates

Plan 07 must finish source bookkeeping, owned cleanup, privacy review, and exact final snapshot freeze. Plan 08 must collect the exact-source terminal receipt and the actual maintainer's six judgments and approved issue comment. If PR #83's review gate clears before freeze, refresh facts and complete its normal release path before freezing. Until then, no Phase 170 completion or READY claim is supported.
