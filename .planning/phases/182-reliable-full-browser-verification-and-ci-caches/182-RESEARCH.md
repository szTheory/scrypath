# Phase 182: Reliable full browser verification and CI caches - Research

**Researched:** 2026-10-26
**Domain:** GitHub Actions CI, Docker Compose/BuildKit, Playwright E2E evidence, Mix/BEAM cache correctness
**Confidence:** HIGH for current repository facts and official documented semantics; MEDIUM for unexercised hosted cache behavior

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The maintainer explicitly requested research of all relevant decisions using subagents, adversarial consideration and automatic adoption of a cohesive recommendation set. These are agent-selected recommendations under that delegation, not individual maintainer votes or an independent formal review. Preserve the approved phase boundary; do not start plan/execute automatically.
- **D-02:** Keep `mix verify.ecommerce_e2e` / `make -C examples/scrypath_ecommerce verify-e2e` as the canonical full capability and the existing mounted equivalents as the focused capability. The Make entrypoint remains Docker-only. Add no application dependency, new fixture platform or required CI job. Prefer small explicit changes to the existing scripts and built-in reporters.
- **D-03:** Append the existing `examples/scrypath_ecommerce/compose.phase173.yaml` only when verifier scope is `full`. Reuse its `standalone_ops` service and fixture database inside the same unique disposable project as mounted `web`, Postgres, Meilisearch and the browser. Focused scope keeps its existing service set, health and teardown behavior. Do not invoke a separate standalone suite to substitute for full-suite coverage.
- **D-04:** Validate the merged Compose model and require healthy dependencies plus bounded HTTP readiness for both actual Ops fixture routes before executing the full browser suite: mounted `/admin/search/phase173/health` and standalone `/ops/phase173/health`. A responding storefront `/` alone does not establish fixture readiness. Keep host ports unpublished, test-only fixtures gated and cleanup limited to the owned project. Collect diagnostics before teardown, preserve the original failure status, and verify disposal of owned containers, network and volumes on normal success/failure. Keep the explicit failed-stack debug escape hatch. Hard runner termination may prevent finalization; absent evidence cannot certify completion.
- **D-05:** Replace the two port-only follow-up guards with one consistent hostname-aware preview refusal rule, following `ui_baseline.spec.ts`: `http://web:4002` is the Docker target; the retained loopback preview on port 4002 remains refused before mutating steps. Preserve supported explicitly isolated local-port use. Exercise positive Docker and negative preview cases in executable guard checks; removing safety checks or turning missing Docker execution into accepted skips is rejected. Read `.planning/UI-PREVIEW.json` and follow its named-checkout/preflight protocol before any later retained-preview work; this discussion does not touch that preview.
- **D-06:** Collect the expanded Playwright inventory using the same source/config/project selection as execution, then reconcile stable case identities against actual JSON outcomes. Include file, title path/project, entrypoint where applicable, outcomes and attempts. Fail clean-proof eligibility for missing/duplicate cases, unexplained skips, unexpected expected-failure masking or retry passes. Any intentional skip needs a concrete scoped reason recorded in the receipt; the intended follow-up/iteration-3 cases must execute, as must both mounted and standalone Phase173 scenarios. Historical approximate counts are not acceptance targets.
- **D-07:** Prefer one unfiltered full Chromium invocation with one worker and `retries: 0`, retaining the current serial database/state assumptions. Keep normal Playwright web-first assertion polling and readiness checks; they are different from retrying a failed test. Do not add arbitrary sleeps, weaken assertions, introduce grep/project exclusions or increase concurrency to obtain green evidence. If measured runtime later requires serial partitions, preserve disjoint reports/output directories and prove their complete union; parallel sharding requires evidence of fixture isolation, which this phase does not assume.
- **D-08:** Produce one authoritative aggregate, with a human-readable summary derived from it. Correct and wire `scripts/ci/phase105_evidence.sh` or replace it coherently; do not leave two competing evidence authorities. Bind collection, results and artifact inventory to the checked-out commit, built/runtime image identity, Compose scope/targets, browser/package version, workflow event/ref/run ID/run attempt and stage timings/statuses. On hosted acceptance, compare the actual checkout to the event SHA and the built source identity; a branch name or successful unrelated check is insufficient. Local dirty runs need a source fingerprint and are not clean exact-commit hosted proof. Read the verifier step's raw outcome as well as the advisory job's conclusion; `continue-on-error` is not a pass.
- **D-09:** Use a fresh owned artifact location per run. Retain inventory, full Playwright JSON/HTML and failure traces, applicable screenshots (including `ui-review-artifacts/iteration3-journeys`), deterministic checker results, Compose health/logs and cleanup/evidence failures. Copy only this run's known outputs before teardown; do not upload a retained preview's review directory or old local captures. Required missing/malformed reports and failed artifact copies block an otherwise successful proof; on an already failed run, keep partial diagnostics without replacing the original cause. Keep bounded logs/artifacts and the existing seven-day hosted retention. Never interpret absent/empty input as successful zero cases.
- **D-10:** Reconcile stale browser expectations against the current fixture and rendered behavior, specifically the `unknown_module` versus `unknown_backend` assertion in `admin_screenshots.spec.ts`, using the existing job-argument decoding contract. Preserve the distinction between unavailable/unknown and healthy/empty. A genuine product regression must not be hidden by changing expected text. Preserve historical evidence; no automatic baseline update or UI redesign is authorized. The current light-baseline checker proves file inventory and widths, not pixel parity or aesthetic approval. Prefer current shipped UI/design authority and `brandbook/` over the older exploratory brand prompt when resolving an actual conflict.
- **D-11:** Set the full scheduled/manual job budget to 30 minutes, including setup/build, readiness, browser checks, deterministic follow-up checks, collection, cleanup and upload. Use an inner execution deadline with measured finalization margin so the job-level timeout is the last resort. Keep actionable timeout diagnostics. Require a successful complete hosted run at the changed source SHA; a retry run does not erase its earlier failure or become clean stability evidence. Cache warm/cold validation is a separate requirement and need not force that full hosted proof to be cold. Do not trade away coverage or exceed the approved budget to meet it.
- **D-12:** Prefer Docker's official SHA-pinned Buildx setup and Bake action in CI, reading the same resolved Compose build graph and local checkout context as the verifier. Load the resulting images locally without registry publication. Use an explicit shared project/image identity and a checked prebuilt-image handoff so Compose consumes precisely those images without a second build. Keep the ordinary local canonical command on its existing uncached-capable Compose build path, with no GitHub runtime credentials required. Avoid a third-party runtime-token helper or an independently maintained second build graph. The planner must prove model/tag/source parity before enabling the hosted prebuild path.
- **D-13:** Use GHA cache API v2 with supported pinned Buildx/BuildKit versions, stable separate scopes for distinct image recipes (application versus browser) and bounded import/export time. Identical mounted/standalone application recipes may share the application build result when built once; otherwise give concurrent exporters distinct scopes. Preserve manifest/lock-before-source Dockerfile layering. A cache scope must not be the changing source SHA, and distinct image recipes must not overwrite the default `buildkit` scope. Prefer the scheduled/manual full job as the shared cache writer and the mounted job as an importer; keep untrusted PRs from exporting trusted shared state. Cache export failure is an explicit performance warning, not a test failure or a fabricated cache hit. No cache credentials, private data or test results belong in exported layers. Prove actual restore/export logs: merely enabling a builder, warm local layers or silently ignored Compose cache fields do not satisfy CACHE-01. BuildKit cache mounts are not assumed to persist through GHA layer-cache export.
- **D-14:** Separate download-cache fallback from resolved dependency/build reuse rather than adding broad `restore-keys` to the current combined `deps`/`_build` archive. Prefer the Hex package-archive directory (`~/.hex/packages`) for cross-lock download reuse; cache Rebar downloads only if the selected paths are verified to contain downloads rather than compiled output. Namespace keys by cache schema, graph/project, runner OS image/architecture, exact resolved Elixir/OTP, actual compile environment/target/profile and relevant manifest/lock inputs, including path-dependency graphs where used. Download fallback may omit the lock only within compatible platform/toolchain/environment/graph boundaries; always run `mix deps.get` and the normal compile/verification commands afterward. `deps/` can contain generated/native outputs, so do not describe it as inherently portable pure source. Never share arbitrary compiled/NIF outputs across ABI boundaries or cache credentials by archiving all of `~/.hex` or `~/.mix`.
- **D-15:** Resolved `deps` plus compiled build reuse must retain the exact graph/lock/manifests/toolchain/environment boundary; they may share one strictly keyed archive so restoring build manifests preserves corresponding dependency source timestamps. A primary key may append a relevant source fingerprint so immutable caches can refresh after source changes; the restore prefix can omit that source fingerprint while retaining all compatibility inputs, letting Mix recompile changed/path-dependent code. A lock change intentionally invalidates compiled reuse. Cache only the intended ordinary environment directories; keep no-optional builds and fresh package-consumer proof isolated. Keep PLTs scoped to their exact analysis toolchain/graph/lock and compatible inputs. A key labelled `test` must not silently pool incompatible build profiles. Reconcile these rules across the existing affected cache steps without adding a cache abstraction dependency or changing support tuples.
- **D-16:** Caches accelerate work and never decide whether `deps.get`, compilation, tests, or the verifier runs. Prove a warm Docker restore/export, a build with import disabled on a genuinely fresh builder, BEAM fallback within a compatible namespace, lock invalidation and representative cold-cache job execution. Use run-local bypasses or fresh namespaces/runners; do not delete shared repository caches. A random new scope alone is not cold proof if an existing local builder still contains layers. Keep source SHA, tuple, hit/miss/fallback and command result with each receipt. These cache proofs may be separate from the successful full-browser hosted receipt.
- **D-17:** Put deterministic infrastructure regressions in existing repository-contract lanes: resolved full/focused service scope, preview guard truth table, strict inventory/outcome reconciliation, missing/malformed evidence, retry/skip/duplicate masking, artifact-copy failure and cache-key boundary/invalidation checks. Test behavior with small synthetic reports or Docker command doubles where appropriate, and retain real Docker/hosted runs as integration acceptance. Contract-string assertions alone do not prove cache reuse, service readiness or browser success. Keep warnings-as-errors for changed test infrastructure per CONTRIBUTING.
- **D-18:** Do not activate or depend on the legacy paid judge, supply API keys, fabricate judge success or make its result part of new acceptance. Phase 185 owns deleting the dormant legacy path and wiring; the evidence schema must already work without it. Task relocation stays Phase 183; dependency upgrades/graph pruning stay Phase 184; token enforcement/storybook/new UI engine or polish remain their approved later phases. Reconcile merged-main ancestry before implementation as required; discussion source is not a claim of latest-main or v1.44 merge/publication.

### Agent's Discretion

- Small helper/module names, cache schema version and source-fingerprint granularity, exact internal deadline/margin based on measurement, and the aggregate's representation while preserving one authority.
- Reusing or replacing the legacy evidence script, with compatible historical filenames/readers reconciled explicitly.
- Exact official action versions/pins and flags after checking current primary documentation. No version from research is an unverified upgrade mandate.
- Deduplicating application image builds when the resolved recipes are truly identical; any prebuild fallback must retain source/model/image parity.

### Deferred Ideas (OUT OF SCOPE)

- Phase 183: move maintainer verifier tasks/support outside the Hex package.
- Phase 184: dependency range changes, pruning, advisory remediation and reconciled graphs.
- Phase 185: token/contrast/drift prerequisites and deletion of the dormant paid-judge path; no judge activation in this phase.
- v1.46+: storybook fixture migration/UI engine; later surface extraction, visual baselines and polish.
- New required browser lane, broad browser/OS matrix, new product APIs, UI redesign and inherited unrelated audit debt remain outside this phase.
- PR #122/publication and merged-main reconciliation are distinct delivery work; this discussion creates no new receipt for archived source.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Exact description | Research support |
|---|---|---|
| BROW-01 | “A contributor can run the canonical full Docker E2E command and exercise mounted and standalone Ops scenarios in the same isolated, health-checked stack; full scope includes compose.phase173.yaml, while focused verification retains its existing service scope and teardown contract.” [VERIFIED: .planning/REQUIREMENTS.md:26] | Overlay, model validation, both route checks, cleanup. |
| BROW-02 | “A contributor can execute every intended ui_followup.spec.ts and ui_iteration3.spec.ts case against Docker's web:4002; their guards continue to reject the retained local preview, and the collected case inventory explains counts and any intentional skips.” [VERIFIED: .planning/REQUIREMENTS.md:27] | Hostname guard and actual inventory/result matching. |
| BROW-03 | “A maintainer can obtain a successful full scheduled/manual ecommerce-e2e run at the changed source SHA within a 30-minute job budget, with complete bounded artifacts and no unexplained skips or retries counted as clean passes; stale expectations are reconciled with current behavior using executable assertions.” [VERIFIED: .planning/REQUIREMENTS.md:28] | Exact SHA and raw result receipt, complete artifacts, time budget, current decoder semantics. |
| CACHE-01 | “A contributor's Docker verification builds can reuse GitHub Actions buildx caches on subsequent runs and still build successfully when the cache is missing.” [VERIFIED: .planning/REQUIREMENTS.md:48] | Compose/Bake parity; real warm and fresh-builder cold proof. |
| CACHE-02 | “A contributor's BEAM dependency/build jobs can use safe restore-keys fallbacks with environment/version-aware keys, while lockfile changes invalidate the appropriate cache and cold-cache runs remain valid.” [VERIFIED: .planning/REQUIREMENTS.md:49] | Download-only compatible fallback and strict deps/build keys. |
</phase_requirements>

## Summary

Make full mode run mounted and standalone Ops in the same isolated Compose project. Validate merged config, require bounded readiness for both fixture routes, inventory with the same Playwright selection, then reconcile all selected identities/attempts against JSON. Clean proof requires complete evidence, raw browser success and cleanup; advisory job status alone is insufficient. Discussion says no full-browser/cache proof has passed. [VERIFIED: 182-CONTEXT.md:23-39]

Use official SHA-pinned Buildx/Bake with the exact Compose graph/local checkout. Load images locally, check model/tag/source parity, and prevent Compose rebuilding. Keep GHA v2 cache scopes stable and separate per recipe. For BEAM, only compatible download archives get lock-omitting fallback; resolved deps/builds key on complete graph, lock, OS/arch, BEAM and environment. Always run normal Mix resolution/build/verification. [CITED: https://docs.docker.com/build/cache/backends/gha/; https://docs.docker.com/reference/dockerfile#run---mounttypecache; https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching; https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html]

**Primary recommendation:** First make readiness and run-local evidence strict, then add cache acceleration and prove warm/cold paths separately.

## Architectural Responsibility Map

| Capability | Owner | Reason |
|---|---|---|
| Verifier dispatch | Mix / Make | Mix task delegates to example Make target. “def run(:ecommerce_e2e” [VERIFIED: lib/mix/tasks/verify/capability.ex:17-30] |
| Services/resources | Compose | Owns disposable services, network, volumes and health; full overlay adds standalone Ops. “standalone_ops:” / “condition: service_healthy” [VERIFIED: examples/scrypath_ecommerce/compose.phase173.yaml:12-39] |
| Browser cases/safety | Playwright container | Uses internal network target “PLAYWRIGHT_BASE_URL: http://web:4002” [VERIFIED: examples/scrypath_ecommerce/compose.e2e.yaml:16-26] |
| Inventory/outcomes | Playwright + small validator | Existing list command is “playwright test --list” [VERIFIED: examples/scrypath_ecommerce/package.json:10-12] |
| Receipt/artifacts | Existing evidence scripts + Actions upload | One aggregate owns pass status; summary derives from it. [VERIFIED: scripts/ci/phase105_evidence.sh:25-27; .github/workflows/ci.yml:359-366] |
| Cache | BuildKit GHA backend / Mix cache | Docker scopes separate recipes; Mix still runs after restore. [CITED: https://docs.docker.com/build/cache/backends/gha/; https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html] |

## Project Constraints (from AGENTS.md)

- Preserve Elixir/Ecto/Phoenix ecosystem fit and public API boundary. [VERIFIED: AGENTS.md:12-20]
- Follow CONTRIBUTING and retain lean required jobs; use PR-first and executable or exact-SHA evidence, not pending UAT/simulated review. [VERIFIED: AGENTS.md:87-103]
- Use absolute workdirs, preserve unrelated edits and obey named-preview checkout/preflight/data rules; no preview is involved here. [VERIFIED: AGENTS.md:108-127]
- Keep seven-day retention; no automatic baseline update. [VERIFIED: AGENTS.md:116-127]

## Standard Stack

| Technology | Current baseline | Planner guidance |
|---|---|---|
| GitHub Actions | Existing five required jobs and advisory full run | No new required lane; current global permission is contents: read. [VERIFIED: .github/workflows/ci.yml:3-20, 341-366] |
| Docker Compose | Existing Compose v2 verifier | Local canonical command remains Compose; overlay only for full mode. |
| Docker Buildx/Bake | Candidate setup action v4.4.1 SHA f87e5991a6d7451dcb8d9637bfbc97413f497069; Bake v7.5.0 SHA 59cb1203cd42bcefd40a1b6d73b589e48c86040e | Docker first-party workflow refs, recheck at implementation. Pin CLI/BuildKit versions too. [CITED: https://github.com/docker/buildx/blob/master/.github/workflows/build.yml; https://github.com/docker/setup-buildx-action] |
| Elixir/OTP | CI pins 1.19.0 / 28.1 | Preserve tuple. “elixir-version: "1.19.0", otp-version: "28.1"” [VERIFIED: .github/workflows/ci.yml:24-35] |
| Playwright | Image 1.60.0; chromium, one worker, zero retries | Preserve parity/serial behavior. “ARG PLAYWRIGHT_VERSION=1.60.0” [VERIFIED: examples/scrypath_ecommerce/Dockerfile.e2e:1-8]; “retries: 0” / “workers: 1” [VERIFIED: examples/scrypath_ecommerce/playwright.config.ts:3-23] |
| Mix cache | Root, Ops, ecommerce path graphs | Include every path manifest/lock, exact tuple/environment/profile. [VERIFIED: mix.exs:108-123; scrypath_ops/mix.exs:41-67; examples/scrypath_ecommerce/mix.exs:34-58] |

Supporting existing actions are SHA-pinned actions/cache v5 and upload-artifact v7. Current cache combines deps/_build and root-only manifest hash [VERIFIED: .github/workflows/ci.yml:28-35]; current full upload warns on missing files with seven-day retention [VERIFIED: .github/workflows/ci.yml:359-366]. Hex archive path ~/.hex/packages is the locked download-cache preference [VERIFIED: 182-CONTEXT.md:48]. No new package is proposed; no install/package-legitimacy audit is needed.

## Architecture Patterns

### System flow

    candidate dispatch or schedule
      -> checkout and compare HEAD with event SHA
      -> Compose-derived Bake graph on local checkout
      -> cache import/export and local image load
      -> validate image/model/source handoff
      -> unique Compose project (mounted + full-only standalone)
      -> model/readiness checks -> inventory -> one Chromium run
      -> JSON/HTML/traces/screenshots and deterministic results
      -> collect before teardown -> verify owned resources removed
      -> reconcile -> authoritative receipt -> derived summary/artifact

Schedule uses default-branch latest commit; changed-source acceptance must dispatch the selected ref, record event/ref/run ID/attempt and compare built/checked-out SHA. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows; https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts]

### Implementation boundaries

Keep changes in existing paths: .github/workflows/ci.yml; examples/scrypath_ecommerce/scripts/verify-e2e.sh; examples/scrypath_ecommerce/docker-playwright.sh; examples/scrypath_ecommerce/playwright.config.ts and e2e specs; scripts/ci/phase105_evidence.sh or a single replacement; test/mix/tasks/workflow_wiring_test.exs and test/mix/tasks/verify_capability_test.exs.

Current Compose argv is “compose=(docker compose -p "$project" -f compose.yaml -f compose.e2e.yaml)” [VERIFIED: examples/scrypath_ecommerce/scripts/verify-e2e.sh:19-31]. Make invokes “@bash ./scripts/verify-e2e.sh full” [VERIFIED: examples/scrypath_ecommerce/Makefile:157-161].

### Pattern 1: Full-only overlay and project ownership

Append Phase173 overlay only in full scope; validate merged config, start one unique project, wait with deadlines on both Ops fixture endpoints, capture logs before teardown and verify project containers/network/volumes are removed. Focused scope preserves current services/cleanup. The verifier contains “project="scrypath_ecommerce_verify_${scope}_${safe_sha}_$$"” [VERIFIED: examples/scrypath_ecommerce/scripts/verify-e2e.sh:23-27]; standalone endpoint “http://127.0.0.1:4003/ops/phase173/health” [VERIFIED: examples/scrypath_ecommerce/compose.phase173.yaml:12-38]; internal browser target “http://web:4002” [VERIFIED: examples/scrypath_ecommerce/compose.e2e.yaml:10-26]. Compose health dependencies supplement, not replace, route readiness. [CITED: https://docs.docker.com/compose/how-tos/startup-order/]

### Pattern 2: Strict browser evidence

Use identical config/project selection for inventory and execution; one unfiltered chromium invocation. Reconcile file/title/project identity against every result attempt. Missing/duplicate tests, unexplained skips, retry pass, unexpected-failure masking, malformed report or nonzero raw step blocks clean proof. Playwright config has one worker, retries 0, chromium project, JSON/HTML reporters [VERIFIED: examples/scrypath_ecommerce/playwright.config.ts:3-23]. Built-in JSON/HTML reporters and flaky retry semantics are documented. [CITED: https://playwright.dev/docs/test-reporters; https://playwright.dev/docs/test-retries]

### Pattern 3: Single receipt

One JSON aggregate owns eligibility; derive readable summary. Include checkout/local fingerprint, built/runtime image ID/digest/source label, Compose scope/targets/project, browser/package version, event/ref/run/attempt, inventory/attempts, stage times/raw statuses, checker results, artifact inventory/copy failures, health/logs and cleanup. Missing required input is invalid. Preserve original failure. Only hosted success at changed event SHA with matching checkout/image is exact-source proof.

Current evidence script converts missing report to null/empty [VERIFIED: scripts/ci/phase105_evidence.sh:119-127]; full job is advisory and upload warns [VERIFIED: .github/workflows/ci.yml:341-366]; artifact copy errors are suppressed [VERIFIED: examples/scrypath_ecommerce/scripts/verify-e2e.sh:36-47].

### Pattern 4: Docker cache parity

Use local checkout and exact Compose-derived Bake targets, separate stable GHA v2 scopes, bounded import/export, local image load, explicit handoff and no second Compose build. Default Docker scope buildkit is overwritten by later builds; distinct recipes need scopes. [CITED: https://docs.docker.com/build/cache/backends/gha/]. Docker cache mounts are not in exported layer cache. [CITED: https://docs.docker.com/reference/dockerfile#run---mounttypecache]. Current action candidates are cited above. Buildx CLI v0.38.1 / BuildKit v0.34.1 are candidate official stable releases; actual graph/cache compatibility is unverified. [CITED: https://github.com/docker/buildx/releases; https://github.com/moby/buildkit/releases]

### Pattern 5: BEAM cache split

Cross-lock restore only for compatible download archive (prefer ~/.hex/packages). Keep resolved deps/_build strict over schema, graph, every path manifest/lock, OS/arch, exact Elixir/OTP and env/target/profile. Isolate PLTs and no-optional/package consumer. Always deps.get, compile and verify after restore. Current root key only hashes root manifests while caching deps/_build together [VERIFIED: .github/workflows/ci.yml:28-35]. Mix documents deps.get and environment behavior. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html; https://hexdocs.pm/mix/Mix.html]

### Anti-patterns / don't hand-roll

Avoid fixed artifact paths, treating list as execution, root health as Ops readiness, port-only preview guard, retry/skip/advisory as clean pass, Compose rebuild after prebuild, shared default cache scope, cold proof on persistent builder, broad compiled BEAM fallback. Reuse Compose, Playwright built-in reporters, official Buildx cache, Mix resolution; do not build a test framework/cache-token shim or activate paid judge.

## Common Pitfalls

- Green advisory conclusion despite browser failure: capture raw step status; strict JSON/cardinality; required copy failures block. [VERIFIED: .github/workflows/ci.yml:341-366; scripts/ci/phase105_evidence.sh:119-152]
- Intended specs skip on Docker because guard is port-only; standalone route errors after root responds. Use hostname guard and both bounded routes. [VERIFIED: examples/scrypath_ecommerce/e2e/ui_followup.spec.ts:7-9; examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts:4-8; examples/scrypath_ecommerce/docker-playwright.sh:5-25]
- Bake image mismatch/rebuild: prove model/tag/source/image parity and no-build handoff. [CITED: https://docs.docker.com/guides/compose-bake/; https://github.com/docker/bake-action]
- Cache enabled but unproven: capture real warm import/export; test import-disabled fresh builder. [CITED: https://docs.docker.com/build/cache/backends/gha/]
- BEAM key crosses ABI/profile: only download archives get compatible fallback; strict outputs key all graph/toolchain/environment inputs.
- Copy/cleanup masks cause or captures preview: run-local allowlisted artifacts, collect pre-teardown, preserve first failure. Current screenshot source path is “ui-review-artifacts/iteration3-journeys”. [VERIFIED: examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts:3-8]

## Code Examples

    make -C examples/scrypath_ecommerce verify-e2e
    # existing Make target invokes bash ./scripts/verify-e2e.sh full
    # Playwright package script is playwright test --workers=1

Source excerpts: “@bash ./scripts/verify-e2e.sh full” [VERIFIED: examples/scrypath_ecommerce/Makefile:160-161]; “test:e2e”: “playwright test --workers=1” [VERIFIED: examples/scrypath_ecommerce/package.json:10-12]. Config keeps zero retries/one worker [VERIFIED: examples/scrypath_ecommerce/playwright.config.ts:3-23].

The stale browser expectation is “unknown_module.*NotARealBackend” [VERIFIED: examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts:50-59], while decoder tags “{:unknown_backend, String.t()}” and calls backend lookup with unknown_backend [VERIFIED: lib/scrypath/oban/job_args.ex:16-30]. Reconcile assertion after checking rendered behavior; do not change product behavior/baseline to force success.

## State of the Art

| Previous | Recommended now |
|---|---|
| Assume action finish/local warmth proves cache | Record restore/export and prove warm plus cold. Docker scopes/cache-mount limits are documented. [CITED: https://docs.docker.com/build/cache/backends/gha/; https://docs.docker.com/reference/dockerfile#run---mounttypecache] |
| Untrusted PR writes shared cache | Trusted writer; treat imported untrusted contents as untrusted. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] |
| Mutable action tags | Verified full SHA pins. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Old ASVS numbering | Versioned ASVS v5.0.0 chapter names; identifiers change. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/v5.0.0/README.md] |

## Assumptions Log

| # | Claim | Risk |
|---|---|---|
| A1 | Buildx v0.38.1 and BuildKit v0.34.1 work with this Compose/GHA graph. [ASSUMED] | Must validate before hosted use. |
| A2 | Split Mix caches fit existing lanes without a new abstraction. [ASSUMED] | Cache scope/topology could change. |
| A3 | Receipt schema and inner timeout margin need measurement. [ASSUMED] | Wrong values risk incomplete proof. |

## Open Questions

1. Test Buildx/BuildKit candidate pair with warm restore/export and fresh-builder import-disabled run.
2. Measure build, both readiness routes, browser, copy/cleanup to set inner deadline within the locked 30-minute cap; existing job is 20 minutes.
3. Inspect historical receipt consumers before choosing schema/filenames; keep one authority.

## Environment Availability

| Dependency | Available | Version | Fallback |
|---|---|---|---|
| Docker Engine | Yes | client/server 29.5.2 | — |
| Compose | Yes | 5.1.3 | — |
| Buildx | Yes | v0.34.0-desktop.1 | CI installs selected pin |
| Elixir/Mix | No active version | “No version is set for command elixir”; same for mix | CI 1.19.0/OTP 28.1 |
| Hosted runner/cache | Not exercised | — | Exact-SHA hosted proof |

Probe output: “client=29.5.2 server=29.5.2”, “5.1.3”, “github.com/docker/buildx v0.34.0-desktop.1 e655a179805a207c4e98cfbd36e978cd0edfb8f9” and “No version is set for command elixir”. [VERIFIED: local availability probe, 2026-10-26]

## Validation Architecture

Nyquist enabled: “nyquist_validation”: true. [VERIFIED: .planning/config.json:15-20]

### Test Framework

| Property | Value |
|---|---|
| Framework | Root ExUnit; existing Node built-in tests for JS selftests |
| Config | Root Mix test suite |
| Quick command | MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract |
| Full contract command | mix verify.repository_contracts; browser uses scheduled/manual canonical task |

CONTRIBUTING prescribes warnings-as-errors and repository-contract checks. [VERIFIED: CONTRIBUTING.md verification/CI sections]

### Phase Requirements → Test Map

| ID | Behavior | Type and proof |
|---|---|---|
| BROW-01 | Scope, readiness, cleanup | Contract + Docker integration |
| BROW-02 | Guard, inventory, actual cases | Contract + browser integration |
| BROW-03 | Exact SHA, complete artifact, raw status, budget | Contract + hosted exact-SHA run |
| CACHE-01 | Real warm and cold Docker cache | Contract + Docker/hosted integration |
| CACHE-02 | Safe fallback, lock invalidation, cold Mix | Unit/property + hosted |

Existing test locations are “test/mix/tasks/workflow_wiring_test.exs” and “test/mix/tasks/verify_capability_test.exs” [VERIFIED: 182-CONTEXT.md:93]. Extend behaviorally with synthetic reports/Docker doubles. No new framework/lane is required.

### Sampling Rate

- Per task: focused contract test plus warnings-as-errors compile/test.
- Per wave: MIX_ENV=test mix verify.repository_contracts.
- Gate: warning-as-error suite, successful changed-SHA hosted verifier, separate warm/cold proof.

### Wave 0 Gaps

- No framework installation gap; add phase behavior cases to existing repository-contract tests.

## Security Domain

Use current ASVS v5.0.0 chapters/versioned identifiers. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/v5.0.0/README.md]

### Applicable ASVS Categories

| Category | Applies | Control |
|---|---|---|
| V1 Encoding and Sanitization | Yes | Quote shell args; prevent injection from refs, paths and reports. |
| V2 Validation and Business Logic | Yes | Validate schema/cardinality, bounded inputs and path allowlist. |
| V3 Web Frontend Security | Limited | Refuse retained preview before mutation; no auth change. |
| V4 API and Web Service | Limited | Probe fixture routes; no API change. |
| V5 File Handling | Yes | Run-owned paths, traversal protection, allowlisted copies. |
| V14 Data Protection | Yes | Exclude secrets/private data/results from caches; minimize seven-day artifacts. |

ASVS v5 chapters include “Encoding and Sanitization,” “Validation and Business Logic,” “Web Frontend Security,” “API and Web Service,” “File Handling,” and “Data Protection.” [CITED: https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv]

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Untrusted PR writes cache later trusted | Tampering/Elevation | Trusted writer, no untrusted export, least permissions, scopes. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] |
| Untrusted ref/path reaches shell/copy | Tampering/Disclosure | Quote, allowlist, validate, run-owned output. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |
| Missing report presented as clean | Repudiation/Tampering | Strict schema/raw status; missing required input blocks. |
| Secret/private data in cache/artifact | Disclosure | Exclude from layers; minimize artifacts/logs; preserve read-only and retention limits. [CITED: https://docs.docker.com/build/cache/backends/gha/; https://docs.github.com/en/actions/reference/security/secure-use] |

This is a threat map, not ASVS certification.

## Sources

### Primary repository sources

- 182-CONTEXT.md — D-01–D-18.
- .planning/REQUIREMENTS.md — five requirements.
- .github/workflows/ci.yml and CONTRIBUTING.md — current CI/runtime/cache/commands.
- Verifier, Compose, Dockerfile, Playwright, Mix/evidence files cited inline.

### Official technical docs (MEDIUM; checked 2026-10-26)

- [Docker GHA cache](https://docs.docker.com/build/cache/backends/gha/), [cache mounts](https://docs.docker.com/reference/dockerfile#run---mounttypecache), [Compose health](https://docs.docker.com/compose/how-tos/startup-order/), [Compose Bake](https://docs.docker.com/guides/compose-bake/).
- [Bake action](https://github.com/docker/bake-action), [Buildx official workflow](https://github.com/docker/buildx/blob/master/.github/workflows/build.yml), [Buildx releases](https://github.com/docker/buildx/releases), [BuildKit releases](https://github.com/moby/buildkit/releases).
- [GitHub cache](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching), [events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [contexts](https://docs.github.com/en/actions/concepts/workflows-and-actions/contexts), [secure use](https://docs.github.com/en/actions/reference/security/secure-use).
- [Playwright CLI](https://playwright.dev/docs/test-cli), [reporters](https://playwright.dev/docs/test-reporters), [retries](https://playwright.dev/docs/test-retries), [output directory](https://playwright.dev/docs/api/class-testproject#test-project-output-dir).
- [Mix deps.get](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html), [Mix](https://hexdocs.pm/mix/Mix.html), [compile](https://hexdocs.pm/mix/Mix.Tasks.Compile.html).
- [OWASP ASVS](https://asvs.owasp.org/) and [ASVS v5 CSV](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv).

## Metadata

**Confidence:** Stack HIGH (repo/docs read, candidate versions runtime-unverified); architecture HIGH (existing boundaries sourced); pitfalls HIGH (current failure paths/documented semantics sourced).
**Research date:** 2026-10-26
**Valid until:** 2026-11-25 for repo structure; recheck action/tool/browser versions before planning.


