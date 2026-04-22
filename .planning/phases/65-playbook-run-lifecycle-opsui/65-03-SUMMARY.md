---
phase: 65-playbook-run-lifecycle-opsui
plan: "03"
subsystem: ui
tags: [elixir, phoenix_live_view, telemetry, docs, scrypath_ops, playbooks]
requires:
  - phase: 65-playbook-run-lifecycle-opsui
    provides: async run lifecycle plus failure enrichment/doc resolver primitives
provides:
  - assign-backed playbook run failure panels with registry-driven docs and copy-safe diagnostics
  - playbook run start/stop telemetry with explicit ok/error/cancelled/timeout outcomes
  - troubleshooting anchors that keep OPSUI failure links within two hops
affects: [phase-65-plan-04, opsui-run-failures, docs-contract-playbook-runs]
tech-stack:
  added: []
  patterns: [allowlisted diagnostics copy payloads, resolver-backed docs in LiveView failure UI]
key-files:
  created: []
  modified:
    - scrypath_ops/assets/js/app.js
    - scrypath_ops/docs/playbook-schema-v1.md
    - scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
key-decisions:
  - "Kept failure diagnostics limited to the allowlisted enriched map and copied it via a LiveView push_event plus browser clipboard handler."
  - "Used DocResolver for both static schema links and run-failure panels so OPSUI stops hardcoding special-case guide URLs."
  - "Emitted stop telemetry from every terminal run path, including superseded and timeout flows, while leaving timeout UI copy on the existing :timed_out reason."
patterns-established:
  - "PlaybookLive stores enriched failure state in run_failure_enriched and renders terminal error UI only when run_ui.phase == :error."
  - "Playbook run telemetry uses [:scrypath_ops, :playbook_run, :start|:stop] with %{system_time|duration} measurements and %{run_id, result} metadata."
requirements-completed: [OPS3-02]
duration: 4min
completed: 2026-04-22
---

# Phase 65 Plan 03: Structured failure UI, docs, telemetry Summary

**Playbook runs now surface doc-backed failure panels, copy-safe diagnostics, and explicit lifecycle telemetry instead of relying on flash-only error copy**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-22T18:56:40Z
- **Completed:** 2026-04-22T19:00:54Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments
- Replaced the preview run error paragraph with an assign-backed DaisyUI alert that renders failure class, message, primary/related docs, and a copy diagnostics button.
- Added `copy_run_diagnostics` plus a browser clipboard listener so OPSUI copies only the allowlisted enriched JSON payload.
- Added troubleshooting anchors to `playbook-schema-v1.md` and emitted `playbook_run` start/stop telemetry from success, error, cancel, supersede, and timeout paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: Structured failure UI, docs, telemetry** - `d420232` (feat)

**Plan metadata:** captured in the summary docs commit for this artifact

## Files Created/Modified
- `scrypath_ops/assets/js/app.js` - Copies server-pushed diagnostics JSON to the clipboard when the browser allows it.
- `scrypath_ops/docs/playbook-schema-v1.md` - Adds troubleshooting anchors for `no_schema`, `invalid_query`, and `page_size_out_of_range`.
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` - Exposes `doc_ref/1` so LiveView can explicitly resolve doc URLs from the registry.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` - Stores `run_failure_enriched`, renders persistent success/error alerts, emits telemetry, and handles diagnostics copying.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` - Covers the enriched failure panel, copy action feedback, and telemetry emission.

## Decisions Made
- Kept the diagnostics payload to `failure_class`, `reason`, `message`, `copy`, and `doc` so clipboard output stays stable and threat-model compliant.
- Reused the existing `:timed_out` UI reason while translating telemetry stop metadata to `:timeout`, matching the plan contract without widening runner errors.
- Resolved doc URLs in the LiveView even after `RunFailure.enrich/2` so the render path remains explicit about registry-to-URL conversion.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PlaybookLive now exposes stable failure DOM and telemetry hooks for Plan 04 assertions.
- The troubleshooting doc anchors and resolver-backed URLs are in place for follow-on docs contract coverage.

## Self-Check: PASSED

