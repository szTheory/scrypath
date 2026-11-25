---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
plan: 04
subsystem: ui
tags: [liveview, function-components, view-model, storybook, seam-test, parity-capture, recovery, catalog-contract, coverage, provenance, copy-lint, ledger, ops-ui]
status: complete

requires:
  - phase: 197-01
    provides: "JOB-03 journey (baseline d913b8b6, unmodified here, including its verified test), the catalog server and the storybook font fix"
  - phase: 197-02
    provides: "HtmlCanon, the story conventions and 197-parity-capture.exs"
  - phase: 197-03
    provides: "FailedSyncView and the Failed sync components, CatalogChecks (identical variations, DOM hygiene, tier/1) and the shared render helpers"
provides:
  - "RecoveryView.build/1 (pure; {:ok, view} | {:error, reason}) and for_page/1 (total): closed status set with :unavailable, evidence nil or a complete map, a refused-combination set; RecoveryView.Document for the document half"
  - "ScrypathOpsWeb.Components.Recovery: document_freshness/1 and recovery_status/1; SyncDriftLive renders both and keeps no recovery presentation helper (defect D3 fixed by construction)"
  - "Stories: areas/recovery_status (7 variations), areas/document_freshness (4), the jobs/ index and jobs/job_03_on_call_recovers_failed_sync (2)"
  - "Five new CopySurfaces states, each cited by existing copy_rules.json rows"
  - "CatalogChecks.coverage_problems/4, provenance_problems/4, copy_rows/1, copy_problems/2 and the contract test's coverage, provenance and copy checks with plants; one shared render pass"
  - "CONTRIBUTING.md required-gate ledger row 11 of 12"
affects: [197-05]

actuals:
  tokens: 25100
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 72ca3bf133e945e3f15d5e0d4c997a0033306537
plan_head_after: 07ad2dfb7c22dccfbdbc4e319bc8f20d6d61b5bd

tech-stack:
  added: []
  patterns:
    - "A view-model makes a crash shape unrepresentable (evidence is nil or complete) and refuses combinations the observer cannot emit; a total for_page/1 turns a refusal into the closed unavailable state"
    - "A seam test builds the expected view itself from every input, so a wiring fault in the LiveView shows as a canonical-tree difference"
    - "One render of every story variation (setup_all) feeds render-all, identical variations, DOM hygiene and copy"
    - "A story note's first line is machine-read provenance; the named Mounted test must contain the scenario id or the note's Claim literal"

key-files:
  created:
    - scrypath_ops/lib/scrypath_ops/recovery_view.ex
    - scrypath_ops/lib/scrypath_ops/recovery_view/document.ex
    - scrypath_ops/lib/scrypath_ops_web/components/recovery.ex
    - scrypath_ops/storybook/areas/recovery_status.story.exs
    - scrypath_ops/storybook/areas/document_freshness.story.exs
    - scrypath_ops/storybook/jobs/_jobs.index.exs
    - scrypath_ops/storybook/jobs/job_03_on_call_recovers_failed_sync.story.exs
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/support/catalog_checks.ex
    - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
    - scrypath_ops/test/support/copy_surfaces.ex
    - scrypath_ops/test/support/copy_rules.json
    - scrypath_ops/storybook/surfaces/_surfaces.index.exs
    - CONTRIBUTING.md

key-decisions:
  - "An unresolved recovery handle renders the closed unavailable state: the status says the outcome could not be checked, the evidence line and every job, task and index value are absent, and the Check detail line stays (moved verbatim)"
  - "RecoveryView.for_page/1 shows a refused combination (verified without verified document evidence, an observed status without full evidence, evidence with no status) as :unavailable, so the page never claims an outcome its evidence does not back"
  - "Copy lint over stories applies the rows that scan all copy (non-empty source_scope with forbidden text); surface-only rows describe one state and are not applied to unrelated stories"
  - "Jobs-tier stories count main landmarks like surface stories: a Job story renders a whole page inside the shell, so it has exactly one main"
  - "The Job story is the real FailedSync.surface/1 in two states (arrived from Search health, after Retry) with a one-paragraph persona caption in the note under the provenance line; it names the journey test as its proof"

patterns-established:
  - "Plant one cause, assert that cause: every wiring seam, view refusal, coverage key, provenance field and copy phrase has a planted input that reports exactly its own tag, plus a real-tree plant for the four checks (restored and checked by diff)"
  - "A test plant that touches two checks at once is split until each reports one cause (a JOB-99 note also trips the file-name check unless the path says job_99)"

requirements-completed: [PILOT-03, PILOT-04, PILOT-05]

coverage:
  - id: C1
    description: "An unresolved recovery handle renders a closed unavailable state (no evidence line, no job number, no attempt, no task, no handle) instead of crashing; the mounted test was red on the old code"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#an unresolved recovery handle renders a closed unavailable state"
        status: pass
    human_judgment: false
  - id: C2
    description: "RecoveryView maps every observed status into the closed set, turns the empty-map shape and any partial map into no evidence, and refuses combinations the observer cannot emit"
    requirement: "PILOT-03"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#RecoveryView.build/1 (5 tests)"
        status: pass
    human_judgment: false
  - id: C3
    description: "The mounted Retry status section (seven states and the real unavailable mount) and the mounted Document freshness section (eight observations) canonicalize equal to the shared components' output for a view the test builds itself"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#seam: recovery_status and #seam: document_freshness"
        status: pass
    human_judgment: false
  - id: C4
    description: "Cumulative parity from 7d87a0bb to this plan: 0 differences over the 54 captures that exist on both sides; the five new copy surfaces exist only on head; same code twice 0; a planted heading change reports exactly the one base capture that shows the heading"
    requirement: "PILOT-03"
    verification:
      - kind: command
        ref: "local evidence recorded in this SUMMARY (197-parity-capture.exs); throwaway by decision, not a gate"
        status: pass
    human_judgment: false
  - id: C5
    description: "The JOB-03 journey is unchanged since its baseline and passes in every run, including its verified test"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs (git log d913b8b6..HEAD on the file prints nothing)"
        status: pass
    human_judgment: false
  - id: C6
    description: "The recovery area stories and the JOB-03 Job story compile with no process running and render in light and dark; their notes pass the provenance lint (the D3 variations name the D3 test by a Claim literal it contains)"
    requirement: "PILOT-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#render-all and #provenance and descriptions"
        status: pass
    human_judgment: false
  - id: C7
    description: "The contract test fails on an uncovered component or route, a stale or reasonless @no_story key, a wrong provenance field, a missing or unbacked Mounted test, an over-long description and a forbidden phrase in rendered copy, each with its own planted input and a real-tree plant"
    requirement: "PILOT-05"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#planted coverage, provenance and copy (7 tests)"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#coverage, #provenance and descriptions and #copy rules over every rendered variation"
        status: pass
    human_judgment: false
  - id: C8
    description: "CONTRIBUTING.md lists the contract as ledger row 11 of 12 and says Budget used: 11 of 12.; the root wiring and namespace-fence tests pass; no workflow or CI context changed"
    requirement: "PILOT-05"
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs and test/mix/tasks/verify_namespace_fence_test.exs (106 tests)"
        status: pass
    human_judgment: false
---

# Phase 197 Plan 04: Recovery areas, the D3 fix, the Job story and the catalog gate Summary

**Sync and index's two recovery areas now render through a pure `RecoveryView` and shared components, which fixes defect D3 (the page crashed on an unresolved recovery handle) by construction; the JOB-03 Job story exists; and the catalog contract test now covers coverage, provenance and copy as ledger row 11 of 12.**

## This plan fixes a defect (D3)

`SyncDriftLive` crashed at render with `KeyError :replacement_job` whenever the recovery handle in the URL could not be resolved (an expired 10-minute receipt, another node, a different organization): the observer's unknown outcome left an empty evidence map, which the template read as a full one. The reconnect re-mounted the same URL and crashed again. The page now says the outcome could not be checked and shows no evidence line. This is the second defect fixed in this phase (the first was D1, Plan 01), by the maintainer's 2026-11-22 choice; the commit titles use `test` and `chore`, the first one names the defect, and the phase PR body (Plan 05) must say it plainly. The change is in `scrypath_ops` only; no root `lib/` file, dependency, lock or workflow changed.

### D3 red and green runs

Red, on the code as it stood before the change (`mix test` for the new test only):

```
** (KeyError) key :replacement_job not found in:
    %{}
    (scrypath_ops 0.1.0) lib/scrypath_ops_web/live/sync_drift_live.ex:2182: anonymous fn/3 in ScrypathOpsWeb.SyncDriftLive.render/1
Last message: {:phoenix, :async_result, {:start, {..., {:recovery_observation, 1, "expired-or-other-node-handle"},
  {:ok, {1, "expired-or-other-node-handle", {:unknown, nil, %{index: nil, reason: :receipt_unavailable, state: :not_checked, ...}}}}}}}
  1) test an unresolved recovery handle renders a closed unavailable state (ScrypathOpsWeb.SyncDriftLiveTest)
```

Green, after the change: the same test passes (44 tests in the file at that point, 0 failures; 52 at the end), and `mix precommit` on the final tree runs 2 doctests and 794 tests with 0 failures. The test mounts `/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA&recovery=expired-or-other-node-handle&recovery_generation=0`, waits for the observer, then asserts: the Retry status block says "Recovery refresh could not be checked" in an alert, with the unavailable copy and "Check detail: :receipt_unavailable."; there is no `recovery-evidence` element; the text of both recovery sections holds none of "Queue job", "attempt", "Meilisearch task", "Active index" or the handle; Document freshness says "Not checked" and "Expected-document evidence is unavailable" with no "Expected effect" or document identities; the rest of the page and the way back to Failed sync still render. A control in the same test renders a resolved receipt's evidence and sees "Queue job 991 · attempt 1", so the absence checks can fail.

## Performance

- **Duration:** about 24 minutes by the wall clock (2026-11-22T14:55:49Z to about 15:20Z)
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Files:** 15 (7 created, 8 modified); realized diff about 25.1k tokens by chars/4 over added lines against the 80k estimate (raw 160k)
- **Commits:** 3 task commits, measured from the plan ledger: `72ca3bf1..07ad2dfb`

| Commit | Subject |
|--------|---------|
| `afd059a8` | test(ops-ui): render recovery status through a shared component (fixes defect D3) (Task 1) |
| `c71c97af` | chore(ops-ui): share recovery components and add the JOB-03 job story (Task 2) |
| `07ad2dfb` | test(ops-ui): add catalog coverage, provenance and copy checks as gate 11 of 12 (Task 3) |

The journey file was not touched: `git log d913b8b6..HEAD -- scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` prints nothing, and it passes (4 tests, the verified test included) in every run below. `git diff --name-only origin/main...HEAD -- lib/` and `-- .github/` print nothing; `mix.exs` and both `mix.lock` files have no diff.

## Accomplishments

- **RecoveryView (PILOT-03, D3).** `build/1` takes the schema, handle, status, evidence, document observation, error, check time and loading flag, and returns `{:ok, view}` or a refusal. Status is the closed set `:not_checked | :accepted | :running | :queue_only_completed | :verified | :failed | :cancelled | :unavailable` (the observer's `:unknown` and anything unnamed become `:unavailable`). Evidence is `nil` or a map that holds `replacement_job`, `attempt`, `index` and `task_uid` (nil allowed); an empty or partial map becomes `nil`. Three combinations are refused: `:verified` without a document observation in state `:verified`, an observed status (`:accepted` through `:cancelled`) without full evidence, and evidence while nothing was checked. `for_page/1` is total: a refusal renders as `:unavailable` with no evidence, the observer's error and document observation kept. The labels, kinds and copy moved verbatim from the six helpers. `RecoveryView.Document` holds the document half with every key a component reads present, so a thin observation (`%{state: :unknown, reason: ...}`) cannot crash a render by a missing key.
- **Shared components.** `recovery_status/1` and `document_freshness/1` hold the two sections moved verbatim (ids `ordinary-recovery`, `recovery-observation`, `recovery-evidence`, `document-freshness`, `document-freshness-result` unchanged); `SyncDriftLive.render/1` builds one view per render with `for_page/1` and a once-per-render clock instant, and calls the components when `view.visible?`. Only the recovery slice of `sync_drift_live.ex` changed (209 lines out, 27 in); `swap_live`, `maybe_start_recovery`, the observer subscription and every other section stayed.
- **Stories (PILOT-04).** `areas/recovery_status` (queued, running, queue done with backend evidence pending, verified, failed, canceled, unavailable), `areas/document_freshness` (verified upsert, verified delete, running, unchecked), and `jobs/` with its index (folder index 4) and `job_03_on_call_recovers_failed_sync`. Every variation is built through `RecoveryView.build/1` from Shopadelic values (queue job 991, task 44, index `shopadelic_product`, records SPD-2041 and SPD-2042) in a shape the observer can emit; the sidebar now reads primitives, patterns, areas, surfaces, jobs.
- **Job story (recorded tier decision).** A Job story is one surface state in the paged on-call engineer's situation (ROLE-OPS), not the cross-screen walk, which stays the journey test. It renders the real `FailedSync.surface/1` in two states: arrived from Search health (five rows, Retry on the four Oban jobs, none on the failed Meilisearch task) and after Retry on job 101 (the receipt with replacement job 991, "Completion has not been confirmed", "Original job #101 is retained", the status link, the `Retry queued · queue job 991` flash). Each note is the provenance line plus a one-paragraph caption with no invented name, and names the journey test, which asserts exactly those facts. No Hosting story, no adopter theming (CONTEXT).
- **Copy surfaces.** Five new anchored `CopySurfaces` states (below), each cited by existing rows; `copy_rules_contract_test.exs` passes.
- **Contract test (PILOT-05, the remaining checks).** One shared render pass feeds render-all, identical variations, DOM hygiene and copy. New: coverage, provenance and descriptions, copy over every rendered variation, and a `planted coverage, provenance and copy` describe. `CatalogChecks` gained `coverage_problems/4`, `provenance_problems/4`, `copy_rows/1` and `copy_problems/2`.
- **Ledger.** `CONTRIBUTING.md` row 11 of 12 and `Budget used: 11 of 12.`; no other row edited.

## Variation list per story (every story)

Notes follow `Adopter: <Name> (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: <label>`. "Journey" is `catalog_journey_test.exs`, "D3 test" is `sync_drift_live_test.exs` with a `Claim:` literal that the test contains.

| Story | Variations | Ids and proof labels |
|---|---|---|
| `areas/recovery_status` | 7 | `shopadelic_failed_journey_` + `queued` (Journey), `running`, `queue_done_backend_pending`, `failed`, `canceled` (render only), `verified` (Journey), `unavailable` (D3 test, Claim "an unresolved recovery handle renders a closed unavailable state") |
| `areas/document_freshness` | 4 | `..._verified_upsert` (Journey), `..._verified_delete`, `..._running` (render only), `..._unchecked` (D3 test, Claim "Expected-document evidence is unavailable") |
| `jobs/job_03_on_call_recovers_failed_sync` | 2 | `..._arrived_from_health`, `..._retry_queued` (both Journey, each with its caption) |
| Earlier stories | 44 | unchanged (primitives 17, patterns 4, Search health and Failed sync areas 19, surfaces 4) |

Whole catalog: 57 variations in 17 stories (primitives 17, patterns 4, areas 30, surfaces 4, jobs 2). The rendered text of every new variation was read and three descriptions were corrected to the page's own words (the queued status description first claimed the page says the backend has not confirmed it, while the copy says the queue has it and refresh only observes; the queue-done and verified-upsert descriptions were tightened the same way). The Job story's receipt was read in the render: "Retry queued · Oban job #991 will add or update records in shopadelic_product . Completion has not been confirmed. Original job #101 is retained. Check sync status", with the handoff link to `/ops/sync-and-index?recovery=...&recovery_generation=0&schema=ScrypathFixtures.Shopadelic.Product`.

## Cumulative parity record (throwaway local evidence, not a gate)

- **Base:** `7d87a0bb24c702b515b8f882bc170970d25eb828` (the commit before Plan 02 Task 1; the session scratchpad still held its 54-file capture, written after the script's last fix). **Head:** the working tree whose lib code is this plan's Task 2 (`c71c97af`; no lib change after it). Result: `PARITY: 5 differences over 59 captures`.
- **The five differences, all intended:** `copy__failed_sync.delete_confirmation`, `copy__failed_sync.scoped_load_error`, `copy__posture.shopadelic_degraded`, `copy__sync_drift.recovery_unavailable` and `copy__sync_drift.recovery_verified` exist only on head, because this plan registered them; there is nothing on base to compare. **0 differences over the 54 captures present on both sides** (11 scenarios x 2 pages, 16 `phase173` pages, 16 earlier copy surfaces), including `copy__sync_drift.recovery_queued`, the one earlier capture that renders both recovery sections. No page crashed on either side.
- **Control 1, same code twice:** head against a second head capture: `0 differences over 59 captures`.
- **Control 2, planted text change:** the Retry status section title changed to `... PLANTED` in `recovery_status/1`. Result: 6 differences, the five head-only files and `copy__sync_drift.recovery_queued.html`, which `grep -l 'Retry status'` confirms is the only base capture that shows the heading. The plant was reverted (`diff` against the saved copy is empty).
- **The D3 change is not in the 54:** no earlier capture reaches an unresolved handle (the base page would have crashed there), so the D3 state is covered by the mounted test and the new `copy__sync_drift.recovery_unavailable` capture only.
- **Cleanup:** the copied script is gone from `scrypath_ops/test/` and no `parity-base` worktree is listed (the plan's second verify command passes). The head capture directories are session-local in the scratchpad.

## New copy surfaces and the rows that cite them

| Surface id (anchor) | Reached by | Cited by |
|---|---|---|
| `failed_sync.delete_confirmation` ("Confirm delete sync work") | Shopadelic failed journey, Retry pressed on job 104 | `pending-aggregate`, `retry-surfaces-no-accepted` |
| `failed_sync.scoped_load_error` ("Failed sync work could not load") | Logistify history over the limit, `/ops/failed-sync` | `pending-aggregate`, `clear-not-healthy` |
| `posture.shopadelic_degraded` ("Sync jobs and Meilisearch tasks failed") | Shopadelic failed journey, `/ops/health` | `control-room-casing`, `last-succeeded`, `pending-aggregate`, `clear-not-healthy` |
| `sync_drift.recovery_unavailable` ("Recovery refresh could not be checked") | the D3 URL, mounted | `retry-surfaces-no-accepted`, `clear-not-healthy` |
| `sync_drift.recovery_verified` ("Recovery verified") | mounted page with the verified assigns merged, as the existing queued surface does | `retry-surfaces-no-accepted`, `clear-not-healthy` |

## Contract test: what it does now, with costs and counts

- **Checks:** render-all, no two identical variations and DOM hygiene (Plan 03, unchanged in behavior); coverage; provenance and descriptions; copy rules over every rendered variation. 26 tests.
- **`@no_story` keys by kind (for the Pause 1 note):** 61 literal keys, **57 components** (47 `OpsUi`, 2 `ResultUi`, 2 `CoreComponents`, 6 `Layouts`) and **4 routes** (`ControlRoomLive`, `SearchLive`, `HelpLive`, `SyncDriftLive`), each with a one-line reason. The reasons cite the recorded deferrals (primitives Phase 198 or later; Control room, Search and Help in Phase 197 CONTEXT Deferred Ideas; Sync and index as a whole surface deferred with its two recovery areas storied; the shell helpers rendered inside every surface story). Storied, not listed: 5 `OpsUi` primitives, 6 `FailedSync`, 3 `SearchHealth`, 2 `Recovery` components, and the `PostureLive` and `FailedSyncLive` routes (the surface and Job stories cover them). The inventory is computed from the loaded app modules and `Phoenix.Router.routes/1`; no count is asserted.
- **ExUnit time:** `catalog_contract_test.exs` alone ran twice, **1.3 s and 1.7 s** (26 tests); with `copy_rules_contract_test.exs`, 2.3 s (57 tests). Plan 03's three full render passes took 2.0 to 2.9 s for 13 tests over 44 variations; one shared pass now covers 57 variations in both themes (114 renders) in less. This is the cost input for the CI-EFFICIENCY entry (Plan 05); the whole ops suite is about 31 s ExUnit time in `mix precommit`.
- **Decisions recorded:** (1) Copy lint applies the rows that scan all copy (a non-empty `source_scope` with forbidden text: casing, last succeeded, pending, retry queued wording, Clear not Healthy), not the surface-only rows such as "Clear beside a retained observation", because a healthy-schema story legitimately says Clear; `copy_rows/1` selects them and a test pins the split. Required text is not checked (a story shows one state). (2) A jobs-tier story counts main landmarks like a surface story (it renders a whole page). (3) One shared render pass in `setup_all`; `render_every_variation` skips `{:unsupported, _}` targets so a `:page` story cannot break the other checks (render-all still refutes unsupported targets, see the hand-off). (4) Provenance accepts any `Persona: <label> (ROLE-X)` registered in `OPERATOR-UI-QUALITY.md`. (5) Primitives are exempt from the provenance line (commented in the test).

## Planted failures

Wiring seams (each restored and checked by `diff`):

| Plant | Result |
|---|---|
| LiveView drops `loading?` | seam fails on "running and checking: page differs" |
| LiveView drops `error` | the real mounted unavailable seam, the "refresh could not be checked" case and the D3 test fail |
| LiveView drops `checked_at` | seam fails on "queued retry: page differs" |
| `document_freshness` gets a `now` two hours later | seam fails on "verified upsert: page differs" |
| LiveView drops the document observation | the document seam, the verified status seam, the old verified-freshness test and the D3 test fail |
| `evidence/1` passes a partial map through (the D3 shape returns) | the D3 test and the real unavailable seam crash with the same `KeyError`, and the unit test reports `%{}` where nil is required |
| the `:verified` refusal removed | the refusal unit test reports `{:ok, ...}` where `{:error, :verified_without_document_evidence}` is required |

Contract checks, planted into the real tree (restored; `diff` empty):

| Plant | Result |
|---|---|
| D3 variation's `Claim:` literal changed to text the test lacks | `{:unbacked_proof, "scrypath_ops/test/.../sync_drift_live_test.exs", "a handle that nobody ever wrote down"}` |
| a description over 140 characters | `{:long_description, 175}` |
| `areas/failed_row.story.exs` moved away | `{:uncovered, {ScrypathOpsWeb.Components.FailedSync, :failed_row}}` |
| the casing phrase planted into the Retry status subtitle | `{:copy, "control-room-casing", ...}` for every recovery variation in both themes |

Planted inputs inside the contract test, each asserting its exact tag: coverage (a key naming nothing, a key a story covers for a component and for a route, an unlisted component and route, a blank and a two-line reason), provenance (`:bad_job`, `:job_mismatch`, `:job_not_in_path`, `:missing_test`, `:unbacked_proof` with a stripped copy of the real journey file and with a missing claim, `:proof_without_needle`, `:long_description` at 141 and a passing 140, `:missing_description`, `:unknown_adopter`, `:unknown_role`, `:no_provenance` for four malformed notes), copy (the casing phrase and the status-word row in a fragment and planted into the real surface render), and the jobs-tier main count (none, two, one, and a plant into the real Job render). Positive controls: the real inventory, a render-only note, a Mounted note whose file holds the scenario id, a claim that is present, a note with a caption after the first line, and the real surface render with no phrase.

## Task verification

- `mix precommit` (compile with warnings as errors, `deps.unlock --unused`, format, full ops suite) after the last commit: 2 doctests, 794 tests, 0 failures in about 31 s; no lock change. Task 1: 79 tests across the four files in its verify command (0 failures) and the full suite at 780. Task 2: 304 tests across the `live/` directory, copy rules and the contract test (0 failures) and the full suite at 781. Task 3: contract and copy rules 57 tests; root `workflow_wiring_test` and `verify_namespace_fence_test` 106 tests; `mix format --check-formatted` clean in both projects.
- `node scripts/ci/ui_literal_policy.cjs`: PASS (30 finding occurrences, unchanged). `mix verify.namespace_fence`: passed.
- **Not run here, a known risk:** `mix verify.ops_ui` (the root boundary integration test builds dev, test, prod and mounted trees), the rest of the repository-contracts lane and the Docker lane. The new `lib` modules are pure (no process, no dev-only reference) and the ops suite that lane runs after the boundary test passed through `mix precommit`. Plan 05 runs the full pre-push mirror on the final tree.

## Deviations from Plan

### Auto-fixed issues

**1. [Design] The Document freshness component and the Document struct were written in Task 1**
- **Issue:** `RecoveryView.build/1` must read the document observation (the `:verified` refusal, the section's visibility), so the document half of the view and its component were written with the tracer. The Task 1 commit therefore holds `document_freshness/1` and `RecoveryView.Document` (unused by the LiveView until Task 2) while the LiveView still rendered its own document section with its three helpers. The tracer gate was kept: the Task 1 verify, the plants and the full suite ran green before Task 2 started.
- **Effect:** Task 2's commit has nine paths (no `recovery_view.ex` or `recovery.ex` edit; `recovery_status.story.exs` is edited for two corrected descriptions), Task 1's has six.
- **Commits:** `afd059a8`, `c71c97af`

**2. [Design] `Document` is its own file**
- The app guidelines forbid nesting modules in one file (as with Plan 03's `Row`), so `ScrypathOps.RecoveryView.Document` lives in `lib/scrypath_ops/recovery_view/document.ex`. With the comment edit in `_surfaces.index.exs` (it said the jobs folder was still to come) that makes 15 files against the plan's 13.

**3. [Design] Seam tests render through `SyncDriftLive.render/1` over mounted assigns**
- A mounted view cannot be made to re-render with injected recovery state without `handle_params` resetting it, so the status and freshness seams take a mounted view's own assigns, merge the state (as `CopySurfaces` does) and render through the LiveView's own `render/1`. The real mounted case that matters most, the unresolved handle, has its own seam over the real mount. The journey proves the real queued and verified pages.

**4. [Design] The copy lint governs stories with the global rows only**
- See "Decisions recorded" above. Applying every row to every story would flag legitimate copy (a healthy-schema story says Clear) or require a state the story does not show.

**5. [Design] Jobs-tier stories count mains**
- `tier/1` already returned `:job`; the plan left open whether the main count applies to it. It does, because the Job story renders a whole page.

**6. [Design] One status label for every unreadable outcome**
- The old helpers gave `:unknown` the "could not be checked" copy but gave any other unnamed status the "No recovery result has been checked yet" copy under the same "could not be checked" label. No unnamed status can occur (the observer emits the named ones and `:unknown`), so both now map to `:unavailable` with the `:unknown` copy; nothing reachable changes.

**7. [Rule 1 - Bug in my own test, caught before any commit]**
- My first D3 test selected `#ordinary-recovery`, which is the heading id, not the section, so its absence checks would have read only the headings; and one assertion used `=~ ... or error`. Both were found while writing the seam tests and fixed (the sections are selected by `aria-labelledby`, and the title is asserted exactly).

**8. [Rule 1 - Bug in my own test, caught by the first run]**
- Two provenance plants reported two problems each (a JOB-99 note also trips the file-name check, and a mismatched job does too). Each plant now uses a story path that carries the note's job so it reports exactly one cause.

Total deviations: 8 (6 design, 2 own-test bugs). Impact: none on scope; no root `lib/` file, dependency, lock or workflow changed. No cut from the plan's cut order was taken.

## Authentication gates

None.

## Known Stubs

None. The Job story and the recovery stories are static renders by design: buttons do nothing, the shell links carry `/ops/...` hrefs the catalog server does not serve, and the "Check sync status" link in the retry receipt goes to a handle that exists only in the story.

## Threat Flags

None beyond the plan's register: T-197-13 (the evidence shape that crashed the page cannot exist; the mounted test was red on the old code and plants return it to red), T-197-14 (the unavailable state shows no evidence line, job number, attempt, task or handle; the D3 test refutes each and a control shows the line when evidence exists; receipt identity binding is untouched), T-197-15 (the lint requires registered fictional adopters; no Hosting story), T-197-16 (a literal `@no_story` with a reason per key; stale, covered and reasonless keys fail; counts are computed; plants prove both directions), T-197-SC (no package added; locks untouched).

## Findings for the maintainer and the Pause 1 note (recorded, not fixed)

- **Copy defect (product), now in two more places:** the unavailable state and the unchecked document area print the observer's atom as text ("Check detail: :receipt_unavailable.", "... (:receipt_unavailable) ..."). Moved verbatim.
- **Dead observer branches (code, not fixed):** `handle_async` accepts bare-status and two-element shapes, `observe_recovery_now` matches `{:error, :job_running}` and `{:error, :queue_only_completed}`, and `verify_task_and_documents` returns `{:running, nil}`, `{:failed, nil}`, `{:cancelled, nil}` and `{:queue_only_completed, nil}`. `validate_recovery_job` returns `{:ok, :running}` and `validate_recovery_task` returns only mismatch errors, so none of those shapes can occur; the new refusal of an observed status without evidence covers exactly them.
- **The unavailable state still offers "Refresh recovery status":** with an unresolved handle a refresh returns the same answer. It is the existing behavior, and the copy says to refresh the same operation. Whether to hide the button there is a product call.
- **Markup defect already recorded (Plan 03), visible in the receipt again:** `ops_inline_code` puts its text on its own lines inside `<code>`, so "records in shopadelic_product ." probably shows a gap before the period. Not opened in a browser.
- **Existing behavior now visible in stories:** the Failed sync load error shows the raw Elixir error term; a retrying row also offers Retry; "3 sync jobs and 1 Meilisearch tasks failed" (no singular). The new `failed_sync.scoped_load_error` and `posture.shopadelic_degraded` copy surfaces render the first and the third; the copy rules pass on them because no row governs those words.
- **Recovery `Schema:` line shows the full module name** (`ScrypathFixtures.Shopadelic.Product`) in the evidence line; unchanged.
- **Persona wording:** the Job story captions say "The on-call engineer"; no name is invented.

## Hand-off for Plan 05 (not done here)

- `catalog_contract_test.exs` still needs the bundle-font check with its plant and the landing-page marker holder check (Plans 01 and 02 notes), and the first compare-mode probe run against a real page dump (`shopadelic_failed_journey__health.html`).
- The landing page will be a `:page` story: `RenderAll.targets/1` reports it as `{path, {:unsupported, :page}}` and the render-all test still refutes any unsupported target, so that assertion must be adjusted deliberately (the shared pass already skips such targets). Its provenance is not linted (no variations); the coverage check only reads `function/0` and `covers/0`.
- `@no_story` and the ledger row text name "Phase 198 or later" and the CONTEXT deferrals; if Plan 05 or Pause 1 changes the deferrals, edit the shared reason attributes.
- The ledger row's cost input: the catalog test is 1.3 to 1.7 s warm; whole ops suite about 31 s. Hosted `ops-ui` was 342 to 436 s in the same-hour controls, so the catalog test is under 1 percent of the job.
- Pre-push mirror still owed: `HEX_HTTP_TIMEOUT=120 mix verify.ops_ui`, the repository-contracts lane (`mix verify.repository_contracts`, needs fetch access), and the Docker lanes if the Docker VM is idle.

## Issues Encountered

- This machine's shared Postgres prints `too_many_connections` noise during `mix test`; every run passed.
- `mix format` rewrote my first-draft test edits (multi-line asserts), so two scripted edits had to be redone against the formatted text; no commit was affected.
- BSD `sed -i` needs an extension argument; the first three plants did nothing and were redone with a small Python helper (restores checked by `diff`).

## Next Phase Readiness

Plan 05 stands up the 4003 storybook (catalog endpoint, landing page with `main@sha`, `UI-PREVIEW.json` block, preflight extension), the AGENTS.md, UI-REVIEW, glossary and playbook edits, the fidelity probe record and the Pause 1 note, then the phase PR. Everything it reads is in place: 57 variations in 17 stories across all five tiers, the Job story, the contract test with its coverage, provenance and copy checks, ledger row 11 of 12, and the `@no_story` counts above for the Pause 1 note. Pause 1 hand-off items: F1, F2, D2, F3 and F4 stay with the maintainer, D1 and D3 are the two defects fixed in this phase (both `scrypath_ops` only, no root `lib/` change), and the findings above join the earlier ones.

## Self-Check: PASSED

All 15 files of this plan exist on disk (the 7 created and the 8 modified), the three task commits (`afd059a8`, `c71c97af`, `07ad2dfb`) are ancestors of HEAD, `sync_drift_live.ex` holds none of the six moved helpers and calls `RecoveryView` and `Recovery`, the Job story file is present, `CONTRIBUTING.md` says `Budget used: 11 of 12.` once and names `catalog_contract_test.exs` once, the contract test holds `@no_story` and all six coverage and provenance tags, the journey file has no commit since its baseline, the copied capture script and the `parity-base` worktree are gone, and no root `lib/` file or `.github/` file differs from `origin/main`.
