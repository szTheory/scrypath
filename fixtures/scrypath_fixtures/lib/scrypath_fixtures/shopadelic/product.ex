defmodule ScrypathFixtures.Shopadelic.Product do
  @moduledoc """
  Shopadelic's searchable product schema. Shopadelic is a fictional online-shop product; the data
  is for development and tests only.

  Fictional adopter: Scrypath-owned data, no records copied from any other project.

  `:storeId` is a filterable attribute next to `:status`, which is what the `:settings_drift`
  scenario leaves out of the applied settings.
  """

  use Ecto.Schema

  use Scrypath,
    fields: [:title, :status, :storeId],
    filterable: [:status, :storeId]

  embedded_schema do
    field(:title, :string)
    field(:status, :string)
    field(:storeId, :string)
  end

  # The two products the `:failed_journey` job 101 carries. They live in code so a retry can be
  # checked against current records without a database.
  @records [
    %{id: "SPD-2041", title: "Hand-glazed tea mug", status: "active", storeId: "north-store"},
    %{id: "SPD-2042", title: "Linen table runner", status: "active", storeId: "north-store"}
  ]

  @doc """
  The records for these document ids, in the order asked, from the two fictional products above;
  an id with no record is left out. A pure loader for tests and stories: it never touches a
  repository, so a schema that is only embedded can still be reloaded when a retry runs.
  """
  @spec search_records([term()], map()) :: [%__MODULE__{}]
  def search_records(ids, _opts) when is_list(ids) do
    for id <- ids, record <- @records, record.id == id, do: struct!(__MODULE__, record)
  end
end
