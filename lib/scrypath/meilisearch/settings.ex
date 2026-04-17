defmodule Scrypath.Meilisearch.Settings do
  @moduledoc false

  alias Scrypath.Meilisearch
  alias Scrypath.Meilisearch.Client

  @canonical_to_camel %{
    synonyms: "synonyms",
    typo_tolerance: "typoTolerance",
    ranking_rules: "rankingRules",
    distinct_attribute: "distinctAttribute",
    stop_words: "stopWords",
    searchable_attributes: "searchableAttributes",
    sortable_attributes: "sortableAttributes",
    filterable_attributes: "filterableAttributes",
    displayed_attributes: "displayedAttributes"
  }

  @scrypath_meta_keys [:ranking_rules_strict?]

  @spec resolve(module(), keyword()) :: map()
  def resolve(schema_module, config) do
    declared =
      schema_module
      |> Scrypath.schema_settings()
      |> maybe_normalize()

    override =
      config
      |> Keyword.get(:settings, %{})
      |> maybe_normalize()

    merged =
      case Keyword.get(config, :settings_merge, :replace) do
        :deep -> deep_merge(declared, override)
        _ -> Map.merge(declared, override)
      end

    merge_faceting_filterable_attributes(schema_module, merged)
  end

  # Facet-derived `filterableAttributes` entries augment `resolve/2` after declared settings
  # merge. Explicit `settings:` entries for the same attribute win: existing maps are kept
  # unchanged; bare strings for facet attributes are upgraded to object form with facetSearch.
  defp merge_faceting_filterable_attributes(schema_module, settings) do
    faceting = Scrypath.schema_faceting(schema_module)
    attrs = Keyword.get(faceting, :attributes, [])

    if attrs == [] do
      settings
    else
      facet_names = MapSet.new(attrs, &Atom.to_string/1)
      list = filterable_attributes_list(Map.get(settings, :filterable_attributes))

      {converted, covered} =
        Enum.map_reduce(list, MapSet.new(), fn entry, covered ->
          transform_filterable_for_faceting(entry, facet_names, covered)
        end)

      appended =
        attrs
        |> Enum.reject(&MapSet.member?(covered, &1))
        |> Enum.map(&facet_filterable_object/1)

      Map.put(settings, :filterable_attributes, converted ++ appended)
    end
  end

  defp filterable_attributes_list(nil), do: []

  defp filterable_attributes_list(list) when is_list(list), do: list
  defp filterable_attributes_list(_), do: []

  defp transform_filterable_for_faceting(entry, facet_names, covered) when is_binary(entry) do
    if MapSet.member?(facet_names, entry) do
      {facet_filterable_object_string(entry), MapSet.put(covered, String.to_existing_atom(entry))}
    else
      {entry, covered}
    end
  end

  defp transform_filterable_for_faceting(entry, facet_names, covered) when is_atom(entry) do
    name = Atom.to_string(entry)

    if MapSet.member?(facet_names, name) do
      {facet_filterable_object_string(name), MapSet.put(covered, entry)}
    else
      {entry, covered}
    end
  end

  defp transform_filterable_for_faceting(%{} = m, facet_names, covered) do
    case attribute_string_from_filterable_entry(m) do
      nil ->
        {m, covered}

      name when is_binary(name) ->
        if MapSet.member?(facet_names, name) do
          {m, MapSet.put(covered, String.to_existing_atom(name))}
        else
          {m, covered}
        end
    end
  end

  defp attribute_string_from_filterable_entry(m) do
    case {Map.get(m, :attribute), Map.get(m, "attribute")} do
      {a, _} when is_atom(a) -> Atom.to_string(a)
      {b, _} when is_binary(b) -> b
      {nil, b} when is_binary(b) -> b
      _ -> nil
    end
  end

  defp facet_filterable_object_string(name) when is_binary(name) do
    %{attribute: name, features: ["facetSearch"]}
  end

  defp facet_filterable_object(attr) when is_atom(attr) do
    %{attribute: Atom.to_string(attr), features: ["facetSearch"]}
  end

  @spec apply(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def apply(schema_module, index_name, config) do
    settings = resolve(schema_module, config)
    translated = translate_settings(settings)

    with {:ok, response} <- client(config).update_settings(index_name, translated, config),
         {:ok, task} <- Meilisearch.normalize_task(response) do
      {:ok,
       %{
         index: index_name,
         settings: settings,
         task: task
       }}
    end
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  @doc """
  Expands synonym declarations from either Meilisearch-native map form (passthrough)
  or Scrypath list-of-groups sugar (bidirectional by default).

  TUNE-02: `[["nyc", "new york"]]` → `%{"nyc" => ["new york"], "new york" => ["nyc"]}`.
  `{groups, one_way: true}` disables bidirectional expansion (first term keys into rest).
  """
  @spec expand_synonyms(list() | map() | {list(), keyword()}) :: map()
  def expand_synonyms(groups) when is_map(groups), do: groups

  def expand_synonyms(groups) when is_list(groups), do: expand_groups(groups, false)

  def expand_synonyms({groups, opts}) when is_list(groups) and is_list(opts) do
    one_way = Keyword.get(opts, :one_way, false)
    expand_groups(groups, one_way)
  end

  defp expand_groups(groups, one_way) do
    Enum.reduce(groups, %{}, fn group, acc ->
      stringified = Enum.map(group, &to_string/1)

      cond do
        stringified == [] ->
          acc

        one_way ->
          [head | rest] = stringified
          Map.update(acc, head, rest, fn existing -> existing ++ rest end)

        true ->
          Enum.reduce(stringified, acc, fn term, acc2 ->
            others = stringified -- [term]
            Map.update(acc2, term, others, fn existing -> existing ++ others end)
          end)
      end
    end)
  end

  @doc """
  Translates a canonical atom-snake settings map to Meilisearch-native camelCase
  string keys. Strips Scrypath meta keys (`*_strict?` suffix + explicit allowlist,
  D-04). Spreads `:__unrecognized__` bucket entries through last (TUNE-01 forward-
  compat passthrough).
  """
  @spec translate_settings(map()) :: map()
  def translate_settings(canonical) when is_map(canonical) do
    {unrecognized, recognized} = Map.pop(canonical, :__unrecognized__, %{})

    one_way =
      case {Map.get(recognized, :one_way), Map.get(unrecognized, :one_way),
            Map.get(unrecognized, "one_way")} do
        {ow, _, _} when not is_nil(ow) -> ow
        {_, ow, _} when not is_nil(ow) -> ow
        {_, _, ow} when not is_nil(ow) -> ow
        _ -> false
      end

    recognized = Map.delete(recognized, :one_way)

    unrecognized =
      unrecognized
      |> Map.delete(:one_way)
      |> Map.delete("one_way")

    stripped = strip_scrypath_meta_keys(recognized)

    recognized_camel =
      Enum.into(stripped, %{}, fn {k, v} ->
        v =
          case k do
            :synonyms ->
              if is_list(v) do
                expand_synonyms({v, [one_way: one_way]})
              else
                expand_synonyms(v)
              end

            _ ->
              recursively_camelize(v)
          end

        camel = Map.get(@canonical_to_camel, k) || camelize_atom(k)
        {camel, v}
      end)

    Map.merge(recognized_camel, unrecognized)
  end

  defp strip_scrypath_meta_keys(map) when is_map(map) do
    map
    |> Enum.reject(fn {k, _} ->
      k in @scrypath_meta_keys or
        (is_atom(k) and String.ends_with?(Atom.to_string(k), "_strict?"))
    end)
    |> Map.new()
  end

  defp camelize_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> Macro.camelize()
    |> then(fn s ->
      String.downcase(String.slice(s, 0..0)) <> String.slice(s, 1..-1//1)
    end)
  end

  defp recursively_camelize(value) when is_map(value) do
    Enum.into(value, %{}, fn {k, v} ->
      camel_k =
        cond do
          is_atom(k) -> camelize_atom(k)
          is_binary(k) -> k
          true -> k
        end

      {camel_k, recursively_camelize(v)}
    end)
  end

  defp recursively_camelize(value), do: value

  defp maybe_normalize(%{__unrecognized__: _} = already_canonical), do: already_canonical

  defp maybe_normalize(map) when is_map(map), do: Scrypath.Options.normalize_settings(map)

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, lv, rv ->
      if is_map(lv) and is_map(rv), do: deep_merge(lv, rv), else: rv
    end)
  end

  @doc """
  Deferred to v1.4. Always returns `{:error, :hot_apply_disabled}`.

  The managed-reindex pipeline via `Scrypath.reindex/2` is the ONLY supported
  path for applying settings in v1.3 (TUNE-03). A real implementation is
  deferred to v1.4 under a guarded contract (restricted subkey allowlist,
  explicit `acknowledge_live_index: true` opt, telemetry event).
  """
  @spec hot_apply(module(), String.t(), keyword()) :: {:error, :hot_apply_disabled}
  def hot_apply(_schema_module, _index_name, _config), do: {:error, :hot_apply_disabled}

  @doc """
  Reads applied Meilisearch settings via `Client.get_settings/2`, compares key-by-key
  against the declared+translated wire form, and returns drift if any.

  Returns:

    * `:ok` — declared keys all match applied values (declared-subset-of-applied semantics).
    * `{:error, {:settings_drift, [{key, declared, actual}, ...]}}` — one or more declared keys diverge or are missing from the applied settings.
    * `{:error, :index_not_found}` — applied-side index does not exist (Meilisearch 404).
    * `{:error, term()}` — other transport/runtime errors passed through.

  """
  @spec verify_applied(module(), String.t(), keyword()) ::
          :ok
          | {:error, {:settings_drift, [{binary() | atom(), term(), term()}]}}
          | {:error, :index_not_found}
          | {:error, term()}
  def verify_applied(schema_module, index_name, config) do
    declared_wire =
      schema_module
      |> resolve(config)
      |> translate_settings()

    case client(config).get_settings(index_name, config) do
      {:ok, applied_wire} ->
        case compute_drift(declared_wire, applied_wire) do
          [] -> :ok
          drift -> {:error, {:settings_drift, drift}}
        end

      {:error, {:http_error, 404, _body}} ->
        {:error, :index_not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec compute_drift(map(), map()) :: [{binary() | atom(), term(), term()}]
  def compute_drift(declared_wire, applied_wire)
      when is_map(declared_wire) and is_map(applied_wire) do
    declared_wire
    |> Enum.reduce([], fn {key, declared_value}, acc ->
      case Map.fetch(applied_wire, key) do
        {:ok, ^declared_value} -> acc
        {:ok, applied_value} -> [{key, declared_value, applied_value} | acc]
        :error -> [{key, declared_value, :not_present} | acc]
      end
    end)
    |> Enum.reverse()
  end
end
