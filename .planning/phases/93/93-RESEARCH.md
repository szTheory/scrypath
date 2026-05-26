# Phase 93: Reflection and Runtime Enforcement - Research

**Researched:** 2024-05-25
**Domain:** Elixir, Metaprogramming, Reflection, and Validation Options
**Confidence:** HIGH

## Summary

This phase aims to expose the schema tenant declarations through `Scrypath.Metadata` and enforce tenant filters safely at runtime within `Scrypath.search/3`. It allows adopters to programmatically introspect schemas to find out if and which field acts as the tenant boundary, and enforces a pattern where caller-supplied filters cannot overwrite or shadow the library-injected tenant scoped filters. 

**Primary recommendation:** Use existing `__scrypath__/1` metadata to expose `:tenant_field` in `Scrypath.Metadata.Capabilities`. Add `tenant_scope:` to `NimbleOptions` validation in `Scrypath.Options` and hard-inject the scope into the `filter:` parameter inside `validate_search_options/2`.

<user_constraints>
## User Constraints (from Context)

### Locked Decisions
- `schema_capabilities/1` must reflect the `tenant_field:` declaration via the `:tenant` key (returning either the field atom or `nil`).
- `tenant_scope:` option must be added to NimbleOptions.
- Tenant scope injection must prevent caller filters from shadowing or overwriting the tenant guard by raising an `ArgumentError`.
- Passing `tenant_scope:` for a schema that has no `tenant_field:` must raise a deterministic error.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reflection | Metadata / Utils | — | `Scrypath.Metadata.Capabilities` provides static reflection on schema capabilities. |
| Validation | API / Backend | — | `Scrypath.Options` validates and transforms caller inputs before passing them down. |
| Tenant Filtering | API / Backend | — | Hard-injecting tenant filter in `validate_search_options/2` enforces multitenancy globally across `search/3`, `search_within_facet/4`, and `search_many/2`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | ~> 1.14 | Language | Host language for Scrypath |
| NimbleOptions | ~> 1.0 | Validation | Handles robust, schema-driven options validation |

## Architecture Patterns

### Recommended Project Structure

Changes will happen within the current module structures:
```
lib/
├── scrypath/
│   ├── metadata/
│   │   └── capabilities.ex    # Add :tenant to schema_capabilities map
│   └── options.ex             # Update @search_options, add inject_tenant_scope!/2
```

### Pattern 1: Hard-Injected Validations
**What:** Validating and modifying inputs in the central `validate_search_options/2` pipeline.
**When to use:** When adding cross-cutting behavioral restrictions (like tenant scoping) that apply to all search variants concurrently.
**Example:**
```elixir
try do
  validated
  |> inject_tenant_scope!(schema_module)
  |> validate_filterable_fields!(filterable)
  |> validate_sortable_fields!(sortable)
  |> then(&{:ok, &1})
rescue
  e in ArgumentError -> {:error, {:validation, Exception.message(e)}}
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Options Injection | Custom nested merging in multiple places | Central `validate_search_options/2` | Guarantees universal application across all search functions without redundant implementations. |
| Reflection | Complex runtime introspection | `schema_module.__scrypath__(:tenant_field)` | Phase 92 built compile-time metadata specifically to avoid runtime cost. |

## Runtime State Inventory
Step 2.5: SKIPPED (Phase is purely code/config changes with no external dependencies identified, no rename/rebrand)

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Common Pitfalls

### Pitfall 1: Caller Filter Shadowing
**What goes wrong:** A caller includes `filter: [tenant_id: "other"]` while also providing `tenant_scope: "expected"`. If merged improperly, the caller's explicit filter could overwrite the required tenant scope.
**Why it happens:** Keyword list overrides (like `Keyword.put/3`) overwrite earlier identical keys.
**How to avoid:** explicitly assert `Keyword.has_key?(current_filter, tenant_field)` in `inject_tenant_scope!/2` and raise `ArgumentError`.

### Pitfall 2: Silently Ignoring Unenforced Scope
**What goes wrong:** Calling `search(tenant_scope: 123)` on a schema without `tenant_field:`.
**Why it happens:** Blindly executing the pipeline when `tenant_field` resolves to `nil`.
**How to avoid:** Assert `tenant_field` is not `nil` when `tenant_scope:` is provided; raise `ArgumentError` if violated.

## Code Examples

### tenant_scope Injection Pipeline
```elixir
defp inject_tenant_scope!(opts, schema_module) do
  case Keyword.fetch(opts, :tenant_scope) do
    :error -> opts
    {:ok, scope_val} ->
      tenant_field = schema_module.__scrypath__(:tenant_field)
      if is_nil(tenant_field) do
        raise ArgumentError, "tenant_scope: provided but schema \#{inspect(schema_module)} does not declare a tenant_field:"
      end

      current_filter = Keyword.get(opts, :filter, [])
      if Keyword.has_key?(current_filter, tenant_field) do
        raise ArgumentError, "tenant_scope: cannot be used because filter: already contains the tenant_field \#{inspect(tenant_field)}. Remove it from filter: to allow tenant enforcement."
      end

      new_filter = current_filter ++ [{tenant_field, scope_val}]
      Keyword.put(opts, :filter, new_filter)
  end
end
```

## Assumptions Log
*(No `[ASSUMED]` claims in this research.)*

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test/test_helper.exs |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-93-1 | `schema_capabilities/1` returns `:tenant` atom when declared | unit | `mix test test/scrypath/metadata_test.exs` | ✅ Wave 0 |
| REQ-93-2 | `schema_capabilities/1` returns `nil` for `:tenant` when omitted | unit | `mix test test/scrypath/metadata_test.exs` | ✅ Wave 0 |
| REQ-93-3 | `tenant_scope:` AND-combines tenant filter; raises on caller conflict | unit | `mix test test/scrypath/options_test.exs` | ✅ Wave 0 |
| REQ-93-4 | `tenant_scope:` raises deterministic error if schema lacks `tenant_field:` | unit | `mix test test/scrypath/options_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] Add conflict/resolution tests to `test/scrypath/options_test.exs`.
- [ ] Ensure `test/scrypath/metadata/capabilities_test.exs` tests capability inclusion (or update existing tests in `test/scrypath/metadata_test.exs`).

## Sources
### Primary (HIGH confidence)
- Current file structures in `lib/scrypath/options.ex` and `lib/scrypath/metadata/capabilities.ex`.
- Context logic from `.planning/phases/93/93-PATTERNS.md` which exactly addresses the required changes.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Scrypath internal modules
- Architecture: HIGH - Matches internal patterns strictly
- Pitfalls: HIGH - Edge cases explicitly covered in instructions

**Research date:** 2024-05-25
**Valid until:** 30 days