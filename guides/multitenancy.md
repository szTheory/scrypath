# Multitenancy

This guide is for the Phoenix or Ecto team that needs to implement safe, isolated search in a SaaS application.

**How do we guarantee that Tenant A can never search Tenant B's data?**

The short version is simple:

**Tenant isolation is a filter parameter explicitly passed by your context layer.**

If you remember one thing from this guide, make it this:

**The context layer must explicitly inject the tenant `filter:` before passing the query to Scrypath.**

## 1. The shared-index model

Scrypath uses a **shared-index model** by default. All tenants' records for a given schema live in the same Meilisearch index.

We do not use per-tenant indexes (e.g., `tenant_a_posts`, `tenant_b_posts`) by default. The reason is throughput: Meilisearch processes indexing tasks sequentially. If N tenants share one index, your indexing throughput scales at $O(1)$. If you create N separate indexes, you will face $O(N)$ write contention and task queue bottlenecks at scale. A shared index with a strong tenant filter is the standard, high-throughput path.

## 2. The correct pattern: explicit tenant parameter

The safest way to enforce tenant isolation is to make the tenant ID a required, explicit parameter in your context boundary.

```elixir
defmodule MyApp.Blog do
  alias MyApp.Blog.Post

  # The context function requires the tenant_id explicitly.
  def search_posts_for_tenant(query, tenant_id, opts \\ []) do
    # Merge the tenant filter into the opts BEFORE calling Scrypath
    # (See the footgun section below for why we don't use Keyword.merge)
    safe_filter = [tenant_id: tenant_id] ++ Keyword.get(opts, :filter, [])
    safe_opts = Keyword.put(opts, :filter, safe_filter)

    Scrypath.search(Post, query, safe_opts)
  end
end
```

The schema declares the `tenant_field:` alongside it:

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    tenant_field: :tenant_id
end
```

**Never** extract the tenant ID implicitly from the `conn`, Plug assigns, or the process dictionary inside the search call. Why? Because asynchronous work like `Task.async`, LiveView's `assign_async`, and Oban workers do not inherit process dictionary values or Plug assigns. Explicit parameters survive process boundaries; implicit state does not.

## 3. The filter merge order footgun

When you merge a tenant filter with user-provided filters, you must avoid the single most dangerous data-leak footgun in Elixir multitenancy: `Keyword.merge/2`.

`Keyword` lists in Elixir allow duplicate keys, but `Keyword.merge/2` resolves duplicate keys by letting the **last key win** and silently dropping the first one. Because Scrypath's filters are grouped under a single `:filter` key, merging them incorrectly deletes the tenant boundary.

### ❌ Wrong — tenant filter silently dropped

```elixir
# DANGER: Data leak!
def unsafe_search(query, tenant_id, user_opts) do
  # If user_opts is [filter: [status: "published"]],
  # Keyword.merge silently drops the [filter: [tenant_id: tenant_id]]!
  bad_opts = Keyword.merge([filter: [tenant_id: tenant_id]], user_opts)

  # Scrypath receives ONLY [filter: [status: "published"]]
  # Tenant A just searched all published posts across all tenants.
  Scrypath.search(Post, query, bad_opts)
end
```

No error is raised. The results just silently include other tenants' data.

### ✅ Correct — explicit AND-combination

Instead of merging the outer `:filter` keyword, you must concatenate the inner filter lists. This creates an explicit AND-combination of the tenant ID and any user filters.

```elixir
def safe_search(query, tenant_id, user_opts) do
  user_filter = Keyword.get(user_opts, :filter, [])
  
  # Concatenate the inner lists. 
  # This results in: [tenant_id: 42, status: "published"]
  combined_filter = [tenant_id: tenant_id] ++ user_filter
  
  safe_opts = Keyword.put(user_opts, :filter, combined_filter)

  Scrypath.search(Post, query, safe_opts)
end
```

## 4. Meilisearch tenant tokens

Meilisearch offers a feature called "tenant tokens." It is crucial to understand when to use them and when not to.

Tenant tokens are designed for **browser-direct search**. This is when your frontend (e.g., a React SPA) makes HTTP requests directly to the Meilisearch server, bypassing your Phoenix backend entirely. In that architecture, the token contains the embedded tenant filter.

**Server-side Scrypath search does NOT use tenant tokens.** When your Phoenix context calls `Scrypath.search/3`, it uses the admin or search API key and relies on the explicit `filter:` parameter we built above.

If you are building a browser-direct integration, you will need to generate a tenant token using a library like Joken. A Joken recipe for token generation belongs in the host app, not in Scrypath.

## 5. The `search_document/1` custom hook edge case

When you declare a `tenant_field:` but also write a custom `search_document/1` hook, what happens if you forget to include the tenant ID in the returned map?

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :tenant_id],
    tenant_field: :tenant_id

  # Oops! We forgot to include tenant_id in the custom projection.
  def search_document(post) do
    %{title: String.upcase(post.title)}
  end
end
```

If the document were indexed without the tenant field, a query filtering by `[tenant_id: 42]` would return zero results for that document, creating a silent failure.

To prevent this, Scrypath guarantees **compile-time and run-time safety**. 
First, if the `tenant_field` is missing from `fields:`, a compile-time warning is emitted and it is auto-injected. 
Second, Scrypath runs a **post-hook merge**: even if your `search_document/1` omits the tenant field, Scrypath automatically injects it from the source record after the hook returns. "Declare once, it works correctly."

If your `search_document/1` already includes the tenant field, the post-hook merge is a safe no-op and will not overwrite your explicit value.

## 6. Schema declaration reference

Here is a complete schema demonstrating the required declarations for a multitenant resource.

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body, :tenant_id],
    filterable: [:tenant_id, :status],
    tenant_field: :tenant_id
end
```

- `fields:` must include the tenant field (or Scrypath will emit an IO warning and auto-inject it).
- `filterable:` must include the tenant field so Meilisearch accepts it in queries.
- `tenant_field:` declares the attribute explicitly, enabling the safety guarantees discussed in this guide.
