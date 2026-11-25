---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
plan: 02
subsystem: ui
tags: [liveview, function-components, view-model, storybook, seam-test, canonical-tree, parity-capture, search-health, ops-ui]
status: complete

requires:
  - phase: 197-01
    provides: "JOB-03 journey (baseline d913b8b6, unmodified here), the catalog server, the storybook font fix and the boundary rows"
  - phase: 196-fixtures-and-three-adopters
    provides: "ScrypathFixtures scenarios, FixtureEnv and the pinned preview epoch the stories and seam tests build from"
provides:
  - "Posture.scan/2 (the only I/O, public) and Posture.build/3 (pure, input :unconfigured | :missing_backend | [row]); summary/2..4 keep their signatures"
  - "ScrypathOpsWeb.Components.SearchHealth: health_verdict/1, health_schema_row/1 (ok and error variants), surface/1 with a fixture_controls slot; PostureLive renders one surface/1 call"
  - "Three glossary-tier stories (areas/health_verdict, areas/health_schema_row, surfaces/search_health), 11 variations, plus the primitives, areas and surfaces tier indexes"
  - "ScrypathOps.Test.HtmlCanon (canon/1, digest/1) and one seam test per area"
  - "197-parity-capture.exs, a reusable throwaway capture-and-compare script, with its recorded result and controls"
affects: [197-03, 197-04, 197-05]

actuals:
  tokens: 21500
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 7d87a0bb24c702b515b8f882bc170970d25eb828
plan_head_after: f19c4866fd16fffe8e0d871c5734aa0f61189d31

tech-stack:
  added: []
  patterns:
    - "A pure builder (Posture.build/3) is the only thing a story calls; a story that needs a process fails mix compile"
    - "One function component per area, called by both the LiveView and the story; a seam test proves the mounted page equals the component output for the page's own view-model"
    - "Parsed-tree comparison with sorted attributes instead of raw HTML text"
    - "Throwaway parity capture: capture base and head with the same script, compare canonical trees, record the controls"

key-files:
  created:
    - scrypath_ops/lib/scrypath_ops_web/components/search_health.ex
    - scrypath_ops/test/support/html_canon.ex
    - scrypath_ops/storybook/areas/health_verdict.story.exs
    - scrypath_ops/storybook/areas/health_schema_row.story.exs
    - scrypath_ops/storybook/surfaces/search_health.story.exs
    - scrypath_ops/storybook/primitives/_primitives.index.exs
    - scrypath_ops/storybook/areas/_areas.index.exs
    - scrypath_ops/storybook/surfaces/_surfaces.index.exs
    - .planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-parity-capture.exs
  modified:
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs

key-decisions:
  - "health_verdict/1 also renders the two configuration empty states for the setup postures, so the Wikily variations render something and the render-all 'empty output' check stays meaningful"
  - "The components take the LiveView's ranked rows as a separate attribute and never sort, so SKIN-07 (a row moves only when a refresh brings new evidence) is unchanged"
  - "Every ops_time inside the components falls back to the posture's snapshot instant, never the clock"
  - "The parity script pins the test clock for the copy surfaces and normalizes the random recovery handle, otherwise the same code twice reports differences"

patterns-established:
  - "Plant one cause, assert that cause: every retargeted source assertion and each seam test was proven against a planted failure"
  - "A source-reading test that a move trips is retargeted in the same task that moves the markup, so no commit is red"

requirements-completed: []

coverage:
  - id: C1
    description: "Posture.summary/4 is scan/2 plus the pure build/3; the 16-scenario round trip and the Posture behaviors are unchanged"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs (the existing Posture and Search health tests in the file, unchanged apart from deviation 2)"
        status: pass
    human_judgment: false
  - id: C2
    description: "The mounted Search health verdict, every row and the whole page canonicalize equal to the shared components' output for five fixture scenarios"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs#seam: health_verdict, #seam: health_schema_row and surface (5 scenarios)"
        status: pass
    human_judgment: false
  - id: C3
    description: "The canonical tree ignores attribute order, generated ids, tokens and whitespace but not text, ordinary ids or ordinary attributes"
    requirement: "PILOT-03"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs#HtmlCanon (2 tests)"
        status: pass
    human_judgment: false
  - id: C4
    description: "The three Search health stories compile with no process running, and all 11 variations render in light and dark through the existing render-all test"
    requirement: "PILOT-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#render-all"
        status: pass
    human_judgment: false
  - id: C5
    description: "Parity: base 7d87a0bb against head shows 0 differences over 54 captures (11 scenarios x 2 pages, 16 phase173 pages, 16 copy surfaces); same code twice 0; a planted text change reports exactly the 22 captures that render a row"
    requirement: "PILOT-03"
    verification:
      - kind: command
        ref: "local evidence recorded in this SUMMARY (197-parity-capture.exs); throwaway by decision, not a gate"
        status: pass
    human_judgment: false
  - id: C6
    description: "The source-reading assertions that the move trips now read the component file, and each fails on its own cause when its token is removed"
    requirement: "PILOT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs and design_tokens_contract_test.exs (planted removals recorded below)"
        status: pass
    human_judgment: false
---

# Phase 197 Plan 02: Search health extraction, first stories and the parity capture Summary

**Search health now renders through shared function components over a pure `Posture.build/3`; three glossary-tier stories show the same markup the page does, and a canonical-tree parity capture over 54 pages shows no change from the commit before the extraction.**

## Performance

- **Duration:** about 15 minutes by the wall clock (2026-11-22T14:12Z to 14:27Z), most of it two cold base captures and the full ops suite
- **Tasks:** 2 of 2 (Task 1 was the tracer)
- **Files:** 14 (9 created, 5 modified); realized diff about 21.5k tokens by chars/4 against the 75k estimate (raw 150k)
- **Commits:** 2 task commits, measured from the plan ledger: `7d87a0bb..f19c4866`

| Commit | Subject |
|--------|---------|
| `5eec3656` | chore(ops-ui): render the Search health verdict through a shared component (Task 1) |
| `f19c4866` | chore(ops-ui): share the Search health components with the storybook (Task 2) |

The journey file was not touched: `git log d913b8b6..HEAD -- scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` prints nothing, and the journey passes (4 tests) in every run below. Neither `phase173_fixture_source.ex` copy changed (`git diff origin/main` exits 0). No root `lib/` file, dependency or lock changed.

## Accomplishments

- **View-model split (PILOT-03).** `Posture.scan/2` is public and is the only I/O; `Posture.build/3` takes `:unconfigured | :missing_backend | [row]`, a snapshot instant and the previous summary, and holds the old branches verbatim with no clock read. `summary/4` is now a three-way `cond` feeding `build/3`. A story can build the view-model with no process running.
- **Shared components.** `SearchHealth.health_verdict/1`, `health_schema_row/1` (ok and error variants) and `surface/1` hold all the Search health markup. `PostureLive.render/1` is one `SearchHealth.surface/1` call. The presentation helpers that lived in the LiveView moved with the markup (22 of the 23 listed in the research; `posture_schema_count` is replaced by the summary's own `schema_count`). The Phase 173 fixture form stays in `posture_live.ex` and reaches the surface through the `fixture_controls` slot; the `refresh-disabled` expression stays there too (`grep -c phase173 posture_live.ex` is 27, the same as before).
- **Stories (PILOT-04).** 11 variations in the glossary tiers, scenario ids as variation ids, a provenance line on each, `job/0` and `covers/0` on each. Folder indexes put the sidebar in ladder order (primitives 0, areas 2, surfaces 3; patterns 1 and jobs 4 arrive with their first stories). The sidebar sorts indexed folders by `{index, name}` and puts unindexed ones last (read from `phoenix_storybook/live/sidebar.ex`); I did not open the sidebar in a browser.
- **Seam tests.** One per area: the verdict (failed journey), every row and the whole page (five scenarios, one test each). The comparison is the canonical tree of the mounted subtree against `render_component/2` of the same function with the page's own summary, ranked rows, sync mode and snapshot instant.
- **Canonical tree.** `ScrypathOps.Test.HtmlCanon.canon/1` (string or parsed selection) and `digest/1`, 25 lines of tree walking, no dependency.

## Variation list per story

Provenance line format: `Adopter: <Name> (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: <label>`. Every `Mounted` label names `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`, which contains each variation's scenario id as an atom in its seam test.

| Story (`job/0` JOB-03, `covers/0` PostureLive) | Variation id | Proof label |
|---|---|---|
| `areas/health_verdict` | `shopadelic_failed_journey` | Mounted |
| | `shopadelic_settings_aligned` | render only |
| | `wikily_unconfigured` | render only |
| | `wikily_missing_backend` | render only |
| | `logistify_history_over_limit_f1` | render only |
| `areas/health_schema_row` | `shopadelic_failed_journey_failed` | Mounted |
| | `wikily_first_delete_failed_backend_failed` | Mounted |
| | `shopadelic_settings_aligned_clear` | Mounted |
| | `logistify_history_over_limit_f1_not_checked` | Mounted |
| `surfaces/search_health` | `shopadelic_failed_journey` | Mounted |
| | `wikily_unconfigured` | Mounted |

Distinct row states reached: failed on queue and backend, failed on backend only, clear, and a row that could not be checked. `logistify_deep_queue` is deliberately not used (its pending count comes through the fake inspector, which the real one would cap at 100 rows, Phase 196 hand-off IN-01). The rendered text of each area variation was read and matches its description. A local digest pass over `[data-phx-main] > *` in light and dark found no two identical variations (the gate for it arrives in Plan 03).

## Parity record (throwaway local evidence, not a gate)

- **Base:** `7d87a0bb24c702b515b8f882bc170970d25eb828` (the commit before Task 1). **Head:** the working tree that became `f19c4866` (no code change between the capture and the commit).
- **Result:** `PARITY: 0 differences over 54 captures`. The 54: 11 scenarios x 2 pages (`/ops/health`, `/ops/failed-sync`), the 16 `/ops/phase173/health?scenario=<name>` pages (names read from the fixture source, each checked to be the selected option), and the 16 `CopySurfaces` anchored surfaces. No capture was a crash on either side. With zero differences there is nothing to classify as intended.
- **Control 1, same code twice:** the first version of the script reported 15 differences between two head captures. All were the copy surfaces: they read the wall clock unless the test clock is pinned, and one queued-retry page carries a 24-byte random recovery handle. The script now pins the test clock for those surfaces and normalizes the handle; after that, head against head is `0 differences over 54 captures`. The first base-against-head comparison (unpinned script) also showed only timestamp and handle differences in the files visible before its output was cut off (Control room surfaces, `failed_sync.after_retry`, `posture.default` and the Sync and index surfaces); I did not read its full list, because the control had already shown the noise. The base was recaptured with the fixed script, and that is the comparison recorded above.
- **Control 2, planted text change:** `Meilisearch document tasks` changed to `... PLANTED` in `health_schema_row/1`. Result: `22 differences over 54 captures`, and the 22 files are exactly the captures whose text contains that heading (derived by `grep -l` over the head capture, compared with `diff`). The 32 captures with no row (setup states, every failed-sync page, the Control room surfaces) did not move. The plant was reverted (`diff` against the saved copy is empty).
- **Cleanup:** the copied script is gone from `scrypath_ops/test/` and no `parity-base` worktree is listed (the plan's second verify command passes). The base worktree was created twice, once per base capture, and removed each time.
- **Reuse:** Plans 03 and 04 run the script as its moduledoc says; the cumulative base for Plan 04 is `7d87a0bb`. The session scratchpad still holds the base capture directory, but it is session-local, so recapture it if it is gone.

## Retargeted source assertions and their planted failures

Each token was removed (or a refuted one added) in the component file, the test failed on that assertion, and the file was restored (restore checked by `diff`).

| Assertion | File | Planted change | Failing line |
|---|---|---|---|
| `space-y-ops-4` present | `design_tokens_contract_test.exs` | class changed to `space-y-6` | `assert posture_live =~ "space-y-ops-4"` |
| `gap-ops-4` present | `design_tokens_contract_test.exs` | `gap-ops-4` replaced by `gap-4x` | `assert posture_live =~ "gap-ops-4"` |
| `mt-4` refuted | `design_tokens_contract_test.exs` | `mt-4` added to the schema list class | `refute posture_live =~ "mt-4"` |
| failed-sync handoff path | `operator_ia_contract_test.exs` | `OperatorSelection.path(...)` replaced by string interpolation | `assert @search_health =~ "OperatorSelection.path(@mount_path, \"failed-sync\", @mod)"` |

Seam test plants: the LiveView passing `sync_mode={:manual}` fails the verdict seam on `"1 schema · Manual sync"` against `"1 schema · Background sync with Oban"`; the LiveView passing `refresh_disabled={true}` fails the surface seam in all five scenario tests (the existing refresh tests fail too, as expected).

## Task commits and verification

- `mix precommit` (compile with warnings as errors, `deps.unlock --unused`, format, full ops suite) on the Task 2 tree: 2 doctests, 743 tests, 0 failures in about 34 s warm. It left no lock change.
- Task 1 verify set (journey, posture, round trip, Control room, catalog contract, plus design tokens and copy rules): 146 tests, 0 failures before the Task 1 commit. Task 2: after the move, the `live/` directory plus design tokens, catalog contract and the round trip passed (280 tests); after the stories, seam tests and retargets, the posture, catalog contract, operator IA and design tokens files passed (69 tests); then the full ops suite through `mix precommit`, above.
- `node scripts/ci/ui_literal_policy.cjs`: PASS on both commits (30 finding occurrences, unchanged). `mix verify.namespace_fence`: passed.
- **Not run here, a known risk:** `mix verify.ops_ui` (the root boundary integration test builds dev, test, prod and mounted trees, so a prod-only problem in the new `lib` module would show there; the module references nothing dev-only), the rest of the repository-contracts lane, and the Docker lane. Plan 05 runs the full pre-push mirror on the final tree. The ops suite itself, which is what `mix verify.ops_ui` runs after the boundary test, passed through `mix precommit`.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 - Blocking] The design-tokens source assertion had to be retargeted in Task 1, not Task 2**
- **Found during:** Task 1, when the verdict markup (which carries `space-y-ops-4`) moved out of `posture_live.ex`
- **Issue:** `design_tokens_contract_test.exs` reads `posture_live.ex` for that token, so the Task 1 commit would have been red. The plan scheduled the retarget for Task 2.
- **Fix:** the assertion reads `posture_live.ex` and `components/search_health.ex` concatenated, in Task 1. The Task 1 commit therefore has seven paths, not six; the Task 2 commit has ten, not eleven.
- **Commit:** `5eec3656`

**2. [Rule 1 - Bug in a test] One existing test injected state the verdict no longer reads**
- **Found during:** Task 1 verify (`a queue that was not observed never renders Clear on the page`)
- **Issue:** it overwrote the derived `:posture_rows` assign and expected the verdict (then computed from that assign) to follow. The verdict now reads the one posture view-model, so the injected rows and the stale summary disagreed. That state (rows and summary inconsistent) is one the LiveView never produces.
- **Fix:** the test injects a coherent summary built by `Posture.build([row], now, nil)` next to the ranked rows. Every assertion is unchanged, so it proves the same thing through the pure builder. The other injection test (rows re-sort only on refresh) passes unchanged.
- **Commit:** `5eec3656`

**3. [Rule 2 - Missing critical functionality] `health_verdict/1` renders the setup empty states**
- **Issue:** the plan's story list includes `wikily_unconfigured` and `wikily_missing_backend`, but the old verdict markup renders nothing for those postures (the empty states sat beside it). A component that renders nothing would fail the render-all `empty output` check.
- **Fix:** `health_verdict/1` renders `ops_config_empty` for `:unconfigured` and `:missing_backend`. The page DOM is identical (the only reorder is relative to the always-false `auto_refresh` paragraph).

**4. [Design] Component attributes follow what each component reads**
- `health_verdict/1` takes `summary` and `sync_mode`, not `now` and `mount_path` as the plan sketched, because the verdict reads neither. `surface/1` and `health_schema_row/1` take `now`, and every `ops_time` falls back to it (`|| @now`), so no time in a component reads the clock. The fallback only applies where the old code passed `nil` and no exact time was shown, so output is unchanged (the parity run confirms it).

**5. [Design] The retargeted operator IA literal ends in `@mod`**
- The row component binds the module as an assign, so the markup reads `OperatorSelection.path(@mount_path, "failed-sync", @mod)`. The assertion pins the same call with the same arguments.

**6. [Rule 1 - Bug in the plan's script] The parity script needed a pinned clock and handle normalization**
- A faithful implementation of the plan's script reports differences for identical code (see Control 1). Both fixes are in `197-parity-capture.exs`.

**7. [Rule 1 - Bug in my own change] A doc comment broke a copy rule**
- My `build/3` doc said "last successful source references", which the `last-succeeded` copy row forbids in `scrypath_ops/lib/**`. Found by `copy_rules_contract_test.exs` before the Task 1 commit; reworded.

Total deviations: 7 (1 blocking, 2 bug, 1 missing critical, 2 design, 1 own-change). Impact: none on scope; no root `lib/` file, dependency or lock changed.

## Authentication gates

None.

## Known Stubs

None. The surface story is a static render by design: its buttons do nothing, and its shell links carry `/ops/...` hrefs (read from the rendered HTML: `/ops`, `/ops/search`, `/ops/health`, `/ops/failed-sync`, `/ops/sync-and-index`, `/ops/help`, the schema-scoped failed-sync link, `/ops/help#sync`, `/ops/search?saved=manage`) that the catalog server does not serve.

## Threat Flags

None beyond the plan's register: T-197-06 (markup moved verbatim into HEEx components, escaping unchanged; the parity and seam tests prove identical output, and the Phase 196 hostile render test runs in the `live/` suite and passed), T-197-07 (stories call only `Scrypath.sync_status/2` and the pure builder; a story that needs a process fails `mix compile`), T-197-08 (the capture script lives in the phase directory, and the plan's verify asserts the copy and the worktree are gone, which they are).

## Findings for the maintainer and the Pause 1 note (recorded, not fixed)

- **Copy defect (product):** the Shopadelic failed-journey verdict reads "3 sync jobs and 1 Meilisearch tasks failed" (no singular for the task count; `degraded_evidence` in `posture.ex`). It is on the Search health surface story and the verdict story.
- **Static surface story (catalog):** shell links in `surfaces/search_health` go to `/ops/...`, which the catalog server does not serve, and the shell's theme control sits inside the story iframe next to the storybook's own theme toggle. Both are by-design consequences of rendering the real shell; worth a word on the landing page in Plan 05 and a look at Pause 1. I did not click through them in a browser.
- **Possible stray space (product, unconfirmed):** in the missing-backend empty state the extracted text reads "`:scrypath_ops` ." (a space before the closing period). It may come from the inline-code component's markup. I have not looked at it rendered.
- **Existing behavior now visible in a story (F1):** for the Logistify task-history-over-limit scenario the row says "Not checked" with "Search task history exceeded its configured limit.", and the verdict says it "could not be fully checked". That is today's behavior, shown as is; F1 itself stays with the maintainer.

## Issues Encountered

- This machine's shared Postgres prints `too_many_connections` noise during `mix test`; every run passed.
- The first base capture used the unpinned-clock script, so a second base worktree and capture were needed after the script fix (about 5 minutes of cold compile each).

## Next Phase Readiness

Plan 03 extracts Failed sync the same way: reuse `ScrypathOps.Test.HtmlCanon` (it accepts a parsed `LazyHTML` selection as well as a string), the story conventions in `areas/health_verdict.story.exs`, and `197-parity-capture.exs` with a new base worktree at the commit before its Task 1. The `patterns/` index (folder index 1) and the `jobs/` index (4) belong to Plans 03 and 04. The surface story has exactly one `main` element, which the hygiene check in Plan 03 expects of surface-tier stories. For Plan 05, from Plan 01's hand-off and unchanged by this plan: `catalog_contract_test.exs` still needs the bundle-font check, the landing-page marker holder check, and the first compare-mode probe run (the dump for it is `shopadelic_failed_journey__health.html` from this script's capture mode).

## Self-Check: PASSED

All 14 plan files exist on disk (the 9 created and the 5 modified), the two task commits (`5eec3656`, `f19c4866`) are ancestors of HEAD, `Posture` has one `scan/2` and three `build/3` clauses, `HtmlCanon` is used 18 times in the posture test, the moved-helper grep is 0, the `phase173` count is 27, the journey file has no commit since its baseline, the copied capture script and the `parity-base` worktree are gone, and no root `lib/` file differs from `origin/main`.
