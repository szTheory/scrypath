---
phase: 174-recovery-entry-and-diagnosis
plan: 03
subsystem: ui
tags: [phoenix-liveview, search-health, accessibility, playwright]

# Dependency graph
requires:
  - phase: 174-recovery-entry-and-diagnosis
    provides: "Shared recovery entry and exact-schema selection rules from Plans 01 and 02"
provides:
  - "Search health schema records without redundant collection/check panels"
  - "A same-schema failed-work handoff only when failed tasks are observed"
  - "Responsive mounted and standalone status coverage at 320px through desktop widths"
affects: [174-recovery-entry-and-diagnosis, operator-ui, search-health]

# Actuals (#2632). Orchestrator must update commit measurements after its task commits.
actuals:
  tokens: 6683
  tasks: 2
  commits: 2
plan_head_before: 8dd5a1b33443023a3fb7f0c140a98e50f44ecdf7
plan_head_after: e15e2778aa63924933872d6d4ff1ea07e16c9c6c

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A schema article is the meaningful surface for its identity, health evidence, and contextual action."
    - "Show a schema-specific failed-work destination only when the current observation includes failed tasks."

key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts

key-decisions:
  - "Keep aggregate and per-source observation semantics in Posture; this plan changes presentation only."
  - "Retain exact-schema failed-work navigation next to the schema record only when failed backend or queue tasks were observed."

patterns-established:
  - "Per-schema health surfaces use one labelled article with plain backend and queue groups."
  - "Narrow-layout browser assertions cover both mounted and standalone entrypoints in light and dark themes."

requirements-completed: [OPUX-17]
coverage:
  - id: D1
    description: "Search health renders a compact one-level collection of full-identity, worst-first schema records with timestamp provenance."
    requirement: OPUX-17
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "A schema record links to its own failed sync work only when failed tasks were observed; hostile fetch reasons remain escaped text."
    requirement: OPUX-17
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mounted and standalone Search health retains long values, keyboard focus, and theme state without page overflow at mobile and rail widths."
    requirement: OPUX-17
    verification:
      - kind: automated_ui
        ref: "bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status"
        status: pass
      - kind: automated_ui
        ref: "make -C examples/scrypath_ecommerce contrast"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-10-10
status: complete
---

# Phase 174 Plan 03: Search Health Summary

Search health now presents one readable record per schema and keeps a failed-work handoff with the exact schema whose backend or queue task failed.

## Performance

- **Duration:** approximately 8 minutes
- **Started:** 2026-10-10T22:44:00-04:00 (approximate)
- **Completed:** 2026-10-10T22:52:00-04:00
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Removed the separate fleet-level Next checks panel, outer fleet panel, and generic handoff; schema records now form the single collection surface.
- Kept the established summary, ordering, source/snapshot timestamps, full schema/index identity, backend and queue groups, and explicit queue uncertainty unchanged.
- Added an adjacent exact-schema failed-work link only when the current status includes failed backend or queue tasks. Fetch errors and clean rows do not imply known failed work.
- Expanded the existing mounted/standalone browser lane to 320px, 390px, and rail boundaries in light and dark themes, including link focus and page-overflow assertions.

## Task Commits

1. **Task 1: Present worst-first schema evidence in one clear record** — `bf12794` (feat)
2. **Task 2: Verify Search health states and narrow layouts in both themes** — `e15e277` (test)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — one-level schema collection, accessible article naming, conditional exact-schema handoff.
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` — failed-task handoff, no-work absence, rank/tie ordering, article semantics, and hostile-reason escaping assertions.
- `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts` — narrow-width, theme, long-value, contextual link, and keyboard-focus browser assertions.

## Decisions Made

- Keep `ScrypathOps.Posture` ranking and classification logic untouched; this plan changes the rendered hierarchy only.
- A fetch error is not evidence that failed sync tasks exist, so the schema's failed-work link is omitted until such tasks are observed.

## Deviations from Plan

None. The additional test setup drives the existing backend fake into an observed failed-task state so the exact-schema link condition is verified without adding dependencies or fixtures.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/posture_live_test.exs` — 17 tests, 0 failures.
- `BUILDX_CONFIG=/private/tmp/scrypath-buildx bash examples/scrypath_ecommerce/scripts/verify-phase173.sh status` — 6 browser tests passed across mounted and standalone entrypoints; disposable Compose resources removed.
- `make -C examples/scrypath_ecommerce contrast` — PASS, 0 AA failures (43 AAA advisories).
- `git diff --check` on all three plan files — passed.

## Deferred Issues

None.

## Threat Flags

None. No new route, authorization boundary, schema, or network surface was added; the existing exact-schema URL helper remains in use.

## Self-Check: PASSED

- The three modified files exist, the focused suite passes, the two browser entrypoints pass, and contrast reports no AA failures.
- Both task commits are ancestors of the summary commit.

## Post-review follow-up (2026-10-11)

Commit `2375f6b71f57037e9e636ae060828e26f59a82c6` closes the Phase 174 UI-review findings: Control Room secondary intents follow the verdict, the generic Search health route is available from healthy state, phase-owned spacing and recovery copy match the contract, and the healthy observation precedes its route. A DOM-order assertion covers the reading order.

The final exact-revision gates passed: `mix verify.ops_ui` (252 tests + 2 doctests), mounted operator journey (4/4), contrast (0 AA failures), and Phase 173 browser regression scopes (shell 14/14, status 6/6, time 8/8, copy 10/10; mounted and standalone). The final Control Room LiveView suite passed 6/6.
