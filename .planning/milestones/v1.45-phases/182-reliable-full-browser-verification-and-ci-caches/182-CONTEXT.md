# Phase 182: Reliable full browser verification and CI caches - Context

**Gathered:** 2026-10-26
**Status:** Ready for planning
**Milestone:** v1.45 Foundation and CI
**Working directory / branch:** `/Users/jon/projects/scrypath` / `planning/v1.45-foundation-ci`
**Research source:** `6957b3dc68670f36d1eb2275a944581735c1b8eb`, plus the pre-existing unrelated `.planning/config.json` edit, which must remain excluded from this work's commits.

<domain>
## Phase Boundary

Deliver BROW-01, BROW-02, BROW-03, CACHE-01 and CACHE-02: complete mounted/standalone browser verification through the existing canonical Docker command, truthful bounded exact-source hosted evidence, and safe Docker/BEAM cache reuse with cold-cache correctness.

Keep the five required jobs (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`) and the scheduled/manual advisory full-browser posture. Preserve supported visible UI and retained-preview data. Phases 183–185 own task relocation, dependency changes and UI quality foundations respectively. No implementation or successful full-browser/cache proof is claimed by this discussion.

</domain>

<decisions>
## Implementation Decisions

### Decision authority and contributor experience

- **D-01:** The maintainer explicitly requested research of all relevant decisions using subagents, adversarial consideration and automatic adoption of a cohesive recommendation set. These are agent-selected recommendations under that delegation, not individual maintainer votes or an independent formal review. Preserve the approved phase boundary; do not start plan/execute automatically.
- **D-02:** Keep `mix verify.ecommerce_e2e` / `make -C examples/scrypath_ecommerce verify-e2e` as the canonical full capability and the existing mounted equivalents as the focused capability. The Make entrypoint remains Docker-only. Add no application dependency, new fixture platform or required CI job. Prefer small explicit changes to the existing scripts and built-in reporters.

### Full stack, readiness and preview safety — BROW-01/02

- **D-03:** Append the existing `examples/scrypath_ecommerce/compose.phase173.yaml` only when verifier scope is `full`. Reuse its `standalone_ops` service and fixture database inside the same unique disposable project as mounted `web`, Postgres, Meilisearch and the browser. Focused scope keeps its existing service set, health and teardown behavior. Do not invoke a separate standalone suite to substitute for full-suite coverage.
- **D-04:** Validate the merged Compose model and require healthy dependencies plus bounded HTTP readiness for both actual Ops fixture routes before executing the full browser suite: mounted `/admin/search/phase173/health` and standalone `/ops/phase173/health`. A responding storefront `/` alone does not establish fixture readiness. Keep host ports unpublished, test-only fixtures gated and cleanup limited to the owned project. Collect diagnostics before teardown, preserve the original failure status, and verify disposal of owned containers, network and volumes on normal success/failure. Keep the explicit failed-stack debug escape hatch. Hard runner termination may prevent finalization; absent evidence cannot certify completion.
- **D-05:** Replace the two port-only follow-up guards with one consistent hostname-aware preview refusal rule, following `ui_baseline.spec.ts`: `http://web:4002` is the Docker target; the retained loopback preview on port 4002 remains refused before mutating steps. Preserve supported explicitly isolated local-port use. Exercise positive Docker and negative preview cases in executable guard checks; removing safety checks or turning missing Docker execution into accepted skips is rejected. Read `.planning/UI-PREVIEW.json` and follow its named-checkout/preflight protocol before any later retained-preview work; this discussion does not touch that preview.

### Coverage, test semantics and acceptance evidence — BROW-02/03

- **D-06:** Collect the expanded Playwright inventory using the same source/config/project selection as execution, then reconcile stable case identities against actual JSON outcomes. Include file, title path/project, entrypoint where applicable, outcomes and attempts. Fail clean-proof eligibility for missing/duplicate cases, unexplained skips, unexpected expected-failure masking or retry passes. Any intentional skip needs a concrete scoped reason recorded in the receipt; the intended follow-up/iteration-3 cases must execute, as must both mounted and standalone Phase173 scenarios. Historical approximate counts are not acceptance targets.
- **D-07:** Prefer one unfiltered full Chromium invocation with one worker and `retries: 0`, retaining the current serial database/state assumptions. Keep normal Playwright web-first assertion polling and readiness checks; they are different from retrying a failed test. Do not add arbitrary sleeps, weaken assertions, introduce grep/project exclusions or increase concurrency to obtain green evidence. If measured runtime later requires serial partitions, preserve disjoint reports/output directories and prove their complete union; parallel sharding requires evidence of fixture isolation, which this phase does not assume.
- **D-08:** Produce one authoritative aggregate, with a human-readable summary derived from it. Correct and wire `scripts/ci/phase105_evidence.sh` or replace it coherently; do not leave two competing evidence authorities. Bind collection, results and artifact inventory to the checked-out commit, built/runtime image identity, Compose scope/targets, browser/package version, workflow event/ref/run ID/run attempt and stage timings/statuses. On hosted acceptance, compare the actual checkout to the event SHA and the built source identity; a branch name or successful unrelated check is insufficient. Local dirty runs need a source fingerprint and are not clean exact-commit hosted proof. Read the verifier step's raw outcome as well as the advisory job's conclusion; `continue-on-error` is not a pass.
- **D-09:** Use a fresh owned artifact location per run. Retain inventory, full Playwright JSON/HTML and failure traces, applicable screenshots (including `ui-review-artifacts/iteration3-journeys`), deterministic checker results, Compose health/logs and cleanup/evidence failures. Copy only this run's known outputs before teardown; do not upload a retained preview's review directory or old local captures. Required missing/malformed reports and failed artifact copies block an otherwise successful proof; on an already failed run, keep partial diagnostics without replacing the original cause. Keep bounded logs/artifacts and the existing seven-day hosted retention. Never interpret absent/empty input as successful zero cases.
- **D-10:** Reconcile stale browser expectations against the current fixture and rendered behavior, specifically the `unknown_module` versus `unknown_backend` assertion in `admin_screenshots.spec.ts`, using the existing job-argument decoding contract. Preserve the distinction between unavailable/unknown and healthy/empty. A genuine product regression must not be hidden by changing expected text. Preserve historical evidence; no automatic baseline update or UI redesign is authorized. The current light-baseline checker proves file inventory and widths, not pixel parity or aesthetic approval. Prefer current shipped UI/design authority and `brandbook/` over the older exploratory brand prompt when resolving an actual conflict.
- **D-11:** Set the full scheduled/manual job budget to 30 minutes, including setup/build, readiness, browser checks, deterministic follow-up checks, collection, cleanup and upload. Use an inner execution deadline with measured finalization margin so the job-level timeout is the last resort. Keep actionable timeout diagnostics. Require a successful complete hosted run at the changed source SHA; a retry run does not erase its earlier failure or become clean stability evidence. Cache warm/cold validation is a separate requirement and need not force that full hosted proof to be cold. Do not trade away coverage or exceed the approved budget to meet it.

### Docker cache reuse — CACHE-01

- **D-12:** Prefer Docker's official SHA-pinned Buildx setup and Bake action in CI, reading the same resolved Compose build graph and local checkout context as the verifier. Load the resulting images locally without registry publication. Use an explicit shared project/image identity and a checked prebuilt-image handoff so Compose consumes precisely those images without a second build. Keep the ordinary local canonical command on its existing uncached-capable Compose build path, with no GitHub runtime credentials required. Avoid a third-party runtime-token helper or an independently maintained second build graph. The planner must prove model/tag/source parity before enabling the hosted prebuild path.
- **D-13:** Use GHA cache API v2 with supported pinned Buildx/BuildKit versions, stable separate scopes for distinct image recipes (application versus browser) and bounded import/export time. Identical mounted/standalone application recipes may share the application build result when built once; otherwise give concurrent exporters distinct scopes. Preserve manifest/lock-before-source Dockerfile layering. A cache scope must not be the changing source SHA, and distinct image recipes must not overwrite the default `buildkit` scope. Prefer the scheduled/manual full job as the shared cache writer and the mounted job as an importer; keep untrusted PRs from exporting trusted shared state. Cache export failure is an explicit performance warning, not a test failure or a fabricated cache hit. No cache credentials, private data or test results belong in exported layers. Prove actual restore/export logs: merely enabling a builder, warm local layers or silently ignored Compose cache fields do not satisfy CACHE-01. BuildKit cache mounts are not assumed to persist through GHA layer-cache export.

### BEAM cache correctness — CACHE-02

- **D-14:** Separate download-cache fallback from resolved dependency/build reuse rather than adding broad `restore-keys` to the current combined `deps`/`_build` archive. Prefer the Hex package-archive directory (`~/.hex/packages`) for cross-lock download reuse; cache Rebar downloads only if the selected paths are verified to contain downloads rather than compiled output. Namespace keys by cache schema, graph/project, runner OS image/architecture, exact resolved Elixir/OTP, actual compile environment/target/profile and relevant manifest/lock inputs, including path-dependency graphs where used. Download fallback may omit the lock only within compatible platform/toolchain/environment/graph boundaries; always run `mix deps.get` and the normal compile/verification commands afterward. `deps/` can contain generated/native outputs, so do not describe it as inherently portable pure source. Never share arbitrary compiled/NIF outputs across ABI boundaries or cache credentials by archiving all of `~/.hex` or `~/.mix`.
- **D-15:** Resolved `deps` plus compiled build reuse must retain the exact graph/lock/manifests/toolchain/environment boundary; they may share one strictly keyed archive so restoring build manifests preserves corresponding dependency source timestamps. A primary key may append a relevant source fingerprint so immutable caches can refresh after source changes; the restore prefix can omit that source fingerprint while retaining all compatibility inputs, letting Mix recompile changed/path-dependent code. A lock change intentionally invalidates compiled reuse. Cache only the intended ordinary environment directories; keep no-optional builds and fresh package-consumer proof isolated. Keep PLTs scoped to their exact analysis toolchain/graph/lock and compatible inputs. A key labelled `test` must not silently pool incompatible build profiles. Reconcile these rules across the existing affected cache steps without adding a cache abstraction dependency or changing support tuples.
- **D-16:** Caches accelerate work and never decide whether `deps.get`, compilation, tests, or the verifier runs. Prove a warm Docker restore/export, a build with import disabled on a genuinely fresh builder, BEAM fallback within a compatible namespace, lock invalidation and representative cold-cache job execution. Use run-local bypasses or fresh namespaces/runners; do not delete shared repository caches. A random new scope alone is not cold proof if an existing local builder still contains layers. Keep source SHA, tuple, hit/miss/fallback and command result with each receipt. These cache proofs may be separate from the successful full-browser hosted receipt.

### Executable protection and phase limits

- **D-17:** Put deterministic infrastructure regressions in existing repository-contract lanes: resolved full/focused service scope, preview guard truth table, strict inventory/outcome reconciliation, missing/malformed evidence, retry/skip/duplicate masking, artifact-copy failure and cache-key boundary/invalidation checks. Test behavior with small synthetic reports or Docker command doubles where appropriate, and retain real Docker/hosted runs as integration acceptance. Contract-string assertions alone do not prove cache reuse, service readiness or browser success. Keep warnings-as-errors for changed test infrastructure per CONTRIBUTING.
- **D-18:** Do not activate or depend on the legacy paid judge, supply API keys, fabricate judge success or make its result part of new acceptance. Phase 185 owns deleting the dormant legacy path and wiring; the evidence schema must already work without it. Task relocation stays Phase 183; dependency upgrades/graph pruning stay Phase 184; token enforcement/storybook/new UI engine or polish remain their approved later phases. Reconcile merged-main ancestry before implementation as required; discussion source is not a claim of latest-main or v1.44 merge/publication.

### Agent's Discretion

- Small helper/module names, cache schema version and source-fingerprint granularity, exact internal deadline/margin based on measurement, and the aggregate's representation while preserving one authority.
- Reusing or replacing the legacy evidence script, with compatible historical filenames/readers reconciled explicitly.
- Exact official action versions/pins and flags after checking current primary documentation. No version from research is an unverified upgrade mandate.
- Deduplicating application image builds when the resolved recipes are truly identical; any prebuild fallback must retain source/model/image parity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read relevant sections before planning or implementing.** Paths are repository-relative unless an HTTPS source is given.

### Scope and authority

- `.planning/ROADMAP.md` — Phase 182 success criteria and milestone phase boundaries.
- `.planning/REQUIREMENTS.md` — BROW-01/02/03 and CACHE-01/02; verification and source-evidence constraints.
- `.planning/PROJECT.md` — verification, GSD handoff and green-main release-train defaults; current v1.45 claims.
- `.planning/reference/ROLLING-ROADMAP.md` §3 — original findings, with historical counts superseded by executable inventory.
- `CONTRIBUTING.md` — canonical commands, warning policy, lean gate topology and source-bound closeout.
- `.planning/research/ui-quality-engine/RECOMMENDATIONS.md` — D4/D6 and approved build order; defer the new engine.
- `.planning/research/ui-quality-engine/RESEARCH-AUTOMATION-CI.md` — current deterministic checks, known misleading parity/judge claims and historical timing context, not a new passing receipt.
- `.planning/research/ui-quality-engine/INVENTORY.md` — existing screens/checks/fixture assets; no new inventory platform.

### Orchestration, browser and evidence

- `.github/workflows/ci.yml` — actual required/advisory jobs, caches, event selection, timeouts and artifact upload.
- `lib/mix/tasks/verify/capability.ex`, `lib/mix/tasks/verify/ecommerce_e2e.ex`, `lib/mix/tasks/verify/ecommerce_mounted.ex` — existing canonical dispatch; Phase 183 will later relocate maintainer tasks.
- `examples/scrypath_ecommerce/Makefile`, `examples/scrypath_ecommerce/scripts/verify-e2e.sh`, `examples/scrypath_ecommerce/scripts/verify-phase173.sh`, `examples/scrypath_ecommerce/docker-playwright.sh` — single capability, project ownership and readiness/collection patterns.
- `examples/scrypath_ecommerce/compose.yaml`, `examples/scrypath_ecommerce/compose.e2e.yaml`, `examples/scrypath_ecommerce/compose.phase173.yaml` — full/focused merged models and existing standalone fixtures.
- `examples/scrypath_ecommerce/Dockerfile`, `examples/scrypath_ecommerce/Dockerfile.e2e`, `examples/scrypath_ecommerce/playwright.config.ts`, `examples/scrypath_ecommerce/package.json`, `examples/scrypath_ecommerce/package-lock.json` — builds, serial test discovery and locked browser package.
- `examples/scrypath_ecommerce/e2e/ui_baseline.spec.ts`, `examples/scrypath_ecommerce/e2e/ui_followup.spec.ts`, `examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts` — safe URL guard, intended currently skipped cases and screenshot paths.
- `examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts`, `examples/scrypath_ecommerce/e2e/phase173_time.spec.ts`, `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`, `examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts` — expanded mounted/standalone discovery and route/state contracts.
- `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts`, `lib/scrypath/oban/job_args.ex` — stale unknown-backend assertion and current decoding semantics.
- `examples/scrypath_ecommerce/e2e/admin-light-baseline-check.mjs`, `scripts/ci/phase105_evidence.sh`, `examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts` — actual inventory checker and legacy evidence paths/source metadata.
- `test/mix/tasks/workflow_wiring_test.exs`, `test/mix/tasks/verify_capability_test.exs`, `lib/mix/tasks/verify.no_optional_deps.ex` — existing wiring contracts and isolated optional-dependency compile.

### Preview, design and local research

- `.planning/UI-PREVIEW.json`, `.planning/reference/UI-WORKTREE-LEARNINGS.md`, `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` — named preview source, safety and rendered-review boundaries before any preview work.
- `.planning/reference/OPERATOR-UI-QUALITY.md`, `DESIGN.md`, `brandbook/README.md` — maintained roles/jobs, supported visual direction and newer brand source if assertion reconciliation touches visible expectations.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/phoenix-best-practices-deep-research.md`, `prompts/elixir-opensource-libs-best-practices-deep-research.md` — relevant ecosystem/testing/OSS guidance; approved current gates override older generic suggested topologies.

### Primary external sources checked during discussion

- [Compose health dependencies](https://docs.docker.com/compose/how-tos/startup-order/) — actual service readiness, rather than start order alone.
- [Docker Bake action](https://github.com/docker/bake-action) and [Compose build specification](https://docs.docker.com/reference/compose-file/build/) — action-managed builds from Compose and local image handoff.
- [Docker GHA cache backend](https://docs.docker.com/build/cache/backends/gha/) and [GitHub Actions build cache](https://docs.docker.com/build/ci/github-actions/cache/) — v2, credentials, driver/scope and cache limitations.
- [GitHub dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) — immutable keys, fallback matching, branch access and avoiding sensitive cache content.
- [setup-beam](https://github.com/erlef/setup-beam/blob/main/README.md), [Mix deps.get](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html) and [Mix compile](https://hexdocs.pm/mix/Mix.Tasks.Compile.html) — resolved toolchains, dependency reconciliation and recompilation.
- [Playwright CLI](https://playwright.dev/docs/test-cli), [retries](https://playwright.dev/docs/test-retries), [skip](https://playwright.dev/docs/api/class-test#test-skip), [output directories](https://playwright.dev/docs/api/class-testproject#test-project-output-dir) and [best practices](https://playwright.dev/docs/best-practices) — actual collection/outcomes, isolation and resilient user-facing assertions.
- [GitHub workflow events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule) — schedule/dispatch source identity.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `verify-e2e.sh` already owns a unique Compose project, source SHA export, logs/copy-before-teardown and a failed-stack retention switch. Extend this spine rather than add another verifier.
- `compose.phase173.yaml` already defines the standalone app, dedicated test database, health check and browser dependency. The full suite already discovers its specs.
- Built-in Playwright `--list` and JSON/HTML reporting, existing Node tooling and ExUnit can implement coverage/evidence checks without a new dependency.
- Dockerfiles already separate dependency manifests/locks from full source copying. Existing source metadata and evidence helpers can be reused after reconciling their paths and strictness.

### Observed Findings and Evidence Limits

- Research ran `npm run test:e2e:list` successfully in `/Users/jon/projects/scrypath/examples/scrypath_ecommerce` using the installed local package: **189 tests in 20 files**; `ui_followup` expands to **7**, `ui_iteration3` to **6**, Phase173 specs to **38** across mounted/standalone. This is collection only, not execution or proof that runtime guards allow those cases. Recollect at implementation source.
- Both target guards currently reject any port 4002, including Docker `web:4002`; `ui_baseline` distinguishes loopback hostname. Full Compose assembly omits the standalone overlay, although full Playwright discovery already includes its cases. Historical standalone DNS failures mean missing service coverage, not missing discovery.
- `docker-playwright.sh` currently makes one Playwright invocation. Its later light-manifest checker is Node-only and does **not** overwrite the Playwright report. If future partitions are introduced, Playwright cleans its output directory at invocation start, so separate directories become mandatory.
- `verify-e2e.sh` suppresses artifact-copy errors and does not collect the iteration3 journey directory. Current hosted upload warns on missing files; the full timeout is 20 minutes.
- `phase105_evidence.sh` is not wired into this canonical flow; it expects different report paths and permits missing inputs to become empty/unknown data. Do not use its existence as proof of complete evidence.
- Existing CI caches combine `deps` and `_build`, have no fallback keys, and many root jobs share the same manifest/lock key. Deep-quality also carries PLTs. Preserve isolated no-optional and consumer builds when improving reuse.

### Integration Points

- Root Mix capability → demo Make target → owned Compose model → browser runner → reports/aggregate → existing advisory artifact upload.
- CI Buildx/Bake preparation → exact loaded image identity → same canonical verifier, with an ordinary local cold-build path.
- Existing repository-contract tests protect deterministic wiring; actual hosted source-bound receipts prove the service/browser/cache behavior.

</code_context>

<specifics>
## Specific Ideas

- Optimize for contributors diagnosing a red run and maintainers judging whether coverage is complete; adopters gain confidence without additional setup or package dependencies.
- Relevant lenses were contributor DX, Phoenix/Ecto integration correctness, browser/accessibility behavior, SRE readiness/cleanup/time budgets, CI cost, cache/ABI security and evidence provenance. Borrow Docker/Playwright's established tooling patterns; unrelated library/API or visual redesign comparisons do not help this phase.
- The maintainer prefers another small copy/paste over another dependency. Use existing tools and official build actions; do not introduce a custom cache framework, reporting service or new test platform.

</specifics>

<deferred>
## Deferred Ideas

- Phase 183: move maintainer verifier tasks/support outside the Hex package.
- Phase 184: dependency range changes, pruning, advisory remediation and reconciled graphs.
- Phase 185: token/contrast/drift prerequisites and deletion of the dormant paid-judge path; no judge activation in this phase.
- v1.46+: storybook fixture migration/UI engine; later surface extraction, visual baselines and polish.
- New required browser lane, broad browser/OS matrix, new product APIs, UI redesign and inherited unrelated audit debt remain outside this phase.
- PR #122/publication and merged-main reconciliation are distinct delivery work; this discussion creates no new receipt for archived source.

</deferred>

---

*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Discussion complete; implementation and requirement verification remain pending.*
*Next: `$gsd-plan-phase 182` from `/Users/jon/projects/scrypath`.*
