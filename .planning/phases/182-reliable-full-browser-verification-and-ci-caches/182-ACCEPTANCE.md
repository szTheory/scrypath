---
phase: "182"
plan: "08"
status: accepted
source_sha: ec248fd2f7eea9314e600bcc10262729d2cce69e
repository: szTheory/scrypath
branch: worktree-agent-p182-08-1793071051075
session_id: phase182-08-ec248fd2-20261027T175951Z
probe_namespace: candidate-556416f7
---

# Phase 182 — Full browser acceptance

**Final-review repair checkpoint (2026-10-27):** This record preserves the prior EC source evidence. The later final review found three source-level blockers and one readiness warning; eight test/fix commits now correct them at `01d1f871`. Those earlier runs do not prove the corrected source. New local/hosted acceptance and final-root closeout remain pending; no phase completion is claimed. See 182-REVIEW-REPAIR.md.

Frozen implementation: `ec248fd2f7eea9314e600bcc10262729d2cce69e` on `worktree-agent-p182-08-1793071051075`. All six accepted invocations join this repository, source, branch, session and namespace. These records do not relabel implementation evidence for later documentation or root commits. Terminal closeout receipts are kept outside the checkout after all tracked writes.

Session root: `/private/tmp/scrypath-phase182-acceptance/ec248fd2f7eea9314e600bcc10262729d2cce69e/phase182-08-ec248fd2-20261027T175951Z/collector-session`. Authority is the manifest-listed receipt set, not loose files or a green workflow conclusion.

| Mode / run | Cases / attempts | Job through upload / completion (s) | Browser-end to upload (s) | Budget left after upload (s) | Browser artifact / digest |
| --- | --- | --- | --- | --- | --- |
| `docker-warm` [40555796347](https://github.com/szTheory/scrypath/actions/runs/40555796347) | 189 / 189 | 769 / 787 | 21 | 1031 | [12757493261](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12757493261) `sha256:51e0fe74556f84690766b20f388fd270b551b178ae00e9d0022259db2cb89108` |
| `docker-cold` [40557917007](https://github.com/szTheory/scrypath/actions/runs/40557917007) | 189 / 189 | 918 / 932 | 21 | 882 | [12759466349](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12759466349) `sha256:7c3a2da4a8a4116b88ffb7514a8bfc1a1dee7ca47ef68a3404d0349cd4f09244` |
| `beam-fallback` [40560404622](https://github.com/szTheory/scrypath/actions/runs/40560404622) | 189 / 189 | 939 / 952 | 19 | 861 | [12760484360](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12760484360) `sha256:d94cb52d1600fcbd5ef5e0cb2b994e67bf48d8e103dcf9d56f54a9d539194983` |
| `beam-lock-change` [40562897988](https://github.com/szTheory/scrypath/actions/runs/40562897988) | 189 / 189 | 890 / 905 | 20 | 910 | [12762632007](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12762632007) `sha256:d451ff4d9b4d155243d97781a3806e6d855c1335b4f3f6a82106b4b84b595443` |
| `beam-cold` [40565218236](https://github.com/szTheory/scrypath/actions/runs/40565218236) | 189 / 189 | 745 / 762 | 21 | 1055 | [12762584292](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12762584292) `sha256:6d371ddf9ea9bada147ad991cfa0c1f7e8fbcb4fc4824cf84cbf8bb16f6df24b` |
| `full` [40567205001](https://github.com/szTheory/scrypath/actions/runs/40567205001) | 189 / 189 | 762 / 768 | 21 | 1038 | [12764966165](https://api.github.com/repos/szTheory/scrypath/actions/artifacts/12764966165) `sha256:5df443b0440ec229851787e122282be7b389dd236fe83c883a406d11ff7310f6` |

All six hosted receipts report raw verifier success, job success, parity/contrast pass, complete owned artifacts and zero owned containers/networks/volumes after disposal. Source checkout, event, built/runtime images and workflow ref join the selected SHA and branch. No passed retry or skipped case is counted as clean first-pass evidence.

## Final full inventory

| Chromium file | Executed cases |
| --- | --- |
| `admin_contrast_matrix.spec.ts` | 3 |
| `admin_path_motion.spec.ts` | 7 |
| `admin_screenshot_matrix.spec.ts` | 3 |
| `admin_screenshots.spec.ts` | 1 |
| `admin_shell_chrome.spec.ts` | 38 |
| `admin_shell_wash.spec.ts` | 4 |
| `admin_surface_depth.spec.ts` | 38 |
| `harness.spec.ts` | 2 |
| `operator.spec.ts` | 2 |
| `phase1_screens.spec.ts` | 6 |
| `phase173_copy.spec.ts` | 10 |
| `phase173_shell.spec.ts` | 14 |
| `phase173_status_actions.spec.ts` | 6 |
| `phase173_time.spec.ts` | 8 |
| `settings_layout.spec.ts` | 8 |
| `storefront.spec.ts` | 5 |
| `ui_baseline.spec.ts` | 7 |
| `ui_followup.spec.ts` | 7 |
| `ui_iteration3.spec.ts` | 6 |
| `ui_reconciliation.spec.ts` | 14 |

Total: 189 cases / 189 first-attempt passes. This includes mounted and standalone Phase 173 coverage, all seven ui_followup cases and six ui_iteration3 cases. Both actual Ops health routes passed before browser execution.

## Source, image and checker joins

```json
{
  "workflow": {
    "event": "workflow_dispatch",
    "ref": "refs/heads/worktree-agent-p182-08-1793071051075",
    "sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "run_id": "40567205001",
    "run_attempt": 1,
    "job_name": "ecommerce-e2e (advisory)",
    "job_conclusion": "success"
  },
  "source": {
    "mode": "hosted",
    "checkout_head": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "dirty": false,
    "event_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "built_source_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "dirty_fingerprint": null
  },
  "images": {
    "application": {
      "built_id": "sha256:6e4c34741f6d80118249c2c0b082acb6f06b40a84156e8f45429bd7356121b71",
      "runtime_id": "sha256:6e4c34741f6d80118249c2c0b082acb6f06b40a84156e8f45429bd7356121b71",
      "source_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
      "source_fingerprint": null
    },
    "browser": {
      "built_id": "sha256:7e06cc2a8cbf1d50eb90c81ec35d66118ff0d4b38ec09ee2b24db8189ca8ef60",
      "runtime_id": "sha256:7e06cc2a8cbf1d50eb90c81ec35d66118ff0d4b38ec09ee2b24db8189ca8ef60",
      "source_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
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
    "project": "scrypath-e2e-40567205001-1-full",
    "containers": 0,
    "networks": 0,
    "volumes": 0
  }
}
```

## Local canonical proof

```json
{
  "sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
  "source": {
    "mode": "local",
    "checkout_head": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "dirty": false,
    "event_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
    "built_source_sha": "ec248fd2f7eea9314e600bcc10262729d2cce69e",
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
    "startTime": "2026-10-27T18:01:32.284Z",
    "duration": 311015.91099999996,
    "expected": 189,
    "skipped": 0,
    "unexpected": 0,
    "flaky": 0
  },
  "cleanup": {
    "project": "scrypath_verify_full_ec248fd2_local",
    "status": "clean",
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

Exact command: `env BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx E2E_RUN_ID=20261027T1800-ec248fd2-local E2E_PROJECT_NAME=scrypath_verify_full_ec248fd2_local E2E_DOCKER_TIMEOUT_SECONDS=1800 E2E_FINALIZATION_MARGIN_SECONDS=300 make -C examples/scrypath_ecommerce verify-e2e`. The approved 1800-second ceiling and 300-second finalization reserve were used; this local-clean class is not relabeled hosted proof. Preserved local bundle: `/private/tmp/scrypath-phase182-acceptance/ec248fd2f7eea9314e600bcc10262729d2cce69e/local-full`.

## Timing and artifact limits

The whole browser job, including setup/build and upload, remains below 1800 seconds in every accepted run. The maximum observed browser-end-to-upload interval is 21 seconds; observation plus at least 60 seconds remains below the configured 300-second body reserve. Measured remaining time after upload is a separate field, not that configured reserve.

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
node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha ec248fd2f7eea9314e600bcc10262729d2cce69e --session-id phase182-08-ec248fd2-20261027T175951Z --probe-namespace candidate-556416f7 --input /private/tmp/scrypath-phase182-acceptance/ec248fd2f7eea9314e600bcc10262729d2cce69e/phase182-08-ec248fd2-20261027T175951Z/collector-session
```

Result: valid and eligible, six invocations. Full aggregate SHA-256: `5eea4d084636789168491da9aa136cadb23f825029464070641a8a29004e7467`. Manifest SHA-256: `98ecb14f9376e694d221a4d269003e45c9bf5147b2349e8c127343f67affd4c9`. Current source/collector, warning-as-error and repository contract checks passed with 110 Node tests, 961 Elixir tests plus five properties, and 98 repository contracts respectively.

## Preserved history and limits

Earlier candidates and failures remain in `/private/tmp/scrypath-phase182-acceptance` and `/private/tmp/scrypath-phase182-local-e2e-failures`. The earlier e37 six-mode set remains valid only for e37; its recorded documents are preserved at [8b34f545](https://github.com/szTheory/scrypath/tree/8b34f5452e254d9aeda6bc2ed0394304bb5e91b6/.planning/phases/182-reliable-full-browser-verification-and-ci-caches).

Closeout [40551292192](https://github.com/szTheory/scrypath/actions/runs/40551292192) passed its five required jobs, coverage and attestation at 8b34f545, but its full advisory job failed after browser success: the producer wrongly required exports under an ordinary import-only branch policy. Regression `851c0456` reproduced it; `7f8c4592` lets observation generation honor the checked policy while strict warm acceptance still requires actual imports and exports. The immutable old handoff replay reproduces the old failure and corrected behavior; it is not new-source hosted acceptance. Current EC receipts below were obtained after the repair.

Older metadata lag, whole-run log ZIP transport failures, selector/handoff repairs, incomplete 900-second local attempts and their later source revisions are not rewritten as clean stability evidence. Source-bound history and failures remain visible in the prior documents and runtime directories. The known deep-quality dependency audit debt remains Phase 184; this report does not say every advisory CI job is green.

No paid judge, retry/skip masking, automatic baseline rewrite, UI redesign, new dependency, required-lane change or retained-preview mutation was used. This is representative maintainer/demo evidence at the stated source and toolchain, not outside-adopter or universal production reliability evidence. Descriptor-less/unclassified planning assumptions remain flagged as such; no human approval or design review is fabricated.
