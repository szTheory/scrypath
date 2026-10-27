---
phase: "182"
plan: "08"
status: accepted
source_sha: 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8
repository: szTheory/scrypath
branch: worktree-agent-p182-final-review-repair
session_id: phase182-review-repair-0b7fe128-20261027T201345Z
probe_namespace: candidate-556416f7
---

# Phase 182 — Full browser acceptance

Frozen implementation: `0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8` on `worktree-agent-p182-final-review-repair`. All six accepted invocations join this repository, source, branch, session and namespace. These records do not relabel implementation evidence for later documentation or root commits. Terminal closeout receipts are kept outside the checkout after all tracked writes.

Session root: `/private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session`. Authority is the manifest-listed receipt set, not loose files or a green workflow conclusion.

| Mode / run | Cases / attempts | Job through upload / completion (s) | Browser-end to upload (s) | Budget left after upload (s) | Browser artifact / digest |
| --- | --- | --- | --- | --- | --- |
| `docker-warm` [40579526346](https://github.com/szTheory/scrypath/actions/runs/40579526346) | 189 / 189 | 924 / 930 | 21 | 876 | [12769402827](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12769402827) `sha256:84114b7a2a6d680b7b3e9a45294d3a15e15965ae4f3a3dbb3ed01beba71c46b7` |
| `docker-cold` [40581822603](https://github.com/szTheory/scrypath/actions/runs/40581822603) | 189 / 189 | 833 / 845 | 20 | 967 | [12769289741](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12769289741) `sha256:05e36ba7174a99fdfc7a7bc985e3db06818be207a7a6e07fd7c992e6c2a1e916` |
| `beam-fallback` [40583923065](https://github.com/szTheory/scrypath/actions/runs/40583923065) | 189 / 189 | 937 / 950 | 20 | 863 | [12771652393](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12771652393) `sha256:b5b9eb1ea3061d6fd66c5856108253355327beee0dffbe8a4a34d978a49c090e` |
| `beam-lock-change` [40586263728](https://github.com/szTheory/scrypath/actions/runs/40586263728) | 189 / 189 | 813 / 824 | 20 | 987 | [12771069240](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12771069240) `sha256:5a076369d6c2325b19762055fe6b7f742bb448e62f7effe8f4b08528fa1bf36a` |
| `beam-cold` [40588198343](https://github.com/szTheory/scrypath/actions/runs/40588198343) | 189 / 189 | 892 / 905 | 20 | 908 | [12773976518](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12773976518) `sha256:86dfb1c9242e5815d82e9ba182e3aa32f7dff029037936e603baabd67a6449a1` |
| `full` [40590280519](https://github.com/szTheory/scrypath/actions/runs/40590280519) | 189 / 189 | 682 / 689 | 22 | 1118 | [12773662637](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12773662637) `sha256:8eee1f4636c24fbd14d327f09f32ba0be0f5445869fcd25a5de9d7b3f7bf6358` |

All six hosted receipts report raw verifier success, job success, parity/contrast pass, complete owned artifacts and zero owned containers/networks/volumes after disposal. Source checkout, event, built/runtime images and workflow ref join the selected SHA and branch. No passed retry or skipped case is counted as clean first-pass evidence.

## Final full inventory

| Chromium file | Executed cases |
| --- | --- |
| `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` | 3 |
| `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` | 7 |
| `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` | 3 |
| `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts` | 1 |
| `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` | 38 |
| `examples/scrypath_ecommerce/e2e/admin_shell_wash.spec.ts` | 4 |
| `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` | 38 |
| `examples/scrypath_ecommerce/e2e/harness.spec.ts` | 2 |
| `examples/scrypath_ecommerce/e2e/operator.spec.ts` | 2 |
| `examples/scrypath_ecommerce/e2e/phase1_screens.spec.ts` | 6 |
| `examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts` | 10 |
| `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts` | 14 |
| `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts` | 6 |
| `examples/scrypath_ecommerce/e2e/phase173_time.spec.ts` | 8 |
| `examples/scrypath_ecommerce/e2e/settings_layout.spec.ts` | 8 |
| `examples/scrypath_ecommerce/e2e/storefront.spec.ts` | 5 |
| `examples/scrypath_ecommerce/e2e/ui_baseline.spec.ts` | 7 |
| `examples/scrypath_ecommerce/e2e/ui_followup.spec.ts` | 7 |
| `examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts` | 6 |
| `examples/scrypath_ecommerce/e2e/ui_reconciliation.spec.ts` | 14 |

Total: 189 cases / 189 first-attempt passes. This includes mounted and standalone Phase 173 coverage, all seven ui_followup cases and six ui_iteration3 cases. Both actual Ops health routes passed before browser execution.

## Source, image and checker joins

```json
{
  "workflow": {
    "event": "workflow_dispatch",
    "ref": "refs/heads/worktree-agent-p182-final-review-repair",
    "sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "run_id": "40590280519",
    "run_attempt": 1,
    "job_name": "ecommerce-e2e (advisory)",
    "job_conclusion": "success"
  },
  "source": {
    "mode": "hosted",
    "checkout_head": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "dirty": false,
    "event_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "built_source_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "dirty_fingerprint": null
  },
  "images": {
    "application": {
      "built_id": "sha256:2824c2ad0c16179d2124632af4f829c62011a9e4af90d227ebb8d7e1f0e1ac17",
      "runtime_id": "sha256:2824c2ad0c16179d2124632af4f829c62011a9e4af90d227ebb8d7e1f0e1ac17",
      "source_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
      "source_fingerprint": null
    },
    "browser": {
      "built_id": "sha256:a1b1226eba071842f3cc69e9a4566bb2d2974eb1e418a3cc7037d2115e5d7379",
      "runtime_id": "sha256:a1b1226eba071842f3cc69e9a4566bb2d2974eb1e418a3cc7037d2115e5d7379",
      "source_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
      "source_fingerprint": null
    }
  },
  "checkers": {
    "light_parity": {
      "path": "admin-light-parity.json",
      "status": "pass",
      "outcome": "success",
      "missing": 0,
      "extra": 0,
      "width_mismatches": 0
    },
    "contrast": {
      "path": "contrast-report.json",
      "status": "pass",
      "outcome": "success",
      "missing": null,
      "extra": null,
      "width_mismatches": null,
      "aa_fail": 0,
      "total": 101
    }
  },
  "cleanup": {
    "status": "clean",
    "project": "scrypath-e2e-40590280519-1-full",
    "containers": 0,
    "networks": 0,
    "volumes": 0
  }
}
```

## Local canonical proof

```json
{
  "sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
  "source": {
    "mode": "local",
    "checkout_head": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "dirty": false,
    "event_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "built_source_sha": "0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8",
    "dirty_fingerprint": null
  },
  "eligibility": {
    "eligible": true,
    "clean": false,
    "class": "local-clean",
    "status": "pass",
    "reason_count": 0
  },
  "cases": 189,
  "attempts": 189,
  "stats": {
    "startTime": "2026-10-27T20:15:20.641Z",
    "duration": 299381.912,
    "expected": 189,
    "skipped": 0,
    "unexpected": 0,
    "flaky": 0
  },
  "cleanup": {
    "status": "clean",
    "project": "scrypath_verify_full_0b7fe128_local",
    "containers": 0,
    "networks": 0,
    "volumes": 0
  },
  "routes": {
    "status": "passed",
    "routes": {
      "mounted_ops": "passed",
      "standalone_ops": "passed"
    }
  },
  "raw": 0,
  "light": "success",
  "contrast": "success"
}
```

Exact command: `env BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx E2E_RUN_ID=20261027T2014-0b7fe128-local E2E_PROJECT_NAME=scrypath_verify_full_0b7fe128_local E2E_DOCKER_TIMEOUT_SECONDS=1800 E2E_FINALIZATION_MARGIN_SECONDS=300 make -C examples/scrypath_ecommerce verify-e2e`. The approved 1800-second ceiling and 300-second finalization reserve were used; this local-clean class is not relabeled hosted proof. Preserved local bundle: `/private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/local-full`.

## Timing and artifact limits

The whole browser job, including setup/build and upload, remains below 1800 seconds in every accepted run. The maximum observed browser-end-to-upload interval is 22 seconds; observation plus at least 60 seconds remains below the configured 300-second body reserve. Measured remaining time after upload is a separate field, not that configured reserve.

The bounded archives retain complete JSON, HTML, screenshots, iteration-3 captures, health/readiness, service logs, image handoff and lifecycle data. Playwright retain-on-failure is preserved: all accepted cases passed, so no failure trace is claimed. Artifacts have the existing seven-day hosted retention; immutable digests and source/run identities are recorded, and downloaded bytes remain outside the checkout. Functional/parity/contrast passes are not independent design review or paid-judge approval.

## Requirement evidence

| Requirement | Current evidence |
| --- | --- |
| BROW-01 | Complete full graph; both actual mounted/standalone readiness routes and 189-case hosted/local execution. |
| BROW-02 | Docker target guard regressions plus all intended follow-up/iteration-3 identities executed with zero skips/retries. |
| BROW-03 | Exact-source raw success, complete identity/attempt reconciliation, required bounded artifacts, timing and clean disposal. |
| CACHE-01 | Current Docker warm and fresh-builder/import-disabled cold receipts in 182-CACHE-ACCEPTANCE.md. |
| CACHE-02 | Current compatible BEAM fallback, lock-byte invalidation and no-import cold receipts in 182-CACHE-ACCEPTANCE.md. |

## Machine authority

```sh
node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-final-review-repair --sha 0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8 --session-id phase182-review-repair-0b7fe128-20261027T201345Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/0b7fe128d94dd8ac25e923a481f3d8d66ce4e1a8/phase182-review-repair-0b7fe128-20261027T201345Z/collector-session
```

Result: valid and eligible, seven recorded invocations (six eligible). Full aggregate SHA-256: `ab15269997252418901b74f0de5035d70a80d864d8f6e6a9ea9a1e8b56ef22a2`. Manifest SHA-256: `3eba92ebb4d04bc8f11861127c4475dfb4c3e39b9855e35847c455daddabb26d`. Current source/collector, warning-as-error and repository contract checks passed with 115 Node tests, 961 Elixir tests plus five properties, and 98 repository contracts respectively.

## Preserved history and limits

Initial corrected-source run [40576150719](https://github.com/szTheory/scrypath/actions/runs/40576150719) passed browser189/189 but failed warm acceptance because all three imports had zero useful cached vertices. All three exports completed without warnings; actual cache inventory binds the resulting Docker and BEAM caches to the new repair branch. [GitHub cache branch restrictions](https://docs.docker.com/build/cache/backends/gha/#scope) prevented the older worktree branch from seeding this branch. After checking that changed cache state, a new warm consumer was collected in the SAME candidate session. The first ineligible receipt remains in the manifest and atomic attempt history; it is a cache producer, never clean warm acceptance. No browser retry or acceptance predicate was changed.

The EC cohort and final child [40569345202](https://github.com/szTheory/scrypath/actions/runs/40569345202) at f2226d12 passed their recorded predicates and full189/189. Final review then exposed three source-level predicate gaps and a redirect-readiness warning. RED/GREEN commits a64f15d2..01d1f871 fixed loopback refusal, exact required UI identities, canonical changed-lock identity/natural-key proof and 2xx readiness; correction review found zero open findings. Those prior receipts are not proof for the corrected source. The current six-mode cohort below was collected after all four fixes, at one frozen source. Original EC documents remain in Git at f2226d12; original manifests, archives and failed attempts remain outside the checkout.

Earlier candidates and failures remain in `/private/tmp/scrypath-phase182-acceptance` and `/private/tmp/scrypath-phase182-local-e2e-failures`. The earlier e37 six-mode set remains valid only for e37; its recorded documents are preserved at [8b34f545](https://github.com/szTheory/scrypath/tree/8b34f5452e254d9aeda6bc2ed0394304bb5e91b6/.planning/phases/182-reliable-full-browser-verification-and-ci-caches).

Closeout [40551292192](https://github.com/szTheory/scrypath/actions/runs/40551292192) passed its five required jobs, coverage and attestation at 8b34f545, but its full advisory job failed after browser success: the producer wrongly required exports under an ordinary import-only branch policy. Regression `851c0456` reproduced it; `7f8c4592` lets observation generation honor the checked policy while strict warm acceptance still requires actual imports and exports. The immutable old handoff replay reproduces the old failure and corrected behavior; it is not new-source hosted acceptance. The later EC receipts established that correction at their own source.

Older metadata lag, whole-run log ZIP transport failures, selector/handoff repairs, incomplete 900-second local attempts and their later source revisions are not rewritten as clean stability evidence. Source-bound history and failures remain visible in the prior documents and runtime directories. The known deep-quality dependency audit debt remains Phase 184; this report does not say every advisory CI job is green.

No paid judge, retry/skip masking, automatic baseline rewrite, UI redesign, new dependency, required-lane change or retained-preview mutation was used. This is representative maintainer/demo evidence at the stated source and toolchain, not outside-adopter or universal production reliability evidence. Descriptor-less/unclassified planning assumptions remain flagged as such; no human approval or design review is fabricated.
