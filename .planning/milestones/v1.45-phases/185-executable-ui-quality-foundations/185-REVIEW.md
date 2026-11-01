---
phase: 185-executable-ui-quality-foundations
reviewed: 2026-11-01T15:22:00Z
depth: standard
files_reviewed: 50
files_reviewed_list:
  - .github/workflows/ci.yml
  - brandbook/README.md
  - brandbook/tokens/tokens.css
  - brandbook/tokens/tokens.json
  - dev/mix/tasks/verify/ui_tokens.ex
  - examples/scrypath_ecommerce/Dockerfile
  - examples/scrypath_ecommerce/Makefile
  - examples/scrypath_ecommerce/README.md
  - examples/scrypath_ecommerce/config/test.exs
  - examples/scrypath_ecommerce/contrast-checker.mjs
  - examples/scrypath_ecommerce/docker-playwright.sh
  - examples/scrypath_ecommerce/e2e/UI-REVIEW.md
  - examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/axe-scan.mjs
  - examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts
  - examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts
  - examples/scrypath_ecommerce/e2e/settings_layout.spec.ts
  - examples/scrypath_ecommerce/e2e/ui-review.mjs
  - examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
  - examples/scrypath_ecommerce/mix.exs
  - examples/scrypath_ecommerce/package.json
  - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  - examples/scrypath_ecommerce/scripts/verify-e2e.sh
  - scripts/ci/ecommerce_build.cjs
  - scripts/ci/ecommerce_build.test.cjs
  - scripts/ci/ecommerce_evidence.cjs
  - scripts/ci/ecommerce_evidence.test.cjs
  - scripts/ci/ecommerce_lifecycle.test.cjs
  - scripts/ci/ecommerce_target.test.cjs
  - scripts/ci/ui_bundle_contract.cjs
  - scripts/ci/ui_bundle_contract.test.cjs
  - scripts/ci/ui_literal_policy.cjs
  - scripts/ci/ui_literal_policy.test.cjs
  - scripts/ci/ui_preservation.cjs
  - scripts/ci/ui_preservation_bundle.cjs
  - scripts/ci/ui_state_pairs.cjs
  - scripts/ci_monitor.cjs
  - scrypath_ops/assets/css/contrast-pairs.mjs
  - scrypath_ops/lib/scrypath_ops/clock.ex
  - scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex
  - scrypath_ops/lib/scrypath_ops_web/router.ex
  - scrypath_ops/mix.exs
  - scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs
  - scrypath_ops/test/scrypath_ops_web/router_test.exs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/mix/tasks/ui_literal_contract_test.exs
  - test/mix/tasks/ui_tokens_contract_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
review_mode: native_in_thread
source_sha: fa42d99ee3ad5290ea7d8ab089ba076c5e25558c
---

# Phase185 code review

The integrated implementation has no remaining blocking code-review finding. Two bounded warnings are explicitly deferred below. Native in-thread review directly covers 50 current paths, including the Axe, prebuilt-handoff and six-file serial-runner follow-ups. Source hashes and actual behavior evidence are retained in `final-code-review-followup-fa42d99e.json` and its original a293/af78/e445 predecessors. This is not independent human, security or design approval.

## Scope

Direct review covers the literal scanner and real-Git history authority, canonical contrast negatives/live focus binding, typed token validation, generated CSS, caller auth/routes and requested assets, bounded raw evidence, full-page/native-hover comparison, clock/fixture/image/runtime provenance, cleanup, exact-source workflow closeout and the isolated frame-safe accessibility optimization. The canonical current source-scope resolver records 158 integration commits and 72 surviving paths, no path outside the plan union and no unreachable commit. Four intentionally deleted paths are asserted absent. Direct review of 50 paths is not claimed as direct review of all 72; cumulative source reviews, actual contract negatives and current runtime proof cover integration boundaries. The root separately reviewed cross-module Clock, Compose, controller, build and documentation wiring.

## Narrative Findings (AI reviewer)

Integration review found and repaired concrete defects before the accepted candidate: dropped semantic assertions; residual fixture task/document history; malformed saved definitions; incorrect protected-script200 assumptions; fullpage sampling losing actualhover; missing captured interaction targets; generated utility later-rule/property falsepasses; governed source/ancestor symlink and Gitlink omissions; unbounded ledger reads; quoted-theme decoys; and interrupted runtime proofs incorrectly reporting success. Source fixes have targeted negative/positive evidence and current integrated runtime coverage, rather than retrospective invented RED commits. Detailed failed attempts remain unchanged in execution history.

The final source followups reject every conflicting generated declaration; reject source120000/160000 and filesystem links plus oversized ledgers; parse real top-level lexical theme blocks; propagate TERM143/INT130; require complete test/prod image/project/port evidence before runtime success; and observe the actual assets loaded by browser layouts while preserving forwarded403 protection. At source `4db097d`, the root core suite passed 1,039 tests and repository contracts passed 146 tests. Accepted local before R15 and candidate R4 receipts each contain 61 paired cases, 213 observations and 426 selected images; the exact pair comparison and repeat both passed, with clean owned cleanup. These local proofs retain their original source identities. Reconciliation at af78 confirms only the CI workflow, its wiring test, and the maintainer UI review guidance changed; the product tree, common fixture overlay and runtime inputs remain unchanged.

## Warnings

### WR-01: Internal direct PNG helpers rely on validated input

**WARNING** — `scripts/ci/ui_state_pairs.cjs` exports internal helpers that decode raw PNG buffers before their own pixel cap. Arbitrary direct helper callers could allocate a large raster. The actual canonical CLI first validates PNG headers, dimensions and pixel bounds through `ecommerce_evidence`; current CLI evidence is bounded and this is not an observed CLI bypass. Deferred as an internal-entry precondition limitation; do not advertise arbitrary-buffer safety or expose it as a public API without a header-first bound.

### WR-02: Inherited custom workflow reporting can misname the selected workflow

**WARNING** — unchanged `scripts/ci_monitor.cjs` can echo a custom `--workflow` value while run selection remains fixed to `ci.yml`. The approved wrappers pass no override and use default `ci.yml`, whose exactSHA, new dispatch, repository/ref, required jobs and artifacts are bound correctly. Deferred as an inherited nondefault reporting issue, outside the chosen phase remedy. No custom-workflow guarantee or risk acceptance is inferred.

## Required acceptance and limits

Candidate and terminal hosted closeout remain separate mandatory external gates. The tracked report cannot certify future terminal success: all final tracking must be committed first and that exact successor attested with no later tracked writes. Actual original-session preservation and current capture inspection are recorded in the preservation/UI reports; missing evidence stays a gap. Inherited Bandit/PhoenixHTML/Cloak/CloakEcto advisories remain unaccepted. Existing OS packages in the unchanged builder base are outside the approved development-wrapper/runtime graph boundary. Retained-preview stop, merge/release and next-phase boundaries remain unchanged.

## Hosted diagnosis and reviewed follow-up

Earlier hosted runs exposed source defects in artifact-path handling, clock transport, strict lint/Dialyzer checks, and the full prebuild identity handoff. At source `4db097d`, the mounted job passed; repository contracts failed because the real PNG decoder dependency was absent, and the advisory full job failed the prebuild/runtime Compose model comparison before starting Compose. At `e445a2c4`, all five required jobs plus coverage and closeout attestation passed, but the advisory full job failed before runtime because source identity exports were not persisted into later workflow steps. Deep quality had no new Dialyzer errors; only inherited Ops advisories remained. Those failures were not accepted as environmental outcomes.

The parent reviewed the repaired source and targeted evidence. Ordinary default artifacts remain in the existing ignored path, while explicit overrides and every before-only artifact root still require an external physical path. Lifecycle tests cover both valid and rejected boundaries, including hostile ambient configuration. The token refactor preserves lexical/depth/alias checks and malformed public input rejection; strict lint, the full focused token suite and existing-PLT analysis pass.

The workflow source now installs the existing locked demo dependencies in `repository-contracts` with lifecycle scripts and browser downloads disabled, before the real PNG evidence tests. The full prebuild computes and exports the checked source SHA plus product-tree and fixture-overlay digests. Commit af78 also writes those same three values to `GITHUB_ENV`, so the separate verify-handoff and runtime steps receive the values that prepared the model; the strict identity guard remains enabled. The full verifier receives the `phase185-<run>-<attempt>` ID that `verify-e2e.sh` uses for its artifact directory, and the upload path matches it while artifact names and Phase 182 run identifiers stay numeric. A read-only actual Compose model reproduction confirmed the prebuild/next-step model and recipe match when those three variables are transported. No package manifest or lockfile changed.

Exact paths and hashes, accepted R15/R4 proof references, the phase-scope cutoff, root check logs, hosted outcomes, and the current run status are in `/private/tmp/scrypath-phase185-execution/final-code-review-followup-af78dd8f.json`. The af78 hosted closeout is in progress and remains pending; neither earlier hosted runs nor local proofs can substitute for it. Terminal hosted acceptance is also still required. This source review does not turn pending runtime or hosted work into a pass.

## Resolved phase scope supplement

The canonical phase resolver now accounts for153 integrated source commits and67 surviving changed paths, with0 outside-union paths and0 unreachable commits (`final-review-resolved-scope-af78dd8f.json`). Four absent historical paths are intentional removals: the paid judge/rubric and generator view/template. Their absence is asserted by surviving source/route contracts. This closes the index153 bookkeeping note without enlarging the direct40-file reviewer claim. Root additionally inspected the small Clock/caller/fixture/Compose/runtime-builder/profile/docs integration deltas and recorded test-quality/guard behavior in `final-test-quality-and-integration-audit-af78dd8f.json`; prior task source reviews remain separately attributed.

## Final candidate evidence supplement

Current candidate [41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c` passed all five required jobs, coverage and exact-source immutable attestation, and its full advisory browser lane succeeded after the diagnosed transport, frame-safe accessibility, runtime-handoff, serial full-suite and cold-start repairs. Original local full/pair/global receipts retain their source identities. Final tracked-source terminal attestation remains mandatory and is not certified by this pre-dispatch record. This is an acceptance-evidence supplement to the reviewed integration including the guarded Axe helper, not a new reviewer identity or dismissal of either deferred warning. The bounded current full lane passes; inherited audit findings remain unaccepted.

## Frame-safe Axe integration scope

The cumulative final source follow-up reviews eight changed test/helper paths, including the installed deprecated method boundary, preflight-before-fast-scan ordering, existing/cross-origin/transient frame fallback, error propagation and listener cleanup. Rules/tags/includes, incomplete output and advisory semantics remain intact. Current source input hashes and actual-browser measurements/fixtures are recorded in `final-code-review-followup-a293993d.json` and `axe-timing-remedy-decision.json`; the current immutable full receipt supplies complete runtime acceptance. The canonical scope resolver records 158 source integration commits and no surviving path outside the plan union; the four intentional deletions remain asserted absent. This is native in-thread integration review. The two previous deferred warnings are unchanged.

## Prebuilt handoff and original-proof boundary

The first optimized hosted browser run passed all254cases in736seconds but its final prebuilt check rejected six newly measured fields, so its whole receipt remains failed. The successor normalizes only those browser metadata values in the prebuild model and independently verifies all supplied values against actual loaded/container images and fresh runtime inspection. Missing/forged partial metadata, source/recipe/cache changes and browser-tag substitution fail. Existing image-only global callers retain their original container-image checks when no measured field is supplied. The initial overstrict caller assumption was caught and reproduced before acceptance; candidate7 was explicitly superseded through existing workflow concurrency. Focused regression and actual read-only model/Bake evidence are in `runtime-handoff-image-only-caller-fix.json` and `runtime-handoff-model-diagnosis-r2.json`. Original R15/R4 runtime identity objects are exactly unchanged, and `state-pair-current-helper-revalidation.json` recomputes the original61-case comparison with byte-identical output. The two metadata helper/test changes are a subset of the six current overlay changes from the original8756 pair; no source or overlay is relabeled. Current canonical full hosted acceptance is separate.

## Serial full-suite source and proof boundary

The current source passed the complete serial full lane, immutable archive verification and independent canonical receipt recomputation. The batches preserve one worker, zero retries, original traces, the exact discovered union and clean owned teardown within the existing limits. The cold local path explicitly acquires only the existing service images before startup; failed acquisition prevents execution.

[Source reconciliation](185-SOURCE-AUDIT.md#serial-full-suite-source-and-proof-boundary) records the six changed outer overlay files, unchanged product/capture inputs, preserved original pair/global identities, discarded trace experiment and excluded failed/superseded runs. The actual current receipt is `candidate-r10-full-acceptance.json`. Final tracking-source terminal acceptance remains a separate mandatory external gate; no independent/design/risk approval or retained-preview action is inferred.
