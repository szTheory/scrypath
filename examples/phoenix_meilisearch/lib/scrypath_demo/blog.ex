defmodule ScrypathDemo.Blog do
  @moduledoc """
  Context module for the related-data fan-out demo.

  Two responsibilities (D-05 — context owns the decision, library owns execution):

  1. `update_author/3` — persists an Author rename, keeps the denormalized
     `posts.author_name` column in sync (D-15, app-owned, explicit, ordered BEFORE
     the fan-out), then invokes the explicit fan-out via `Scrypath.sync_related/3`.
     This is an explicit context call — NOT an Ecto callback (D-05).

  2. `resolve_posts_for_authors/1` — the resolver MFA registered in
     `ScrypathDemo.Blog.Author.__scrypath__(:fan_outs)`. It handles BOTH arities:
     - `:inline` path passes Author structs (`[%Author{} | _]`).
     - `:oban` path passes Author document IDs (`[_id | _]`), round-tripped through JSON.
     Both clauses funnel to a reload-by-`author_id` query (D-15 flat reload).
  """

  import Ecto.Query

  alias ScrypathDemo.Repo
  alias ScrypathDemo.Blog.Author
  alias ScrypathDemo.Blog.Post

  @search_param_keys ["q", "category"]
  @facet_param_keys ["facet_query"]

  @doc """
  Searches published posts for an already-authenticated synthetic host principal.

  The principal's persisted membership is the only source of tenant scope. `params`
  contains ordinary, allowlisted search inputs; `runtime_opts` is a separate
  server-owned configuration argument.
  """
  def search_posts(principal, selected_tenant_id, params, runtime_opts) do
    with {:ok, tenant_id} <- authorized_tenant(principal, selected_tenant_id),
         {:ok, normalized} <- validate_params(params, @search_param_keys),
         true <- valid_runtime_opts?(runtime_opts) do
      query = Map.get(normalized, "q", "")
      category = Map.get(normalized, "category")

      filter =
        [status: "published"]
        |> maybe_add_filter(:category, category)

      options =
        runtime_opts
        |> Keyword.delete(:repo)
        |> Keyword.merge(
          tenant_scope: tenant_id,
          filter: filter,
          facets: [:category],
          page: [number: 1, size: 20]
        )

      with {:ok, result} <- Scrypath.search(Post, query, options) do
        {:ok, %{records: hydrate_tenant_hits(result, tenant_id)}}
      end
    else
      false -> {:error, :invalid_search_input}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Looks up published category facet values for an authorized synthetic host principal.
  """
  def search_post_categories(principal, selected_tenant_id, params, runtime_opts) do
    with {:ok, tenant_id} <- authorized_tenant(principal, selected_tenant_id),
         {:ok, normalized} <- validate_params(params, @facet_param_keys),
         true <- valid_runtime_opts?(runtime_opts),
         facet_query when is_binary(facet_query) <- Map.get(normalized, "facet_query") do
      options =
        runtime_opts
        |> Keyword.delete(:repo)
        |> Keyword.merge(tenant_scope: tenant_id, filter: [status: "published"])

      with {:ok, result} <- Scrypath.search_facet_values(Post, "category", facet_query, options) do
        {:ok, safe_category_facets(result, tenant_id)}
      end
    else
      false -> {:error, :invalid_search_input}
      {:error, _reason} = error -> error
      _ -> {:error, :invalid_search_input}
    end
  end

  @doc """
  Creates a post for a tenant the persisted principal belongs to.

  `tenant_id` is selected by the trusted caller context and is never accepted
  from the post attributes.
  """
  def create_post(principal, selected_tenant_id, attrs) when is_map(attrs) do
    with {:ok, tenant_id} <- authorized_tenant(principal, selected_tenant_id) do
      %Post{tenant_id: tenant_id}
      |> Post.changeset(attrs)
      |> Repo.insert()
    end
  end

  def create_post(_principal, _selected_tenant_id, _attrs),
    do: {:error, :invalid_post_input}

  defp authorized_tenant(%{id: actor_id}, tenant_id)
       when is_integer(actor_id) and actor_id > 0 and is_integer(tenant_id) and tenant_id > 0 do
    membership_tenant =
      Repo.one(
        from(actor in "host_actors",
          join: membership in "host_memberships",
          on: field(membership, :actor_id) == field(actor, :id),
          where:
            field(actor, :id) == ^actor_id and
              field(membership, :tenant_id) == ^tenant_id,
          select: field(membership, :tenant_id)
        )
      )

    case membership_tenant do
      authorized when is_integer(authorized) -> {:ok, authorized}
      _ -> {:error, :unauthorized}
    end
  end

  defp authorized_tenant(_principal, _tenant_id), do: {:error, :unauthorized}

  defp validate_params(params, allowed_keys) when is_map(params) do
    allowed = MapSet.new(allowed_keys)

    with true <-
           Enum.all?(params, fn {key, value} ->
             is_binary(key) and MapSet.member?(allowed, key) and is_binary(value)
           end) do
      {:ok, params}
    else
      _ -> {:error, :invalid_search_input}
    end
  end

  defp validate_params(_params, _allowed_keys), do: {:error, :invalid_search_input}

  defp valid_runtime_opts?(opts), do: Keyword.keyword?(opts)

  defp maybe_add_filter(filters, _field, nil), do: filters
  defp maybe_add_filter(filters, field, value), do: Keyword.put(filters, field, value)

  defp hydrate_tenant_hits(result, tenant_id) do
    hit_ids = Enum.map(result.hits, &hit_id/1)

    records_by_id =
      Repo.all(
        from(post in Post,
          where:
            post.tenant_id == ^tenant_id and post.status == "published" and post.id in ^hit_ids
        )
      )
      |> Map.new(&{to_string(&1.id), &1})

    Enum.flat_map(hit_ids, fn id ->
      case Map.fetch(records_by_id, to_string(id)) do
        {:ok, record} -> [record]
        :error -> []
      end
    end)
  end

  defp safe_category_facets(result, tenant_id) do
    candidates = Enum.map(result.hits, & &1.value)

    counts_by_category =
      Repo.all(
        from(post in Post,
          where:
            post.tenant_id == ^tenant_id and post.status == "published" and
              post.category in ^candidates,
          group_by: post.category,
          select: {post.category, count(post.id)}
        )
      )
      |> Map.new()

    hits =
      Enum.flat_map(result.hits, fn hit ->
        case Map.fetch(counts_by_category, hit.value) do
          {:ok, count} -> [%{value: hit.value, count: count}]
          :error -> []
        end
      end)

    %{facet_query: result.facet_query, hits: hits}
  end

  defp hit_id(%{} = hit), do: Map.get(hit, "id") || Map.get(hit, :id)

  @doc """
  Persists an Author rename, syncs the denormalized `author_name` on related Posts,
  then fans out the Post re-sync via `Scrypath.sync_related/3`.

  `sync_opts` is passed through to `Scrypath.sync_related/3` after prepending
  `fan_out: :posts`. Use `sync_mode: :inline` or `sync_mode: :oban` to select the
  execution path.

  Returns `{:ok, sync_result, updated_author}` on success so callers can assert
  both the fan-out outcome shape (`%{mode:, status:}`) and the updated author.
  Propagates errors from Repo or Scrypath on failure.
  """
  def update_author(%Author{} = author, attrs, sync_opts) do
    {:ok, updated} = author |> Author.changeset(attrs) |> Repo.update()

    # (D-15) keep denormalized projection in sync — APP-OWNED, explicit, ordered BEFORE fan-out.
    from(p in Post, where: p.author_id == ^updated.id)
    |> Repo.update_all(set: [author_name: updated.name])

    # explicit fan-out the context invokes (D-05) — not a callback.
    {:ok, result} =
      Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

    {:ok, result, updated}
  end

  @doc """
  Resolver for the `posts` fan-out declared on `ScrypathDemo.Blog.Author`.

  Handles both arities that `Scrypath.sync_related/3` may invoke depending on `sync_mode`:
  - `:inline` passes a list of Author structs — map to IDs, then reload Posts.
  - `:oban` passes a list of Author document IDs (integers) — reload Posts directly.
  - Empty list — returns `[]` immediately.
  """
  def resolve_posts_for_authors([%Author{} | _] = authors),
    do: authors |> Enum.map(& &1.id) |> reload_posts()

  def resolve_posts_for_authors([_id | _] = author_ids), do: reload_posts(author_ids)

  def resolve_posts_for_authors([]), do: []

  defp reload_posts(author_ids),
    do: Repo.all(from(p in Post, where: p.author_id in ^author_ids))
end
