---
phase: 172-consistent-operator-ui-and-verified-recovery
plan: "02"
subsystem: ui
status: complete
requirements-completed: []
requirements-addressed: [OPUX-01, OPUX-02, OPUX-03]
tags: [phoenix, accessibility, forms, dialogs, assets]
requires: [172-01]
provides:
  - Semantic Search fields, schema choices and selected search modes.
  - Shared modal lifecycle and labeled Playbooks file actions.
  - Content-versioned mounted assets with safe legacy revalidation.
affects: [172-03, 172-06, 172-07, 172-08]
tech-stack:
  added: []
key-files:
  created: [scrypath_ops/test/scrypath_ops_web/asset_plug_test.exs]
  modified: [scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex, scrypath_ops/lib/scrypath_ops_web/live/search_live.ex, scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex, scrypath_ops/assets/js/app.js, scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex, scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex]
completed: 2026-10-03
plan_head_before: 7ef35fd
plan_head_after: 1459ee7ac04c050023b8a14b1e29a6dd5d2edb8f
---

# Phase 172 Plan 02 Summary

Search uses named modes and actual disabled controls; Playbooks uses labeled file inputs and shared keyboard-aware dialogs. Mounted CSS and JavaScript URLs now change with their content.

## Changes and commits

- `b14afba` / `f64de1d`: RED/GREEN Search contracts and implementation. Labeled radio/select schema branches, stable input/help IDs, explicit pressed mode, unavailable-runtime fieldsets, empty/partial results.
- `1cc4ea6`: RED modal and mounted-asset contracts.
- `e9f4b5c` / `da2843a`: modal and asset tests/implementation, generated CSS/JS, and browser scenarios for Plan 07. OpsModal handles initial focus, containment, overlay arbitration, Escape, removal and successor focus. Playbooks names file actions and retains rejected rename input.

- `1459ee7`: isolate browser modal fixture using the existing seed helper (execution remains in Plan 07).

## Verification

Executor-reported current-plan results:

- Task 1 focused compile/test command: 15 tests, zero failures (initial RED: 11 tests, 3 intended failures).
- Task 2 RED: 28 tests, 5 behavior failures for asset caching and missing file/dialog semantics.
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/live/playbook_live_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs test/scrypath_ops_web/asset_plug_test.exs`: 39 tests, zero failures.
- `mix assets.build`: succeeded; generated CSS and JavaScript committed.
- `MIX_ENV=test mix precommit`: 165 tests and 2 doctests, zero failures. Existing upstream typing warning in `Scrypath.Sync` remains.
- Environment: Elixir 1.19.5 / OTP 28.5, existing locked dependencies and local test Postgres.

## Deviations

1. Observed mounted asset defect: unversioned URLs had a one-year lifetime, leaving the feedback browser with stale CSS. Added SHA-256 query versions, current-content ETags, immutable caching only for matching versions, and revalidation for legacy/mismatched requests. Request tests cover validators and traversal rejection. Hashing reads current generated files so an asset build after compilation changes the URL.
2. Scoped shell theme assertions to theme buttons; Search now legitimately adds aria-pressed mode buttons.
3. Parent reconciled task commits and finished this summary after interrupting the executor during its final bookkeeping. All implementation commits were already clean and test outcomes reported; no task was replayed.

## Remaining evidence

The new browser focus cases are **written, not yet executed**. Plan 07 must run the complete cycles, Escape/Cancel, removed trigger, overlay conflict, patched input retention, layering and timing cases in a disposable stack. Global OPUX requirements remain open until their full cross-plan evidence is available. No human UAT is substituted for those checks.

## Self-check

The listed task commits and both principal source artifacts exist. Git status was clean before this summary. Continue Plan 03; do not repeat Plans 01–02.
