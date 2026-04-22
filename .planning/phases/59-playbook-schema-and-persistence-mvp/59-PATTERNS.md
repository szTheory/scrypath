# Phase 59 — Pattern map

Analogs and excerpts for executors.

## Validation / bounds

**Analog:** `scrypath_ops/lib/scrypath_ops/search_playground.ex`

```elixir
def validate_page_size(n) when is_integer(n) do
  max = max_page_size_allowed()
  cond do
    n < 1 -> {:error, {:page_size_out_of_range, n, max}}
    n > max -> {:error, {:page_size_out_of_range, n, max}}
    true -> :ok
  end
end
```

Playbook **`opts["page"]["size"]`** (or equivalent nested shape per design) should delegate to **`SearchPlayground.validate_page_size/1`** or mirror **1..max** with identical error tuples.

## Multi-search entry shape

**Analog:** `lib/scrypath/multi_search/entries.ex` — **`normalize/2`** expects tuples after schema resolution; playbook **`search_many`** validation should ensure entry count ≤ **`SearchPlayground.max_schemas_allowed/0`** and triple shape per **59-CONTEXT D-08**.

## Stub dispatch (optional tests)

**Analog:** `scrypath_ops/test/support/search_playground_stub_adapter.ex` — **`@behaviour ScrypathOps.SearchPlayground.Adapter`**; configure **`Application.put_env(:scrypath_ops, :search_playground_adapter, Stub)`** in test only.

## Plan document shape

**Analog:** `.planning/phases/58-core-library-and-doc-qol-b1/58-PLAN-01.md` — YAML frontmatter, `<threat_model>`, `<tasks>` with **`<read_first>`**, **`<action>`**, **`<acceptance_criteria>`** using grep-able checks.

## PATTERN MAPPING COMPLETE
