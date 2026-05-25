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

  @doc """
  Persists an Author rename, syncs the denormalized `author_name` on related Posts,
  then fans out the Post re-sync via `Scrypath.sync_related/3`.

  `sync_opts` is passed through to `Scrypath.sync_related/3` after prepending
  `fan_out: :posts`. Use `sync_mode: :inline` or `sync_mode: :oban` to select the
  execution path.

  Returns `{:ok, updated_author}` on success, or propagates errors from Repo/Scrypath.
  """
  def update_author(%Author{} = author, attrs, sync_opts) do
    {:ok, updated} = author |> Author.changeset(attrs) |> Repo.update()

    # (D-15) keep denormalized projection in sync — APP-OWNED, explicit, ordered BEFORE fan-out.
    from(p in Post, where: p.author_id == ^updated.id)
    |> Repo.update_all(set: [author_name: updated.name])

    # explicit fan-out the context invokes (D-05) — not a callback.
    {:ok, _result} =
      Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

    {:ok, updated}
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
