---
phase: 173-shared-visual-foundation-and-operational-time
plan: 02
subsystem: ops-ui
tags: [elixir, ecto, liveview, meilisearch, oban, playwright, timestamps]
requires: [173-01]
provides:
  - Validated source ISO timestamp provenance alongside normalized DateTime values.
  - Snapshot-relative operational ages with source-local references retained after failed refresh.
  - Accessible exact timestamp and UTC disclosure in mounted and standalone Search health.
  - Deterministic time fixtures and responsive browser proof for both production entrypoints.
affects: [173-03, 173-04]
actuals:
  tokens: not-recorded-after-context-restart
  tasks: 3
  commits: 1
tech-stack:
  added: []
  patterns:
    - Preserve validated ISO source text next to parsed instants; use DateTime.compare for instant equality.
    - Carry backend and queue observation references independently and retain them on failed schema reads.
    - Use native details/summary for selectable exact evidence, with snapshot-based age labels.
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/phase173_time.spec.ts
    - .planning/phases/173-shared-visual-foundation-and-operational-time/173-02-SUMMARY.md
  modified:
    - lib/scrypath/operator/state.ex
    - lib/scrypath/operator/status.ex
    - scrypath_ops/lib/scrypath_ops/posture.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - examples/scrypath_ecommerce/docker-playwright.sh
requirements-completed: [OPUX-14]
coverage:
  - id: D15-D18
    description: Lossless timestamp source provenance, snapshot-relative age thresholds, future handling, and distinct absent/unavailable states.
    requirement: OPUX-14
    verification:
      - kind: unit
        ref: test/scrypath/operator/status_test.exs (6 tests)
        status: pass
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs (11 tests)
        status: pass
      - kind: e2e
        ref: bash examples/scrypath_ecommerce/scripts/verify-phase173.sh time at 012649917e6dd0cf82dbb7d0154ccd37ac45bc43 (8 tests)
        status: pass
  - id: D19
    description: Native exact timestamp disclosure keeps selectable source ISO precision and explains its UTC equivalent.
    requirement: OPUX-14
    verification:
      - kind: e2e
        ref: mounted and standalone time disclosure at 390/1279/1280/1440px, pointer/keyboard/touch
        status: pass
    human_judgment: false
status: complete
completed: 2026-10-10
---

# Phase 173 Plan 02 Summary

**Search health now shows last-success age relative to the successful observation and exposes the exact timestamp source and UTC equivalent in both entrypoints.**

## Accomplishments

- State normalization keeps a valid Meilisearch `finishedAt` or Oban `completed_at` ISO string with its parsed instant, preserving offset and fractional precision without changing the public State struct.
- Posture stores backend and queue source references against their own successful snapshot. A later fetch error retains the old reference and labels it as retained instead of changing its observation time.
- OpsUi derives just-now/minute/hour/day/absolute-UTC labels from the fixed observation snapshot, handles future values before flooring, and distinguishes no completion, completion without valid time, unavailable observation, and unused queue.
- A native `Exact timestamp` disclosure provides selectable source ISO and a human-readable UTC equivalent. No dependency was added.
- Paired mounted and standalone fixtures exercise production PostureLive, Posture, Status, State, OpsUi, and the built Ops CSS. The disposable runner now routes its `time` scope to the new spec.

## Task Commit

- **T1–T3: Preserve and render snapshot-stable operational time** — `012649917e6dd0cf82dbb7d0154ccd37ac45bc43`.

## Verification

- Root focused status normalization tests — 6 tests, 0 failures.
- Ops focused PostureLive tests — 11 tests, 0 failures.
- `bash examples/scrypath_ecommerce/scripts/verify-phase173.sh time` at exact source SHA `012649917e6dd0cf82dbb7d0154ccd37ac45bc43` — 8 browser tests passed across mounted and standalone routes. Coverage includes pointer, keyboard and touch disclosure; responsive geometry at 390, 1279, 1280 and 1440px; source offset/fractional precision; refresh stability; and no-success, invalid-time, unavailable and queue-unused states. The unique Compose project and its containers, volume and network were removed.
- `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix verify.core --exclude integration --exclude docs_contract` at that same source SHA — passed formatting, workspace cleanliness, warnings-as-errors compile, Credo (2361 checks; no issues), 660 tests, 4 properties and docs generation.
- `make -C examples/scrypath_ecommerce contrast` — pass, 0 AA failures and 41 AAA advisory findings. Added the exact-evidence labels and retained-note selectors to the existing muted-token manifest; no new tool or package.
- `mix format --check-formatted` on the changed root, Ops and ecommerce fixture sources; `git diff --check` — pass.

## Visual Evidence

- Before captures: actual base application from clean commit `b96f4da`, in `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_shell_5befd00e_89591/screenshots/` (`before-light-1440.png`, `before-dark-390.png`, plus other Plan 01 base views).
- After captures at the exact Plan 02 source SHA: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase173/scrypath_phase173_time_01264991_18687/screenshots/`, with mounted and standalone light/dark views at 390, 1279, 1280 and 1440px.
- Inspected mounted light mobile and standalone dark desktop. The evidence disclosure wraps on mobile, remains selectable, keeps its labels and UTC equivalent readable, and introduces no page overflow. The baseline has different source data and does not permit a data-identical before/after comparison. The retained preview at `:4012` was not used.

## Deviations

- The contrast checker’s D-15 lockstep guard surfaced two new uses of `--ops-text-muted`; both were added to `contrast-pairs.mjs`, after which the required contrast gate passed.
- The first browser iterations corrected fixture assumptions: the queue timestamp preserves the source `-04:00` offset; the queue-unavailable fixture uses a valid backend result; and each absent-evidence case reloads a clean route so prior successful references cannot correctly reappear as retained data.
- Root and Ops Mix checks emitted the pre-existing Dialyzer warning for `Scrypath.Sync.sync_related/3`; it did not fail the required compile or Credo gates.

## Next Plan

Plan 03 applies neutral status/metric surfaces and consistent quiet-action behavior, with local state cues and source-backed browser proof.
