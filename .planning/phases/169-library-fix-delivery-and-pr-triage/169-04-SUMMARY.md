---
phase: 169-library-fix-delivery-and-pr-triage
plan: "04"
subsystem: delivery
tags: [tenant-scope, phoenix, meilisearch, exact-sha, pull-request]

requires:
  - phase: 169-02
    provides: Phoenix membership-gated tenant search and fresh local-package proof
  - phase: 169-03
    provides: bounded live repair and empty-scope evidence
provides:
  - joined, internally reviewed correction candidate with exact-source local and hosted evidence
  - PR #85 squash-merged to public main with exact candidate/main identity and CI receipts recorded
  - explicit user authorization to merge after all required checks passed; no GitHub review was claimed
affects: [169-05]

actuals:
  tokens: 18758
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - keep raw Meilisearch response out of tenant host results; revalidate records and facet counts against current Ecto rows
    - keep candidate, PR merge-ref, hosted workflow, and local package artifact identities separate

key-files:
  created:
    - .planning/phases/169-library-fix-delivery-and-pr-triage/169-04-SUMMARY.md
  modified:
    - examples/phoenix_meilisearch/README.md

key-decisions:
  - "Use persisted membership as the example host's tenant gate, and expose only current tenant database records/facets from host entrypoints."
  - "Keep the fresh local package artifact as proof input only; no Hex package was published."
  - "The user authorized a normal squash merge once all required CI checks were green. No GitHub review was submitted or represented as having occurred."

patterns-established:
  - "Record exact candidate, PR head/base/merge-ref, source-specific run, and artifact identities independently."
  - "A passing candidate is not public-main delivery; record the squash SHA, exact-source main run, named proof jobs, and candidate-to-main tree comparison."

requirements-completed: [DELIV-02]
coverage:
  - id: D1
    description: "The corrected tenant/facet candidate has local proof, exact-SHA hosted closeout, and user-authorized normal squash delivery with exact-source public-main evidence."
    requirement: DELIV-02
    verification:
      - kind: unit
        ref: "mix test test/scrypath/tenant_scope_contract_test.exs test/scrypath/facet_values_contract_test.exs test/scrypath/search_within_facet_test.exs — 21 tests, 0 failures at 46331b8"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract — 4 properties, 628 tests, 0 failures, 84 excluded at 46331b8"
        status: pass
      - kind: integration
        ref: "mix verify.phoenix_example and mix verify.phoenix_example --package — 18 tests, 0 failures each at 46331b8"
        status: pass
      - kind: integration
        ref: "SCRYPATH_INTEGRATION=1 mix verify.backend — repair and empty-scope scenarios passed at 46331b8"
        status: pass
      - kind: other
        ref: "Exact-SHA workflow_dispatch run 36629280522; PR #85 runs 36630385268 and 36630385258"
        status: pass
      - kind: integration
        ref: "Public-main push CI run 36644133759 at 933ad30645c41df9f21dd4ddfd2d5b93fbd48620; all five required jobs passed, Phoenix path/package job 109663038663 passed 18 tests in each mode, backend job 109663038664 passed"
        status: pass
    human_judgment: true
    rationale: "The user explicitly authorized a normal squash merge once required CI was green. All five required PR checks passed at the candidate SHA and GitHub completed the ordinary squash merge without bypass. No GitHub review exists; this summary records that accurately and does not claim one."

duration: "not measured"
completed: 2026-09-29
status: complete
---

# Phase 169 Plan 04: Joined Delivery and Public-Main Verification Summary

**Tenant/facet runtime, consumer, and repair proofs pass on the exact source now integrated on public main through user-authorized squash merge.**

## Performance

- **Duration:** Not measured.
- **Completed:** 2026-09-29.
- **Tasks:** 2 of 2 completed.
- **Plan-owned commits:** 1.
- **Candidate source files:** 19; four maintained lockfiles unchanged.

## Accomplishments

- Reconciled `examples/phoenix_meilisearch/README.md` with the named path and fresh local-package proof. It explains persisted synthetic membership, separate raw-library observations and tenant-plus-ID host hydration, keyword facets, and the local-artifact-versus-Hex boundary while retaining Phase 168 graph guidance.
- Re-reviewed the corrected host boundary after Plan 02 addressed the prior findings. The host search now returns only database-hydrated current published tenant records; host facets include only current published tenant categories and recompute counts. `Post.changeset/2` no longer casts `tenant_id`; the context assigns it only after persisted membership validation.
- Passed joined candidate verification at `46331b89035174ee8383b32630621555f1fef619`:
  - Focused tenant/facet/search contracts: 21 tests, 0 failures.
  - Strict fast suite: 4 properties, 628 tests, 0 failures, 84 excluded.
  - Phoenix path proof: 18 tests, 0 failures. Source and resolved lock digest: `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f`. The named host receipt reported tenant A ID `6` and category/facet `phone-a:1`; tenant B ID `8` and `phone-b-forbidden:1`.
  - Fresh local-package proof: artifact tag `v0.3.13`, artifact commit `df883fe11c63ee3dcb1fa5020a5fbbd38cea4289`; consumer compiled and 18 tests passed. Source lock digest `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f`; resolved package graph digest `3d99e6e9cef7db24ca34ddc7a67b6596fffd204f2ca9f54d6b70c2b84761ad75`. Tenant A receipt ID `22`, `phone-a:1`; tenant B ID `24`, `phone-b-forbidden:1`. This was a local artifact, not a Hex install or publication.
  - Live backend gate: all named scenarios passed. The bounded repair receipt selected ID `166000040`, with successful task IDs `75` and `76`; report-only observation made 3 reads and 0 mutations. Empty-scope proof passed.
  - `git diff --check` passed, the four maintained lockfiles had no diff, and the candidate tree was clean at the selected SHA.
- Exact-source GitHub closeout passed on run [36629280522](https://github.com/szTheory/scrypath/actions/runs/36629280522), event `workflow_dispatch`, head `46331b89035174ee8383b32630621555f1fef619`. The five required jobs, coverage, and `closeout-attestation` succeeded. Coverage artifact ID `11062335979`, digest `sha256:faa01f5ad6770728751d43ba8b9452ad4dd71cfa3fecdc663c550c673460cdfc`; closeout artifact ID `11062615886`, digest `sha256:c9f79cee21716caf0b294b49c28ec3ab5ea92595022cd6e75886f1c89a4cb3ef`. Both artifacts were unexpired at verification time.
- Opened [PR #85](https://github.com/szTheory/scrypath/pull/85), titled `fix: restore tenant-scoped search and facets`. Its head is `46331b89035174ee8383b32630621555f1fef619`; base is `2832e91d725d70eff9ba11d08052260ba17e2747`; observed GitHub merge-ref is `dbe9d0a80dd71a69005743b6521a7703dee1ffe0`. The `pull_request` CI run `36630385268` and Website run `36630385258` completed successfully at the candidate head. All five required PR checks and the Phoenix example advisory passed; coverage, E2E, and closeout-attestation are skipped for the pull-request event. Exact-SHA workflow-dispatch evidence remains a separate receipt.
- The user explicitly authorized a normal squash merge once required CI was green. Immediately before merging, PR #85 still pointed at the recorded candidate SHA and all five required checks passed. No GitHub review was submitted, no reviewer identity was simulated, and no admin bypass was used.
- PR #85 merged at `2026-09-29T23:14:36Z` as `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`; GitHub reports `merged_by: szTheory`. The live `main` ref resolved to that same SHA.
- Candidate and squash-main commits have the identical full Git tree SHA `48605fa22efafd8c37ad563ea84949a1fdf05988`; the trees are byte-identical, so no source blob changed between candidate proof and public main.
- Exact squash-main push CI run [36644133759](https://github.com/szTheory/scrypath/actions/runs/36644133759) completed successfully at the squash SHA. All five required jobs passed: `core` job `109663038524`, `package` job `109663038585`, `repository-contracts` job `109663038262`, `backend` job `109663038664`, and `ecommerce-mounted` job `109663038560`.
- The same push run's Phoenix advisory job `109663038663` passed both named modes: path mode reported 18 tests, 0 failures; local-package mode reported 18 tests, 0 failures. Tenant A returned only ID `6`, `phone-a:1`; tenant B returned only ID `8`, `phone-b-forbidden:1`. The path lock stayed unchanged. The local package artifact was tag `v0.3.13`, artifact commit `c8dfbfc9a9cf472c3912ed6d5f08cb3030b633b7`; staged dependencies resolved to that local artifact, and the consumer compiled. This remains local package evidence, not Hex publication.
- The exact-candidate closeout run `36629280522` remains a separate receipt with successful backend repair/empty-scope proof and immutable coverage/attestation artifacts. Its source tree equals the squash-main tree above. The public-main `backend` job also passed at the squash SHA.

## Task Commits

1. **Task 1: Prove the joined candidate and open its review PR** — `6281630` (`docs(169-04): describe tenant example proof`). The Plan 02-owned security correction was completed in owner commit `75963eefbc69ef58254886349c48fae8c1b76402` and cherry-picked into the delivery candidate as `46331b89035174ee8383b32630621555f1fef619`.
2. **Task 2: Squash through actual policy and verify integrated public main** — PR #85 squash-merged at `933ad30645c41df9f21dd4ddfd2d5b93fbd48620` after explicit user authorization and passing required checks. No GitHub review was recorded; no self-approval or admin bypass was used. Public-main checks and exact-source comparison are recorded above.

## Review Findings

The original internal review artifact identified two blockers and one README warning. CR-01 (raw search payload and aggregates escaped hydration) and CR-02 (`tenant_id` mass assignment) were fixed through the owning Plan 02 task and covered by recorder/live tests. WR-01 (README omission) was fixed in `6281630`. The follow-up review artifact found no remaining blocker or new high/medium finding in the corrected boundary and affected tests.

## Evidence and identity boundaries

- Public-main base refreshed before proof and immediately before PR creation: `2832e91d725d70eff9ba11d08052260ba17e2747`.
- Candidate / PR head: `46331b89035174ee8383b32630621555f1fef619`.
- PR #85 merge-ref before squash: `dbe9d0a80dd71a69005743b6521a7703dee1ffe0`.
- Squash-main SHA: `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`.
- Public-main push CI run: `36644133759`, event `push`, conclusion `success`, head SHA equal to squash-main.
- Candidate and squash-main tree SHA: `48605fa22efafd8c37ad563ea84949a1fdf05988` for both.
- Published package: none.
- Bounded logs and the closeout receipt are retained outside the tested tree in external session storage.

The first closeout invocation was rejected before any push because same-command environment assignment left the expanded `--sha` empty (`expected a full lowercase 40-character SHA, got true`). The corrected invocation exported the variables first and completed successfully as run `36629280522`; this was a command invocation error, not a candidate test or workflow failure.

## Review authorization and remaining work

The original plan called for an actual GitHub maintainer review. The user then explicitly authorized merging once CI was green; after rechecking the unchanged candidate and all five required checks, PR #85 was merged through the normal squash path. GitHub still reports no review and an empty `reviewDecision`, so this record does not claim a GitHub review occurred. DELIV-02 is complete under the user's explicit merge authorization and the passing exact-source public-main receipts. Plan 05 is now unblocked. No Hex package was published.

The original maintainer checkout's unrelated dirty state was left untouched. The isolated Plan 04 Postgres and Meilisearch services were stopped after proof.

## Self-Check

- Pass: candidate SHA, PR head/base/merge-ref, closeout run, PR CI runs, and artifact IDs are recorded separately.
- Pass: the summary distinguishes the locally built package artifact from Hex publication; `published package: none`.
- Pass: DELIV-02 has source-specific candidate and exact-main receipts; Plan 05 can use the distinct squash-main identity.
- Pass: PR #85 is merged at the recorded SHA; no GitHub review is claimed, user authorization is explicit, and no bypass was used.

---
*Phase: 169-library-fix-delivery-and-pr-triage*
*Plan: 04 — complete; user-authorized public-main delivery verified*
