# Stack Research

**Domain:** Tenant-safe search additions to Scrypath (Elixir OSS library)
**Researched:** 2026-05-25
**Confidence:** HIGH

## Verdict on New Dependencies

**Zero new Hex dependencies required for the core milestone.**

`tenant_field:` schema option + `schema_capabilities/1` reflection + `guides/multitenancy.md` are implemented entirely within existing Scrypath modules. The existing stack (Ecto, NimbleOptions, Req, Jason, Oban-optional) already provides everything needed.

Joken is relevant ONLY as a host-app recipe in the guide for browser-direct tenant token generation. It must NOT be added to Scrypath's `mix.exs`.

---

## Existing Stack (Unchanged)

| Technology | Version | Role | Notes |
|------------|---------|------|-------|
| Elixir | `~> 1.17` | Runtime | No change needed |
| Ecto | `~> 3.13` | Schema metadata backbone | `__scrypath__/1` callbacks rely on Ecto-style field atoms |
| NimbleOptions | `~> 1.1` | Option validation | Powers `@schema_options` in `Scrypath.Options` — `tenant_field:` entry adds here |
| Req | `~> 0.5` | HTTP transport to Meilisearch | No change — `filterableAttributes` sync goes through existing Meilisearch client path |
| Jason | `~> 1.4` | JSON encode/decode | No change |
| Oban | `~> 2.21` (optional) | Async sync workers | No change |

---

## New Dependencies

**None.**

Do not add Joken, JOSE, or any JWT library to `mix.exs`. Rationale:

- The core milestone (`tenant_field:` + reflection + guide) involves zero JWT work.
- The guide's tenant token section is a recipe for host-app code, not library code.
- Adding Joken would widen the Scrypath transitive dependency graph without any shipped library surface that uses it — a maintenance burden with no adoption benefit.
- Scrypath's `lib/scrypath.ex` `@moduledoc` already states "tenant authz ... stay host_owned". A Joken dep would contradict that boundary.

---

## Module Integration Points

These are the existing Scrypath modules that need modification for AUTH-01. No new files are required for the minimum credible slice (guide + `tenant_field:` + reflection).

### 1. `lib/scrypath/options.ex` — Schema options extension

**What changes:** Add `tenant_field:` to `@schema_options`.

```elixir
tenant_field: [
  type: {:custom, __MODULE__, :validate_optional_atom, []},
  default: nil,
  doc: "Optional field atom used as the tenant isolation key. Auto-added to filterable: and document projection."
]
```

**Downstream effects in `validate_schema_options!/1`:**
- After NimbleOptions validation, the `ensure_non_empty_fields!` / map coercion path must auto-merge `tenant_field` into `:filterable` if not already present.
- This prevents the silent "forgot to declare filterable" footgun without changing any search-time code path.

**Search option extension (stretch — `tenant_scope:`):**

If the stretch option is included, add `tenant_scope:` to `@search_options`:

```elixir
tenant_scope: [
  type: {:custom, __MODULE__, :validate_tenant_scope, []},
  default: nil,
  doc: "Privileged tenant guard injected as a mandatory AND filter before caller filter: opts. Not overridable."
]
```

`validate_tenant_scope/1` accepts integer, binary, or atom (any value the host supplies as a tenant identity). The filter injection happens in `Scrypath.Search` before the query is assembled, not in `validate_search_options/2`.

### 2. `lib/scrypath/schema.ex` — `__scrypath__/1` callback

**What changes:** Add a `__scrypath__(:tenant_field)` clause so the declaration is accessible at runtime and for reflection.

```elixir
def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
```

This also enables the `Scrypath.Metadata.Capabilities` module to surface `tenant_field` without additional data fetching.

### 3. `lib/scrypath/metadata/capabilities.ex` — `schema_capabilities/1` output

**What changes:** Add a `tenant` key to the capabilities map returned by `schema_capabilities/1`.

```elixir
tenant: %{
  field: schema_module.__scrypath__(:tenant_field),
  declared: schema_module.__scrypath__(:tenant_field) != nil
}
```

This is the reflection surface adopters use to programmatically discover whether a schema has a tenant field declared. The `host_owned` attribution in `Scrypath.Metadata.Resolve` (`tenant_policy: :host_owned`) is already correct and stays unchanged.

### 4. `lib/scrypath/projection.ex` — Document projection

**What changes:** `build_field_document/2` currently projects only `fields:`. If `tenant_field:` names a field not already in `fields:`, it must be included in the synced document. The projection must union `fields + [tenant_field]` (deduped) when `tenant_field` is non-nil.

This closes the "tenant_id missing from document" footgun without the adopter needing to remember to add it to `fields:` manually.

### 5. `guides/multitenancy.md` (new file)

The canonical guide. No module changes — pure documentation. Content scope per auth-01-tenant-research.md:
- Shared-index model
- Why per-tenant indexes are not the default (sequential task processing throughput)
- Correct context-layer pattern with explicit tenant parameter
- Filter merge order footgun with working and broken examples
- `tenant_field:` declaration and what it buys
- Tenant token recipe (Joken, HS256, payload structure) for browser-direct search — clearly marked as host-app code, not Scrypath library code
- What NOT to do: process dictionary for tenant context, per-tenant index proliferation, server-side tenant tokens

### 6. `lib/scrypath/search.ex` — Stretch only (`tenant_scope:`)

**What changes (stretch only):** In `do_search/5`, before `Query.new(text, search_opts)`, extract `tenant_scope:` from search opts and inject it as a prepended filter:

```elixir
search_opts_with_tenant =
  case Keyword.pop(search_opts, :tenant_scope) do
    {nil, opts} -> opts
    {tenant_id, opts} ->
      tenant_field = schema_module.__scrypath__(:tenant_field)
      inject_tenant_filter(opts, tenant_field, tenant_id)
  end
```

`inject_tenant_filter/3` prepends `{tenant_field, tenant_id}` to the front of the `:filter` keyword list, ensuring it cannot be shadowed by caller-supplied filter entries. This is the library-level enforcement guarantee.

---

## Supporting Library for Guide (Host-App Only, Not a Scrypath Dep)

| Library | Version | Purpose | Integration |
|---------|---------|---------|-------------|
| Joken | `~> 2.6` | Meilisearch tenant token generation (HS256 JWT) | Host-app `mix.exs` only. Recipe in guide. |

**Joken v2.6.2 API** (verified against hexdocs.pm/joken, HIGH confidence):

```elixir
signer = Joken.Signer.create("HS256", api_key_value)
{:ok, token, _claims} = Joken.encode_and_sign(claims_map, signer)
```

`Joken.encode_and_sign/2` accepts a `%{}` with binary keys and a `Joken.Signer`. Returns `{:ok, bearer_token, claims}`. The Meilisearch tenant token payload uses binary keys (`"apiKeyUid"`, `"searchRules"`, `"exp"`), which matches Joken's raw claims API exactly.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| No new dep (filterable auto-merge in schema declaration) | Runtime filter guard without schema enforcement | Doesn't fix the "forgot to declare filterable" footgun — the field must be in `filterableAttributes` or Meilisearch silently ignores the filter |
| `tenant_field:` as schema option | Separate `Scrypath.Tenancy` module | Unnecessary module for what is a single option key — keeps the surface inside the existing Options/Schema/Capabilities triad |
| Guide-only JWT recipe (host Joken dep) | Scrypath.TenantToken helper module | No library value-add — Joken is 3 lines of host code; adding a wrapper would grow the public API for zero benefit and introduce a JWT dep permanently |
| `tenant_scope:` injected before `Query.new` in `Search` | Filter merge in `Composition` layer | `Search` is the correct enforcement layer — Composition is data-only and bypassing it there would not protect raw `Scrypath.search/3` calls |

---

## What NOT to Add

| Avoid | Why |
|-------|-----|
| `{:joken, "~> 2.6"}` in Scrypath `mix.exs` | Tenant token generation is host-app concern; adds transitive dep weight (JOSE, etc.) with no shipped library surface using it |
| `{:jose, ...}` or any JWT library | Same reason as Joken — also, Meilisearch's HS256 token needs are trivially met by Joken in host app |
| A new `Scrypath.Tenancy` or `Scrypath.TenantToken` module | Violates boundary discipline — `lib/scrypath.ex` `@moduledoc` already declares tenant authz host_owned |
| Process dictionary tenant context reading | Breaks across `Task.async`, `assign_async`, Oban workers — explicitly anti-pattern per curiosum.com/blog/multitenancy-in-elixir |
| Automatic per-tenant `index_prefix:` routing | Same throughput problem as per-tenant index strategy; Meilisearch sequential task processing degrades at scale |

---

## mix.exs: No Changes Required

Current `mix.exs` is at version `0.3.6`. The AUTH-01 milestone requires no dependency additions, removals, or version bumps. The milestone delivers:

1. A new `tenant_field:` key in `@schema_options` (NimbleOptions already handles custom validators)
2. Extensions to `__scrypath__/1` in `schema.ex`
3. A `tenant` key in the `schema_capabilities/1` output
4. Auto-include of `tenant_field` in document projection
5. `guides/multitenancy.md` new file
6. Optionally: `tenant_scope:` in `@search_options` + injection in `Scrypath.Search.do_search`

All of these use existing dependencies.

---

## Sources

- Direct codebase inspection: `lib/scrypath/options.ex`, `lib/scrypath/schema.ex`, `lib/scrypath/metadata/capabilities.ex`, `lib/scrypath/metadata/resolve.ex`, `lib/scrypath/projection.ex`, `lib/scrypath/search.ex`, `mix.exs` — HIGH confidence
- hexdocs.pm/joken/Joken.html — `encode_and_sign/2` signature and return shape — HIGH confidence
- hexdocs.pm/joken/signers.html — `Joken.Signer.create("HS256", key)` API — HIGH confidence
- .planning/research/auth-01-tenant-research.md — prior domain research with PRIMARY citations to Meilisearch specs and official docs — HIGH confidence

---
*Stack research for: Scrypath v1.25 Tenant-Safe Search (AUTH-01)*
*Researched: 2026-05-25*
