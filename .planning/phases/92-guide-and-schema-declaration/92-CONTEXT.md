# Phase 92: Guide and Schema Declaration - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 92 delivers two co-shipped artifacts:
1. `guides/multitenancy.md` — canonical multitenancy guide covering the shared-index + filter-injection model, the filter merge order footgun, per-tenant index anti-pattern, tenant token placement, and the `search_document/1` edge case (TNNT-01)
2. `tenant_field:` schema option — a single declaration that auto-injects the named field into both `filterable:` and `fields:` (if not already present) and ensures it appears in synced document projections including when `search_document/1` is used (TNNT-02)

Phase 92 does NOT include: `schema_capabilities/1` reflection (Phase 93), `tenant_scope:` runtime enforcement (Phase 93), or the hermetic verify gate (Phase 94).

</domain>

<decisions>
## Implementation Decisions

### tenant_field: + fields: auto-injection

- **D-01:** `tenant_field: :tenant_id` auto-adds `:tenant_id` to `fields:` at compile time if it is not already present. The merge is idempotent — if `:tenant_id` is already in `fields:`, no-op, no warning.
- **D-02:** When auto-injection occurs (field NOT already in `fields:`), emit `IO.warn/2` (not `IO.puts`) at compile time with a message explaining the auto-addition and telling the developer how to silence it (add the field explicitly to `fields:`). `IO.warn/2` is the correct Elixir mechanism for "we did something on your behalf at compile time — here's what and how to silence it."
- **D-03:** `tenant_field:` also auto-adds the named field to `filterable:` (idempotent — no-op if already present). This is the primary purpose: marking the field as filterable for Meilisearch index settings.
- **D-04:** Implementation goes in `lib/scrypath/options.ex` `validate_schema_options!/1` as a normalization pass AFTER NimbleOptions validation. Deduplicate both `fields:` and `filterable:` lists preserving original order using the same dedup helper already present in `options.ex`.

### search_document/1 + tenant_field: — Scrypath owns the guarantee

- **D-05:** When `tenant_field:` is declared AND the schema exports `search_document/1`, `Scrypath.Projection` performs a post-hook merge: after calling `schema_module.search_document(record)` to get the projected map, it ensures the tenant field is present in `Document.data` by pulling its value from the source record. If the custom hook already included the tenant field, the merge is a no-op (key already present → no overwrite).
- **D-06:** This post-hook merge ensures the library's "declare once, it works correctly" contract holds regardless of whether the developer's `search_document/1` remembered to include the tenant field. A missing tenant field in the indexed document returns empty results for the entire tenant with no error — this is a silent data-leak failure mode that cannot be left to a guide warning.
- **D-07:** The projection module must check `schema_module.__scrypath__(:config)` (or a new `__scrypath__(:tenant_field)` accessor added in Schema) to know whether a tenant field is declared. Add `def __scrypath__(:tenant_field)` to `lib/scrypath/schema.ex` alongside the other accessors.

### Guide narrative structure and filter footgun examples

- **D-08:** The multitenancy guide uses a **correct-pattern-first** structure: show the recommended shared-index + filter-injection pattern upfront, then introduce the footgun as a "common mistake to avoid" section with explicit `## Wrong` / `## Correct` code examples. Developers reading the guide to implement from scratch see the right way first.
- **D-09:** Filter footgun examples use ONLY the context-layer pattern (explicit filter construction). Phase 92 ships without `tenant_scope:` — that is Phase 93. The guide does NOT forward-reference `tenant_scope:` or pre-announce Phase 93. The guide is accurate at ship time; Phase 93 additions get their own subsection when they land.
- **D-10:** The wrong pattern must be labeled prominently (e.g., `## ❌ Wrong — tenant filter silently dropped`) and the `Keyword.merge` last-key-wins behavior explained inline. The correct pattern shows explicit `AND`-combination in the context layer.
- **D-11:** The guide's filter composition example shows the context as the enforcement boundary — tenant ID is an explicit parameter, never extracted from conn/plug assigns/process dictionary. Async safety (Task.async, assign_async, Oban) is called out explicitly as the reason.

### Guide scope and ExDoc registration

- **D-12:** Guide sections to include (all required per TNNT-01):
  1. Overview of shared-index model + why per-tenant indexes are not the default (Meilisearch sequential task processing throughput reason)
  2. The correct context-layer pattern with explicit tenant parameter
  3. Filter merge order footgun (wrong/correct code examples)
  4. Meilisearch tenant token guidance (browser-direct only, NOT for server-side Scrypath search, Joken recipe link)
  5. The `search_document/1` custom hook edge case (what `tenant_field:` guarantees in projection, what the developer must still do)
  6. Schema declaration example (`use Scrypath` with `tenant_field:`)
- **D-13:** Add `guides/multitenancy.md` to ExDoc `extras:` list and place it in the **Getting Started** `groups_for_extras` group alongside `guides/composing-real-app-search.md` and `guides/related-data-and-reindexing.md`. The guide is relevant to any SaaS app, not Phoenix-specific.

### Claude's Discretion

- Exact wording of `IO.warn` message — follow existing advisory messages in `options.ex` for tone/format
- Exact placement of `guides/multitenancy.md` within the Getting Started group list (after `related-data-and-reindexing.md` is sensible)
- Internal dedup helper naming/reuse — reuse existing pattern in `options.ex`
- Whether to add `__scrypath__(:tenant_field)` or check `__scrypath__(:config).tenant_field` — use whichever is consistent with existing accessor pattern in `schema.ex`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and Roadmap

- `.planning/REQUIREMENTS.md` §v1.25 Requirements — TNNT-01 and TNNT-02 are the locked requirements for this phase; defines guide sections and schema declaration behavior precisely
- `.planning/ROADMAP.md` §Phase 92 — success criteria, phase boundaries, and what Phase 93/94 add (do not implement those here)

### Core Implementation Files

- `lib/scrypath/options.ex` — `@schema_options` NimbleOptions spec; `tenant_field:` option added here; normalization pass for auto-injection goes here
- `lib/scrypath/schema.ex` — `use Scrypath` macro; add `__scrypath__(:tenant_field)` accessor and update `@moduledoc` key list
- `lib/scrypath/projection.ex` — document projection; post-hook tenant field merge for `search_document/1` schemas goes here
- `lib/mix.exs` — ExDoc `extras:` list and `groups_for_extras`; `guides/multitenancy.md` must be registered here

### Existing Guides (for voice/style consistency)

- `guides/phoenix-contexts.md` — canonical context-layer pattern used throughout the project; new guide must be consistent
- `guides/related-data-and-reindexing.md` — most recent guide added; same structure/depth/tone target
- `guides/common-mistakes.md` — wrong/correct example style precedent; follow the same format for the footgun examples

### Project Constraints

- `.planning/PROJECT.md` §Core Value and §Current Milestone — explicit out-of-scope items (no automatic tenant extraction from conn/process dict, no per-tenant index routing as default, no Joken in library core)
- `.planning/STATE.md` §Blockers/Concerns — filter merge order footgun is the #1 silent failure mode; scope discipline for tenant-safe search

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/scrypath/options.ex` `validate_schema_options!/1` — already has a normalization post-pass pattern (see `fan_outs` validation); `tenant_field:` normalization follows the same structure
- Dedup helper already present in `options.ex` for hierarchy expansion — reuse for idempotent merge of `fields:` and `filterable:`
- `lib/scrypath/projection.ex` `build_custom_document/2` — the post-hook merge for `search_document/1` schemas goes here, after the existing custom document logic

### Established Patterns

- `IO.warn/2` advisory pattern: already used in options.ex for soft compile-time advisories (ranking_rules completeness check, settings key normalization)
- `__scrypath__/1` accessor pattern in `schema.ex`: new `:tenant_field` key follows the same `def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field` pattern
- NimbleOptions schema option additions: `fan_outs:` in `@schema_options` is the most recent addition — follow the same doc string + type + default structure

### Integration Points

- `tenant_field:` option is a schema-level declaration — it affects `filterable:` (Meilisearch index settings), `fields:` (document projection), and adds a new reflection key for Phase 93
- The post-hook merge in `Projection` must use the `__scrypath__(:tenant_field)` accessor (nil if not declared) to decide whether to inject
- The guide is standalone but should cross-link to `guides/phoenix-contexts.md` (context pattern) and `guides/sync-modes-and-visibility.md` (sync semantics)

</code_context>

<specifics>
## Specific Ideas

- The filter footgun example must use the actual `Keyword.merge` footgun pattern (not a strawman), showing that `Keyword.merge(base_opts, [filter: tenant_filter])` silently drops a preceding `filter:` in `base_opts` — this is the exact real-world failure mode
- The `IO.warn` message should name the field and explain the action clearly: e.g., `"[scrypath] tenant_field :tenant_id is not listed in fields:. It has been auto-added so search documents include the tenant value. To silence this warning, add :tenant_id to fields: explicitly."`
- For the `search_document/1` edge case section in the guide: show a code example where the custom hook FORGETS the tenant field, then explain that Scrypath still ensures it appears in the indexed document via post-hook merge — this gives adopters confidence the library is safe by default

</specifics>

<deferred>
## Deferred Ideas

- `schema_capabilities/1` reflection for `:tenant` key — Phase 93
- `tenant_scope:` runtime enforcement hard-injecting tenant filter at library level — Phase 93
- `mix verify.phase94` hermetic gate — Phase 94
- Joken tenant token generation helpers in library core — TNNT-FUT-02, explicitly out of scope for the entire project
- Per-tenant Meilisearch index routing — TNNT-FUT-01, explicitly out of scope

</deferred>

---

*Phase: 92-Guide and Schema Declaration*
*Context gathered: 2026-05-25*
