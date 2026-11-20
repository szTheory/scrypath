# Phase 189 gate receipt

Tested SHA: 76948c2ebd5baae68755f9d359faaef53af83c87
repository_contracts: pass
core: pass

Date: 2026-11-20

Each long gate ran once on that commit, from a clean working tree, in this order and never at the same time (they share build output). Both runs used the worktree's own checkout. No capture or screenshot run happened. The repository_contracts run used the escalated permission for Git metadata that the task's fetch step needs, so the sandbox could not hide a result.

- `mix verify.repository_contracts` established that the repository's contract suite, including the new website contract wrapper, the workflow wiring test with the new deploy checks, the brand pin and the docs contracts, holds on this exact commit.
- `mix verify.core --exclude integration --exclude docs_contract` established that the library's full non-integration test suite, the same wrapper and the isolated build without the optional dependency pass on this exact commit.

Not claimed here: `mix verify.ops_ui`, the browser lanes (`ecommerce-mounted`, `ecommerce-e2e`), `backend`, `package` and the website `build-and-check` run in hosted CI on the exact PR head, and their results are the Post-ship evidence in `189-PHASE-RECORD.md`.

Staleness rule: any change outside `.planning/` after this receipt (a fix, a workflow edit, or a rebase onto a new main that brings code changes) needs one fresh gate run on the new SHA and a re-issued receipt. This receipt is then a stale receipt and a failed gate. The commits after the tested SHA are the receipt, the phase-record line and the plan summary, all under `.planning/`.
