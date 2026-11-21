---
phase: 195-mount-and-prove
plan: 03
subsystem: infra
tags: [phoenix_storybook, go-no-go, hosted-ci, ops-ui, adr, release-train, docker-boundary]

requires:
  - phase: 195-mount-and-prove
    provides: "Plans 01 and 02: dependency, route guard, absence proofs, hooks, render-all with a planted failing tree, five stories"
provides:
  - "Local mirror of every required lane on the pushed commit, all green"
  - "Phase PR #171 merged (squash 96521ab1) at the measured head with six required checks green"
  - "Hosted ops-ui numbers: cold 517 s (PR) and 620 s (first main run after the merge), warm 378 s, with time-matched controls (342 s and 417 s)"
  - "GO-NO-GO.md (decision: go, as the maintainer's choice against a tripped cold sample; one verdict per ADR 0001 trigger plus both H exit items) and the ADR 0001 amendment"
  - "CI-EFFICIENCY findings 25 to 28 (measured ops-ui cost, root-graph cache candidate, timing observability candidate, post-merge docs PR saving)"
affects: [196, 197, 198]

actuals:
  tokens: 13000
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "the real phase PR is the cost-measurement run (cold = first run, warm = job rerun on the same SHA, plus a paired main rerun at the same hour)"
    - "hosted NIF fetch time is read from BuildKit logs, where the Elixir logger's own clock survives, because verify.ops_ui buffers subprocess output"
    - "the decision record lands in a post-merge planning-only PR so path-scoped lanes skip"
    - "a decision checkpoint after merge is possible: the first cold main run only exists once the merge has started it"

key-files:
  created:
    - .planning/phases/195-mount-and-prove/GO-NO-GO.md
    - .planning/phases/195-mount-and-prove/195-03-SUMMARY.md
  modified:
    - .planning/adr/0001-phoenix-storybook-for-scrypath-ops.md
    - .planning/reference/CI-EFFICIENCY.md

key-decisions:
  - "Continue (go) on the maintainer's choice against a tripped cold sample, not as a pass: the PR cold run (517 s) was under the 548 s line, the first main run after the merge (620 s) was over it, so the checkpoint was presented after the merge and the maintainer selected \"Continue (Recommended)\" on 2026-11-21"
  - "Took the same-day main control at the same time as the warm sample, and a second control matched to the main run's hour, so each cold sample has a paired comparison"
  - "Cold-versus-warm gap (139 s) is attributed to the root-graph BEAM cache miss any lock change pays, not to the storybook; the storybook's own marginal cost is about +36 s (inference from one paired sample)"

patterns-established:
  - "Report a close margin plainly, and treat a later sample over the line as a trip even after the merge, rather than choosing the favourable sample"

requirements-completed: [MOUNT-04, FLOW-01, FLOW-02, FLOW-03, FLOW-04]

coverage:
  - id: D1
    description: "Hosted cold and warm ops-ui timings with run, attempt and job ids; baseline, median, spread and the 38-run main history as evidence; NIF fetch time with its source; lock growth; advisory status; asset_builder delta with its method; one verdict per ADR 0001 trigger and both H exit items"
    requirement: MOUNT-04
    verification:
      - kind: other
        ref: "gh run view 44955813968 --json jobs (attempt 1: ops-ui 517 s; attempt 2: 378 s); gh run view 44958204651 --json jobs (main, cold: 620 s); .planning/phases/195-mount-and-prove/GO-NO-GO.md"
        status: pass
      - kind: other
        ref: "grep -cE '^\\| (Advisory open over 14 days|Cold ops-ui over baseline plus 180 s|Isolation work over a day|Docker asset_builder over plus 60 s|NIF failure twice)' GO-NO-GO.md prints 5; grep -c '^## ' prints 11"
        status: pass
    human_judgment: false
  - id: D2
    description: "ADR 0001 carries an amendment with the numbers and the decision"
    requirement: MOUNT-04
    verification:
      - kind: other
        ref: "grep -c 'measured go/no-go' .planning/adr/0001-phoenix-storybook-for-scrypath-ops.md prints 1; the amendment links GO-NO-GO.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase PR titled chore(ops-ui): and squash-merged on six green required checks at the measured head; record in a docs(phase-195): PR; no release PR"
    requirement: FLOW-01
    verification:
      - kind: other
        ref: "gh pr view 171 --json state,title (MERGED, chore(ops-ui):); gh pr list --state open release-please count 0 before the phase merge, after it, and after the docs merge"
        status: pass
    human_judgment: false
  - id: D4
    description: "Local mirror of every required lane on the pushed commit, each with a result; Docker resources task-scoped and cleaned"
    requirement: FLOW-03
    verification:
      - kind: other
        ref: "scripts/ci/pre_push.sh, mix verify.core, verify.package, verify.repository_contracts, the five Node files, verify.ops_ui, mix precommit, mix verify.ecommerce_mounted (table below)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The dashboard_routes guard defect, the compile-time flag residual, the measure-then-merge ordering gap and the open F1, F2, D2 and hygiene items handed to the maintainer, not fixed"
    requirement: FLOW-04
    verification:
      - kind: other
        ref: "GO-NO-GO.md '## Findings for the maintainer' items (a) to (f)"
        status: pass
    human_judgment: false

duration: 95min
completed: 2026-11-21
status: complete
commits: 5
plan_head_before: 96521ab19bdca2a3831a3d171fb621fa9d7d5311
plan_head_after: ed29d92392dc3bbf4851bc53a0d80e5f56426d29
---

# Phase 195 Plan 03: Mount and prove (go/no-go, hosted cost, ship) Summary

**The storybook costs the hosted `ops-ui` job 517 s cold on the PR and 620 s cold on the first main run, and 378 s warm, against a 368 s baseline; the 620 s sample tripped the cold trigger, the maintainer chose to continue, the phase PR (#171) is merged and the decision is recorded in `GO-NO-GO.md` and an ADR 0001 amendment.**

## Performance

- **Duration:** about 95 min (about 45 min on local lanes, the rest on hosted waits, the checkpoint round trip and the record)
- **Started:** 2026-11-21T21:48Z
- **Completed:** 2026-11-21
- **Tasks:** 3 (Task 2, the checkpoint, was reached after the merge and answered)
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- The full local mirror of every required lane passed on the exact pushed commit, including the Docker `ecommerce-mounted` lane, which is the only local proof that the Plan 01 script edit returns a real 404 for `/storybook` from the test and prod images.
- Phase PR #171 (`chore(ops-ui): ...`) ran once on hosted CI as the cold sample and once more as the warm sample, and merged with all six required checks green on the measured head. No release PR appeared.
- Measured and recorded: cold 517 s on the PR and 620 s on the first main run after the merge, warm 378 s, controls 342 s and 417 s; NIF fetch 0.40 s and 0.66 s on the hosted Linux target; lock growth 56 to 65 lines; no advisory on a resolved version; asset_builder proxy +33 s; isolation work 0.1 h.
- The 620 s main-run sample is over the 548 s cold line, so the trigger counts as tripped. The executor stopped and asked; the maintainer selected "Continue (Recommended)" on 2026-11-21. It is recorded as their choice against a tripped cold sample, not as a pass. The other four triggers are not tripped and the warm line held.
- The cold excess is mostly the root-graph BEAM cache miss any lock change pays (found in the cache logs, 139 s on the PR runs), logged as a CI candidate. The storybook's own marginal cost is about +36 s on one paired sample. Of the previous 38 main runs, 5 exceeded 548 s and none of them changed a lock file.

## Task Commits

1. **Task 1: Local mirror, draft PR, hosted measurement** - no commit by design (the plan keeps GO-NO-GO.md uncommitted); PR #171 opened as a draft at head `f9af18d4` and merged as `96521ab1`.
2. **Task 2: Maintainer checkpoint** - reached after the merge, when the main push run the merge started measured 620 s. Maintainer reply: `Maintainer selected "Continue (Recommended)" in an interactive dialog on 2026-11-21`, relayed to the executor by the orchestrating agent (the executor did not see the dialog).
3. **Task 3: Record, amend, merge, land the record** - five commits on the docs branch: `a92cc794` (record), `a3df4c43` and its revert `325a60f0` (a plan-completion commit that was undone when the checkpoint turned out to be needed; the pair nets to nothing), `38d75709` (record held pending, `[skip ci]`) and `ed29d923` (decision go). The phase PR squash merge is `96521ab1`.

**Plan metadata:** the commit after `ed29d923` on the same docs branch carries this file and the STATE, ROADMAP and REQUIREMENTS updates. Docs PR `#172` (`docs(phase-195): record the storybook go/no-go`) is squash-merged after its required checks; its merge commit is the commit that carries this file.

## Evidence

### Local mirror on the pushed commit (`f9af18d4`)

| Lane | Command | Result |
|---|---|---|
| cheap subset | `bash scripts/ci/pre_push.sh` | exit 0, 11 steps passed, none skipped (actionlint present), 83 s |
| `core` | `mix verify.core --exclude integration --exclude docs_contract` | exit 0, 6 properties, 1315 tests, 0 failures (104 excluded), 585 s |
| `package` | `mix verify.package` | exit 0, 69 s |
| `repository-contracts` | `mix verify.repository_contracts` (git metadata access as AGENTS.md authorizes) | exit 0, 175 tests, 0 failures, 393 s |
| `repository-contracts` | `node scripts/ci/ui_literal_policy.cjs` | PASS |
| `repository-contracts` Node step | `node --test --test-reporter=tap` over the five CI files (after `npm ci --ignore-scripts` restored the missing `pngjs`) | exit 0, 162 tests, 0 fail, 591 s: `ecommerce_build` 22, `ecommerce_lifecycle` 35, `ecommerce_evidence` 49, `ecommerce_target` 17, `ui_state_pairs` 39 |
| `ops-ui` | `mix verify.ops_ui` | exit 0, root boundary integration 2 tests, ops suite 2 doctests and 567 tests, 0 failures, 286 s |
| `ops-ui` | `cd scrypath_ops && mix precommit` | exit 0, 2 doctests, 567 tests, 0 failures, 25 s, `mix.lock` unchanged |
| `ecommerce-mounted` | `mix verify.ecommerce_mounted` with `E2E_PROJECT_NAME=scrypath_195_mounted`, `BUILDX_CONFIG` in the scratchpad | exit 0, 775 s: the boundary script's runtime proof passed (`DEPENDENCY_BOUNDARY_CATALOG ... status=404` for the host and standalone Ops in both the test and prod images) and the five Playwright specs passed |
| `backend` | none | not affected (no root `lib/` change) |

Nothing was skipped. What a local run cannot show: hosted caches and a clean checkout, Elixir 1.19.0 on OTP 28.1 (local OTP 28.5), amd64 images (local Docker builds arm64) and Docker-in-Docker. The hosted run on the same commit passed every required lane first time. For the docs PR, the cheap local checks ran on its commit: both path classifiers report `run=false`, UI token and state pair tests (129), UI literal policy, `mix verify.workspace_clean`, and the planning-reading contract tests (171, 0 failures).

### Hosted runs used

| Purpose | Run | Attempt | Job | Result |
|---|---|---|---|---|
| Cold sample 1 (PR #171, head `f9af18d4`) | 44955813968 | 1 | `ops-ui` 137003601222 | 517 s, step 479 s |
| Warm sample (`gh run rerun --job`) | 44955813968 | 2 | `ops-ui` 137007958395 | 378 s, step 344 s |
| Cold sample 2 (main push after the merge, `96521ab1`) | 44958204651 | 1 | `ops-ui` 137010963728 | **620 s**, step 581 s |
| Same-day control (main `a11c36cd`, rerun at 22:32 UTC) | 44943834998 | 2 | `ops-ui` 137007989641 | 342 s, step 307 s |
| Control matched to the main run's hour (22:57 UTC) | 44943834998 | 3 | `ops-ui` 137014561618 | 417 s, step 378 s |
| Baseline (latest green main push) | 44943834998 | 1 | `ops-ui` 136966725694 | 374 s, step 334 s |
| Bake-step baseline (last three green main pushes) | 44943834998, 44943130548, 44939887715 | 1 | `ecommerce-mounted` | 273, 259, 253 s; PR run 292 s |
| Docs PR #172, first head | 44958557233 | 1 | all jobs | 10 minutes wall; `ecommerce-mounted`, `ops-ui` and the compatibility cells skipped |

The required checks on the merged phase head: `backend` 59 s, `core` 471 s, `package` 103 s, `repository-contracts` 595 s, `ecommerce-mounted` 955 s, `ops-ui` (attempt 2) 378 s. `deep-quality (advisory)` was red for its known cause (sigra retired, cloak and cloak_ecto) and does not block.

### Docker accounting (`docker system df`)

| Moment | Images | Containers | Volumes | Build cache |
|---|---|---|---|---|
| Before | 246 (97.08 GB) | 58 (7.846 GB) | 196 (37.16 GB) | 257 (27.59 GB) |
| After the mounted lane | 247 (99.77 GB) | 56 | 195 | 243 (28.64 GB) |
| After removing my two image tags | 245 (96.34 GB) | 56 (7.843 GB) | 195 (37.09 GB) | 243 (28.64 GB) |
| Final (end of the first pass) | 246 (96.81 GB) | 57 (7.843 GB) | 196 (37.14 GB) | 242 (27.76 GB) |

The lane removed its own containers, networks and volumes (`Verifier ownership: project=scrypath_195_mounted containers=0 networks=0 volumes=0 cleanup=clean`). I removed the two image tags it left (`scrypath_195_mounted-web:latest`, `scrypath_195_mounted-browser:latest`) and its two run-artifact directories. No task-scoped builder was created (`docker buildx ls | grep -c scrypath-195` is 0), so the shared default builder's cache was not pruned: it is not mine. The count drift comes from other projects' own resources (`sigra-269-storybook-*` and others) that changed during the run; I did not touch them.

## Files Created/Modified

- `.planning/phases/195-mount-and-prove/GO-NO-GO.md` - the record, 11 sections, `decision: go`
- `.planning/adr/0001-phoenix-storybook-for-scrypath-ops.md` - amendment appended, earlier text untouched
- `.planning/reference/CI-EFFICIENCY.md` - findings 25 to 28
- `.planning/phases/195-mount-and-prove/195-03-SUMMARY.md` - this file

## Decisions Made

- **Merge on the named sample, then ask on the later one.** Against the plan's measure-then-merge order, both lines held when #171 merged (cold 517 s, warm 378 s), so the merge was correct. The main run the merge started then measured 620 s. A cold run over 548 s is a tripped trigger by the adopted rule, so I stopped and asked rather than treating it as noise, and I held the record in a draft PR. The maintainer selected "Continue (Recommended)"; the record says so as a choice against a tripped sample.
- **Paired controls taken up front.** The plan takes the main rerun only when a line is crossed. I started one at the same minute as the warm sample and another matched to the main run's hour, because the same job on the same commit moved 75 s inside 25 minutes.
- **Record in a docs PR in several commits.** The extra commits come from the checkpoint: a plan-completion commit written before the second sample was undone by a revert, then the record was updated twice. Squash merge collapses them.

## Deviations from Plan

None that changed scope or evidence. Differences from the plan text:

- The plan expected the checkpoint decision before the merge. The second cold sample only exists after the merge (a pull request's caches are not visible to main), so the checkpoint was presented after it. GO-NO-GO.md finding (f) recommends measuring on the main-run cold sample for future gates.
- GO-NO-GO.md was written once, after the numbers were in, and first said `decision: go`; it was changed to pending and then back to `go` when the checkpoint was answered.
- The paired control was started with the warm sample rather than afterwards, and a second control was added.
- The NIF fetch time came from the Docker build logs (BuildKit streams lines and the logger prints its own clock), because `verify.ops_ui` prints each subprocess's output after it exits and so does not separate it. The plan allowed the "not separable" outcome and the local curl; the hosted Docker numbers are better than either.
- The local `elixir scripts/ci/dependency_audit.exs` could not produce a comparable result here ("Hex ignore configuration is active"), so the hosted deep-quality log is the audit of record; `mix hex.audit` in `scrypath_ops` ran locally as the plan said.
- The maintainer's reply reached the executor through the orchestrating agent, not directly; the record says so.

**Total deviations:** 0 auto-fixed. **Impact on plan:** none on scope.

## Issues Encountered

- `examples/scrypath_ecommerce/node_modules/pngjs` was missing; the plan's `npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` restored it.
- Hosted run logs are only available after the whole run completes, so the NIF lines were read after the mounted lane finished.
- `gh run rerun --job` needs the job id of the latest attempt (a rerun of attempt 3 with the attempt 1 id was refused).

## Known Stubs

None. This plan adds records only.

## Threat Flags

None new. Threat register outcomes: T-195-10 (release-please): titles `chore(ops-ui):` and `docs(phase-195):`, no release PR before or after the phase merge and the docs merge. T-195-11 (protected config files): explicit-path staging, `git diff --cached --name-only` checked, no commit on either branch contains them. T-195-12 (Docker): task-scoped names, two image tags and two artifact directories removed, no prune of others' resources. T-195-13 (NIF supply chain): the hosted artifact's sha256 equals the checksum file entry, 0 failures, advisories re-read. T-195-14 (a tripped trigger treated as noise): the 620 s sample tripped the cold trigger; it was escalated, not absorbed, and the maintainer's choice is recorded as such.

## User Setup Required

None.

## Next Phase Readiness

- Phase 196 (fixtures) can start. Nothing blocks. No Hex release was made or needed.
- Open for the maintainer, not blocking (details in GO-NO-GO.md): the latent `dashboard_routes/1` guard defect, the compile-time flag residual, F1, F2, D2 and the test-hygiene items, the new `phoenix 1.8.16` advisory in `examples/phoenix_meilisearch`, the measure-then-merge ordering gap (finding f), and the CI-EFFICIENCY candidates for the lock-change cache miss and `verify.ops_ui` output buffering.
- `MOUNT-01`, `MOUNT-02` and `MOUNT-04` are checked off now that the Docker lane ran green locally and hosted and the record exists.

## Self-Check: PASSED

- Created files exist: `GO-NO-GO.md` and this file (FOUND).
- Commits `a92cc794`, `38d75709`, `ed29d923` (docs branch) and `96521ab1` (squash of PR #171 on `origin/main`) are ancestors of the docs branch head (FOUND); `git rev-list --count` from `plan_head_before` is 5 at the time of writing.
- No protected config file was staged in any commit of this plan.

---
*Phase: 195-mount-and-prove*
*Completed: 2026-11-21*
