defmodule ScrypathOps.Playbook.V1 do
  @moduledoc """
  Version **1** playbook JSON codec and strict validation for operator-supplied files.

  ## Wire format

  * Single JSON object per document with **string keys** at the JSON layer.
  * **`playbook_format`** must be the integer **`1`** (increment for breaking changes).
  * **`mode`** is **`"search"`** or **`"search_many"`**, selecting the dispatch path after validation.

  ## Caps

  * **`page.size`** is validated with **`ScrypathOps.SearchPlayground.validate_page_size/1`**
    (aligned with the library ceiling, typically **1..50**).
  * **`search_many`** entry count must not exceed **`ScrypathOps.SearchPlayground.max_schemas_allowed/0`**
    (library default **10**). Out-of-range values are **rejected**, not clamped.

  ## Security

  * Decoding uses **`Jason.decode/2`** with default string keys (never atom keys from JSON) to avoid atom exhaustion from untrusted input.
  * Transport and secret-shaped keys (**`meilisearch_api_key`**, **`req_options`**, **`meilisearch_url`**,
    **`meilisearch_client`**) are rejected anywhere under **`opts`** (deep scan).
  * This module does **not** call **`Path.expand/1`** on paths (**LFI**); importers should read from temp uploads
    or env-allowlisted directories only.

  ## Modes (top-level shape)

  * **`"search"`:** `schema`, `q`, `opts` (see phase context **D-08**).
  * **`"search_many"`:** `entries` (array of `[schema, q, opts]` triples), plus shared top-level `opts`.

  See **`scrypath_ops/docs/playbook-schema-v1.md`** for the normative field reference.
  """

  alias ScrypathOps.SearchPlayground

  @search_opt_keys MapSet.new(~w(facets facet_filter filter sort page per_query))

  @search_many_shared_extra MapSet.new(~w(
    federation_limit
    federation_offset
    federation_timeout
    hydration_timeout
    max_schemas
    global_schemas
    otp_app
  ))

  @banned_opt_keys MapSet.new(~w(
    meilisearch_api_key
    req_options
    meilisearch_url
    meilisearch_client
  ))

  @per_query_keys MapSet.new(~w(
    ranking_score_threshold
    show_ranking_score
    show_ranking_score_details
  ))

  @search_top ~w(playbook_format mode schema q opts title description tags)
  @search_many_top ~w(playbook_format mode entries opts title description tags)

  @doc """
  Decodes UTF-8 JSON into a **string-keyed** map.

  Returns `{:ok, map()}` or `{:error, {:invalid_json, reason}}`.
  """
  @spec decode(iodata()) :: {:ok, map()} | {:error, {:invalid_json, term()}}
  def decode(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, %{} = map} ->
        {:ok, map}

      {:ok, _} ->
        {:error, {:invalid_json, :not_object}}

      {:error, %Jason.DecodeError{} = err} ->
        {:error, {:invalid_json, err}}
    end
  end

  def decode(data) do
    data |> IO.iodata_to_binary() |> decode()
  end

  @doc """
  Strictly validates a decoded playbook map.

  Returns `{:ok, validated}` with the same string-keyed shape, or `{:error, {:invalid_playbook, reason}}`.

  ## Examples

      iex> playbook = %{
      ...>   "playbook_format" => 1,
      ...>   "mode" => "search",
      ...>   "schema" => "MyApp.Post",
      ...>   "q" => "hello",
      ...>   "opts" => %{}
      ...> }
      iex> {:ok, ^playbook} = ScrypathOps.Playbook.V1.validate(playbook)

      iex> bad = %{"playbook_format" => 2, "mode" => "search", "schema" => "M", "q" => "", "opts" => %{}}
      iex> {:error, {:invalid_playbook, {:invalid_playbook_format, 2}}} =
      ...>   ScrypathOps.Playbook.V1.validate(bad)

  """
  @spec validate(term()) :: {:ok, map()} | {:error, {:invalid_playbook, term()}}
  def validate(data) when is_map(data) do
    with :ok <- assert_no_banned_keys_deep(data),
         :ok <- validate_playbook_format(data),
         :ok <- validate_mode_field(data),
         :ok <- validate_top_level_keys(data),
         :ok <- validate_operator_metadata(data),
         {:ok, _} <- validate_by_mode(data) do
      {:ok, data}
    end
  end

  def validate(other), do: {:error, {:invalid_playbook, {:not_a_map, other}}}

  @doc """
  Encodes a validated playbook map to a compact JSON string (UTF-8).

  The input must already satisfy `validate/1`; this only performs **`Jason.encode!/1`**.
  """
  @spec encode(map()) :: {:ok, String.t()} | {:error, term()}
  def encode(data) when is_map(data) do
    {:ok, Jason.encode!(data)}
  rescue
    e in Protocol.UndefinedError -> {:error, {:encode_failed, e}}
  end

  def encode(_), do: {:error, {:encode_failed, :not_a_map}}

  defp validate_playbook_format(data) do
    case Map.get(data, "playbook_format") do
      1 -> :ok
      other -> {:error, {:invalid_playbook, {:invalid_playbook_format, other}}}
    end
  end

  defp validate_mode_field(data) do
    case Map.get(data, "mode") do
      m when m in ["search", "search_many"] -> :ok
      other -> {:error, {:invalid_playbook, {:invalid_mode, other}}}
    end
  end

  defp validate_top_level_keys(data) do
    mode = Map.get(data, "mode")
    allowed = MapSet.new(top_keys_for_mode(mode))
    got = MapSet.new(Map.keys(data))

    case MapSet.difference(got, allowed) |> MapSet.to_list() do
      [] -> :ok
      extras -> {:error, {:invalid_playbook, {:unknown_top_level_keys, extras}}}
    end
  end

  defp top_keys_for_mode("search"), do: @search_top
  defp top_keys_for_mode("search_many"), do: @search_many_top

  defp validate_operator_metadata(data) do
    with :ok <- maybe_validate_title(Map.get(data, "title")),
         :ok <- maybe_validate_description(Map.get(data, "description")),
         :ok <- maybe_validate_tags(Map.get(data, "tags")) do
      :ok
    end
  end

  defp maybe_validate_title(nil), do: :ok

  defp maybe_validate_title(title) when is_binary(title) do
    if byte_size(title) <= 200,
      do: :ok,
      else: {:error, {:invalid_playbook, {:invalid_metadata, {:title_too_large, byte_size(title)}}}}
  end

  defp maybe_validate_title(other),
    do: {:error, {:invalid_playbook, {:invalid_metadata, {:invalid_title, other}}}}

  defp maybe_validate_description(nil), do: :ok

  defp maybe_validate_description(desc) when is_binary(desc) do
    if byte_size(desc) <= 2000,
      do: :ok,
      else:
        {:error, {:invalid_playbook, {:invalid_metadata, {:description_too_large, byte_size(desc)}}}}
  end

  defp maybe_validate_description(other),
    do: {:error, {:invalid_playbook, {:invalid_metadata, {:invalid_description, other}}}}

  defp maybe_validate_tags(nil), do: :ok

  defp maybe_validate_tags(tags) when is_list(tags) do
    cond do
      length(tags) > 20 ->
        {:error, {:invalid_playbook, {:invalid_metadata, {:too_many_tags, length(tags), 20}}}}

      true ->
        Enum.reduce_while(Enum.with_index(tags), :ok, fn {tag, idx}, :ok ->
          cond do
            not is_binary(tag) ->
              {:halt, {:error, {:invalid_playbook, {:invalid_metadata, {:invalid_tag, idx, tag}}}}}

            tag == "" ->
              {:halt, {:error, {:invalid_playbook, {:invalid_metadata, {:empty_tag, idx}}}}}

            byte_size(tag) > 64 ->
              {:halt,
               {:error,
                {:invalid_playbook, {:invalid_metadata, {:tag_too_large, idx, byte_size(tag)}}}}}

            true ->
              {:cont, :ok}
          end
        end)
    end
  end

  defp maybe_validate_tags(other),
    do: {:error, {:invalid_playbook, {:invalid_metadata, {:invalid_tags, other}}}}

  defp validate_by_mode(%{"mode" => "search"} = data) do
    with {:ok, schema} <- require_string(data, "schema"),
         {:ok, q} <- require_string(data, "q"),
         :ok <- validate_opts(Map.get(data, "opts"), :search) do
      {:ok, %{data | "schema" => schema, "q" => q}}
    end
  end

  defp validate_by_mode(%{"mode" => "search_many"} = data) do
    entries = Map.get(data, "entries")

    with :ok <- validate_entries(entries),
         :ok <- validate_opts(Map.get(data, "opts"), :search_many_shared) do
      {:ok, data}
    end
  end

  defp validate_by_mode(data),
    do: {:error, {:invalid_playbook, {:invalid_mode, Map.get(data, "mode")}}}

  defp require_string(data, key) do
    case Map.get(data, key) do
      s when is_binary(s) -> {:ok, s}
      other -> {:error, {:invalid_playbook, {:invalid_string_field, key, other}}}
    end
  end

  defp validate_entries(entries) when is_list(entries) do
    max = SearchPlayground.max_schemas_allowed()

    cond do
      length(entries) > max ->
        {:error, {:invalid_playbook, {:too_many_entries, length(entries), max}}}

      true ->
        Enum.reduce_while(Enum.with_index(entries), :ok, fn {entry, _idx}, :ok ->
          case validate_entry(entry) do
            :ok -> {:cont, :ok}
            {:error, _} = err -> {:halt, err}
          end
        end)
    end
  end

  defp validate_entries(other),
    do: {:error, {:invalid_playbook, {:invalid_entries, other}}}

  defp validate_entry([schema, q, opts])
       when is_binary(schema) and is_binary(q) and is_map(opts) do
    validate_opts(opts, :search_many_entry)
  end

  defp validate_entry(entry),
    do: {:error, {:invalid_playbook, {:invalid_entry_shape, entry}}}

  defp validate_opts(nil, _), do: {:error, {:invalid_playbook, {:missing_opts}}}

  defp validate_opts(opts, ctx) when is_map(opts) do
    allow = allowlist(ctx)

    with :ok <- assert_only_keys(opts, allow),
         :ok <- assert_no_banned_keys_deep(opts),
         :ok <- validate_known_opt_shapes(opts, ctx),
         :ok <- maybe_validate_entry_federation_weight(ctx, opts) do
      :ok
    end
  end

  defp validate_opts(other, _), do: {:error, {:invalid_playbook, {:invalid_opts, other}}}

  defp maybe_validate_entry_federation_weight(:search_many_entry, opts),
    do: validate_entry_federation_weight(opts)

  defp maybe_validate_entry_federation_weight(_, _), do: :ok

  defp allowlist(:search), do: @search_opt_keys

  defp allowlist(:search_many_shared),
    do: MapSet.union(@search_opt_keys, @search_many_shared_extra)

  defp allowlist(:search_many_entry),
    do: MapSet.put(@search_opt_keys, "federation_weight")

  defp assert_only_keys(map, allowed) do
    case Map.keys(map) |> Enum.reject(&MapSet.member?(allowed, &1)) do
      [] -> :ok
      bad -> {:error, {:invalid_playbook, {:unknown_opt_keys, bad}}}
    end
  end

  defp validate_known_opt_shapes(opts, ctx) do
    with :ok <- validate_page_object(Map.get(opts, "page")),
         :ok <- validate_per_query_object(Map.get(opts, "per_query")),
         :ok <- validate_shared_many_fields(opts, ctx),
         :ok <- validate_otp_app(Map.get(opts, "otp_app"), ctx) do
      validate_page_size_if_present(Map.get(opts, "page"))
    end
  end

  defp validate_shared_many_fields(opts, ctx)
       when ctx in [:search, :search_many_entry] do
    # Shared federation / catalog keys are not allowed on per-query or entry opts.
    _ = opts
    :ok
  end

  defp validate_shared_many_fields(opts, :search_many_shared) do
    with :ok <- validate_global_schemas(Map.get(opts, "global_schemas")),
         :ok <- validate_federation_int(Map.get(opts, "federation_limit"), "federation_limit", []),
         :ok <-
           validate_federation_int(Map.get(opts, "federation_offset"), "federation_offset",
             non_neg: true
           ),
         :ok <-
           validate_federation_int(Map.get(opts, "federation_timeout"), "federation_timeout", []),
         :ok <-
           validate_federation_int(Map.get(opts, "hydration_timeout"), "hydration_timeout", []),
         :ok <- validate_federation_int(Map.get(opts, "max_schemas"), "max_schemas", []) do
      :ok
    end
  end

  defp validate_page_object(nil), do: :ok

  defp validate_page_object(page) when is_map(page) do
    allowed = MapSet.new(~w(number size))

    case Map.keys(page) |> Enum.reject(&MapSet.member?(allowed, &1)) do
      [] -> :ok
      bad -> {:error, {:invalid_playbook, {:unknown_page_keys, bad}}}
    end
  end

  defp validate_page_object(other),
    do: {:error, {:invalid_playbook, {:invalid_page, other}}}

  defp validate_page_size_if_present(nil), do: :ok

  defp validate_page_size_if_present(page) when is_map(page) do
    case Map.get(page, "size") do
      nil ->
        :ok

      size when is_integer(size) ->
        case SearchPlayground.validate_page_size(size) do
          :ok ->
            :ok

          {:error, {:page_size_out_of_range, _, _} = reason} ->
            {:error, {:invalid_playbook, reason}}
        end

      other ->
        {:error, {:invalid_playbook, {:invalid_page_size, other}}}
    end
  end

  defp validate_page_size_if_present(other),
    do: {:error, {:invalid_playbook, {:invalid_page, other}}}

  defp validate_per_query_object(nil), do: :ok

  defp validate_per_query_object(pq) when is_map(pq) do
    case Map.keys(pq) |> Enum.reject(&MapSet.member?(@per_query_keys, &1)) do
      [] -> :ok
      bad -> {:error, {:invalid_playbook, {:unknown_per_query_keys, bad}}}
    end
  end

  defp validate_per_query_object(other),
    do: {:error, {:invalid_playbook, {:invalid_per_query, other}}}

  defp validate_global_schemas(nil), do: :ok

  defp validate_global_schemas(list) when is_list(list) do
    if Enum.all?(list, &is_binary/1) do
      :ok
    else
      {:error, {:invalid_playbook, {:invalid_global_schemas, list}}}
    end
  end

  defp validate_global_schemas(other),
    do: {:error, {:invalid_playbook, {:invalid_global_schemas, other}}}

  defp validate_otp_app(nil, _), do: :ok

  defp validate_otp_app(s, :search_many_shared) when is_binary(s) and s != "",
    do: :ok

  defp validate_otp_app(other, :search_many_shared),
    do: {:error, {:invalid_playbook, {:invalid_otp_app, other}}}

  defp validate_otp_app(_val, :search), do: :ok
  defp validate_otp_app(_val, :search_many_entry), do: :ok

  defp validate_federation_int(nil, _key, _opts), do: :ok

  defp validate_federation_int(n, key, opts) when is_integer(n) do
    non_neg? = Keyword.get(opts, :non_neg, false)

    cond do
      non_neg? and n < 0 ->
        {:error, {:invalid_playbook, {:invalid_federation_field, key, n}}}

      not non_neg? and n < 1 ->
        {:error, {:invalid_playbook, {:invalid_federation_field, key, n}}}

      true ->
        :ok
    end
  end

  defp validate_federation_int(other, key, _opts),
    do: {:error, {:invalid_playbook, {:invalid_federation_field, key, other}}}

  defp assert_no_banned_keys_deep(term) do
    case find_banned_key(term) do
      nil -> :ok
      {path, key} -> {:error, {:invalid_playbook, {:banned_key, key, path}}}
    end
  end

  defp find_banned_key(map) when is_map(map) do
    Enum.reduce_while(map, nil, fn {k, v}, acc ->
      cond do
        is_binary(k) and MapSet.member?(@banned_opt_keys, k) ->
          {:halt, {[], k}}

        true ->
          sub = find_banned_key_in_value(v, [to_string(k)])
          if sub, do: {:halt, sub}, else: {:cont, acc}
      end
    end)
  end

  defp find_banned_key(list) when is_list(list) do
    Enum.reduce_while(Enum.with_index(list), nil, fn {elem, i}, acc ->
      case find_banned_key_in_value(elem, ["[#{i}]"]) do
        nil -> {:cont, acc}
        found -> {:halt, found}
      end
    end)
  end

  defp find_banned_key(_), do: nil

  defp find_banned_key_in_value(map, path) when is_map(map) do
    Enum.reduce_while(map, nil, fn {k, v}, acc ->
      cond do
        is_binary(k) and MapSet.member?(@banned_opt_keys, k) ->
          {:halt, {Enum.reverse(path), k}}

        true ->
          subpath = [to_string(k) | path]
          sub = find_banned_key_in_value(v, subpath)
          if sub, do: {:halt, sub}, else: {:cont, acc}
      end
    end)
  end

  defp find_banned_key_in_value(list, path) when is_list(list) do
    Enum.reduce_while(Enum.with_index(list), nil, fn {elem, i}, acc ->
      subpath = ["[#{i}]" | path]

      case find_banned_key_in_value(elem, subpath) do
        nil -> {:cont, acc}
        found -> {:halt, found}
      end
    end)
  end

  defp find_banned_key_in_value(_, _), do: nil

  # Entry-level federation_weight (validated only when present on entry opts)
  defp validate_entry_federation_weight(opts) when is_map(opts) do
    case Map.get(opts, "federation_weight") do
      nil ->
        :ok

      n when is_integer(n) ->
        :ok

      n when is_float(n) ->
        if finite_float?(n),
          do: :ok,
          else: {:error, {:invalid_playbook, {:invalid_federation_weight, n}}}

      other ->
        {:error, {:invalid_playbook, {:invalid_federation_weight, other}}}
    end
  end

  defp finite_float?(f) when is_float(f), do: f == f and abs(f) <= 1.7976931348623157e308
  defp finite_float?(_), do: false
end
