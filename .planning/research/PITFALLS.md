# Pitfalls Research

**Domain:** Tenant-safe search in an Elixir/Meilisearch OSS library (Scrypath v1.25 AUTH-01)
**Researched:** 2026-05-25
**Confidence:** HIGH (grounded in codebase inspection + verified Meilisearch behavior)

---

## Silent vs. Noisy Failure Classification

The most dangerous pitfalls here produce no error — they silently return wrong data or empty results. This classification matters for prioritization because silent failures are security vulnerabilities, not UX bugs.

| Failure Mode | Signal Type | Security Risk | Data Risk |
|---|---|---|---|
| Filter merge order bug drops tenant guard | SILENT — returns cross-tenant documents | HIGH data leak | Cross-tenant exposure |
| `tenant_id` not in `filterableAttributes` | SILENT — filter ignored, all docs returned | HIGH data leak | Cross-tenant exposure |
| `tenant_id` missing from document projection | SILENT — filter matches nothing | LOW security | All tenants get zero results |
| `tenant_id` field on association, not schema | NOISY at sync (raises at projection), SILENT if nil returned from custom hook | MEDIUM | Depends on workaround used |
| Composition preset silently drops tenant guard | SILENT — merge-order bug reappears in composed output | HIGH data leak | Cross-tenant exposure |
| Settings not reconciled after `tenant_field:` added | SILENT — live index stale, filter ignored | HIGH data leak | Cross-tenant exposure |
| Per-tenant index proliferation | SLOW degradation — no error, just latency | None | Ops problem only |
| Tenant tokens used server-side | Operational overhead — no error | None | Ops problem only |
| Process dictionary for tenant context | SILENT wrong-tenant across async boundaries | HIGH data leak | Depends on timing |
| Scope creep: auto-extracting tenant from conn | Architectural debt — breaks in non-request contexts | MEDIUM | Context-dependent |

---

## Critical Pitfalls

### Pitfall 1: Filter Merge Order Bug Silently Drops the Tenant Guard

**Classification: SILENT — data leak, HIGH security risk**

**What goes wrong:**
The context function assembles search opts by merging caller-supplied opts with the tenant filter. If `Keyword.merge/2` is called with the tenant filter as the first argument and caller opts as the second, `Keyword.merge` last-key-wins semantics silently discard the tenant guard when the caller passes `filter:` in opts. No error is raised. The query executes with only the caller's filters, returning all matching documents regardless of tenant.

```elixir
# WRONG — tenant filter is silently lost if opts contains filter:
def search_posts(text, tenant_id, opts \\ []) do
  Scrypath.search(Post, text,
    Keyword.merge([filter: [tenant_id: tenant_id]], opts)
  )
end

# If caller passes: opts = [filter: [status: :published]]
# Result: filter is [status: :published] only — tenant_id guard gone
```

**Why it happens:**
`Keyword.merge/2` uses right-wins semantics: the `:filter` key in `opts` clobbers the `:filter` key in the base list. This is correct Elixir behavior. The bug is in the merge direction chosen by the developer, not in Elixir or Scrypath. The mental model "merge my defaults then caller overrides" accidentally promotes caller-supplied opts to higher priority than the security-critical tenant filter.

**Scrypath-specific context:**
`Scrypath.Options.validate_search_options/2` validates that filter fields are declared in `filterable:`. It does NOT validate merge order or whether a tenant guard that was present in one call site survived opts assembly. The validation gate fires on whatever filter the assembled keyword list contains — after the damage is already done.

**Correct pattern:**
```elixir
def search_posts(text, tenant_id, opts \\ []) do
  tenant_filter = [tenant_id: tenant_id]
  caller_filter = Keyword.get(opts, :filter, [])
  composed_filter = tenant_filter ++ caller_filter

  Scrypath.search(Post, text,
    Keyword.merge(opts, [filter: composed_filter])
  )
end
```

The tenant filter is prepended, not merged at the keyword-list level. The `filter:` key in `opts` is extracted, concatenated after the tenant guard, then the resulting filter replaces `opts`' `:filter` key.

**How to avoid:**
- Guide (`guides/multitenancy.md`): Document the merge order explicitly with a wrong/correct comparison. Make the wrong pattern visually prominent with a danger callout.
- Stretch (v1.25): `tenant_scope:` option on `Scrypath.search/3` injects the tenant filter after all caller opts are resolved — removing the host's ability to accidentally override it.

**Warning signs:**
- Tests pass with a single tenant but production shows cross-tenant results after adding UI filters
- Opts assembly uses `Keyword.merge([filter: ...], opts)` — the arg order is wrong
- No context-module test where the caller also passes `filter:` opts

**Phase to address:**
Guide phase (v1.25 Phase 1) — wrong/correct merge order comparison is the first thing `guides/multitenancy.md` must show. If the `tenant_scope:` stretch option is built, it eliminates this pitfall entirely at the library layer.

---

### Pitfall 2: `tenant_id` Not in `filterableAttributes` — Filter Silently Ignored, All Docs Returned

**Classification: SILENT — data leak, HIGH security risk**

**What goes wrong:**
The `tenant_id` field is in the Meilisearch document (synced correctly) but is not in the `filterableAttributes` index setting. Meilisearch silently ignores filter expressions on non-filterable fields. The search returns all documents in the index — across all tenants — with no error. This is confirmed behavior per the Meilisearch `filterableAttributes` specification: filtering on undeclared attributes is a no-op, not an error.

**Why it happens:**
Two independent declarations are required: `filterable: [:tenant_id]` in the Scrypath schema declaration, AND the live Meilisearch index must have that setting applied. In Scrypath, `filterable:` in the schema drives `filterableAttributes` when settings are applied via `mix scrypath.reconcile` or during a reindex. If `tenant_id` is added to `fields:` for sync but omitted from `filterable:`, the field is in documents but Meilisearch will not filter on it.

A subtler variant: the developer adds `filterable: [:tenant_id]` to the schema declaration but never runs `mix scrypath.reconcile`. The schema is correct; the live index is still the old value. The filter is declared but silently ignored in production.

**Scrypath-specific context:**
`Scrypath.Options.validate_filterable_fields!` (called inside `validate_search_options!/2`) validates that filter keys are in the schema's declared `filterable:` list. This will raise `ArgumentError` if you try to filter on `:tenant_id` without declaring it. However, it only fires if the schema declaration is wrong — it cannot detect when the schema declaration is correct but the live index is out of sync.

**Correct pattern:**
```elixir
defmodule MyApp.Blog.Post do
  use Scrypath,
    fields: [:title, :body, :tenant_id],    # must be in fields to sync
    filterable: [:tenant_id, :status],      # must be in filterable for index settings
    sortable: [:inserted_at]
end
```

After adding `tenant_id` to the schema: run `mix scrypath.reconcile` to apply settings to the live index. Use `mix scrypath.settings.diff` to confirm alignment before go-live.

**How to avoid:**
- `tenant_field:` schema option (v1.25 core deliverable): auto-adds the named field to `filterable:`, removing the "forgot to declare filterable" failure mode
- Guide: explain the two-step requirement (declaration + live index sync) explicitly, with a post-declaration checklist
- `mix scrypath.settings.diff` before every deploy that touches schema declarations

**Warning signs:**
- Search returns results from multiple tenants even with filter applied
- `mix scrypath.settings.diff` shows `filterableAttributes` divergence for the tenant field
- Index was created before `tenant_id` was added to the schema declaration

**Phase to address:**
`tenant_field:` schema option phase (v1.25 Phase 2) — the option closes this class of error at the declaration layer. Guide phase closes it at the documentation layer.

---

### Pitfall 3: `tenant_id` Missing From Document Projection — Filter Matches Nothing, All Tenants Get Zero Results

**Classification: SILENT — correctness failure, LOW direct security risk but operationally broken**

**What goes wrong:**
`tenant_id` is in `filterable:` (index settings are correct) but not in `fields:`. Documents are indexed without the `tenant_id` field. Meilisearch cannot match the filter expression against an absent field — `"tenant_id = 42"` matches nothing. Every tenant gets empty results with no error.

**Why it happens:**
In Scrypath's field-mode projection (`build_field_document`), only fields declared in `fields:` are included in the synced document. `filterable:` is an index settings concern, not a projection concern. The two lists are intentionally independent. A developer may correctly add `tenant_id` to `filterable:` for index settings but forget to also add it to `fields:` for document projection.

**Scrypath-specific context:**
`Scrypath.Projection.build_field_document/2` uses only `schema_module.__scrypath__(:fields)` — exactly that list. There is no cross-check that filterable fields are also projected. If the schema uses a custom `search_document/1` hook, the pitfall shifts there: the custom projection must explicitly include `:tenant_id` in the returned map.

**Correct pattern:**
```elixir
# WRONG — tenant_id in filterable but not fields
use Scrypath,
  fields: [:title, :body],
  filterable: [:tenant_id, :status]

# CORRECT — tenant_id in both fields and filterable
use Scrypath,
  fields: [:title, :body, :tenant_id],
  filterable: [:tenant_id, :status]
```

For custom `search_document/1` schemas:
```elixir
def search_document(%Post{} = post) do
  %{
    title: post.title,
    body: post.body,
    tenant_id: post.tenant_id    # must be explicitly included
  }
end
```

**How to avoid:**
- `tenant_field:` schema option: auto-adds the field to both `filterable:` AND ensures it is included in the projected document (field-mode case injects into `fields:` processing)
- Guide: explicit checklist showing both declarations required
- Backfill document inspection: after any schema change, verify a sample document in Meilisearch contains the `tenant_id` key

**Warning signs:**
- All search calls return empty results after adding tenant filtering
- Meilisearch document inspector shows no `tenant_id` field in stored documents
- `filterable:` has `:tenant_id` but `fields:` does not

**Phase to address:**
`tenant_field:` schema option phase (v1.25 Phase 2) — this pitfall is exactly what the option is designed to eliminate.

---

### Pitfall 4: `Scrypath.Composition` Preset Silently Drops Tenant Guard Via Merge-Order Bug

**Classification: SILENT — data leak risk, HIGH security risk in apps using Composition**

**What goes wrong:**
A host app uses `Scrypath.Composition.compose/2` to build search opts from reusable presets. The context then tries to inject the tenant filter into the composition result before calling `Scrypath.search/3`. Three concrete failure modes:

**Failure mode A — merge-order bug reappears post-composition:**
`Scrypath.Composition.to_search_args/1` converts the composed result to `{text, keyword_opts}`. The context then does `Keyword.merge(keyword_opts, [filter: [tenant_id: id]])` — wrong direction again. If `keyword_opts` already has a `:filter` key from the preset, the tenant filter overwrites it instead of being appended.

**Failure mode B — `fixed:` conflict detection fires on valid tenant injection:**
`Scrypath.Composition.Merge` detects conflicts in `fixed:` fields and returns `{:error, {:composition_conflict, field, key, ...}}`. If a preset declares `fixed: %{filter: [tenant_id: :placeholder]}` and the context tries to inject the real tenant filter via a second `fixed:` fragment, a composition conflict is raised. The error is noisy, but the code path is wrong and the fix path is unclear.

**Failure mode C — `to_search_args/1` silently drops unrecognized keys:**
`Scrypath.Composition.to_search_args/1` outputs only `@search_option_keys = [:filter, :sort, :page, :facets, :facet_filter, :per_query]`. Any tenant-related key added to the composition result at the context level but not in `@search_option_keys` (e.g., a custom `:tenant_scope` key) would be silently dropped when lowering to search args.

**Why it happens:**
Composition and tenant enforcement are orthogonal in the current design. The library has no concept of "privileged" vs "caller-supplied" filters. Any filter assembled via Composition faces the same merge-order pitfalls as raw opts assembly, with the added complication that the merge happens across two steps (compose + to_search_args).

**Scrypath-specific context:**
`Scrypath.Composition.Merge.apply_fixed/2` does conflict detection: if caller criteria already contain a conflicting value for a `fixed:` key, it returns `{:error, {:composition_conflict, ...}}`. There is no notion of "tenant is higher priority than fixed." `fixed:` is positioned as the highest-priority layer in the current Composition design — the wrong layer for tenant enforcement.

**How to avoid:**
- Guide: document that tenant filter injection must happen AFTER `to_search_args/1`, using explicit filter concatenation — not via Composition
- Do NOT use `Scrypath.Composition.fixed:` for tenant filters — `fixed:` is for preset business rules that survive caller overrides, not for security-critical isolation
- Stretch: `tenant_scope:` on `Scrypath.search/3` sidesteps Composition entirely — the tenant guard is injected at the library layer after all Composition output is resolved

**Warning signs:**
- Context uses `Composition.compose/2` and then tries to "add tenant" to the result map
- `fixed:` preset includes any `:filter` keys that overlap with the tenant field
- `to_search_args/1` output is merged with tenant filter using `Keyword.merge` without explicit filter concatenation

**Phase to address:**
Guide phase (v1.25 Phase 1) — the guide must explicitly address the "Composition + tenant filter" assembly pattern. `tenant_scope:` stretch option eliminates this class of pitfall if implemented.

---

### Pitfall 5: Settings Not Reconciled After Adding `tenant_field:` — Live Index Stays Stale

**Classification: SILENT — data leak equivalent to Pitfall 2, but with correct schema declaration**

**What goes wrong:**
The developer adds `tenant_field: :tenant_id` to their schema declaration (the v1.25 feature). This correctly updates the schema's metadata and adds `:tenant_id` to `filterable:`. But if the live Meilisearch index already exists from before the declaration change, and `mix scrypath.reconcile` is not run, the live index does not have `filterableAttributes` updated. The schema and Meilisearch are in drift. The filter is declared correctly but silently ignored in production — Pitfall 2 again, through a different path.

**Why it happens:**
Scrypath separates schema declaration from settings application by design. The schema is the source of truth; the live index is a reflection that must be explicitly synchronized. Adding `tenant_field:` is a schema change — it does not automatically push a settings update to Meilisearch.

**How to avoid:**
- Guide: explicit post-declaration step — "Run `mix scrypath.reconcile` after adding `tenant_field:`"
- `mix scrypath.settings.diff` to verify alignment before go-live; make this a deployment checklist item
- Consider emitting a compile-time or startup warning when `tenant_field:` is declared but the implementation cannot verify live index alignment

**Warning signs:**
- Added `tenant_field:` but did not run `mix scrypath.reconcile`
- `mix scrypath.settings.diff` shows `filterableAttributes` drift for the tenant field
- Index was created in a previous deploy cycle

**Phase to address:**
`tenant_field:` schema option phase (v1.25 Phase 2) — the guide produced in this phase must include the post-declaration reconciliation step prominently.

---

## Moderate Pitfalls

### Pitfall 6: `tenant_id` Field Lives on an Association, Not the Schema

**Classification: NOISY at sync time (raises), SILENT if developer works around with nil**

**What goes wrong:**
In some SaaS data models, the Ecto schema does not have a direct `tenant_id` column — instead, it belongs to a record that belongs to the tenant (`Post → User → Tenant`). The developer adds `tenant_id` to `fields:` and `filterable:`, expecting Scrypath to resolve the association. Field-mode projection uses `Map.fetch!` against the struct — if `tenant_id` is not a direct field on `Post`, projection raises `ArgumentError: missing projected field :tenant_id in source record`. This is noisy. The silent variant: developer overrides with `search_document/1` and returns `nil` for `tenant_id` because the association isn't loaded — `nil` is serialized but the filter `tenant_id = 42` never matches `null`.

**How to avoid:**
- Guide: explicitly show how to include `tenant_id` from an association — using `search_document/1` with an explicit preload in the indexing path, or (strongly recommended) denormalizing `tenant_id` as a direct foreign key column on every multi-tenant schema
- Strongly recommend direct `tenant_id` column over multi-hop association walking for tenant isolation

**Warning signs:**
- Schema has `belongs_to :user` but no direct `tenant_id` column
- `search_document/1` references `post.user.tenant_id` without verifying the association is loaded
- Sync raises `ArgumentError` at projection time for tenant field

**Phase to address:**
Guide phase (v1.25 Phase 1) — "association tenant_id" guidance in `guides/multitenancy.md`.

---

### Pitfall 7: Per-Tenant Index Proliferation Degrades Meilisearch Throughput

**Classification: OPERATIONAL — no data leak, progressive throughput degradation**

**What goes wrong:**
A developer reads about `index_prefix:` for environment partitioning and assumes the same pattern works for per-tenant isolation. They create one index per tenant (`posts_tenant_42`, `posts_tenant_99`). With 100+ tenants, Meilisearch's sequential task processing degrades indexing throughput for all tenants — the global task queue is one worker across all indexes.

**How to avoid:**
- Guide: explicit "Why not per-tenant indexes?" section before presenting the shared-index model
- Quote the Meilisearch throughput constraint directly (cited in official multi-tenancy blog post)
- Shared-index + `filterable: [:tenant_id]` is the default. Per-tenant indexes are an explicit opt-out for compliance/regulatory requirements only.

**Warning signs:**
- Index naming convention includes tenant IDs
- Indexing latency increases linearly with tenant count
- `mix scrypath.status` shows a growing global task backlog

**Phase to address:**
Guide phase (v1.25 Phase 1) — position shared-index as the canonical model in the opening sections.

---

### Pitfall 8: Tenant Tokens Used Server-Side Instead of Context Filter Injection

**Classification: OPERATIONAL CONFUSION — no data leak if used correctly, unnecessary overhead if misapplied**

**What goes wrong:**
Meilisearch tenant tokens are designed for browser-direct search (the client hits Meilisearch directly without a server proxy). A developer reads about tenant tokens and generates one per request server-side, then passes it as the API key to Scrypath for each search call. This adds JWT generation to the hot search path and provides no benefit over simple filter injection.

**How to avoid:**
- Guide: clearly separate the two models in a "Which approach for your app?" decision section:
  - Server-side search via Scrypath: use `filter: [tenant_id: id]` context injection
  - Browser-direct search (frontend hits Meilisearch directly): use tenant tokens generated server-side, sent to the browser as a short-lived credential

**Warning signs:**
- JWT generation in the hot search request path on the Elixir side
- `Joken` or a JWT library added to the core app's dependencies for search purposes only

**Phase to address:**
Guide phase (v1.25 Phase 1) — "Tenant tokens: when and when not" section.

---

### Pitfall 9: Process Dictionary for Tenant Context Breaks Across Async Boundaries

**Classification: SILENT — wrong-tenant data in async contexts, HIGH risk**

**What goes wrong:**
Libraries like `Triplex` store the current tenant in the process dictionary (via `Process.put/2`) at the plug layer. If a developer tries to apply this pattern to Scrypath search — storing `tenant_id` in process state and reading it inside a search helper — the tenant context is lost across `Task.async`, LiveView's `assign_async`, and Oban workers. Scrypath's `search_many/2` uses `Task.async_stream` internally for parallel hydration — spawning child processes that don't inherit the caller's process dict.

**Scrypath-specific context:**
Scrypath's `@moduledoc` explicitly states tenant authz is host-owned. But neither the `@moduledoc` nor any guide warns specifically about the process dictionary anti-pattern and why it is dangerous in async contexts. The `guides/composing-real-app-search.md` non-goals section says "no tenant/authz guarantees" without explaining the async boundary failure mode.

**How to avoid:**
- Guide: explicit "Do not use process dictionary for tenant context" warning with async boundary explanation — `Task.async`, `assign_async`, Oban workers do not inherit process state
- Correct model: tenant ID as explicit function argument through the context — immune to process spawning
- Out of scope: Scrypath will never extract tenant from process state

**Warning signs:**
- `Process.put(:current_tenant, ...)` or `Process.get(:current_tenant)` in search-related code
- Using a library like `Triplex` for DB tenant routing and attempting to share the same context with Scrypath calls

**Phase to address:**
Guide phase (v1.25 Phase 1) — anti-pattern section.

---

## Minor Pitfalls

### Pitfall 10: Scope Creep — Automatic Tenant Extraction From conn/Plug Assigns

**Classification: ARCHITECTURAL DEBT — breaks in non-request contexts**

**What goes wrong:**
A developer asks Scrypath to "read the current tenant from the conn" or "extract tenant from plug assigns automatically." If Scrypath were to add such a feature, search calls from Oban workers, admin scripts, or Mix tasks would have no conn to read from — all such callers would need special-casing. The feature would create an implicit coupling between the search layer and the request layer that Scrypath explicitly avoids.

**How to avoid:**
- Guide: state explicitly that Scrypath does not and will not extract tenant context from conn, session, or plug assigns
- Context function is the correct boundary — `search_posts/3` takes tenant as an explicit argument
- This constraint is already in `PROJECT.md` — reinforce it in the guide's out-of-scope section

**Phase to address:**
Guide phase (v1.25 Phase 1) — out-of-scope section.

---

### Pitfall 11: `schema_capabilities/1` Not Reflecting `tenant_field` — Host Cannot Detect Tenant-Aware Schemas

**Classification: TOOLING GAP — not a security issue, but creates incorrect host rendering and coupling**

**What goes wrong:**
After v1.25 ships `tenant_field:` schema declaration, host apps may want to programmatically check whether a schema is tenant-safe before rendering search controls or building context functions. If `schema_capabilities/1` does not surface `tenant_field`, hosts must inspect schema declaration internals directly — coupling themselves to implementation detail.

**Scrypath-specific context:**
`Scrypath.Metadata.Capabilities.schema_capabilities/1` currently reflects `filters`, `sorts`, `facets`, `paging`, and `limits`. No `tenant` key exists. The implementation lives in `lib/scrypath/metadata/capabilities.ex` and is straightforward to extend — adding `tenant: %{field: schema_module.__scrypath__(:tenant_field)}` (or `tenant: nil` when absent) would complete the reflection surface.

**How to avoid:**
- v1.25 Phase 3 delivers `schema_capabilities/1` update to surface `tenant_field` if declared
- Reflection key shape: `tenant: %{field: :tenant_id}` when declared, `tenant: %{field: nil}` or omitted when not

**Phase to address:**
Reflection phase (v1.25 Phase 3 — same phase as `schema_capabilities/1` update, or tightly coupled to Phase 2).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Skip `tenant_field:` option, use raw `filterable: [:tenant_id]` manually | Less migration work | Two separate declarations to keep in sync; forgetting either breaks isolation silently | Acceptable only if schema has thorough tests and `filterable:` discipline is enforced in code review |
| `Keyword.merge([filter: tenant_filter], opts)` (wrong direction) | Works when caller never passes `filter:` | Silent cross-tenant data leak the moment any caller starts passing filters | Never — always use explicit filter concatenation |
| Per-tenant indexes for 2–5 tenants | Hard isolation, no filter needed | Pattern breaks at 20+ tenants; hard to unwind; Meilisearch docs warn explicitly | Only for regulated/compliance scenarios with confirmed < 10 long-term tenants |
| Store tenant in process dict and read in search helper | Ergonomic, avoids threading tenant ID everywhere | Breaks in all async contexts silently; Oban workers, `assign_async`, `search_many/2` hydration | Never — Elixir async boundaries make this categorically unsafe |
| Inject tenant filter via `Composition.fixed:` preset | Feels like the "correct" highest-priority layer | `fixed:` conflict detection fires on valid tenant variation; composition is not the tenant enforcement boundary | Never for security-critical tenant isolation |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| Meilisearch `filterableAttributes` | Declaring `filterable: [:tenant_id]` in schema but not running settings reconciliation | Run `mix scrypath.reconcile` after any schema filterable change; verify with `mix scrypath.settings.diff` |
| Meilisearch filter semantics | Filtering on a field absent from the document returns zero results, not an error | Include `tenant_id` in both `fields:` and `filterable:`; inspect documents post-backfill |
| Meilisearch filter semantics | Filtering on a field not in `filterableAttributes` returns ALL documents, not an error | Apply index settings after schema declaration change before going to production |
| `Scrypath.Composition` | Injecting tenant filter via `fixed:` preset expecting it to survive composition | Inject tenant filter after `to_search_args/1`, not inside composition fragments |
| Oban workers | Using process-dict tenant context from plug layer expecting it to carry into Oban jobs | Pass tenant ID as explicit Oban job arg; read from job args in `perform/1` |
| `Scrypath.search_many/2` | Expecting one tenant filter assembly to cover all schemas in a multi-index call | Each schema entry must have its filter assembled independently — `search_many/2` is per-schema |
| `search_document/1` custom hook | Returning a map without `tenant_id` even though `tenant_field:` is declared | Always include the tenant field explicitly in the custom projection map |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|---|---|---|---|
| Per-tenant Meilisearch indexes | Indexing latency increases with tenant count; global task queue backs up | Shared-index + `filterableAttributes` model; one index per schema, not per tenant | ~20–50 tenants with active writes; Meilisearch docs flag sequential task processing as the bottleneck |
| Server-side tenant token generation per search request | JWT signing adds latency to every search call | Use context filter injection for server-side search; tokens are for client-direct only | Any high-traffic search path |
| Backfill without `tenant_id` in projection | Reindex does not include tenant field; all tenants lose results after reindex | Include `tenant_id` in `fields:` before backfill; verify document content post-backfill | At next backfill or managed reindex cycle |
| Adding `filterableAttributes` to large existing index | Re-running settings triggers Meilisearch re-indexing task on all existing documents | Plan settings changes during low-traffic periods; test with `mix scrypath.settings.diff` drift gates | First time `tenant_id` is added to `filterableAttributes` on a large index with millions of documents |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---|---|---|
| `Keyword.merge` wrong direction drops tenant guard | Cross-tenant document exposure with no error signal | Always use explicit filter concatenation: `tenant_filter ++ caller_filter`; test with a caller that passes its own `filter:` |
| `tenant_id` not in `filterableAttributes` | All documents returned to all tenants — complete isolation failure | `tenant_field:` declaration auto-adds to `filterable:`; run settings reconciliation; verify with `settings.diff` |
| Tenant ID sourced from user-supplied request params without validation | Caller passes arbitrary tenant ID to see other tenants' data | Tenant ID must come from authenticated session/struct, never from unvalidated request params; this is host-app scope |
| Tenant tokens with excessive TTL or weak signing key | Token replay across user sessions | Short TTL (15–60 min); sign with strong API key value; tokens for browser-direct only — not for Scrypath server-side search |
| Admin/operator search path bypasses tenant filter | Unintentional cross-tenant exposure if admin path is reachable from non-admin context | Separate admin search context with explicit no-tenant-scope declaration; never reuse the same context function for admin and tenant-scoped calls |

---

## "Looks Done But Isn't" Checklist

- [ ] **`tenant_field:` declared (or `filterable:` manually includes tenant field):** `Post.__scrypath__(:filterable)` includes the tenant field atom
- [ ] **Live index settings applied:** `mix scrypath.settings.diff` shows no drift for `filterableAttributes` after schema change
- [ ] **Document projection includes tenant field:** Inspect a synced document in Meilisearch; the tenant field key must be present in the document body
- [ ] **Filter merge direction correct:** Context-module test where caller passes `filter: [status: :published]` — resulting search still returns only tenant-owned documents
- [ ] **Async paths tested:** A search dispatched from a background job (Oban worker) uses explicit tenant ID argument, not process dictionary
- [ ] **Composition paths covered:** If `Scrypath.Composition` is used, post-composition tenant filter injection is tested end-to-end
- [ ] **Backfill documents contain tenant field:** After any backfill, sample documents in Meilisearch include the tenant field with non-nil values
- [ ] **`schema_capabilities/1` reflects tenant_field:** `Scrypath.schema_capabilities(Post)` returns a `tenant` key (after v1.25 Phase 3)
- [ ] **No per-tenant index naming:** Index names do not contain tenant IDs at any callsite
- [ ] **Tenant source is authenticated session, not request params:** Context function receives a validated `%Tenant{}` or authenticated `tenant_id`, not a user-controlled string

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Filter merge order bug shipped to production | HIGH | Fix merge direction in all context functions immediately; audit logs for affected time window; consider notifying affected tenants of potential cross-tenant exposure |
| `tenant_id` not in `filterableAttributes` (production) | MEDIUM | Run `mix scrypath.reconcile` to apply settings; Meilisearch re-indexes all documents for the new attribute; filter works after task completes |
| `tenant_id` missing from document projection | MEDIUM–HIGH | Add field to `fields:` and run a full backfill/reindex to re-project all documents; existing documents are wrong until backfill completes |
| Per-tenant index proliferation discovered at scale | HIGH | Design shared-index schema; write migration to re-index all tenant documents into unified index; update all callsites; requires coordinated cutover with downtime risk |
| Process dictionary tenant context broken in async | MEDIUM | Refactor context functions to thread tenant ID as explicit argument; identify all async call paths; test Oban workers and `assign_async` paths independently |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| Filter merge order bug (Pitfall 1) | v1.25 Phase 1 — `guides/multitenancy.md` wrong/correct comparison | Test: context function called with caller-supplied `filter:` opts still returns only tenant-owned documents |
| `tenant_id` not in `filterableAttributes` (Pitfall 2) | v1.25 Phase 2 — `tenant_field:` auto-adds to `filterable:` | `Post.__scrypath__(:filterable)` includes the tenant field; `settings.diff` shows no drift |
| `tenant_id` missing from document projection (Pitfall 3) | v1.25 Phase 2 — `tenant_field:` auto-includes in projection | Backfill a test record; Meilisearch document inspector shows tenant field with correct value |
| Composition bypassing tenant filter (Pitfall 4) | v1.25 Phase 1 — explicit Composition + tenant pattern in guide | Test: `Composition.to_search_args/1` output + tenant injection; search returns only tenant docs |
| Settings not reconciled after `tenant_field:` (Pitfall 5) | v1.25 Phase 2 — guide includes post-declaration reconciliation step | `mix scrypath.settings.diff` shows no drift for tenant field after adding `tenant_field:` |
| Association-based `tenant_id` (Pitfall 6) | v1.25 Phase 1 — association denormalization guidance in guide | Schema has direct `tenant_id` column; no multi-hop association needed for sync |
| Per-tenant index proliferation (Pitfall 7) | v1.25 Phase 1 — "Why not per-tenant indexes?" guide section | Index names contain no tenant IDs; shared-index model used |
| Tenant tokens used server-side (Pitfall 8) | v1.25 Phase 1 — two-model decision tree in guide | No JWT generation in hot search path on server side |
| Process dictionary for tenant context (Pitfall 9) | v1.25 Phase 1 — anti-pattern warning in guide | No `Process.put/get` in search-related code; async test passes correct tenant |
| Scope creep: auto-extraction from conn (Pitfall 10) | v1.25 Phase 1 — out-of-scope declaration in guide | No conn/plug dependency in `Scrypath` core |
| `schema_capabilities/1` not reflecting tenant_field (Pitfall 11) | v1.25 Phase 3 — `schema_capabilities/1` update | `Scrypath.schema_capabilities(Post)` includes `tenant: %{field: :tenant_id}` |

---

## Sources

### PRIMARY (verified against codebase)

- `lib/scrypath/options.ex` — `validate_filterable_fields!/2` raises `ArgumentError` if filter key not in schema's `filterable:` list; gate fires at search time, not at opts merge time
- `lib/scrypath/schema.ex` — `__scrypath__/1` keys confirmed: no `:tenant_field` key today; `filterable:` and `fields:` are independent declarations
- `lib/scrypath/projection.ex` — `build_field_document/2` uses only `fields:` list; no cross-check against `filterable:` for tenant field presence
- `lib/scrypath/composition.ex` + `lib/scrypath/composition/merge.ex` — `fixed:` conflict detection confirmed; `to_search_args/1` outputs only `@search_option_keys`; no tenant-aware composition path exists
- `lib/scrypath/metadata/capabilities.ex` — no `tenant` key in current `schema_capabilities/1` output; extending is straightforward
- `lib/scrypath/meilisearch/settings.ex` — `filterableAttributes` managed via settings apply pipeline; no automatic reconciliation triggered by schema declaration change
- `guides/composing-real-app-search.md` — confirms "no tenant/authz guarantees" in non-goals
- `lib/scrypath.ex` — `@moduledoc` explicitly states tenant authz is host-owned

### PRIMARY (official Meilisearch documentation)

- `meilisearch.com/blog/multi-tenancy-guide` — shared-index recommended over per-tenant; sequential task processing throughput constraint cited explicitly
- `specs.meilisearch.dev/specifications/text/0123-filterable-attributes-setting-api.html` — filtering on non-filterable field silently returns all documents; SILENT failure mode confirmed
- `meilisearch.com/docs/learn/security/tenant_tokens` — tenant tokens for client-direct search only; not for server-side filter injection

### SECONDARY (community patterns and prior research)

- `curiosum.com/blog/multitenancy-in-elixir` — process dictionary anti-pattern, async boundary loss confirmed
- `.planning/research/auth-01-tenant-research.md` — footguns section extended and given prevention strategy and phase mapping in this file

---

*Pitfalls research for: Scrypath v1.25 tenant-safe search (AUTH-01)*
*Researched: 2026-05-25*
