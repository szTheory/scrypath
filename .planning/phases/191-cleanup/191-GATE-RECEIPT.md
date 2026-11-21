# Phase 191 gate receipt

Tested SHA: ce250655b7e90e737f3a922287114c402c8a3b9d
repository_contracts: pass
core: pass

Date: 2026-11-20

Each long gate ran once on that commit, from a clean working tree, in this order and never at the same time (they share build output). Both runs used the worktree's own checkout, and no tracked file was edited while either ran. No capture or screenshot run happened. The repository_contracts run used the escalated permission for Git metadata that the task's fetch step needs, so the sandbox could not hide a result. The commit is the last code commit of the phase (the ledger reword); it sits on top of plan 191-01's three deletion commits and this plan's two guard commits.

- `mix verify.repository_contracts` (23:48:08 to 23:53:33 UTC, 159 tests, 0 failures) established that the repository's contract suite holds on this exact commit: the token test wrapper with its raised floor and the five new live names (the five source invariants and the favicon consumer scan run inside it), the brand pin with the new unthemed-favicon tripwire and the demo favicon byte-equality test, the workflow wiring test with the reworded ledger, the website contract wrapper, and the package contents test with the deleted verifier gone. The contrast child tests clone committed HEAD, so they ran against this exact commit and not against the working tree.
- `mix verify.core --exclude integration --exclude docs_contract` (23:53:42 to 23:59:46 UTC, 5 properties, 1183 tests, 0 failures, with the format check, the clean-workspace check, the warning-free compile, Credo, the docs build with warnings as errors and the no-Oban compile) established that the library's full non-integration test suite passes on this exact commit, and that `CONTRIBUTING.md` still builds as an ExDoc page after the ledger reword.
- `MIX_ENV=test mix test test/scrypath/no_human_gates_contract_test.exs` (2 tests, 0 failures) ran once as a cheap check that no plan or verification file in the phase carries the blocked markers.

Earlier run, not part of this receipt: plan 191-01 ran `mix verify.repository_contracts` once on commit `f7515d5cf5254f5ef799c29322b8672f7c9d6468` (the readers commit, before the old brand directory was deleted) and it passed (159 tests, 0 failures). That is a different SHA with different code, so it is recorded in `191-01-SUMMARY.md` as the earlier run and is not evidence for the tested SHA above.

Not claimed here: `ops-ui (path-scoped)` (it runs because `ci.yml` changed in plan 191-01), `ecommerce-mounted`, `backend`, `package` and the exact-head hosted `repository-contracts` run happen in hosted CI on the exact PR head, and their results are the Post-ship evidence in `191-PHASE-RECORD.md`. `mix verify.package` was not run locally (`files:` did not change). Nothing here says how any rendered page looks.

Staleness rule: any change outside `.planning/` after this receipt (a fix, a workflow edit, or a rebase onto a new main that brings code changes) needs one fresh gate run on the new SHA and a re-issued receipt. This receipt is then a stale receipt and a failed gate. The commits after the tested SHA are the receipt, the phase record, the CI-efficiency entry and the plan summary, all under `.planning/`.
