---
phase: 185-executable-ui-quality-foundations
plan: "02"
subsystem: ui-verification
status: blocked
blocker: separate_bootstrap_pr_merge_authority
requirements-completed: []
requires:
  - phase: 185-01
    provides: canonical repository-contracts lane
provides:
  - retained scanner/history implementation, not yet integrated
key-files:
  created:
    - scripts/ci/ui_literal_policy.cjs
    - scripts/ci/ui_literal_policy.test.cjs
    - scripts/ci/ui-literal-baseline.json
    - test/mix/tasks/ui_literal_contract_test.exs
  modified:
    - dev/mix/tasks/verify.phase99.ex
    - .github/workflows/ci.yml
actuals:
  tasks_implemented: 2
  plan_head_before: 0d39fa8b40e3a666d36256ac9cf95b6313f9e732
  repaired_source_head: f62e8a9090417758a2608e436574fdb90eb61db7
  integrated: false
---

# Plan 02 retained implementation checkpoint

The bounded source scanner, immutable-source ledger, first-parent history verifier and existing required-lane wiring are implemented in this worktree. The plan is not integrated or complete. A separate data-only main merge is needed before later cleanup under the repository's squash-only policy. [Bootstrap PR #124](https://github.com/szTheory/scrypath/pull/124) is a draft awaiting explicit merge authority with all five required checks passed on its proposed head. Primary `.planning/phases/185-executable-ui-quality-foundations/185-02-DELIVERY-REVIEW.md` owns the cross-checkout delivery decision and continuation.

## Behavior

- Scan the four authored UI roots with finite file, source and Git bounds, excluding generated/vendor/test material. Recognize raw styling hex, arbitrary utility values, inline style attributes and literal z utilities. The reader is static and does not execute source or resolve arbitrary runtime-generated styles.
- Pin the initial multiset to immutable bootstrap `767f368473f17fba43d7be4675c53ab65a87530c`: 45 occurrences and 45 identities, also exactly matching freshly fetched main. The dedicated owned introduction is `934de629`; it precedes reductions. No committed main inventory has been enlarged.
- Preserve exact meaningful values and multiplicities, structural markup/selector and bounded named-function contexts; ignore harmless line/comment movement. Reject ledger metadata/count tampering, source mismatches, first-parent growth/deletion/reversal and stale candidates exceeding fresh trusted target reductions.
- Validate canonical origin and event authority for local, PR, push, schedule and manual paths. No production CLI override selects refs or skips history.
- Exercise the actual public repository command in the matching malicious source/ledger child, with recursive negative tests excluded only inside that disposable child. Run production CLI from the existing full-history required CI lane.

## Parent review repairs

The executor's original implementation missed inline-style values, SVG presentation colors, topbar styling color, additional static class arguments, and falsely authorized CSS from theme syntax inside comments/strings. Parent review reproduced the inline-style and source-context bugs with real assertion failures, repaired them, strengthened structural anchors and corrected overlapping JSX reader counts. The final immutable inventory was regenerated from Git objects, then reconciled into the owned unpublished introduction using a preserved recovery ref. No remote main history was rewritten. Root `185-02-DELIVERY-REVIEW.md` contains the detailed disposition.

## Evidence and historical limits

- Final `node --test scripts/ci/ui_literal_policy.test.cjs`: 14 passed, zero failed. Log: `/private/tmp/phase185-02-final-node.log`.
- Final canonical `mix verify.repository_contracts`: 131 tests passed, zero failures, exit zero on repaired source `f62e8a9090417758a2608e436574fdb90eb61db7`. Log: `/private/tmp/phase185-02-final-canonical.log`. Production CLI also passed against fresh canonical main with all 45 occurrences (`/private/tmp/phase185-02-final-policy.log`).
- Actual production-checker delivery reproductions: combined introduction/reduction squash rejects; separate data-only introduction then the same cleanup squash passes. Root `185-02-DELIVERY-PROOF.json` preserves machine receipts. These synthetic Git histories prove delivery shape; they do not claim hosted implementation acceptance.
- Accepted parent regressions: `185-02-inline-style-RED.json` and `185-02-source-context-RED.json` preserve actual scanner assertion failures before their respective repairs. Temporary TAP logs remain under `/private/tmp/phase185-*`.
- The original Task 1 failed only an ordering assertion against already-present uncommitted implementation. It is not valid behavioral RED. The original Task 2 historical failure has no machine RED receipt. Do not retroactively call either accepted TDD evidence. Current passing tests do not repair that historical discipline limitation.
- No hosted run has accepted this implementation. PR #124 runs checks on its data-only branch, not these scanner changes. No current visual, independent design, phase-goal or release approval is claimed.

## Resume ownership

Keep this worktree and branch; do not merge, redispatch or clean it before the explicit bootstrap merge decision. The orchestrator owns main verification, GSD-adapter integration and the remaining waves after authorization. Preserve the unrelated root config edit, stale retained-preview stop and data. No dependencies were added or installed.
