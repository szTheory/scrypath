---
phase: 48-ia-and-jtbd-alignment
plan: "02"
subsystem: testing
tags: [mix, jason, documentation, ops]

requires:
  - phase: 48-01
    provides: Nav.primary/0 canonical routes and labels
provides:
  - Machine-readable JSON fence in operator-ia.md
  - mix scrypath_ops.check_nav_contract with optional --write
  - test alias runs nav contract before ecto/test
affects: []

tech-stack:
  added: []
  patterns:
    - "Doc fence delimited by HTML comments; Mix task compares to Nav at runtime"

key-files:
  created:
    - scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex
  modified:
    - scrypath_ops/docs/operator-ia.md
    - scrypath_ops/mix.exs

key-decisions:
  - "Mix task calls compile + app.start so runtime ~p paths in Nav.primary/0 resolve against the endpoint."

patterns-established:
  - "CI fails fast on doc vs Nav drift via the test alias."

requirements-completed: [OPSUX-01]

duration: 30min
completed: 2026-04-21
---

# Phase 48: IA and JTBD alignment — Plan 02 Summary

**`operator-ia.md` carries a Jason-parseable nav fence; `mix scrypath_ops.check_nav_contract` enforces parity with `Nav.primary/0` and runs before `mix test`.**

## Performance

- **Duration:** 30 min (estimate)
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Inserted `<!-- scrypath:nav-contract-begin/end -->` JSON array after the primary nav table’s Search & federation row.
- Implemented `Mix.Tasks.ScrypathOps.CheckNavContract` with mismatch `Mix.raise`, success log, and `--write` to refresh the fence from code.
- Prepended `scrypath_ops.check_nav_contract` to the `test` alias in `mix.exs`.

## Task Commits

1. **Task 1: Fence in operator-ia.md** — `53b28c8` (docs)
2. **Task 2: Mix task** — `b29fa28` (feat)
3. **Task 3: test alias** — `1871d16` (chore)

## Deviations from Plan

- `--write` always rewrites the fence when passed (clearer operator story than only-on-mismatch).

## Issues Encountered

- `Nav.primary/0` uses runtime `~p` resolution; `app.start` is required in the Mix task before reading Nav. Phoenix 1.8 rejects `~p` in module attributes, so a compile-time-only list was not viable without dropping verified routes.

## Self-Check: PASSED

- `cd scrypath_ops && mix scrypath_ops.check_nav_contract` — pass
- `cd scrypath_ops && mix test` — pass

---
*Phase: 48-ia-and-jtbd-alignment*
*Completed: 2026-04-21*
