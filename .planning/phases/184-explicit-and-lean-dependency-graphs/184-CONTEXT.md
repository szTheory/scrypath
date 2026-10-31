# Phase 184: Explicit and lean dependency graphs - Context

**Gathered:** 2026-10-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver DEP-01–DEP-07: explicit core Telemetry/Req dependencies, a lean mounted Ops dependency/runtime boundary, usable development assets with tool-free test/production graphs, compatible optional Sigra authentication, and coordinated dependency/lockfile updates with truthful security and Dependabot dispositions.

The maintainer requested research of all relevant decision areas using specialist subagents, primary sources, ecosystem precedent, tradeoffs and an adversarial pass, and explicitly delegated selection and automatic adoption of a coherent recommendation set. The decisions below are that delegated synthesis; they are not individual questionnaire answers or blanket risk approval. Discussion is complete; planning and execution have not run.

Keep existing product/API/UI behavior and support boundaries. Phase 185's quality foundation, later UI-engine/polish work and adopter features remain separate. No publication, merge, PR closure, retained-preview mutation, or security-risk acceptance is authorized by this context.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the scope, recommendations and affected seam references before planning or implementing. Paths below are repository-relative.**

### Scope, evidence and working rules

- `.planning/ROADMAP.md` — Phase 184 goal, DEP-01–DEP-07 success criteria and verification/delivery boundaries.
- `.planning/REQUIREMENTS.md` — the seven locked dependency requirements and milestone constraints.
- `.planning/PROJECT.md` — core value, approved v1.45 scope and verification policy; older dated next-step paragraphs do not override current STATE.
- `.planning/STATE.md` — active position, worktree and inherited debt.
- `.planning/reference/ROLLING-ROADMAP.md` §3 — source dependency work and referenced Dependabot proposals; its old Cloak/Sigra wording is superseded by the dated research here.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-RECOMMENDATIONS.md` — comparative recommendations, primary-source links, current advisory/PR snapshot, adversarial corrections and evidence limits. It is not the later `184-RESEARCH.md` implementation artifact.
- `.planning/phases/183-maintainer-tooling-outside-the-hex-package/183-CONTEXT.md` — package/tooling ownership decisions; referenced pre-move code locations there are historical.
- `.planning/phases/183-maintainer-tooling-outside-the-hex-package/183-VERIFICATION.md` — dependency-phase baseline and existing package proof.
- `.planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-CONTEXT.md` — source/build/download cache boundaries and browser lifecycle ownership.
- `AGENTS.md`, `CONTRIBUTING.md` — repository rules, changed-scope gates, exact-source closeout and delivery authority.

### Existing code and documentation seams

- `mix.exs`, `mix.lock`, `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock` — root/Ops direct ranges and independent locks.
- `examples/phoenix_meilisearch/mix.exs`, `examples/phoenix_meilisearch/mix.lock`, `examples/scrypath_ecommerce/mix.exs`, `examples/scrypath_ecommerce/mix.lock` — consumer constraints and independent locks.
- `test/release/consumer_smoke_test.exs`, `test/release/package_metadata_test.exs`, `test/support/release/package_contract.ex` — extend actual package/consumer proof.
- `dev/mix/tasks/verify.no_optional_deps.ex`, `dev/mix/tasks/verify/capability.ex`, `scripts/ci/dependency_audit.exs` — existing optional-dependency and per-graph quality seams.
- `scrypath_ops/lib/scrypath_ops/application.ex`, `scrypath_ops/lib/scrypath_ops_web/telemetry.ex`, `scrypath_ops/lib/scrypath_ops_web/endpoint.ex`, `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, `scrypath_ops/lib/scrypath_ops_web/router.ex` — diagnostics compilation/startup and mounted routing.
- `scrypath_ops/lib/scrypath_ops/security.ex`, `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex`, `scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex` — optional auth boundaries.
- `scrypath_ops/test/scrypath_ops/security_validation_test.exs`, `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs`, `scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs` — existing auth coverage.
- `examples/scrypath_ecommerce/Dockerfile`, `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh`, `examples/scrypath_ecommerce/compose.phase173.yaml` — current build/standalone E2E ownership; reconcile the asset boundary here.
- `.github/workflows/ci.yml`, `scripts/ci/beam_cache.cjs`, `scripts/ci/beam_cache.test.cjs` — keep required jobs/cache graph inputs coherent; inspect other workflows affected by the live PR inventory.
- `guides/support-and-compatibility.md`, `scrypath_ops/README.md`, `examples/scrypath_ecommerce/README.md` — canonical support and affected integration/build guidance. The currently missing `guides/integrations/sigra.md` reference is an issue to correct, not an existing canonical file.

### Practices and conditional UI preservation

- `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/elixir-best-practices-deep-research.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/phoenix-best-practices-deep-research.md`, `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — relevant ecosystem/DX/operational practices, subject to current code and primary-source validation.
- `.planning/UI-PREVIEW.json`, `.planning/reference/UI-WORKTREE-LEARNINGS.md`, `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` — mandatory named-checkout/preflight/data/review rules when implementation touches Ops/storefront; no preview work occurred here.
- `PRODUCT.md`, `DESIGN.md`, `brandbook/README.md`, `brandbook/tokens/tokens.json` — current product/design preservation authorities where relevant; do not revive stale prompt-brand choices or implement Phase 185 here.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The package suite already builds an archive and compiles an unpacked consumer; extend it with independent Req witnesses rather than introduce a new harness dependency.
- The existing optional-dependency verifier and capability commands already separate base library, package, repository, backend and mounted proof.
- `scripts/ci/dependency_audit.exs` inventories all four graphs. Keep its raw/nonzero outcomes and collect analysis separately if audit short-circuiting would hide whether analysis ran.
- Existing Sigra validation/gating/OnMount tests and application/router tests provide the auth and mode seams to extend.

### Established Patterns

- A dependency normally compiles under `:prod`; Phase 183 already uses environment-specific compilation to exclude repository tooling.
- Compile-time module imports and route macros need compile-safe exclusions; runtime supervisor ownership is a separate concern.
- `runtime: false` controls application startup, not presence in the graph. Optional deps are included by the direct declaring project but not imposed downstream.
- A root lock cannot certify an example or the installed artifact; cache identity must follow the actual graph/manifest/lock/toolchain/environment.

### Integration Points

- The current ecommerce Docker/E2E path builds assets at test runtime and must be reconciled before dev-only wrappers can work.
- Ops and ecommerce currently duplicate dependencies; changing only Ops leaves parts of the host graph intact.
- Mounted Ops uses the host Endpoint/Repo while standalone controls its own children; keep these jobs distinct without adding an API layer.

</code_context>

<specifics>
## Specific Ideas

The maintainer's preference is “another copy and paste is better than another dep” for genuinely small helpers, with small flat graphs, low setup friction and least surprise. The recommendation uses that preference without copying security/protocol implementations. Primary-source Mix/Phoenix/Req/Telemetry/Sigra/advisory references and the ten live PR links are in the discussion research companion. Successful ecosystem examples are used narrowly for explicit dependency ownership and dev build boundaries, not as a reason to add abstractions.

### Requirement-to-decision handoff

| Requirement | Decisions | Future executable proof |
| --- | --- | --- |
| DEP-01 | D-01–D-03 | Built metadata declares mandatory Telemetry; consumer receives request events. |
| DEP-02 | D-02–D-04, D-14 | Independent 0.6.x/0.7.x package consumers assert actual versions and behavior. |
| DEP-03 | D-05 | Clean Ops/host startup and complete unused-mail removal with reconciled locks. |
| DEP-04 | D-06/D-07, D-09 | Mounted dependency exclusion, standalone dev diagnostics and unchanged core telemetry/routes. |
| DEP-05 | D-08/D-09 | Dev assets generate; clean test/prod compile/start/serve with wrappers absent. |
| DEP-06 | D-10–D-12, D-17/D-18 | Compatible Sigra/no-Sigra auth cases fail closed as specified; audit failures remain explicit. |
| DEP-07 | D-13–D-19, D-21 | Four graph locks, all ten PR dispositions, supported-stack checks and source-bound audit/CI records. |

</specifics>

<deferred>
## Deferred Ideas

Phase 185's token/contrast/quality work, v1.46–v1.48 UI/adopter capabilities, public backend abstraction, auth replacement, crypto vendoring, runtime support-floor changes, public security-risk acceptance, publication and remote PR cleanup remain outside this phase discussion. No pending todos matched this phase. Cloak/Cloak Ecto upstream remediation remains explicit unresolved dependency debt with revisit triggers; it is not marked accepted or fixed.

</deferred>

---

*Phase: 184-explicit-and-lean-dependency-graphs*
*Context gathered: 2026-10-29*
