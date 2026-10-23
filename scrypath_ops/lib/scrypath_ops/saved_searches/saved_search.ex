defmodule ScrypathOps.SavedSearches.SavedSearch do
  @moduledoc """
  A saved search stored in the `scrypath_ops_saved_searches` table.

  `definition` holds the validated v1 saved-search map (see `ScrypathOps.SavedSearches.V1`),
  the same document used for JSON import and export. `schema` is derived from it for listing:
  the target schema of a `"search"` definition, or the comma-joined targets of a
  `"search_many"` definition in entry order.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @max_name_length 120

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          schema: String.t() | nil,
          definition: map() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "scrypath_ops_saved_searches" do
    field(:name, :string)
    field(:schema, :string)
    field(:definition, :map)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a changeset from a name and an already validated v1 definition.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(saved_search, attrs) do
    saved_search
    |> cast(attrs, [:name, :definition])
    |> validate_name()
    |> validate_required([:definition])
    |> put_schema()
  end

  @doc """
  Builds a changeset that only changes the name.
  """
  @spec rename_changeset(t(), String.t()) :: Ecto.Changeset.t()
  def rename_changeset(saved_search, name) do
    saved_search
    |> cast(%{name: name}, [:name])
    |> validate_name()
  end

  @doc """
  Returns the maximum length of a saved search name.
  """
  @spec max_name_length() :: pos_integer()
  def max_name_length, do: @max_name_length

  @doc """
  Returns the `schema` column value for a v1 definition.
  """
  @spec schema_for(map()) :: String.t() | nil
  def schema_for(%{"mode" => "search", "schema" => schema}) when is_binary(schema), do: schema

  def schema_for(%{"mode" => "search_many", "entries" => entries}) when is_list(entries) do
    entries
    |> Enum.flat_map(fn
      [schema | _rest] when is_binary(schema) -> [schema]
      _other -> []
    end)
    |> Enum.uniq()
    |> Enum.join(",")
  end

  def schema_for(_definition), do: nil

  defp validate_name(changeset) do
    changeset
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name])
    |> validate_length(:name, max: @max_name_length)
    |> validate_format(:name, ~r/\A[^\p{Cc}]+\z/u, message: "must not contain control characters")
    |> unique_constraint(:name)
  end

  defp put_schema(changeset) do
    case get_field(changeset, :definition) do
      %{} = definition -> put_change(changeset, :schema, schema_for(definition))
      _other -> changeset
    end
    |> validate_required([:schema])
  end
end
