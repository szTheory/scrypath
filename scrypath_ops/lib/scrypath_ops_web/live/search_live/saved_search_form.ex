defmodule ScrypathOpsWeb.SearchLive.SavedSearchForm do
  @moduledoc false
  # Converts between the Search form and v1 saved-search definitions.
  #
  # A saved search the form can show exactly (one query, page size only) is run through the
  # normal Search path. Anything richer (per-schema queries, filters, sort, facets) is run as
  # stored and labelled with the inputs it used, so a replay never silently drops options.

  alias ScrypathOps.SearchPlayground

  @type form :: %{
          mode: :single | :multi,
          schema: module() | nil,
          schemas: [module()],
          q: String.t(),
          page_size: term()
        }

  @metadata_keys ~w(title description tags)

  @doc "Builds a v1 definition from the current form inputs."
  @spec to_definition(form()) :: {:ok, map()} | {:error, atom() | tuple()}
  def to_definition(%{mode: mode} = form) do
    page_size = form.page_size
    max_schemas = SearchPlayground.max_schemas_allowed()

    cond do
      SearchPlayground.validate_page_size(page_size) != :ok ->
        {:error, :invalid_page_size}

      mode == :single and is_nil(form.schema) ->
        {:error, :no_schema}

      mode == :single ->
        {:ok,
         %{
           "playbook_format" => 1,
           "mode" => "search",
           "schema" => inspect(form.schema),
           "q" => form.q,
           "opts" => %{"page" => %{"size" => page_size}}
         }}

      form.schemas == [] ->
        {:error, :no_schemas}

      length(form.schemas) > max_schemas ->
        {:error, {:too_many_schemas, length(form.schemas), max_schemas}}

      true ->
        {:ok,
         %{
           "playbook_format" => 1,
           "mode" => "search_many",
           "entries" => Enum.map(form.schemas, &[inspect(&1), form.q, %{}]),
           "opts" => %{"federation_limit" => page_size}
         }}
    end
  end

  @doc "Copies title, description and tags from `source` onto `definition`."
  @spec keep_metadata(map(), map()) :: map()
  def keep_metadata(definition, source) do
    Map.merge(definition, Map.take(source, @metadata_keys))
  end

  @doc """
  Projects a validated definition onto the form.

  Returns `{:exact, form}` when running the form reproduces the saved search,
  `{:stored, form}` when the definition has inputs the form can't show (the form then holds
  the closest match), or `{:error, {:unknown_schemas, names}}` when a target isn't allowlisted.
  """
  @spec from_definition(map(), [module()], term()) ::
          {:exact | :stored, form()} | {:error, {:unknown_schemas, [String.t()]}}
  def from_definition(definition, allowlist, fallback_page_size) do
    names = target_names(definition)
    by_name = Map.new(allowlist, &{inspect(&1), &1})

    case Enum.reject(names, &Map.has_key?(by_name, &1)) do
      [] -> project(definition, Enum.map(names, &Map.fetch!(by_name, &1)), fallback_page_size)
      unknown -> {:error, {:unknown_schemas, Enum.uniq(unknown)}}
    end
  end

  defp project(%{"mode" => "search"} = definition, [schema], fallback) do
    opts = Map.get(definition, "opts") || %{}
    page = Map.get(opts, "page") || %{}

    form = %{
      mode: :single,
      schema: schema,
      schemas: [schema],
      q: Map.get(definition, "q", ""),
      page_size: Map.get(page, "size") || fallback
    }

    exact? =
      Map.keys(opts) -- ["page"] == [] and Map.keys(page) -- ["size", "number"] == [] and
        Map.get(page, "number", 1) == 1

    {if(exact?, do: :exact, else: :stored), form}
  end

  defp project(%{"mode" => "search_many", "entries" => entries} = definition, schemas, fallback) do
    opts = Map.get(definition, "opts") || %{}
    queries = entries |> Enum.map(&Enum.at(&1, 1)) |> Enum.uniq()

    form = %{
      mode: :multi,
      schema: List.first(schemas),
      schemas: Enum.uniq(schemas),
      q: List.first(queries) || "",
      page_size: Map.get(opts, "federation_limit") || get_in(opts, ["page", "size"]) || fallback
    }

    exact? =
      length(queries) == 1 and Enum.all?(entries, &(Enum.at(&1, 2) == %{})) and
        length(Enum.uniq(schemas)) == length(schemas) and
        Map.keys(opts) -- ["federation_limit", "federation_offset"] == [] and
        Map.get(opts, "federation_offset", 0) == 0

    {if(exact?, do: :exact, else: :stored), form}
  end

  defp project(_definition, _schemas, fallback) do
    {:stored, %{mode: :single, schema: nil, schemas: [], q: "", page_size: fallback}}
  end

  @doc "Returns the schema names a definition targets, in entry order."
  @spec target_names(map()) :: [String.t()]
  def target_names(%{"mode" => "search", "schema" => schema}), do: [schema]

  def target_names(%{"mode" => "search_many", "entries" => entries}) when is_list(entries),
    do: Enum.map(entries, &hd/1)

  def target_names(_definition), do: []

  @doc "True when two forms would run the same search."
  @spec same?(form(), form()) :: boolean()
  def same?(a, b), do: normalize(a) == normalize(b)

  defp normalize(%{mode: :single} = form), do: {:single, form.schema, form.q, form.page_size}

  defp normalize(%{mode: :multi} = form),
    do: {:multi, Enum.sort(form.schemas), form.q, form.page_size}

  @doc "Label/value rows describing the inputs stored in a definition."
  @spec summary(map()) :: [{String.t(), String.t()}]
  def summary(definition) do
    opts = Map.get(definition, "opts") || %{}

    targets =
      case definition do
        %{"mode" => "search_many", "entries" => entries} ->
          Enum.map_join(entries, "\n", fn [schema, q | _] -> "#{short(schema)}: #{query(q)}" end)

        %{"schema" => schema} ->
          "#{short(schema)}: #{query(Map.get(definition, "q", ""))}"

        _other ->
          nil
      end

    options =
      opts
      |> Map.drop(["page", "federation_limit", "federation_offset"])
      |> Enum.sort()
      |> Enum.map_join("\n", fn {key, value} -> "#{key}: #{Jason.encode!(value)}" end)

    limit = Map.get(opts, "federation_limit") || get_in(opts, ["page", "size"])

    [
      {"Searches", targets},
      {"Results per page", limit && to_string(limit)},
      {"Options", options}
    ]
    |> Enum.reject(fn {_label, value} -> value in [nil, ""] end)
  end

  defp short(schema) when is_binary(schema), do: schema |> String.split(".") |> List.last()
  defp short(schema), do: inspect(schema)

  defp query(""), do: "all documents"
  defp query(q) when is_binary(q), do: "“#{q}”"
  defp query(q), do: inspect(q)

  @doc "Plain-language text for a definition that failed validation."
  @spec reason_text(term()) :: String.t()
  def reason_text({:invalid_json, _}), do: "The file isn't valid JSON."

  def reason_text({:invalid_saved_search, reason}), do: reason_text(reason)

  def reason_text({:invalid_playbook_format, format}),
    do:
      "It uses saved-search format #{inspect(format)}. Only format 1 is supported (\"playbook_format\": 1)."

  def reason_text({:page_size_out_of_range, n, max}),
    do: "Results per page must be between 1 and #{max}; it has #{inspect(n)}."

  def reason_text({:invalid_mode, _mode}),
    do: "\"mode\" must be \"search\" or \"search_many\"."

  def reason_text({:unknown_schemas, names}),
    do: "It uses a schema that isn't available here: #{Enum.join(names, ", ")}."

  def reason_text({:not_a_map, _}), do: "The file must contain one JSON object."

  def reason_text(reason),
    do:
      "It doesn't match the saved-search format (#{reason |> inspect() |> String.slice(0, 160)})."

  @doc "Message for a form that can't be saved."
  @spec form_error_text(term()) :: String.t()
  def form_error_text(:invalid_page_size),
    do:
      "Results per page must be a whole number from 1 to #{SearchPlayground.max_page_size_allowed()}."

  def form_error_text(:no_schema), do: "Choose a schema first."
  def form_error_text(:no_schemas), do: "Choose at least one schema first."

  def form_error_text({:too_many_schemas, _count, max}),
    do: "Choose up to #{max} schemas."

  def form_error_text(_other), do: "Check the search inputs, then save again."
end
