---
phase: 183-maintainer-tooling-outside-the-hex-package
plan: "08"
subsystem: release-packaging
tags: [acceptance, closeout, hosted-ci, pull-request, hex-package]
requires:
  - phase: 183-06
    provides: "consumer smoke proves the compiled task surface"
  - phase: 183-07
    provides: "packaged-docs guard and source-checkout boundary docs"
provides:
  - "183-ACCEPTANCE.md requirement-to-evidence map for PKGH-01..03"
  - "PROJECT.md adopter-contract line recording the shipped-surface change"
  - "Open, unmerged PR #123 and a successful exact-SHA hosted closeout"
affects: [phase-183-verification, phase-transition]
tech-stack:
  added: []
  patterns:
    - "Two-stage exact-SHA closeout with receipts kept outside the checkout"
key-files:
  created:
    - .planning/phases/183-maintainer-tooling-outside-the-hex-package/183-ACCEPTANCE.md
  modified:
    - .planning/PROJECT.md
key-decisions:
  - "PR base is planning/v1.44-new-milestone (PR #122 still open, ancestor of HEAD) so the diff shows only v1.45 work"
  - "Advisory deep-quality failure (Hex audit advisory against a locked Bandit in the example graphs) is recorded, not fixed: out of scope and not a required check"
requirements-completed: [PKGH-01, PKGH-02, PKGH-03]
status: complete
commits: 1
plan_head_before: 99d843cc981377e54475a72de263697484be35e6
plan_head_after: ff761beaebc4136549eb4685653ec81788642d76
actuals:
  tokens: 6000
  tasks: 2
  commits: 1
duration: 35min
completed: 2026-10-28
coverage:
  - id: D1
    description: "Every local phase gate is green at one recorded SHA (verify.core, verify.package, verify.repository_contracts, beam_cache node tests, both docs builds, offline verify tasks, path-dependency consumer, documented-command loop, history checks)"
    requirement: PKGH-02
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix verify.core --exclude integration --exclude docs_contract"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix verify.package"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix verify.repository_contracts"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix docs --warnings-as-errors && MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "The in-repo path-dependency consumer compiles cold with 0 Verify beams and the 8 public task beams, mix.lock unchanged"
    requirement: PKGH-01
    verification:
      - kind: integration
        ref: "183-08-PLAN Task 1 path-dependency gate on examples/phoenix_meilisearch"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 36 documented mix verify tokens resolve; 7 commands executed from the intended envs"
    requirement: PKGH-02
    verification:
      - kind: other
        ref: "documented-command loop: resolved=36 unresolved=0 total=36"
        status: pass
    human_judgment: false
  - id: D4
    description: "Exact-SHA hosted closeout succeeded for core, package, repository-contracts, backend, ecommerce-mounted, coverage and closeout-attestation; PR open, unmerged, no auto-merge"
    requirement: PKGH-03
    verification:
      - kind: integration
        ref: "node scripts/ci_monitor.cjs closeout --push (run 40700112673, attempt 1, SHA ff761bea)"
        status: pass
    human_judgment: false
---

# Phase 183 Plan 08: Acceptance, PR and hosted closeout Summary

The whole local gate set is green at `99d843cc`, `183-ACCEPTANCE.md` maps PKGH-01..03 to executed evidence, PROJECT.md records that verify tasks are source-checkout only, and PR #123 is open (unmerged, no auto-merge) with a successful exact-SHA hosted closeout.

## Performance

- **Duration:** about 35 min (gates about 12 min, hosted closeout about 14 min)
- **Completed:** 2026-10-28
- **Tasks:** 2
- **Files modified:** 2 (`183-ACCEPTANCE.md` created, `.planning/PROJECT.md` one line added)

## Task 1: local gate, acceptance record, PROJECT.md line

Commit `ff761bea` (`docs(183-08): record phase 183 acceptance`). Toolchain: Elixir 1.19.0 / OTP 28.5 (the plan text names 1.19.5 / 28.1; those are not installed locally). All at HEAD `99d843cc981377e54475a72de263697484be35e6`:

| Gate | Result |
|---|---|
| `MIX_ENV=test mix verify.core --exclude integration --exclude docs_contract` | exit 0; 5 properties, 985 tests, 0 failures (101 excluded); no-optional-deps compile verified; docs build ok; about 53 s |
| `MIX_ENV=test mix verify.package` | exit 0; release contract 104 tests, 0 failures; hex.build ok |
| `MIX_ENV=test mix verify.repository_contracts` | exit 0; 98 tests, 0 failures |
| `node --test scripts/ci/beam_cache.test.cjs` | 10 tests, 10 pass |
| `MIX_ENV=test mix docs --warnings-as-errors` and `MIX_ENV=dev mix docs --warnings-as-errors` | both exit 0, no warning text |
| Path-dependency consumer `examples/phoenix_meilisearch` (cold build dir outside checkout) | exit 0 in about 16 s; 0 `Verify*` beams, 8 `Scrypath.*` task beams, example tree unchanged |
| `mix verify.adopter`, `verify.namespace_fence`, `verify.workspace_clean`, `verify.phase108` (default env) | all exit 0 |
| Documented-command loop | `resolved=36 unresolved=0 total=36` |
| History checks (D-19 CHANGELOG, D-20 Phase 182 and milestones, old fence name grep) | all pass |
| PROJECT.md numstat | `1	0` (one line added, none removed) |

## Task 2: tracking sync, PR, hosted closeout

- Tracking sync: STATE integrity gate passed (`milestone=v1.45`, `milestone_name=Foundation and CI`, `status=executing`), and the cleanliness gate (untracked files included) found nothing uncommitted outside the maintainer's `.planning/config.json` edit, so no sync commit was needed. `.planning/config.json` was never staged.
- Pushed the owned branch as a fast-forward (`2a0f1428..ff761bea`), then opened **PR #123**, https://github.com/szTheory/scrypath/pull/123, titled `fix(package): keep repository-only verify tasks out of the Hex package`, base `planning/v1.44-new-milestone`. State check: `OPEN|<title>|unmerged|no-automerge`.
- Stage 1 closeout at `ff761beaebc4136549eb4685653ec81788642d76`: run **40700112673** (attempt 1, `workflow_dispatch`), https://github.com/szTheory/scrypath/actions/runs/40700112673, exit 0. Required jobs `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, plus `coverage (advisory)` and `closeout-attestation`: all success. Coverage artifact 12820409499, closeout artifact 12820484785 (digests in 183-ACCEPTANCE.md).
- Stage 2 closeout: rerun at the final SHA after the record commit; the receipt lives outside the checkout at `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase183-closeout/stage2-receipt.json`. The executor's return message carries the stage 2 run identity.

## Decisions Made

- PR base is `planning/v1.44-new-milestone`, not `main`: PR #122 from that branch is open and the branch is an ancestor of HEAD, so the diff shows only v1.45 work (plan step 2 rule).
- The advisory `deep-quality` failure is recorded, not repaired: it is a Hex audit advisory in the example lock graphs (Bandit), the phase touches neither lockfile, and the job is not a required check.

## Deviations from Plan

None to the plan's scope. Environment notes:

- Toolchain 1.19.0 / OTP 28.5 instead of the plan's 1.19.5 / 28.1, per the orchestrator.
- My first path-dependency run redirected its log into a directory that did not exist yet (my shell mistake, not a gate failure); I created the directory and reran the plan's gate command unchanged, and only the rerun is recorded.
- A `mix verify.core` step ran the `:test` docs build as part of its sixth step as well as the explicit docs run; both are green.

## Issues Encountered

- `deep-quality (advisory)` failed in the hosted run on the example-graph Hex audit (see above). Advisory only; nothing to fix in this phase.

## Known Stubs

None.

## Threat Flags

None. T-183-14: gates and closeout bind to exact SHAs with failed jobs preserved (there were none among required jobs). T-183-15: CHANGELOG.md, tags, releases and merges were untouched; the PR is OPEN with no auto-merge. T-183-SC: no installs; `mix deps.get` in `examples/phoenix_meilisearch` left its tracked tree unchanged.

## Self-Check: PASSED

- `183-ACCEPTANCE.md` and `.planning/PROJECT.md` changes are in commit `ff761bea`, an ancestor of HEAD.
- Run 40700112673 concluded `success` at the candidate SHA; PR #123 is open and unmerged.
