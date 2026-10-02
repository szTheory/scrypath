---
phase: 170-documentation-and-readiness-closeout
plan: "01"
subsystem: documentation
tags: [README, ExDoc, Ecto, sync, Phoenix]

# Dependency graph
requires:
  - phase: 169-library-fix-delivery-and-pr-triage
    provides: verified tenant/facet corrections on refreshed public main
provides:
  - Concise first-hour and sync-mode guidance routed to the sync guide and public API
  - Consolidated README and JTBD navigation retaining the original useful destinations
  - Focused documentation contracts for route presence and canonical sync ownership
affects: [adopter-documentation, documentation-contracts, phase-170-closeout]

# Actuals (#2632): realized diff size measured as chars/4, commits measured from the persisted plan ledger.
actuals:
  tokens: 6954
  tasks: 2
  commits: 4
plan_head_before: 933ad30645c41df9f21dd4ddfd2d5b93fbd48620

# Tech tracking
tech-stack:
  added: []
  patterns:
    - README task-oriented routes point to canonical guide/API owners
    - Docs contract tests assert destinations and contract ownership rather than repeated prose

key-files:
  created: []
  modified:
    - README.md
    - guides/sync-modes-and-visibility.md
    - guides/jtbd-and-user-flows.md
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "Keep first-hour inline guidance prominent and leave exact sync return semantics with Scrypath.sync_record/3 and the sync guide."
  - "Merge navigation and repeated JTBD positioning while preserving every original local destination and the six numbered jobs."
  - "Treat route assertions as structural evidence only; P-170-DOC and EA-170-01 remain flagged and unresolved."

patterns-established:
  - "Concise README route map: group adopter destinations by job and link detailed behavior to canonical owners."

requirements-completed: [DOC-03]
coverage:
  - id: D1
    description: "Adopters can follow installation and the inline-first path, choose a sync mode with an accurate visibility boundary, and reach the detailed API and lifecycle owners."
    requirement: DOC-03
    verification:
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs (74 tests)"
        status: pass
      - kind: unit
        ref: "mix verify.phase112 (8 tests)"
        status: pass
      - kind: unit
        ref: "mix verify.adopter (25 tests)"
        status: pass
      - kind: other
        ref: "mix docs --warnings-as-errors"
        status: pass
      - kind: other
        ref: "Local-link inventory and preservation diff against 933ad30645c41df9f21dd4ddfd2d5b93fbd48620"
        status: pass
    human_judgment: true
    rationale: "P-170-DOC requires bounded semantic review of documentation quality; route assertions and successful builds do not settle that judgment."

commits: 4
duration: 29min
completed: 2026-09-30
status: complete
---

# Phase 170 Plan 01: First-Hour Documentation and Sync Truth Summary

**README and JTBD navigation now preserve the inline-first adoption path while routing sync return semantics to their canonical owners and retaining every useful destination.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-09-30T15:54:48Z
- **Completed:** 2026-09-30T16:24:00Z
- **Tasks:** 2
- **Files modified:** 5
- **Actual diff size:** 27,816 bytes, or 6,954 estimate tokens using chars/4

## Accomplishments

- Kept installation, the schema example, Quick Path, and inline-first Golden path guidance. README briefly distinguishes `:inline`, `:oban`, and `:manual`, preserves acceptance-versus-visibility and database/search non-atomicity caveats, and links to the sync guide and `Scrypath.sync_record/3` API docs.
- Updated the sync guide table to describe the return boundary. Inline `:completed` now explicitly requires a returned task handle and terminal task wait; lifecycle, Phoenix, and recovery detail remains with the guide.
- Consolidated README navigation by adopter job and merged duplicate JTBD positioning and next-reading sections. The six numbered jobs, adoption progression, composition subflow, product limits, and original destinations remain available.
- Updated focused docs assertions without removing the `:docs_contract` exclusion tag.

## Task Commits

The task-owned branch is `agent-170-01-docs`, based on refreshed public main `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`.

1. **Task 1: Follow first-result guidance through canonical sync and API owners** — `5638244` (`docs(170-01): clarify sync return boundaries`)
2. **Task 2: Consolidate job routes without losing useful destinations** — `d27101b` (`docs(170-01): consolidate adopter route maps`)
3. **Plan-scoped wording follow-up:** `ac40f7f` (`docs(170-01): qualify inline task wait results`)
4. **Post-wave regression repair:** `b8a7466` (`fix(170-01): restore release guidance and Oban contract`)

## Files Created/Modified

- `README.md` — concise mode guidance and consolidated adopter/maintainer routes.
- `guides/sync-modes-and-visibility.md` — exact conditional return boundary and API link; full lifecycle and recovery guidance retained.
- `guides/jtbd-and-user-flows.md` — one positioning section, one next-reading section, all six numbered jobs and maturity progression.
- `test/scrypath/docs_contract_test.exs` — assertions for canonical return ownership and retained route set.
- `test/scrypath/telemetry_test.exs` — assertion updated to the documented accepted-after-enqueue Oban return boundary.

## Verification

- `mix test test/scrypath/docs_contract_test.exs` — **74 tests, 0 failures**.
- `mix verify.phase112` — **8 tests, 0 failures**.
- `mix verify.adopter` — **25 tests, 0 failures**.
- `mix test --exclude integration --exclude docs_contract` — **628 tests, 0 failures, 85 excluded** on the task-owned branch after the regression repair.
- `mix docs --warnings-as-errors` — passed; generated HTML, Markdown, and EPUB docs.
- `git diff --exit-code 933ad30645c41df9f21dd4ddfd2d5b93fbd48620 -- guides/golden-path.md lib/scrypath.ex mix.lock examples/phoenix_meilisearch/mix.lock examples/scrypath_ecommerce/mix.lock scrypath_ops/mix.lock` — passed; all preservation-boundary files match the public-main base.
- Route inventory comparison — no original local README/JTBD destination lost and no broken relative link found.

## Route Inventory Disposition

The original README local link set and both JTBD next-reading lists were captured against the refreshed public-main base in an external temporary comparison. The consolidated README route map retains the overview, support, intake, scope, request-edge, composition, related-data, examples, concept, debugging, Phoenix controller/context/LiveView, facet, multi-index, per-query, and operations destinations. The Phoenix integration smoke command, support checks, operator UI check, and backend/Oban scope note remain explicit. Both JTBD lists now resolve through a single `Where to go next` section, including the app-boundary, catalog, and cross-schema routes.

## Key Assumptions and Bounded Judgments

- **EA-170-01 remains unresolved:** this plan serialized changes on its owned branch; it establishes no general concurrent-edit guarantee.
- **P-170-DOC remains unresolved:** focused route/contract assertions establish structure and ownership, not the subjective quality judgment reserved for bounded review.

## Deviations from Plan

- The fresh worktree had no fetched dependencies. `mix deps.get` fetched only versions already pinned in its `mix.lock`, using a temporary Hex cache after the default home cache returned `:eaccess`; no dependency declaration or lockfile changed.
- Final API review prompted one additional plan-scoped documentation commit (`ac40f7f`) to state the task-handle condition precisely. It changed no runtime code.
- The post-wave fast suite caught two Plan 01 regressions: README copy no longer carried the required release-truth tokens, and an existing telemetry assertion still expected the old Oban table row. Restored the concise README wording and updated that assertion to the new accepted-after-enqueue contract in `b8a7466`; the full fast suite then passed.

## Known Stubs

None found in the files created or modified by this plan.

## Threat Flags

None. This plan changed documentation and documentation assertions only.

## Next Phase Readiness

The four task commits, including the post-wave regression repair, are ready to join Plan 02 on the Phase 170 delivery branch. The task-owned worktree and handoff record remain available for sequential Plans 02–05. Semantic review of P-170-DOC and the interruption/concurrency assumption EA-170-01 remain explicitly open.

## Self-Check: PASSED

- Summary file exists in the maintainer planning tree.
- All four task-scoped commits exist on the task-owned branch.

---
*Phase: 170-documentation-and-readiness-closeout*
*Completed: 2026-09-30*
