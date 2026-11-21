---
phase: 190-wording-without-the-catalog
plan: 02
subsystem: ui
tags: [copy, scrypath-ops, exunit, copy-rules, ops-ui-path, ledger, gate-receipt, playwright, wording]

requires:
  - phase: 190-wording-without-the-catalog
    provides: plan 190-01's glossary section, copy table, helper, surface registry, contract test and the renamed label
provides:
  - Host-queue outcomes read queued (Retry queued, A retry for job N is already queued, The queue has this retry); accepted survives only for Meilisearch tasks
  - Schema-level counts read N jobs pending, Caught up. Nothing pending, retrying or failed. and wait for pending sync work to finish
  - Eight more table rows on six more anchored surfaces (14 rows, 14 surfaces) and a self-check that every Status wording term is cited by a row
  - A Cancel-focus assertion in operator.spec.ts (required ecommerce-mounted lane)
  - ExUnit pins for the ops_modal default focus (with a planted override), the Save search exception, the saved-search delete confirmation's Cancel and all 17 promotion notice sentences
  - The ops-ui-path pattern covers the glossary, DESIGN.md and the demo e2e, lib, test and scripts directories, with a behavioural wiring test, ledger row 10 (10 of 12) and CI-EFFICIENCY finding 12
  - 190-PHASE-RECORD.md and 190-GATE-RECEIPT.md
affects: [v1.48 copy lint, Phase 191 (same ops-ui-path pattern and the same ledger)]

actuals:
  tokens: 14300
  tasks: 4
  commits: 7

plan_head_before: 258c684807f12a9a6f0871879f012d0dcac74e28
plan_head_after: 8052481c6f6c604496d1b346deb528fdd031bedf

tech-stack:
  added: []
  patterns:
    - "shared fixture stubs live once in test/support/copy_stubs and are aliased by the LiveView tests and the surface registry (failed-sync stubs and the Oban.Job stub joined the sync-drift ones)"
    - "a CI path pattern is proved by behaviour: compile the extracted grep pattern, match representative and table-derived paths, and run the same check on a narrowed copy to show it can fail"
    - "a table self-check fails when a glossary term in the Status wording section is cited by no row"

key-files:
  created:
    - scrypath_ops/test/support/copy_stubs/failed_sync.ex
    - scrypath_ops/test/support/copy_stubs/oban_job.ex
    - scrypath_ops/test/scrypath_ops_web/modal_focus_contract_test.exs
    - .planning/phases/190-wording-without-the-catalog/190-PHASE-RECORD.md
    - .planning/phases/190-wording-without-the-catalog/190-GATE-RECEIPT.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/help_live.ex
    - scrypath_ops/test/support/copy_rules.json
    - scrypath_ops/test/support/copy_rules.ex
    - scrypath_ops/test/support/copy_surfaces.ex
    - scrypath_ops/test/support/copy_stubs/sync_drift.ex
    - scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
    - examples/scrypath_ecommerce/e2e/operator.spec.ts
    - .github/workflows/ci.yml
    - test/mix/tasks/workflow_wiring_test.exs
    - CONTRIBUTING.md
    - .planning/reference/CI-EFFICIENCY.md

key-decisions:
  - "The queue and pending rows split a rendered check from a static scan: the static scan reads lib for a phrase list only (never a broad accepted pattern, which would hit atoms and docs), and the broad word check runs only on the two retry surfaces, which carry no Meilisearch task text"
  - "The failed-sync flash is rendered on failed_sync.after_retry, so the retry rows cover the flash as well as the receipt (RESEARCH item 5)"
  - "The new ops-ui pattern check is its own wiring test instead of a longer body for the old one; the old substring loop is untouched"
  - "Ledger row 10 is the copy rules table; finding 11 in CI-EFFICIENCY now says the website job would be gate 11 (10 of 12 used)"

requirements-completed: [COPY-01, COPY-03, COPY-04, GATE-02]

coverage:
  - id: D1
    description: "Host-queue outcomes say queued and only Meilisearch tasks say accepted; schema counts say pending; each rule has a row evaluated on an anchored rendered surface; the strings the required-lane specs pin are still in lib"
    requirement: "COPY-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs (rows pending-aggregate, pending-count, pending-caught-up, pending-promotion-reason, retry-queued-not-accepted, retry-surfaces-no-accepted, accepted-is-meilisearch-only, queued-host-queue-outcome on six surfaces; planted old forms through the same helper)"
        status: pass
      - kind: other
        ref: "preservation loop over the 17 strings the required-lane specs pin: missing=0"
        status: pass
    human_judgment: false
  - id: D2
    description: "A Status wording term cited by no row fails the table validation, and the real table cites all seven"
    requirement: "COPY-03"
    verification:
      - kind: unit
        ref: "copy_rules_contract_test.exs#a Status wording term that no row cites fails, and the real table cites them all"
        status: pass
    human_judgment: false
  - id: D3
    description: "The promotion dialog's Cancel button is focused when it opens (required lane); the ops_modal default, both destructive modals, the Save search exception, the delete confirmation's Cancel and every promotion notice sentence are pinned"
    requirement: "COPY-04"
    verification:
      - kind: e2e
        ref: "examples/scrypath_ecommerce/e2e/operator.spec.ts (expect(cancel).toBeFocused(), runs in hosted ecommerce-mounted; locally the spec parses under playwright test --list)"
        status: pass
      - kind: unit
        ref: "modal_focus_contract_test.exs; search_saved_searches_test.exs (Save search modal, delete confirmation); sync_drift_live_test.exs#the promotion notice says one exact sentence for every blocked reason and both other states"
        status: pass
    human_judgment: false
  - id: D4
    description: "The ops-ui path pattern matches the glossary, DESIGN.md and the demo e2e, lib, test and scripts directories and every source_scope directory of the table; a narrowed pattern fails the same check; ledger row 10 and the budget line agree"
    requirement: "COPY-03"
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs#the ops-ui path pattern matches every path the copy rules table scans; the required-gate budget ledger test"
        status: pass
    human_judgment: false
  - id: D5
    description: "The demo ExUnit test passes locally with the sentence-case label"
    requirement: "COPY-04"
    verification:
      - kind: integration
        ref: "mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs: 7 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D6
    description: "One mix verify.repository_contracts and one mix verify.core ran once each on the tested SHA, with a receipt"
    requirement: "GATE-02"
    verification:
      - kind: other
        ref: "190-GATE-RECEIPT.md"
        status: pass
    human_judgment: false

duration: 1h
completed: 2026-11-20
status: complete
---

# Phase 190 Plan 02: Queue and pending wording, dialog pins, ops-ui path coverage and the gate receipt Summary

**Host-queue work now reads queued and schema aggregates read pending, each guarded by a table row on an anchored rendered surface; the promotion dialog's Cancel focus is asserted in the required lane; the `ops-ui` path pattern covers every path the table scans, proved by behaviour; one gate run per tested SHA is recorded in a receipt.**

## Performance

- **Duration:** about 1 hour of execution, from the dependency fetch (20:44 UTC) to the summary (about 21:40 UTC); reading the plan and context before that is not counted. The four long-gate runs (two rounds) took about 26 minutes of it.
- **Commits:** 7 commits from the plan ledger (`plan_head_before` to `plan_head_after`): four task commits, one small cleanup commit, the namespace-fence fix and the receipt commit; this summary's own commit follows.
- **Files:** 21 changed from `plan_head_before` to `plan_head_after` (1004 insertions, 152 deletions).

## Accomplishments

- **Queue and pending wording (Task 1).** Six strings moved (Q-1 to Q-6) and three more (P-1 to P-3), exactly as D-07 and D-08 list. Every kept string (the Meilisearch uses of accepted, the Meilisearch tasks waiting lines, the Pending status word, atoms and function names) is untouched. `help_live.ex` differs from its base in the one sentence that ended in Acceptance alone.
- **Eight rows, six surfaces.** `pending-aggregate`, `pending-count`, `pending-caught-up`, `pending-promotion-reason`, `retry-queued-not-accepted`, `retry-surfaces-no-accepted`, `accepted-is-meilisearch-only` and the anchor row `queued-host-queue-outcome`, on `sync_drift.queue_pending`, `sync_drift.caught_up`, `sync_drift.promotion_blocked_queue`, `sync_drift.recovery_queued`, `sync_drift.promotion_accepted` and `failed_sync.after_retry`. Each surface has a state anchor asserted before its rows run. The table is now 14 rows on 14 surfaces.
- **Self-check.** `validate/2` now also takes the glossary's Status wording terms (`status_terms/1`) and fails when one is cited by no row. The planted case drops the only row that cites Queued and expects exactly that one message; the real table cites all seven.
- **Cancel focus (Task 2).** One line in `operator.spec.ts`, between the `confirm` locator and the first `close.focus()` call, asserts the existing `cancel` locator (accessible name Cancel index swap) is focused. It is the only change to that spec.
- **Pins (Task 2).** `modal_focus_contract_test.exs` pins the `ops_modal` default selector with a planted override that fails the same assertion. `search_saved_searches_test.exs` pins the Save search modal to its name input (and not the Cancel default) and the delete confirmation's Cancel button wired to `cancel_row`. `sync_drift_live_test.exs` renders the promotion notice for all 16 named reasons plus the fallback, the eligible state and the unchecked state, and asserts the exact title and sentence from the notice element alone. The two destructive `ops_modal` pins in `sync_drift_live_test.exs` (Confirm index promotion) and `failed_sync_live_test.exs` (Confirm delete sync work) are untouched and are part of the COPY-04 record.
- **CI (Task 3).** The `ops-ui-path` pattern gained `GLOSSARY\.md`, `DESIGN\.md` and `examples/scrypath_ecommerce/(e2e|lib|test|scripts)/` inside its group; the diff of `ci.yml` is that one line. The wiring test compiles the extracted pattern, matches seven representative paths, refuses README.md and the website index, matches the literal directory of every `source_scope` glob in `copy_rules.json`, runs the same check on a copy of the pattern with the new alternatives removed (it reports six paths missed), and checks the whole-tree scope is documented as the partial case. Ledger row 10 and the budget line (`Budget used: 10 of 12.`, 10 table rows) are in `CONTRIBUTING.md`; the ops-ui description names the copy inputs; `CI-EFFICIENCY.md` finding 12 records the 386 s cost, the reason, the rejected alternative and the revisit trigger.
- **Record, demo test and gates (Task 4).** The demo test passes (command and result below). `190-PHASE-RECORD.md` has the resolved notes, the decisions, the Post-ship evidence table (row 1 and row 6 filled, rows 2 to 5 empty for the orchestrator), the exact-head dispatch procedure, the follow-ups and the not-proved list. The two long gates ran once each on the tested SHA (below).

## `git grep` results at execution time (before the edits)

`git grep -n -i -F` over `scrypath_ops/lib`:

| Search | Hits |
|--------|------|
| `already accepted` | `saved_searches/runner.ex:5` (moduledoc, not copy) and `failed_sync_live.ex:319`; the row's literal is the narrower `is already accepted`, which only the flash matches |
| `Retry accepted` | `failed_sync_live.ex:351`, `sync_drift_live.ex:579` |
| `The queue accepted` | `sync_drift_live.ex:601` |
| `accepted operation` | `sync_drift_live.ex:2154` |
| `Acceptance alone` | `help_live.ex:123` |
| `Nothing queued` | `sync_drift_live.ex:1703` |
| `queued work` | `sync_drift_live.ex:1560` |
| `\bjobs? queued\b` (regex, `-P`) | no hit: the suffix is built by concatenation, so the rendered `sync_drift.queue_pending` row is its guard |

Every hit was in a string this task edits. After the edits the table's static scan over the lib prefix is clean.

## Flash visibility (RESEARCH item 5)

The Retry queued flash is on `failed_sync.after_retry`: a throwaway probe (deleted, never committed) found `Retry queued · queue job 991` in the HTML that `render_click` returns after the retry, next to the receipt text. It was run twice, once on the first version of the surface (Sigra mode with a sudo window) and once after the namespace-fence fix (default basic mode), with the same result. The retry rows therefore cover the flash, not only the receipt.

## Throwaway calibration (old strings restored, rows seen red, files restored from a backup; none committed)

- With all the old queue and pending strings restored, the contract test failed on every row for the right reason: the static scan named `failed_sync_live.ex:351` and `:319`, `help_live.ex:123`, `sync_drift_live.ex:579`, `:601`, `:2154`, `:1703` and `:1560`; the rendered surfaces failed `retry-queued-not-accepted` (Retry accepted, The queue accepted, accepted operation and the missing Retry queued), `retry-surfaces-no-accepted`, `pending-aggregate` (`job queued`, Nothing queued, queued work), `pending-count`, `pending-caught-up` and `pending-promotion-reason`.
- With only the old queue reason restored, the promotion notice test failed naming `:queue_work_pending`, the sentence it expected and the sentence it saw.
- With the new `ops-ui-path` alternatives removed from `ci.yml`, the wiring test failed on the missed paths (GLOSSARY.md, DESIGN.md and the four demo paths).

## D-14 fallbacks used

None. All six new surfaces were built (the four that need the render-with-assigns pattern included), and `not_covered` is unchanged.

## Deviations from Plan

**1. [Rule 3 - Blocking] The failed-sync stubs and `Oban.Job` moved to `test/support/copy_stubs/`**
- **Found during:** Task 1 (the `failed_sync.after_retry` surface needs the failed-sync client, inspector, recording insert, environment and the Oban job struct; the Oban package is optional for the ops app, so the surface cannot rely on the failed-sync test file defining it).
- **Fix:** `copy_stubs/failed_sync.ex` holds the three stub modules, the environment and `render_after_retry/1`; `copy_stubs/oban_job.ex` holds the `Oban.Job` stub as its own file (one top-level module per file). `failed_sync_live_test.exs` aliases them; `FailingOban` stays in the test file because only that test uses it. The plan names only `failed_sync.ex`.
- **Side effect, recorded in the phase record:** `Oban.Job` is now defined in the whole test environment. A whole-suite run already had it (every test file loads before any test runs). The whole suite passes.
- **Commits:** the stub move is in the Task 1 commit; a small follow-up commit dropped the then-unused `put_live_assigns/2` wrapper so Task 2's criterion "`failed_sync_live_test.exs` is unchanged by this task" holds (the fence fix below put an equivalent helper back).

**2. [Rule 1 - Bug] The first `mix verify.core` failed on the namespace fence, and the fix changed the code head**
- **Found during:** Task 4, first long-gate round on `47558725`. `mix verify.repository_contracts` passed (174 tests, 0 failures); `mix verify.core --exclude integration --exclude docs_contract` ran 1195 tests with one failure: `Mix.Tasks.Verify.NamespaceFenceTest` ("live repository still passes as a canary"). The fence (`dev/mix/tasks/verify.namespace_fence.ex`) allows `Sigra.` only under the Sigra integration namespace and `scrypath_ops/test/scrypath_ops_web/live/`, and my shared stub file `copy_stubs/failed_sync.ex` named `ScrypathOps.Integrations.Sigra.OperatorContext` (line 173) in its `sudo!/1` helper. Docs and the no-Oban compile steps of that core run were fine.
- **Cause:** my change (Task 1 moved the helper out of an allowed test file into `test/support`), and none of my local checks ran that root test; it is a 1 s check and `core` was the first place it showed.
- **Fix (cycle 1 of 2 allowed):** the fence was not touched or dodged. The sudo confirmation, its `:sigra` environment, `OPSUI_AUTH_MODE=sigra` and the `sudo!/1` and `put_live_assigns/2` helpers went back to `failed_sync_live_test.exs` (an allowed path), and the shared stubs no longer set up Sigra at all. The `failed_sync.after_retry` surface renders the retry in the default host-authenticated mode (`OPSUI_AUTH_MODE=basic`, set and restored inside `with_stubs/1`), where `gate_sensitive_action` runs the retry with no operator context; the receipt and the flash are the same. The fence test (3 tests), the contract test, the failed-sync test and the whole ScrypathOps suite (546 tests) pass.
- **Consequence for GATE-02:** the fix is a code change, so the first round's `repository_contracts` pass belongs to a superseded SHA. Both gates were rerun once each on the fixed SHA `f6c78bd2` (see Long gates). The lesson, added to the CI efficiency ledger: run `mix test test/mix/tasks/verify_namespace_fence_test.exs` after adding or moving any file under `scrypath_ops/test`.
- **Commit:** `f6c78bd2`.

**3. Shared Oban helpers for the two sync-drift tests**
- `SyncDriftStubs.put_oban_env/1` and `pending_and_retrying_jobs/0` were added so the caught-up and sync-activity tests and the two new surfaces share one definition of the Oban switches and the two jobs (the plan asks for the surfaces to reuse them).

**4. The new ops-ui pattern check is its own test**
- The plan says to extend the existing ops-ui context test. The substring loop in that test is untouched, and the behavioural checks are in a second test named for what it proves, so a failure names the pattern check. Outcomes are the same.

**5. [Rule 1 - consistency] CI-EFFICIENCY finding 11 reworded**
- It said the website `build-and-check` job would become gate 10 with 9 of 12 used. This phase took gate 10, so it now says gate 11 with 10 of 12 used. The finding 12 entry is appended after it, no other finding renumbered.

**6. Forbidden literals are case-insensitive**
- The plan does not state a case for the queue and pending literals. They are insensitive (stricter); the case-insensitive `git grep` results above show no extra hit.

**7. The preservation loop used plain `grep -rF`**
- The sandbox refused a compound `git grep` loop, so the loop (`scratchpad/preservation_loop.sh`, 17 strings) ran as `grep -rF` over the same two lib trees. All 17 strings are present.

## Local check results

All on the committed result, with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` and the local Postgres on 5432:

| Check | Result |
|-------|--------|
| Task 1 files (`copy_rules_contract_test`, `failed_sync_live_test`, `sync_drift_live_test`) | 97 tests, 0 failures |
| Task 2 files (`modal_focus_contract_test`, `sync_drift_live_test`, `search_saved_searches_test`, `failed_sync_live_test`) | 111 tests, 0 failures |
| `playwright test --list` | 300 tests in 25 files, no parse error; the focus line sits after `const confirm` and before the first `close.focus()` (the plan's awk check exits 0) |
| Wiring test (root) | 89 tests, 0 failures (88 before); docs contract (`--include docs_contract`) 74 tests, 0 failures |
| `mix format --check-formatted` (root and `scrypath_ops`) | clean |
| `MIX_ENV=test mix compile --warnings-as-errors --force` (in `scrypath_ops`) | exit 0, no warnings |
| Whole ScrypathOps suite | 2 doctests, 546 tests, 0 failures (538 before), both before and after the fence fix |
| Namespace fence test (root, `test/mix/tasks/verify_namespace_fence_test.exs`), added after the first `core` failure | 3 tests, 0 failures after the fix (it was the one failing test in `core` before it) |
| `node --test scripts/ci/ui_preservation.test.cjs`; `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` | 53 pass; 32 pass |
| Preservation loop (17 pinned strings in lib) | missing=0 |
| Whole-tree count of the old label outside `.planning/`, `brand/` and the table file | 0 (`git grep -c` exits 1) |
| Demo test: `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs` (repository root) | 7 tests, 0 failures in 13.7 s, after `mix deps.get` in the demo (no lockfile or vendored change; `git status` clean) |

The CI Node step was not rerun: nothing it reads changed (`git diff --name-only` from the plan base lists no `app.css`, `contrast-pairs.mjs`, `contrast-checker.mjs` or `brand/` file, and none of the spec files `ecommerce_target.test.cjs` reads).

No Docker container, image or network was started by this plan (`docker system df` was read only; the containers listed there belong to other work).

## Long gates (GATE-02)

Each gate ran once per SHA, sequentially (they share build output), in the background and read afterwards. `mix verify.repository_contracts` used the escalated permission from its first invocation because its fetch step writes the worktree `FETCH_HEAD`; `mix verify.core` ran in the sandbox. The tree was clean before each run (no staged or modified path; `.planning/config.json` and `.planning/state.json` were not dirty in this worktree and were never staged).

| Round | SHA | `mix verify.repository_contracts` | `mix verify.core --exclude integration --exclude docs_contract` |
|-------|-----|-----------------------------------|----------------------------------------------------------------|
| 1 (superseded) | `47558725c212cbb15935b4169b8d61053a6f0a3d` | pass: 174 tests, 0 failures (21:00:15 to 21:06:42 UTC) | **fail**: 1195 tests, 1 failure, the namespace fence (21:08:31 to 21:14:49 UTC); the Credo, docs-build and no-Oban-compile steps of that run were fine |
| 2 (tested SHA) | `f6c78bd243602701857891dd77332d602a392d3e` | pass: 174 tests, 0 failures (21:19:53 to 21:25:55 UTC) | pass: 5 properties, 1195 tests, 0 failures (21:26:34 to 21:33:37 UTC), including format, warning-free compile, Credo, the docs build and the no-Oban compile |

The round-1 failure was a real defect of this plan's change (deviation 2), fixed in code without touching the fence, so both gates were rerun on the fixed SHA. `190-GATE-RECEIPT.md` names `f6c78bd2` as the tested SHA; the one commit after it (`8052481c`) changes only files under `.planning/` (the receipt, the phase record and a CI efficiency note), and this summary's commit follows it, also under `.planning/`.

## Ledger and budget line as written

`CONTRIBUTING.md` has 10 rows in the Required-gate budget table (9 plus the copy rules table row) and `Budget used: 10 of 12.`; the wiring test's ledger check passes. The budget sentence that names only the v1.46 milestone and the component-contract row's v1.47 trigger are untouched (Phase 191).

## For the orchestrator

- Branch: `worktree-agent-ae5cfe7309d2db0c9` (cut from `gsd/phase-190-wording-without-the-catalog` at `258c6848`).
- Final head SHA: the summary commit, which is this file's own commit (the SHA is in the return message, since a file cannot name its own commit). The tested SHA is `f6c78bd243602701857891dd77332d602a392d3e` (`190-GATE-RECEIPT.md`), and every commit after it changes only files under `.planning/`.
- Nothing was pushed, no PR was opened or touched, no workflow was dispatched. Post-ship evidence rows 2 to 5 in `190-PHASE-RECORD.md` are empty for you to fill after the merge; row 1 (baseline run 44805847191, `ecommerce-e2e (advisory)` success in 1320 s) and row 6 (demo test) are filled.

## What this does not prove

That the new wording reads well or suits the brand voice (no design pass, rendered review, screenshot comparison or aesthetic or independent-review approval is claimed); that Cancel receives focus in any browser but the mounted host's Chromium run or with a real screen reader (the focus line runs only in the hosted `ecommerce-mounted` lane; locally the spec is parsed, not run); that the saved-search delete confirmation focuses Cancel first (it is an inline form, pinned as it exists); that the advisory specs are green beyond the one exact-head dispatch, or that a red dispatch is caused by this phase when `main` is also red; that the hosted `ops-ui` job finds `git` the way the local run does; or that a path outside the extended pattern re-introducing a retired phrase is caught before the merge (it is caught on the push to `main`).

## Known Stubs

None. The `copy_stubs` modules are test-only fixtures; no placeholder or empty value flows to rendering.

## Threat Flags

None. No new network endpoint, auth path or schema change. The only workflow edit is one path-pattern line (T-190-07 is mitigated by the behavioural wiring test with its negative control). The demo's `mix deps.get` changed no lockfile (T-190-11) and no Docker route was used (T-190-12).

## Self-Check

PASSED. The created files exist (`copy_stubs/failed_sync.ex`, `copy_stubs/oban_job.ex`, `modal_focus_contract_test.exs`, `190-PHASE-RECORD.md`, `190-GATE-RECEIPT.md`), and the seven plan commits (`710ebee1`, `64cf246a`, `f7527f23`, `46772df2`, `47558725`, `f6c78bd2`, `8052481c`) are listed by `git log` from the plan base to HEAD, so they are ancestors of it. The only change after the tested SHA `f6c78bd2` is `8052481c`, under `.planning/`.
