defmodule Scrypath.TestSupport.LoaderBackfill.Migration do
  @moduledoc false

  # Portable DDL for the shared loader/backfill cases. Runs unchanged on
  # SQLite and Postgres; composite keys use `primary_key: false` on the table
  # plus `primary_key: true` on each key column.

  use Ecto.Migration

  def change do
    create table(:lb_posts) do
      add(:title, :string)
    end

    create table(:lb_categories) do
      add(:name, :string)
    end

    create table(:lb_products) do
      add(:title, :string)
      add(:category_id, references(:lb_categories))
    end

    create table(:lb_articles) do
      add(:title, :string)
      add(:region, :string)
      add(:published, :boolean)
      add(:pinned, :boolean)
    end

    create table(:lb_memberships, primary_key: false) do
      add(:org_id, :integer, primary_key: true)
      add(:seq, :integer, primary_key: true)
      add(:label, :string)
    end

    create table(:lb_devices, primary_key: false) do
      add(:org_id, :integer, primary_key: true)
      add(:uid, :binary_id, primary_key: true)
      add(:name, :string)
    end

    create table(:lb_keyless_events, primary_key: false) do
      add(:external_ref, :string)
      add(:title, :string)
    end
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.Post do
  @moduledoc false

  use Ecto.Schema

  use Scrypath, fields: [:title]

  schema "lb_posts" do
    field(:title, :string)
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.Category do
  @moduledoc false

  use Ecto.Schema

  schema "lb_categories" do
    field(:name, :string)
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.Product do
  @moduledoc false

  use Ecto.Schema

  use Scrypath, fields: [:title], preload: [:category]

  schema "lb_products" do
    field(:title, :string)
    belongs_to(:category, Scrypath.TestSupport.LoaderBackfill.Category)
  end

  def search_document(product) do
    %{id: product.id, title: product.title, category_name: product.category.name}
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.Article do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query, only: [from: 2]

  use Scrypath, fields: [:title, :region]

  schema "lb_articles" do
    field(:title, :string)
    field(:region, :string)
    field(:published, :boolean)
    field(:pinned, :boolean)
  end

  # Pinned rows are returned for every batch on purpose: they are out-of-batch
  # extras the loader-routed backfill must handle (D-03).
  def search_records(ids, %{repo: repo}) do
    send(self(), {:search_records, ids})

    from(a in __MODULE__,
      where: (a.id in ^ids and a.published == true) or a.pinned == true
    )
    |> repo.all()
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.Membership do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  use Scrypath, fields: [:label]

  schema "lb_memberships" do
    field(:org_id, :integer, primary_key: true)
    field(:seq, :integer, primary_key: true)
    field(:label, :string)
  end

  def search_document(membership) do
    %{id: search_document_id(membership), label: membership.label}
  end

  def search_document_id(membership), do: "#{membership.org_id}:#{membership.seq}"
end

defmodule Scrypath.TestSupport.LoaderBackfill.Device do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  use Scrypath, fields: [:name]

  schema "lb_devices" do
    field(:org_id, :integer, primary_key: true)
    field(:uid, :binary_id, primary_key: true)
    field(:name, :string)
  end

  def search_document(device) do
    %{id: search_document_id(device), name: device.name}
  end

  def search_document_id(device), do: "#{device.org_id}:#{device.uid}"
end

defmodule Scrypath.TestSupport.LoaderBackfill.KeylessEvent do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  use Scrypath, fields: [:title], document_id: :external_ref

  schema "lb_keyless_events" do
    field(:external_ref, :string)
    field(:title, :string)
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.StubMeilisearch do
  @moduledoc false

  # The index-management callbacks Scrypath.reindex invokes. Results carry no
  # `:task`, so reindex never polls a real Meilisearch server.

  def index_name(schema_module, config) do
    Scrypath.TestSupport.LoaderBackfill.RecordingBackend.index_name(schema_module, config)
  end

  def create_index(schema_module, primary_key, config) do
    send(self(), {:create_index, schema_module, primary_key, config})
    {:ok, %{target_index: Keyword.fetch!(config, :target_index)}}
  end

  def apply_settings(schema_module, index_name, config) do
    send(self(), {:apply_settings, schema_module, index_name, config})
    {:ok, %{index: index_name}}
  end

  def swap_indexes(schema_module, config) do
    send(self(), {:swap_indexes, schema_module, config})
    {:ok, %{target_index: Keyword.fetch!(config, :target_index)}}
  end
end

defmodule Scrypath.TestSupport.LoaderBackfill.RecordingBackend do
  @moduledoc false

  # Records writes in the calling process mailbox. Results carry `task: nil`, so
  # empty batches never raise and reindex never polls Meilisearch.

  @behaviour Scrypath.Backend

  alias Scrypath.Operations.Result

  @impl true
  def name, do: :recording

  @impl true
  def index_name(schema_module, config) do
    prefix = Keyword.get(config, :index_prefix) || "scrypath"
    schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

    "#{prefix}_#{schema_name}"
  end

  @impl true
  def upsert_documents(schema_module, documents, config) do
    send(self(), {:upsert_documents, schema_module, documents, config})

    {:ok,
     Result.new(
       mode: Keyword.get(config, :sync_mode, :manual),
       status: :accepted,
       document_ids: Enum.map(documents, & &1.id),
       document_count: length(documents),
       task: nil,
       metadata: %{
         index: Keyword.get(config, :index_name) || index_name(schema_module, config)
       }
     )}
  end

  @impl true
  def delete_documents(schema_module, document_ids, config) do
    send(self(), {:delete_documents, schema_module, document_ids, config})
    {:ok, %{}}
  end

  @impl true
  def search(_schema_module, _query, _config) do
    {:ok, %{hits: []}}
  end

  @impl true
  def search_facet_values(_schema, _facet, _query, _opts, _config) do
    {:error, :not_implemented}
  end
end
