# Multi-index search with Scrypath

This guide shows how to call `Scrypath.search_many/2` from a Phoenix LiveView dashboard that searches several schemas at once, handles **per-schema** filters and facets, and surfaces **partial failures** without pretending hits are merged.

## When to use `search_many/2`

Use `search_many/2` when you explicitly list schemas (for example posts, users, tags, and events) and want one federated Meilisearch round-trip. Do **not** expect a single relevance ordering across schemas: scores stay per index. If you reuse the same `text` for every tuple, that is fine for a unified search bar, but treat ranking as **per-schema**, not comparable across rows.

## Primary example: four-schema LiveView dashboard

Imagine a dashboard mount that assigns four independent searches sharing only `repo` and Meilisearch settings:

```elixir
def mount(_params, _session, socket) do
  shared = [
    repo: MyApp.Repo,
    backend: Scrypath.Meilisearch,
    meilisearch_url: Application.fetch_env!(:my_app, :meilisearch_url)
  ]

  entries = [
    {MyApp.Post, "release", filter: [published: true], page: [size: 8], facets: [:status]},
    {MyApp.User, "release", filter: [active: true], page: [size: 5]},
    {MyApp.Tag, "release", page: [size: 12], facets: [:kind]},
    {MyApp.Event, "conference", filter: [region: [eq: "EU"]], facets: [:region]}
  ]

  case Scrypath.search_many(entries, shared) do
    {:ok, results} ->
      {:ok, assign(socket, multi: results)}

    {:error, reason} ->
      {:ok, put_flash(socket, :error, format_many_error(reason))}
  end
end
```

Render each schema section from `results.ordered` so declaration order matches your UI cards. Read per-schema facets from `elem(result, 1).facets` — never assume facets are merged across schemas. Scrypath intentionally does **not** set Meilisearch `mergeFacets`.

## Secondary recipe: same `q` everywhere with a warning

```elixir
q = socket.assigns.query

Scrypath.search_many(
  [
    {MyApp.Post, q, filter: [published: true]},
    {MyApp.Comment, q, filter: [hidden: false]}
  ],
  repo: MyApp.Repo,
  backend: Scrypath.Meilisearch,
  meilisearch_url: url
)
```

This is convenient for a global search bar, but relevance scores and hit ranks are **not** comparable across `{MyApp.Post, _}` and `{MyApp.Comment, _}`. Keep ranking UI per schema block.

## Partial failures in HEEx

Use a calm, accessible banner with `aria-live="polite"` (not `role="alert"` unless the whole page is blocked). Pair it with `<details>` for operator diagnostics.

```heex
<%= if @multi.failures != [] do %>
  <aside class="banner banner--warning" aria-live="polite">
    <p>Some indexes did not return results.</p>
    <details>
      <summary>Details</summary>
      <ul>
        <%= for %{schema: mod, reason: reason} <- @multi.failures do %>
          <li><%= inspect(mod) %>: <%= user_message(mod, reason) %></li>
        <% end %>
      </ul>
    </details>
  </aside>
<% end %>
```

Define `user_message/2` in your LiveView or a small helper module so you map `:hydration_timeout`, transport errors, and validation failures to human copy without echoing raw exception blobs.

## Duplicate schema in one call

`results.by_schema` is a map and therefore **last-wins** if the same schema appears twice. Always iterate `results.ordered` when you need both result sets (for example A/B facet layouts):

```elixir
for {schema, result} <- results.ordered do
  # safe for duplicate schema modules
end
```

## Cross-links

- [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md) — single-schema facet UX patterns.
- [Sync modes and visibility](sync-modes-and-visibility.md) — eventual consistency and what “searchable” means after writes.

## Anti-patterns

- **Merged hits illusion** — do not interleave `results.ordered` hits as if they were one index; federation preserves per-schema boundaries.
- **`mergeFacets`** — Scrypath never sends this flag; cross-schema facet blobs hide which schema failed validation.
- **Silent truncation** — cardinality limits (`max_schemas`, `page.size`, federation limits) return `{:error, _}` instead of clamping quietly.

## `%Scrypath.MultiSearchResult{}`

Public fields include `ordered`, `by_schema`, `failures`, and optional `federation` metadata from Meilisearch. Failures are maps `%{schema: module(), reason: term()}`; successful schemas are absent from `failures` and present in `ordered`.
