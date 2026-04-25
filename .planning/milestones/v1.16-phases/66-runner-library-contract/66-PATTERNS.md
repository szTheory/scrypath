# Phase 66: runner-library-contract - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` | service | request-response | `lib/scrypath.ex` | role-match |
| `scrypath_ops/docs/playbook-schema-v1.md` | config | transform | `scrypath_ops/docs/team-playbook-persistence.md` | role-match |
| `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` | test | request-response | `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` | exact |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | test | async request-response | `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | exact |

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` (service, request-response)

**Primary analog:** `lib/scrypath.ex`

**Related sources to copy from:**
- `lib/scrypath/search.ex`
- `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex`
- existing `scrypath_ops/lib/scrypath_ops/playbook/runner.ex`

**Public contract doc pattern** (`lib/scrypath.ex:140`, `lib/scrypath.ex:154`, `lib/scrypath.ex:207`, `lib/scrypath.ex:233`):
```elixir
@doc """
Primary hydrated search entry: validates options, resolves runtime config, and
returns `{:ok, %Scrypath.SearchResult{}}` or tagged `{:error, _}` failures ...

## Errors vs raises

* **`{:error, reason}`** — operational failures ...

`search!/3` raises `Scrypath.Search.Error` with the same `reason` ...
"""
```

**Bang/non-bang alignment pattern** (`lib/scrypath/search.ex:146-151`, `lib/scrypath/search.ex:227-235`):
```elixir
def search!(schema_module, text, opts \\ []) do
  case search(schema_module, text, opts) do
    {:ok, result} -> result
    {:error, reason} -> raise Scrypath.Search.Error, reason: reason
  end
end
```

**Typed result alias pattern if local `@typedoc`s are added** (`scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex:4-11`):
```elixir
@typedoc "Return type of `Scrypath.search/3`."
@type search_result :: {:ok, Scrypath.SearchResult.t()} | {:error, term()}

@typedoc "Return type of `Scrypath.search_many/2`."
@type search_many_result :: {:ok, Scrypath.MultiSearchResult.t()} | {:error, term()}
```

**Existing dispatch and guard pattern to preserve** (`scrypath_ops/lib/scrypath_ops/playbook/runner.ex:17-18`, `scrypath_ops/lib/scrypath_ops/playbook/runner.ex:27-49`, `scrypath_ops/lib/scrypath_ops/playbook/runner.ex:52-77`):
```elixir
@spec run_validated(map() | {:ok, map()}, [module()], keyword()) ::
        {:ok, term()} | {:error, term()}

def run_validated(%{"mode" => "search"} = map, allowlist, scrypath_opts) do
  ...
  cond do
    allowlist == [] -> {:error, {:config, :empty_allowlist}}
    mod == nil -> {:error, {:config, :no_schema}}
    not is_binary(q) -> {:error, {:config, :invalid_query}}
    not Keyword.has_key?(scrypath_opts, :backend) -> {:error, {:config, :missing_backend}}
    true ->
      with {:ok, opts} <- build_dispatch_opts(scrypath_opts, opts_map, :search) do
        SearchPlayground.dispatch_search(mod, q, opts)
      end
  end
end
```

**Planner guidance:** add a dedicated `## Runner-library contract` subsection inside the existing `@moduledoc`; mirror the root-library “errors vs raises” style; document accepted validated input shape, `%Scrypath.SearchResult{}` vs `%Scrypath.MultiSearchResult{}` success values, `{:error, reason}` failures, and that reason identity is the stable contract while Mix/UI formatting stays downstream.

---

### `scrypath_ops/docs/playbook-schema-v1.md` (config, transform)

**Primary analog:** `scrypath_ops/docs/team-playbook-persistence.md`

**Related source to copy from:** `docs/operator-support.md`

**Canonical-authority wording pattern** (`scrypath_ops/docs/team-playbook-persistence.md:3-8`):
```md
This page is the **canonical operator story** ...
There is **exactly one** mutating catalog source ...
```

**Link-out instead of duplication pattern** (`scrypath_ops/docs/team-playbook-persistence.md:65-68`):
```md
## Further reading

- **[playbook-schema-v1.md](playbook-schema-v1.md)** — normative wire format, caps, banned keys.
```

**Boundary-language pattern** (`docs/operator-support.md:37-44`):
```md
Support docs should keep two boundaries explicit:

- operator visibility and recovery live on `Scrypath.*`
- backend-native search power stays under `Scrypath.Meilisearch.*`
```

**Current wire-format scope to preserve** (`scrypath_ops/docs/playbook-schema-v1.md:1-4`, `scrypath_ops/docs/playbook-schema-v1.md:94-116`):
```md
# Playbook interchange — `playbook_format` 1

Normative reference for **version 1** saved-search playbooks consumed by **ScrypathOps** ...
Executable validation lives in **`ScrypathOps.Playbook.V1`**.
```

**Planner guidance:** keep this file as JSON-wire-format authority only. Add a short link near the top to the canonical runner contract in `ScrypathOps.Playbook.Runner`; do not duplicate tuple success/error shapes here; do not disturb existing troubleshooting anchors that `DocResolver` already targets.

---

### `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` (test, request-response)

**Primary analog:** existing `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`

**Related sources to copy from:**
- `test/scrypath/search_many_test.exs`
- `scrypath_ops/test/support/search_playground_stub_adapter.ex`

**Existing environment setup/restore pattern** (`scrypath_ops/test/scrypath_ops/playbook/runner_test.exs:11-45`):
```elixir
setup do
  prev_allow = Application.get_env(:scrypath_ops, :schema_allowlist)
  ...
  Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
  ...
  on_exit(fn ->
    restore = fn k, v ->
      if v == nil, do: Application.delete_env(:scrypath_ops, k), else: Application.put_env(:scrypath_ops, k, v)
    end
    ...
  end)
end
```

**Existing explicit test style to preserve** (`scrypath_ops/test/scrypath_ops/playbook/runner_test.exs:47-81`):
```elixir
assert {:ok, map} = V1.validate(raw)

assert {:ok, %Scrypath.MultiSearchResult{} = ms} =
         Runner.run_validated(map, Schemas.allowlist(), Schemas.scrypath_opts())

assert length(ms.ordered) == 2
```

**Representative matrix pattern from core tests** (`test/scrypath/search_many_test.exs:141-152`, `test/scrypath/search_many_test.exs:183-189`, `test/scrypath/search_many_test.exs:201-212`, `test/scrypath/search_many_test.exs:234-248`):
```elixir
assert {:ok, %MultiSearchResult{ordered: ordered, failures: [], by_schema: by}} =
         Scrypath.search_many([{SearchablePost, "a"}, {FacetableMovie, "b"}], @base_opts)

assert {:error, {:validation_failed, SearchablePost, {:unknown_facet, :nope}}} =
         Scrypath.search_many([{SearchablePost, "a", facets: [:nope]}], @base_opts)

assert {:error,
        {:invalid_options,
         {:federation_merge_requires_native_search_many, %{backend: SequentialOnlyBackend}}}} =
         Scrypath.search_many([...], Keyword.put(@base_opts, :backend, SequentialOnlyBackend))
```

**Deterministic adapter-double pattern if a narrow helper is needed** (`scrypath_ops/test/support/search_playground_stub_adapter.ex:18-35`):
```elixir
def search_many(entries, opts) when is_list(entries) do
  case Application.get_env(:scrypath_ops, :search_stub_variant, :ok) do
    :hard_error -> {:error, :stub_hard_failure}
    _ -> ok_result(entries, opts)
  end
end
```

**Planner guidance:** keep the suite explicit and small. Add 4-5 parity cases, not a meta-harness: `search` success, `search_many` success, one pre-dispatch/config failure, one backend/runtime failure, and one operator-relevant `search_many` edge. Prefer asserting exact reason heads and result struct modules over UI copy or docs links.

---

### `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` (test, async request-response)

**Primary analog:** existing `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`

**Related sources to copy from:**
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`
- `scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs`

**Existing async-run assertion pattern** (`scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`):
```elixir
view
|> element("button[phx-click='run-playbook']")
|> render_click()

render_async(view)
```

**Assign-state boundary pattern to preserve** (`scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`):
```elixir
|> assign(:run_error, reason)
|> assign(:run_failure_enriched, enriched)
```

**Planner guidance:** add one focused downstream regression that inspects assign state or equivalent LiveView test seam after a failing run and proves the raw reason survives alongside enriched output. Keep assertions on reason identity and enriched-state presence, not exact flash-copy wording.

## Shared Patterns

### Stable Tuple Contract

**Sources:**
- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex:17-18`
- `lib/scrypath.ex:140-167`
- `lib/scrypath.ex:207-239`

```elixir
@spec run_validated(map() | {:ok, map()}, [module()], keyword()) ::
        {:ok, term()} | {:error, term()}
```

Apply to `runner.ex` docs and tests: the stable seam is raw `{:ok, result}` / `{:error, reason}`; reason term identity is the compatibility target.

### Formatting Lives Downstream

**Sources:**
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex:31-42`
- `lib/scrypath/errors.ex:6-17`

```elixir
def enrich(reason, context \\ []) do
  context = sanitize_context(context)
  {failure_class, message, doc_ref, copy_strategy} = lookup(reason)

  %{
    failure_class: failure_class,
    reason: normalize_reason(reason),
    message: message,
    copy: build_copy(copy_strategy, context),
    doc: DocResolver.resolve(doc_ref)
  }
end
```

Apply to runner docs and parity tests: do not freeze flash text, docs links, or enriched payloads as the execution contract.

### Delegate to Core Scrypath APIs Directly

**Source:** `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex:14-28`

```elixir
def search(schema, text, opts), do: Scrypath.search(schema, text, opts)
def search_many(entries, opts), do: Scrypath.search_many(entries, opts)
```

Apply to parity-test design: compare runner outcomes against the same root-library calls the adapter uses; avoid introducing a parallel normalization layer in this phase.

### Explicit, Representative Tests

**Sources:**
- `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs:47-81`
- `test/scrypath/search_many_test.exs:141-152`
- `test/scrypath/search_many_test.exs:183-248`

Use a handful of named cases with direct assertions. Avoid property tests, generated case matrices, or replaying the full root suite through OPSUI.

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/`, `test/`, `scrypath_ops/lib/`, `scrypath_ops/test/`, `docs/`, `scrypath_ops/docs/`
**Files scanned:** 16
**Pattern extraction date:** 2026-04-22
