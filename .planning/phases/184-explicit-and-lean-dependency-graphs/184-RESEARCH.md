# Phase 184: Explicit and lean dependency graphs — Research

**Researched:** 2026-10-29
**Domain:** Elixir/Mix dependency ownership, Phoenix compile/runtime boundaries, Req consumer compatibility, asset build stages, dependency security and GitHub Actions
**Confidence:** HIGH for repository seams and locked scope; MEDIUM for current upstream version/advisory snapshots that must be revalidated when executing.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions


### Dependency ownership and consumer ergonomics

- **D-01:** Prefer the existing stack and small local helpers over new dependencies/frameworks or public feature-configuration systems. Flatten unused dependency trees, but retain maintained HTTP/authentication/cryptography/build implementations. Directly declare packages whose public APIs Scrypath actually calls; indirect availability is not a contract.
- **D-02:** Declare mandatory root `{:telemetry, "~> 1.0"}` and `{:req, "~> 0.6.1 or ~> 0.7"}` exactly as approved. Use the same Req union in Ops/ecommerce direct declarations so their old bounds do not force one line across the host graph. Verify these requirements in the actual built package metadata; an existing transitive Telemetry dependency must not mask an omitted direct declaration.
- **D-03:** Extend the existing package-consumer proof, rather than create another verifier architecture: one built/unpacked archive, two clean consumer workspaces, independent dependency/build/lock identities, direct non-overriding Req witness constraints `~> 0.6.1` and `~> 0.7.0`, and assertions on the actual resolved versions. Both consumers exercise the same public Scrypath HTTP request/response and telemetry contract. Prefer maintained `Req.Test`/Plug fixtures with explicit test-only fixture dependencies. Keep no-Oban/no-optional dependency proof and the package tooling boundary established by Phase 183.
- **D-04:** Preserve the approved broad `~> 0.7` bound; do not silently narrow it to `~> 0.7.0` in shipped metadata. Explain that it admits stable versions below 1.0 while the two concrete witnesses prove only the selected 0.6.x/0.7.x versions/toolchains. Select compatible stable releases, not Req 0.8 prereleases. Revisit resolution/support on a stable new minor, changed JSON/transport APIs, or a changed upstream toolchain floor.

### Mail, diagnostics and application ownership

- **D-05:** Remove the complete unused Swoosh/Mailer slice from Ops and duplicated ecommerce declarations: manifest entries, Mailer module, application config, mailbox/dead references and the obsolete Swoosh-only client test. Prune obsolete locks after checking the active graph; do not remove a transitive package still used elsewhere merely to satisfy a textual name ban.
- **D-06:** Scope LiveDashboard, `telemetry_metrics` and `telemetry_poller` to direct Ops source development (`only: :dev`); retain the standalone development dashboard/metrics experience. Mounted Ops does not impose this diagnostic slice. Direct standalone test/production retains supported operator routes and core functionality, without this developer diagnostic slice. A host may choose its own diagnostics; the guarantee concerns what Ops forces into its graph.
- **D-07:** Compile and start the diagnostic slice consistently. Guard its imports/macros/routes/module compilation, `Phoenix.LiveDashboard.RequestLogger` plug and `ScrypathOpsWeb.Telemetry` supervisor child at the appropriate boundary; a runtime flag alone cannot make missing compile inputs safe. Keep existing runtime `standalone` endpoint/Repo ownership, core `:telemetry` producers, `RecoveryObservation`, PubSub and TaskSupervisor. Do not drive dependency lists from runtime configuration or pretend toggling `standalone` changes installed code.

### Assets and clean environment boundaries

- **D-08:** Keep esbuild/Tailwind as the existing Mix tools, dev-only in Ops and in the ecommerce app's own declarations. Preserve normal dev commands/watchers. Generate current-source Ops and storefront static bundles in an isolated dev asset-builder stage, then copy only required `priv/static` output into independently resolved/compiled test or production builds. Keep current tool-version authorities and UI output; use the target-environment digest step where needed. Do not introduce a second npm/CLI asset framework just to replace the wrappers.
- **D-09:** Reconcile Docker, E2E entrypoints, aliases and docs with that build boundary. The current test-runtime asset installation/build calls must move out of `docker-e2e-entrypoint.sh`. Test/prod compile/start/serve must succeed without installing esbuild/Tailwind as Mix dependencies. Never copy dev dependencies, compiled BEAMs, `_build/dev`, or dev config into the final stage. Host-owned dev asset tools remain legitimate; absence is required in test/prod, not every host dev graph. Verify clean environments and generated `.app` requirements, code paths, loaded/started apps and behavior separately; do not substitute raw BEAM string absence or a dirty local cache for those checks.

### Optional Sigra and fail-closed behavior

- **D-10:** Relax Ops Sigra to `{:sigra, "~> 1.5", optional: true}` and verify the selected compatible current stable 1.x release. Preserve root/core Elixir 1.17 and existing OTP compatibility policy; document Sigra's intrinsic Elixir 1.18+ tier separately. Direct Ops development and the dev asset builder include optional dependencies, so use a compatible tested toolchain or prove a specific dependency-excluded build path. An upstream `.tool-versions` is not a declared consumer OTP floor: do not infer OTP 27 as a new minimum. Verify with-Sigra and without-Sigra cases on the appropriate supported tuples.
- **D-11:** Explicitly requested Sigra auth must fail clearly at validation/startup when the required integration is unavailable, even if a sudo confirmation path is configured. Add executable dependency-absent negative coverage. Preserve supported basic/proxy-host modes without Sigra. The discovered permissive fallback is a source-inspection finding, not a demonstrated remote authentication bypass.
- **D-12:** In requested Sigra mode, sensitive-action gating must reject missing/invalid operator context rather than invoke the callback. Verify present-dependency behavior, stale/fresh sudo, impersonation denial and action audit identity. Keep the host responsible for route/LiveView authentication; the auth-mode selector alone is not an authentication system. Correct the missing guide reference through focused existing setup/support documentation rather than a new auth abstraction.

### Coordinated upgrades and security truth

- **D-13:** Remediate the affected Bandit version in Ops and both example lockfiles using a verified fixed stable release admitted by existing bounds. Research found 1.14.1 compatible with `~> 1.13`; revalidate current advisory/version/toolchain evidence before selection. Do not churn a compatible manifest constraint merely to move its lock.
- **D-14:** Treat root, Ops, Phoenix example and ecommerce as four independently resolved graphs. Use scoped updates and unused pruning, coordinate direct dependency ranges/path-dependency inputs, and verify each resulting lock. Prefer one current compatible stable Req 0.7.x default plus the separate 0.6.x consumer witness; coordinate Oban across its consumers while preserving optional/no-Oban and job behavior. Do not globally unlock, merge stale root-only locks sequentially, or confuse one lock with range-wide proof.
- **D-15:** Incorporate compatible root development updates from the referenced StreamData, ExDoc and Dialyxir proposals as a coherent verified tooling batch. Check actual selected versions against existing runtime support; test properties, warnings-as-errors docs and analysis rather than assuming an admitted version works. Preserve the support floor if a proposed version is incompatible and record the concrete version disposition.
- **D-16:** Record a verified disposition for all ten referenced Dependabot PRs: #65 and #68–#76. Reconcile compatible Actions changes in coherent workflow slices within this approved update set, checking runtime/runner requirements, permissions, checkout credentials and Phase 182 cache semantics. Each PR gets incorporated, superseded/equivalent, or specifically blocked/deferred with reason, source/version, evidence and revisit trigger. Do not silently drop workflow majors, blindly cherry-pick bot branches, change required-job topology, or close/merge/publish remotely as part of bookkeeping.
- **D-17:** Audit all four final graphs and retain complete per-graph status, raw failures and evidence identity. Fix compatible available issues; keep unfixable Cloak/Cloak Ecto findings explicit. Relaxing Sigra does not remove its required Cloak Ecto dependency. Usage/reachability limits (such as AES-GCM instead of CTR or no inspected PBKDF2 use) are not a clean package audit or risk acceptance. No new audit ignore, swallowed exit, weakened advisory semantics, vendored crypto patch or blanket all-green claim.
- **D-18:** Separate compatibility, dependency-audit and runtime-security claims. Preserve the existing core floor/tested tuples while reporting the observed upstream OTP 26 maintenance status accurately; no silent support-floor raise or claim of ongoing upstream security support. Preserve dated historical evidence, and replace stale current claims about what Sigra widening fixes. Revisit residual findings on an upstream fixed release, changed reachable use/configuration, new relevant advisory or explicit maintainer policy decision.

### Verification, UI preservation and delivery

- **D-19:** Reuse the five required jobs and existing advisory/path-scoped lanes. Put the dependency/consumer predicates into the applicable current core/package/repository/backend/mounted proofs; verify Ops optional/auth paths and both independent asset outputs. Run changed-scope executable checks on supported toolchains and CONTRIBUTING's exact-source closeout at execution. Passing captures, root-only audits, a selector job, pending UAT or simulated approval cannot substitute for the relevant proof. This context does not claim any new implementation check has passed.
- **D-20:** Preserve supported operator/storefront routes, assets, copy, light/dark appearance, keyboard behavior and host endpoint/Repo ownership. No redesign, token change, new feature, paid review or baseline auto-update. Implementation that touches Ops/storefront must follow the named-preview/preflight/review rules, preserve data and use disposable verification stacks; this discussion did not edit/restart/reseed that preview. Keep serious work PR-first and publication/merge authority separate.
- **D-21:** Keep support/developer commands accurate and centralized: update the canonical support guide, affected setup/build/integration docs and capability runbooks together with behavior. Distinguish released package guidance, unreleased source changes, direct Ops development, mounted hosts and optional Sigra requirements. Preserve the Phase 183 repository-only verifier/package boundary and unrelated `.planning/config.json` edits.

### the agent's Discretion

Choose helper names, exact compiler directory organization for dev-only diagnostics, test fixture layout, assertion wording, scoped update sequence and compatible stable versions after revalidation. Reuse existing test/verifier seams and cache isolation rules. These are engineering choices delegated by the maintainer, not permission to expand public API/support scope, accept security risk or add delivery actions. Stop research when additional surveys would not change a decision; record concrete implementation uncertainties for phase research rather than manufacturing more questions.

## Deferred Ideas

Phase 185's token/contrast/quality work, v1.46–v1.48 UI/adopter capabilities, public backend abstraction, auth replacement, crypto vendoring, runtime support-floor changes, public security-risk acceptance, publication and remote PR cleanup remain outside this phase discussion. No pending todos matched this phase. Cloak/Cloak Ecto upstream remediation remains explicit unresolved dependency debt with revisit triggers; it is not marked accepted or fixed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| DEP-01 | An adopter receives an explicit root dependency on telemetry ~> 1.0, and the existing instrumentation remains available without relying on another dependency to supply it. | Direct declaration, package metadata assertion, public telemetry event proof in the package consumers. |
| DEP-02 | An adopter can resolve and use Scrypath with Req matching ~> 0.6.1 or ~> 0.7, with focused HTTP/consumer verification for both admitted version lines. | Extend archive consumer harness with independent witnesses and actual resolved-version assertions; exercise same request/response contract. |
| DEP-03 | An operator can run ScrypathOps without Swoosh or the unused Mailer, with their configuration, references and obsolete lock entries removed. | Remove full unused mail slice from Ops and ecommerce; prune only packages no longer active in their graph. |
| DEP-04 | An adopter can mount ScrypathOps without loading its standalone/development dashboard and telemetry polling/metrics dependencies; the supported standalone/development diagnostics and core Scrypath telemetry still work in their intended modes. | Environment-scope diagnostics and gate compile imports/macros/routes, endpoint plug, telemetry module and child start; test both mounted and direct standalone/dev behavior. |
| DEP-05 | An adopter can compile/run ScrypathOps in test and production without installing esbuild or Tailwind as Mix dependencies; development asset build commands remain usable. | Dev-only wrappers plus isolated asset builder; clean independent test/prod build and start with output-only static copy; remove E2E entrypoint runtime installs. |
| DEP-06 | An adopter can use the approved compatible Sigra version range without the current patch-series restriction, with the optional integration and relevant auth behavior verified; dependency-audit results remain explicit and are not silenced to obtain a pass. | Retain the approved range, reselect non-retired compatible stable, test available/absent behaviors and audit all four resulting graphs without silencing failures. |
| DEP-07 | A maintainer receives one reconciled dependency update set across affected manifests and lockfiles, with a recorded disposition for the roadmap's referenced Dependabot changes (#65 and #68–#76), supported-stack verification and an explicit account of remaining advisories. | Four lock identities, PR disposition ledger, supported tuple execution and exact-source/per-graph security evidence. |
</phase_requirements>

[VERIFIED: .planning/REQUIREMENTS.md, DEP-01–DEP-07]

## Project Constraints (from AGENTS.md)

- Maintain Scrypath as an Ecto-first Elixir library with Phoenix-friendly integrations; public v1 targets Meilisearch while keeping the adapter seam internal.
- Preserve inline, Oban-backed and manual synchronization, minimal setup, operational clarity and the pre-release quality bar.
- Keep main green on five lean required gates, prefer PR-first for serious scope, and support completion with executable or exact-source hosted evidence.
- Follow CONTRIBUTING.md for verification, CI and release gates; the current support guide remains the canonical adopter-facing source.
- Preserve unrelated user edits, including .planning/config.json. Do not transfer older files over newer behavior during worktree operations.
- If implementation touches Ops/storefront UI, follow UI-PREVIEW.json, named checkout, preflight, review, and retained-data rules. Use disposable test stacks; never start, restart or reseed the retained preview.
- No product-scope edits unless the phase intentionally changes shipped claims. Phase 185 and later UI/adopter work remain out of scope.

[VERIFIED: AGENTS.md; CONTRIBUTING.md]

## Summary

Treat Phase 184 as a coordinated graph-boundary change, not a version bump sweep. Root package metadata and installed-consumer behavior must establish mandatory direct Telemetry and both Req lines. Ops diagnostics and wrappers must be excluded at dependency and compiler boundaries; static assets need a separate builder whose output alone enters clean test/production graphs. The mail slice is removed only where unused. Optional Sigra must stay optional and fail closed when explicitly requested but unavailable. Four independently resolved graphs, ten PR dispositions and unfiltered audit results must remain traceable to the final source. [VERIFIED: phase context and requirements; repository sources cited below]

**Primary recommendation:** Plan the work in vertical proof slices: root consumer contract; Ops dependency/compiler/runtime boundary; static asset builder and clean target proof; Sigra fail-closed modes; coordinated per-graph versions, audits and documentation. Sequence graph updates after manifest/source boundaries are clear, then run target checks on supported tuples. Keep the five required CI jobs and current advisory/path-scoped lanes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Mandatory public HTTP and telemetry dependencies | API / Backend | Package consumer | Public library code calls Req and emits Telemetry, so its archive must directly declare them and consumers must resolve the actual boundary. |
| Ops diagnostics and optional Sigra integration | API / Backend | Host application | Ops owns its development diagnostic/auth integration code; a mounted host owns Endpoint/Repo and route authentication. |
| JavaScript/CSS generation and delivery | Build / Static | Phoenix host | Existing Mix wrappers generate bundles; an isolated build stage owns tool installation, and the target runtime serves copied static output. |
| Dependency advisory and workflow maintenance | CI / Release | Four graph owners | Lockfiles and Actions versions resolve independently; each proof must identify its graph and source. |

[VERIFIED: Scrypath public API and dependency sources; official Mix/Phoenix docs]

## Standard Stack

This is a dependency-boundary phase; do not add a new framework or asset tool. Existing packages are already used in the repository. Versions below are current stable observations as of 2026-10-29, not required manifest ceilings; revalidate before lock changes.

| Package / graph | Research-time current stable | Purpose | Planning instruction |
|---|---:|---|---|
| Telemetry / root | 1.4.2 | Core instrumentation; declare approved direct range ~> 1.0. | Keep exact approved bound and assert packaged direct metadata. [VERIFIED: Hex API, https://hex.pm/api/packages/telemetry] |
| Req / root, Ops, ecommerce | 0.7.5 | HTTP client and maintained Req.Test support. 0.8.0-rc.0 was prerelease. | Approved union remains ~> 0.6.1 or ~> 0.7; test 0.6.x and 0.7.x witnesses. [VERIFIED: Hex API, https://hex.pm/api/packages/req; https://hex.pm/packages/req/versions] |
| Sigra / Ops | 1.7.1 usable compatible stable | Optional operator integration; Elixir ~> 1.18, still requires Cloak Ecto ~> 1.3. | D-10's ~> 1.5 is the locked range. Sigra 1.20.0 reports as latest stable in metadata but is retired; do not select it. Do not change the core Elixir 1.17 floor or infer an OTP 27 minimum. [VERIFIED: Hex API, https://hex.pm/api/packages/sigra/releases/1.7.1 and https://hex.pm/api/packages/sigra/releases/1.20.0] |
| Bandit / Ops and both examples | 1.14.1 | Phoenix HTTP server. | Existing ~> 1.13 admits 1.14.1; update affected locks, recheck advisory data and behavior. [VERIFIED: Hex API, https://hex.pm/api/packages/bandit/releases/1.14.1] |
| Oban / core consumers | 2.24.2 | Optional background-job integration. | Coordinate selected compatible stable version across graph consumers; preserve optional/no-Oban behavior. [VERIFIED: Hex API, https://hex.pm/api/packages/oban/releases/2.24.2] |
| StreamData / root test | 1.4.0 | Property-based testing. | Consider as approved dev/test tooling update; execute relevant properties. [VERIFIED: Hex API, https://hex.pm/api/packages/stream_data/releases/1.4.0] |
| ExDoc / root docs | 0.40.4 | API documentation generation. | Existing root ~> 0.37 excludes it; adjust only as needed for approved batch, then run warnings-as-errors docs. [VERIFIED: Hex API, https://hex.pm/api/packages/ex_doc/releases/0.40.4; mix.exs:129] |
| Dialyxir / root analysis | 1.4.8 | Static type analysis. | Check selected version on supported tuples and keep audit/analysis evidence separate. [VERIFIED: Hex API, https://hex.pm/api/packages/dialyxir/releases/1.4.8] |
| LiveDashboard / telemetry_metrics / telemetry_poller | dashboard 0.8.3 line; metrics 1.2.0; poller 1.3.0 | Development-only Ops diagnostics. | D-06 scopes direct Ops source to only: :dev; gate consumers of those modules too. [VERIFIED: Hex API https://hex.pm/api/packages/phoenix_live_dashboard, /telemetry_metrics, /telemetry_poller] |
| esbuild / Tailwind wrappers | esbuild 0.10 line; tailwind 0.3 line | Existing Phoenix asset tasks. | Retain current tool-version authorities and dev tasks; build in isolated asset stage. [VERIFIED: Ops/ecommerce mix.exs, lines cited below; official wrapper docs] |

[VERIFIED: mix.exs:14,115-130] The repository declares the Elixir range as ~> 1.17 and its direct dependency list includes Ecto, NimbleOptions, optional Oban, Req ~> 0.6.1, Jason, test Plug/StreamData/Ecto/Postgres dependencies, and dev/test tooling. The quoted root lines do not contain a direct Telemetry entry. This is the exact seam for DEP-01/02 and root tooling work.

[VERIFIED: scrypath_ops/mix.exs:41-65] The current Ops manifest includes Sigra ~> 1.5.0 optional, LiveDashboard ~> 0.8.3, esbuild/tailwind with runtime: Mix.env() == :dev, Swoosh, Req ~> 0.6.1, telemetry_metrics, telemetry_poller and Bandit ~> 1.13. Runtime flags on esbuild/tailwind do not express D-08's test/prod dependency absence.

The repository's existing tested compatibility tuples are Elixir/OTP 1.17/26, 1.18/27, 1.19/26 and 1.19/28; keep these claims and the current floor unchanged during this phase. [VERIFIED: CONTRIBUTING.md:229, quoted values: “1.17/26, 1.18/27, 1.19/26, and 1.19/28”] The official Erlang release-status page reports OTP 26 maintenance has ended as of the research snapshot. State compatibility separately from upstream security maintenance; do not describe OTP 26 as receiving current upstream security fixes or raise the floor silently. [CITED: https://www.erlang.org/versions?v=26.2.5.3; D-18]

The prior dated audit reports remaining Cloak and Cloak Ecto advisories after Bandit correction. Its reviewed exposure notes AES-GCM in Sigra's generated vault and no inspected use of the affected PBKDF2 type; these narrow inspected paths do not clear package-level audit results or accept risk. Preserve those findings with raw final graph audits and revisit only on upstream fixed release, changed reachable use/configuration, relevant new advisory or explicit maintainer policy. [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-95105; https://osv.dev/vulnerability/EEF-CVE-2026-94206; .planning/phases/184-explicit-and-lean-dependency-graphs/184-RECOMMENDATIONS.md]

**Package legitimacy audit:** No new package is proposed; the phase promotes already-present or transitive packages to explicit declarations and changes bounds/scopes. The prescribed package-legitimacy seam supports npm, PyPI and Cargo, not Hex; do not claim a Hex legitimacy verdict. Check the official Hex metadata links above and keep fixture dependency declarations limited to existing test dependencies. [VERIFIED: package-legitimacy tool usage; repository manifests]

## Architecture Patterns

### Dependency and runtime boundary

[CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html; https://hexdocs.pm/mix/Mix.Project.html] Mix separates environment availability via only:, runtime application inclusion, and optional downstream imposition. A runtime: false dependency remains in the dependency graph and compile path; a dependency usually compiles as part of a library project in prod. Optional dependencies are included by the project that declares them but are not imposed on downstream consumers. The implementation should make each desired boundary explicit in both Mix metadata and source compilation/startup rather than expecting one setting to do all jobs.

#### Ops ownership map (conceptual flow)

| Boundary | Required behavior |
|---|---|
| Ops source in dev | Compile diagnostics and asset wrappers; standalone development keeps dashboard/metrics and usual build/watch commands. |
| Ops mounted in host | Do not force development diagnostics; host owns its Endpoint and Repo, and remains free to choose its own diagnostics. |
| Test/prod target | Resolve and compile without Ops esbuild/Tailwind Mix dependencies; retain supported operator routes and core telemetry. |
| Asset builder | Resolve dev tools separately, compile current Ops and storefront source, emit static output. |
| Test/prod output | Copy only required generated static files, digest under the target environment if needed, then compile/start/serve independently. |

### Package consumer compatibility

[VERIFIED: test/release/consumer_smoke_test.exs:1-30; official Req docs https://req.hexdocs.pm/0.6.3/Req.Test.html and https://req.hexdocs.pm/0.7.5/Req.Test.html] The existing consumer test already creates a package artifact, isolated HEX_HOME and MIX_HOME, and a consumer workspace. Extend this harness, not a parallel framework: build and unpack one artifact; create two isolated consumer roots with distinct lock/build paths; supply non-overriding direct Req witness dependencies ~> 0.6.1 and ~> 0.7.0; assert installed Req versions; then invoke the same public Scrypath operation and assert HTTP result plus Telemetry event. Use Req.Test with Plug fixtures already explicit as test-only dependencies. Avoid testing only Scrypath.Meilisearch.Client, which is internal; the public Scrypath search/request flow owns the consumer contract.

A shipped ~> 0.7 range admits stable versions below 1.0, not just 0.7.x. The concrete 0.7.0 witness is intentionally a test constraint that selects a 0.7.x candidate; it must not become the shipped metadata range. Keep prereleases out of default lock selection. [CITED: https://hexdocs.pm/elixir/Version.html; https://req.hexdocs.pm/0.7.5/Req.Test.html]

### Diagnostics require compile-time and runtime guards

[VERIFIED: scrypath_ops/mix.exs:53-61; scrypath_ops/lib/scrypath_ops/application.ex:21-43; scrypath_ops/lib/scrypath_ops_web/endpoint.ex:41-58; scrypath_ops/lib/scrypath_ops_web/dev_router.ex:47-56; https://phoenix-live-dashboard.hexdocs.pm/metrics.html] Current Ops starts ScrypathOpsWeb.Telemetry in its base children even in mounted mode, imports Telemetry.Metrics in that module, and unconditionally compiles the LiveDashboard.RequestLogger plug. DevRouter imports LiveDashboard.Router and includes Dashboard and Swoosh mailbox macros behind a compile-time config check. A runtime flag or compile_env false alone cannot safely guard references to removed dependency modules. Plan coordinated source compilation boundaries for diagnostic modules, imports, macros/routes, Endpoint plug and application child; keep operator routes, Scrypath telemetry producers, RecoveryObservation, PubSub and TaskSupervisor available.

[VERIFIED: scrypath_ops/lib/scrypath_ops/security.ex:4-34; scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:19-45,86-103] Security allows auth-mode values “basic”, “proxy_headers” and “sigra”; Sigra validation currently only requires a sudo confirmation path. In the present dependency branch, missing operator_context calls the sensitive action; in the absent dependency branch the callback is called unconditionally. Change only the explicitly requested Sigra path to fail on unavailable integration or missing/invalid context. Preserve the non-Sigra paths and keep host route/LiveView authentication a host responsibility. Existing tests at security_validation_test.exs and gating_test.exs provide focused seams; add dependency-absent execution proof without treating source inspection as a demonstrated remote bypass.

### Static assets and separate output ownership

[VERIFIED: examples/scrypath_ecommerce/Dockerfile:2-38; examples/scrypath_ecommerce/docker-e2e-entrypoint.sh:15-37; examples/scrypath_ecommerce/mix.exs:34-58; scrypath_ops/mix.exs:53-61] The ecommerce container currently uses MIX_ENV=test, resolves three graphs, copies source, and its entrypoint installs/builds both ecommerce and Ops assets at test runtime. That current flow conflicts with dev-only wrapper dependencies. The Docker plan must introduce a real asset-builder stage sourced from current checkout files and its dev dependencies, emit both apps' static bundles, and copy only owned static outputs into a clean test/prod target. Remove runtime install/build calls from docker-e2e-entrypoint.sh. Keep asset versions/config/tool authority in existing project files. Ensure target dependency resolution/build is independent; copying _build/dev, dev deps or dev config into the final stage would invalidate the proof. Build and digest decisions must be verified in the actual target environment. [CITED: https://phoenix.hexdocs.pm/1.8.14/asset_management.html; https://phoenix.hexdocs.pm/deployment.html; https://esbuild.hexdocs.pm/Mix.Tasks.Esbuild.html; https://tailwind.hexdocs.pm/Mix.Tasks.Tailwind.html]

### Four graph update and audit pattern

[VERIFIED: scripts/ci/dependency_audit.ex:14-53; .planning/RECOMMENDATIONS.md] The repository audit inventory is root, examples/phoenix_meilisearch, examples/scrypath_ecommerce and scrypath_ops. Treat each manifest/lock as an independent resolution. Use targeted updates and unused pruning, then inspect each lock and run the exact graph audit. Retain raw outputs, nonzero exits, source SHA, before/after lock identity, package manager version and ignored advisory/retirement metadata. Current deep-quality sequencing can short-circuit Dialyzer after audit failure; preserve the audit exit and collect the analysis result independently if needed. Do not convert unresolved Cloak/Cloak Ecto findings into a clean audit through suppression, package removal based solely on names, or inferred runtime exposure.

## Dependabot Proposal Disposition Inputs

The read-only GitHub API snapshot on 2026-10-29 showed all ten referenced PRs open and unmerged. This is a dated observation only; recheck before execution. Record one explicit disposition per PR in the phase evidence, and do not merge or close PRs as part of the phase. [VERIFIED: GitHub API snapshot 2026-10-29; linked PR pages]

| PR | Proposal observed | Research-time target/current fact | Planning disposition |
|---|---|---|---|
| [#65](https://github.com/szTheory/scrypath/pull/65) | actions/cache 5.1.0 → 6.1.0 | Official cache docs report v6.1.0, Node 24 and runner >=2.327.1. | Reconcile with Phase 182 split restore/save topology and cache identities; verify runner and current workflow action SHAs/comments. [CITED: https://github.com/marketplace/actions/cache] |
| [#68](https://github.com/szTheory/scrypath/pull/68) | dependency-review-action 4.9.0 → 5.0.0 | Official action docs report v5 uses Node 24 and runner >=2.327.1. | Check existing permissions and advisory failure behavior; do not weaken failure semantics. [CITED: https://github.com/actions/dependency-review-action] |
| [#69](https://github.com/szTheory/scrypath/pull/69) | StreamData 1.3 → 1.4.0 | 1.4.0 was the current stable release observed. | Include in compatible root test-tooling batch; run property tests and review changed shrinking behavior. [VERIFIED: Hex API, https://hex.pm/api/packages/stream_data/releases/1.4.0] |
| [#70](https://github.com/szTheory/scrypath/pull/70) | setup-node 6.5.0 → 7.0.0 | Official releases show v7.1.0 released 2026-10-08, so the proposal target is superseded. | Prefer current v7 target only after checking runner/runtime, ESM and NODE_AUTH_TOKEN behavior, and update immutable SHA/comment coherently. [CITED: https://github.com/actions/setup-node/releases] |
| [#71](https://github.com/szTheory/scrypath/pull/71) | checkout 6.1.0 → 7.0.1 | v7.0.1 is the proposal target observed; v7 has changed fork behavior for pull_request_target/workflow_run. | Inspect all affected workflow uses, credential persistence and whether jobs fetch history; adopt or record concrete deferral reason. [CITED: https://github.com/marketplace/actions/checkout] |
| [#72](https://github.com/szTheory/scrypath/pull/72) | deploy-pages 5.0.0 → 5.0.1 | 5.0.1 was the current target observed. | Check workflow syntax and permissions; do not infer authorization to publish as part of this phase. [CITED: https://github.com/actions/deploy-pages/releases] |
| [#73](https://github.com/szTheory/scrypath/pull/73) | Req 0.6.3 → 0.7.4, root only | Stable 0.7.5 supersedes 0.7.4; approved direct ranges cover root, Ops and ecommerce. | Supersede the root-only proposal with coordinated approved unions and current compatible 0.7.x locks; keep the independent 0.6.x package witness. [VERIFIED: Hex API, https://hex.pm/api/packages/req] |
| [#74](https://github.com/szTheory/scrypath/pull/74) | ExDoc 0.40.3 → 0.40.4 | 0.40.4 was the current stable release observed; root's existing ~> 0.37 excludes it. | Include only in approved root docs tooling batch with an explicit compatible bound and warnings-as-errors docs proof. [VERIFIED: Hex API, https://hex.pm/api/packages/ex_doc/releases/0.40.4; mix.exs:129] |
| [#75](https://github.com/szTheory/scrypath/pull/75) | Dialyxir 1.4.7 → 1.4.8 | 1.4.8 was the current stable release observed. | Include in the tooling batch after supported-tuple analysis; make analysis result visible even when audits fail. [VERIFIED: Hex API, https://hex.pm/api/packages/dialyxir/releases/1.4.8] |
| [#76](https://github.com/szTheory/scrypath/pull/76) | Oban 2.23.0 → 2.24.1, root only | Stable 2.24.2 supersedes 2.24.1; consumers need coordinated graph choices. | Supersede with current compatible stable across affected graphs; preserve optional/no-Oban and job behavior. [VERIFIED: Hex API, https://hex.pm/api/packages/oban/releases/2.24.2] |

For every row, execution evidence should say incorporated, superseded/equivalent, or blocked/deferred; include the selected target, primary source, check result and revisit trigger. Keep Actions pinned by immutable commit SHA and align the human-readable version comment. Preserve the five required jobs and existing advisory/path-scoped topology. [VERIFIED: D-16; .github/workflows/ci.yml:33-48; .planning/REQUIREMENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| HTTP requests and transport test fixtures | Custom HTTP stack or local mock protocol | Req and Req.Test | Existing maintained request API; fixtures prove the same transport path under both installed consumer lines. |
| Metrics and periodic sampling | Local replacement module or copied library code | Existing Telemetry, telemetry_metrics, telemetry_poller in their scoped environments | Keep mature instrumentation implementations and only change their graph ownership. |
| JS/CSS build wrappers | A second npm/esbuild/Tailwind framework and lock authority | Existing Mix wrappers in dev, isolated build stage for output | D-08 fixes environment ownership without replacing tools. |
| Authentication, audit logging and crypto | A homegrown Sigra/Cloak substitute | Existing optional Sigra integration; report residual advisory debt | Security protocol implementations remain maintained dependencies; fail closed at integration edges. |
| Dependency auditing | Grep-based advisory detector or ignored nonzero status | Existing four-graph audit command and raw results | The audit records exact graph, lock and source identity and detects incomplete runs. |
| Package consumer harness | New verifier architecture | Existing archive/consumer smoke test | Phase 183 established a package/tooling boundary and harness. |

## Common Pitfalls

1. **Letting transitive dependencies mask public metadata.** Ecto already depends on Telemetry, so a root-only compile can pass even if Scrypath omits the direct Telemetry declaration. Assert the built archive's direct dependency metadata and run installed consumers.
2. **Confusing Mix flags.** runtime: false does not make an application disappear from resolution or compilation; optional: true only prevents downstream imposition; only: :dev must be paired with source and route guards.
3. **Guarding only a runtime child.** Endpoint plugs, imports, route macros, compile-time environment checks and module references may fail before application startup if dependencies are absent.
4. **Building assets in the test runtime.** Once wrappers are dev-only, the current ecommerce entrypoint cannot install/build them. Asset generation belongs in a builder stage; only the generated static output crosses stages.
5. **Copying too much between Docker stages.** Dev dependencies, _build/dev, compiled BEAMs or dev config could hide missing target dependencies. Re-resolve and compile target env independently.
6. **Treating locks as range proofs.** Each root/example/Ops graph resolves separately, and one package archive consumer lock does not prove every admitted Req version. Keep independent locks and actual version assertions.
7. **Selecting retired/latest metadata blindly.** Sigra 1.20.0 is reported by package metadata as latest stable but is marked retired; current usable compatible stable observed was 1.7.1. Keep the approved ~> 1.5 range, verify the resolver result at execution, and do not “fix” this by changing the locked range or adding an OTP floor. [VERIFIED: https://hex.pm/api/packages/sigra/releases/1.7.1; https://hex.pm/api/packages/sigra/releases/1.20.0]
8. **Overstating Sigra's OTP floor.** Its declared Elixir floor is ~> 1.18; .tool-versions is not a consumer support matrix. Do not infer OTP 27 from it. Test a suitable supported pair and retain the repository's support policy. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]
9. **Misrepresenting security status.** Bandit remediation does not clear Cloak/Cloak Ecto findings; AES-GCM usage or lack of inspected PBKDF2 call sites does not produce a package-level clean result or imply risk acceptance. OTP support and Hex advisory audits answer different questions.
10. **Using stale bot PR targets.** Several proposal versions were surpassed by current stable releases. Record each disposition and evidence, update current compatible versions coherently, and do not cherry-pick a historical bot branch.
11. **Breaking Phase 182 cache proof.** Keep action updates compatible with current restore/save split, cache keys, namespaces and trusted writer behavior. Preserve five required job topology and existing action permissions/checkout semantics.
12. **Using a dirty local cache as proof.** Establish clean build paths and inspect generated .app requirements, code path, loaded/started applications and served route behavior independently.
13. **Treating UI capture as dependency proof.** Preserve Ops/storefront UI and follow conditional preview rules, but use disposable integration containers for asset verification; do not start or mutate the retained preview.
14. **Letting audits hide analysis.** If deep-quality audit fails first, ensure the analysis result is still captured separately while keeping audit nonzero and visible.

## Code Examples

Recommended implementation/verification patterns, expressed as planning instructions:

| Need | Pattern |
|---|---|
| Explicit package dependency | Declare Telemetry as a direct mandatory root dependency using exactly the approved range; verify the built archive metadata. |
| Dual Req proof | Build/unpack once; resolve separate consumer workspaces with non-overriding 0.6.1 and 0.7.0 witness constraints; assert resolved versions and the same public HTTP/telemetry behavior. |
| Dev-only compile boundary | Put optional diagnostic modules and all compile-time imports/macros behind an environment-appropriate compilation path; guard the endpoint plug and application child using that same compiled capability. |
| Asset production | Resolve dev asset tooling in the builder; build both bundles from current sources; transfer only static outputs; digest/compile/start the clean target environment. |
| Dependency audit | Capture each graph's status and raw output at the same source revision, including nonzero results, lock identities and audit tool version. |
| Sigra absence | With Sigra not compiled/loaded, requesting Sigra auth returns a clear validation/startup error; a protected action callback does not run without a valid operator context. |

## State of the Art

| Earlier assumption or approach | Revalidated guidance | Impact |
|---|---|---|
| Sigra 1.20.0 is the latest suitable current stable release. | Hex metadata marks 1.20.0 retired; 1.7.1 was the observed current valid compatible stable release. | Retain D-10's exact ~> 1.5 range; choose and test resolver output at execution. Do not treat discussion research's old latest-version wording as a locked version. |
| An upstream Sigra .tool-versions entry establishes consumer OTP minimum. | A tool-version file does not declare consumer OTP support; Sigra metadata declares Elixir ~> 1.18. | Keep core floor and OTP policy; test an appropriate tuple. |
| runtime: false makes a Mix dependency unavailable outside runtime startup. | Mix keeps it in the graph/compile boundary; only: and optional: express different axes. | Dependency metadata, compiler inclusion, application startup and runtime behavior need separate checks. |
| Asset wrappers can stay present if they are not started in prod. | D-08 requires wrappers absent from test/prod graphs; current test entrypoint invokes their Mix tasks. | Move generation into an isolated builder and rework the E2E entrypoint. |
| A root lock proves all consumers and versions. | Each Mix project resolves its own graph, and the packaged consumer has a new independent lock. | Four project locks plus two consumer witnesses need explicit evidence. |

[VERIFIED: official Mix docs; current Hex Sigra release metadata; repository code paths cited above]

## Assumptions Log

No implementation design assumptions are needed beyond the locked context. The asset stage layout, helper names, and selected stable versions remain delegated engineering decisions; validate exact Docker output paths and installed graph results during planning/execution. Sigra 1.7.1 is a research-time release observation, not a permanent selection. The recommendation's Sigra/OTP correction is supported by upstream declared Elixir metadata and the official compatibility table; the requested execution tuple remains to be verified.

## Open Questions

1. **What exact Sigra lock result is compatible with the chosen tested Elixir/OTP tuple?**
   - What we know: D-10 locks the range at ~> 1.5 and preserves the core floor; current Hex metadata marks 1.20.0 retired and 1.7.1 as valid, with an Elixir ~> 1.18 floor and Cloak Ecto ~> 1.3.
   - What's unclear: exact current resolver selection and successful compilation/behavior across the selected supported tuple(s).
   - Recommendation: revalidate package retirement/dependency metadata and run the with-Sigra and no-Sigra executable proofs without changing locked support policy.

2. **Which Actions upgrades satisfy current runner and cache behavior?**
   - What we know: the ten PRs were observed open/unmerged on 2026-10-29; current action release tags may be newer than the PR's proposed target. CI pins actions by immutable SHA.
   - What's unclear: exact current SHAs, runner minimums, Node runtime, checkout credential behavior, dependency-review behavior and action/cache v6 compatibility with Phase 182. The five job identities must remain unchanged.
   - Recommendation: inspect current official action release/docs and refresh SHA/version comments together with repository-contract proof. Record incorporated/superseded/blocked disposition for each referenced PR; do no remote PR mutation.

3. **Can clean test and production targets compile, start and serve both assets with only generated output?**
   - What we know: current E2E entrypoint performs runtime install/build in test; D-08/D-09 require a separate builder and output-only transfer.
   - What's unclear: actual bundle directories, any Phoenix digest/manifest path dependency and which aliases are safe in the target stage.
   - Recommendation: trace current esbuild/Tailwind output configuration before changing Docker; prove clean graph resolution, build/start, app loading and mounted route serving with disposable image targets.

4. **How should audit and Dialyzer evidence coexist when audit fails?**
   - What we know: current deep-quality chain can stop after nonzero Hex audit; all four graph outcomes and raw failures must remain visible.
   - What's unclear: whether existing verifier already captures analysis in a later shell/workflow step or needs an independent collection boundary.
   - Recommendation: inspect existing task orchestration and add no suppression; preserve nonzero audit status while ensuring analysis execution/result is independently recorded.

5. **Do new upstream advisories or stable releases change the researched snapshot?**
   - What we know: Req 0.7.5, Bandit 1.14.1, Oban 2.24.2, StreamData 1.4.0, ExDoc 0.40.4, Dialyxir 1.4.8 and Sigra 1.7.1 were observed as stable candidates on 2026-10-29; Cloak/Cloak Ecto findings were reported in the prior dated audit.
   - What's unclear: package/advisory status at the actual lock/update date and compatibility of newest candidates across the project's full matrix.
   - Recommendation: re-query authoritative Hex/advisory sources and record raw final per-graph audits, not only these research-time versions.

## Environment Availability

| Dependency/tool | Required by | Available | Observed version/state | Fallback |
|---|---|---:|---|---|
| Elixir/Mix | Mix updates, compile, tests, docs, audits | Installed tool manager reports candidate versions; current command shim has no selected version | Output lists Elixir 1.20.4-OTP29, 1.20.2-OTP29, 1.19.5-OTP28/27, 1.19.0-OTP28, 1.18.4-OTP27 and 1.17.3-OTP27, then says no version is set for elixir and mix. | Select an explicitly installed compatible tuple through project toolchain configuration or run in CI matrix; don't infer unsupported tuples. [VERIFIED: command output, 2026-10-29] |
| Docker CLI | Disposable ecommerce mounted/asset stage checks | ✓ | 29.5.2 | Docker daemon/service was not probed; use hosted/disposable environment if unavailable. |
| Node / npm | Existing asset wrappers and Actions workflow probes | ✓ | Node 26.10.0; npm 11.19.1 | — |
| Git / GitHub CLI | Lock/source identity and read-only PR status review | ✓ | Git 2.41.0; gh 2.101.0 | API/source links for read-only current status. |
| PostgreSQL / Meilisearch | Existing live backend/hosted proof where applicable | Not checked | No service state probed. | Use existing service-enabled verification lane; keep core fast checks service-free. |

[VERIFIED: local command output, 2026-10-29; CONTRIBUTING.md]

## Validation Architecture

Nyquist validation is enabled in .planning/config.json. The plan should map requirements to existing gates and focused extension tests; do not add a new required CI job. The required job set remains core, package, repository-contracts, backend, ecommerce-mounted. Tests were not run during research.

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Mix; Docker Compose for mounted asset image proof |
| Config | Existing root and Ops Mix test configuration; existing release consumer tests |
| Quick run command | mix test --exclude integration --exclude docs_contract |
| Full relevant commands | mix verify.core --exclude integration --exclude docs_contract; mix verify.package; mix verify.repository_contracts; mix verify.backend; mix verify.ecommerce_mounted; mix verify.ops_ui; mix verify.deep_quality; mix verify.compatibility |
| Required CI jobs | core, package, repository-contracts, backend, ecommerce-mounted |

[VERIFIED: CONTRIBUTING.md canonical verification and CI tables; .planning/REQUIREMENTS.md verification constraints]

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command / proof | Existing seam |
|---|---|---|---|---|
| DEP-01 | Archive declares mandatory direct Telemetry and public instrumentation still fires in consumer. | Package integration | mix verify.package | Extend test/release/consumer_smoke_test.exs and package metadata contract. |
| DEP-02 | Two independent package consumers resolve intended Req branches and same request/response behavior. | Package integration | mix verify.package | Extend existing consumer smoke harness; isolate build/lock identities and assert Mix.lock selected versions. |
| DEP-03 | Ops and ecommerce run without unused mail integration/config/references. | Static contract + Ops integration | mix verify.ops_ui; mix verify.repository_contracts | Existing Ops tests, manifest and lock contract; search references and compile/start after pruning. |
| DEP-04 | Mounted Ops excludes diagnostic dependency slice; direct dev/standalone diagnostics and core telemetry work. | Compile/start integration | mix verify.ops_ui; mix verify.ecommerce_mounted | Extend Ops application/endpoint/router and mounted-host tests; clean env/code-path/app-start checks. |
| DEP-05 | Dev assets build; clean test/prod images resolve/compile/start/serve without Mix wrapper dependencies. | Docker integration / smoke | mix verify.ecommerce_mounted; disposable target build/serve proof | examples/scrypath_ecommerce Dockerfile and docker-e2e-entrypoint.sh. Validate both Ops and storefront outputs. |
| DEP-06 | Optional Sigra range resolves; absent explicit mode errors; protected actions fail closed; present path retains expected behavior. | Unit + integration | mix verify.ops_ui; mix verify.compatibility | Existing security_validation_test, gating_test and on_mount_test; add dependency-excluded negative path. |
| DEP-07 | Four locks reflect coordinated compatible graph; all ten PRs have evidence-backed dispositions; advisories remain explicit. | Repository contract + audit + matrix | mix verify.repository_contracts; mix verify.deep_quality; mix verify.compatibility; captured audit result per graph | scripts/ci/dependency_audit.exs inventories all four graphs; retain raw outputs and exact source/lock identity. |

### Sampling Rate

- Per implementation task: run the narrow test/compiler proof named in the plan.
- Per wave: rerun the relevant canonical command above and check the changed lockfiles/graph manifests.
- Phase gate: full changed-scope executable proof on supported tuples, all four audit results with raw evidence, exact-source CONTRIBUTING closeout at execution. Passing one root audit does not satisfy four-graph coverage.

### Wave 0 Gaps

- [ ] Extend existing consumer proof for two isolated Req witness consumers and mandatory direct Telemetry metadata.
- [ ] Add testable compile/start boundaries for optional diagnostics and positive/negative Sigra dependency cases if existing test harness does not cover these states.
- [ ] Add clean target asset graph and serve proof for both bundles; exact output paths need inspection before planning concrete Docker copy instructions.
- [ ] Decide where four raw per-graph audit outputs and the ten-entry PR disposition ledger are retained as phase evidence; do not invent a new CI job.

## Security Domain

Security enforcement is enabled (the setting is absent/true by default). Phase work affects operator authentication gates, dependency advisories and CI permissions; security behavior must have executable tests and no risk acceptance.

### Applicable ASVS Categories

| ASVS category | Applies | Standard control for this phase |
|---|---:|---|
| V2 Authentication | Yes | Requested Sigra mode requires available integration; host is still responsible for route/LiveView authentication. |
| V3 Session Management | Yes | Verify sudo freshness/session context remains checked in the present Sigra path. |
| V4 Access Control | Yes | Missing/invalid operator context cannot run sensitive callback; preserve impersonation denial and audit identity. |
| V5 Input Validation | Yes | Validate allowed auth mode and required configuration before startup. |
| V6 Cryptography | Yes | Retain maintained crypto dependencies; preserve Cloak/Cloak Ecto audit findings without suppressing or overstating reachable usage. |

[VERIFIED: scrypath_ops/lib/scrypath_ops/security.ex:4-34; scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:19-45,86-103; D-11/D-12/D-17]

### Known threat patterns

| Pattern | STRIDE | Mitigation / proof |
|---|---|---|
| Explicit Sigra selected but dependency absent | Spoofing / elevation | Fail validation or startup with clear error; assert absent dependency negative path. |
| Sensitive callback invoked without operator context | Elevation / repudiation | Fail closed; assert callback was not invoked and verify valid action audit identity. |
| Compile-time route/plug references to removed dependency | Denial of service / availability | Compile modules/imports/macros only when dependency environment includes required modules; clean compile/start proof. |
| Stale dependency advisories hidden by version/range or audit handling | Tampering / repudiation | Keep unfiltered audit exit and full per-graph raw results bound to lock/source identity. |
| Workflow update changes credentials/permissions/cache behavior | Elevation / information disclosure | Review least-privilege permissions, checkout credential persistence and Phase 182 trusted cache writer boundaries; preserve required-job topology. |

## Sources

### Primary / authoritative sources

- Project phase context, requirements, current manifests, verifier/source seams, CONTRIBUTING.md and AGENTS.md — repository citations throughout.
- [Official Mix dependency task documentation](https://hexdocs.pm/mix/Mix.Tasks.Deps.html) and [Mix.Project documentation](https://hexdocs.pm/mix/Mix.Project.html) — environment, optional and runtime dependency semantics.
- [Req 0.6.3 Req.Test](https://req.hexdocs.pm/0.6.3/Req.Test.html), [Req 0.7.5 Req.Test](https://req.hexdocs.pm/0.7.5/Req.Test.html), and [Req versions](https://hex.pm/packages/req/versions) — consumer test patterns and stable/prerelease distinction.
- [Phoenix LiveDashboard metrics guide](https://phoenix-live-dashboard.hexdocs.pm/metrics.html), [Phoenix asset management](https://phoenix.hexdocs.pm/1.8.14/asset_management.html), [Phoenix deployment](https://phoenix.hexdocs.pm/deployment.html), [esbuild Mix task](https://esbuild.hexdocs.pm/Mix.Tasks.Esbuild.html), [Tailwind Mix task](https://tailwind.hexdocs.pm/Mix.Tasks.Tailwind.html) — source/build/runtime boundaries.
- [Sigra 1.7.1 Hex release metadata](https://hex.pm/api/packages/sigra/releases/1.7.1) and [retired 1.20.0 metadata](https://hex.pm/api/packages/sigra/releases/1.20.0) — current usable version correction; [Elixir 1.18 compatibility](https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html) for runtime pair selection.
- [Bandit 1.14.1 metadata](https://hex.pm/api/packages/bandit/releases/1.14.1), [Cloak advisory](https://osv.dev/vulnerability/EEF-CVE-2026-95105), [Cloak Ecto advisory](https://osv.dev/vulnerability/EEF-CVE-2026-94206), and [Erlang OTP 26 status](https://www.erlang.org/versions?v=26.2.5.3) — dated security/support claims to revalidate.
- [actions/cache](https://github.com/marketplace/actions/cache), [actions/checkout](https://github.com/marketplace/actions/checkout), [dependency-review-action](https://github.com/actions/dependency-review-action), [setup-node releases](https://github.com/actions/setup-node/releases), [deploy-pages releases](https://github.com/actions/deploy-pages/releases) — workflow upgrade facts; refresh exact release SHA and runtime on execution.
- Dependabot proposals: [#65](https://github.com/szTheory/scrypath/pull/65), [#68](https://github.com/szTheory/scrypath/pull/68), [#69](https://github.com/szTheory/scrypath/pull/69), [#70](https://github.com/szTheory/scrypath/pull/70), [#71](https://github.com/szTheory/scrypath/pull/71), [#72](https://github.com/szTheory/scrypath/pull/72), [#73](https://github.com/szTheory/scrypath/pull/73), [#74](https://github.com/szTheory/scrypath/pull/74), [#75](https://github.com/szTheory/scrypath/pull/75), [#76](https://github.com/szTheory/scrypath/pull/76) — observed open/unmerged in read-only API snapshot at research time; recheck at execution.

### Research source limits

The cache seam classifies websearch as LOW confidence; official documentation and Hex metadata were read directly and are cited, but release/advisory/PR facts are temporal observations, not permanent support guarantees. Revalidate current versions, advisories, action SHAs and PR states when execution begins. Package legitimacy check does not support Hex, and no new package is proposed.

## Metadata

**Confidence breakdown:**
- Repository architecture and seams: HIGH — source files and requirement/context documents were read directly.
- Mix, Req, Phoenix and asset patterns: HIGH/MEDIUM — official documentation checked; some behaviors should be proven in clean target builds.
- Current versions and upstream status: MEDIUM — official registry/advisory/action sources checked on 2026-10-29; time-sensitive and must be refreshed.
- Security findings: MEDIUM — advisory evidence is authoritative, but final lock graph and reachability/audit outputs must be captured on the execution source.
- Validation design: HIGH — maps locked requirements to existing project commands and source seams.

**Research date:** 2026-10-29
**Valid until:** Revalidate fast-moving versions, advisories, PR state, action SHAs and OTP status at execution; code seams and locked acceptance remain valid until changed by the maintainer.

