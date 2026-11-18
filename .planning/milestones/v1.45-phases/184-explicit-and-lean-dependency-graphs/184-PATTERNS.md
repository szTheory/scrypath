# Phase 184: Explicit and Lean Dependency Graphs - Pattern Map

**Mapped:** 2026-10-29  
**Files analyzed:** 44 scoped source, test, config, workflow, and documentation paths  
**Analogs found:** 41 / 44; three bounded gaps are listed below

## File Classification

| New/Modified File(s) | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs`, `mix.lock` | config | dependency graph resolution | same root files; `mix.exs:115-130` | exact |
| `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock` | config | dependency graph resolution | same Ops files; `mix.exs:41-65` | exact |
| `examples/phoenix_meilisearch/mix.exs`, `examples/phoenix_meilisearch/mix.lock` | config | dependency graph resolution | same example files | exact |
| `examples/scrypath_ecommerce/mix.exs`, `examples/scrypath_ecommerce/mix.lock` | config | dependency graph resolution | same app files; `mix.exs:34-58` | exact |
| `test/release/consumer_smoke_test.exs` | test | package/build + request-response | `test/scrypath/meilisearch_test.exs`, `test/scrypath/telemetry_test.exs` | role + flow |
| `test/release/package_metadata_test.exs`, `test/support/release/package_contract.ex` | test, utility | package/build | same consumer harness and package contract | exact |
| `dev/mix/tasks/verify.no_optional_deps.ex`, `dev/mix/tasks/verify/capability.ex` | utility | compile/build | `test/mix/tasks/verify_no_optional_deps_test.exs` | role-match |
| `scripts/ci/dependency_audit.ex`, `scripts/ci/dependency_audit.exs` | utility | batch | `test/mix/tasks/dependency_audit_test.exs` | role + flow |
| `scrypath_ops/lib/scrypath_ops/application.ex`, `scrypath_ops/lib/scrypath_ops_web/telemetry.ex` | application, provider | event-driven/runtime | `scrypath_ops/test/scrypath_ops/application_test.exs` | role + flow |
| `scrypath_ops/lib/scrypath_ops_web/endpoint.ex`, `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, `scrypath_ops/lib/scrypath_ops_web/router.ex` | endpoint, route | request-response | same Ops endpoint/router and `scrypath_ops/test/scrypath_ops_web/router_test.exs` | exact |
| `scrypath_ops/lib/scrypath_ops/security.ex`, `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex`, `scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex` | utility, hook | request-response | same Sigra code and its tests | exact |
| `scrypath_ops/test/scrypath_ops/application_test.exs`, `scrypath_ops/test/scrypath_ops_web/router_test.exs` | test | runtime/request-response | same Ops modules | exact |
| `scrypath_ops/test/scrypath_ops/security_validation_test.exs`, `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs`, `scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs` | test | request-response | same Sigra modules | exact |
| `examples/scrypath_ecommerce/Dockerfile`, `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh`, `examples/scrypath_ecommerce/compose.phase173.yaml` | config, utility | build/runtime | same mounted ecommerce flow | exact for current ownership; no builder-stage match |
| `.github/workflows/ci.yml`, `scripts/ci/beam_cache.cjs`, `scripts/ci/beam_cache.test.cjs` | config, utility, test | batch | same workflow/cache paths | exact |
| `.github/workflows/workflow-security.yml`, `.github/workflows/website.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/release-please.yml`, `.github/workflows/verify-published-release.yml` | config | event-driven | `test/mix/tasks/workflow_wiring_test.exs` | role-match; coverage varies by workflow |
| `test/mix/tasks/dependency_audit_test.exs`, `test/mix/tasks/workflow_wiring_test.exs` | test | batch | same CI verifiers and workflows | exact |
| `guides/support-and-compatibility.md`, `scrypath_ops/README.md`, `examples/scrypath_ecommerce/README.md` | documentation | request-response / deployment | same product and deployment docs | exact |

The four `mix.lock` files are independent graphs: root, Ops, Phoenix example, and ecommerce. All paths above were confirmed with `git ls-files`; no ignored install/runtime mirror is used as an analog. No new source or test filenames are specified in the phase inputs; extend the existing harnesses. The five non-CI action workflows are conditional targets if their current pins are updated.

## Pattern Assignments

### Package consumer and Req compatibility proof

**Primary analogs:** `test/release/consumer_smoke_test.exs`, `test/scrypath/meilisearch_test.exs`, `test/scrypath/telemetry_test.exs`

`consumer_smoke_test.exs` already builds one real Hex archive, unpacks it, creates an isolated adopter, and runs Mix in a temporary environment. Extend that setup to two independent consumer roots, each with its own lock/build identity and non-overriding direct Req witness (`~> 0.6.1` and `~> 0.7.0`). Keep the single archive build shared as D-03 requires.

**Isolated archive/consumer setup** (`test/release/consumer_smoke_test.exs:7-45`):

```elixir
hex_home = Path.join(tmp_root, "hex_home")
mix_home = Path.join(tmp_root, "mix_home")
File.mkdir_p!(hex_home)
File.mkdir_p!(mix_home)
isolated_env = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}, {"MIX_ENV", "dev"}]

build_packaged_artifact!(repo_root, artifact_dir)
...
run_mix!(["deps.get"], cd: app_dir, env: isolated_env)
run_mix!(["compile"], cd: app_dir, env: isolated_env)
```

**Use the public search request path** (`test/scrypath/meilisearch_test.exs:172-200`):

```elixir
Req.Test.stub(stub, fn conn ->
  send(self(), {:search_request, conn.method, conn.request_path, conn.body_params})
  Req.Test.json(conn, %{"hits" => [%{"id" => 99}], "page" => 2, "hitsPerPage" => 20, "totalHits" => 1})
end)

assert {:ok, %SearchResult{hits: [%{"id" => 99}]}} =
         Scrypath.search(SearchablePost, "hello",
           backend: Scrypath.Meilisearch,
           meilisearch_url: "http://localhost:7700",
           req_options: [plug: {Req.Test, stub}]
         )
```

`test/scrypath/telemetry_test.exs:136-160` demonstrates capturing the public `Scrypath.search/3` span and checking its stop metadata. Adapt the test-local capture shape (`:telemetry.attach_many/4`, execute the call, detach, assert event) into generated consumer code or fixture support. Do not use only the internal client API as the consumer contract.

**Package metadata pattern:** `test/release/package_metadata_test.exs:35-53` asserts source package allowlist signals; `test/support/release/package_contract.ex:4-18` states the real `hex.build --unpack` artifact is the authority. Keep those roles. Add the direct Telemetry assertion against built archive metadata and assert actual Req versions in each consumer; current metadata tests alone do not inspect archive dependency metadata.

### Ops dependency, compile, runtime, and auth boundaries

**Primary analogs:** `scrypath_ops/mix.exs`, `scrypath_ops/lib/scrypath_ops/application.ex`, `scrypath_ops/test/scrypath_ops/application_test.exs`, and Sigra tests.

The manifest's dependency list is the concrete declaration style to edit (`scrypath_ops/mix.exs:41-65`): direct packages are tuples with options such as `optional: true`, `only: :dev`, and `runtime: ...`. The current dashboard/metrics dependencies are unscoped and the asset wrappers use a runtime expression; use explicit Mix environment scope for the approved diagnostics and wrappers. Do not let runtime app config decide whether dependencies compile.

**Application ownership pattern** (`scrypath_ops/lib/scrypath_ops/application.ex:21-44`):

```elixir
base_children = [
  ScrypathOpsWeb.Telemetry,
  ScrypathOps.RecoveryObservation,
  {Phoenix.PubSub, name: ScrypathOps.PubSub},
  {Task.Supervisor, name: ScrypathOps.TaskSupervisor}
]

standalone_children =
  if standalone? do
    [ScrypathOps.Repo, {DNSCluster, ...}, ScrypathOpsWeb.Endpoint]
  else
    []
  end
```

`application_test.exs:23-42` inspects `Supervisor.which_children/1` and checks retained children plus absent standalone children. Preserve that executable assertion shape, and make the developer telemetry child follow the same compile-time dependency availability as its module. `endpoint.ex:41-45` has the direct `Phoenix.LiveDashboard.RequestLogger` compile reference to guard alongside route/import/module references; `router.ex` is the mounted route seam. The existing `if Code.ensure_loaded?(Sigra.Audit)` and `if Code.ensure_loaded?(Sigra.Session)` source guards in the Sigra modules are the nearest compile-boundary precedent.

**Fail-closed auth tests:** `security_validation_test.exs:35-48` uses env/config setup, `validate!/0`, and a clear `assert_raise` message. `gating_test.exs:34-57` uses a callback that `flunk`s when impersonation or stale sudo must block. Extend this pattern for explicit Sigra mode without Sigra and for missing/invalid operator context; keep the callback uncalled. The current nil-context closure path at `gating.ex:21-24` and absent-Sigra fallback at `:86-103` are behaviors to change, not patterns to preserve. Existing fresh-sudo action/audit checks continue to apply.

### Ecommerce assets and clean target graphs

**Primary analogs:** `examples/scrypath_ecommerce/Dockerfile`, `docker-e2e-entrypoint.sh`, both app manifests.

Current source paths and dependency ownership are useful references: `Dockerfile:18-32` resolves the root/Ops/ecommerce manifests before copying source. `docker-e2e-entrypoint.sh:17-31` currently installs and builds ecommerce and Ops assets inside the test runtime. Move those build steps to a dev-dependency builder based on current source, then copy only each app's generated `priv/static` output to independently resolved and compiled test/production targets. Preserve the existing source manifests as version/config authorities and retain the target-side digest/serve behavior.

`examples/scrypath_ecommerce/compose.phase173.yaml` and its standalone service are the existing mounted/standalone ownership tests; keep the service boundary and data behavior intact. A separate `Dockerfile.e2e` only builds the browser runner and does not provide a BEAM asset-builder pattern.

### Four-graph audit and action/workflow contracts

**Primary analogs:** `scripts/ci/dependency_audit.ex`, `test/mix/tasks/dependency_audit_test.exs`, `test/mix/tasks/workflow_wiring_test.exs`.

`dependency_audit.ex:4-53` names the four graph directories, verifies tracked locks/source identity, and attempts every graph. `dependency_audit_test.exs:20-63` is the focused runner-injection pattern: capture per-graph calls and assert that later graphs still run after failures. Preserve raw output, nonzero status, and lock identity assertions; don't mask findings to make a graph green.

`workflow_wiring_test.exs:159-208` checks immutable action pins and cache steps, while `:225-231` asserts ordering for audit then deep quality. `:501-523` protects one audit invocation, its advisory status, and the separate remaining-check runner. Extend these static workflow contracts for changed action refs/comments and affected behavior while keeping the five required job identities and existing Phase 182 cache semantics. Existing workflow coverage is strongest for `ci.yml`; there is no equally specific dependency-review or Pages action assertion, so add narrowly scoped assertions if those pins change. Do not add a required CI job.

## Shared Patterns

### Dependency-absent proof

**Source:** `dev/mix/tasks/verify.no_optional_deps.ex:25-49`; test counterpart `test/mix/tasks/verify_no_optional_deps_test.exs:31-58`  
**Apply to:** Ops compile/runtime dependency checks

The verifier clears any old isolated build, launches a separate Mix compiler with its own build path, then checks optional package/build artifacts are absent. Keep clean compilation, `.app` requirements, code path, loaded/started apps, and behavior as separate evidence; a raw BEAM string search is not sufficient.

### Auth and callback assertion

**Source:** `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs:34-64`  
**Apply to:** Sigra present/absent and operator-context branches

Use a callback that fails the test if a forbidden operation runs, then assert the returned redirect/flash or error. Keep the positive fresh-sudo test and audit identity coverage.

### Lock and workflow identity

**Source:** `scripts/ci/dependency_audit.ex:152-200`, `.github/workflows/ci.yml:285-313`  
**Apply to:** each independent dependency graph and deep-quality workflow update

Bind audit evidence to source SHA and before/after lock bytes; keep the audit command's nonzero result visible, and run analysis in the existing distinct follow-up step.

## No Analog Found

| File or pattern | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/scrypath_ecommerce/Dockerfile` new asset-builder/output-only handoff | config | transform | No current project Dockerfile builds both app asset bundles in an isolated stage and transfers only static outputs. Use the locked Research boundary and verify actual paths. |
| built archive direct dependency metadata assertion | test | package/build | Current `package_metadata_test.exs` asserts source Mix metadata and current consumer smoke compiles the archive, but neither asserts the built archive's direct dependency set. Extend the package harness. |
| Pages/dependency-review action version policy | test | event-driven | Existing `workflow_wiring_test.exs` strongly covers CI pins/cache and release wiring, but no specific assertion for the action behavior in `website.yml` or `workflow-security.yml` was found. Add targeted wiring checks only if those refs change. |

## Metadata

**Analog search scope:** root Mix package/test code; `scrypath_ops/`; both examples; `scripts/ci/`; `.github/workflows/`; canonical support docs.  
**Tracked-source check:** every analog path named above was non-empty in `git ls-files -- <path>`.  
**Pattern extraction date:** 2026-10-29
