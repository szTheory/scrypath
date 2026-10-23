defmodule ScrypathOps.SavedSearches do
  @moduledoc """
  Stores operator saved searches in the host application's database.

  Every function takes the host `Ecto.Repo` (the `:repo` given to `scrypath_ops_routes/2`) and
  accepts an optional `:prefix` for hosts that keep the table outside the default Postgres
  schema. Run `ScrypathOps.Migration` first to create the `scrypath_ops_saved_searches` table.

  Names identify saved searches and are unique. Definitions are v1 saved-search maps and are
  validated with `ScrypathOps.SavedSearches.V1.validate/1` before they are written. The same
  v1 JSON document is the import and export format, so existing saved-search files import
  unchanged.
  """

  import Ecto.Query, only: [from: 2]

  alias ScrypathOps.SavedSearches.SavedSearch
  alias ScrypathOps.SavedSearches.V1

  @type repo :: module()
  @type opts :: [prefix: String.t() | nil]
  @type write_error ::
          :name_taken
          | :invalid_name
          | {:invalid_saved_search, term()}
          | Ecto.Changeset.t()

  @doc """
  Lists saved searches ordered by name.
  """
  @spec list(repo(), opts()) :: [SavedSearch.t()]
  def list(repo, opts \\ []) do
    repo.all(from(s in SavedSearch, order_by: [asc: s.name]), repo_opts(opts))
  end

  @doc """
  Fetches a saved search by name.
  """
  @spec get(repo(), String.t(), opts()) :: {:ok, SavedSearch.t()} | {:error, :not_found}
  def get(repo, name, opts \\ [])

  def get(repo, name, opts) when is_binary(name) do
    case repo.get_by(SavedSearch, [name: name], repo_opts(opts)) do
      %SavedSearch{} = saved_search -> {:ok, saved_search}
      nil -> {:error, :not_found}
    end
  end

  def get(_repo, _name, _opts), do: {:error, :not_found}

  @doc """
  Creates a saved search. Returns `{:error, :name_taken}` when the name is already used.
  """
  @spec create(repo(), String.t(), map(), opts()) ::
          {:ok, SavedSearch.t()} | {:error, write_error()}
  def create(repo, name, definition, opts \\ []) do
    with {:ok, validated} <- validate_definition(definition) do
      %SavedSearch{}
      |> SavedSearch.changeset(%{name: name, definition: validated})
      |> repo.insert(repo_opts(opts))
      |> normalize_write()
    end
  end

  @doc """
  Saves a definition under `name`, replacing the definition of an existing saved search with
  that name.
  """
  @spec save(repo(), String.t(), map(), opts()) ::
          {:ok, SavedSearch.t()} | {:error, write_error()}
  def save(repo, name, definition, opts \\ []) do
    with {:ok, validated} <- validate_definition(definition) do
      changeset = SavedSearch.changeset(%SavedSearch{}, %{name: name, definition: validated})

      changeset
      |> repo.insert(
        Keyword.merge(repo_opts(opts),
          on_conflict: {:replace, [:schema, :definition, :updated_at]},
          conflict_target: :name,
          returning: true
        )
      )
      |> normalize_write()
    end
  end

  @doc """
  Renames a saved search. Returns `{:error, :name_taken}` when `to` is already used.
  """
  @spec rename(repo(), String.t(), String.t(), opts()) ::
          {:ok, SavedSearch.t()} | {:error, :not_found | write_error()}
  def rename(repo, from, to, opts \\ []) do
    with {:ok, saved_search} <- get(repo, from, opts) do
      saved_search
      |> SavedSearch.rename_changeset(to)
      |> repo.update(repo_opts(opts))
      |> normalize_write()
    end
  end

  @doc """
  Copies a saved search to a new name. The definition is copied as stored.
  """
  @spec duplicate(repo(), String.t(), String.t(), opts()) ::
          {:ok, SavedSearch.t()} | {:error, :not_found | write_error()}
  def duplicate(repo, from, to, opts \\ []) do
    with {:ok, source} <- get(repo, from, opts) do
      %SavedSearch{schema: source.schema, definition: source.definition}
      |> SavedSearch.rename_changeset(to)
      |> repo.insert(repo_opts(opts))
      |> normalize_write()
    end
  end

  @doc """
  Deletes a saved search by name.
  """
  @spec delete(repo(), String.t(), opts()) :: :ok | {:error, :not_found}
  def delete(repo, name, opts \\ []) when is_binary(name) do
    query = from(s in SavedSearch, where: s.name == ^name)

    case repo.delete_all(query, repo_opts(opts)) do
      {0, _} -> {:error, :not_found}
      {_count, _} -> :ok
    end
  end

  @doc """
  Suggests an unused name for a copy of `name`, such as `"Daily check copy"` or
  `"Daily check copy 2"`.
  """
  @spec suggest_duplicate_name(repo(), String.t(), opts()) :: String.t()
  def suggest_duplicate_name(repo, name, opts \\ []) when is_binary(name) do
    taken = repo |> list(opts) |> MapSet.new(& &1.name)
    base = "#{name} copy"

    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(fn
      1 -> base
      n -> "#{base} #{n}"
    end)
    |> Enum.find(&(not MapSet.member?(taken, &1)))
  end

  @doc """
  Returns true when `name` can identify a saved search.
  """
  @spec valid_name?(term()) :: boolean()
  def valid_name?(name) when is_binary(name) do
    trimmed = String.trim(name)

    trimmed != "" and String.length(trimmed) <= SavedSearch.max_name_length() and
      not String.match?(trimmed, ~r/\p{Cc}/u)
  end

  def valid_name?(_name), do: false

  @doc """
  Decodes and validates v1 saved-search JSON, as found in an exported or hand-written file.
  """
  @spec decode_json(binary()) ::
          {:ok, map()} | {:error, {:invalid_json, term()} | {:invalid_saved_search, term()}}
  def decode_json(json) when is_binary(json) do
    with {:ok, map} <- V1.decode(json) do
      V1.validate(map)
    end
  end

  @doc """
  Imports v1 saved-search JSON as a new saved search named `name`.
  """
  @spec import_json(repo(), String.t(), binary(), opts()) ::
          {:ok, SavedSearch.t()} | {:error, {:invalid_json, term()} | write_error()}
  def import_json(repo, name, json, opts \\ []) when is_binary(json) do
    with {:ok, definition} <- decode_json(json) do
      create(repo, name, definition, opts)
    end
  end

  @doc """
  Exports a saved search as pretty-printed v1 JSON, ready to import elsewhere.
  """
  @spec export_json(SavedSearch.t() | map()) :: {:ok, String.t()} | {:error, term()}
  def export_json(%SavedSearch{definition: definition}), do: export_json(definition)

  def export_json(definition) when is_map(definition) do
    with {:ok, validated} <- V1.validate(definition) do
      {:ok, Jason.encode!(validated, pretty: true) <> "\n"}
    end
  end

  defp validate_definition(definition), do: V1.validate(definition)

  defp normalize_write({:ok, %SavedSearch{} = saved_search}), do: {:ok, saved_search}

  defp normalize_write({:error, %Ecto.Changeset{} = changeset}) do
    cond do
      unique_violation?(changeset) -> {:error, :name_taken}
      Keyword.has_key?(changeset.errors, :name) -> {:error, :invalid_name}
      true -> {:error, changeset}
    end
  end

  defp unique_violation?(changeset) do
    Enum.any?(changeset.errors, fn {_field, {_message, meta}} ->
      Keyword.get(meta, :constraint) == :unique
    end)
  end

  defp repo_opts(opts) do
    case Keyword.get(opts, :prefix) do
      prefix when is_binary(prefix) and prefix != "" -> [prefix: prefix]
      _other -> []
    end
  end
end
