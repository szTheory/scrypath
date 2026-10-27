---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "08"
subsystem: ci
tags: [github-actions, docker-buildx, beam-cache, playwright, exact-sha]
requires: [182-07]
actuals:
  tasks: 2
  commits: 84
plan_head_before: 532686900769264eea618e5c9a1a681014d09b1f
plan_head_after: caeb197876f8fc2437040ef2752c70881fac7bef
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
    - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
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
current_browser_source_sha: 1c72637038f2c225d56e2311678b05f912b014f3
retained_cache_source_sha: 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8
requirements-completed: [BROW-01, BROW-02, BROW-03, CACHE-01, CACHE-02]
coverage:
  - id: D1
    requirement: BROW-01
    description: "BROW-01 has source-bound executable evidence with named invalidators recorded."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 1c72637038f2c225d56e2311678b05f912b014f3 --session-id phase182-assertion-1c726370-20261027T224427Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/1c72637038f2c225d56e2311678b05f912b014f3/phase182-assertion-1c726370-20261027T224427Z/collector-session"
        status: pass
    human_judgment: false
  - id: D2
    requirement: BROW-02
    description: "BROW-02 has source-bound executable evidence with named invalidators recorded."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 1c72637038f2c225d56e2311678b05f912b014f3 --session-id phase182-assertion-1c726370-20261027T224427Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/1c72637038f2c225d56e2311678b05f912b014f3/phase182-assertion-1c726370-20261027T224427Z/collector-session"
        status: pass
    human_judgment: false
  - id: D3
    requirement: BROW-03
    description: "BROW-03 has source-bound executable evidence with named invalidators recorded."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 1c72637038f2c225d56e2311678b05f912b014f3 --session-id phase182-assertion-1c726370-20261027T224427Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/1c72637038f2c225d56e2311678b05f912b014f3/phase182-assertion-1c726370-20261027T224427Z/collector-session"
        status: pass
    human_judgment: false
  - id: D4
    requirement: CACHE-01
    description: "CACHE-01 has source-bound executable evidence with named invalidators recorded."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
  - id: D5
    requirement: CACHE-02
    description: "CACHE-02 has source-bound executable evidence with named invalidators recorded."
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session"
        status: pass
    human_judgment: false
completed: 2026-10-27
status: complete
---

# Phase 182 Plan 08 — Source-bound cache and full browser acceptance

The five cache scenarios passed at 0b7 and retain that exact cutoff. Following the final review's inherited WR-02 assertion correction, local full and hosted warm/full passed at `1c72637038f2c225d56e2311678b05f912b014f3`: each current hosted run 189 distinct cases/189 first attempts, no skipped/retried/flaky/unexpected outcomes, required artifacts and clean disposal. The current warm/full session is distinct from the earlier seven-invocation cache session; neither is relabeled.

## Task outcomes

1. Cache acceptance: all five scenarios in 182-CACHE-ACCEPTANCE.md are bound to 0b7. The additional current strict warm receipt proves useful remote reuse/export for the changed browser image input.
2. Browser acceptance: 182-ACCEPTANCE.md records current local and hosted full 189/189, both routes, all 13 required follow-up/iteration3 identities, source/image/ref joins, parity/contrast, bounded timing and disposal.

## Evidence reuse and invalidators

The only non-planning change from `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` to `1c72637038f2c225d56e2311678b05f912b014f3` is the WR-02 settings assertion line in `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts` (fix `30becbc4`). It now uses an actual RegExp for both rendered status strings; it cannot pass by locating numeric text. The source-derived RED/GREEN logs and 115 passing Node checks are retained outside the checkout.

PROJECT's named-invalidator policy reuses passing evidence within its source/scenario boundaries. Cache implementation/configuration, Dockerfiles, dependencies/locks and BEAM graph inputs are unchanged. An exact file-tree comparison excluding only that spec passed; rebuilding the original hosted BEAM identity from current input bytes produced the identical manifest, lock and source digests (this is input parity at the original tuple, not a new hosted BEAM run). The spec is outside all four BEAM source graphs. The changed browser image input is covered by the new strict warm receipt; local and hosted full execution cover the stronger assertion.

The complete five-mode cache aggregate remains valid at `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` with seven recorded invocations (six eligible). The new two-invocation session at `1c72637038f2c225d56e2311678b05f912b014f3` has a strict eligible warm receipt and a valid full aggregate. No five-mode cache aggregate at the newer SHA is claimed, no receipts cross source/session identities, and no acceptance predicate was changed. Earlier full passes are not relabeled as proof of the corrected assertion.

## Current verification

| Mode/run | Cases/attempts | Through upload/job(s) | Finalization(s) | Budget left(s) | Browser artifact |
| --- | --- | --- | --- | --- | --- |
| `docker-warm` [40597095307](https://github.com/szTheory/scrypath/actions/runs/40597095307) | 189/189 | 873/887 | 22 | 927 | [12777860977](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12777860977) `sha256:adc96a02e1b7bcff831169b13460272878c16d7c5aab7450e9054f0c641586a5` |
| `full` [40598906757](https://github.com/szTheory/scrypath/actions/runs/40598906757) | 189/189 | 812/817 | 22 | 988 | [12779125946](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12779125946) `sha256:264dba5b4ad68ed883605aed0b6b586200ea2e872eb7a6a6c163d37b858c3f42` |

Local canonical full: 189/189, source-clean local class (not hosted), parity/contrast pass and zero owned resources. Node behavior checks 115/115. Before the one-line TS assertion change, fresh merged Elixir 961 tests plus five properties and repository 98, formatting/actionlint/docs passed; those inputs are unchanged. Current source hosted required jobs are recorded by their real workflow runs, and final merged/root checks are separately verified.

Current maximum browser-end-to-upload interval 22s plus 60s fits the configured 300s reserve. Job durations 817–887s stay below 1800. Retention remains seven days.

## Canonical commands

```sh
node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session
node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 1c72637038f2c225d56e2311678b05f912b014f3 --session-id phase182-assertion-1c726370-20261027T224427Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/1c72637038f2c225d56e2311678b05f912b014f3/phase182-assertion-1c726370-20261027T224427Z/collector-session
```

## Review disposition and history

Original CR-01/02/03 and WR-01 plus WR-02 are fixed with executable evidence; WR-03 remains the explicitly deferred baseline-only same-run rerun artifact naming limitation. It is not a human approval or blanket risk acceptance. Fresh closeout dispatches use distinct runs, and retries cannot become clean stability evidence. The known dependency-audit debt remains Phase 184. No all-advisory-green, independent design approval, main merge, public release or outside-adopter reliability claim is made.

All original failures, initial no-hit producer, old candidates, source-bound archives and correction history remain in the acceptance records, REVIEW-REPAIR and Git. The full 24 review and scoped correction are not fabricated as human review. No baseline rewrite, paid judge, skip/retry masking or retained-preview mutation was used.

## Commits since plan entry

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
| `c4cb1eaf` | docs(182): checkpoint reviewed repair source and live acceptance |
| `2ef2490d` | docs(182-08): record corrected-source cache acceptance |
| `fd8cb869` | docs(182-08): record corrected-source full browser acceptance |
| `cac11859` | docs(182-08): reconcile reviewed repairs and completed acceptance |
| `542da333` | chore: merge executor worktree (worktree-agent-p182-final-review-repair) |
| `995001a9` | docs(182): checkpoint merged repairs and verified source evidence |
| `bbeeca50` | docs(182): validate all task coverage at corrected source |
| `5515ffa8` | docs(182): verify authored security mitigations after repairs |
| `b5c41c6d` | docs(182): review final UI applicability without design claims |
| `18cccbbc` | docs(182): record code review disposition |
| `0206068c` | docs(182): record code review disposition |
| `e43fdf16` | docs(182): checkpoint scoped assertion follow-up and inherited rerun warning |
| `30becbc4` | test(182): assert the actual Meilisearch settings status |
| `f83b84e9` | docs(182): bind assertion follow-up to named browser invalidators |
| `b1916d38` | docs(182): record code review disposition |
| `ca0953d2` | docs(182): review corrected settings assertion and retain rerun warning |
| `2abfcf8e` | docs(182): record code review disposition |
| `1c726370` | docs(182): preserve canonical deferred finding identity |
| `78af98e7` | docs(182-08): retain cache cutoff and add current warm image proof |
| `caeb1978` | docs(182-08): record corrected assertion browser acceptance |

This metadata commit is absent from its own table. Entire-plan duration/token use was not measured reliably; no source-size proxy is used. Actual current batch timestamps are in its control.

## Handoff

Current source-bound records and canonical validators pass. Terminal child closeout must run after all tracked writes at the actual documentation head, with raw browser/default-policy proof checked separately from required gates. Root then merges through GSD, checks parity and applicable hooks/goal verification, transitions tracking and obtains its own final exact-head closeout. Phase completion is not claimed by this plan summary alone.
