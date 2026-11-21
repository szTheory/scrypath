---
phase: 190-wording-without-the-catalog
plan: 01
subsystem: ui
tags: [copy, glossary, scrypath-ops, exunit, copy-rules, wording, sentence-case]

requires: []
provides:
  - GLOSSARY.md Status wording section (seven entries)
  - Searchable settings row reads Used for search / Not used for search / Not used for search yet.
  - Last succeeded is the only form in scrypath_ops/lib; Clear is not shown beside a retained observation
  - Control room in sentence case in 54 places across 28 files, with an /ops shell test
  - scrypath_ops/test/support/copy_rules.json (6 rows, 8 surfaces) plus helper, surface registry, stubs and one ops-ui contract test
affects: [190-02, v1.48 copy lint]

actuals:
  tokens: 31700
  tasks: 3
  commits: 4

plan_head_before: 06fc3e726a7d1f7f3aac9f82bfcd17a18a24ab87
plan_head_after: f4b9736615591dfcd19472d45bf9b4916036e4a4

tech-stack:
  added: []
  patterns:
    - "one data table (JSON) + one pure helper + one ExUnit test; planted failures drive the same helper functions the real test calls"
    - "every rendered surface has a state anchor asserted before any row is evaluated"
    - "shared fixture stubs live once in test/support/copy_stubs and are aliased by the LiveView tests and the surface registry"

key-files:
  created:
    - scrypath_ops/test/support/copy_rules.json
    - scrypath_ops/test/support/copy_rules.ex
    - scrypath_ops/test/support/copy_surfaces.ex
    - scrypath_ops/test/support/copy_stubs/sync_drift.ex
    - scrypath_ops/test/support/copy_stubs/control_room.ex
    - scrypath_ops/test/support/copy_stubs/posture.ex
    - scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs
  modified:
    - GLOSSARY.md
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs

key-decisions:
  - "The Searchable settings row keeps its tuple structure: declared Used for search, live-missing Not used for search, effect Not used for search yet. (D-03, pre-seed call stands)"
  - "Stubs and env setup are extracted once into test/support/copy_stubs and aliased (with `as:`) by the existing LiveView tests, so no fixture state is defined twice"
  - "The tracked-file scan skips symlinks, binaries and invalid UTF-8 files as well as NUL files, and raises on an empty list or a missing git instead of passing"
  - "unmatched_scopes/2 checks each glob of a row, not the row as a whole, so one typo in a multi-glob scope cannot hide behind a live glob"

requirements-completed: [COPY-01, COPY-02, COPY-03, GATE-02]

coverage:
  - id: D1
    description: "GLOSSARY.md ends with a Status wording section of seven entries; the table test fails a row whose glossary value is not a bold term"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs#validates against the glossary and the registered surfaces; #a glossary value that is not a glossary term"
        status: pass
    human_judgment: false
  - id: D2
    description: "Searchable fields settings row renders Used for search, Not used for search and Not used for search yet.; Filterable and Sortable rows unchanged"
    requirement: "COPY-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs (settings diff test) and rows searchable-observation-only, searchable-settings-row on surface sync_drift.settings_missing_field"
        status: pass
    human_judgment: false
  - id: D3
    description: "Last succeeded is the only form in scrypath_ops/lib (comments included); no Clear word beside a retained or partial Control room observation, and the healthy fixture still shows its status word"
    requirement: "COPY-01"
    verification:
      - kind: integration
        ref: "control_room_live_test.exs#a retained or partial observation shows no status word; rows last-succeeded, last-succeeded--absence, clear-needs-observation"
        status: pass
    human_judgment: false
  - id: D4
    description: "Control room is sentence case in 54 occurrences across 28 files; /ops shell test proves aria-current, document title and palette item"
    requirement: "COPY-02"
    verification:
      - kind: integration
        ref: "ops_shell_contract_test.exs#/ops; row control-room-casing (whole-tree scan and two rendered surfaces)"
        status: pass
      - kind: other
        ref: "npx --no-install playwright test --list (300 tests in 25 files parse); node --test scripts/ci/ui_preservation.test.cjs (53 pass); node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs (32 pass)"
        status: pass
    human_judgment: false
  - id: D5
    description: "copy_rules.json, helper, surfaces and one ops-ui contract test with planted failures and accept cases"
    requirement: "COPY-03"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs (22 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Plan gate: forced warnings-as-errors compile, whole ScrypathOps suite, workflow_wiring_test, hand-run node tests and the whole CI Node step pass on the committed result"
    requirement: "GATE-02"
    verification:
      - kind: other
        ref: "see Local check results"
        status: pass
    human_judgment: false

duration: 2h
completed: 2026-11-20
status: complete
---

# Phase 190 Plan 01: Glossary, wording, Control room casing and the copy rules table Summary

**Status wording glossary section first, then the Searchable, Last succeeded and Control room strings follow it, each guarded by a row in one JSON table that one `ops-ui` ExUnit test validates, scans and renders, with planted failures run through the same helper code.**

## Performance

- **Duration:** about 2 hours of execution (research reading and deps fetch included)
- **Commits:** 4 task commits (glossary; tracer; rename; Last succeeded and Clear), measured from the plan ledger (`plan_head_before` to `plan_head_after`); the SUMMARY commit follows.
- **Files:** 39 changed in the task commits (1753 insertions, 381 deletions).

## Accomplishments

- **Glossary first.** `## Status wording` with Searchable, Pending, Queued, Retry queued, Accepted, Last succeeded and Clear, in the existing entry format, as its own commit before any string changed. It does not spell the old title-case label.
- **Tracer (Searchable row).** The Searchable fields settings row now reads Used for search, Not used for search and Not used for search yet. The Filterable and Sortable tuples are byte-identical. The pinning LiveView test was updated in place (live cell, effect sentence, and a new assertion that the declared cell reads Used for search). The whole path was proved end to end before the other rows were built: glossary term, lib string, LiveView test, table row, helper, surface, contract test.
- **Table design.** `copy_rules.json` (version, `exempt_paths`, `not_covered`, rows with all eight fields), the pure helper `ScrypathOps.Test.CopyRules` (`load!/0`, `validate/2`, `scan_source/3`, `evaluate_surface/3`, `check_surface/4`, `unmatched_scopes/2`, `tracked_paths/2`, `glossary_terms/1`, `in_scope?/2`), the surface registry `ScrypathOps.Test.CopySurfaces` and the one ops-ui test. `git ls-files -z` runs through `System.cmd` with fixed arguments, never a shell; the scan raises on a missing git, a missing root or an empty list.
- **Control room rename.** Scripted from an explicit 28-file list with per-file counts asserted before any write (54 total, no write on mismatch). Every hunk was machine-checked to be a one-word case change (50 changed lines, 0 mismatches). The nav item `label` and `title`, the `page_title`, the command palette label, the four exact-match Playwright sites and the `admin_shell_chrome` surface name and its lookup key all moved together.
- **`/ops` shell test.** Asserts `aria-current="page"` on the `/ops` link, the document title (read from the connected view with `page_title/1` and from the dead render's `<title>` element), the palette's first item, and that `/ops` carries no `aria-current` on `/ops/health` (with a positive control on the health link).
- **Last succeeded and Clear.** All forms of Last success and Last successful in `scrypath_ops/lib` (comments included) now read Last succeeded. The Control room passes no status word to the verdict when a refresh issue is set (187 review IN-02). Underscored identifiers (`last_successful_posture`, `last_success_refs`, `source_last_success_label`) are untouched.
- **Repaired refutes.** The no-prior control-room test no longer refutes a sentence that was never in lib (`The last successful observation is retained below`); it refutes the real sentence and the new label on that fixture. The posture failed-row test no longer refutes a dash-placeholder form that could not render; it asserts both source labels and refutes the new label followed by a dash with a regex. Old-string refutes are removed from tests; the table owns them.
- **Rows and surfaces.** Six rows (`searchable-observation-only`, `searchable-settings-row`, `control-room-casing`, `last-succeeded`, `last-succeeded--absence`, `clear-needs-observation`) on eight surfaces, each with a state anchor asserted before its rows are evaluated.

## RESEARCH item findings

- **`git ls-files` in the hosted job.** `.github/workflows/ci.yml` `ops-ui` uses the default `actions/checkout` step (no sparse or shallow options that remove `.git`) and `mix verify.ops_ui` runs `mix test` in `scrypath_ops` in place (only the build and deps directories are isolated), so the source tree is the checkout and `git` is present. The helper finds the root with `git rev-parse --show-toplevel` from the table's directory. Local runs are green; the first hosted log is the remaining confirmation (plan 190-02). The `Path.wildcard` fallback was not needed.
- **`<title>` in the dead render.** `live/2` returns the dead render including the root layout: `<title data-default="Scrypath" data-suffix=" · Scrypath">Control room · Scrypath</title>` (with whitespace). The `/ops` test reads both that element (through `LazyHTML`) and `page_title/1` on the connected view.
- **Whole-word Clear.** After the D-06 fix, `\bClear\b` is absent from both the retained and the no-prior Control room surfaces and no other `Clear` token exists on those pages; the healthy fixture still renders its Clear status word (asserted in the new test and in the existing "every row clear" test).
- **Re-count.** `git grep -o 'Control Room' -- . ':!.planning' ':!brand' ':!scrypath_ops/test/support/copy_rules.json'` exits 1 with empty output (54 before, 0 after). `git grep -n -i -P "last success(ful)?\b" -- scrypath_ops/lib` and `git grep -n -P "Searchable(?! fields)|Not searchable|Not searched yet" -- scrypath_ops/lib` are also empty (`-P` is needed; `git grep -E` on macOS does not support `\b`). The queue and pending literals (`Retry accepted`, `Nothing queued`) belong to plan 190-02 and are still in lib.

## Throwaway calibration (old string restored, row seen red, file restored; none committed)

- **Searchable:** restoring the old tuple made `searchable-observation-only` fail the static scan (`sync_drift_live.ex:1734`, three forbidden texts) and the rendered surface `sync_drift.settings_missing_field`, and made `searchable-settings-row` report all three required strings missing.
- **Control room casing:** planting the old label in `operator.spec.ts` made `control-room-casing` fail the whole-tree scan naming `operator.spec.ts:64`. Setting `page_title` to the old casing made the `/ops` shell test fail on the missing `aria-current` (the coupling it exists for).
- **Last succeeded:** restoring one old label each in `control_room_live.ex` and `sync_drift_live.ex` made `last-succeeded` fail the static scan on both files and the rendered surfaces `control_room.refresh_retained` and `sync_drift.reconcile_error_retained` (forbidden text present, and required `last succeeded` missing on the latter).
- **Clear (D-06):** restoring `status={Posture.worst_status(@posture.rows)}` made the new control-room test fail on the retained fixture.

## Deviations from Plan

### Auto-fixed or judgement calls

**1. [Rule 3 - Blocking] `control_room.ex` stub created in Task 2, extended in Task 3**
- **Found during:** Task 2 (the `control_room.default` surface needs the Control room environment).
- **Fix:** Task 2 created `test/support/copy_stubs/control_room.ex` with `put_env/0`, `restore_env/1` and `with_env/1` and made the Control room test's setup use it; Task 3 added `Client` and `put_healthy_posture!/0` and removed the inline copies. The plan lists the file only under Task 3.
- **Commits:** 109b334e (created), f4b97366 (extended).

**2. [Rule 1 - Bug avoided] `unmatched_scopes/2` is per glob**
- The plan describes it per row; a multi-glob row with one dead glob would have hidden the typo. It returns `%{row, globs}` for each row that has a dead glob. The planted test pins the single-glob case.

**3. [Rule 2 - hardening] Scan skips symlinks, binaries and invalid UTF-8**
- Beyond the NUL check the plan names: `Regex` with the `u` flag raises on invalid UTF-8, and a symlink would be read twice. `read_text/2` returns `:skip` for them.

**4. Calibration slip (no effect on the commits)**
- While calibrating Task 1 I reverted with `git checkout -- <file>`, which discarded my still-uncommitted lib edit as well as the throwaway change. I restored it from a backup copy taken before the calibration and re-verified the diff. Later calibrations used backup copies and a `cp` restore.

**5. `git commit --amend --only` on the glossary commit**
- Only the subject line was reworded to `docs(190): ...` (the orchestrator's commit-type scope). Content unchanged; nothing had been pushed.

### Plan statements that did not hold exactly

- The plan's `<automated>` commands name `/Users/jon/projects/scrypath/...` (the primary checkout). They were run from this worktree's own paths instead.
- Plan 190-01 Task 2 "the title assertion through `page_title/1` or a plain `get/2` dead render; say which": both were used (see RESEARCH item findings).

## D-14 fallbacks used

None. All eight surfaces were built from existing fixtures, including `sync_drift.reconcile_error_retained` through the render-with-assigns pattern from a mounted view. `not_covered` lists the five generic gaps only (JavaScript strings, attribute-only text, Playwright locators, states with no named surface, non-English text).

## Local check results

All on the committed result (HEAD `f4b97366`), from this worktree, with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` and the local Postgres up on 5432:

| Check | Command | Result |
|-------|---------|--------|
| Tracer tests | `cd scrypath_ops && MIX_ENV=test mix test test/scrypath_ops_web/copy_rules_contract_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs` | 61 tests, 0 failures |
| Task 2 files | `MIX_ENV=test mix test` on the contract, shell, control room, sync drift, router and reskin component tests | 162 tests, 0 failures |
| Format | `mix format --check-formatted` in `scrypath_ops` and at the root | clean |
| Forced compile | `cd scrypath_ops && MIX_ENV=test mix compile --warnings-as-errors --force` | exit 0, no warnings |
| Whole ScrypathOps suite | `cd scrypath_ops && MIX_ENV=test mix test` | 2 doctests, 538 tests, 0 failures (514 before this plan) |
| Wiring test | `mix test test/mix/tasks/workflow_wiring_test.exs` (root) | 88 tests, 0 failures |
| Brand pin guard (extra, cheap) | `mix test test/mix/tasks/brand_pin_contract_test.exs` | 96 tests, 0 failures |
| Hand-run node tests | `node --test scripts/ci/ui_preservation.test.cjs`; `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` | 53 pass; 32 pass |
| Spec parse | `cd examples/scrypath_ecommerce && npx --no-install playwright test --list` | 300 tests in 25 files, no parse error |
| CI Node step | `node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs scripts/ci/ui_state_pairs.test.cjs` | 162 tests, 0 failures, exit 0 (584 s) |

Cleanup: no Docker container, image or network was started by this plan (the lifecycle cases run in temporary directories they remove); three older `scrypath-e2e-lifecycle-*` temp directories dated 2026-11-18 predate this run and were left alone.

Not run here by design: `mix verify.repository_contracts`, `mix verify.core` (once on the final head in plan 190-02), any Playwright browser lane (browsers are not installed; the mounted and e2e lanes run in hosted CI), the demo `page_controller_test.exs` (plan 190-02, D-25), any preview capture or `ui:review`.

## What this does not prove

That the new wording reads well or suits the brand voice (no design pass, rendered review, screenshot comparison, aesthetic approval or independent review is claimed); coverage of JavaScript strings, attribute-only text, states with no named fixture surface or non-English text (listed in `not_covered`); that the advisory Playwright specs pass (only the exact-head dispatch in plan 190-02 speaks to that); that the hosted `ops-ui` job finds `git` and a checkout the way the local run does (read from the workflow, not yet observed in a hosted log); or that a re-introduced old label in a path the `ops-ui` regex does not match is caught before the merge (plan 190-02 extends the regex; the whole-tree scan still runs on every push to `main`).

## Known Stubs

None. No placeholder or hard-coded empty value flows to rendering; the `copy_stubs` modules are test-only fixtures that the existing LiveView tests already used.

## Threat Flags

None. No new network endpoint, auth path or schema change. The `git ls-files` call uses a fixed argument list (T-190-02) and the table holds no code.

## Self-Check

PASSED. Created files (GLOSSARY.md section, `copy_rules.json`, `copy_rules.ex`, `copy_surfaces.ex`, the three `copy_stubs` files, the contract test, the `/ops` shell test) exist, and the four task commits (`a7d8b447`, `e20a23e6`, `109b334e`, `f4b97366`) are ancestors of HEAD.
