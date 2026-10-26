# Phase 181: Schema hook contract and no-Oban build - Research

**Researched:** 2026-10-26
**Domain:** Elixir behaviours/`@optional_callbacks`, compile-time macros, Mix optional-dependency builds, Elixir 1.19 type-checker warnings, CI lane wiring
**Confidence:** HIGH. Every central claim was checked by a local probe on Elixir 1.19.0 / OTP 28.1, the version CI uses.

## Summary

Scrypath calls exactly three duck-typed hooks on adopter schema modules: `search_document/1`, `search_document_id/1` and `search_records/2`. Each is detected with `function_exported?/3`. No behaviour declares them today: `Scrypath.Schema.__using__/1` injects only `__scrypath__/1`. The idiomatic fix is the `use GenServer` pattern. Declare the three as `@callback` plus `@optional_callbacks` on the existing public module `Scrypath.Schema`, and have `__using__` inject `@behaviour Scrypath.Schema`. This alone does not catch a wrong arity. Probes show the compiler is silent about `def search_records(ids)` under an optional-callback behaviour unless the adopter writes `@impl true`. So the phase also needs a `@before_compile Scrypath.Schema` check that warns when a hook name is defined only at a non-hook arity. A prototype of this check fails `mix compile --warnings-as-errors` with a located warning. It added no compile warnings to the existing test suite, and Elixir also starts flagging a hook written with `defp` for free.

The no-Oban half has a much bigger finding. **`mix verify.no_optional_deps` is a false green today, and `main` does not compile warning-free without Oban on Elixir 1.19.** When `_build/<env>/lib/oban` already exists, which is always true in CI because of the `_build` cache and because `mix run` compiles every dep first, `mix compile --no-optional-deps` still puts Oban on the code path. In that case `Code.ensure_loaded?(Oban.Job)` is true and nothing is really tested. With Oban actually absent, the build fails on a real Elixir 1.19 type warning in `lib/scrypath/sync.ex:74`. The cause is the no-Oban `Scrypath.Sync.RelatedEnqueue` stub, which always raises, so the checker infers its return type as `none()`. The same compile passes on 1.17.3 and 1.18.4. The check also never effectively runs in CI: it lives only in `deep-quality (advisory)`, and on the latest `main` run that job failed at `dependency_audit.exs`, so the step that calls it was **skipped**.

**Primary recommendation:**
1. Put the hook contract on `Scrypath.Schema` (callbacks, `@optional_callbacks` and a `@before_compile` arity check).
2. Fix `verify.no_optional_deps` so it compiles into an isolated build path with no prebuilt optional deps (`MIX_BUILD_PATH`), and have it assert afterwards that Oban really was absent.
3. Remove the `sync.ex` warning by making `RelatedEnqueue` unconditional and building its jobs through `Scrypath.Oban.Enqueue`'s existing runtime-guarded job builder, the same pattern the main enqueue path already uses.
4. Run the check in `core (required)` by composing it into `Mix.Tasks.Verify.Capability.run(:core, …)`. This mirrors how Phase 178 composed `verify.postgres` into `verify.backend`.

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Elixir support floor is `1.17`, the target is current stable through `1.19`, and OTP is 26–28. Anything new (`Code.with_diagnostics/1`, `Module.definitions_in/2`, `IO.warn/2` with a `Macro.Env`) must work on 1.17. Probes confirmed this on 1.17.3 and 1.19.0.
- Oban is an **optional** integration. Inline and manual sync must work without it, and the core path should be mostly plain functions with no mandatory supervision.
- The adapter seam is internal. Do not promise a public multi-backend facade. That is not affected here, because the hooks are schema-side.
- **Lean required gates.** Do not add a new required CI lane. Fold checks into existing capability commands (CONTRIBUTING "Canonical verification commands").
- **Shift verification left.** Completion must be backed by executable tests or exact-SHA hosted evidence. Never rely on human UAT (user memory: "0 human UAT — automate verification").
- PR-first, squash-only and green `main`. Keep edits focused. Update `.planning/PROJECT.md` when shipped claims change: the two unchecked v1.44 bullets "Schema hooks are declared optional callbacks." and "Builds without Oban compile with no warnings."
- Run the checks CONTRIBUTING names for the change: `mix verify.core`, `mix verify.package` (docs and package contract), and `mix verify.no_optional_deps`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hook contract declaration (`@callback`/`@optional_callbacks`) | Library public API (`Scrypath.Schema`) | HexDocs | The module that adopters `use` owns the contract, following the `use GenServer` → `@behaviour GenServer` convention |
| Wrong-arity detection | Compile time (`__before_compile__` in the adopter's module) | ExUnit test via `Code.with_diagnostics/1` | Only compile time sees the adopter's definitions before `function_exported?` silently ignores them |
| Runtime hook dispatch | `Scrypath.Identity` / `Scrypath.Projection` / `Scrypath.Loader` | — | Unchanged. `function_exported?` detection stays as it is |
| No-Oban compile correctness | Library source (`Scrypath.Sync.RelatedEnqueue`, `Scrypath.Oban.Enqueue`) | — | Remove the always-raising stub that drives the type warning |
| No-Oban build check | Mix task (`verify.no_optional_deps`) | CI `core (required)` via `verify.core` | Existing task, fixed and composed into an existing required capability |

## Hook Inventory (Question 1)

Grep of `lib/` for `function_exported?`, `Code.ensure_loaded`, `apply(` and `schema_module.` found three adopter-implemented hooks. Everything else that is called on a schema module is Scrypath-generated (`__scrypath__/1`) or Ecto-generated (`__schema__/1,2`).

| Hook | Detected at | Called at | Default when absent | Notes |
|------|-------------|-----------|---------------------|-------|
| `search_document/1` | `lib/scrypath/projection.ex:19` and `:28` `function_exported?(schema_module, :search_document, 1)` | `projection.ex:33-34` `\|> schema_module.search_document()` | Projects the declared `fields:` (`build_field_document/2`); `document_source` is `:fields` | Must return a map, or it raises `"search_document/1 must return a map"` (`projection.ex:92`). `:id`/`"id"` keys in the result override the id. The tenant field is auto-injected |
| `search_document_id/1` | `lib/scrypath/identity.ex:19-21` `function_exported?(schema_module, :search_document_id, 1)` | `identity.ex:6-7` `schema_module.search_document_id(source_record)` | The record's `document_id` field (default `:id`) via `Scrypath.Schema.Metadata.document_id/1` | If it is present *without* `search_records/2`, Oban sync is rejected: `Loader.check_loadable/2` → `{:error, :search_records_required}` (`loader.ex:53-58`) |
| `search_records/2` | `lib/scrypath/loader.ex:41-43` `Code.ensure_loaded?(schema_module) and function_exported?(schema_module, :search_records, 2)` | `loader.ex:153-157` `schema_module.search_records(document_ids, %{repo: repo})` | Ecto query on the `document_id` field with cast ids, plus the declared `preload:` | Receives at most 1000 deduped ids per call and a context `%{repo: repo}`, where `repo` may be nil. A non-list return becomes `{:error, {:invalid_search_records, other}}`. It is used by inline load, the Oban workers, backfill and reindex (all through `Scrypath.Loader`) |

[VERIFIED: Read of lib/scrypath/identity.ex:1-38, lib/scrypath/projection.ex:1-111, lib/scrypath/loader.ex:1-80,140-170]

Verbatim detection code:
- `identity.ex:19-21`: `def supports_custom_document_id?(schema_module) do` / `function_exported?(schema_module, :search_document_id, 1)`
- `projection.ex:19`: `if function_exported?(schema_module, :search_document, 1) do`
- `loader.ex:42`: `Code.ensure_loaded?(schema_module) and function_exported?(schema_module, :search_records, 2)`

**Not hooks, and kept out of the behaviour:** `fan_outs:` resolvers are MFAs on arbitrary modules (`sync.ex:108`, `related_worker.ex:73` `apply(mod, fun, ...)`). `__scrypath__/1` is generated by the macro. `__schema__/1,2` is Ecto's.

**Adjacent observation, out of scope:** `identity.ex` and `projection.ex` call `function_exported?` without `Code.ensure_loaded?`, unlike `loader.ex`. In practice the module is already loaded because `__scrypath__/1` has been called by then, so this phase leaves it alone.

## Standard Stack

No new dependencies. Everything below is Elixir/Mix core.

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `@callback` + `@optional_callbacks` | Elixir core | Declare the hooks so ExDoc renders them under "Callbacks" | The canonical way to document a duck-typed module contract [VERIFIED: probe — `Code.fetch_docs(Scrypath.Schema)` returned `{:callback, :search_records, 2}` entries after the prototype] |
| `@before_compile` + `Module.definitions_in/2` + `IO.warn/2` with `Macro.Env` | Elixir core (≥1.17 verified) | Wrong-arity compile check | Produces a located compiler diagnostic that `--warnings-as-errors` and `Code.with_diagnostics/1` both see [VERIFIED: probe on 1.17.3 and 1.19.0] |
| `Code.with_diagnostics/1` + `Code.compile_string/1` | Elixir core (≥1.15) | Unit-test the compile check | Returns structured diagnostics with no stderr scraping. `test/scrypath/schema_test.exs` already uses `Code.compile_string` |
| `mix compile --no-optional-deps --warnings-as-errors` | Mix core | No-Oban build | Already used by `verify.no_optional_deps` |
| `MIX_BUILD_PATH` env var | Mix core | Isolate the no-Oban build from the cached `_build` | Mix docs: "sets the project `Mix.Project.build_path/0`, including the current environment" [CITED: `Code.fetch_docs(Mix)` on 1.19.0, MIX_BUILD_PATH entry] [VERIFIED: probe — used for all no-Oban runs below] |

## Package Legitimacy Audit

Not applicable: this phase installs no external packages. `mix.exs` deps are unchanged.

## Architecture Patterns

### System Architecture Diagram

```
adopter module ── use Scrypath ──> Scrypath.__using__ ──> Scrypath.Schema.__using__
                                                     │
                       injects: @behaviour Scrypath.Schema         (NEW)
                                @before_compile Scrypath.Schema    (NEW)
                                def __scrypath__/1 ...             (existing)
                                                     │
adopter defs (search_document/1, search_records/2 ...)
                                                     ▼
            compile: Elixir behaviour checks ──> warns on defp hook / @impl mismatches
            compile: Scrypath.Schema.__before_compile__ ──> warns "defines search_records/1
                                                            but Scrypath calls search_records/2"
                                                     ▼
            runtime: Identity / Projection / Loader ── function_exported? ──> hook or default

no-Oban build check:
mix verify.core ──> verify (fmt, compile, credo, tests, docs)
                └─> verify.no_optional_deps (NEW in core)
                       └─ System.cmd mix compile --force --no-optional-deps --warnings-as-errors
                          env MIX_BUILD_PATH=<isolated dir>  (no prebuilt lib/oban)
                          └─ post-assert: <isolated>/lib/oban absent AND Oban worker beams absent
```

### Pattern 1: Hook contract on `Scrypath.Schema` (HYG-01)

**What:** Add `@doc`-documented `@callback`s and `@optional_callbacks` to `Scrypath.Schema`. Inject `@behaviour Scrypath.Schema` and `@before_compile Scrypath.Schema` from `__using__`.
**Module name:** `Scrypath.Schema`. It is already the public, documented module that owns "declaration grammar" (`lib/scrypath.ex:49-50`: "`Scrypath.Schema` — read that module instead of duplicating option tables here"). `use Scrypath` delegates to it (`lib/scrypath.ex:79-83`), and Elixir's convention is that `use X` injects `@behaviour X`. A separate `Scrypath.Schema.Hooks` would be a second page adopters must discover. Do not create one.

Prototype that compiled cleanly and kept the existing suite free of compile warnings on 1.19.0 (scratch copy):

```elixir
# lib/scrypath/schema.ex (prototype shape — add @doc text per callback)
@doc "Builds the search document for `record`. ..."
@callback search_document(record :: struct() | map()) :: map()
@doc "Returns the search document id for `record`. ..."
@callback search_document_id(record :: struct() | map()) :: term()
@doc "Loads the current records for `document_ids` (≤ 1000 per call). ..."
@callback search_records(document_ids :: [term()], context :: %{required(:repo) => module() | nil}) ::
            [struct() | map()]
@optional_callbacks search_document: 1, search_document_id: 1, search_records: 2

@hooks [search_document: 1, search_document_id: 1, search_records: 2]

@doc false
defmacro __before_compile__(env) do
  defs = Module.definitions_in(env.module, :def)

  for {name, arity} <- @hooks,
      arities = for({^name, a} <- defs, do: a),
      arities != [] and arity not in arities do
    IO.warn(
      "#{inspect(env.module)} defines #{name}/#{Enum.join(arities, ", ")} but Scrypath calls #{name}/#{arity}",
      env
    )
  end

  :ok
end

# inside __using__'s quote, before Module.register_attribute:
@behaviour Scrypath.Schema
@before_compile Scrypath.Schema
```

Insertion point: `lib/scrypath/schema.ex:32-34` (`quote bind_quoted: [config: Macro.escape(config)] do` / `Module.register_attribute(__MODULE__, :scrypath_config, persist: true)`) [VERIFIED: Read lib/scrypath/schema.ex:26-36].

Design rules:
- Warn only when the hook name exists at some arity **and** the expected arity is absent. A helper such as `search_document/2` next to a correct `search_document/1` stays silent.
- Optional improvement: point the warning at the offending `def` line instead of the `defmodule` line. Read `Module.get_definition(env.module, {name, a})` meta `:line` and call `IO.warn(msg, file: env.file, line: line)`. The prototype's location was the `defmodule` line, which is acceptable.
- Use `IO.warn`, not `raise`. This matches Elixir's own `@impl`/behaviour diagnostics: it fails `--warnings-as-errors` builds without breaking adopters who compile without that flag. [ASSUMED: preference; raising would also satisfy "flags"]

### Pattern 2: Isolated no-optional-deps build (HYG-02 check)

**What:** In `Mix.Tasks.Verify.NoOptionalDeps.run/1`, pass `MIX_BUILD_PATH` pointing to a dedicated directory. After the compile, assert that no optional dep was built there and that Oban-only modules were not generated.

```elixir
# shape only — names are the planner's choice
build_path = Path.join(Path.dirname(Mix.Project.build_path()), "no_optional_deps")
File.rm_rf!(Path.join(build_path, "lib/oban"))   # defensive: never reuse a prebuilt optional dep

System.cmd(mix, ["compile", "--force", "--no-optional-deps", "--warnings-as-errors"],
  env: [{"MIX_ENV", "prod"}, {"MIX_BUILD_PATH", build_path}],
  stderr_to_stdout: true)

# anti-false-green self-check
for {dep, _req, opts} <- Mix.Project.config()[:deps], is_list(opts), opts[:optional] do
  if File.exists?(Path.join([build_path, "lib", to_string(dep)])), do: Mix.raise("...")
end
if File.exists?(Path.join(build_path, "lib/scrypath/ebin/Elixir.Scrypath.Oban.UpsertWorker.beam")),
  do: Mix.raise("Oban was on the code path; the no-optional-deps build proved nothing")
```

`MIX_ENV=prod` vs the current `Mix.env()` (test): **use prod.** It matches what an adopter's dependency compile sees: no test-only deps such as `plug`, `ecto_sqlite3` or `postgrex` that could hide optional-dep fallout. It is also faster cold. The probe compiled the whole prod dep set plus Scrypath in about 4.8s wall time locally, and it reproduces the same red/green [VERIFIED: probe]. It needs prod deps fetched; plain `mix deps.get` fetches every env and CI already runs it. If the planner prefers to keep `Mix.env()`, the isolated path alone still fixes the false green.

### Pattern 3: Remove the always-raising stub (HYG-02 fix)

**What:** Make `Scrypath.Sync.RelatedEnqueue` a single, unconditional module that builds jobs through `Scrypath.Oban.Enqueue.job_changeset/4`. Today that is a `defp` at `lib/scrypath/oban/enqueue.ex:224`; promote it to `@doc false def`. It already resolves `Oban.Job` at runtime through `oban_job_module!/0` (`enqueue.ex:251-258`) and raises the identical "Oban dependency is required…" message.

Current code that causes the warning [VERIFIED: Read lib/scrypath/sync/related_enqueue.ex:1-2,36-48,77-85; lib/scrypath/sync.ex:68-74]:

```elixir
# related_enqueue.ex:1-2
if Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Sync.RelatedEnqueue do
# related_enqueue.ex:44-48
            Oban.Job.new(job_args(schema_module, chunk, fan_out_key, config),
              worker: @worker,
              queue: queue,
              max_attempts: max_attempts,
              unique: Enqueue.unique_opts()
# related_enqueue.ex:77-83
else
  defmodule Scrypath.Sync.RelatedEnqueue do
    @moduledoc false

    def enqueue(_schema_module, _records, _fan_out_key, _config) do
      raise ArgumentError,
            "Oban dependency is required for sync_mode :oban. Add {:oban, \"~> 2.21\", optional: true} to your deps."
# sync.ex:71-74
        config
        |> Config.ensure_oban_ready!()
        |> then(&RelatedEnqueue.enqueue(schema_module, records, fan_out_key, &1))
        |> decorate_result(config)
```

Prototype replacement inside the `Enum.map` (behaviour-identical: same worker, `queue: to_string(Config.oban_queue(config))`, `max_attempts`, `unique: unique_opts()` when `job_opts` is `[]`):

```elixir
Enqueue.job_changeset(job_args(schema_module, chunk, fan_out_key, config), @worker, config, [])
```

`Enqueue.job_changeset/4` body [VERIFIED: Read lib/scrypath/oban/enqueue.ex:224-236]: `base = [worker: worker, queue: to_string(Config.oban_queue(config)), max_attempts: Config.oban_max_attempts(config)]`, then `if Keyword.get(job_opts, :unique, true), do: base ++ [unique: unique_opts()], else: base`, then `oban_job_module!().new(payload, opts)`.

With this prototype, the no-Oban build passed on 1.19.0 (test and prod env), the with-Oban `--warnings-as-errors` build passed, and `test/scrypath/sync/related_worker_test.exs`, `loader_test.exs`, `projection_test.exs`, `identity_test.exs` and `schema_test.exs` passed [VERIFIED: probe in a scratch copy].

### Anti-Patterns to Avoid
- **Silencing the type warning with `apply/3` or a dynamic module variable.** It dodges the checker without fixing the dead-end type and reads as suppression. Use Pattern 3.
- **Changing the stub to return `{:error, …}`.** That is a contract change for the custom-`oban:` module case. Pattern 3 keeps the raise.
- **Blanket suppression:** `elixirc_options: [warnings_as_errors: false]`, `Code.put_compiler_option(:ignore_…)` in lib, or dropping `--warnings-as-errors`. All are forbidden by HYG-02.
- **A separate `Scrypath.Schema.Hooks`/`Scrypath.Hooks` behaviour.** It splits the docs. Keep the contract where `use` lives.
- **Relying on `@impl` warnings alone for the arity check.** Adopters rarely write `@impl` on schema hooks, so the compiler stays silent (see Pitfall 1).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capturing compiler warnings in tests | stderr regex over `capture_io` | `Code.with_diagnostics/1` | Structured `%{severity: :warning, message: …}` that works on 1.15+ |
| Proving "callbacks appear in HexDocs" | Parsing built `doc/*.html` | `Code.fetch_docs(Scrypath.Schema)` callback entries plus `mix docs --warnings-as-errors` (already in `verify`) | ExDoc reads exactly this chunk, so it is fast and deterministic |
| Hiding Oban from the build | Renaming `_build/test/lib/oban` in place | A `MIX_BUILD_PATH` isolated dir | A crash mid-run would leave the real build broken |
| Runtime Oban detection in RelatedEnqueue | A new `if Code.ensure_loaded?` split | `Enqueue.job_changeset/4` / `oban_job_module!/0` | One guarded seam, already shared by the main path |

## Common Pitfalls

### Pitfall 1: The compiler does not flag wrong-arity optional callbacks without `@impl`
**What goes wrong:** `def search_records(ids)` under `@behaviour` with optional `search_records/2` compiles silently, and at runtime `function_exported?(_, :search_records, 2)` is false, so the default loader runs.
**Evidence:** Probe on 1.19.0 and 1.17.3. "wrong arity, no @impl" produced **no diagnostics**. "wrong arity, @impl true" produced `got "@impl true" for function search_records/1 but no behaviour specifies such callback`. A `defp search_document/1` produced `function search_document/1 required by behaviour Hooks was implemented as "defp" but should have been "def"` [VERIFIED: probe].
**How to avoid:** Use the `__before_compile__` check (Pattern 1).

### Pitfall 2: `--no-optional-deps` still loads an already-built optional dep (false green)
**What goes wrong:** Mix documents `--no-optional-deps` as "does not compile or load optional deps" [CITED: `mix help compile`, Elixir 1.19.0]. But when `_build/<env>/lib/oban` exists, Oban is on the code path during the compile.
**Evidence [VERIFIED: probe, Elixir 1.19.0/OTP 28.1]:**
- Build dir copied from `_build/test` with `lib/oban` present: `mix compile --force --no-optional-deps --warnings-as-errors` → `status=0`, and `Elixir.Scrypath.Oban.UpsertWorker.beam` was freshly written. That module is only defined `if Code.ensure_loaded?(Oban.Worker)`.
- Same dir with `lib/oban` removed → `status=1`:
  ```
  warning: incompatible types given to decorate_result/2:
  ...
  the 1st argument is empty (often represented as none()), most likely because it is the result of an expression that always fails, such as a `raise` ...
  └─ lib/scrypath/sync.ex:74:12: Scrypath.Sync.do_sync_related/6
  Compilation failed due to warnings while using the --warnings-as-errors option
  ```
- Code-path probe: with a prebuilt `lib/oban`, `deps.loadpaths --no-optional-deps` left `.../build_test/lib/oban/ebin` on `:code.get_path()` and `Code.ensure_loaded?(Oban.Worker) == true`. Without it, `[]` and `false`.
**Consequence:** The "no_optional_deps green" claims in the 179/180 summaries (e.g. `180-01-SUMMARY.md:68`) were produced against a `_build/test` containing Oban, so they did not test a no-Oban build.
**How to avoid:** Use an isolated `MIX_BUILD_PATH` plus the post-compile absence assertion (Pattern 2).

### Pitfall 3: The check is skipped in CI today
**What goes wrong:** `verify.no_optional_deps` only runs from `run_deep_quality_without_audit/0` (`lib/mix/tasks/verify/capability.ex:91` `task_runner.("verify.no_optional_deps", [])`). The `deep-quality (advisory)` job (`.github/workflows/ci.yml:147-165`) is `continue-on-error: true`, and its step `run: elixir scripts/ci/dependency_audit.exs` precedes `run: mix run --no-start -e 'Mix.Tasks.Verify.Capability.run_deep_quality_without_audit()'`.
**Evidence:** Latest `main` run 40284288955 (schedule, 2026-10-26): `deep-quality (advisory) failure`; step `Run elixir scripts/ci/dependency_audit.exs failure`; step `Run mix run --no-start -e 'Mix.Tasks.Verify.Capability.run_deep_quality_without_audit()' skipped` [VERIFIED: `gh run view 40284288955`].
**How to avoid:** Compose the check into `core (required)` (see "CI lane" below).

### Pitfall 4: The warning is version-specific
**What goes wrong:** The `sync.ex:74` warning appears on 1.19.0 but not on 1.17.3 or 1.18.4. Those no-Oban compiles exit 0 [VERIFIED: probe]. A check run only on an older Elixir would miss it.
**How to avoid:** Run the check on the 1.19.0/OTP 28.1 toolchain that the `core` job pins (`erlef/setup-beam … elixir-version: "1.19.0", otp-version: "28.1"`).

### Pitfall 5: The new `@behaviour` can surface `@impl` warnings in adopter modules
**What goes wrong:** If an adopter schema module uses `@impl true` for *any* function (for some other behaviour) and defines a hook without `@impl`, Elixir now warns: `module attribute @impl was not set for function search_records/2 callback (specified in Hooks)` [VERIFIED: probe].
**Scope check:** The prototype ran the whole root suite with `--warnings-as-errors` and produced no such compile warnings in test fixtures. `examples/` and `scrypath_ops` were not compiled under the prototype; the `ops-ui` and `ecommerce-mounted` lanes on the PR cover them.
**How to avoid:** Mention it in the `Scrypath.Schema` moduledoc ("If your schema uses `@impl`, mark hooks `@impl Scrypath.Schema`"). Treat it as additive and non-breaking.

### Pitfall 6: Bare `mix` does not run in this shell
**What goes wrong:** The repo has no `.tool-versions`, so asdf reports `No version is set for command mix`.
**How to avoid:** Prefix commands with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1`. Both are installed. This matches CI.

## CI lane (Question 5)

**Recommendation:** `core (required)`. Change `Mix.Tasks.Verify.Capability.run(:core, args)` (`capability.ex:5`: `def run(:core, args), do: run_task!("verify", args)`) so it runs `verify` with `args` and then `verify.no_optional_deps` with `[]`. This mirrors `backend!/1`, which runs `verify.meilisearch_smoke` then `verify.postgres` (`capability.ex:57-58`). It adds no new lane and no `ci.yml` edit; the core job already runs `mix verify.core --exclude integration --exclude docs_contract`. Keep the existing deep-quality call so `verify_capability_test.exs:72-85` and the documented `mix verify.deep_quality` contents stay valid.

- Make `run(:core, …)` testable the way deep quality is, with an injectable `task_runner`, and add a sequence test asserting `[{"verify", args}, {"verify.no_optional_deps", []}]`.
- Update the CONTRIBUTING table row "Core library | `mix verify.core` | Standard root maturity gate (`mix verify`)" to mention the no-optional-deps compile. Check `workflow_wiring_test.exs` (asserts `core_job =~ "mix verify.core"`) and `docs_contract_test.exs:1208-1211` (pins `run: mix verify.core --exclude integration --exclude docs_contract`). Neither needs changes if `ci.yml` is untouched.
- CI cost: with a cold isolated dir, the prod-env dep set compiled in about 5s locally. CI runners are slower, but this stays well under a minute. `_build` is in the core cache, but the cache only saves on a key miss, so expect a cold compile until `mix.exs`/`mix.lock` changes [ASSUMED: runner timing].

**Alternative considered:** `package (required)`. It fits the "what Hex consumers get" idea, but `verify.package` is pinned to the release-contract test list (`verify.phase11.ex:28-35`). Core is the natural sibling of its existing `compile --warnings-as-errors` step.

## HexDocs (Question 3)

- `mix.exs` `docs:` has `extras` and `groups_for_extras` only. There is **no `groups_for_modules`** [VERIFIED: Read mix.exs]. Every module whose `@moduledoc` is not `false` is listed. `Scrypath.Schema` is public, so its new callbacks render on its existing page. No `mix.exs` change is needed.
- No docs or package contract test enumerates modules (`grep` of `test/scrypath/docs_contract_test.exs` and `test/release/package_metadata_test.exs` for module lists found none). `test/scrypath/schema_test.exs` does not pin the moduledoc text either.
- Prototype docs chunk: `[{:search_document, 1, :none, …}, {:search_document_id, 1, :none, …}, {:search_records, 2, :none, …}]`. Add a `@doc` to each `@callback` so the docs are not `:none`, and assert that in the test.
- Guides that describe hooks (`guides/sync-modes-and-visibility.md`, `guides/related-data-and-reindexing.md`, `guides/multitenancy.md`, `README.md`, `ARCHITECTURE.md`, `lib/scrypath/loader.ex`, `lib/scrypath/projection.ex` moduledocs) can link `c:Scrypath.Schema.search_records/2`. ExDoc autolinks are then checked by `mix docs --warnings-as-errors`, which is step 6 of `verify`. Keep this optional and minimal.

## Blanket-suppression inventory (Question 4)

Every compiler-suppression site in `lib/` and `mix.exs` [VERIFIED: grep `no_warn_undefined|elixirc_options|compiler_options|ignore_module_conflict` over lib/ and mix.exs]:
- `lib/scrypath/oban.ex:16` `@compile {:no_warn_undefined, Oban}`
- `lib/scrypath/oban/inspect.ex:3` `@compile {:no_warn_undefined, [Oban.Job]}`
- `lib/scrypath/oban/enqueue.ex:3` `@compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Repo]}`
- `mix.exs`: no `elixirc_options`, no `xref` [VERIFIED: Read mix.exs]

These are **targeted**: per module, naming the specific optional modules. They are not blanket. `no_warn_undefined` cannot silence the `sync.ex` type warning anyway. A small source-contract test can pin this: `mix.exs` has no `elixirc_options`, no `Code.put_compiler_option` appears in `lib/`, and every `@compile {:no_warn_undefined, …}` in `lib/` names only `Oban*` modules.

## Code Examples

### Wrong-arity diagnostic test (verified behaviour)
```elixir
# Source: local probe (Elixir 1.17.3 + 1.19.0); pattern from test/scrypath/schema_test.exs Code.compile_string usage
test "flags a hook implemented with the wrong arity" do
  {_result, diagnostics} =
    Code.with_diagnostics(fn ->
      Code.compile_string("""
      defmodule Scrypath.SchemaHookArityFixture do
        use Scrypath, fields: [:title]
        def search_records(ids), do: ids
      end
      """)
    end)

  assert [%{severity: :warning, message: message}] = diagnostics
  assert message =~ "search_records/1"
  assert message =~ "search_records/2"
end

test "a correct hook compiles without diagnostics" do
  {_result, diagnostics} =
    Code.with_diagnostics(fn ->
      Code.compile_string("""
      defmodule Scrypath.SchemaHookOkFixture do
        use Scrypath, fields: [:title]
        def search_records(ids, _context), do: ids
      end
      """)
    end)

  assert diagnostics == []
end
```

### Contract and docs assertions
```elixir
assert Enum.sort(Scrypath.Schema.behaviour_info(:optional_callbacks)) ==
         [search_document: 1, search_document_id: 1, search_records: 2]
assert Scrypath.Schema in Keyword.get_values(SearchablePost.module_info(:attributes), :behaviour) |> List.flatten()

{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Scrypath.Schema)
for {name, arity} <- [search_document: 1, search_document_id: 1, search_records: 2] do
  assert {{:callback, ^name, ^arity}, _, _, %{"en" => doc}, _} =
           List.keyfind(docs, {:callback, name, arity}, 0)
  assert doc != ""
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Optional-dep stubs that always `raise` | Runtime-guarded single module (`oban_job_module!/0` style) | Elixir 1.19's type checker infers `none()` across modules | Always-raising stubs now produce warnings at their call sites [VERIFIED: 1.19.0 warns, 1.18.4 does not] |
| Duck-typed hooks via `function_exported?` only | `@optional_callbacks` behaviour plus compile check | — | Hooks show up in HexDocs, and `defp`/`@impl` mistakes get flagged |

**Forward-looking, outside the support range:** Elixir 1.20.4/OTP 29 adds further Scrypath warnings in a no-Oban build. They are redundant-clause warnings at `lib/scrypath/meilisearch/task_payload.ex:53`, `lib/scrypath/meilisearch/settings.ex:167` and `lib/scrypath/composition/merge.ex:163,166,169`, plus `warning: cannot infer signatures from :oban because it is not loaded` [VERIFIED: probe]. The support target is "through 1.19" and no CI lane runs 1.20, so this is out of scope. Record it as a follow-up.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `IO.warn`, not `raise`, is the right severity for the arity check | Pattern 1 | Low. Either satisfies "flags". `raise` would break adopters compiling without `--warnings-as-errors` |
| A2 | Compiling the check with `MIX_ENV=prod` is preferable to `Mix.env()` | Pattern 2 | Low. Both reproduce the red/green. Prod needs prod deps fetched, which default `mix deps.get` does |
| A3 | The cold isolated compile in CI stays under a minute | CI lane | Low. It only affects lane duration |
| A4 | `examples/` and `scrypath_ops` schemas don't combine `@impl` with hooks in one module | Pitfall 5 | Medium. A new `@impl` warning could fail their `--warnings-as-errors` lanes. Grep found hooks in `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/{product,variant,category}.ex` and `scrypath_ops/test/support/ops_schemas.ex`; the planner should add a quick per-module check |
| A5 | ExDoc labels optional callbacks distinctly | HexDocs | Cosmetic |

## Open Questions

1. **Should the arity check also cover `defp` hooks with the right name but the wrong kind?**
   - What we know: Elixir already warns for a `defp` at the callback arity once `@behaviour` is present (probe).
   - Recommendation: nothing extra is needed. Add one test asserting that diagnostic so the behaviour stays pinned.
2. **Should the deep-quality copy of the check be removed once core runs it?**
   - Recommendation: keep it. It is cheap, its sequence is pinned by `verify_capability_test.exs`, and it is documented in CONTRIBUTING.
3. **Should the 1.20 warnings be addressed?** Defer, and record them as a follow-up in STATE or the rolling roadmap.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir 1.19.0 / OTP 28.1 | Reproducing the CI warning | ✓ (asdf; needs env vars) | 1.19.0-otp-28 / 28.1 | — |
| Elixir 1.17.3 | Floor check of the compile-check APIs | ✓ | 1.17.3-otp-27 | — |
| `gh` CLI | Reading hosted CI evidence | ✓ | — | — |
| Oban source in `deps/` | With-Oban build | ✓ | per mix.lock | — |

**Missing dependencies with no fallback:** none. **Note:** bare `mix` fails here (no `.tool-versions`). Use the `ASDF_*` prefix from Pitfall 6.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0), `Code.with_diagnostics/1` |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath/schema_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_no_optional_deps_test.exs test/scrypath/sync/related_worker_test.exs` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract` (now includes the no-Oban build) + `mix verify.package` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | Failing direction (must be RED first) | File Exists? |
|--------|----------|-----------|-------------------|---------------------------------------|-------------|
| HYG-01 | The three hooks are `@optional_callbacks` on `Scrypath.Schema` | unit | `mix test test/scrypath/schema_test.exs` | On current source, `Scrypath.Schema.behaviour_info/1` is undefined → test fails | ✅ extend `schema_test.exs` |
| HYG-01 | Callbacks are documented in the docs chunk ExDoc reads | unit | same | `Code.fetch_docs` has no `{:callback, …}` entries today | ✅ extend |
| HYG-01 | `use Scrypath` modules carry `@behaviour Scrypath.Schema` | unit | same | `module_info(:attributes)[:behaviour]` lacks it today | ✅ extend |
| HYG-01 | Wrong-arity hook is flagged at compile time | unit | same (`Code.with_diagnostics`) | Today `search_records/1` produces `[]` diagnostics (probe) | ✅ extend |
| HYG-01 | Correct hooks compile with zero diagnostics (no false positives) | unit | same | Guards against an over-eager check | ✅ extend |
| HYG-01 | HexDocs build stays warning-free | docs | `mix docs --warnings-as-errors` (step 6 of `verify`) | Broken `c:` links fail it | ✅ existing |
| HYG-02 | No-Oban build compiles with `--warnings-as-errors` | build | `mix verify.no_optional_deps` | **With the fixed task and current source, it fails at `lib/scrypath/sync.ex:74:12`** (probe). Fix the task first, then the code | ✅ task exists; fix |
| HYG-02 | The task proves Oban was absent (no false green) | unit | `mix test test/mix/tasks/verify_no_optional_deps_test.exs` | Seam test: a fake build dir containing `lib/oban` → `Mix.Error` | ❌ Wave 0 |
| HYG-02 | `verify.core` runs the no-Oban build | unit | `mix test test/mix/tasks/verify_capability_test.exs` | Sequence assertion fails until `run(:core, …)` composes it | ✅ extend |
| HYG-02 | No blanket suppression | contract | `mix test test/mix/tasks/workflow_wiring_test.exs` (or a new small contract test) | Adding `elixirc_options`/`put_compiler_option` to lib/mix.exs fails it | ✅ extend / ❌ |
| HYG-02 | Related Oban enqueue behaviour is unchanged | unit | `mix test test/scrypath/sync/related_worker_test.exs test/scrypath/sync_test.exs test/scrypath/oban_test.exs` | Existing job-shape and unique assertions | ✅ existing |
| HYG-02 | Runs on the phase PR in a required lane | hosted | `core (required)` job log shows "Compiling Scrypath without optional dependencies" | Exact-SHA PR run | n/a |

### Sampling Rate
- **Per task commit:** the quick run command plus `mix verify.no_optional_deps`
- **Per wave merge:** `mix compile --warnings-as-errors --force`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`
- **Phase gate:** `mix verify.core --exclude integration --exclude docs_contract` + `mix verify.package`, then green `core (required)` on the PR's exact SHA

### Wave 0 Gaps
- [ ] `test/mix/tasks/verify_no_optional_deps_test.exs`: seam tests for build-path isolation, env (`MIX_BUILD_PATH`, `MIX_ENV`) and the optional-dep absence guard. Extract a pure function so no subprocess compile is needed in the unit test.
- [ ] Injectable runner for `Capability.run(:core, …)`, so the sequence is testable without running the real gate.

**Suggested task order (TDD):** (1) Fix `verify.no_optional_deps` isolation and the absence guard; run it and observe RED on `sync.ex:74`. (2) Refactor `RelatedEnqueue` onto `Enqueue.job_changeset/4` → GREEN. (3) Compose into `verify.core` and add the sequence test. (4) Add the hook-contract tests (RED), then the callbacks, `@behaviour` and `__before_compile__` (GREEN), then moduledoc and guide links. (5) Update `PROJECT.md` bullets and CONTRIBUTING.

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so it is treated as enabled. This phase is compile-time and build hygiene with no new input surface.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no (no new runtime input; job args unchanged) | Existing `Scrypath.Oban.JobArgs` safe decoding is untouched |
| V6 Cryptography | no | — |
| V14 Configuration / build integrity | yes | Warnings-as-errors build without optional deps. No blanket suppression, pinned by a contract test |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A false-green build gate hides a broken adopter build | Repudiation / Tampering of evidence | Post-compile absence assertion in `verify.no_optional_deps` |
| A refactor changes the related-job unique policy | Tampering (duplicate work) | Reuse `Enqueue.job_changeset/4`; existing `related_worker_test` unique assertions |

## Sources

### Primary (HIGH confidence)
- Local probes on Elixir 1.19.0/OTP 28.1 and 1.17.3/OTP 27, recorded in the scratch logs: behaviour/`@impl` diagnostics, the `__before_compile__` warning failing `mix compile --warnings-as-errors`, no-Oban compile red/green in test and prod envs, the code-path probe, and the docs-chunk callback probe
- Repo files read this session: `lib/scrypath/schema.ex`, `lib/scrypath.ex`, `lib/scrypath/identity.ex`, `lib/scrypath/projection.ex`, `lib/scrypath/loader.ex`, `lib/scrypath/sync.ex`, `lib/scrypath/sync/related_enqueue.ex`, `lib/scrypath/oban/enqueue.ex`, `lib/scrypath/config.ex`, `lib/mix/tasks/verify.no_optional_deps.ex`, `lib/mix/tasks/verify/capability.ex`, `lib/mix/tasks/verify.ex`, `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `test/mix/tasks/verify_capability_test.exs`, `test/scrypath/schema_test.exs`, `test/scrypath/oban_test.exs:150-190`
- `gh run view 40284288955` (latest `main` CI, deep-quality steps)
- Mix built-in docs on 1.19.0: `mix help compile` (`--no-optional-deps`) and `Code.fetch_docs(Mix)` (`MIX_BUILD_PATH`)

### Secondary (MEDIUM confidence)
- `.planning/PROJECT.md:40-42`, `.planning/reference/ROLLING-ROADMAP.md:43-45` (scope intent), and the 179/180 SUMMARY claims of a green `verify.no_optional_deps`, which the probes contradict

## Metadata

**Confidence breakdown:**
- Hook inventory and contract design: HIGH. Source read and prototype compiled.
- No-Oban warning and false-green mechanism: HIGH. Reproduced red/green, with code-path evidence.
- CI lane placement: HIGH for the facts and MEDIUM for the timing estimate.
- Pitfall 5 adopter impact: MEDIUM. Not compiled against `examples/` or `scrypath_ops` under the prototype.

**Note on the prototype's full-suite run:** in the scratch copy (no `.git`, alternate build path), about 41 tests failed both with and without the prototype, in different seed-dependent sets. Causes included git-dependent tests, `missing plug dependency` and purged modules. These are environment artifacts, and the prototype introduced no compile warnings. Re-run the real suite in the real checkout.

**Research date:** 2026-10-26
**Valid until:** 2026-11-25 (stable Elixir/Mix behaviour; re-probe if the CI Elixir pin changes)
