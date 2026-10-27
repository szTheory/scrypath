---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "08"
subsystem: ci
tags: [github-actions, docker-buildx, beam-cache, playwright, exact-sha]
requires: [182-07]
provides:
  - Exact-source real cache and complete browser acceptance with preserved failure history.
affects: [ci, contributor-verification, phase-182-closeout]
actuals:
  tasks: 2
  commits: 66
plan_head_before: 532686900769264eea618e5c9a1a681014d09b1f
plan_head_after: fd8cb869d56ec9e8c5902bb745a0387f4422bf7b
key-files:
  created:
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-08-SUMMARY.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-ACCEPTANCE.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-CACHE-ACCEPTANCE.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-REVIEW-DISPOSITION.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-REVIEW-REPAIR.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-REVIEW.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-SECURITY.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-UI-REVIEW.md
  modified:
    - .github/workflows/ci.yml
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-VALIDATION.md
    - CONTRIBUTING.md
    - examples/scrypath_ecommerce/compose.e2e.yaml
    - examples/scrypath_ecommerce/docker-playwright.sh
    - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
    - examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs
    - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - scripts/ci/ecommerce_build.cjs
    - scripts/ci/ecommerce_build.test.cjs
    - scripts/ci/ecommerce_evidence.cjs
    - scripts/ci/ecommerce_evidence.test.cjs
    - scripts/ci/ecommerce_lifecycle.test.cjs
    - scripts/ci/ecommerce_target.test.cjs
    - scripts/ci/phase182_acceptance.cjs
    - scripts/ci/phase182_acceptance.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs
requirements-completed: [BROW-01, BROW-02, BROW-03, CACHE-01, CACHE-02]
coverage:
  - id: D1
    requirement: BROW-01
    description: "Exact-source BROW-01 behavior is covered by current machine receipts and executable contracts."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
  - id: D2
    requirement: BROW-02
    description: "Exact-source BROW-02 behavior is covered by current machine receipts and executable contracts."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
  - id: D3
    requirement: BROW-03
    description: "Exact-source BROW-03 behavior is covered by current machine receipts and executable contracts."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
  - id: D4
    requirement: CACHE-01
    description: "Exact-source CACHE-01 behavior is covered by current machine receipts and executable contracts."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
  - id: D5
    requirement: CACHE-02
    description: "Exact-source CACHE-02 behavior is covered by current machine receipts and executable contracts."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
completed: 2026-10-27
status: complete
---

# Phase 182 Plan 08 — Real browser and cache acceptance

All five cache scenarios and the final full collection passed at `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8`. Each of six hosted invocations completed 189 cases in 189 first-pass attempts, with raw verifier success, exact source/image/ref joins, required artifacts and clean owned disposal. Both canonical aggregate validators returned eligible with seven recorded invocations (six eligible).

## Task outcomes

1. Cache acceptance: [182-CACHE-ACCEPTANCE.md](182-CACHE-ACCEPTANCE.md) records real warm imports/useful hits/exports, fresh-builder no-import cold execution, compatible BEAM download fallback, changed-lock compiled invalidation and representative no-import BEAM cold execution.
2. Browser acceptance: [182-ACCEPTANCE.md](182-ACCEPTANCE.md) records the complete local and hosted inventory, both fixture routes, all seven follow-up and six iteration-3 cases, source/image joins, artifacts and measured budget.

## Verification

- Node CI behavior suite: 115 tests, zero failures/skips (`/private/tmp/scrypath-phase182-execution/final-review-repair-node.log`).
- Warning-as-error root suite: 961 tests plus five properties, zero failures (`/private/tmp/scrypath-phase182-execution/review-repair-standard-tests.log`).
- Repository contracts: 98 tests, zero failures (`/private/tmp/scrypath-phase182-execution/review-repair-repository-contracts.log`).
- Canonical local full: 189/189, skipped/unexpected/flaky zero, parity/contrast and both routes pass, owned containers/networks/volumes zero.
- Six current-source hosted invocations: 189/189 each, nonpass zero and clean disposal.
- Strict cache and full aggregate validators: valid/eligible, seven recorded invocations (six eligible).
- CI-version formatting, actionlint and warnings-as-errors docs passed earlier; their relevant source paths did not change afterward.

The configured body-finalization reserve is 300 seconds. The observed maximum browser-end-to-upload interval is 22 seconds; adding the required 60-second margin remains below 300. Remaining budget after upload ranges from 863 to 1118 seconds. Whole full-job duration and upload timings are recorded separately.

## Task commits

| Commit | Change |
| --- | --- |
| `9ef84888` | fix(182-08): preserve run-scoped browser evidence |
| `24a97406` | test(182-08): align artifact path contract |
| `2ab82a4a` | fix(182-08): target fields disclosure by structure |
| `770b10e3` | fix(182-08): disambiguate nested result disclosures |
| `e627e47a` | fix(182-08): tolerate disclosure label whitespace |
| `4c84ec14` | fix(182-08): preserve and validate full evidence receipts |
| `2dc1f0b0` | fix(182-08): await saved-search picker closure |
| `aa637a9e` | fix(182-08): repair hosted image handoff checks |
| `57d81cd8` | fix(182-08): stabilize hosted Compose handoffs |
| `f85b960c` | fix(182-08): pull runtime dependencies for mounted proof |
| `96c23e65` | fix(182-08): validate hosted artifact contracts |
| `0b62d50e` | fix(182-08): parse GitHub-prefixed BuildKit cache logs |
| `f4db59b8` | fix(182-08): bind cache hits to exact recipe outputs |
| `86eff19e` | fix(182-08): preserve cache probe identity during handoff |
| `dde08b5d` | fix(182-08): pass cache probe scope to E2E verifier |
| `b8cb4035` | fix(182-08): namespace trusted BEAM seed caches |
| `9d9ba977` | test(182-08): reproduce lagging Actions metadata |
| `5f250d1f` | fix(182-08): await complete Actions metadata |
| `8ac1c4e8` | docs(182-08): record early evidence contract review |
| `fc72cb77` | test(182-08): reject foreign browser workflow refs |
| `ed6d2f3c` | fix(182-08): bind browser proof to selected workflow ref |
| `6f2f2970` | test(182-08): reproduce unbound cache namespace selection |
| `b35b0441` | fix(182-08): bind cache evidence to requested namespace |
| `dac69aeb` | docs(182-08): record follow-up provenance review |
| `4f75605c` | test(182-08): reproduce validation CLI namespace loss |
| `d4b8fc0c` | fix(182-08): preserve namespace in validation CLI |
| `c0cbfa27` | docs(182-08): close reviewed provenance findings |
| `c5a6840e` | test(182-08): reproduce full aggregate receipt selection bug |
| `b309d0d1` | fix(182-08): validate full aggregate using parsed receipts |
| `556416f7` | docs(182-08): record full source review and fixed findings |
| `28e1b770` | test(182-08): reproduce whole-run log download failure |
| `53f51a8f` | fix(182-08): download logs directly for selected jobs |
| `2ca0bb05` | test(182-08): cover raw REST BuildKit log timestamps |
| `8c2f1f38` | fix(182-08): parse timestamped job logs without changing raw hashes |
| `e37f5bde` | docs(182-08): review direct job-log transport |
| `6c6bbdd3` | docs(182-08): record actual cache acceptance |
| `b87660a7` | docs(182-08): record full browser acceptance |
| `48f427d7` | docs(182-08): complete reliable browser and cache acceptance |
| `87e944de` | docs(182-08): correct warm receipt digest |
| `8b34f545` | docs(182-08): finalize accepted plan summary |
| `851c0456` | test(182-08): reproduce import-only observation rejection |
| `7f8c4592` | fix(182-08): observe configured Docker cache policy without granting acceptance |
| `ec248fd2` | docs(182-08): preserve prior evidence and reopen policy follow-up |
| `51ceb707` | docs(182-08): record corrected-source real cache acceptance |
| `e6297735` | docs(182-08): record corrected-source complete browser acceptance |
| `f2226d12` | docs(182-08): reconcile final cache and browser acceptance |
| `0c80e5b0` | chore: merge executor worktree (worktree-agent-p182-08-1793071051075) |
| `839c9790` | docs(182): validate automated task and integration coverage |
| `38c46040` | docs(182): verify authored security mitigations at ASVS L1 |
| `e6c330fe` | docs(182): record UI review applicability and evidence limits |
| `8ec30e76` | docs(182): record code review disposition |
| `f08def5d` | docs(182): record code review disposition |
| `1f62e23c` | docs(182): retain final review findings for scoped repairs |
| `5918efd3` | docs(182): checkpoint merged plans and final review repair scope |
| `a64f15d2` | test(182): reproduce loopback preview guard bypasses |
| `b6bf7bf0` | fix(182): refuse all loopback preview targets before mutation |
| `61a9346d` | test(182): reject redirect-only fixture readiness |
| `2f615705` | fix(182): require successful HTTP status for fixture readiness |
| `32352d69` | test(182): require every intended follow-up and iteration identity |
| `edd47eee` | fix(182): enforce complete intended UI case identities |
| `b112131d` | test(182): reproduce unbound and forced lock invalidation proof |
| `01d1f871` | fix(182): bind lock invalidation to canonical bytes and natural keys |
| `762baf30` | docs(182): preserve prior proof and record final review repairs |
| `0b7fe128` | docs(182): review and close final source predicate findings |
| `2ef2490d` | docs(182-08): record corrected-source cache acceptance |
| `fd8cb869` | docs(182-08): record corrected-source full browser acceptance |

The following summary metadata commit is intentionally absent from its own commit table. Entire-plan token use and duration were not measured reliably across handoffs; no source-size proxy is presented as harness tokens. The current batch timestamps are in its persisted control file.

## Acceptance-driven repairs and deviations

Real runs exposed stale selectors, artifact/Compose/image identity mismatches, GitHub API metadata lag/shape differences, deduplicated BuildKit progress, scoped mode/namespace propagation, aggregate receipt selection, log transport and policy/eligibility coupling. They were repaired through scoped bug/blocker fixes and executable regressions, not by dropping cases or weakening assertions. Current strict acceptance retains all source/ref/namespace/digest joins and actual cache evidence.

The final producer-policy repair lets ordinary import-only runs emit honest observations while strict warm acceptance continues to require actual imports and exports. Old 8b34 advisory failure remains recorded; it was not waived as Phase 184 debt.

## Preserved history and limits

Initial corrected-source run [40576150719](https://github.com/szTheory/scrypath/actions/runs/40576150719) passed browser189/189 but failed warm acceptance because all three imports had zero useful cached vertices. All three exports completed without warnings; actual cache inventory binds the resulting Docker and BEAM caches to the new repair branch. [GitHub cache branch restrictions](https://docs.docker.com/build/cache/backends/gha/#scope) prevented the older worktree branch from seeding this branch. After checking that changed cache state, a new warm consumer was collected in the SAME candidate session. The first ineligible receipt remains in the manifest and atomic attempt history; it is a cache producer, never clean warm acceptance. No browser retry or acceptance predicate was changed.

The EC cohort and final child [40569345202](https://github.com/szTheory/scrypath/actions/runs/40569345202) at f2226d12 passed their recorded predicates and full189/189. Final review then exposed three source-level predicate gaps and a redirect-readiness warning. RED/GREEN commits a64f15d2..01d1f871 fixed loopback refusal, exact required UI identities, canonical changed-lock identity/natural-key proof and 2xx readiness; correction review found zero open findings. Those prior receipts are not proof for the corrected source. The current six-mode cohort below was collected after all four fixes, at one frozen source. Original EC documents remain in Git at f2226d12; original manifests, archives and failed attempts remain outside the checkout.

Earlier candidates and failures remain in `/private/tmp/scrypath-phase182-acceptance` and `/private/tmp/scrypath-phase182-local-e2e-failures`. The earlier e37 six-mode set remains valid only for e37; its recorded documents are preserved at [8b34f545](https://github.com/szTheory/scrypath/tree/8b34f5452e254d9aeda6bc2ed0394304bb5e91b6/.planning/phases/182-reliable-full-browser-verification-and-ci-caches).

Closeout [40551292192](https://github.com/szTheory/scrypath/actions/runs/40551292192) passed its five required jobs, coverage and attestation at 8b34f545, but its full advisory job failed after browser success: the producer wrongly required exports under an ordinary import-only branch policy. Regression `851c0456` reproduced it; `7f8c4592` lets observation generation honor the checked policy while strict warm acceptance still requires actual imports and exports. The immutable old handoff replay reproduces the old failure and corrected behavior; it is not new-source hosted acceptance. The later EC receipts established that correction at their own source.

Older metadata lag, whole-run log ZIP transport failures, selector/handoff repairs, incomplete 900-second local attempts and their later source revisions are not rewritten as clean stability evidence. Source-bound history and failures remain visible in the prior documents and runtime directories. The known deep-quality dependency audit debt remains Phase 184; this report does not say every advisory CI job is green.

No paid judge, retry/skip masking, automatic baseline rewrite, UI redesign, new dependency, required-lane change or retained-preview mutation was used. This is representative maintainer/demo evidence at the stated source and toolchain, not outside-adopter or universal production reliability evidence. Descriptor-less/unclassified planning assumptions remain flagged as such; no human approval or design review is fabricated.

## Self-check and handoff

Both acceptance records exist, all listed commits are reachable, current implementation is unchanged from the corrected frozen source, and both canonical validators pass. Configuration and shared STATE/ROADMAP/REQUIREMENTS/PROJECT tracking were preserved in this checkout. Terminal closeout runs after all these tracked writes at the actual documentation head; its runtime receipt and default full-job outcome must be checked before merging. Root later performs phase-level hooks, verification, shared tracking and a separate final-root-SHA closeout.
