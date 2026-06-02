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

  These accessors are declared by hand because this example keeps `Author` out of
  the searchable-schema declaration path. Ordinary schemas can declare the same
  metadata with `use Scrypath, fan_outs: ...`; hand-written accessors remain a
  supported low-level shape for owning schemas that only participate in fan-out.
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
