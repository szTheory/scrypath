defmodule ScrypathDemo.Blog.Author do
  @moduledoc """
  Owning schema for the related-data fan-out demo.

  `Author` is NOT itself a searchable Scrypath target — it is the *owning* schema
  that declares a `fan_outs:` entry pointing at the searchable `Post`. The shipped
  library reads two reflection keys off the owning schema:

    * `__scrypath__(:fan_outs)` — consumed by `Scrypath.sync_related/3`
      (`lib/scrypath/sync.ex`) and the internal `Scrypath.Sync.RelatedWorker`.
    * `__scrypath__(:document_id)` — used by `Scrypath.Identity.document_ids/2`
      when the `:oban` fan-out path enqueues only the owning document IDs.

  These accessors are declared by hand (the same pattern the library's own fan-out
  tests use — see `test/scrypath/sync/related_test.exs` and
  `test/scrypath/sync/related_worker_test.exs`) rather than through
  `use Scrypath, fan_outs: ...`. The shipped `use Scrypath` declaration macro does
  not yet resolve module aliases in `fan_outs:` at macro-expansion time, and it does
  not generate a `__scrypath__(:fan_outs)` accessor, so the hand-written reflection
  is the correct, library-respecting (read-only) declaration path for the example.
  """
  use Ecto.Schema

  schema "authors" do
    field(:name, :string)
    has_many(:posts, ScrypathDemo.Blog.Post)
    timestamps(type: :utc_datetime)
  end

  # Owning-side fan_outs: declaration consumed by Scrypath.sync_related/3 (D-02).
  # The resolver MFA points at the Blog context and must handle BOTH arities
  # (inline -> Author records, oban -> author IDs).
  def __scrypath__(:fan_outs) do
    [
      posts: [
        target: ScrypathDemo.Blog.Post,
        resolver: {ScrypathDemo.Blog, :resolve_posts_for_authors, []}
      ]
    ]
  end

  # Used by the :oban fan-out enqueue path (Scrypath.Identity.document_ids/2).
  def __scrypath__(:document_id), do: :id

  def changeset(author, attrs) do
    author
    |> Ecto.Changeset.cast(attrs, [:name])
    |> Ecto.Changeset.validate_required([:name])
  end
end
