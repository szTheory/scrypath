# Saved search storage

ScrypathOps stores saved searches in the host application's database, in a
**`scrypath_ops_saved_searches`** table in the Repo passed to **`scrypath_ops_routes/2`**.
Operators never choose or see a storage location; saving, renaming, duplicating and deleting
work the same in development, releases, containers and multi-node deploys.

## Install the table

Generate a migration in the host app and call **`ScrypathOps.Migration`** from it:

```elixir
defmodule MyApp.Repo.Migrations.AddScrypathOps do
  use Ecto.Migration

  def up, do: ScrypathOps.Migration.up(version: 1)
  def down, do: ScrypathOps.Migration.down(version: 1)
end
```

The migration is versioned like **`Oban.Migration`**: a later release that changes the table ships
a new version, and you add another one-line migration that calls **`up(version: N)`**. The applied
version is recorded as a comment on the table, so running a version twice is a no-op.

To keep the table outside the Repo's default Postgres schema, create the schema first and pass the
same **`prefix:`** to the migration and to **`scrypath_ops_routes/2`**.

If the Repo's **`prepare_query/3`** callback requires an option such as a tenant id, let queries on
tables whose names start with **`scrypath_ops_`** through, as you would for **`oban_`** tables.

## Table layout

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `bigserial` | Primary key. |
| `name` | `text` | Unique, up to 120 characters, no control characters. Identifies the saved search in the UI. |
| `schema` | `text` | The target schema of a `"search"` definition, or the comma-joined targets of a `"search_many"` definition, for listing. |
| `definition` | `jsonb` | The v1 saved-search document (see **[saved-search-schema-v1.md](saved-search-schema-v1.md)**), validated before every write. |
| `inserted_at`, `updated_at` | `timestamp` | UTC, microsecond precision. |

Saved searches are shared by everyone who can open the operator UI; there is no per-user
ownership. **`ScrypathOps.SavedSearches`** is the only writer.

## Import, export and review

The v1 JSON document is the interchange format. Import accepts existing v1 files unchanged
(including files saved by earlier releases), and the stored **`definition`** is the same document,
so exporting and importing round-trips.

- Treat shared saved-search JSON like **config**: keep reviewed copies in git and import them into
  each environment.
- **Secrets do not belong in saved searches.** The codec rejects secret-shaped keys under **`opts`**
  (see **`saved-search-schema-v1.md`** — *Banned / secret keys*). Still assume **git history**
  is long-lived: never commit keys “temporarily”, even if validation would catch some shapes.

## CI validation

Validate a directory of saved-search JSON files **without Meilisearch** or **`mix test`** coupling:

```bash
cd scrypath_ops
mix scrypath_ops.saved_searches.validate /path/to/saved_searches
```

The task reads **only** eligible **`*.json`** files **non-recursively** and runs
**`ScrypathOps.SavedSearches.V1.decode/1`** then **`validate/1`**. In-repo examples live under
**`examples/saved_searches/`** (see **`mix scrypath_ops.saved_searches.validate examples/saved_searches`**).

## Further reading

- **[saved-search-schema-v1.md](saved-search-schema-v1.md)** — normative wire format, caps, banned keys.
- **[operator-ia.md](operator-ia.md)** — navigation and adoption; **securing `/ops`** is a **host** concern (see *Securing `/ops`* there).
