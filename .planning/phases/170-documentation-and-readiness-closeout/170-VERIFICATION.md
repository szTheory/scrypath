# Phase 170 Preterminal Verification Report

**Status:** Plans 01–06 prerequisites recorded; phase closeout is not complete.
**Assessment cutoff:** 2026-10-01T01:56:33Z
**Decision:** No six-condition judgment or READY/NOT READY decision is made here. Phase 167 remains the latest dated NOT READY assessment until a later maintainer decision is published to issue #86.

## Scope and source identities

This report verifies the completed documentation/tooling delivery and Plan 06 factual reconciliation. It does not claim final-source attestation, release publication, semantic readiness, or completion of Phase 170. Candidate, merged-main, local-package, published-package, and planning-source identities remain distinct in 170-READINESS-INPUTS.json.

- PR #87 candidate: 00f8ea1655d189c99a8eb236c2caaadf2633c169.
- PR #87 squash on public main: 87d74259a9f569c6b11c8d9481f5465a172c70ba.
- Exact-main push run 36795877117 passed the five required jobs: backend, core, ecommerce-mounted, package, and repository-contracts. Deep-quality also succeeded. The path-scoped ecommerce E2E job was skipped.
- Latest named full scheduled E2E evidence remains run 36681173632 on 933ad30645c41df9f21dd4ddfd2d5b93fbd48620. The PR #87 exact comparison confirms the relevant ecommerce paths were unchanged, but this is not a fresh full E2E run on current main.
- Latest published package remains 0.3.13 at scrypath-v0.3.13. Release Please PR #83 proposes 0.3.14 at head 64963c7042c451f9d4932fee7850d8bf7ca93684. Its package check passed, but the PR is open and blocked by its required approving review. No 0.3.14 tag, GitHub release, or Hex package exists; a 2026-10-01 02:05 UTC refresh confirmed public main is unchanged, the tag is absent, and Hex latest stable remains 0.3.13.

## Roadmap and plan outcomes

| Area | Observed outcome | Status |
|---|---|---|
| First-hour and sync documentation | README and guides shipped through PR #87; recorded contract, route, and docs-build checks passed. | Verified for the named documentation changes |
| Factual closeout tooling | Collector, validator, comment renderer/readback, and tests shipped through PR #87. Automation preserves supplied judgments and does not infer semantic readiness. | Verified for recorded fixtures and exact-main delivery |
| Issue pointer | Issue #86 was created with explicit authorization; repository, title, body, author, and body digest were read back. | Verified as a decision location only |
| Current evidence packet | Seven baseline dimensions, 24 claims, eight workflows, six condition definitions, and named invalidators retained. Current main, E2E freshness, security, and release boundaries are reconciled in the input ledger. | Verified by Plan 06 input validator |
| Patch release | Normal release path was authorized by the user, conditional on repository gates. Actual required review is absent; no protection bypass or simulated review occurred. | Blocked before merge/publication |
| Terminal readiness | Six judgments, final exact-source receipt, and dated public decision comment remain future actions. | Pending Plans 07–08 and the accountable maintainer |

## Executed evidence

- Plan 01 recorded 74 documentation-contract tests, 8 Phase 112 tests, 25 adopter tests, the fast suite (628 passed, 85 excluded), warning-free documentation generation, route retention, and preservation-boundary comparisons.
- Plan 02 recorded the full closeout-tool test file and fast suite. The delivered PR #83 candidate was also checked in an isolated checkout: mix test test/scripts/ci_monitor_test.exs passed 15 tests with 0 failures in 6.80 seconds.
- Plan 03 recorded input validation as FACTUAL_ONLY_VALID with semantic_decision null and issue #86 readback matching the authorized proposal.
- Plan 04 recorded candidate closeout run 36780859495 and exact-main run 36795877117. The latter passed all five required checks on the exact squash SHA.
- Plan 05 recorded mix verify.package passing 81 tests and building/unpacking scrypath-0.3.14 on the isolated release candidate. Exact-head workflow run 36797983093 reported all five required contexts successful. A 2026-10-01 02:05 UTC refresh confirmed the PR is still OPEN on the same head/base, with no reviews, empty statusCheckRollup, blank reviewDecision, and mergeStateStatus BLOCKED; branch policy still requires an actual approving review.
- Plan 06 records current source comparisons and the current factual input validator result below. The task-owned test command was run against the exact PR #83 source tree at 64963c7042c451f9d4932fee7850d8bf7ca93684.

## Outstanding acceptance predicates

1. Plan 07 must finish tracked bookkeeping, milestone-arc reconciliation, the owned cleanup inventory, and the final frozen source allowlist before attestation.
2. Before freeze, Plan 07 must refresh PR #83 facts. If a real approving review arrives on unchanged head 64963c7042c451f9d4932fee7850d8bf7ca93684, Plan 06/05 must rejoin the normal release path and update this factual packet before freeze.
3. Plan 08 must obtain the exact-source closeout attempt/receipt, then the accountable maintainer must provide all six judgments, any accepted risks, and the final decision. Only that maintainer may approve the exact rendered issue comment.
4. The final issue comment must be posted and read back without any tracked repository write after source attestation.

The current results establish named, bounded prerequisites. They do not imply a READY decision or satisfy a human judgment.
