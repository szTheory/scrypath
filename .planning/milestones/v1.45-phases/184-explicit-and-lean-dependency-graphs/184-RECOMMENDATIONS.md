# Phase 184 discussion research and recommendations

Date: 2026-10-29. Source inspected: `aab0e0d349a867b92f96b20c38ae25eea34a2075` on `planning/v1.45-foundation-ci`.

This is decision-support research for discuss-phase, not the implementation research artifact `184-RESEARCH.md`, an implementation plan, or acceptance evidence for changed source. Three specialist subagents covered core consumers, Ops lifecycle/assets, and security/upgrades. A subsequent cross-area adversarial pass checked the recommendations against repository wiring. The maintainer explicitly delegated discussion of all areas and selection of coherent recommendations. No implementation, remote PR mutation, publication, independent visual review, or security-risk acceptance occurred.

## Recommendation

Keep the existing Elixir/Phoenix architecture and make its dependency boundaries real: mandatory direct core dependencies, development-only diagnostic and asset tools, independently built static assets, compatible optional authentication, and four reconciled dependency graphs. Reuse the existing verifiers. Prefer a small local helper over another dependency; retain maintained HTTP, cryptography, authentication and build tools rather than copying their implementations.

## Alternatives and tradeoffs

| Decision | Alternatives considered | Selected approach and cost |
| --- | --- | --- |
| Core declarations | Transitive Telemetry; optional Telemetry; mandatory direct dependency | Mandatory `telemetry ~> 1.0`; the core emits its events directly. No new transitive package is intended. |
| Req compatibility | One locked source build; two source builds; two package consumers | Build one archive and run two isolated consumers with disjoint Req witnesses. More resolution/compile time, but proves the delivered contract and actual selected versions. |
| Diagnostics | Keep everything and guard startup; host-managed optional diagnostics; direct-source dev-only diagnostics | Dev-only LiveDashboard/metrics/poller slice, with matching compile and startup boundaries. Preserves direct standalone development without making mounted hosts configure a new feature system. |
| Assets | Keep wrappers everywhere with `runtime: false`; separate dev Mix builder; migrate to external npm/CLI builders | Dev-only existing wrappers and a separate asset-builder stage. Copies only static output into clean test/prod builds; requires changing the current E2E entrypoint. No second asset framework/lock authority. |
| Mail | Remove only the manifest entry; remove the complete unused integration | Remove Swoosh/Mailer/config/obsolete tests and duplicate host declarations; prune locks according to remaining active dependencies. |
| Sigra | Retain patch-only pin; admit compatible 1.x; remove/rewrite authentication | Optional `~> 1.5`, verifying the selected current 1.x release and missing-dependency path. Keep core floor unchanged and state the integration-specific Elixir requirement. Do not claim this fixes Cloak advisories. |
| Upgrade process | Merge old bots sequentially; globally unlock; targeted coordinated refresh | Reconcile changes across four graphs in coherent batches and record every referenced PR's disposition. Extra evidence bookkeeping prevents root-only false greens. |
| Unfixed advisories | Ignore/suppress; remove Sigra; retain approved optional scope and report | Preserve existing approved scope and truthful advisory failure. No risk acceptance, unsupported vendored crypto fix, or new blocking policy is inferred. |

## Core consumer and dependency semantics

Declare `{:telemetry, "~> 1.0"}` and `{:req, "~> 0.6.1 or ~> 0.7"}` as mandatory root dependencies. Ecto also declares Telemetry directly; this is normal ownership of a called API, not an abstraction to hide behind another package. Optional dependencies remain suitable for opt-in integrations such as Oban and Sigra, not for the core HTTP/instrumentation path. [Ecto manifest](https://github.com/elixir-ecto/ecto/blob/v3.13.3/mix.exs), [Telemetry installation](https://github.com/beam-telemetry/telemetry#installation).

Mix distinguishes availability (`only:`), runtime application inclusion (`runtime:`), and downstream opt-in (`optional:`). A dependency normally compiles in `:prod`; its lockfile does not control a consuming project's resolution. `runtime: false` alone does not remove the resolved/compiled dependency. These are existing supported-runtime semantics, not a reliance on newer Mix features. [Mix 1.17.3 dependency implementation/docs](https://github.com/elixir-lang/elixir/blob/v1.17.3/lib/mix/lib/mix/tasks/deps.ex), [Mix 1.19.5 docs](https://mix.hexdocs.pm/1.19.5/Mix.Tasks.Deps.html), [Mix application metadata](https://github.com/elixir-lang/elixir/blob/v1.17.3/lib/mix/lib/mix/tasks/compile.app.ex).

The root lock currently selects Req 0.6.3. Extend `test/release/consumer_smoke_test.exs` and the existing package metadata assertions: build/unpack once, then create independent consumer locks, dependency paths and build paths. Use direct non-overriding witness constraints `~> 0.6.1` and `~> 0.7.0`, assert the selected version belongs to the intended branch, and exercise the same public Scrypath request/response and telemetry behavior. `Req.Test` can provide a service-free maintained Plug stub; declare its required Plug fixture dependency explicitly as test-only. Verify the actual archive's mandatory dependency metadata too, since Ecto's transitive Telemetry would otherwise mask an omitted direct declaration. [Req.Test 0.6.3](https://req.hexdocs.pm/0.6.3/Req.Test.html), [Req.Test 0.7.5](https://req.hexdocs.pm/0.7.5/Req.Test.html), [Req.Plug](https://req.hexdocs.pm/0.7.5/Req.Plug.html).

The approved `~> 0.7` admits stable releases below 1.0; it does not mean only 0.7.x. Keep the approved bound and separate admission from tested witnesses. Research observed stable 0.7.5 and prerelease 0.8.0-rc.0; the prerelease raises the Elixir floor and changes JSON handling. Do not select prereleases. Revisit on a stable new minor or changed transport/JSON behavior; re-resolve on the supported toolchains before extending verification claims. Do not represent two consumers as proof of all future admitted versions. [Version requirements](https://elixir.hexdocs.pm/Version.html), [Req versions](https://hex.pm/packages/req/versions), [0.8 prerelease changelog](https://hex.pm/packages/req/0.8.0-rc.0/files/CHANGELOG.md).

## Ops mode and asset contract

| Mode | Diagnostics | Assets and ownership |
| --- | --- | --- |
| Direct Ops source, dev, standalone | Dashboard, metrics and poller available; start them only for standalone development | Existing dev Mix commands/watchers remain usable. |
| Direct Ops source, test/prod | Development diagnostics absent; supported operator screens remain | Resolve/compile/run without esbuild/Tailwind Mix dependencies; serve separately built static files. |
| Mounted Ops in host dev/test/prod | Ops compiles as a production dependency; does not impose its dashboard/metrics/poller | Host owns its Endpoint/Repo. A host may choose its own dev asset tools or diagnostics; do not prohibit host choices. |
| Isolated asset builder | Dev dependencies exist only in the builder | Copy current source before generating both Ops and storefront bundles; transfer only required static output into the final independently resolved build. |

`ScrypathOpsWeb.Telemetry` currently imports `Telemetry.Metrics` and starts a poller, yet `ScrypathOps.Application` starts it in mounted mode. The Endpoint also unconditionally uses `Phoenix.LiveDashboard.RequestLogger`. Gate the whole diagnostic slice, including imports/macros/routes/modules and its supervisor child, at the appropriate compilation boundary. Keep `RecoveryObservation`, PubSub, TaskSupervisor, actual operator routes and core `:telemetry` event production. The existing runtime `standalone` flag controls endpoint/Repo ownership, not dependency resolution. Do not invent environment-driven dependency lists or a new public diagnostics option matrix. LiveDashboard itself scopes its development build tools and poller to dev. [LiveDashboard manifest](https://github.com/phoenixframework/phoenix_live_dashboard/blob/v0.8.7/mix.exs), [metrics guide](https://phoenix-live-dashboard.hexdocs.pm/metrics.html).

Remove Swoosh and the Mailer throughout Ops and the ecommerce host, including stale application config, mailbox references and the obsolete Swoosh client test. Keep ecommerce's own asset wrappers available in host dev, but scope them to `only: :dev`; changing Ops alone cannot remove duplicate host declarations.

The current test image installs test dependencies and `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh` builds both apps' assets at test runtime. That contradicts dev-only wrappers. Move these builds into a real dev asset stage and remove runtime wrapper installation/build calls. Keep current tool-version authorities and generated JS/CSS behavior; do not copy builder `deps`, BEAMs, `_build/dev`, or dev application configuration into the final test/prod build. Digest under the target environment where required. Document that the production workflow is prebuild/copy/digest/compile, rather than promising `MIX_ENV=prod mix assets.deploy` still runs missing wrappers. [Phoenix assets](https://phoenix.hexdocs.pm/1.8.14/asset_management.html), [Phoenix deployment](https://phoenix.hexdocs.pm/deployment.html), [esbuild wrapper](https://esbuild.hexdocs.pm/Mix.Tasks.Esbuild.html), [Tailwind wrapper](https://tailwind.hexdocs.pm/Mix.Tasks.Tailwind.html).

Prove clean resolution, compilation, generated `.app` requirements, code-path availability, loaded/started applications and route behavior separately. Use isolated environment builds so prior dev artifacts cannot mask omissions. Do not substitute a raw BEAM string/atom ban for those behavioral properties. A host explicitly choosing a dependency is distinct from Ops forcing it.

## Sigra compatibility and authentication

The compatible range recommendation is `{:sigra, "~> 1.5", optional: true}`. Research observed semantic-latest Sigra 1.20.0; all queried published releases declare Elixir `~> 1.18` and retain required `cloak_ecto ~> 1.3`. Keep the root/core Elixir 1.17 policy. Document and verify the Sigra-enabled integration/developer tier separately; `optional: true` still includes Sigra when building Ops as the direct project. The dev asset-builder must use a compatible toolchain, or planning must prove an explicit dependency-excluded build path. [Sigra metadata](https://hex.pm/api/packages/sigra/releases/1.20.0), [Sigra source manifest](https://github.com/szTheory/sigra/blob/main/mix.exs).

**Correction from the cross-area review:** an upstream development `.tool-versions` file is not a consumer OTP floor. The initial interim suggestion that Sigra requires OTP 27 was too strong. Its declared Elixir floor is verified; choose a compatible tested Elixir/OTP tuple and do not invent an OTP-27 minimum. Elixir 1.18's compatibility documentation includes OTP 25–27. [Elixir compatibility](https://elixir.hexdocs.pm/1.18.0/compatibility-and-deprecations.html).

Source inspection found that `Security.validate/1` checks a sudo path for requested Sigra mode without checking integration availability, and the absent-dependency gating branch invokes the sensitive-action callback. Present-dependency gating also invokes it when operator context is nil. This is a permissive configuration fallback; it does not demonstrate a remote authentication bypass, since the host may authenticate upstream. Require explicit Sigra mode to fail validation/startup if unavailable, and sensitive actions to fail closed with missing/invalid Sigra operator context. Test absent and present dependency cases, sudo freshness, impersonation and action auditing; preserve existing non-Sigra basic/proxy-host behavior. Auth-mode selection itself is not host route authentication. Correct the missing Sigra-guide reference with focused setup/support documentation, without adding a new auth system.

## Dated audit baseline and remediation

The security researcher ran `elixir scripts/ci/dependency_audit.exs` at the inspected SHA using isolated temporary homes and pinned Hex 2.5.1. All four graph results parsed completely; locks were unchanged and no ignores were configured. An earlier Hex 2.4.2/cache-permission failure is not an audit result. This is baseline evidence, not evidence that any upgrades work.

| Graph | Research-time result | Proposed disposition |
| --- | --- | --- |
| Root | Clean | Reaudit after its selected dependency updates. |
| Phoenix example | Bandit 1.13.1 affected | Target verified fixed compatible stable Bandit, then exercise backend/consumer paths. |
| Ecommerce | Bandit 1.13.1 affected | Same Bandit correction, clean mounted/image proof. |
| Ops | Bandit 1.13.1, Cloak 1.1.4 and Cloak Ecto 1.3.0 affected | Correct Bandit; retain explicit unresolved Cloak results and optional-integration usage limits. |

Research observed Bandit 1.14.1 released October 28; existing `~> 1.13` bounds admit it, and the queried advisory data reported no findings at that version. Its changelog identifies the latest HTTP/2 DATA-frame fix. Update the three affected graph locks, recheck source/package/runtime compatibility, and rerun audits at the selected final versions; do not treat a dated absence of findings as a permanent security guarantee. [Bandit release metadata](https://hex.pm/api/packages/bandit/releases/1.14.1), [Bandit changelog](https://github.com/mtrudel/bandit/blob/main/CHANGELOG.md), [latest observed advisory](https://osv.dev/vulnerability/EEF-CVE-2026-116078).

No fixed published Cloak/Cloak Ecto version was observed. The findings concern unauthenticated AES-CTR ciphertext and PBKDF2 iteration handling. Sigra's generated vault uses AES-GCM and the inspected integration does not use the PBKDF2 type; those are exposure limits, not package-level clean results or risk acceptance. Preserve approved optional Sigra scope, report findings and upstream-fix/reachability revisit triggers, and do not silence audit exits or vendor cryptographic fixes. Any new deployment risk acceptance remains a maintainer judgment. [Cloak advisory](https://osv.dev/vulnerability/EEF-CVE-2026-95105), [Cloak Ecto advisory](https://osv.dev/vulnerability/EEF-CVE-2026-94206), [Sigra vault template](https://github.com/szTheory/sigra/blob/main/priv/templates/sigra.install/core/vault.ex).

Hex audits do not certify OTP patch/security status. Research found OTP 26's upstream maintenance status has ended. Keep the existing compatibility floor and tested tuples as compatibility facts; do not label that floor upstream-security-supported, raise it silently, or claim an OTP-28-only run proves the floor. Runtime-floor policy changes are separate work. [OTP branch status](https://www.erlang.org/versions?v=26.2.5.3), [OTP security policy](https://github.com/erlang/otp/security).

## Referenced Dependabot dispositions to implement and verify

All ten PRs were open/unmerged at the research read. The entries below are recommendations, not applied updates or remote closure decisions. Revalidate live state when executing. Do not merge stale bot branches sequentially or assume an old target is current.

| PR | Observed proposal | Recommended disposition |
| --- | --- | --- |
| [#65](https://github.com/szTheory/scrypath/pull/65) | actions/cache 6.1.0 | Reconcile with Phase 182's cache wiring in a coherent workflow batch; validate runtime/runner/cache semantics before adopting. |
| [#68](https://github.com/szTheory/scrypath/pull/68) | dependency-review-action 5.0.0 | Compatible workflow batch after checking its Node/runner requirements and existing permissions. |
| [#69](https://github.com/szTheory/scrypath/pull/69) | StreamData 1.4.0 | Root development/test batch; verify properties and changed shrinking behavior. |
| [#70](https://github.com/szTheory/scrypath/pull/70) | setup-node 7.0.0 | Workflow batch after runtime/runner and cache-input review. |
| [#71](https://github.com/szTheory/scrypath/pull/71) | checkout 7.0.1, six workflows | Reconcile all affected references and credential behavior; verify rather than blindly cherry-pick a major. |
| [#72](https://github.com/szTheory/scrypath/pull/72) | deploy-pages 5.0.1 | Workflow patch batch with deployment-workflow syntax/permissions proof; actual publishing remains separately authorized. |
| [#73](https://github.com/szTheory/scrypath/pull/73) | Req 0.7.4, root only | Supersede its narrow/root-only proposal with the approved union bounds in direct declarations and coordinated locks, selecting verified current stable 0.7.x (research: 0.7.5); retain 0.6.x consumer proof. |
| [#74](https://github.com/szTheory/scrypath/pull/74) | ExDoc 0.40.4 | Root development batch with warnings-as-errors documentation proof. |
| [#75](https://github.com/szTheory/scrypath/pull/75) | Dialyxir 1.4.8 | Root development batch with supported-toolchain analysis; audit failure must not obscure whether analysis ran. |
| [#76](https://github.com/szTheory/scrypath/pull/76) | Oban 2.24.1, root only | Reconcile all four graphs at a verified compatible stable version (research: 2.24.2); preserve optional/no-Oban and job behavior. |

For every PR, execution records incorporated, superseded/equivalent, or specifically blocked/deferred with source, selected version, reason, verification and revisit trigger. A workflow major that cannot meet the runner/support constraints receives an explicit disposition rather than forcing a policy change. Prefer scoped `deps.update`/unused pruning, not global unlock; one lock remains one resolution, not an all-versions guarantee.

## Coverage, roles and limits

The combined recommendations cover integrator setup and independent resolution, operator route/security/recovery jobs, contributor asset/CI workflows, package maintainers, supported-runtime testing, security exposure and incident response. Performance work is bounded to removing unused graph/process/build overhead; no unmeasured startup, memory, download or accessibility improvement is claimed. Existing accessible light/dark UI and auth/operational semantics are preservation requirements, not a redesign opportunity.

The adversarial pass changed concrete acceptance: build assets before runtime; preserve host-owned dev tools; guard macros and supervisor children together; distinguish `.app`/code path/loaded/started properties; document Sigra's actual Elixir tier; reject requested-but-unavailable Sigra. A final source reconciliation corrected the unjustified OTP-27 inference. Further general product/graphics/cross-language surveys would not change these decisions and were stopped at diminishing returns.

Keep the five required jobs and existing advisory/path-scoped lanes. Extend `verify.core`, `verify.package`, repository contracts, backend and mounted proof where appropriate, with exact-source closeout from CONTRIBUTING. Audit all four graphs independently after changes and retain raw failures; no new required CI topology, paid judge, pending UAT, baseline auto-update, publication or remote PR cleanup is part of this discussion. Phase 185 and the later UI/adopter milestones remain separate.

Local guidance consulted: `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/elixir-best-practices-deep-research.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/phoenix-best-practices-deep-research.md`, and relevant system-design guidance. Historical OpenSearch/generic-framework examples in prompts inform principles; current Scrypath scope and current upstream sources win over stale package assumptions. No visible design decision requires reviving the older prompt brand book; `PRODUCT.md`, `DESIGN.md` and current brandbook/token authorities govern any preservation checks.
