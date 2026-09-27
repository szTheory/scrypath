---
phase: 166-host-tenant-and-repair-evidence
plan: "03"
subsystem: evidence
tags: [phoenix, ecto, postgres, meilisearch, oban, exact-sha, closeout]

# Dependency graph
requires:
  - phase: 166-01
    provides: persisted-membership host tenant search and facet scenario
  - phase: 166-02
    provides: selected-ID repair, task, and raw-search scenario
provides:
  - Exact-source local and hosted receipts for host path, local package artifact, and root repair.
  - Per-path C-09 freshness disposition against the historical delete receipt.
  - Accurate task validation map and Phase 167 evidence boundaries.
affects: [167-dated-readiness-and-closeout]

# Actuals
actuals:
  tokens: 16369
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Store scenario receipts separately from service/job metadata and keep both source-bound.
    - Inspect the advisory job independently when closeout attestation covers required jobs only.
    - Compare historical evidence with a two-tree relevant-path diff and a reason for every changed path.

key-files:
  created:
    - .planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md
    - .planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json
    - .planning/phases/166-host-tenant-and-repair-evidence/166-03-SUMMARY.md
  modified:
    - .planning/phases/166-host-tenant-and-repair-evidence/166-VALIDATION.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex

key-decisions:
  - "Bind all three live scenarios to committed candidate 50d5c12d36ec560525e245bcb992c40e5927854f and exact-SHA hosted run/job identities."
  - "Treat the package receipt as a fresh local tagged artifact consumption proof, not a Hex registry or publication claim."
  - "Reuse C-09 only for its bounded raw-hit hard-delete claim after accounting for every changed relevant path."
  - "Keep unresolved probe and prohibition rows visible for Phase 167; no readiness decision is made here."

patterns-established:
  - "An advisory scenario can provide acceptance evidence for a recorded source without changing its nonblocking CI status."
  - "Receipts preserve the exact named assertion, source, task, index, runtime, service, and dependency identity."

requirements-completed: [HOST-01, HOST-02, PKG-04, REPAIR-01, REPAIR-02, DELETE-01]

coverage:
  - id: D1
    description: "Persisted host membership determines search scope and the host hydrates only the permitted returned IDs."
    requirement: HOST-01
    verification:
      - kind: integration
        ref: "examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs#authorized tenant search and facet values; run 36321613553 job 108626420623"
        status: pass
    human_judgment: false
  - id: D2
    description: "The mixed-tenant search proves permitted IDs, hydrated records, counts, category facets, and facet values for both tenants."
    requirement: HOST-02
    verification:
      - kind: integration
        ref: ".planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json#host-path"
        status: pass
    human_judgment: false
  - id: D3
    description: "The same named host scenario passes through the repository path and a fresh locally built package artifact."
    requirement: PKG-04
    verification:
      - kind: integration
        ref: ".planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json#host-package"
        status: pass
    human_judgment: false
  - id: D4
    description: "The live manual repair is ID-bounded, read-only at report time, task-correlated, and visible in the same raw query."
    requirement: REPAIR-01
    verification:
      - kind: integration
        ref: "test/scrypath/live_operator_verification_test.exs#bounded manual repair restores the selected raw document; run 36321613553 job 108626420717"
        status: pass
    human_judgment: false
  - id: D5
    description: "The selected repair repeats with a new successful task and the empty selection creates no task."
    requirement: REPAIR-02
    verification:
      - kind: integration
        ref: ".planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json#root-repair"
        status: pass
    human_judgment: false
  - id: D6
    description: "The historical delete receipt is compared at the assessment source and reused only for its bounded claim."
    requirement: DELETE-01
    verification:
      - kind: other
        ref: ".planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json#delete_receipt"
        status: pass
      - kind: other
        ref: "git diff dc400b2b57aec0ca6b0ef16c9477d266fd41a433 50d5c12d36ec560525e245bcb992c40e5927854f -- lib examples config test/support .github/workflows mix.exs mix.lock"
        status: pass
    human_judgment: false

# Metrics
duration: unmeasured
completed: 2026-09-27
status: complete
---

# Phase 166 Plan 03: Exact-Source Evidence Summary

**The host path, local-artifact package, and root repair scenarios passed at one implementation SHA, and the historical deletion receipt remains reusable for its narrow raw-hit claim.**

## Performance

- **Duration:** Unmeasured; the exact Plan 03 start and final hosted wait were not separately recorded.
- **Started:** Exact time not captured; the prior plan handoff was recorded at 2026-09-27T13:00:47Z.
- **Completed:** 2026-09-27.
- **Tasks:** 2.
- **Files modified:** 11 across the fixture correction and phase evidence/tracking.

## Accomplishments

- Ran the canonical Phoenix path and package commands plus the root backend wrapper locally at `50d5c12d36ec560525e245bcb992c40e5927854f` against Postgres 16 / Meilisearch 1.15.2 for the Phoenix consumer and SQLite IntegrationRepo / live Meilisearch for root repair.
- Pushed that candidate and completed exact-SHA closeout run `36321613553`, attempt 1. Required backend succeeded; the independently inspected advisory Phoenix job also succeeded and contains both path/package markers, artifact provenance, and named test counts. Closeout attestation and coverage artifacts were produced.
- Preserved the selected raw IDs, hydrated IDs, counts, facets, settings/write task IDs, repair task IDs/states/index, no-write observation, runtime, local lock digests, hosted run/job IDs, and log excerpt digests in `166-EVIDENCE.json`.
- Compared all 16 changed relevant paths between historical source `dc400b2b57aec0ca6b0ef16c9477d266fd41a433` and assessment source `50d5c12d36ec560525e245bcb992c40e5927854f`. The Phase 165 common-filter behavior change affects facet-search serialization; the C-09 storefront oracle uses ordinary search and raw hits. No changed path invalidates the bounded claim.
- Updated the validation map to the actual six plan tasks and retained all 11 unresolved assumption probes and six unresolved descriptor-less prohibitions.

## Test Results

- Phoenix path: 16 tests, 0 failures; named scenario 505 ms hosted and 491 ms local.
- Phoenix package: freshly built/tagged local artifact `v0.3.13`; staged artifact dependency resolved, consumer compiled, and 16 tests passed. Named scenario 515 ms hosted and 487 ms local.
- Root backend: hosted backend job succeeded; live operator module 4 tests, 0 failures; named repair scenario 432 ms hosted and 643 ms local, with successful first/repeat tasks and the raw projection restored.
- `mix verify.core --exclude integration --exclude docs_contract`: formatting, packaged-path cleanliness, warnings-as-errors compilation, Credo, 591 tests (0 failures; 84 excluded), and docs generation passed.
- Evidence JSON structural and exact changed-path coverage checks passed. `git diff --check` passed.

## Task Commits

1. **Task 1: Trace the same committed host scenario through path and package to exact-source receipts** — implementation/fixture commit `50d5c12` and hosted run/job evidence above.
2. **Task 2: Disposition C-09 against the completed source and preserve the final freshness handoff** — evidence, validation, state, roadmap, and summary tracking commit (this commit).

**Plan metadata:** committed with this summary.

## Deviations from Plan

### Auto-fixed issue

The tenant projection added another ID-like field, so Meilisearch primary-key inference became ambiguous in four existing Phoenix demo smoke fixtures. The canonical path run exposed the fixture problem before acceptance.

- **Fix:** Create those fixture indexes with primary key `id` explicitly through a small test support helper.
- **Files:** `examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex` and four existing smoke tests.
- **Verification:** Canonical path and package consumer suites both passed all 16 tests; exact-SHA hosted Phoenix job passed both modes.
- **Committed in:** `50d5c12`.

**Total deviations:** 1 necessary test-fixture correction. **Impact:** No library API or runtime semantics changed; service evidence now runs with deterministic primary-key configuration.

## Issues Encountered

- The user's default Hex cache was not writable in this environment. Verification used isolated writable `HEX_HOME` and `MIX_HOME` directories under `/private/tmp`.
- Initial path failures were resolved by the explicit test-index primary key correction above.
- `mix deps.get` printed existing Mint 1.9.3 security advisory notices; the lockfile was not changed as part of this evidence phase.

## User Setup Required

None. The configured local services and existing hosted workflow supplied the required receipts.

## Next Phase Readiness

Phase 167 can consume the three exact-source receipts and the bounded reusable C-09 disposition. It owns the separate dated six-condition readiness decision and must repeat source freshness against its own final assessment SHA. The six descriptor-less prohibitions and 11 probe rows remain unresolved.

---
*Phase: 166-host-tenant-and-repair-evidence*
*Completed: 2026-09-27*

## Self-Check: PASSED

- Confirmed the evidence Markdown and JSON exist and the JSON identifies the three named exact-source executions.
- Re-ran the source-bound receipt structure, hosted excerpt digest, and exact changed-path C-09 disposition checks; all passed.
- Confirmed exact-SHA run `36321613553`, advisory Phoenix job `108626420623`, and required backend job `108626420717` concluded success at the recorded candidate.
