# Common integration mistakes

These pitfalls tie common symptoms to the mental model that usually causes them, a fix pattern, and the guide that owns the full rule.

## How to use this page

Skim the headings for a match to your symptom, read the **Wrong model** line to sanity-check assumptions, then follow the **Authority** link for the full rules rather than duplicating them here.

## Treating search visibility as “same transaction” as the database

**Symptom:** A record insert or update succeeds, but `Scrypath.search/3` does not return the row you just wrote—or returns stale data—so you assume the library “lost” the document.

**Wrong model:** Search indexes are updated on a separate path from your Ecto transaction commit; “accepted work” is not the same thing as “searchable right now,” especially with `:inline`, `:oban`, or `:manual` sync.

**Fix pattern:** Decide which sync mode you run, then read the lifecycle language for that mode before branching application code on search results.

**Authority:** See [Sync modes and visibility](sync-modes-and-visibility.md) for the authoritative semantics.

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
