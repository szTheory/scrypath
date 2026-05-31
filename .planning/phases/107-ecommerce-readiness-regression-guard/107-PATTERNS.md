# Phase 107: Pattern Map

## Pattern Mapping Complete

## Files to Modify or Verify

| File | Role | Closest Existing Analog | Pattern to Preserve |
|------|------|-------------------------|---------------------|
| `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` | dev/test readiness probe controller | Existing `search_visible/2` and nearby `parse_integer/1` helpers | Keep controller logic thin: parse params, compose explicit search opts, call `Scrypath.search/3`, return JSON or deterministic 400. |
| `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` | service-free controller regression test | Existing `SearchVisibleBackend` stub and `assert_receive {:search_visible_query, ...}` pattern | Stub the Scrypath backend, capture `%Scrypath.Query{}`, and assert the exact merged filter instead of relying only on response JSON. |
| `lib/mix/tasks/verify.phase107.ex` | focused phase verification task | `lib/mix/tasks/verify.phase106.ex`, `lib/mix/tasks/verify.phase94.ex` | `use Mix.Task`, reject args, run `app.start`, reenable `test`, and run a short explicit focused test list. |
| `test/mix/tasks/verify.phase107_test.exs` | verify task source/argument contract test | `test/mix/tasks/verify.phase106_test.exs` | Use `ExUnit.Case, async: false`, `ExUnit.CaptureIO`, argument rejection, help/source assertions for focused test paths. |
| `mix.exs` | Mix task environment registration | Existing `preferred_envs` entries for phase verify tasks | Add `"verify.phase107": :test` near adjacent phase verification task entries. |

## Concrete Code Patterns

### Preserve Existing Filters Before Adding Category

The readiness probe should begin from tenant-scoped explicit filters, then add category readiness filtering by reading the current filter keyword list:

```elixir
filters =
  opts
  |> Keyword.get(:filter, [])
  |> Keyword.put(:category_id, category_id)

{:ok, Keyword.put(opts, :filter, filters)}
```

Do not replace the whole `filter` value with `[category_id: category_id]`, and do not switch this probe to `tenant_scope:` in Phase 107.

### Assert Query Contract at the Backend Boundary

The controller test can prove the regression directly by stubbing `Scrypath.Backend.search/3`, sending the generated query back to the test process, and asserting:

```elixir
assert_receive {:search_visible_query, Product, %Query{text: "quantum", filter: filter}}
assert Enum.sort(filter) == [category_id: 202, tenant_id: 101]
```

This is stronger than a response-body-only assertion because it proves tenant scope survives option composition before backend execution.

### Focused Verify Task Pattern

Phase verify tasks should stay deterministic and service-free:

```elixir
defmodule Mix.Tasks.Verify.Phase107 do
  @moduledoc false
  use Mix.Task

  @focused_tests [
    "examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs",
    "test/mix/tasks/verify.phase107_test.exs"
  ]

  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")
    Mix.Task.reenable("test")
    Mix.Task.run("test", @focused_tests)
  end
end
```

Match nearby task helper style where possible; the important contract is no arguments, no live services, and only focused regression proof.

## Anti-Patterns

- Do not add Playwright cross-tenant fixture expansion in Phase 107.
- Do not promote `phase105-e2e` or add required CI lanes.
- Do not add a shared storefront/probe helper just to remove the narrow duplicate filter composition.
- Do not introduce new Scrypath public APIs, tenant helper semantics, or Meilisearch behavior changes.
