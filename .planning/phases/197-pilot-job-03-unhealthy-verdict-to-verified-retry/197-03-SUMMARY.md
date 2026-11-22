---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
plan: 03
subsystem: ui
tags: [liveview, function-components, view-model, storybook, seam-test, parity-capture, failed-sync, catalog-contract, dom-hygiene, ops-ui]
status: complete

requires:
  - phase: 197-01
    provides: "JOB-03 journey (baseline d913b8b6, unmodified here), the catalog server and the storybook font fix"
  - phase: 197-02
    provides: "HtmlCanon, the story conventions, the Search health slice and 197-parity-capture.exs"
  - phase: 196-fixtures-and-three-adopters
    provides: "ScrypathFixtures scenarios and FixtureEnv, the pinned preview epoch the stories and seam tests build from"
provides:
  - "FailedSyncView.build/4 (pure) with closed enums for page state, summary kind, cause, row sync status and row action; Row struct; all_rows/1, cause/1, row_key/1, filter_path/3 for the LiveView"
  - "ScrypathOpsWeb.Components.FailedSync: failed_filters/1, failed_summary/1, retry_receipt/1, failed_row/1, delete_confirmation/1, surface/1; FailedSyncLive renders one surface/1 call and keeps events, Gating, receipts and start_async"
  - "Six Failed sync stories (16 variations) plus the Patterns folder index; seam tests for every area, pattern and the whole page across all four page states"
  - "ScrypathOps.Test.CatalogChecks (identical_variations/1, dom_problems/2, main_digest/1, tier/1) and the two checks wired into catalog_contract_test.exs, each with planted inputs and a plant into the real render"
affects: [197-04, 197-05]

actuals:
  tokens: 26200
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 4fd1813ab5f3b7f40bdd6bea072550d756a89445
plan_head_after: ff3e5d083c7eb5a9ad252e85bdf5f3dee62522f0

tech-stack:
  added: []
  patterns:
    - "A pure builder (FailedSyncView.build/4) is the only thing a story calls; the clock is read once by the LiveView and passed down, so no component reads it"
    - "One function component per area and pattern, called by both the LiveView and the story; a seam test per component proves the mounted page equals the component output for the page's own view-model, rebuilt independently from the LiveView's assigns"
    - "Catalog checks are pure functions over digests and parsed HTML; each cause has a planted input asserting its exact tagged problem and a plant into the real render"

key-files:
  created:
    - scrypath_ops/lib/scrypath_ops/failed_sync_view.ex
    - scrypath_ops/lib/scrypath_ops/failed_sync_view/row.ex
    - scrypath_ops/lib/scrypath_ops_web/components/failed_sync.ex
    - scrypath_ops/storybook/areas/failed_row.story.exs
    - scrypath_ops/storybook/areas/failed_summary.story.exs
    - scrypath_ops/storybook/patterns/_patterns.index.exs
    - scrypath_ops/storybook/patterns/failed_filters.story.exs
    - scrypath_ops/storybook/patterns/retry_receipt.story.exs
    - scrypath_ops/storybook/patterns/delete_confirmation.story.exs
    - scrypath_ops/storybook/surfaces/failed_sync.story.exs
    - scrypath_ops/test/support/catalog_checks.ex
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/storybook/areas/_areas.index.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs

key-decisions:
  - "The row action is a closed `:retry | :receipt | :ineligible` set that records eligibility only; whether the signed-in operator may act stays with the LiveView's sensitive-action gate (the plan's cut-first `retry_decision` was kept, not cut)"
  - "failed_summary/1 renders the filter chips by calling failed_filters/1, because the old markup nests the form inside the summary section and the DOM had to stay identical"
  - "A nil load with no scope error is refused (FunctionClauseError) instead of becoming a fifth page state that would render a healthy-looking page"
  - "The LiveView reads the clock once per render and passes it as `now`; components pass it to every ops_time as snapshot_at"
  - "Variation proof labels name the seam test that mounts the same scenario and compares the row, summary, filters, dialog or page; the journey is named only for the retryable and receipt states it asserts; the hostile long-error variation is render only"

patterns-established:
  - "Plant one cause, assert that cause: every retargeted source assertion, seam test and catalog check was proven against a planted failure and the plant restored (checked by diff)"
  - "A seam test can only catch a wiring fault in the LiveView, not a change inside the shared component (both sides run it), so its plants edit what the LiveView passes"
  - "Stage new files before running the full ops suite: the copy-rules scan reads tracked and staged files only, so an untracked file can hide a violation"

requirements-completed: []

coverage:
  - id: C1
    description: "FailedSyncView.build/4 is pure and classifies: Retry for the four Oban jobs, none for the Meilisearch task, receipt only on the row that holds one, causes inside the closed set, four page states, four summary kinds, and an impossible nil load is refused"
    requirement: "PILOT-03"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#FailedSyncView.build/4 (7 tests)"
        status: pass
    human_judgment: false
  - id: C2
    description: "Every mounted row, the summary and load errors, the filters, the delete confirmation, the receipt and the whole page canonicalize equal to the shared components' output for the page's own view-model, across nine scenario and URL cases that reach all four page states"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#seam: failed_row (2 tests) and #seam: failed_summary, failed_filters and surface (11 tests)"
        status: pass
    human_judgment: false
  - id: C3
    description: "Parity: base 4fd1813a against head shows 0 differences over 54 captures; same code twice 0; a planted Retry text change reports exactly the two captures that render a Retry button"
    requirement: "PILOT-03"
    verification:
      - kind: command
        ref: "local evidence recorded in this SUMMARY (197-parity-capture.exs); throwaway by decision, not a gate"
        status: pass
    human_judgment: false
  - id: C4
    description: "The JOB-03 journey is unchanged since its baseline and passes before every commit"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs (git log d913b8b6..HEAD on the file prints nothing)"
        status: pass
    human_judgment: false
  - id: C5
    description: "The 16 Failed sync variations compile with no process running and render in light and dark; the three source-reading assertions the move tripped now read the component file and each fails when its token is removed"
    requirement: "PILOT-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#render-all"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs (planted removals recorded below)"
        status: pass
    human_judgment: false
  - id: C6
    description: "The catalog contract test fails when two variations of one story render the same page in a theme, and on a duplicate id, an ARIA reference to nothing (including the literal false), an unnamed control, or a surface without exactly one main; the real catalog passes all of them in light and dark"
    requirement: "PILOT-05"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#planted catalog checks (7 tests)"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#no two identical variations and #DOM hygiene"
        status: pass
    human_judgment: false
---

# Phase 197 Plan 03: Failed sync extraction, stories and two catalog checks Summary

**Failed sync now renders through shared function components over a pure `FailedSyncView.build/4`; six stories show the same markup the page does, a parity capture shows no change from the commit before the extraction, and the catalog contract test now fails on identical variations and broken DOM hygiene.**

## Performance

- **Duration:** about 21 minutes by the wall clock (2026-11-22T14:30Z to 14:51Z); the base parity capture ran in the background while the view-model was written
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Files:** 16 (11 created, 5 modified); realized diff about 26.2k tokens by chars/4 over added lines against the 80k estimate (raw 160k)
- **Commits:** 3 task commits, measured from the plan ledger: `4fd1813a..ff3e5d08`

| Commit | Subject |
|--------|---------|
| `0ab82f30` | chore(ops-ui): render Failed sync rows through a shared component (Task 1; first committed as `91c8d960`, amended once, see deviation 4) |
| `ee0c89b0` | chore(ops-ui): share the Failed sync components with the storybook (Task 2) |
| `ff3e5d08` | test(ops-ui): fail the catalog on identical variations and broken DOM hygiene (Task 3) |

The journey file was not touched: `git log d913b8b6..HEAD -- scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` prints nothing, and the journey passes (4 tests) in every run below. No root `lib/` file, dependency or lock changed (`git diff origin/main` over root `lib/`, both `mix.lock` files and `mix.exs` is empty; the only fixtures difference is Plan 01's `Product.search_records/2`).

## Accomplishments

- **View-model split (PILOT-03).** `FailedSyncView.build(loads, scope, receipts, now)` computes what `render/1` computed before (visible rows, load errors, all-failed, filtered, filtered-out, hidden count, summary kind, headline, guidance, schema and cause facets, handoff schema, delete row) and returns one struct with the closed sets: page state `:no_schemas | :unavailable | :missing_backend | :ready`, summary kind `:warning | :neutral | :partial | :success`, cause (five), row sync status `:retrying | :failed`, row action `:retry | :receipt | :ineligible`. It has no clock, process or Phoenix import. The LiveView keeps `retry`, `confirm_retry_delete`, `cancel_retry_delete`, `filter`, `refresh`, scope resolution, loading, `Gating`, receipt registration and `find_row`/`row_by_key`/`row_key` (the last one now delegates to the view's single definition, so a receipt and its row can never use different keys).
- **Shared components.** `failed_filters/1`, `failed_summary/1`, `retry_receipt/1`, `failed_row/1`, `delete_confirmation/1` and `surface/1` hold all the markup; `FailedSyncLive.render/1` is one `surface/1` call. The LiveView went from 1253 to 522 lines; the presentation helpers the plan counted (43 `defp` names) left it, except the three the events need (`find_row`, `row_by_key`, `row_key`). Every `ops_time` gets `snapshot_at={@now}` and its existing id.
- **Stories (PILOT-04).** 16 variations in the glossary tiers, plus the `patterns/` index (folder index 1), so the sidebar now reads primitives, patterns, areas, surfaces. Every row comes from `Scrypath.failed_sync_work/2` over the scenario's own options, built by the pure view; a story that needs a process fails `mix compile`.
- **Seam tests.** One per component, plus the whole page across nine scenario and URL cases: failed journey (plain, `?cause=transport`, `?cause=backend_rejected`, and `?schema=No.Such.Schema` for the unavailable state), settings aligned (nothing failed), Logistify history over limit (a load error), Wikily first delete failed, Wikily unconfigured (no schemas) and Wikily missing backend. The delete dialog is opened by clicking the rendered Retry on job 104. The receipt is injected in the mounted view's assigns as the LiveView stores it; the journey drives the real retry.
- **Two catalog checks (PILOT-05, two of the checks).** `CatalogChecks.main_digest/1` hashes only `[data-phx-main] > *`; `identical_variations/1` groups by story path and theme; `dom_problems/2` reports `{:duplicate_id, id}`, `{:dangling_aria, attr, token}`, `{:unnamed_control, tag}` and, for surface-tier stories, `{:main_count, n}`. A control is named by its text (ignoring `aria-hidden`), `aria-label`, an `aria-labelledby` target with text, `title`, image `alt`, a button `value`, `label[for]` or a wrapping label with text. The real catalog passes both checks for all 44 variations in light and dark. The existing render-all and planted-tree assertions are unchanged (the only removed line in the file is the old return inside `render_target/3`, now built on a new `render_document/2`).

## Variation list per story

Provenance line: `Adopter: <Name> (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: <label>`. `job/0` is JOB-03 and `covers/0` is `FailedSyncLive` on every story. "Seam" means `failed_sync_live_test.exs`, which mounts the same scenario and compares the rendered subtree to the component output; "Journey" means `catalog_journey_test.exs`. No variation was dropped: the new check finds no identical pair in either theme.

| Story | Variation id | Proof label |
|---|---|---|
| `areas/failed_row` | `shopadelic_failed_journey_retryable` | Journey |
| | `shopadelic_failed_journey_retrying` | Seam |
| | `shopadelic_failed_journey_retry_queued` | Journey |
| | `shopadelic_failed_journey_ineligible_task` | Seam |
| | `shopadelic_failed_journey_delete_retry` | Seam |
| | `shopadelic_hostile_ids_long_error` | render only |
| `areas/failed_summary` | `shopadelic_failed_journey_failed_and_retrying` | Seam |
| | `shopadelic_failed_journey_filtered_out` | Seam |
| | `shopadelic_settings_aligned_nothing_failed` | Seam |
| | `logistify_history_over_limit_f1_load_error` | Seam |
| `patterns/failed_filters` | `shopadelic_failed_journey_mixed_causes`, `shopadelic_failed_journey_cause_selected` | Seam |
| `patterns/retry_receipt` | `shopadelic_failed_journey_queued` | Journey |
| `patterns/delete_confirmation` | `shopadelic_failed_journey_delete_retry_open` | Seam |
| `surfaces/failed_sync` | `shopadelic_failed_journey`, `wikily_missing_backend` | Seam |

Failed sync total: 16. Whole catalog: 44 (17 primitives, 19 areas, 4 patterns, 4 surfaces). The rendered text of each variation was read and matches its description. Each scenario id in a Seam or Journey label appears in the named test file, which is what Plan 04's backing check will read. The four Wikily states other than missing backend and first delete failed are not storied here (the first delete renders the same row component and adds no new page).

## Parity record (throwaway local evidence, not a gate)

- **Base:** `4fd1813ab5f3b7f40bdd6bea072550d756a89445` (the commit before Task 1; its code equals `f19c4866`). **Head:** the working tree whose lib code is `0ab82f30` (no lib change after Task 1).
- **Result:** `PARITY: 0 differences over 54 captures` (11 scenarios x 2 pages, 16 `phase173` pages, 16 copy surfaces). With zero differences there is nothing to classify as intended.
- **Control 1, same code twice:** head against a second head capture: `0 differences over 54 captures`.
- **Control 2, planted text change:** `Retry` changed to `Retry now` in `failed_row/1`. Result: `2 differences over 54 captures`, the two captures `shopadelic_failed_journey__failed-sync.html` and `shopadelic_hostile_ids__failed-sync.html`, which is exactly the set of head captures that contain the Retry button (`grep -l 'data-testid="failed-sync-retry"'` gave the same two). The plant was reverted (`diff` against the saved copy is empty).
- **What the capture does not cover:** the open delete dialog and the receipt are not in the 54 captures; the seam tests cover them against the component output, and the component markup was moved verbatim.
- **Cleanup:** the copied script is gone from `scrypath_ops/test/` and no `parity-base` worktree is listed (the plan's second verify command passes). The base capture directory is session-local in the scratchpad.

## Retargeted source assertions and their planted failures

The three assertions in `operator_ia_contract_test.exs` that read `failed_sync_live.ex` for markup now read `components/failed_sync.ex` (a new `@failed_sync_components` attribute); the `handle_params` assertion still reads the LiveView. Each token was changed in the component file, the test failed on that assertion, and the file was restored (checked by `diff`).

| Assertion | Planted change | Failing line |
|---|---|---|
| sync-and-index path | `OperatorSelection.path(mount_path, "sync-and-index", mod)` replaced by string interpolation | `assert @failed_sync_components =~ "OperatorSelection.path(mount_path, \"sync-and-index\", mod)"` |
| retry event | `phx-click="retry"` changed to `phx-click="retry_job"` | `assert @failed_sync_components =~ "phx-click=\"retry\""` |
| More details | `summary="More details"` changed to `summary="Details"` | `assert @failed_sync_components =~ "summary=\"More details\""` |

## Seam and catalog-check plants

A component edit cannot break a seam test (the page and the test both run it), so the seam plants edit what the LiveView passes. Each was restored and checked by `diff`.

| Plant | Result |
|---|---|
| surface passes a `now` an hour later to every row | both row seam tests fail (`==` on the canonical trees) |
| LiveView scope drops `cause_filter` | the `?cause=transport` and `?cause=backend_rejected` seam cases fail (and the existing cause-filter test) |
| LiveView passes `last_refresh_at={nil}` | seven page cases fail (the unavailable case and no-schemas case never show a refresh time, so they pass, correctly) |
| LiveView builds the view without receipts | the row receipt seam and the receipt pattern seam fail (and two existing retry tests) |
| LiveView scope drops `delete_confirmation` | the dialog seam fails (and the existing dialog tests) |
| a second variation made identical in `patterns/failed_filters` | `no two variations...` fails with `{:identical, "/patterns/failed_filters", "light" and "dark", [cause_selected, mixed_causes]}` |
| the Retry button's text removed in `failed_row/1` | the hygiene test fails with `{:unnamed_control, "button"}` for each variation that shows Retry, in both themes, naming path and variation |

Planted inputs inside the contract test: a duplicate id, `aria-describedby="false"`, a dangling `aria-labelledby` and `aria-controls` token, a bare button, a button holding only an `aria-hidden` span, an icon-only link, an unlabelled checkbox, no main, two mains and a `role=main` plus a `main`, each asserting its exact tagged problem. Controls: the real `ops_button` render, a checkbox named only by a wrapping label, `label[for]`, `aria-label`, `title`, `aria-labelledby`, `sr-only` text, a submit `value`, a hidden input and an image `alt`. Plants into the real render: removing every `<label>` from the real filters story leaves every cause checkbox unnamed (one tagged problem per checkbox), and renaming the real summary heading id reports exactly the dangling `aria-labelledby`.

## Task commits and verification

- `mix precommit` (compile with warnings as errors, `deps.unlock --unused`, format, full ops suite) on the final tree, run before and after the Task 3 commit: 2 doctests, 772 tests, 0 failures in about 38 s warm; no lock change.
- Task 1 verify (journey, Failed sync, catalog contract): 51 tests, 0 failures. Task 2 verify (the `live/` directory, operator IA, catalog contract, copy rules, a11y): green after the copy-rules fix below, then the full suite at 763 tests. Task 3 verify twice: 13 tests, 0 failures both times, 2.0 s and 2.9 s ExUnit time (three full render passes over 44 variations x 2 themes; Plan 04 may share one pass).
- `node scripts/ci/ui_literal_policy.cjs`: PASS (30 finding occurrences, unchanged). `mix verify.namespace_fence`: passed after the fix below.
- **Not run here, a known risk:** `mix verify.ops_ui` (the root boundary test builds dev, test, prod and mounted trees; the new `lib` modules reference nothing dev-only, and the ops suite it runs after that test passed through `mix precommit`), the rest of the repository-contracts lane, and the Docker lane. The Node step was not run because nothing the verifier fixture copies changed. Plan 05 runs the full pre-push mirror on the final tree.

## Deviations from Plan

### Auto-fixed issues

**1. [Design] The whole extraction landed in the Task 1 commit, not only the row**
- **Issue:** the plan makes Task 1 the thinnest path (view, `failed_row`, one story, one seam test) and moves the rest of the components in Task 2. The LiveView cannot render half-moved markup without transitional code that Task 2 would delete.
- **Fix:** Task 1 extracted every component and `surface/1`. The tracer gate was still kept: before any further story or seam test, the Task 1 verify (journey, Failed sync, catalog contract) and the row seam plants ran green. Task 1 therefore has seven paths (view, `Row`, component module, LiveView, row story, live test, operator IA test) and Task 2 has eight (patterns index, three pattern stories, `failed_summary`, the surface story, the areas index comment, the live test) instead of the plan's five and eleven.
- **Commits:** `0ab82f30`, `ee0c89b0`

**2. [Rule 3 - Blocking] Operator IA retarget moved into Task 1 and covers a third assertion**
- **Issue:** `operator_ia_contract_test.exs` reads `failed_sync_live.ex` for `phx-click="retry"`, `summary="More details"` and, in the same test and earlier, `OperatorSelection.path(mount_path, "sync-and-index", mod)`. The first two moved with the row markup in Task 1 (so the Task 1 commit would have been red), and the third moved with the `sync_and_index_path/2` helper; the plan named only two.
- **Fix:** all three read the component file; each has a planted failure (above).

**3. [Design] `Row` is its own file**
- The app guidelines forbid nesting modules in one file, so `ScrypathOps.FailedSyncView.Row` lives in `lib/scrypath_ops/failed_sync_view/row.ex` (a sixteenth file against the plan's fourteen).

**4. [Rule 1 - Bug in my own doc] A doc comment broke a copy rule and the namespace fence, and the Task 1 commit was amended**
- **Found during:** Task 1 verification and, for the copy rule, Task 2.
- **Issue:** the `Row` typedoc named the Sigra gate module (the namespace fence forbids Sigra names outside the integration namespace) and said a retry "was queued", which the `pending-aggregate` copy row forbids in `scrypath_ops/lib/**`. The copy-rules scan reads tracked files, so my Task 1 `mix precommit` (new files still untracked) passed and the Task 1 commit was red on that one test.
- **Fix:** the doc says "the LiveView's sensitive-action gate" and "accepted". The fence failure was fixed before the first commit; the copy-rule failure was fixed by amending the local, unpushed Task 1 commit (`91c8d960` became `0ab82f30`), so no commit on the branch is red. From then on I staged new files before running the full suite.

**5. [Design] `failed_summary/1` calls `failed_filters/1`**
- The old markup nests the filter form inside the summary section, and the DOM and its spacing had to stay identical, so the summary area owns the call. `failed_filters/1` is still a pattern with its own story.

**6. [Design] A nil load with no scope error raises**
- `build/4` accepts `nil` loads only while a scope error is set. Any other `nil` raises `FunctionClauseError`, because the LiveView never produces it and rendering it as a ready page would show a false "nothing failed" verdict. A test pins it.

**7. [Design] One clock read per render**
- Before, each `ops_time` fell back to the clock itself for its tooltip age. The LiveView now reads the clock once per render and passes it as `now`, so every age on a render is measured from one instant. Output is identical under the pinned fixture clock (the parity run confirms it); in production the ages are now consistent within one render.

**8. [Design] Seam tests rebuild the scope themselves**
- The tests build the view from the mounted page's assigns with their own scope map instead of calling a LiveView function, so a wiring fault in the LiveView's scope shows as a difference (the `cause_filter` plant above).

**9. [Design] Proof labels point at the seam test for the failed-journey states**
- The plan named the journey as the only `Mounted` proof, for the retryable and receipt states. The seam test mounts every row of the scenario and compares it to the component, so the other failed-journey states are labelled with it; the hostile long error stays `render only`.

**10. [Design] Seam tests inject the receipt instead of driving a retry**
- The journey already drives the real retry. A seam test that did it again would need its own queue and repo stand-ins; it injects a receipt shaped as the LiveView stores it, then patches to the same page to re-render. That proves the markup for a receipt; the receipt and retry-queued stories carry the journey label because only the journey proves a real retry produces such a receipt.

Total deviations: 10 (1 blocking, 1 bug in own work, 8 design). Impact: none on scope; no root `lib/` file, dependency or lock changed. No cut from the plan's cut order was taken (`retry_decision` and the `delete_confirmation` story both stayed).

## Authentication gates

None.

## Known Stubs

None. The surface story is a static render by design: its buttons do nothing, and its shell links and the receipt's "Check sync status" link carry `/ops/...` hrefs that the catalog server does not serve (same as the Search health surface story).

## Threat Flags

None beyond the plan's register: T-197-09 (events, `Gating` and receipt registration stayed in `failed_sync_live.ex`, components only render; the journey's allowlist and stale-sudo denials ran unmodified and green before every commit), T-197-10 (markup moved verbatim into HEEx, escaping unchanged; the existing hostile-value test and the seam tests ran in the `live/` suite), T-197-11 (accepted: the long-error story shows the backend text as the fixture holds it and its comment says so), T-197-12 (each new check has planted inputs asserting its exact cause, a positive control on the real tree and a plant into the real render).

## Findings for the maintainer and the Pause 1 note (recorded, not fixed)

- **Markup defect, shared primitive (unconfirmed in a browser):** `ops_inline_code` renders its text on its own indented lines inside `<code>`, so the markup is `records in <code ...>\n  shopadelic_product\n</code>.` (read from the rendered story). Browsers collapse that to a single space inside the code, so a period right after an inline code span probably shows a gap before it. It is visible in the retry receipt ("... records in shopadelic_product .") and, from Plan 02, in the missing-backend empty state. The cause is the primitive, so every use that is followed by punctuation shares it. I did not open it rendered.
- **Existing behavior now visible in stories (not defects of this phase):** a retrying row ("This will retry automatically") also offers Retry, as the journey asserts; after Retry the row keeps its Failed status next to "Retry queued" because the original job is retained; the load error shows the raw Elixir error term (`{:task_history_truncated, %{next: 200, limit: 1000, ...}}`) to the operator (adjacent to F1); the 729-character hostile error (F2) is clamped by a "Show all" toggle once it passes 240 characters or three lines, but the whole text is in the page and the copy button, so the toggle limits what is read at a glance, not what is rendered.
- **Coverage gaps (fixtures, not code):** no fixture scenario has two schemas, so the Schema chip group has no story (the mounted behavior is covered by the existing Failed sync tests with two stub schemas); the unavailable-schema state and the receipt without a status link (a failed registration) are covered by seam tests and mounted tests but have no story.
- **No hygiene finding:** the DOM-hygiene check found no duplicate id, dangling reference or unnamed control in any of the 44 variations, so the check has not changed any markup. The one place a naive rule would have misfired, the cause chips, is named by a wrapping label and is handled.
- **From Plan 02, unchanged:** "3 sync jobs and 1 Meilisearch tasks failed" (no singular for the task count in the Search health verdict).

## Issues Encountered

- The base parity capture ran in about a minute because the copied `_build` made it warm; it ran in the background while the view-model was written.
- This machine's shared Postgres prints `too_many_connections` noise during `mix test`; every run passed.
- Three scripted edits produced wrong Elixir (a function capture piped into `render_component`, `put_in` on a nested struct replacing its root); both showed up at compile or in the first test run and were corrected before any commit.

## Next Phase Readiness

Plan 04 extracts the two recovery areas of Sync and index the same way (the cumulative parity base for it is `7d87a0bb`; recapture if the scratchpad is gone), adds the Job story and the `jobs/` index (folder index 4), and completes the contract test with coverage, provenance and copy checks. It can reuse `CatalogChecks` as it is: `tier/1` already returns `:job` for `/jobs/...` paths, and `dom_problems/2` only counts mains for `:surface`, so a jobs-tier story that renders a full shell needs a decision on whether to count them. The provenance backing check will find each seam and journey label's scenario id in its named file (verified above). For Plan 05, from Plans 01 and 02 and unchanged here: `catalog_contract_test.exs` still needs the bundle-font check with its plant, the landing-page marker holder check, and the first compare-mode probe run (the dump for it is `shopadelic_failed_journey__health.html` from the parity script's capture mode). `mix verify.ops_ui` and the rest of the pre-push mirror run there.

## Self-Check: PASSED

All 16 files of this plan exist on disk (the 11 created and the 5 modified), the three task commits (`0ab82f30`, `ee0c89b0`, `ff3e5d08`) are ancestors of HEAD, `FailedSyncView` has one `build/4`, the moved-helper grep is 0, `FailedSync.surface` appears once in the LiveView, `storybook/patterns` holds three stories, `CatalogChecks` is referenced from the contract test, the journey file has no commit since its baseline, the copied capture script and the `parity-base` worktree are gone, and no root `lib/` file differs from `origin/main`.
