# Phase 190 gate receipt

Tested SHA: f6c78bd243602701857891dd77332d602a392d3e
repository_contracts: pass
core: pass

Date: 2026-11-20

Each long gate ran once on that commit, from a clean working tree, in this order and never at the same time (they share build output). Both runs used the worktree's own checkout. No capture or screenshot run happened. The repository_contracts run used the escalated permission for Git metadata that the task's fetch step needs, so the sandbox could not hide a result.

- `mix verify.repository_contracts` (21:19:53 to 21:25:55 UTC, 174 tests, 0 failures) established that the repository's contract suite, including the workflow wiring test with the new `ops-ui` path-pattern checks and the ledger row, the brand pin, the website contract and the docs contracts, holds on this exact commit.
- `mix verify.core --exclude integration --exclude docs_contract` (21:26:34 to 21:33:37 UTC, 5 properties, 1195 tests, 0 failures, with format, warning-free compile, Credo, the docs build and the no-Oban compile) established that the library's full non-integration test suite, including the namespace fence, passes on this exact commit.

An earlier round ran on `47558725c212cbb15935b4169b8d61053a6f0a3d`: `mix verify.repository_contracts` passed there, and `mix verify.core` failed on one test, the namespace fence, because a shared test stub under `scrypath_ops/test/support` named the Sigra operator context. That was a real defect in this phase's own change. It was fixed in code (commit `f6c78bd2`, without touching the fence), so the earlier round's results belong to a superseded SHA and are not part of this receipt. Both gates were rerun once each on the fixed commit above. Details: `190-02-SUMMARY.md`, deviation 2.

Not claimed here: `mix verify.ops_ui`, the browser lanes (`ecommerce-mounted`, including the Cancel-focus line in `operator.spec.ts`, and `ecommerce-e2e`), `backend`, `package` and the advisory dispatch run in hosted CI on the exact PR head, and their results are the Post-ship evidence in `190-PHASE-RECORD.md`. The whole ScrypathOps suite (546 tests) and the namespace fence test were run locally on the fixed code and passed. The workflow wiring test, the two hand-run node tests and `playwright test --list` passed on the code just before the fix, and the fix touches nothing they read (it changes two test files under `scrypath_ops/test`).

Staleness rule: any change outside `.planning/` after this receipt (a fix, a workflow edit, or a rebase onto a new main that brings code changes) needs one fresh gate run on the new SHA and a re-issued receipt. This receipt is then a stale receipt and a failed gate. The commits after the tested SHA are the receipt, the phase-record update, the CI-efficiency note and the plan summary, all under `.planning/`.
