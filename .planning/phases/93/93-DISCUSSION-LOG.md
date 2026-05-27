# Phase 93: Reflection and Runtime Enforcement - Discussion Log

## Assumptions & Alignment

1. **Introspection (`schema_capabilities/1`):**
   - **Assumption:** We will map the `:tenant` capability key to `schema_module.__scrypath__(:tenant_field)` inside `Scrypath.Metadata.Capabilities.schema_capabilities/1`.
   - **Evidence:** `lib/scrypath/metadata/capabilities.ex` constructs the capability map. `lib/scrypath/schema.ex` exposes the schema declaration via `def __scrypath__(:tenant_field)` (shipped in Phase 92).
   - **Status:** Aligned.

2. **Runtime Options Parsing:**
   - **Assumption:** We will add `tenant_scope: [type: :any, default: nil]` to `@search_options` in `Scrypath.Options`.
   - **Evidence:** `Scrypath.Search.search/3` delegates to `Scrypath.Options.validate_search_options/2`. Any undeclared option triggers a NimbleOptions validation failure.
   - **Status:** Aligned.

3. **Hard-injected Filter Combination:**
   - **Assumption:** We will prepend `[{tenant_field, tenant_scope_value}]` to the caller's normalized `filter:` keyword list inside `Scrypath.Options.validate_search_options/2`.
   - **Evidence:** `translate_filter/1` in `lib/scrypath/meilisearch/query.ex` uses `Enum.flat_map` to flatten the keyword list into a flat array of strings (`["tenant_id = GOOD", "tenant_id = MALICIOUS"]`). Meilisearch strictly ANDs these array elements. If a caller attempts to shadow the tenant guard by passing their own filter for the tenant field, it evaluates as `tenant_id = GOOD AND tenant_id = MALICIOUS`, safely yielding 0 results. No manual deep-tree rewriting is needed.
   - **Status:** Aligned.

4. **Undeclared Tenant Field:**
   - **Assumption:** Supplying `tenant_scope:` when the schema's declared `tenant_field:` is `nil` will raise an `ArgumentError` during option validation.
   - **Evidence:** The ROADMAP explicitly mandates this "does not silently fail". Raising matches existing structural validations in `Scrypath.Options`.
   - **Status:** Aligned.

## Resolution
The implementation approach is fully aligned. We are ready to proceed to Phase 93 Planning.
