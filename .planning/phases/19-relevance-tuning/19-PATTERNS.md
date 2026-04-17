# Phase 19: Relevance Tuning - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 17 (6 modified library, 2 new mix tasks, 1 new guide, 1 modified CHANGELOG, 1 modified mix.exs, 4 extended test files, 2 new test files)
**Analogs found:** 17 / 17 (every new/modified file has a clear in-repo analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scrypath/options.ex` (mod) | schema-macro / NimbleOptions validator | validation/transform | self — extend `validate_settings/1` in place | exact (self-extension) |
| `lib/scrypath/meilisearch/settings.ex` (mod) | Scrypath→Meilisearch seam / declarative transform | transform + verify-request-response | self — extend `resolve/2` + `apply/3` | exact (self-extension) |
| `lib/scrypath/meilisearch/client.ex` (mod — `get_settings/2`) | Meilisearch wire adapter | request-response (GET) | `update_settings/3` in same file (client.ex L20-29) | exact (same role, same data flow, differs only in HTTP verb) |
| `lib/scrypath/reindex.ex` (mod) | runtime orchestrator (with-chain) | batch + request-response | self — extend existing `with` chain at L20-35 | exact (self-extension) |
| `lib/scrypath/config.ex` (mod — `resolve!/1` cascade) | config cascade utility | transform | self — extend the existing `Keyword.merge/2` chain at L13-17 | exact (self-extension) |
| `mix.exs` (mod — `cli.preferred_envs`) | project config | data-list extension | self — lines 38-48 | exact (self-extension) |
| `CHANGELOG.md` (mod) | release docs | append | prior Unreleased entries | exact |
| `lib/mix/tasks/scrypath.settings.diff.ex` NEW | mix task (verify/diff) | request-response with exit-code discipline | `lib/mix/tasks/verify.release_parity.ex` (drift/parity/error exit codes) + `scrypath.status.ex` (Scrypath namespace conventions + `--repo`/`--index-prefix` handling) | strong (hybrid: exit-codes from verify.*, naming+flags from scrypath.*) |
| `lib/mix/tasks/scrypath.settings.read.ex` NEW | mix task (read + pretty-print) | request-response | `lib/mix/tasks/scrypath.status.ex` (read-and-render thin delegate) | exact (same role, same data flow) |
| `guides/relevance-tuning.md` NEW | docs | n/a | `guides/operator-mix-tasks.md` (sibling ops guide) | exact |
| `test/scrypath/options_test.exs` (ext) | ExUnit unit test | validator-shape assertions | self — `describe "validate_backfill_options!/1"` at L85+, `"validate_reindex_options!/1"` at L116+ | exact (self-extension) |
| `test/scrypath/meilisearch/settings_test.exs` NEW | ExUnit unit test | transform + verify | `test/scrypath/meilisearch/tasks_test.exs` (same subdirectory, same test style: mock-client Agent pattern) | strong |
| `test/scrypath/meilisearch/client_test.exs` NEW | ExUnit unit test for wire adapter | request-response mock | `test/scrypath/meilisearch_test.exs` (RecordingClient pattern L18-52) | strong |
| `test/scrypath/reindex_test.exs` (ext) | ExUnit unit test | with-chain ordering assertions | self — existing test at L260-289 already asserts ordering with `assert_receive {:apply_settings, ...}` | exact (self-extension) |
| `test/mix/tasks/scrypath_settings_diff_test.exs` NEW | ExUnit mix-task test | exit-code + IO capture | `test/mix/tasks/verify_release_parity_test.exs` (pure `compute/2` + `render_json/4` tests + `retry_until!/4` agent stubs) | exact (same role, same data flow) |
| `test/mix/tasks/scrypath_settings_read_test.exs` NEW | ExUnit mix-task test | IO capture | `test/scrypath/mix_tasks/operator_tasks_test.exs` (CaptureIO + client-mock Application env pattern) | exact |

---

## Pattern Assignments

### 1. `lib/scrypath/options.ex` (schema-macro extension)

**Analog:** self (extend in place). Current `validate_settings/1` at L327-343 is the seam.

**Current contract (keep):**

```elixir
# lib/scrypath/options.ex:327-343
def validate_settings(value) when is_map(value), do: {:ok, value}

def validate_settings(value) do
  cond do
    Macro.quoted_literal?(value) ->
      {evaluated, _binding} = Code.eval_quoted(value)

      if is_map(evaluated) do
        {:ok, evaluated}
      else
        {:error, "expected settings to be a plain map"}
      end

    true ->
      {:error, "expected settings to be a plain map"}
  end
end
```

**NimbleOptions nested schema idiom** (copy shape from the existing `@schema_options`/`@runtime_options` schemas L4-113):

```elixir
# Existing shape to mirror for the new :settings_merge entry
sync_mode: [
  type: {:in, [:inline, :manual, :oban]},
  default: :inline,
  doc: "Synchronization mode to use for write operations."
],
```

`settings_merge` addition (D-07, planner lands in 19-01):

```elixir
settings_merge: [
  type: {:in, [:replace, :deep]},
  default: :replace,
  doc: "Merge strategy for runtime settings overrides against schema-declared settings."
]
```

**Routing `validate_settings/1` through `normalize_settings/1` + `validate_recognized_subkeys/1`:** keep existing `is_map(value)` clause head, append normalize + validate-subkeys steps; preserve the `Macro.quoted_literal?/1` fallback clause for compile-time macro callers. Return shape stays `{:ok, map()} | {:error, String.t()}` so NimbleOptions surfaces validation errors unchanged.

**Divergences from the analog (self):** must not break any v1.2 caller that passes `%{searchableAttributes: ["title"]}` (atom-camelCase). Normalize-on-entry (D-16) is the compatibility mechanism; existing `validate_reindex_options!/1` test at `test/scrypath/options_test.exs:125` (`settings: %{sortableAttributes: ["inserted_at"]}`) must still pass unchanged.

**Remove inert `:settings` from `@backfill_options` (D-08):** delete lines 164-168 (the `settings:` entry in `@backfill_options`). CHANGELOG phrases as removal of inert plumbing, not behavior change.

---

### 2. `lib/scrypath/meilisearch/settings.ex` (Scrypath↔Meilisearch seam)

**Analog:** self. Current module is 32 LOC; grows to ~6x that.

**Current `resolve/2` (baseline to preserve for `:replace` mode, D-09):**

```elixir
# lib/scrypath/meilisearch/settings.ex:7-12
@spec resolve(module(), keyword()) :: map()
def resolve(schema_module, config) do
  schema_module
  |> Scrypath.schema_settings()
  |> Map.merge(Keyword.get(config, :settings, %{}))
end
```

**Current `apply/3` (baseline to wrap with `translate_settings/1`):**

```elixir
# lib/scrypath/meilisearch/settings.ex:14-27
@spec apply(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
def apply(schema_module, index_name, config) do
  settings = resolve(schema_module, config)

  with {:ok, response} <- client(config).update_settings(index_name, settings, config),
       {:ok, task} <- Meilisearch.normalize_task(response) do
    {:ok,
     %{
       index: index_name,
       settings: settings,
       task: task
     }}
  end
end

defp client(config) do
  Keyword.get(config, :meilisearch_client) || Client
end
```

**Extensions (19-02, 19-03 land here):**

1. `resolve/2` — normalize BOTH sides before merge (D-17), honor `:settings_merge` mode:
   - `:replace` branch calls existing `Map.merge/2` (semantically identical to today — regression test asserts this).
   - `:deep` branch calls `deep_merge/2` (hand-rolled, ~12 LOC, maps-only, D-12).
2. `apply/3` — call `translate_settings/1` on the resolved map before passing to `Client.update_settings/3`. Keep the `with` chain and return shape.
3. New functions (19-01, 19-02, 19-03):
   - `normalize_settings/1` (accepts 3 input shapes, produces canonical `%{atom_snake_key => val, :__unrecognized__ => %{raw => raw}}`).
   - `canonicalize_key/1` (`Macro.underscore/1` + `String.to_existing_atom/1` guard against allowlist; fall through to `:__unrecognized__` bucket).
   - `expand_synonyms/1` (list-of-groups sugar + `one_way:` nested key → Meilisearch map form).
   - `translate_settings/1` (canonical atom-snake → Meilisearch camelCase string keys; passes `:__unrecognized__` bucket through last; calls `strip_scrypath_meta_keys/1` to drop any `*_strict?` / allowlisted Scrypath meta keys before sending to Meilisearch, D-04).
   - `verify_applied/3` (GET via `client.get_settings/2`, key-by-key drift detection; returns `:ok | {:error, {:settings_drift, [{key, declared, actual}, ...]}}`; surface `{:error, :index_not_found}` distinctly, RELEVANCE.md §4 Phase 19 constraint).
   - `hot_apply/3` stub (returns `{:error, :hot_apply_disabled}`, D-23 plan 19-01, RELEVANCE.md §5).
   - `deep_merge/2` private helper (maps-only; all non-map values terminal).
   - `strip_scrypath_meta_keys/1` private helper (drops `*_strict?`-suffixed keys + explicit allowlist).

**`Macro.camelize/Macro.underscore` idiom** — already used for filter keys in `client.ex`:

```elixir
# lib/scrypath/meilisearch/client.ex:158-163
defp camelize_filter(key) do
  key
  |> to_string()
  |> Macro.camelize()
  |> then(&String.replace_prefix(&1, String.first(&1), String.downcase(String.first(&1))))
end
```

`translate_settings/1` mirrors this shape (first-letter-lowercase camelCase) to stay idiomatically consistent with the existing wire boundary.

**Client-override indirection** (copy from current `settings.ex:29-31`):

```elixir
defp client(config) do
  Keyword.get(config, :meilisearch_client) || Client
end
```

Reuse in `verify_applied/3` so tests can inject a mock client.

---

### 3. `lib/scrypath/meilisearch/client.ex` — `get_settings/2` (wire adapter)

**Analog:** `update_settings/3` in the same file (L20-29). `get_settings/2` is the GET counterpart to this PATCH.

**Exact shape to mirror:**

```elixir
# lib/scrypath/meilisearch/client.ex:20-29
@spec update_settings(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
def update_settings(index_name, settings, config) when is_map(settings) do
  run_request(
    :patch,
    "/indexes/#{index_name}/settings",
    [json: settings],
    config,
    index: index_name
  )
end
```

**New function (19-03):**

```elixir
@spec get_settings(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
def get_settings(index_name, config) do
  run_request(
    :get,
    "/indexes/#{index_name}/settings",
    [],
    config,
    index: index_name
  )
end
```

**Divergences from analog:** no body (`[]` not `[json: ...]`); method is `:get` not `:patch`; no `when is_map(...)` guard. Same metadata shape (`index: index_name`), same `run_request/5` path, same response-normalization (inherits `normalize_response/1` at L116-127 which already maps 4xx to `{:error, {:http_error, status, body}}` — `verify_applied/3` translates `{:http_error, 404, _}` to `{:error, :index_not_found}` before returning).

**Telemetry envelope already handled** — `run_request/5` at L91-104 wraps every call in `Telemetry.span([:scrypath, :meilisearch, :request], ...)`, so `get_settings/2` gets telemetry for free.

---

### 4. `lib/scrypath/reindex.ex` — insert verify step + ranking-rules guard + telemetry

**Analog:** self. Extend the `with` chain at L20-35.

**Current `with` chain (exact seam, copy verbatim when inserting the new clause):**

```elixir
# lib/scrypath/reindex.ex:20-35
with {:ok, create_result} <-
       meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config),
     {:ok, _create_result} <- maybe_wait_for_result_task(create_result, workflow_config),
     {:ok, settings_result} <-
       meilisearch.apply_settings(schema_module, target_index, workflow_config),
     {:ok, _settings_result} <- maybe_wait_for_result_task(settings_result, workflow_config),
     # <-- INSERT VERIFY STEP HERE (between L25 and L27, after settings-wait, before backfill)
     {:ok, backfill_result} <-
       backfill.run(
         schema_module,
         workflow_config
         |> backfill_config()
         |> Keyword.put(:index_name, target_index)
       ),
     ...
```

**New clause to insert (between L25 and L27):**

```elixir
     :ok <- maybe_verify_settings(schema_module, target_index, workflow_config),
```

With private helper:

```elixir
defp maybe_verify_settings(schema_module, target_index, config) do
  if Keyword.get(config, :skip_settings_verification?, false) do
    Logger.warning("skip_settings_verification? set; skipping post-apply drift check")
    :telemetry.execute([:scrypath, :reindex, :verify_skipped], %{}, %{
      schema: schema_module,
      target_index: target_index
    })
    :ok
  else
    # emit settings_verified telemetry via Telemetry.span envelope
    Telemetry.span([:scrypath, :reindex, :settings_verified], %{
      schema: schema_module, target_index: target_index
    }, fn ->
      {Scrypath.Meilisearch.Settings.verify_applied(schema_module, target_index, config), %{}}
    end)
  end
end
```

**Telemetry envelope to mirror** (already in reindex module via `Scrypath.Telemetry.span/3`):

```elixir
# lib/scrypath/telemetry.ex:10-15
def span(event_name, metadata, fun) when is_list(event_name) and is_map(metadata) do
  :telemetry.span(event_name, metadata, fn ->
    {result, stop_metadata} = fun.()
    {result, Map.merge(metadata, stop_metadata)}
  end)
end
```

**Ranking-rules reindex-time guard (D-23 plan 19-04, TUNE-04):** insert a guard before the `with` chain (circa L19) that raises `ArgumentError` if declared settings contain `ranking_rules` missing any of the six defaults AND `ranking_rules_strict?` is not `false`. Compile-time warning counterpart lives in `validate_settings/1` (19-01 plan).

**Read `skip_settings_verification?` from `workflow_config`** — `workflow_config` is `Keyword.put(config, :target_index, target_index)` at L18; the runtime opt is read via `Keyword.get(workflow_config, :skip_settings_verification?, false)` — same access idiom as every other opt in this file.

---

### 5. `lib/scrypath/config.ex` — per-repo cascade source (D-10)

**Analog:** self. Current `resolve!/1` at L13-17 is a three-line `Keyword.merge/2` chain.

**Current shape to extend:**

```elixir
# lib/scrypath/config.ex:12-17
@doc "Resolve runtime options by merging explicit opts over application defaults."
@spec resolve!(keyword()) :: keyword()
def resolve!(opts) when is_list(opts) do
  Application.get_env(:scrypath, :defaults, [])
  |> Keyword.merge(opts)
  |> Options.validate_runtime_options!()
end
```

**Extension shape (19-04):**

```elixir
def resolve!(opts) when is_list(opts) do
  Application.get_env(:scrypath, :defaults, [])
  |> Keyword.merge(per_repo_config(opts))
  |> Keyword.merge(opts)
  |> Options.validate_runtime_options!()
end

# per_repo_config/1 reads Application.get_env(otp_app, repo_module, [])[:scrypath]
# when opts contains :repo. Right-biased: per-call (opts) wins over per-repo
# wins over library-global (:scrypath, :defaults). (D-10, D-11)
defp per_repo_config(opts) do
  # ... look up {otp_app, repo_module} from opts[:repo], return [] if absent
end
```

**Divergences from the analog (self):** current chain is two sources; extended chain is three. Precedence documented explicitly in `guides/relevance-tuning.md` (D-11). `settings_merge` at per-call wins over per-repo wins over library-global.

---

### 6. `mix.exs` — `cli.preferred_envs` extension

**Analog:** self. Lines 38-48.

**Current shape:**

```elixir
# mix.exs:36-52
def cli do
  [
    preferred_envs: [
      "verify.phase5": :test,
      "verify.phase8": :test,
      ...
      "verify.release_parity": :test,
      credo: :test,
      dialyzer: :test
    ]
  ]
end
```

**Two new entries (19-07):**

```elixir
"scrypath.settings.diff": :test,
"scrypath.settings.read": :test,
```

(Both in `:test` to match Phase 18's convention since the new mix-task tests live under `test/mix/tasks/`.)

---

### 7. `lib/mix/tasks/scrypath.settings.diff.ex` NEW (thin delegate with exit-code discipline)

**Primary analog:** `lib/mix/tasks/verify.release_parity.ex` — provides the exit-code discipline (0/2/1), `--json` flag, and `System.halt(2)` on drift pattern.
**Secondary analog:** `lib/mix/tasks/scrypath.status.ex` + `Scrypath.CLI.OperatorTask` — provides the `Mix.Tasks.Scrypath.*` naming, `--repo`, `--index-prefix` flag handling, and thin-delegate shape.

**Exit-code discipline to copy** (from `verify.release_parity.ex`):

```elixir
# lib/mix/tasks/verify.release_parity.ex:13-17 (documented in moduledoc)
## Exit codes
  * `0` — parity (no drift)
  * `2` — drift detected (POSIX "intentional failure")
  * `1` — runtime error (network failure, missing tag, tarball fetch failure)
```

**Halt-on-drift pattern** (copy from `verify.release_parity.ex:248-260`):

```elixir
defp emit_drift_and_halt!(version, only_in_git, only_in_hex, opts) do
  output =
    if opts[:json] do
      render_json(version, :drift, only_in_git, only_in_hex)
    else
      human_diff(version, only_in_git, only_in_hex)
    end

  Mix.shell().info(output)

  # D-10: exit 2 distinguishes drift from runtime errors.
  System.halt(2)
end
```

**Imports + use + moduledoc shape** (copy from `verify.release_parity.ex:1-50`):

```elixir
defmodule Mix.Tasks.Scrypath.Settings.Diff do
  @moduledoc """
  Diffs declared-vs-applied Meilisearch settings for one Scrypath schema.

  ## Usage

      mix scrypath.settings.diff MyApp.Blog.Post
      mix scrypath.settings.diff MyApp.Blog.Post --json
      mix scrypath.settings.diff MyApp.Blog.Post --repo MyApp.Repo --index-prefix tenant

  ## Exit codes

    * `0` — no drift
    * `2` — drift detected
    * `1` — runtime error (index not found, network failure)
  """

  @shortdoc "Diffs declared-vs-applied Meilisearch settings for one Scrypath schema"

  use Mix.Task
  # ...
end
```

**OptionParser + argv shape** (copy from `scrypath.status.ex` via `OperatorTask.parse!/2`):

```elixir
# lib/mix/tasks/scrypath.status.ex:13-17
def run(args) do
  Mix.Task.run("app.start")

  {opts, argv} = OperatorTask.parse!(args)
  schema = OperatorTask.schema_from_argv!(argv)
  ...
end
```

Reuse `Scrypath.CLI.OperatorTask.parse!/2` (passes `--repo`, `--index-prefix`, etc. through its shared switches) and extend with a `[json: :boolean]` switch local to this task.

**Thin-delegate body** — call `Scrypath.Meilisearch.Settings.verify_applied/3`, branch on return:
- `:ok` → print parity table (or JSON), exit 0.
- `{:error, {:settings_drift, drift}}` → format three-column table (or JSON shaped per RELEVANCE.md §M-1 7a), `System.halt(2)`.
- `{:error, :index_not_found}` → `OperatorTask.error!("scrypath.settings.diff", :index_not_found)` (which calls `Mix.raise/1`, exits 1).

**Splittable pure functions for testability** — follow `verify.release_parity.ex`'s `compute/2` + `render_json/4` split (L86-118). Keep the drift-comparison computation pure and public so `test/mix/tasks/scrypath_settings_diff_test.exs` can assert on it without mocking the full Mix task.

**Divergences from the primary analog (`verify.release_parity.ex`):**
- No version-regex parsing (no user-supplied semver string).
- Uses `Scrypath.CLI.OperatorTask.parse!/2` for switches instead of hand-rolling `OptionParser.parse/2`.
- No `retry_until!/4` CDN retry loop (not a release-parity task; the live Meilisearch call has no CDN-propagation concern).

**Divergences from the secondary analog (`scrypath.status.ex`):** adds a `--json` switch and `System.halt(2)` on drift (neither present in the status task).

---

### 8. `lib/mix/tasks/scrypath.settings.read.ex` NEW (thin delegate, pretty-print)

**Analog:** `lib/mix/tasks/scrypath.status.ex` (thin read-and-render delegate).

**Full shape to mirror** (copy structure from `scrypath.status.ex` verbatim, swap the core call):

```elixir
# lib/mix/tasks/scrypath.status.ex (full file, 24 LOC):
defmodule Mix.Tasks.Scrypath.Status do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask

  @shortdoc "Prints sync visibility for one Scrypath schema"

  @moduledoc """
  Shows pending, failed, and last-successful sync visibility for one searchable schema.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args)
    schema = OperatorTask.schema_from_argv!(argv)

    case Scrypath.sync_status(schema, OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()) do
      {:ok, status} -> Mix.shell().info(OperatorTask.render_status(status))
      {:error, reason} -> OperatorTask.error!("scrypath.status", reason)
    end
  end
end
```

**New task body (19-06):** same shape, but:
- Call `Scrypath.Meilisearch.Client.get_settings(backend.index_name(schema, config), config)` instead of `Scrypath.sync_status/2`.
- Resolve `config` via `Scrypath.Config.resolve!(OperatorTask.runtime_opts(opts))` (gets the new per-repo cascade source for free via 19-04).
- Pretty-print the returned settings map via `Kernel.inspect/2` with `pretty: true, limit: :infinity` (no table; this task is debuggability-as-dump per RELEVANCE.md §M-4).
- Exit code 0 on success, 1 on error (default `Mix.raise/1` behavior via `OperatorTask.error!/2`).

**Divergences from analog:** no specialized renderer (unlike `render_status/1`); plain `IO.inspect` / `inspect` via `Mix.shell().info/1`. No drift semantics — this task does not exit 2.

---

### 9. `guides/relevance-tuning.md` NEW (docs)

**Analog:** `guides/operator-mix-tasks.md` (sibling ops guide) — check section structure + tone + cross-link idioms.

**Content outline (D-23 plan 19-07):**
- The 5 settings (synonyms, typo_tolerance, ranking_rules, distinct_attribute, stop_words) — declaration shape, translation to Meilisearch, example per setting.
- Ranking-rules safety rail (TUNE-04; compile-time warning, reindex-time error, `ranking_rules_strict?: false` opt-out; D-02 placement rationale).
- Verify / drift (TUNE-05; `mix scrypath.settings.diff` usage, exit codes, what drift means, `skip_settings_verification?` opt-out, D-03 placement rationale).
- Mix tasks (`scrypath.settings.diff`, `scrypath.settings.read`).
- `:settings_merge` example with three-source cascade diagram (library-global → per-repo → per-call; D-10 / D-11).
- Hot-apply v1.4 deferral note (RELEVANCE.md §5; single sentence pointing at `{:error, :hot_apply_disabled}`).
- Three-shape input note (D-19 informational hint; both atom-camelCase and atom-snake-case supported permanently).

**Must add to `mix.exs docs.extras`** (line 74-86) for ExDoc to pick up — matches how every other guide is registered.

---

### 10. `CHANGELOG.md` (modified)

**Analog:** existing Unreleased section (check head of file for current conventions).

**Unreleased entry (D-23 plan 19-07)** names all 8 TUNE-IDs:
- TUNE-01..08 added.
- `{:error, :hot_apply_disabled}` deliberate-deferral bullet (D-23 plan 19-01, RELEVANCE.md §5).
- `:settings` opt removal from `@backfill_options` (D-08; phrase as "removal of inert plumbing, not behavior change").
- Posture D three-shape normalize-on-entry (D-15..21; phrase as "no breaking changes — atom-camelCase and atom-snake-case both work").
- Per-repo cascade source added to `Scrypath.Config.resolve!/1` (D-10).

Closing commit `feat(19): add declarative relevance tuning ...` triggers release-please cut (D-24).

---

### 11. `test/scrypath/options_test.exs` (extended)

**Analog:** self. Existing `describe` blocks at L85+ (`validate_backfill_options!/1`), L116+ (`validate_reindex_options!/1`) already test the shape this phase extends.

**Existing assertion style to mirror** (L125-139):

```elixir
settings: %{sortableAttributes: ["inserted_at"]},
...
assert config[:settings] == %{sortableAttributes: ["inserted_at"]}
```

**Extensions (19-01, 19-02 tests):**
- Nested settings validation (TUNE-01): `settings: %{typo_tolerance: %{enabled: true, min_word_size_for_typos: %{one_typo: 5, two_typos: 9}}}` passes; `one_typo: -1` raises `ArgumentError`.
- `normalize_settings` 3-shape tests (D-15..16): atom-camelCase, string-camelCase, atom-snake-case inputs all produce the same canonical form.
- `canonicalize_key` allowlist tests (D-16): `:searchableAttributes` canonicalizes to `:searchable_attributes`; unknown camelCase falls through to `:__unrecognized__`.
- `:settings_merge` value validation (D-07): `:replace` accepted; `:deep` accepted; `:fooey` rejected with NimbleOptions auto-generated error message `"expected :settings_merge to be one of [:replace, :deep], got: :fooey"`.
- Ranking-rules compile-time warning emission (D-23 plan 19-01): use `ExUnit.CaptureIO.capture_io(:stderr, fn -> ... end)` to assert the warning surfaces.
- Backward-compat regression: existing fixture `settings: %{searchableAttributes: ["title"]}` (L96) still validates unchanged.

---

### 12. `test/scrypath/meilisearch/settings_test.exs` NEW

**Analog:** `test/scrypath/meilisearch/tasks_test.exs` (same subdirectory, same mock-client Agent pattern).

**Test module shape to mirror:**

```elixir
# test/scrypath/meilisearch/tasks_test.exs:1-27
defmodule Scrypath.Meilisearch.TasksTest do
  use ExUnit.Case, async: true

  alias Scrypath.Operations.Task, as: OperationTask
  alias Scrypath.Meilisearch.Tasks

  defmodule SequencedClient do
    def task(task_uid, config) do
      agent = Keyword.fetch!(config, :task_responses)
      send(self(), {:client_task, task_uid, config})
      # ...
    end
    # ...
  end

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    %{task_responses: agent}
  end
  # ...
end
```

**Extensions (19-02, 19-03 tests):**
- `expand_synonyms/1` property + edge tests (TUNE-02): empty list, single-term group, duplicate across groups, `one_way:` nested key.
- `translate_settings/1` tests (D-04, D-17): snake → camel conversion, `:__unrecognized__` passthrough, `*_strict?` meta-key stripping.
- `verify_applied/3` tests (TUNE-05): happy path (parity → `:ok`), drift (→ `{:error, {:settings_drift, [{key, d, a}]}}`), index-not-found (→ `{:error, :index_not_found}`). Inject mock client via `meilisearch_client:` config key, same pattern as `SequencedClient` above.
- `hot_apply/3` stub test: any args → `{:error, :hot_apply_disabled}`.
- `:settings_merge` `:replace` vs `:deep` tests (D-09, D-12): verify D-09 regression (default `:replace` identical to v1.2 `Map.merge/2`); verify deep-merge preserves `min_word_size_for_typos` when flipping `enabled: false`.
- Doubled-key impossibility regression (D-17): normalize-both-sides ensures `%{searchableAttributes: [...]}` + `%{searchable_attributes: [...]}` collapse to one canonical key pre-merge.

---

### 13. `test/scrypath/meilisearch/client_test.exs` NEW

**Analog:** `test/scrypath/meilisearch_test.exs` (RecordingClient pattern at L18-52) — the in-repo convention for mocking HTTP responses and asserting request shape.

**Shape to mirror:**

```elixir
# test/scrypath/meilisearch_test.exs:18-52
defmodule RecordingClient do
  def update_settings(index_name, settings, config) do
    send(self(), {:client_update_settings, index_name, settings, config})

    {:ok,
     %{
       "taskUid" => 20,
       "indexUid" => index_name,
       "status" => "enqueued",
       "type" => "settingsUpdate"
     }}
  end
  # ...
end
```

**Extensions (19-03 tests):**
- `get_settings/2` happy path: returns `{:ok, %{...}}` on 200; metadata includes `index: index_name`.
- `get_settings/2` index-not-found: returns `{:error, {:http_error, 404, _body}}` on 404 (translation to `:index_not_found` happens one layer up in `verify_applied/3`; this test asserts the raw wire shape).

**Divergences from analog:** tests wire adapter's raw behavior, not the high-level `Scrypath.Meilisearch.*` API. Use `Plug.Test` or a `Req` test adapter to inject HTTP responses if needed; else use the same `meilisearch_client:` injection idiom seen in `meilisearch_test.exs`.

---

### 14. `test/scrypath/reindex_test.exs` (extended)

**Analog:** self. Existing test at L256-289 already exercises the `with` chain ordering via `assert_receive {:apply_settings, ...}`, `assert_receive {:backfill, ...}`, `assert_receive {:swap_indexes, ...}`.

**Exact existing pattern to extend** (L272-288):

```elixir
assert_receive {:create_index, QueryablePost, :id, create_config}
assert create_config[:target_index] == "posts_rebuild_v2"

assert_receive {:apply_settings, QueryablePost, "posts_rebuild_v2", settings_config}
assert settings_config[:target_index] == "posts_rebuild_v2"

assert_receive {:backfill, QueryablePost, backfill_config}
assert backfill_config[:index_name] == "posts_rebuild_v2"

assert_receive {:swap_indexes, QueryablePost, swap_config}
```

**Extensions (19-04 tests):**
- Ordering assertion with verify step (TUNE-03): create → apply → **verify** → backfill → cutover. Add `assert_receive {:verify_applied, QueryablePost, "posts_rebuild_v2", verify_config}` between the existing `{:apply_settings, ...}` and `{:backfill, ...}` assertions.
- Verify-drift blocks cutover (TUNE-05): set mock client to return stale settings → assert reindex returns `{:error, {:settings_drift, [...]}}` AND no `{:swap_indexes, ...}` message received.
- Ranking-rules missing-rule reindex-time error (TUNE-04): declare `settings: %{ranking_rules: [:typo, :proximity]}` → assert reindex raises `ArgumentError`.
- `skip_settings_verification?` opt-out path with telemetry emission (D-03): pass `skip_settings_verification?: true` → reindex succeeds without calling verify + `[:scrypath, :reindex, :verify_skipped]` event fires (use `:telemetry_test.attach_event_handlers/2` pattern, or inject a test handler).

---

### 15. `test/mix/tasks/scrypath_settings_diff_test.exs` NEW (mix task test)

**Analog:** `test/mix/tasks/verify_release_parity_test.exs` — pure-function split + `Agent`-backed stubs + `assert_raise Mix.Error` pattern.

**Pure-function test shape to mirror** (L6-23):

```elixir
describe "compute/2 (pure path-diff)" do
  test "returns :parity when git paths and hex paths match (D-08)" do
    git = MapSet.new(["lib/a.ex", "guides/x.md", "docs/releasing.md"])
    hex = MapSet.new(["lib/a.ex", "guides/x.md", "docs/releasing.md"])
    assert ReleaseParity.compute(git, hex) == :parity
  end

  test "returns drift tuple with sorted only_in_git and empty only_in_hex" do
    git = MapSet.new(["lib/a.ex", "lib/b.ex", "lib/c.ex"])
    hex = MapSet.new(["lib/a.ex"])
    assert ReleaseParity.compute(git, hex) == {:drift, ["lib/b.ex", "lib/c.ex"], []}
  end
end
```

**JSON-render test shape to mirror** (L26-47):

```elixir
describe "render_json/4 (D-11 stable field order)" do
  test "emits documented JSON shape for drift" do
    json = ReleaseParity.render_json("0.3.0", :drift, ["lib/b.ex"], [])
    decoded = Jason.decode!(json)

    assert decoded == %{
             "version" => "0.3.0",
             "status" => "drift",
             "only_in_git" => ["lib/b.ex"],
             "only_in_hex" => []
           }
  end
end
```

**Extensions (19-05 tests, TUNE-07):**
- Pure drift-comparison function — parity (returns 0-exit shape), drift (returns `{:drift, [...]}`), index-not-found (returns `{:error, :index_not_found}`).
- JSON render per RELEVANCE.md §M-1 7a field shape.
- `Mix.raise` on index-not-found (via `assert_raise Mix.Error`) — mirrors `retry_until!/4` test at `verify_release_parity_test.exs:64-68`.

---

### 16. `test/mix/tasks/scrypath_settings_read_test.exs` NEW (mix task test)

**Analog:** `test/scrypath/mix_tasks/operator_tasks_test.exs` (`CaptureIO` + Application-env client-injection pattern).

**Shape to mirror** (L1-57):

```elixir
defmodule Scrypath.MixTasks.OperatorTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule TaskMeilisearchClient do
    def tasks(filters, _config), do: ...
  end

  setup do
    original_defaults = Application.get_env(:scrypath, :defaults)
    Application.put_env(:scrypath, :defaults,
      backend: Scrypath.Meilisearch,
      meilisearch_url: "http://localhost:7700",
      meilisearch_client: TaskMeilisearchClient,
      # ...
    )

    on_exit(fn -> put_env_or_delete(:defaults, original_defaults) end)
    :ok
  end
  # ...
end
```

**Extensions (19-06 tests, TUNE-08):**
- `capture_io(fn -> Mix.Tasks.Scrypath.Settings.Read.run(["MyApp.Post"]) end)` returns pretty-printed settings map.
- Stub `get_settings/2` on the test client module; assert output contains expected keys.
- Index-not-found → `assert_raise Mix.Error, ~r/index not found/`.

---

## Shared Patterns

### Shared Pattern A: Mix.Task boilerplate

**Source:** `lib/mix/tasks/scrypath.status.ex` (full file; 24 LOC — the canonical short form).
**Apply to:** `lib/mix/tasks/scrypath.settings.diff.ex`, `lib/mix/tasks/scrypath.settings.read.ex`.

```elixir
use Mix.Task

@shortdoc "..."

@moduledoc """..."""

@impl true
def run(args) do
  Mix.Task.run("app.start")

  {opts, argv} = OperatorTask.parse!(args, @switches)    # @switches task-specific
  schema = OperatorTask.schema_from_argv!(argv)
  # ... delegate to Scrypath.* call, render result, or OperatorTask.error!/2
end
```

### Shared Pattern B: Telemetry span envelope

**Source:** `lib/scrypath/telemetry.ex:10-15` + `lib/scrypath/meilisearch/client.ex:91-104`.
**Apply to:** every new telemetry event in `lib/scrypath/reindex.ex` (`[:scrypath, :reindex, :settings_verified]`, `[:scrypath, :reindex, :verify_skipped]`).

```elixir
Telemetry.span([:scrypath, :reindex, :settings_verified], metadata, fn ->
  result = Settings.verify_applied(schema, index, config)
  {result, stop_metadata(result)}
end)
```

### Shared Pattern C: Client-override indirection (test injection)

**Source:** `lib/scrypath/meilisearch/settings.ex:29-31`, `lib/scrypath/meilisearch.ex:85-87`.
**Apply to:** any new function calling into `Scrypath.Meilisearch.Client.*` (notably `verify_applied/3` in the settings module).

```elixir
defp client(config) do
  Keyword.get(config, :meilisearch_client) || Client
end
```

Tests inject a mock via `meilisearch_client:` config key. Already used in every Meilisearch-facing test file; reuse verbatim.

### Shared Pattern D: `Keyword.merge/2` cascade (right-biased precedence)

**Source:** `lib/scrypath/config.ex:13-17` (the entire `resolve!/1` body is the canonical cascade).
**Apply to:** extended `resolve!/1` with per-repo cascade (D-10).

Right-biased: later source wins. Phoenix/Ecto/Oban precedent for config precedence in the Elixir ecosystem. NO new cascade framework needed — extend the existing `Keyword.merge/2` chain by one link.

### Shared Pattern E: Exit-code discipline (0/2/1)

**Source:** `lib/mix/tasks/verify.release_parity.ex:13-17` (moduledoc) + L248-260 (`emit_drift_and_halt!/4`).
**Apply to:** `lib/mix/tasks/scrypath.settings.diff.ex` — same 0/2/1 semantics (no drift / drift / runtime error). D-23 plan 19-05 explicitly reuses this discipline.

### Shared Pattern F: ExUnit mock-client via `send(self(), ...)`

**Source:** `test/scrypath/meilisearch_test.exs:18-52` (RecordingClient with `send` for each call).
**Apply to:** `test/scrypath/meilisearch/client_test.exs`, `test/scrypath/meilisearch/settings_test.exs`, `test/scrypath/reindex_test.exs` extensions.

```elixir
defmodule RecordingClient do
  def get_settings(index_name, config) do
    send(self(), {:client_get_settings, index_name, config})
    {:ok, %{"rankingRules" => [...]}}
  end
end
```

Combined with `assert_receive {:client_get_settings, _, _}` in tests.

---

## No Analog Found

None. All 17 new/modified files have a close in-repo analog. The hybrid analog for `scrypath.settings.diff.ex` (exit-code discipline from `verify.*` namespace + naming conventions from `scrypath.*` namespace) is explicit in CONTEXT.md D-23 plan 19-05 and the canonical_refs section.

---

## Metadata

**Analog search scope:** `lib/scrypath/**/*.ex`, `lib/mix/tasks/*.ex`, `test/**/*.exs`, `mix.exs`.
**Files scanned:** 37 library files, 13 mix-task files, 33 test files, 1 mix.exs.
**Pattern extraction date:** 2026-04-17.
**Phase:** 19 (relevance-tuning).
**Consumed by:** `gsd-planner` — plans 19-01 through 19-07.
