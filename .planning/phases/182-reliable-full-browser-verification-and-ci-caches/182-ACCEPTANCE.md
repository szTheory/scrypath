
> Historical evidence checkpoint: the receipts below belong to frozen implementation `e37f5bde914d123f0bf7dcb9c12daec64d465657`. Worktree closeout `40551292192` at `8b34f5452e254d9aeda6bc2ed0394304bb5e91b6` passed required gates but exposed a default import-only cache observation defect after browser success. The subsequent producer-policy repair requires fresh acceptance; these receipts are not relabeled for the new source.

# Phase 182 browser acceptance

## Source and session identity

The accepted implementation candidate is `e37f5bde914d123f0bf7dcb9c12daec64d465657`, on `worktree-agent-p182-08-1793071051075`, repository `szTheory/scrypath`. All five cache-mode runs and the separate full run were `workflow_dispatch` runs for that branch and SHA, in the single session `phase182-08-e37f5bde-20261027T154542Z` and namespace `candidate-556416f7`. The selected run, attempt, event, checkout, build, and aggregate identities agree; every hosted receipt has `dirty: false`, exact event/build/checkout SHA, and application/browser built image IDs equal to their runtime IDs.

The collector root is `/private/tmp/scrypath-phase182-acceptance/e37f5bde914d123f0bf7dcb9c12daec64d465657/phase182-08-e37f5bde-20261027T154542Z/collector-session/`. Its manifest is SHA-256 `92a50e6df2e99ed1598cecf387ae32c390a4125e4aeedb79d0c5d37324978a1d`. The cache aggregate is SHA-256 `d86b6d7a296704f30aea9901fd7c3d23633c15f9f46451dd906b30b9d9e72421`; the full aggregate is SHA-256 `5f0dfab4fc52bf6fcde07df5a807acc4c34634d99a87ed94f6f150345e589b7e`. Both were validated from the session root with explicit repo, branch, SHA, session, and namespace arguments; each returned `valid: true`, `eligible: true`, and six invocations. The raw receipts and bytes, rather than the derived `acceptance-facts.cjs` convenience output, remain authority.

## Hosted browser receipts

Each selected mode has a successful raw `ecommerce-e2e (advisory)` outcome for the full 189-case Chromium inventory. Each recorded 189 cases and 189 total attempts, with every case passing on retry 0; there were no skipped, failed, unexpected, or flaky outcomes. All five required jobs, the coverage job, and `closeout-attestation` succeeded in every accepted workflow. The exact selected attempts and downloaded browser artifacts are:

| Mode | Run / attempt | Workflow elapsed to completion | Browser archive SHA-256 | Browser job log SHA-256 | Collector receipt SHA-256 |
|---|---|---:|---|---|---|
| `docker-warm` | [40534189615](https://github.com/szTheory/scrypath/actions/runs/40534189615) / 1 | 829 s | `39c61c9a9689592eabc9a04956d9af57eeac7dd7089f2631c24dc36782243b8a` | `d2ba3cc313baf11317e8ec3845b8d9e2fd9689c3e21c71cd698cb161db9863ac` | `f497e12d9d5af1fe196adf389392ae7a4241306a0ff2035712e8076457087a6a` |
| `docker-cold` | [40536521371](https://github.com/szTheory/scrypath/actions/runs/40536521371) / 1 | 757 s | `ac486868269ec4c0be6c066f11a2d6ec59fd3f8332caa08b3e8c3101fa07f271` | `d41bc8468f2f1313b6503668dce5ac60eef9d707fab93de2867af911a4e06ea1` | `e57eb192bc94b0dc3ca9b3303884dd32dfe8d78effaa4e298887dfc8b33b422e` |
| `beam-fallback` | [40538671636](https://github.com/szTheory/scrypath/actions/runs/40538671636) / 1 | 722 s | `1d449aea5ae0c6b81b252632bc9cedd389bdac78c7f2264d419f63ca33d9ddb0` | `179750320ef87c2bde239f996ec18cb3c87531c8d26712d1d2e8d7872789e94f` | `54bfd4b05d56b3c4d9ba465b510d45748034fcba884879afd6ad8c8f807268a2` |
| `beam-lock-change` | [40540687164](https://github.com/szTheory/scrypath/actions/runs/40540687164) / 1 | 903 s | `64625411423ffb7aa0b6552a0038a1f5f08d117c51c826b0478e388302665684` | `b49cedcefe6b1db74bdb5c4378d4b5d714cf69a3887d3d8f6323baea14a9b3da` | `2371db50e1ff1d1a4b61519a0e907890c5029a78f21effad4038e1e0940a51b5` |
| `beam-cold` | [40543183784](https://github.com/szTheory/scrypath/actions/runs/40543183784) / 1 | 936 s | `d1aa56d6a31ee1426d2bc2d8653798d718b4527193ee3759276e7ab4f9102eeb` | `89bebea87908d885ebdcd37d59348c851b4d205bcfff0fd3baa2d51fc42b13d7` | `770bd144ad677862695fb46ace9adc2fdf103ba83e729c8642060549d862e8fd` |
| `full` | [40545747370](https://github.com/szTheory/scrypath/actions/runs/40545747370) / 1 | 826 s | `cbe29294bcc1c949016fccd2664dc5bfb23a371dd445eb64336280e335c7f7e1` | `40393fac23638055f25d8e3963f3ed15e7decf14c72833cd252be17155507dda` | `fd40fd7444d24c4c893970399baded143a4470fa555a7cf5e708d69a7ab5bb5b` |

The full run was a manual `workflow_dispatch` at the changed source SHA; it is not described as a scheduled run. The full browser archive is named `ecommerce-e2e-evidence-40545747370-1`. Its downloaded bytes match the immutable digest above. It contains 186 entries: the JSON evidence and Playwright reports, HTML report, 157 screenshots (including 14 iteration3 journey screenshots), lifecycle/compose/browser/parity/contrast/finalization logs, and the artifact manifest. The test configuration uses Playwright `trace: "retain-on-failure"`; no trace file was emitted because all cases passed. No failure trace is claimed. The archive includes both fixture route readiness outcomes and artifact-copy status.

## Complete browser inventory

The actual inventory contains 189 tests in 20 spec files. The entrypoint split is 173 `shared`, 1 `both`, 8 `mounted`, and 7 `standalone`. The Phase 173 specs account for 38 cases across the mounted and standalone routes. Both `ui_followup.spec.ts` cases (7) and `ui_iteration3.spec.ts` cases (6) are present and passed.

| Spec file | Cases |
|---|---:|
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
| **Total** | **189** |

The run-owned full archive includes all 14 iteration3 journey screenshots. It also retains health/readiness, browser, Compose, parity, contrast, and finalization logs alongside the inventory, JSON evidence, HTML report, and screenshots. The current `unknown_backend` rendered assertion in `admin_screenshots.spec.ts` is included in the 189-case inventory and passed with the suite. Every accepted browser evidence receipt reports raw verifier outcome `success`, browser job conclusion `success`, successful artifact copy, the deterministic light checker with 30 expected/checked, 0 missing, 0 extra, and 0 width mismatches, and the contrast checker with 101 measured pairs and 0 AA failures.

## Canonical local full proof

The exact unfiltered local canonical command completed successfully at the same frozen source SHA:

```sh
env BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx \
  E2E_RUN_ID=20261027T1548-e37f5bde-local \
  E2E_PROJECT_NAME=scrypath_verify_full_e37f5bde_local \
  E2E_DOCKER_TIMEOUT_SECONDS=1800 \
  E2E_FINALIZATION_MARGIN_SECONDS=300 \
  make -C examples/scrypath_ecommerce verify-e2e
```

The local record reports 189 expected and executed tests, 189 attempts, all 189 passed on their first attempt, skipped/unexpected/flaky counts of 0, light parity and contrast success, mounted and standalone Ops readiness both passed, artifact copy passed, and cleanup clean with 0 containers, networks, or volumes. The Playwright browser stage measured `298986.883 ms`; the command used the already-approved 1800-second full-job ceiling and a 300-second configured body-finalization reserve. Its eligibility class is `local-clean` with `clean: false`; this is local integration proof and is not relabeled as hosted proof.

Local machine evidence remains under `/private/tmp/scrypath-phase182-acceptance/e37f5bde914d123f0bf7dcb9c12daec64d465657/local-full/`:

- `phase105-evidence.json` SHA-256: `706eb395d71668258be94f9f9f3c4c321d045f2c9dcdbc85b11b12cffd0b89ff`
- `phase105-playwright.json` SHA-256: `12b6c11d4f3ba570f5b6851f7bde55907f3ac8c966b4f1a561836bf852c80117`
- `artifact-manifest.json` SHA-256: `2b648f3d6d6054c95d0c07b3f8d498d0e426436b9858522d9529293d53f51ec8`
- `lifecycle.json` SHA-256: `55fdaa6120797d362e76ce89e853b1462df0de95b45c5b737d8535565e934e39`

The local artifact manifest records successful bounded copy and 166 copied files, including 14 iteration3 journey screenshots. As with hosted evidence, no trace was generated because the full run passed and the configured policy retains traces only on failure.

## Runtime and finalization margin

Workflow elapsed is measured from the selected Actions run's `started_at` through `completed_at`, including job upload and workflow completion. The receipt's `finalization_reserve_seconds` is the remaining portion of the 1800-second budget after the browser evidence upload; it is distinct from the configured 300-second body-finalization reserve.

| Mode | Workflow elapsed through completion | Browser stage end to artifact upload | 1800-second budget remaining after upload |
|---|---:|---:|---:|
| `docker-warm` | 829 s | 20 s | 988 s |
| `docker-cold` | 757 s | 21 s | 1066 s |
| `beam-fallback` | 722 s | 20 s | 1100 s |
| `beam-lock-change` | 903 s | 20 s | 933 s |
| `beam-cold` | 936 s | 21 s | 884 s |
| `full` | 826 s | 20 s | 985 s |

The longest observed browser-stage-end-to-upload interval was 21 seconds. The configured 300-second reserve exceeds that by 279 seconds and leaves 219 seconds beyond the required 60-second safety margin. The full run had 985 seconds of the 1800-second budget remaining after upload; the lowest remaining budget across all six runs was 884 seconds. Every entire workflow completed within the approved 1800-second ceiling. The earlier shorter-deadline local failures remain recorded; they are not rewritten as passes.

## Requirement mapping

| Requirement | Evidence and result |
|---|---|
| **BROW-01** | The canonical unfiltered local `make ... verify-e2e` passed at e37 and proved both mounted and standalone Ops readiness routes in the full Compose model. Hosted full-mode run 40545747370 also passed its exact-source browser proof. |
| **BROW-02** | The executable inventory includes all 7 `ui_followup` and all 6 `ui_iteration3` cases; every case passed on its first attempt in the full inventory. Their run-owned screenshot artifacts were copied and included. |
| **BROW-03** | Full manual hosted run 40545747370 at e37 has raw verifier `success`, exact workflow/event/checkout/build/runtime SHA and image joins, 189/189 first-attempt success, complete bounded artifacts, 826-second workflow elapsed, and clean owned disposal. |
| **CACHE-01** | [182-CACHE-ACCEPTANCE.md](./182-CACHE-ACCEPTANCE.md) records exact-source real three-target Docker warm import/useful reuse/export plus fresh-builder mounted cold proof with imports disabled. |
| **CACHE-02** | [182-CACHE-ACCEPTANCE.md](./182-CACHE-ACCEPTANCE.md) records compatible BEAM download fallback, strict compiled-cache miss after changed lock bytes, and successful no-import cold commands. |

## Evidence boundaries and limitations

- The accepted current-source browser and cache receipts are the six e37 session attempts listed above. Earlier candidate and failed collector attempts remain in the histories documented in [182-CACHE-ACCEPTANCE.md](./182-CACHE-ACCEPTANCE.md); they are not relabeled, and no clean-stability claim is made across all historical attempts.
- The local run is classified `local-clean`, not hosted exact-SHA proof. Historical full runs whose log collection failed remain ineligible.
- The hosted run was `workflow_dispatch`; no claim is made that this exact receipt came from `schedule`.
- Deep-quality dependency audit debt remains deferred to Phase 184. This acceptance does not claim every advisory CI workflow is green.
- The paid judge was not required or activated. Descriptor-less/unclassified assumptions remain in their existing planning state; no reviewer approval or human UAT is fabricated.
- No retry, skip, flaky pass, baseline update, retained-preview mutation, new dependency, public API change, or required-lane change was used to obtain this proof.

