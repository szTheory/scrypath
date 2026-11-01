---
phase: 184-explicit-and-lean-dependency-graphs
verified: 2026-10-31T01:31:40Z
status: passed
score: 22/22 must-haves verified
verification_scope: implementation_candidate
source_sha: 779c13312de1f2a774d39ad6928aac60d2eecfac
covered_files: [".github/workflows/ci.yml",".github/workflows/publish-hex.yml",".github/workflows/release-please.yml",".github/workflows/verify-published-release.yml",".github/workflows/website.yml",".github/workflows/workflow-security.yml",".planning/phases/184-explicit-and-lean-dependency-graphs/184-01-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-01-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-02-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-02-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-03-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-03-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-04-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-04-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-05-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-05-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-06-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-06-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-07-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-07-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-08-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-08-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-09-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-09-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-10-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-10-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-11-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-11-SUMMARY.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-12-PLAN.md",".planning/phases/184-explicit-and-lean-dependency-graphs/184-12-SUMMARY.md","AGENTS.md","CONTRIBUTING.md","dev/mix/tasks/verify.ops_ui.ex","dev/mix/tasks/verify.phase99.ex","docs/local-demo-docker-dx.md","examples/phoenix_meilisearch/README.md","examples/phoenix_meilisearch/mix.exs","examples/phoenix_meilisearch/mix.lock","examples/scrypath_ecommerce/Dockerfile","examples/scrypath_ecommerce/README.md","examples/scrypath_ecommerce/compose.phase173.yaml","examples/scrypath_ecommerce/compose.yaml","examples/scrypath_ecommerce/config/config.exs","examples/scrypath_ecommerce/config/dev.exs","examples/scrypath_ecommerce/config/prod.exs","examples/scrypath_ecommerce/config/runtime.exs","examples/scrypath_ecommerce/docker-e2e-entrypoint.sh","examples/scrypath_ecommerce/mix.exs","examples/scrypath_ecommerce/mix.lock","examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh","examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh","examples/scrypath_ecommerce/scripts/verify-e2e.sh","guides/support-and-compatibility.md","lib/scrypath.ex","lib/scrypath/meilisearch.ex","lib/scrypath/telemetry.ex","mix.exs","mix.lock","scripts/ci/beam_cache.cjs","scripts/ci/beam_cache.test.cjs","scripts/ci/dependency_audit.ex","scripts/ci/dependency_audit.exs","scripts/ci/ecommerce_build.cjs","scripts/ci/ecommerce_build.test.cjs","scripts/ci/ecommerce_lifecycle.test.cjs","scripts/ci_monitor.cjs","scrypath_ops/README.md","scrypath_ops/config/config.exs","scrypath_ops/config/dev.exs","scrypath_ops/config/prod.exs","scrypath_ops/config/runtime.exs","scrypath_ops/config/test.exs","scrypath_ops/lib/scrypath_ops/application.ex","scrypath_ops/lib/scrypath_ops/integrations/sigra/capability.ex","scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex","scrypath_ops/lib/scrypath_ops/security.ex","scrypath_ops/lib/scrypath_ops_web/dev_router.ex","scrypath_ops/lib/scrypath_ops_web/endpoint.ex","scrypath_ops/lib/scrypath_ops_web/live/search_live.ex","scrypath_ops/lib/scrypath_ops_web/telemetry.ex","scrypath_ops/mix.exs","scrypath_ops/mix.lock","scrypath_ops/test/scrypath_ops/application_test.exs","scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs","scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs","scrypath_ops/test/scrypath_ops/security_test.exs","scrypath_ops/test/scrypath_ops/security_validation_test.exs","scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs","scrypath_ops/test/scrypath_ops_web/router_test.exs","test/mix/tasks/dependency_audit_test.exs","test/mix/tasks/dependency_boundary_contract_test.exs","test/mix/tasks/verify_capability_test.exs","test/mix/tasks/workflow_wiring_test.exs","test/release/consumer_smoke_test.exs","test/release/ops_dependency_boundary_test.exs","test/release/package_metadata_test.exs","test/scrypath/docs_contract_test.exs","test/support/release/package_contract.ex"]
covered_digest: "v4:sha256:68e41b8286744abcfe61902e259d938880012cb06d361ebb7ac178ed079444db"
behavior_unverified: 0
overrides_applied: 0
human_verification: []
decision_coverage:
  honored: 21
  total: 21
  not_honored: []
flagged_prohibitions: 2
prohibitions:
  - statement: "Dependency cleanup must not silently raise the core support floor or authorize security-risk acceptance."
    verification: judgment
    status: unverified
    flagged: true
    verdict: "NON-AUTHORITATIVE LLM judgment: inspected declarations, supported-tuple execution and explicit unaccepted advisory records support preservation. This is not human acceptance."
    flag: "unverified-prohibition — human review recommended; nonblocking intent annotation under the approved no-UAT policy"
  - statement: "Dependency cleanup must not redesign the supported UI, mutate retained-preview data, or authorize publication/merge/PR closure."
    verification: judgment
    status: unverified
    flagged: true
    verdict: "NON-AUTHORITATIVE LLM judgment: inspected presentation diff, preview stop, disposable resource ownership and delivery records support preservation. No approval or delivery authority is inferred."
    flag: "unverified-prohibition — human review recommended; nonblocking intent annotation under the approved no-UAT policy"
outer_acceptance:
  status: pending_terminal_root
  owner: orchestrator
  condition: "Commit all final verification/tracking records, attest that exact successor SHA with canonical closeout, and make no later tracked writes."
---

# Phase 184: Explicit and lean dependency graphs Verification Report

**Phase Goal:** Adopters receive explicit, compatible dependencies and a lighter mounted Ops app, with truthful upgrade and security evidence across the affected graphs.
**Verified:** 2026-10-31T01:31:40Z
**Status:** passed — implementation candidate; final phase acceptance remains conditional below.
**Re-verification:** No — initial verification; no earlier Phase 184 VERIFICATION.md existed.

## Goal Achievement

Actual implementation, requirement-linked tests, raw process results, current manifest/lock hashes and hosted logs establish the goal at `779c13312de1f2a774d39ad6928aac60d2eecfac`. SUMMARY claims were used to discover scope, never as the sole evidence of a truth.

The score covers 22 deduplicated implementation truths: all five roadmap criteria plus the additional detail in all 31 PLAN truths. It does **not** certify future tracking bytes or security-risk acceptance. The two descriptor-less judgment prohibitions remain flagged and unverified; they are not counted as positive truths or silently approved. The session's supplied AGENTS.md and Phase 184 context require executable/exact-source acceptance and keep subjective checks nonblocking; no post-implementation UAT or simulated reviewer is introduced.

### Mandatory outer acceptance condition

CONTRIBUTING.md explicitly requires two stages: attest the candidate, finish and commit final tracking/verification artifacts, then attest the exact final SHA. The first stage is real: [run 41153254156](https://github.com/szTheory/scrypath/actions/runs/41153254156) succeeded at the implementation SHA above. This report and the parent-owned report/tracking changes form a later planning successor.

**That successor has not yet been attested.** Plan 184-10's literal final-tracked-SHA completion clause remains pending at this outer boundary; it is not represented as an already completed terminal run in the score. After all tracked writes, the orchestrator must commit the owned records, run `node scripts/ci_monitor.cjs closeout --push --branch planning/v1.45-foundation-ci --sha "$(git rev-parse HEAD)"`, require the exact repository/ref/new dispatch/SHA, five required jobs, coverage and immutable attestation, and make no further tracked writes. Its external authority will be `/private/tmp/scrypath-phase184-execution/terminal-root-result.json`. No future result is asserted here. A tracked repair afterward requires a replacement terminal run. Do not claim phase acceptance or begin Phase 185 before this condition succeeds.

### Observable Truths

| # | Truth | Status | Actual evidence |
| --- | --- | --- | --- |
| 1 | The root directly declares `telemetry ~> 1.0`; instrumentation and focused HTTP/consumer checks pass with each admitted Req line (`~> 0.6.1` and `~> 0.7`). | ✓ VERIFIED | `mix.exs:125` onward declares both mandatory dependencies. Actual hosted package logs show Req 0.6.3 and 0.7.5 witnesses emitting success/error spans from one archive; four compatibility tuples pass. |
| 2 | ScrypathOps runs without Swoosh/Mailer and builds/runs in test/production without esbuild/Tailwind Mix dependencies; the development asset workflow remains usable. | ✓ VERIFIED | Mail implementation/test are deleted; active manifests/config/routes/locks are clean. Cold Ops consumer tests, the complete direct suite, and actual hosted test/prod runtime proof pass. Docker dev builder invokes both maintained asset aliases. |
| 3 | A mounted adopter does not load standalone/development dashboard or polling/metrics dependencies, while supported standalone/development diagnostics and core telemetry still work. | ✓ VERIFIED | Ops diagnostic tuples are dev-only and optional. Clean consumer test inspects locks, generated .app requirements, module paths, loaded/started apps and core children; dev/test/prod cases and metrics-only counterexample execute. |
| 4 | The relaxed compatible Sigra range passes optional-integration/auth checks, and audit failures are reported rather than suppressed. | ✓ VERIFIED | Exact optional `~> 1.5` selects non-retired 1.7.1; present/absent auth paths are implemented and exercised. Current four-graph audit aggregate really exits 1 for Cloak; the hosted advisory remains failed. |
| 5 | Affected manifests/lockfiles form one verified update set with supported-stack checks, recorded dispositions for referenced Dependabot updates and explicit remaining advisories. | ✓ VERIFIED | Current four manifest/lock hashes match raw audit identities and stable resolver receipts. All ten proposal records are complete; exact-source package/backend/mounted/repository/core, four tuples and Phoenix pass. |
| 6 | The actual archive declares the exact mandatory Telemetry/Req requirements, preserves optional Oban and excludes repository-only tooling. | ✓ VERIFIED | `consumer_smoke_test.exs:121` reads real `hex_metadata.config` before artifact Git initialization; removal mutation rejects missing direct Telemetry despite Ecto. Installed .app/task/lock assertions cover the package surface. |
| 7 | One archive feeds two independently resolved consumers with actual branch/version/lock assertions and identical public request/result/error/span behavior. | ✓ VERIFIED | `consumer_smoke_test.exs:27-46` creates separate roots/homes/builds/deps; `:104` and `:146` assert identities and invoke public search. Hosted package markers share archive `8e23f53dcb8fee816609409a1c29ffa772f39fcc` and select 0.6.3/0.7.5. |
| 8 | The complete unused mail slice is removed, including host config, mailbox route and obsolete locks, while active transitives remain. | ✓ VERIFIED | Both deleted files are absent. AST mutation tests cover both manifests, five Ops configs, both host sites and alias-independent mailbox routing. Final Ops/ecommerce locks omit Swoosh/idna and independently resolve unchanged. |
| 9 | Runtime secrets, environment imports, Repo ownership and existing asset-version authorities are preserved. | ✓ VERIFIED | Actual config and diff retain secret inputs/environment imports, esbuild 0.25.4/Tailwind 4.1.12 authorities and separate ownership. Clean runtime startup and source contracts exercise the resulting configuration. |
| 10 | Optional diagnostic module/import/route/plug/child compilation agrees with available capabilities, including a host with Metrics but no poller. | ✓ VERIFIED | `telemetry.ex:1` requires both real capabilities; Endpoint and router macros guard absent imports. Application starts diagnostics only if their module exists. Real metrics-only cold probe recompiles after explicitly loading Metrics; repaired canonical suite passes. |
| 11 | Mounted Ops leaves Endpoint/Repo to its host; standalone retains supported Endpoint/Repo/routes and core children. | ✓ VERIFIED | `application.ex:21-49` keeps RecoveryObservation/PubSub/TaskSupervisor separate from standalone children. Consumer and application/router tests check supervisor children and supported routes; test/prod HTTP runtime checks pass. |
| 12 | Requested unavailable Sigra fails validation/startup even with a confirmation path; basic/proxy modes remain usable. | ✓ VERIFIED | `Security.validate/1` checks capability before path success; `Application.start/2` validates before supervision. Real no-Sigra VM checks validate/validate!, failed startup/no supervisor and callback nonexecution for every action; host modes start. |
| 13 | Sensitive Sigra actions deny invalid identity/context, impersonation and invalid/future sudo; fresh sudo executes once with preserved identity, while nil/stale sudo reaches confirmation. | ✓ VERIFIED | Actual Gating branches and maintained tests cover every configured action, malformed identity in both fields, timestamps/window, encoded return path and audit arguments. Verifier independently reran named unconfirmed-action and fresh-callback tests against current source and real dependency beams: both pass. |
| 14 | Both app wrappers remain development-only; direct Req bounds, Ops Telemetry and development aliases retain approved versions/output paths. | ✓ VERIFIED | Actual Mix tuples/preferred environments and aliases agree with config. Parsed dependency/alias tests and actual asset-builder commands cover both apps; no alternative build framework was added. |
| 15 | Production names its static manifest and explicit runtime secret/database/endpoint inputs, with no copied test secret/sandbox policy. | ✓ VERIFIED | `config/prod.exs` and prod branch of `config/runtime.exs` require runtime inputs; test sandbox override is separate. Negative source mutations reject unsafe config, and actual independent production startup succeeds. |
| 16 | Clean mounted and direct dev/test/prod cases distinguish graph selection, .app requirements, module paths and loaded/started applications. | ✓ VERIFIED | `ops_dependency_boundary_test.exs:35` and `:67` use fresh roots, anonymous Mix/Hex/archive homes, independent deps/build paths, real no-Sigra and metrics-only cases; canonical local root cold tests and full direct suite pass. |
| 17 | Current-source asset generation transfers only both static trees into independent test/prod graphs, which digest/serve the four exact bundles without runtime wrappers. | ✓ VERIFIED | Docker stages independently resolve root/Ops/host; only two `COPY --from=asset_builder .../priv/static` transfers occur. Runtime script compares builder/target/decoded HTTP bytes, checks content type and graph leakage. Actual hosted runtime proof and cleanup pass; static and extraction-failure checks were rerun here. |
| 18 | Stable compatible Bandit/Req/Oban/Sigra and development tooling selections preserve the existing support policy. | ✓ VERIFIED | Four current locks select Req 0.7.5, Bandit 1.14.1 in HTTP graphs, Oban 2.24.2 where used, Sigra 1.7.1 in direct Ops, StreamData 1.4.0, ExDoc 0.40.4, Dialyxir 1.4.8. Retired Sigra 1.20.0 is rejected in the recorded resolution. Four tuples, properties/docs/package and independent analysis evidence pass. |
| 19 | Compatible immutable Actions preserve exactly five required jobs, permissions/events/credential behavior and Phase 182 cache isolation. | ✓ VERIFIED | Six workflows contain matching immutable pins; workflow/cache contracts cover source identity, scopes and trusted writers. Existing unconditional resolution and independent quality follow-up remain. Actual candidate execution succeeds without new required jobs or publishing events. |
| 20 | Canonical guidance distinguishes admitted ranges from witnesses, core/optional tiers, compatibility/upstream maintenance, audit/runtime security, and source/released claims. | ✓ VERIFIED | Actual support guide and linked Ops/example/runbooks contain these distinctions. Focused docs contracts and warnings-as-errors package/docs evidence pass. Dated historical records remain distinguishable from later superseding lock/audit receipts. |
| 21 | Complete four-graph/ten-proposal evidence preserves real failures and source identity; exact-source closeout controls are wired and exercised. | ✓ VERIFIED | Actual audit term/log/exit, current hashes, complete proposal records, negative completeness tests and independent Dialyzer receipt agree. Canonical closeout succeeded on the integrated implementation SHA with immutable artifacts and unchanged HEAD. Final planning-successor execution remains mandatory as stated above. |
| 22 | Supported presentation/routes/host ownership and retained-preview data are preserved within this dependency phase's objective scope. | ✓ VERIFIED | Phase diff has no asset/static/shared-component changes; SearchLive change only groups helpers. Auth recovery/copy repairs are tested. Hosted full verifier is eligible/clean with zero lifecycle/copy/cleanup errors. Stale-preview stop remains in force; no current rendered or independent design pass is claimed. |

**Score:** 22/22 implementation truths verified; 0 present-but-behavior-unverified truths; 0 overrides. Two nonblocking intent prohibitions remain flagged-unverified.

### PLAN truth accounting

All 31 positive PLAN truths were merged; none reduces the five roadmap criteria. The final-tracking execution clause is preserved as the explicit outer condition, not silently narrowed into candidate acceptance.

| Plan | Positive truths | Merged truth coverage |
| --- | ---: | --- |
| 01 | 2 | 1, 6, 7 |
| 02 | 2 | 2, 8, 9 |
| 03 | 3 | 3, 10, 11, 16 |
| 04 | 3 | 4, 12, 13, 18 |
| 05 | 2 | 9, 14, 15 |
| 06 | 3 | 3, 11–13, 16, 17, 22 |
| 07 | 3 | 5, 8, 18 |
| 08 | 2 | 5, 19, 21 |
| 09 | 3 | 20, 22 |
| 10 | 3 | 5, 20–22; exact final successor execution pending outer acceptance |
| 11 | 2 | 2, 8, 11 |
| 12 | 3 | 9, 17, 22 |

No gap was moved into Phase 185. Its token/contrast foundation scope is separate and does not excuse missing Phase 184 behavior.

### Required Artifacts

The owner CLI's artifact checks pass all 44 declarations across twelve plans. That existence/substance result was supplemented by source/wiring/behavior inspection below. The fingerprint excludes deleted files because the owner rejects missing input paths; their absence is independently asserted by the surviving mail contract.

| Artifact(s) | Expected | Status | Substantive implementation and wiring |
| --- | --- | --- | --- |
| `mix.exs`; `test/release/consumer_smoke_test.exs`; `package_metadata_test.exs` | Exact direct metadata and installed-consumer contract | ✓ VERIFIED | Actual declarations, real archive construction/metadata read, two independently invoked public consumers and .app/task/lock assertions; package capability executes them. |
| `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/mix.exs` | Mail-free graph; dev-only tools/diagnostics; approved ranges/aliases | ✓ VERIFIED | Real Mix dependency/alias functions, not comments or unused declarations; independent resolver/runtime cases exercise them. |
| Five `scrypath_ops/config/*.exs`; host `config/config.exs` and `dev.exs` | Removed mail, retained configuration | ✓ VERIFIED | Active config/source inspected; complete AST negative fixtures are wired into the repository capability. |
| Deleted `scrypath_ops/lib/scrypath_ops/mailer.ex` and `swoosh_api_client_req_test.exs` | Complete unused implementation removal | ✓ VERIFIED (absent as required) | Both absent, no remaining active mail references or obsolete lock entries. |
| Ops `application.ex`, `telemetry.ex`, `endpoint.ex`, `dev_router.ex`; application/router tests | Complete compile/start and ownership boundary | ✓ VERIFIED | Real guarded module/route/plug/child implementations; ordinary and partial-capability cold consumers plus route/supervisor behavior. |
| Ops `security.ex`, `integrations/sigra/capability.ex`, `gating.ex` and auth tests | Optional capability validation and total requested-mode callback gate | ✓ VERIFIED | Startup calls validation; actual sensitive controls call gate; valid branches audit then invoke callback, invalid branches never invoke it. |
| Host `config/prod.exs` and `runtime.exs` | Explicit secure production/static configuration | ✓ VERIFIED | Actual runtime variables/static manifest and distinct test sandbox; production runtime is exercised. |
| `test/release/ops_dependency_boundary_test.exs`; `dev/mix/tasks/verify.ops_ui.ex` | Cold independent modes before complete Ops suite | ✓ VERIFIED | Integration tag/deadline, fresh roots and cleanup; capability invokes cold tests with integration included, then direct suite in isolated paths. |
| `Dockerfile`; both runtime entrypoints; both Compose files | Dev builder and independent tool-free target graphs | ✓ VERIFIED | Real stages/explicit targets/current-source generation; static-only handoff and no runtime wrapper calls. |
| `verify-dependency-boundaries.sh`; `verify-e2e.sh`; Node build/lifecycle tests | Runtime/serve/source/cleanup proof in mounted capability | ✓ VERIFIED | Actual runtime proof precedes focused Compose; fault tests execute actual script with external-I/O doubles. Required hosted mounted run executes the real Docker path. |
| All four `mix.lock` files | Reconciled independent stable update set | ✓ VERIFIED | Actual version/checksum selections, matching current hashes and unchanged second-resolution/audit results. |
| Six workflow files; workflow/cache tests | Compatible immutable pins and unchanged trust topology | ✓ VERIFIED | Correct current SHA/version comments, real CI uses and permission/event boundaries, source/cache mutation tests and hosted execution. |
| Canonical support/build/setup docs and CONTRIBUTING | Accurate central source/release/security guidance | ✓ VERIFIED | Commands resolve to real aliases/targets/capabilities; docs/contract evidence passes. |
| `184-DEPENDENCY-EVIDENCE.md`, `184-ACTIONS-DISPOSITIONS.md`, `184-ACCEPTANCE.md`, `184-VALIDATION.md` | Complete truthful evidence with limits | ✓ VERIFIED | Read alongside actual source, external receipts and raw logs; later lock/source identities explicitly supersede historical rows. Future terminal proof is not asserted. |
| `test/mix/tasks/dependency_boundary_contract_test.exs`; `dependency_audit_test.exs`; `dev/mix/tasks/verify.phase99.ex` | Negative completeness/policy checks in existing repository lane | ✓ VERIFIED | Active assertions reject missing/duplicate/empty/mismatched records and forbidden config/handoff mutations; actual capability references test files. |

### Key Link Verification

The generic owner CLI resolves only 3/23 links textually. Most plans use conceptual endpoints/commands as `from` or describe reverse-direction calls, so its remaining negative results are locator limitations, not proof of missing implementation. All 23 declared links were traced manually to concrete code:

| Plan/link | From → To | Via | Status |
| --- | --- | --- | --- |
| 01.1 | Root project → actual archive metadata | `hex.build --unpack` then metadata read before artifact Git init | WIRED |
| 01.2 | Two installed consumers → public search | Actual Req.Test request/result/error and attached span assertions | WIRED |
| 02.1 | Mail-free manifest → all Ops config | Coordinated active-source removal plus coherent cold/direct startup | WIRED |
| 03.1 | Dev-only dependency tuples → diagnostic module | Both actual compile capabilities required before module definition | WIRED |
| 03.2 | Application → standalone Endpoint/Repo | Runtime flag gates only standalone children | WIRED |
| 04.1 | Application startup → Security validation | `validate!` executes before supervisor construction | WIRED |
| 04.2 | Sensitive control → Gating → callback/audit | Search/failed-sync controls call gate; requested-mode context/sudo branches enforce execution order | WIRED |
| 05.1 | Both manifests → existing aliases/config | Preferred dev environments invoke configured maintained tools | WIRED |
| 05.2 | Production config → runtime_prod | Explicit runtime variables/static manifest, prod compile and target digest | WIRED |
| 06.1 | Ops capability → cold tests → direct suite | Ordered `verification_commands/1` and isolated process dispatch | WIRED |
| 06.2 | Mounted capability → runtime proof | `verify-e2e.sh` invokes `--runtime` before focused Compose | WIRED |
| 07.1 | Final manifests → four locks | Independent lock-stable fetch/audit evidence matches current bytes | WIRED |
| 07.2 | Selected versions → evidence ledger | Actual lock selections and superseding hash rows join official metadata/resolution receipts | WIRED |
| 08.1 | CI → BEAM cache planner | Graph-specific planner invocations, keys/restore policy and unconditional resolution | WIRED |
| 08.2 | Workflow contracts → all six workflows | Immutable pin/version, permissions, events and required-job assertions | WIRED |
| 09.1 | Support guide → setup/build docs | Existing resolved Ops/example/contributor links | WIRED |
| 09.2 | Current guidance → focused contracts | Direct source assertions check current text without rewriting archives | WIRED |
| 10.1 | Audit runner → four actual graph records | Complete inventory, raw outputs/status, source/lock/Hex/ignore joins | WIRED |
| 10.2 | Closeout → exact SHA/run/artifacts | Canonical real candidate invocation verifies identity and immutable artifact digests; successor rerun remains mandatory | WIRED; terminal execution pending |
| 11.1 | Repository capability → mail contract | `verify.phase99.ex` focused list includes the actual test file | WIRED |
| 11.2 | Complete mail removal → application startup/compile | Real Ops suite and independent Docker host/direct target builds | WIRED |
| 12.1 | asset_builder → runtime_test/runtime_prod | Exactly both static trees transferred; independent target resolution/compilation | WIRED |
| 12.2 | Static checker → source/config/entrypoints | Actual checker plus rejecting bad copied-source fixtures | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Value | Source and propagation | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Packaged public search | HTTP request/result and span metadata | Consumer schema/query → actual Scrypath public search → actual Meilisearch/Req adapter → deliberately explicit Req.Test HTTP fixture → normalized SearchResult; actual Telemetry handlers observe start/stop success/error values | Yes; HTTP response is a declared test fixture, not a production fallback | ✓ FLOWING |
| Runtime assets | Four decoded JS/CSS byte streams | Current tracked CSS/JS + configured tools → isolated dev builder → exact static-only COPY → test/prod target files → actual HTTP response bytes/digests/content types | Yes; equality is against independently collected builder output, with source/image/recipe identity | ✓ FLOWING |
| Core/diagnostic telemetry | Real span events, metrics definitions and supervisor children | Real dependencies and capability guard → conditional module/child → direct dev measurements; core search events remain attached/observed in no-diagnostics consumers | Yes | ✓ FLOWING |
| Sensitive action context | Actor/org/sudo/impersonator, return path | Host-authenticated socket → actual OnMount/OperatorContext → Gating validation → shared audit arguments and Sigra.Audit call → callback only when allowed | Yes; host supplies authentication by documented contract | ✓ FLOWING |

No phase-created rendered value terminates in a static fallback or a hollow property. The empty backend response in the clean-consumer telemetry fixture is explicit test input; production search still issues the actual Req request. This dependency phase adds no database-backed UI data source, so a new database query is not an applicable artifact requirement.

### Behavioral Spot-Checks

No server, real service, build or full suite was started by this verifier. Existing exact-source service/consumer/browser proofs were inspected instead of duplicated.

| Behavior | Command/check executed by verifier | Result | Status |
| --- | --- | --- | --- |
| Ordinary unconfirmed operator reaches confirmation without callback for every action | Service-free Elixir process loads real dependency beams and compiles current OperatorContext, OnMount, capability, Security and Gating; runs only `test an unconfirmed operator reaches confirmation without running any protected action` | 1 test, 0 failures, 11 excluded; exit 0; under 1 second | ✓ PASS |
| Fresh sudo invokes callback once and preserves audit argument identity | Same actual-source process; only `test fresh sudo invokes the closure once and passes audit identity to Sigra` | 1 test, 0 failures, 11 excluded; exit 0; under 1 second | ✓ PASS |
| Failed target extraction preserves original failure and reports cleanup success/failure | `node --test --test-name-pattern='runtime boundary target extraction' --test-reporter=tap scripts/ci/ecommerce_lifecycle.test.cjs` | Four actual-script external-I/O fault cases pass for both targets; original copy exit 42 preserved; approximately 6 seconds | ✓ PASS |
| Static-only handoff and runtime shell syntax | `bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only` plus `bash -n` on both verifiers and entrypoints | Explicit four-asset/output-only success marker; syntax exits 0 | ✓ PASS |
| Current exact-source required/optional lanes | Read-only `scripts/ci_monitor.cjs test-summary 41153254156` and focused `grep` after its `--help`; external XDG cache | Required five + coverage + attestation, four tuples and Phoenix pass; hosted Ops skipped. Full step reports `Docker verifier passed (scope=full)`, lifecycle/copy/cleanup all 0 and hosted-exact-sha eligible/clean true | ✓ PASS |

The service-free named tests used Elixir 1.19.5/OTP 28.5, `-pa '/private/tmp/scrypath-phase184-execution/sudo-recovery-build/lib/*/ebin'`, compiled the five current integration/security files in memory, and used ExUnit's exact test-name include with all other tests excluded. No test helper, application, endpoint or database was started. The full canonical Ops result is separate external evidence, not inferred from these probes.

### Probe Execution

No `scripts/*/tests/probe-*.sh` file or explicitly declared `probe-*.sh` path exists for this phase. There is no missing conventional probe. The declared static dependency checker was independently executed above. Its runtime mode was actually executed in the exact-source required hosted mounted job: raw log says `Runtime dependency boundary proof passed (test/prod graphs, owned cleanup, and four served assets per target)` and `DEPENDENCY_BOUNDARY case=cleanup status=passed`. It was not replaced by SUMMARY narration or a selector result.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DEP-01 | 01, 07, 09, 10 | Explicit mandatory root Telemetry and instrumentation | ✓ SATISFIED | Exact source and actual archive metadata/mutation, installed consumer spans, core telemetry proof |
| DEP-02 | 01, 07, 09, 10 | Approved Req union and focused proof for both lines | ✓ SATISFIED | Independent 0.6.3/0.7.5 public HTTP/normalization/error/span witnesses; actual versions/locks; broad-range limits documented |
| DEP-03 | 02, 06, 07, 10, 11 | Remove unused Swoosh/Mailer source/config/references/locks | ✓ SATISFIED | Full mail AST/deletion/mutation contract, clean independent locks and actual application startup/compile |
| DEP-04 | 03, 05, 06, 09, 10 | Mounted diagnostic exclusion with intended dev/core behavior | ✓ SATISFIED | Dev-only optional tuples, complete compile/start guards, real clean/metrics-only mode probes, ownership and core telemetry assertions |
| DEP-05 | 05, 06, 09, 10, 12 | Test/prod tool-free Ops with usable dev generation | ✓ SATISFIED | Real maintained builder, independent target graph/app/path checks, current-source handoff and served-byte equality |
| DEP-06 | 04, 06, 07, 09, 10 | Relax compatible optional Sigra, verify auth, retain audit failures | ✓ SATISFIED | Exact optional range/stable lock; present/absent startup, total invalid-context denial, sudo/identity behavior; raw nonzero audit unignored |
| DEP-07 | 07, 08, 09, 10 | Reconciled graphs/proposals/support and remaining advisories | ✓ SATISFIED | Four current stable locks, complete ten-proposal union, immutable Actions/trust contracts, supported tuple and real candidate evidence; mandatory terminal successor condition remains |

All seven requirement IDs appear in plan frontmatter and REQUIREMENTS.md maps exactly these seven to Phase 184. No orphaned Phase 184 requirement was found. Their unchecked global tracking markers are parent-owned bookkeeping pending this verification; they are not evidence of absent implementation.

### Decision Coverage

Owner query `check.decision-coverage-verify` returned: **All trackable CONTEXT.md decisions are honored by shipped artifacts.** Honored 21/21; no missing decisions. This heuristic was treated as advisory and supplemented by actual code inspection.

### Test Quality Audit

| Test surface | Linked requirements | Active / skipped | Circularity / assertion strength | Verdict |
| --- | --- | --- | --- | --- |
| Consumer smoke and package metadata | DEP-01, DEP-02 | 6 + 6 declared tests; no disabled coverage | Real archive metadata and independent installed versions; explicit independent request/result/error expectations; behavior/value assertions | Adequate |
| Cold Ops boundary consumers | DEP-03–DEP-06 | 2 integration tests intentionally included by Ops capability; no disabled requirement proof | Fresh real graphs and processes; distinct .app/code/app/startup/callback assertions | Adequate |
| Ops Gating/OnMount/path/application/router tests | DEP-04, DEP-06 | Active present-dependency cases; real canonical direct suite passes | Callback sentinel/nonexecution, actual LiveView navigation, valid/invalid identity and audit argument values; behavioral assertions | Adequate within stated host-auth contract |
| Dependency boundary/audit contracts | DEP-01–DEP-07 | 18 + 17 declared tests; no disabled requirement proof | Bad fixtures produce rejection; missing/duplicate/source/lock/ignore/continuation and CLI nonzero paths; value/behavior assertions | Adequate |
| Node lifecycle/build/cache tests | DEP-05, DEP-07 | Current repository-script run has no skipped cases | External-I/O doubles test harness failure/cleanup semantics; real runtime/browser acceptance is separately established by hosted proof | Adequate; fixture outputs are not represented as browser acceptance |
| Workflow/guidance/capability contracts | DEP-04–DEP-07 | Active source assertions exercised by required repository lane | Immutable pins, command ordering, range/limit and trust assertions; actual execution independently corroborates source checks | Adequate |

No test linked to a requirement is disabled as its only proof. Pattern matches on `on_exit`/`process.exit` are cleanup/fault code, not `xit`; no disabled-test defect was inferred from those substrings. Fixtures write copied-source mutations and deliberate external-I/O responses; they do not derive a correctness oracle from the system under test.

Disconfirmation checks: source-only contracts cannot prove mounted startup, so the real cold/runtime proofs were required and found. The mounted absent-callback helper tolerates an unavailable function; that helper alone would not prove Gating exists. Actual current Gating source, real-module named probes and the complete direct suite provide the independent implementation/behavior evidence. Audit-argument assertions prove identity construction, not universal audit persistence; the source actually passes that constructed tuple into maintained `Sigra.Audit.log_safe/3`, and this phase makes no new audit-storage guarantee.

### Anti-Patterns Found

| File/surface | Pattern | Severity | Impact/disposition |
| --- | --- | --- | --- |
| Current Ops audit and hosted deep-quality | High Cloak AES-CTR authentication finding; medium Cloak Ecto PBKDF2 finding | ⚠️ Known upstream dependency findings | Both remain affected/unaccepted; aggregate exit 1 is preserved. The goal requires honest accounting, not an unavailable upstream fix. No ignore/waiver/security clearance. |
| Retained preview review | Source preflight refuses stale provenance | ℹ️ Preserved safety stop | No preview mutation or current rendered/independent design claim. Subjective rendered evidence remains nonblocking under approved scope. |
| Two PLAN intent prohibitions | Descriptor-less judgment evidence | ⚠️ Flagged-unverified intent annotations | Retained prominently in frontmatter; non-authoritative judgment only, human review recommended, no requested UAT/approval or accepted risk. |
| Generic key-link CLI | Conceptual `from` values/reverse call direction | ℹ️ Locator limitation | All negative textual results were resolved by concrete manual wiring traces; not auto-passed. |
| Full changed-file scan | `JTBD`, `mktemp ...XXXXXX`, input placeholder attributes, missing-optional-file reader and fixture empty log list | None | These are not unresolved debt comments or rendered stubs. No unreferenced TBD/FIXME/XXX debt marker, empty production implementation or console-only handler was found. |

Scanned all 64 surviving changed source/documentation/test files from the phase base, plus deleted-file disposition. No objective BLOCKER or incomplete wiring WARNING remains. The original five code-review findings and two concrete UI recovery/copy findings were rechecked in actual source, their repaired tests and subsequent canonical evidence; none is reopened by unevidenced new scope.

### Human Verification Required

None. No positive truth remains PRESENT_BEHAVIOR_UNVERIFIED or insufficient-spec. No PLAN contains a deferred `<human-check>` block. The approved repository/session policy requires executable or exact-source evidence rather than post-implementation human acceptance. Full-inventory/current-rendered Sigra critique remains an expressly nonblocking evidence limit, not an invented user task. The two unresolved judgment prohibitions remain recommendations/annotations exactly as described above.

### Exact-source and audit evidence

- Actual canonical candidate authority: `/private/tmp/scrypath-phase184-execution/candidate-root-repaired-result.json`; command exit 0, repository `szTheory/scrypath`, branch `planning/v1.45-foundation-ci`, new `workflow_dispatch`, source/completed HEAD `779c13312de1f2a774d39ad6928aac60d2eecfac` and unchanged HEAD.
- Coverage artifact `13023504806`: `sha256:21bd6e9ce0dad8142b530eba49d2cbabf0e8ebd531afa91af1ec3141301303ad`. Attestation artifact `13025026532`: `sha256:30b62993032bc0d65dcff7b4e8a5336f8a2f754918e528bf2128d7a08f75266f`. Actual wrapper/hosted logs corroborate the join; these artifacts attest the candidate, not this later planning successor.
- Fresh four-graph raw authority: `current-root-audit.term`, `.log` and `.exit` under the same external directory. Every graph is complete and lock-stable, source-bound to the candidate, Hex 2.5.1, default empty advisory/retirement ignores. Root/Phoenix/ecommerce audit clean; Ops affected; aggregate exit 1. Current lock hashes independently checked here match:
  - root `40535db1c56fdd39c3ec55327c29b6044fe6becb1626289a2973a5d8878f96b3`
  - Phoenix `61844005edac11b96e952ab06d08fce5dcc8ac5392d50d4ee76b5c2dfea74980`
  - ecommerce `19024cdcc5be4d78f43ba990ec6b6113b8f9f58004031591d573834ba4c8817e`
  - Ops `f1771d6219216b5b144f1cf3d220ee487de39da7df071c8bbdaba1b2b3a44fdf`.
- Actual hosted failed-advisory log `candidate-repaired-failed.log` contains only the two Cloak findings. Newly published Phoenix.HTML issue is repaired by compatible 4.4.0 in both affected locks; resolver before/after/stable-second-fetch receipt and official captured metadata/changelog are `phoenix-html-*`. No old clean result was substituted for this fresh audit.
- Canonical local Ops authority: `phoenix-html-full-ops.log` (cold boundary checks then 320 direct tests + 2 doctests, no failures) and `phoenix-html-postgres.json` (test exit 0, owned cleanup 0). That receipt names precommit HEAD `501dd05a`; the separately hashed lock-resolution receipt and actual direct log identify the 4.4.0 working-tree repair. The cold archive case uses its recorded committed source; exact final-SHA Docker mounted test/prod graphs independently exercise current locks. The hosted path-scoped Ops job was skipped and is not relabeled execution.
- Current prior-phase regression authority: `regression-current-result.json` / `regression-root-current.log` at the candidate SHA, exit 0; repository-script `candidate-repair-node.log` passes without skipped cases. The verifier did not rerun either suite.
- Independent Dialyzer raw output/result: `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/dialyzer-final.stdout` and `receipts/dialyzer-final.exit`, actual exit 0, total errors 0. Root source/lock relevant to that analysis remains unchanged; later Ops/host HTML repair is separately tested. A failing aggregate audit did not conceal analysis.
- Current read-only CI monitor independently confirmed all four compatibility tuples, Phoenix and full browser success. Raw full-step evidence is `scope=full`, original/copy/cleanup exit 0, zero owned resources and hosted-exact-sha eligible/clean true. This is stronger than an advisory job conclusion alone, and still does not claim a complete rendered aesthetic review.

### Gaps Summary

No implementation gap blocks the Phase 184 goal. The update is compatible and lean in the intended boundaries, with executable failure-path and real hosted evidence. Remaining Cloak findings stay failed/unaccepted; the stale retained-preview stop remains preserved; two intent prohibitions stay explicitly flagged-unverified.

**Phase acceptance is still withheld until the orchestrator obtains the separate exact final planning-successor terminal-root receipt after every tracked write.** This report grants no merge, publication, remote proposal cleanup, security-risk acceptance, human approval or next-phase authority.

---

_Verified: 2026-10-31T01:31:40Z_
_Verifier: the agent (gsd-verifier)_

