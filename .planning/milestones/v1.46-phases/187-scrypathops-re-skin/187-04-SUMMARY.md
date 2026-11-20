---
phase: 187-scrypathops-re-skin
plan: 04
subsystem: ui
tags: [status-vocabulary, ops-sync-status, notices, ranking, verdicts, copy-fixes, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 01 all-statuses fixture and exact token ceilings; plan 02 type floor and mono identities; plan 03 palette, status tokens (`--ops-status-*`, `--ops-control-edge`) and the contrast proof
provides:
  - ops_sync_status, the one component that renders Failed, Retrying, Pending and Clear (word first, then a 16px decorative bar icon with four distinct shapes)
  - ops_condition, plain muted words for Not observed, Not checked, Queue not used and Unavailable
  - ScrypathOps.Posture row_status, ranking (failed, retrying, pending, unverified, clear, then name), worst_status and verdict_kind (LD-8, LD-10), shared by Control Room and Search health
  - Search health rows, source groups, a dense facts line, both verdicts and the Sync and index activity list on the new vocabulary
  - notices, statuses, verdicts and tone chips on one Panel with a 2px inline-start rule (no tint, no shadow, no cue dot)
  - the retry flash without a raw term, the promotion flash with one "blocked", and the Search run state "Search failed"
  - reskin_component_contract_test.exs (E-01, E-03, E-17), required gate 8 of 12
affects: [187-05, 187-06, 187-07, 187-08, 187-09, 187-10, 187-11]

actuals:
  tokens: 18300
  tasks: 3
  commits: 5

plan_head_before: 3cce86736c639cb2bfefa41680e707c066bbaa38
plan_head_after: ff8cd3b659047bbf63c6d10177ea3f59655b7a8e

tech-stack:
  added: []
  patterns:
    - "pure row and verdict logic lives in ScrypathOps.Posture, so the two screens that show a verdict cannot disagree"
    - "rows rank once when loaded or refreshed, never in render"
    - "one mapping function (notice_modifier/1) decides the rule for notices, statuses, verdicts and tone chips"
    - "no Tailwind `border` utility on a notice-like surface: the utilities layer would beat the 2px inline-start width"

key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
  modified:
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - DESIGN.md
    - CONTRIBUTING.md
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts
    - examples/scrypath_ecommerce/e2e/settings_layout.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts

key-decisions:
  - "The shared row and verdict logic is public in ScrypathOps.Posture instead of private copies in two LiveViews, so Control Room and Search health cannot drift apart"
  - "A notice's kind decides its rule; the old `neutral` attr on ops_status is accepted but no longer changes the surface, so an error stays Failed"
  - "Search health sorts when rows are loaded, not when they render"
  - "The Failed sync work verdict keeps its old kind and shows no status word (the plan scopes verdict status to Control Room and Search health)"

requirements-completed: []

coverage:
  - id: D1
    description: "one status component with four shapes, a closed condition set, Clear only with an observation"
    requirement: "STAT-01, STAT-02"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs (E-01, E-03) and posture_live_test.exs (E-02 to E-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "ranking and verdicts follow LD-8 and LD-10; rows re-sort only on refresh"
    requirement: "SKIN-07, STAT-03"
    verification:
      - kind: integration
        ref: "posture_live_test.exs (E-05, E-06) and control_room_live_test.exs (E-06)"
        status: pass
    human_judgment: false
  - id: D3
    description: "notices, statuses and verdicts are the 2px-rule surface; both copy fixes and Search failed"
    requirement: "STAT-03, SKIN-07"
    verification:
      - kind: integration
        ref: "reskin_component_contract_test.exs (E-17); failed_sync_live, sync_drift_live and search_live tests (E-11)"
        status: pass
    human_judgment: false
  - id: D4
    description: "the all-statuses capture fixture renders all four words, their shapes and a condition word, and its name equals the scenario the capture command is given"
    requirement: "SKIN-08"
    verification:
      - kind: integration
        ref: "posture_live_test.exs (E-19)"
        status: pass
    human_judgment: false

duration: 48m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 04: Status vocabulary, ranking and notices Summary

**Every sync state in ScrypathOps now reads as one of four words (Failed, Retrying, Pending, Clear) with its own bar shape, anything nobody observed is a plain muted word that can never read as Clear, Search health ranks by urgency, and notices and verdicts are a Panel with a 2px rule instead of tinted boxes.**

GATE-02: this is a rendered-UI plan. Status words, shapes, ranking, verdict wording of state and notice surfaces changed on Control Room, Search health, Failed sync work and Sync and index. The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched and no Docker resource was created.

`requirements-completed` is empty on purpose: STAT-01 to STAT-03 and SKIN-07 are proved at the HTML level here (component, LiveView and stylesheet tests), but the computed-color and shape checks in a real browser (P-03, P-15) belong to Plan 10, and SKIN-08's after-captures come later. The orchestrator decides when to mark them.

## What was built

- **Task 1, the status component (tracer, `62e5c90b`).** `ops_sync_status/1` renders the word first and then an inline 16px `aria-hidden` svg (`focusable="false"`, no role, no name) whose `data-shape` is `filled` (Clear), `hollow` (Pending), `bottom-filled` (Retrying) or `notched` (Failed). The four paths are the LD-7 paths, built from three named pieces so the file never repeats them. Word and icon take `var(--ops-status-<status>)` through `currentColor`; there is no transition. The `status` attr is a closed list, and the shape table is private, so input never picks markup. Failed sync work rows use it (Failed or Retrying from `row.state`; `data-state` and test ids stay). The component contract file is created here (E-01) and its row is in CONTRIBUTING (`Budget used: 8 of 12.`).
- **Task 2, ranking, conditions and verdicts (`dfeb0f50`).**
  - `ScrypathOps.Posture` gained `row_status/1`, `queue_unused?/1`, `sort_by_urgency/1`, `row_rank/1`, `worst_status/1` and `verdict_kind/1`. A row is Failed, Retrying, Pending, a condition (`Not checked` for a row that could not be read, `Not observed` for a queue that sync mode says should have been observed) or Clear. Clear needs an observation: observed-empty, or a queue the sync mode does not use. A zero count from an unobserved source never earns it.
  - Search health rows rank Failed, Retrying, Pending, unverified, Clear, then module name, once, when rows are loaded or refreshed. Each row header shows one status word or one condition word. Source groups put `ops_sync_status` in every `dt` (count stays in `dd`, empty statuses are not rendered, the `data-tone` wrappers stay) and show `Clear` beside the existing empty sentence only for an observed source. A dense facts line prints each source's counts and last success (`Queue 2 pending, 1 retrying, last succeeded <time> · Meilisearch 0 pending, ...`), zero statuses left out unless all are zero, an unobserved source printing its condition word.
  - Both verdicts (Control Room, Search health) show the worst row status and take their kind from LD-10 (any Failed row is an error; Retrying or unverified is a warning; otherwise neutral; Clear only if every row is clear). The verdict icon and its helpers are deleted. The Sync and index activity list shows Failed and Pending through the component and uses a text arrow.
  - E-19: the all-statuses scenario test now asserts exactly the four status values with their words and shapes and at least one condition word, and reads `reskin-capture.mjs` to prove its `SCENARIO` equals `all-statuses`.
  - `phase173_status_actions.spec.ts` follows the new markup (see "Advisory spec pins" below); it lists under Playwright with the mandatory `ui_followup.spec.ts` (13 tests, no errors).
- **Task 3, notices and copy (`5eecb82b`).** `ops_notice`, `ops_status`, `ops_verdict` and `ops_tone_chip` share `.ops-notice-surface`: Panel fill, 1px Hairline on three sides, a 2px inline-start rule, no shadow. Failed rule and title for errors, Retrying amber for warnings and partial, Control Edge with an Ink title for info, success, running and neutral. The tinted `.ops-tone-*` and `.ops-badge-*` classes, the cue dot and the verdict and metric icons are gone. `ops_badge` is plain muted text (the Search run state is its only user). The Retry queued receipt is the neutral kind. The retry flash now reads `Retry did not go through for {Schema}. The failed work is unchanged and still listed. Check that the queue and Meilisearch are reachable, then retry.` and the reason goes to `Logger.warning`; the promotion flash is `Index promotion blocked: {reason}.` (or the generic sentence) with "blocked" once; a failed search run reads `Search failed`.
- **Follow-ups (`57fd1235`, `ff8cd3b6`).** The advisory depth spec's hero-shadow expectation now matches the no-shadow rule; `DESIGN.md` describes the status words and the rule scheme.

## Gate results (GATE_SHA `ff8cd3b659047bbf63c6d10177ea3f59655b7a8e`, the last commit touching non-`.planning` files)

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0, thinnest pair 4.58 (Retrying on Selected Page); no stale manifest entry |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 48 pass, 0 fail (no ceiling or ledger change expected; none needed) |
| root `mix test` on `workflow_wiring`, `ui_contrast`, `ui_tokens`, `ui_tokens_helper`, `ui_literal` contract tests, `--exclude contrast_child` | 102 tests, 0 failures (the ledger parser reads 8 of 12; the literal ratchet ledger equals the source scan) |
| `scrypath_ops` `mix test` (whole suite, task-scoped database `scrypath_ops_test_187_04`) | 2 doctests, 412 tests, 0 failures |
| `mix verify.ops_ui` (boundary test, then the ops suite) | boundary 2 tests; 2 doctests, 412 tests, 0 failures |
| `mix verify.repository_contracts` (escalated route per AGENTS.md) | 157 tests, 0 failures, 252.7 s |
| `mix verify.core --exclude integration --exclude docs_contract` | format, clean workspace, warnings-as-errors compile, credo, 5 properties and 1158 tests with 0 failures (103 excluded), docs with warnings as errors, Standard Maturity Gate PASSED, no-optional-deps compile clean |
| `npx playwright test e2e/phase173_status_actions.spec.ts e2e/ui_followup.spec.ts --list` | 13 tests in 2 files, no `Error:` (also listed: `admin_surface_depth` and `settings_layout`, 46 tests) |
| `git diff --name-only GATE_SHA..HEAD` after the SUMMARY commit | only `.planning/` paths |

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off, `<verify>` automated only. The Task 1 verify command (component contract, failed sync and token tests) passed on the tree that became the Task 1 commit; Tracer verified end-to-end, expanding.

Mutation checks I ran on the committed tree (each restored with `git checkout --` afterwards; the tree was clean at the end): removing the `data-tone` wrappers fails the E-02 wrapper test; sorting in render instead of at load fails the E-05 refresh test; letting an unobserved queue read Clear fails three E-04 and E-05 tests.

The task-scoped database `scrypath_ops_test_187_04` was dropped afterwards (verified absent).

## Numbers and calibration

All plan numbers held: `posture_row_rank` 4 to 0, `defp verdict_icon` 12 to 0 and the spec's `ops-verdict-icon` 2 to 0 (as the acceptance lines expected), `Budget used` 7 to 8. `MUTED_PAIRS` went from 11 direct entries to 9: `.ops-badge-neutral` and `.ops-tone-chip__value` left with the `color: color-mix(...)` declarations they tracked, in the same commit as the stylesheet rewrite. Token ceilings did not move (this plan adds no allowlist entry or hit). `@min_token_test_calls` stays 42 (no token-test case added or removed). The ops suite grew from 350 to 412 tests.

## Advisory spec pins rewritten

- `phase173_status_actions.spec.ts` (every test name kept): the verdict-icon pins became `[data-sync-status]` word and shape checks plus a `data-verdict-kind` check; the `.ops-badge-*` pins became `.ops-badge` count 0 and `[data-sync-status]` checks on the row header and failing groups; the "surface stays the same across states" fingerprint now compares the fill and the three plain borders (the 2px rule is the state carrier, so it is asserted to differ separately); the unreadable row asserts `Not checked` and no status word.
- `settings_layout.spec.ts`: its status locator used `.ops-notice-surface--neutral`, which now means only neutral kinds, so it selects `.ops-notice-surface[data-status-kind]` (the title-and-body alignment it checks applies to every kind).
- `admin_surface_depth.spec.ts`: the hero verdict is expected to compute `box-shadow: none` (UI-SPEC P-15). Plan 09 still owns that file's old color constants.
- Mandatory `ui_followup.spec.ts` cases were not edited: the markup keeps `[data-tone=error]` containing `Failed`, `[data-tone=retrying]` containing `Retrying`, and one svg in every `.ops-signal-counts dt` (asserted by the E-02 LiveView tests).

## Deviations from Plan

**1. [Judgement] The shared row and verdict logic is public in `ScrypathOps.Posture`, not private in two LiveViews.** The plan lists `row_status/1`, the rank constant and `verdict_kind/1` as private functions in `posture_live.ex` and `control_room_live.ex`. Two private copies of ranking and verdict logic would have to stay in lockstep by hand, and E-06 requires both verdicts to agree. `Posture` already says it exists so the two screens never diverge. Nothing later depends on the private names.

**2. [Judgement] `ops_condition/1` is a component.** The plan names only the `.ops-condition` class. A component with a closed `values:` list on its `word` attr enforces the condition set at compile time, gives E-03 something to test directly, and has its catalog row. It has no new behavior beyond the plan.

**3. [Judgement] The `neutral` attr on `ops_status` no longer changes the surface.** The plan's mapping line reads as if `neutral` forces the neutral rule. Nine call sites pass `neutral`, three of them with a literal `kind={:error}` and several with a computed kind that can be `:error`, and the same plan (and UI-SPEC) says error kinds use the Failed rule and title, so honoring `neutral` literally would have shown an error with a Control Edge rule. The kind decides the rule; `neutral` stays accepted so no call site changes.

**4. [Judgement] Three small hooks that make behavior observable.** `data-verdict-kind` on `ops_verdict` (E-06 has to read LD-10's kind), `data-badge-kind` on `ops_badge`, `data-condition` on `ops_condition`. `ops_status` also accepts `kind={:neutral}` now (the receipt "becomes the neutral kind"). `ops_intent_card` lost its `kind` attr: it had no callers and was the last user of the tinted tone class.

**5. [Rule 3 - Blocking] The promotion notice body had to change too.** The acceptance count for `Promotion is blocked` in `sync_drift_live.ex` is 0 and the plan says to remove the inner sentence at both sites. The second site (`promotion_eligibility_copy/1`) renders as the body of the "Promotion unavailable" notice, so it now reads the reason alone as a sentence (for example `Wait for backend tasks to finish.`). No test or spec pinned the old body; it is not in the UI-SPEC copy-diff allowlist, so Plan 10's preservation check should expect this one extra string on Sync and index when a prepared index exists.

**6. [Rule 1 - Bug] Dead CSS removed.** `.ops-sync-work li > svg` and `.ops-sync-work [data-tone="error"] > svg` matched the old icons only; the status svg is now inside `.ops-sync-status`, so both were dead.

**7. The Failed sync work verdict is unchanged except for losing its icon.** Plan 04 scopes verdict status to Control Room and Search health, so Failed sync work shows its headline (`2 failed, 1 retrying`) and an amber warning rule when rows exist, with no status word. Plan 05 or 06 can decide whether it should follow LD-10; the data to do it is the same `row.state` the rows use.

**8. Where the row's condition word sits.** An unreadable Search health row shows `Not checked` in the row header (the same slot as every other row's status or condition), with the unchanged sentence in Ink below it, no icon and no error color. The plan said "beside it"; the header is the one place every row says its state.

**9. An unobserved queue group says `Not observed` before its existing sentence.** For a queue-using sync mode whose queue was not observed, the group shows the condition word before `Queue observations unavailable; ...`. For `inline` and `manual` the existing sentence already starts with `Queue not used`, so no extra word is added there.

## Decisions and what later plans must know

- `Posture.badge_kind/1` is now unused in `lib/`; it stays (the plan said to leave it).
- A Tailwind `border` utility on any notice-like element would beat the 2px inline-start width, because the utilities layer wins over the components layer. `ops_verdict` lost its `border` class for that reason; keep it off.
- `.ops-tone-chip` and `.ops-notice-surface` are used together (the chip adds only its own layout); the kind modifier supplies the rule color. Nothing renders `ops_tone_chip` or `ops_metric` today.
- Required-gate budget: `Budget used: 8 of 12.` Plan 05 adds E-07 to E-09 and Plan 06 adds E-16 inside the same file, so the count stays 8.
- The facts line prints the success time through `ops_time` (so it carries a copy button); a row now has a time in the facts line and one in each source group. If that reads as noise in review, the facts line can switch to plain `<time>` without touching the tests that count `time` elements (they count two in the facts line).
- `text-base-content/NN` classes remain in `posture_live.ex` (the Plan 08 sweep owns them); this plan added none.
- Gap for Plan 10: the glyph coverage test renders the all-statuses fixture, which now includes the facts line separator `·` (an allowlisted fallback glyph) and the text `→` (in the Hanken subset).

## Known Stubs

None.

## Threat Flags

None new. T-187-11 (raw reason in the retry flash): the page gets a fixed sentence with the module name only, the reason goes to `Logger.warning`, and the E-11 test uses a stub error holding a map and atoms and asserts none of `%{`, `:timeout`, `{:error` or `meta` appears. T-187-12 (status input choosing markup): the attr's value list is closed and asserted through the component declaration, and shapes and words come from a private table. T-187-13 (health shown as Clear without an observation): `row_status/1` returns Clear only for observed-empty or queue-not-used rows, with fixtures for observed-empty, a row that could not be read, an unobserved Oban queue, inline, manual and a zero from an unobserved source, plus a mutation check that fails three tests. No package was added.

## Blocked gates

None. Every gate ran and passed. No Docker resource was created, so there is nothing to clean up or measure with `docker system df`.

## Self-Check: PASSED

- Files exist: this SUMMARY and the 23 files listed above (22 modified, plus `reskin_component_contract_test.exs`, which this plan created).
- Commits are ancestors of HEAD: `62e5c90b`, `dfeb0f50`, `5eecb82b`, `57fd1235`, `ff8cd3b6`.
- `git diff --name-only 3cce8673..HEAD` touches no `STATE.md` or `ROADMAP.md`, and neither `.planning/config.json` nor `.planning/state.json` was created or staged.
