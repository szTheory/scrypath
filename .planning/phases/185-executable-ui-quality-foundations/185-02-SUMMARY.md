---
phase: 185-executable-ui-quality-foundations
plan: "02"
subsystem: ui-verification
status: complete
blocker: none
requirements-completed: [UIF-01]
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
  integrated: true
---

# Plan 02 retained implementation checkpoint

The bounded scanner, immutable-source ledger, first-parent history verifier and required-lane wiring are integrated. The maintainer explicitly approved squash-merging [bootstrap PR #124](https://github.com/szTheory/scrypath/pull/124); actual main commit `c1be269ec202deed8602c74683c1b9ce5e42eaa9` adds exactly the reviewed inventory. Production enforcement passed against that main, then GSD manifest-scoped cleanup merged and removed the clean Plan 02 worktree. The combined root build, Node suite and canonical root gate passed. No phase-goal completion is claimed.

## Root integration verification

On combined root `d624f30570ec56a72c0173122c0c1c68a4391486`, `mix compile --warnings-as-errors` passed, the Node suite passed 14 tests, and `mix verify.repository_contracts` passed 131 tests with zero failures. Logs are `/private/tmp/phase185-wave2-root-node.log` and `/private/tmp/phase185-wave2-root-canonical.log`. Schema drift gate passed; codebase drift was unavailable because no structure map exists. UI safety gate returned nonblocking with degraded task-row scope, not a visual approval. The repaired source files are present and the plan-scoped evaluation query resolves commits reachable on this phase branch. Tracking-only changes follow this cutoff.

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

## Task Commits

| Task | Commits | Disposition |
|---|---|---|
| 185-02-01 scanner and history | `9f5ec9f4`, `4d742386`, `9881487b`, `ff9c045f` | Implementation and actual history contracts; historical initial RED limitation retained above. |
| Dedicated initial inventory | `934de629` | Owned unpublished introduction reconciled before reduction; actual main introduction is separately `c1be269e`. |
| 185-02-02 CI transport and diagnostics | `757c240a`, `10532255` | Test assertions and production wiring; historical machine RED limitation retained above. |
| Parent value and public-command repairs | `89d606e9`, `6d5b5db4`, `743a6566` | Actual value-swap RED, repair and canonical malicious-ledger child. |
| Parent source and authority repairs | `b694b7d7`, `f62e8a90` | Actual omissions/exemption RED followed by scanner correction. |

## Integration and deviations

GSD cleanup succeeded with advisory scope warnings because the original creation call recorded the six paths as one comma-separated path instead of six whitespace-separated paths. Actual source diff was reviewed: declared artifacts, necessary contrast-child integration, and owned RED evidence; no unrelated runtime changes. The worktree was clean at cleanup and all code/evidence is reachable on the phase branch. Later dispatch uses the documented whitespace format. The original private histories remain in named recovery refs; no main history was rewritten.

The separate main bootstrap PR is an evidence-supported delivery deviation to preserve squash-only policy and exact first introduction. Main inventory parity is checked on actual merged source, not inferred from a SHA match.

## Resume ownership

No redispatch is needed. The orchestrator owns the final root gate, tracking and remaining phase waves. Preserve unrelated root config and retained-preview safety stop/data. No dependencies were added or installed. No subsequent main merge or release is authorized by this bootstrap approval.


## Self-Check: PASSED

Declared implementation artifacts exist, current plan commits resolve on this branch, actual merged-main inventory parity and production policy pass, and the post-integration build/Node/canonical gate passed. Historical TDD limitations, scope-warning disposition and hosted implementation/visual limits remain explicit.
