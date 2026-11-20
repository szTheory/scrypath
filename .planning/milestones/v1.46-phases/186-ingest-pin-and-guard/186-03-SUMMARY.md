---
phase: 186-ingest-pin-and-guard
plan: 03
subsystem: ci-governance-and-preservation-guard
tags: [tok-04, structural-pair-check, png, ink-coverage, calibration, workflow-wiring, branch-protection, storybook-boundary, gate-budget, gate-02]

requires:
  - phase: 186
    plan: 02
    provides: GATE-02 decision "go" and the token guard this plan sits beside
provides:
  - "comparePngStructural and inkCoverageGrid in scripts/ci/ui_state_pairs.cjs: recolor-tolerant pixel check calibrated on real captures, replacing the exact pixel term only"
  - "scripts/ci/fixtures/ui-state-pairs/: four committed 390x320 crops of real v1.43 captures plus PROVENANCE.md (about 134 KB)"
  - "ui_state_pairs.test.cjs: 24 tests (calibration accept and rejects on real captures, layout mutations, recolor accept through the full bundle path, isolated actions, transport_sequence and test_identity mutations)"
  - "workflow-wiring test pinning exactly six required contexts and the unchanged ops-ui (path-scoped) name"
  - "storybook boundary checks (root lib, root manifest, ScrypathOps only: [:dev, :test]) with planted cases, running in core and repository-contracts"
  - "CONTRIBUTING.md 'Required-gate budget' ledger (5 of 12) parsed by a test with planted defects"
  - "Phase 186 close-out receipts (GATE-02)"
affects: [187, 188, 189]

actuals:
  # chars/4 over the added lines of the realized non-planning diff (29,143 chars). The four binary PNG
  # fixtures (about 134 KB) are not text and are not counted. The plan's estimate (70,000) was a work
  # estimate that included reading, calibration and the three gate runs.
  tokens: 7300
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Mode-relative block check: per 16 px block, share of pixels off the block's most common color, rounded to 16 steps; accept needs at most 0.25 percent of blocks over a step delta of 2, worst step at most 8, identical dimensions"
    - "Calibration fixtures are committed whole-row crops with a provenance note, so tests never read a prunable archive"
    - "A governance ledger in prose is made enforceable by a parser test with planted defects"

key-files:
  created:
    - scripts/ci/fixtures/ui-state-pairs/recolor-before-dark-390x320.png
    - scripts/ci/fixtures/ui-state-pairs/recolor-after-dark-390x320.png
    - scripts/ci/fixtures/ui-state-pairs/state-before-dark-390x320.png
    - scripts/ci/fixtures/ui-state-pairs/state-after-dark-390x320.png
    - scripts/ci/fixtures/ui-state-pairs/PROVENANCE.md
  modified:
    - scripts/ci/ui_state_pairs.cjs
    - scripts/ci/ui_state_pairs.test.cjs
    - .github/workflows/ci.yml
    - test/mix/tasks/workflow_wiring_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - CONTRIBUTING.md
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md

key-decisions:
  - "The calibration reproduced the plan's numbers exactly, so no threshold was changed (tolerance 0.25 percent, worst step 8, 16 px blocks)"
  - "Task 1 carries the rewrite of the three solid-color pair cases (not Task 2), because the comparator change makes them fail or pass vacuously and Task 1's verify needs a green file"
  - "The pair report keeps its v3 schema string and its status values; status 'exact-match' now means all receipts match under the structural pixel check"
  - "Phase close gates ran on the final code commit 6af22174, with the later commits touching only .planning/"

requirements-completed: [TOK-04, GATE-01, GATE-02]

coverage:
  - id: D1
    description: "Structural pair check accepts a real recolor pair and rejects a real state-change pair and a real 8 px band shift, on committed crops"
    requirement: TOK-04
    verification:
      - kind: unit
        ref: "scripts/ci/ui_state_pairs.test.cjs (describe: structural calibration on real captures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The pair comparator still fails on geometry, state, focus, copy, assertions, actions, transport sequence and test identity; each of actions, transport_sequence and test_identity has its own isolated mutation"
    requirement: TOK-04
    verification:
      - kind: unit
        ref: "scripts/ci/ui_state_pairs.test.cjs (a source pair fails structural pixels, geometry, state, copy and semantic assertions; a recolor-only candidate passes the source pair when all other evidence matches)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exactly six required contexts including the unchanged ops-ui (path-scoped) name; ops-ui path list covers brand/, language/ and fixtures/; CONTRIBUTING names all six"
    requirement: GATE-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs (exactly six required contexts; contributing required-check contract; ops-ui is a required context that reports instead of being path-filtered)"
        status: pass
      - kind: other
        ref: "gh api repos/szTheory/scrypath/branches/main/protection --jq '.required_status_checks.contexts' (read-only) lists six contexts including ops-ui (path-scoped)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Static storybook boundary checks with planted cases, in core and repository-contracts"
    requirement: GATE-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs (describe: storybook boundary (v1.47 catalog))"
        status: pass
    human_judgment: false
  - id: D5
    description: "Required-gate budget ledger at 5 of 12 with deletion trigger and churn per gate, enforced by a parser test with planted defects"
    requirement: GATE-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs (required-gate budget ledger stays within 12 with deletion triggers; planted ledger defects are flagged and a compliant ledger is accepted)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Phase 186 closed in 3 plans with each full gate run once on the plan's final code SHA; Plan 03 gates green on 6af22174"
    requirement: GATE-02
    verification:
      - kind: other
        ref: "mix verify.repository_contracts, mix verify.core --exclude integration --exclude docs_contract, mix verify.ops_ui on 6af221748691038f041561732ac5f7942c23515f (receipts below)"
        status: pass
    human_judgment: false

duration: 50min
completed: 2026-11-18
plan_head_before: 388fa8299b37c18d5925d0d8ddd041d048383f5e
plan_head_after: 3553e8bebc42f5e549d3f31d2ced321918f3cf75
commits: 4
status: complete
---

# Phase 186 Plan 03: Structural pair check, six required contexts and the gate-budget ledger Summary

**The Phase 185 pair check now accepts a real recolor (0 of 500 blocks over) and rejects a real state change (179 of 500) and a real 8 px band shift (71 of 500), the wiring test pins six required contexts with `ops-ui (path-scoped)` unchanged, three storybook boundary checks and a 5-of-12 gate ledger are enforced by tests, and all three full gates are green on the final code commit.**

## What this means in plain terms

Before this plan, every Phase 187 preservation pair would have failed on the recolor alone, because the pair check compared pixels exactly. Now only that one term is relaxed: it asks whether the page layout and content moved, not whether the colors changed. Copy, geometry, state, focus, assertions, actions, transport sequence and test identity are still compared exactly, and each now has a test that fails if it is dropped. The relaxed check is a coarse backstop: a single band of 16 to 40 px moved by 1 to 8 px stays under its tolerance, and the geometry and copy receipts are what catch small layout moves. The CI contract now matches branch protection (six required contexts), the storybook cannot leak into the published package without a required job failing, and the budget for new required gates is written down and checked by a test. No rendered UI changed and branch protection was only read.

## Accomplishments

- **Calibrated comparator.** `comparePngStructural` replaces the exact pixel equality term only. Byte-identical or pixel-identical inputs short-circuit to equal; different dimensions are never equal; the decode, raw-hash reuse and metadata-dimension checks are unchanged. Result fields keep their names and the v3 schema string.
- **Real-capture calibration.** Four committed 390x320 crops of whole rows (about 134 KB) with a provenance note. Accept and both rejects reproduce the planning-time numbers (table below).
- **Both directions probed.** Loosening the share tolerance turns both real-reject tests (and the moved-block test) red; making the step delta over-strict turns the recolor accept red.
- **Mutation tests for the non-pixel terms.** Actions, transport_sequence and test_identity each have an isolated mutation asserting the matching mismatch flag is false while pixels stay equal. Removing `actionEqual` from the verdict, reducing `actionEqual` to actions only, and removing `identityEqual` each turn the matching assertion red.
- **Solid-color cases replaced.** The three sites that a structural check would pass vacuously (a 12x8 pair, a hover-only case, a pixel-changed candidate) are now striped layouts with a moved block; a recolor-only candidate passes through the full 61-case, 213-observation bundle path.
- **Existing required step.** `scripts/ci/ui_state_pairs.test.cjs` is appended to the repository-contracts Node step; no new job or step.
- **Six required contexts.** The wiring test expects backend, core, ecommerce-mounted, ops-ui, package and repository-contracts, and pins the exact `ops-ui (path-scoped)` name with a message about orphaning the live required context. CONTRIBUTING's contract test names all six.
- **Storybook boundary.** Root `lib/` never mentions `PhoenixStorybook` or `phoenix_storybook`; the root manifest does not depend on it; a ScrypathOps dependency must declare `only: [:dev, :test]` (order-insensitive). Planted sources and temp manifests prove each check fails (unrestricted, `only: :dev`, `only: [:dev, :test, :prod]`) and a compliant manifest passes. These pass vacuously on the live tree until v1.47 adds the dependency, as planned.
- **Gate-budget ledger.** `### Required-gate budget` in CONTRIBUTING.md: 5 rows, each with enforcing file, lane, deletion trigger and expected churn; "Budget used: 5 of 12." A test parses it and fails on more than 12 rows, an empty trigger or churn cell, a missing enforcing file, a missing Phase 186 gate or a budget line that disagrees with the row count; planted defects prove each.

## Task Commits

| # | SHA | Task | What |
|---|-----|------|------|
| 1 | `ad3449b4` | tracer | comparator, committed crops and provenance, calibration tests, wiring into the existing Node step, three solid-color cases rewritten |
| 2 | `c5cd9ca3` | auto | recolor-only accept through the bundle path; isolated actions, transport and identity mutations; test rename |
| 3 | `6af22174` | auto | six-context wiring test, CONTRIBUTING contract names, storybook boundary checks, gate ledger and its parser test |
| - | `3553e8be` | docs only | brand playbook evidence (T9, T17, S5, S26) |

**Tracer note.** Task 1 was proven end to end before Task 2 expanded it: the comparator, real-capture calibration, the committed crops, the rewritten cases and the CI wiring were green together (`# fail 0`, wiring test 0 failures) before any other task started. `# tests 24` and `# pass 24` after Task 2.

## Calibration measurements

Block size 16 px, 16 steps, over-step threshold 2, tolerance 0.25 percent, worst step at most 8. Reproduced with a throwaway script (planning-time prototype logic) and then with the module itself; both agree with the plan.

| Case | Full capture | Committed crop |
|------|--------------|----------------|
| Recolor accept: 173 cool vs warm, dark, 390 | 0 of 5100 over, worst step 1 | 0 of 500 over, worst step 0 |
| State-change reject: 176 delete dialog initial vs invalid, dark, 390 | 322 of 1725 over (18.7 percent), worst step 12 | 179 of 500 over (35.8 percent), worst step 8 |
| Band-shift reject: warm with 100 rows shifted down 8 px, against cool | 20 of 5100 over (0.39 percent), worst step 6 (rows 600-699) | 71 of 500 over (14.2 percent), worst step 7 (rows 120-219) |

Other measurements: 173 cool vs warm light 390 gives 0 of 5100 over; dark 1440 gives 0 of 9630 over; 176 light 1440 state change gives 487 of 6210 over (rejected). Block sizes 8 and 32 also separate the cases on the full captures (recolor 0 over at both; state 1237 of 6762 and 59 of 455; shift 82 of 19992 and 4 of 1326). The numbers match the plan (accept 0 of 500, state 179 of 500, shift 71 of 500), so no threshold was touched and the stop condition was not triggered.

Finding recorded: on the crops both real rejects stay within the worst-step limit (8 and 7), so only the share-of-blocks tolerance separates them from the accept. Fixture sizes: 21,213 + 21,127 + 41,914 + 50,358 = 134,612 bytes (`du` total 144 KiB, under the 160 limit).

## Red-on-removal and probe observations

The plan asked for local temporary edits of the verdict. The Edit tool refused a temporary in-repo loosening of the threshold (classified as weakening a guard), so every probe ran on a scratch copy of `scripts/ci` and the demo directory outside the repository; the repository files were never mutated.

| Probe (scratch copy) | Result |
|---|---|
| `STRUCTURE_MAX_BLOCK_SHARE = 1` | state-change, band-shift and moved-block tests red; recolor accept still green |
| `STRUCTURE_STEP_DELTA = -1` | recolor accept red |
| `actionEqual` removed from `passed` | "actions change alone fails the pair" red |
| `actionEqual` reduced to actions only | "transport_sequence change alone fails the pair" red |
| `identityEqual` removed from `passed` | "test_identity change alone fails the pair" red |

## GATE-02 phase close

### Branch protection (read-only)

`gh api repos/szTheory/scrypath/branches/main/protection --jq '.required_status_checks.contexts'` printed:

```
["backend (required)","core (required)","ecommerce-mounted (required)","package (required)","repository-contracts (required)","ops-ui (path-scoped)"]
```

Count 6, includes `ops-ui (path-scoped)`. Nothing was changed. No job was renamed and `closeout-attestation` was not touched.

### Receipts

**The phase closed in 3 plans.** Each full gate ran once on the plan's final code SHA (a code SHA, never a SUMMARY commit). Later commits for each plan touch only `.planning/` paths. No capture was taken: TOK-04 used committed captures only, so the no-dirty-tree capture rule was not exercised.

| Plan | GATE_SHA | Gate | Result | `git diff --name-only <GATE_SHA>..<plan's last commit>` |
|------|----------|------|--------|---|
| 01 | `a876a61379685de2c1034e5781c188a24fac63ec` | `verify.core` | steps 1-5 pass (format, workspace, compile, credo, 1100 tests 0 failures); **step 6 `mix docs --warnings-as-errors` red** from an `AGENTS.md` link in CONTRIBUTING.md that predates the plan. Not re-run on this SHA. | `.planning/phases/186-ingest-pin-and-guard/186-01-SUMMARY.md`, `.planning/phases/186-ingest-pin-and-guard/deferred-items.md`, `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` |
| 01 | same | `verify.ops_ui` | pass: root boundary 2 tests, ops 2 doctests and 329 tests, 0 failures | same |
| 01 | same | `verify.package` (extra) | pass: 110 tests, 0 failures | same |
| 02 | `b58fd05b0ab6a0220edee0e92f30869246e76ac5` | `verify.repository_contracts` | pass: 151 tests, 0 failures, 193.7 s | `.planning/phases/186-ingest-pin-and-guard/186-02-SUMMARY.md`, `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` |
| 02 | same | `verify.core` | pass: all six steps (1111 tests, 0 failures, docs clean) | same |
| 02 | same | `verify.ops_ui` | pass: 2 doctests, 329 tests, 0 failures | same |
| 03 | `6af221748691038f041561732ac5f7942c23515f` | `verify.repository_contracts` | pass: 157 tests, 0 failures, 185.1 s | `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` and this SUMMARY |
| 03 | same | `verify.core --exclude integration --exclude docs_contract` | pass: format, workspace clean, compile with warnings as errors, credo, 5 properties and 1117 tests 0 failures (103 excluded, 286.0 s), docs with warnings as errors clean, no-optional-deps compile | same |
| 03 | same | `verify.ops_ui` | pass: root boundary 2 tests (188.4 s), then ops 2 doctests and 329 tests, 0 failures (218 s); host Postgres, task-scoped database `scrypath_ops_test_186_03`, dropped afterwards | same |

Plan 01's `verify.core` is the one receipt that was not fully green on its own SHA. The cause was a pre-existing branch defect, not Plan 01's code: the orchestrator fixed it in `97f6ea8c` (plain-text mention instead of a link), which is an ancestor of both Plan 02's and Plan 03's GATE_SHA, and both of those SHAs have a fully green `verify.core` including the docs step. I did not re-run a gate on Plan 01's superseded SHA (a stale receipt is not repaired by re-running it on an old input). The gate-sha receipt for Plan 03 had a clean working tree (`git status --short` printed nothing) before each of the three runs.

The three Plan 03 gates ran with the escalated permission AGENTS.md authorizes for fetch-dependent verification; it was granted each time.

### Closure evidence and hosted CI

Closure evidence for Plan 03 is local: `verify.core`, `verify.ops_ui` and `verify.repository_contracts` are green on `6af22174`, as the plan allows. **Hosted CI has not run**: nothing is pushed. Follow-up for `/gsd-ship`, separate from the local closure evidence: a hosted exact-SHA run of `core`, `package`, `repository-contracts`, `ecommerce-mounted` and `ops-ui` on the PR head. `package` and `ecommerce-mounted` were not in Plan 03's gate list; `package` was last run locally on Plan 01's SHA.

### CI speed-win note (copied from Plan 02, extended)

From the research, on the latest main push run, `repository-contracts` spends 575 of its 823 s in the four-file Node step (about 16 lifecycle tests at 30 to 36 s each plus one of 67 s). That remains the candidate for a later CI change; nothing in this phase changed CI timing on purpose. Measured here: the new `ui_state_pairs.test.cjs` adds one file of about 29 s locally (24 tests) to that step; hosted cost is unmeasured and likely small because `node --test` runs files concurrently. Locally, `verify.repository_contracts` took 185.1 s (5.8 s async, 179.2 s sync); Plan 02 attributed that sync part to the four `contrast_child` tests, each starting a nested `mix verify.repository_contracts`, and I did not re-measure them separately. `verify.core`'s `mix test` took 286.0 s, of which 276.4 s is sync (non-async) tests, so the sync tests are where a speed win would be.

## Files Created/Modified

See the frontmatter `key-files`. The binary fixtures are the only large additions; the rest are small edits and tests.

## Decisions Made

- No threshold change (see key-decisions).
- The ledger check is a helper returning a list of problems, used by one live test and one planted-defect test, rather than inline assertions. That is what lets planted defects prove it is not vacuous.
- The `status: "exact-match"` string in the pair report is left as is. It now means every receipt matches with the structural pixel check. Renaming it would need a schema bump and nothing in this phase reads it; an optional cosmetic follow-up for Phase 187.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The three solid-color rewrites moved from Task 2 into Task 1**
- **Found during:** Task 1
- **Issue:** Task 1's verify requires `# fail 0` on the whole test file, but replacing the pixel term makes the three solid-color cases (`png(12, 8, 20)` vs `21`, `imageColor: 20` vs `hoverImageColor: 21`, `imageColor: 21`) fail or pass vacuously.
- **Fix:** Added `layoutPng` and the `imageLayout` and `hoverImageLayout` options in Task 1 and rewrote the three sites there. Task 2 then added the recolor accept case, the isolated mutations and the rename, as planned. The Task 2 acceptance greps all hold.
- **Commit:** `ad3449b4`

**2. [Rule 2 - Missing critical functionality] Extra non-vacuity checks**
- A fourth calibration test (different dimensions are never equal and report null block counts) and a planted-defect test for the gate ledger, so the ledger parser is shown to fail on 13 rows, an empty trigger, a missing file, a missing Phase 186 gate, a wrong budget line and a missing section. The plan listed only the live ledger test.
- **Commit:** `ad3449b4`, `6af22174`

**3. [Rule 1 - Bug] Deprecated sigil in the first ledger test**
- `~R/.../` is deprecated in Elixir 1.19 and printed a warning under `mix test`. Replaced with a `String.split` on the next heading before commit. Found by the first test run; never committed.

### Form differences, no behavior change

- Mutation probes ran on a scratch copy outside the repository (see the probe section) instead of temporary in-repo edits.
- `STRUCTURE_BLOCK_PX` and the other constants are not exported (the plan asked for `comparePngStructural` and `inkCoverageGrid` only); tests assert block counts through the result fields.
- Added the playbook evidence commit (`3553e8be`) because AGENTS.md asks for the playbook to be updated in the same change that proves or refines a rule; the plan's file list did not name it.

**Total deviations:** 3 auto-fixed (1 blocking, 1 missing-critical, 1 bug found before commit). **Impact:** none on scope; every acceptance grep in the plan holds.

## Issues Encountered

- No `<project_root_pin>` block was in the dispatch prompt, so the supplied-root pin was skipped with this note and the worktree guards (branch namespace, toplevel sentinel, plan-head ledger) were used.
- The worktree had no `node_modules`; `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` (the repository-contracts install step) provided pngjs.

## Blocked gates

None. The escalated route AGENTS.md authorizes was granted for all three gates. No Docker or Buildx step ran, so no Docker resources were created and none need cleanup; the only task-scoped resource (the Postgres database `scrypath_ops_test_186_03`) was dropped.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-186-13 (comparator too loose) is mitigated by the two-sided probes and two real rejects; T-186-14 by keeping the decode, raw-hash reuse and dimension checks unchanged and bounding the grid scratch buffer to one block; T-186-15 by the six-context and exact-name assertions with no branch-protection write; T-186-16 by the planted storybook checks in two required jobs; T-186-17 by the parsed ledger. T-186-SC: no package was installed beyond the locked `npm ci` that already carries pngjs 7.0.0.

## Playbook dispositions

T9, T17, S5 and S26 gained build evidence and refinements in `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` (change log line added). New findings: a mode-relative structural check is blind to uniform rasters, so solid-color fixtures pass vacuously; a band shifted by 1-8 px stays under the tolerance; on the crops only the share-of-blocks term separates the real rejects from the accept.

## Next Phase Readiness

TOK-04 is on main-bound code before any Phase 187 "before" capture, so editing `ui_state_pairs.cjs` no longer changes the evidence identity after a capture. Phase 187 owns, as recorded in Plan 02's projection: flipping token-map rows to applied, rebuilding the tracked CSS, the muted-text alpha lockstep, and the three advisory-lane e2e specs. Optional cosmetic follow-ups: rename the report `status` value, and consider the repository-contracts Node-step speed win. No user action is needed to proceed; the hosted exact-SHA run is the `/gsd-ship` follow-up.

## Self-Check: PASSED

- Files present: the four fixture PNGs, `PROVENANCE.md`, the edited comparator and test, `ci.yml`, the two wiring and boundary tests, `CONTRIBUTING.md`.
- Commits reachable from HEAD: `ad3449b4`, `c5cd9ca3`, `6af22174`, `3553e8be`.
- `STATE.md` and `ROADMAP.md` untouched; `.planning/config.json` and `.planning/state.json` not created or staged.

---
*Phase: 186-ingest-pin-and-guard*
*Completed: 2026-11-18*
