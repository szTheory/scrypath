# Common integration mistakes

These pitfalls tie common symptoms to the mental model that usually causes them, a fix pattern, and the guide that owns the full rule.

## How to use this page

Skim the headings for a match to your symptom, read the **Wrong model** line to sanity-check assumptions, then follow the **Authority** link for the full rules rather than duplicating them here.

## Treating search visibility as “same transaction” as the database

**Symptom:** A record insert or update succeeds, but `Scrypath.search/3` does not return the row you just wrote—or returns stale data—so you assume the library “lost” the document.

**Wrong model:** Search indexes are updated on a separate path from your Ecto transaction commit; “accepted work” is not the same thing as “searchable right now,” especially with `:inline`, `:oban`, or `:manual` sync.

**Fix pattern:** Decide which sync mode you run, then read the lifecycle language for that mode before branching application code on search results.

**Authority:** See [Sync modes and visibility](sync-modes-and-visibility.md) for the authoritative semantics.

## Treating Meilisearch as the business source of truth

**Symptom:** A user can find a record in search that should be hidden, deleted, or outside their tenant; or the UI trusts search-hit fields that no longer match the database.

**Wrong model:** The search document is treated like the authoritative record instead of a denormalized projection.

**Fix pattern:** Keep sensitive authorization checks in the database path, index only safe display fields, and hydrate records from the repo when visibility matters. Rebuild from source data when projection drift is broad.

**Authority:** [Meilisearch concepts](meilisearch-concepts.md) for the projection model, then [Drift recovery](drift-recovery.md) for repair paths.

## Changing filterable or sortable fields after the import

**Symptom:** A filter or sort option works in the UI code but fails, behaves oddly, or requires a long backend operation after deployment.

**Wrong model:** Meilisearch settings are treated like harmless display preferences.

**Fix pattern:** Declare settings in code, apply them before import, and treat index-contract changes as migration/reindex work. Use settings diff and managed reindex instead of patching broad settings casually in production.

**Authority:** [Relevance tuning](relevance-tuning.md).

## Indexing documents that are too large or too private

**Symptom:** Search responses are slow or bloated, indexing uses more memory than expected, or fields appear in search results that should have stayed server-only.

**Wrong model:** The indexed document is a copy of the Ecto struct or rendered page.

**Fix pattern:** Index a lean search card: stable ID, searchable text, safe display fields, and the filter/sort fields Meilisearch needs. Leave private or frequently-changing business state in Postgres.

**Authority:** [Meilisearch concepts](meilisearch-concepts.md).

## Producing one Meilisearch task for every tiny event

**Symptom:** `/tasks` shows a growing queue, failed tasks pile up, or search freshness falls behind even though each individual write is small.

**Wrong model:** Async indexing removes the cost of high-churn updates.

**Fix pattern:** Batch, debounce, or omit fields that do not affect search quality. Avoid syncing page views, counters, and inventory ticks one record at a time unless the product really needs that freshness.

**Authority:** [Meilisearch operations](meilisearch-operations.md) and [Search backend operations](../docs/search-backend-sre.md).

## Rebuilding directly into the live index

**Symptom:** Users see partial results or empty search during a repair, import, or settings change.

**Wrong model:** A full rebuild is just a larger backfill.

**Fix pattern:** Use managed reindex semantics: create a target index, apply settings, backfill it, verify counts and searches, then cut over deliberately. Use `cutover?: false` when the target needs inspection first.

**Authority:** [Drift recovery](drift-recovery.md) and [Meilisearch operations](meilisearch-operations.md).

## Federating `search_many/2` without reading the multi-index rules

**Symptom:** `{:error, {:invalid_options, _}}` (or related option errors) when combining `global_schemas`, federation weights, or `:all` expansion—often after copying options from a single-index example.

**Wrong model:** Treating federation and `:all` as “just more indexes” instead of a constrained composition with preflight validation.

**Fix pattern:** Start from the multi-index guide’s rules for allowed combinations, then align options with the documented shapes before retrying.

**Authority:** [Multi-index search](multi-index-search.md).

## Expecting `search/3` to guess a schema you never declared with `use Scrypath`

**Symptom:** `{:error, _}` paths that mention an unknown or unregistered schema module, or confusion about why a module is “not searchable,” even though Ecto can load the struct.

**Wrong model:** Any `Ecto.Schema` is automatically indexed and searchable without the Scrypath declaration layer.

**Fix pattern:** Ensure the schema uses `use Scrypath` with the intended fields and that your app registers the index name you pass to `search/3`.

**Authority:** [Getting started](getting-started.md) for the configuration mental model, then [Sync modes and visibility](sync-modes-and-visibility.md) for how sync attaches to writes.
