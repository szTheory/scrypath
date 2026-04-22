defmodule ScrypathOps.Playbook.Runner do
  @moduledoc """
  Runs a **validated** playbook map through `ScrypathOps.SearchPlayground` dispatch only.

  Callers must pass maps already accepted by `ScrypathOps.Playbook.V1.validate/1` (`{:ok, map}`).
  Invalid shapes or configuration issues return tagged `{:error, reason}` tuples without logging
  raw playbook bodies.

  ## Runner-library contract

  `run_validated/3` is the canonical execution contract for playbook runs. Call this function
  only after `ScrypathOps.Playbook.V1.validate/1` has accepted the JSON payload and produced
  the validated string-keyed map, or pass the equivalent `{:ok, map}` wrapper from validation.

  The contract stays on the same raw tuple seam as the root `Scrypath` search APIs:

  - `search` mode returns `{:ok, %Scrypath.SearchResult{}}` on success.
  - `search_many` mode returns `{:ok, %Scrypath.MultiSearchResult{}}` on success.
  - Failures stay `{:error, reason}`. The stable compatibility key is the `reason` term itself,
    not any later UI or CLI wording.

  This mirrors the root-library "Errors vs raises" split: the non-bang path returns raw
  `{:error, reason}` tuples for callers that want to branch, while bang helpers raise later with
  that same reason. `ScrypathOps.Playbook.RunFailure`, `ScrypathOpsWeb.PlaybookLive`,
  `Scrypath.Errors`, and Mix or operator tasks own presentation formatting after the raw reason
  already exists; they do not redefine this runner contract.

  Boundary normalization here stays intentionally narrow. `module_in_allowlist/2` rescues only the
  existing module-resolution `ArgumentError` raised by `String.to_existing_atom/1` so invalid
  schema strings normalize to `nil` and then to the explicit config failure. The runner does not
  add generic `try`/`rescue` handling that would swallow a divergent `{:error, reason}` outcome
  from the underlying search path.
  """

  alias ScrypathOps.SearchPlayground

  @doc """
  Executes a validated playbook against the configured search playground adapter.

  The first argument must be the string-keyed map from `Playbook.V1.validate/1`, or `{:ok, map}`.
  """
  @spec run_validated(map() | {:ok, map()}, [module()], keyword()) ::
          {:ok, term()} | {:error, term()}
  def run_validated({:ok, map}, allowlist, scrypath_opts) when is_map(map) do
    run_validated(map, allowlist, scrypath_opts)
  end

  def run_validated({:error, _}, _, _) do
    {:error, :playbook_not_validated}
  end

  def run_validated(%{"mode" => "search"} = map, allowlist, scrypath_opts) do
    mod = module_in_allowlist(Map.get(map, "schema"), allowlist)
    q = Map.get(map, "q")
    opts_map = Map.get(map, "opts") || %{}

    cond do
      allowlist == [] ->
        {:error, {:config, :empty_allowlist}}

      mod == nil ->
        {:error, {:config, :no_schema}}

      not is_binary(q) ->
        {:error, {:config, :invalid_query}}

      not Keyword.has_key?(scrypath_opts, :backend) ->
        {:error, {:config, :missing_backend}}

      true ->
        with {:ok, opts} <- build_dispatch_opts(scrypath_opts, opts_map, :search) do
          SearchPlayground.dispatch_search(mod, q, opts)
        end
    end
  end

  def run_validated(%{"mode" => "search_many"} = map, allowlist, scrypath_opts) do
    entries = Map.get(map, "entries")
    opts_map = Map.get(map, "opts") || %{}

    cond do
      allowlist == [] ->
        {:error, {:config, :empty_allowlist}}

      not is_list(entries) ->
        {:error, {:config, :invalid_entries}}

      not Keyword.has_key?(scrypath_opts, :backend) ->
        {:error, {:config, :missing_backend}}

      true ->
        with {:ok, shared_opts} <-
               build_dispatch_opts(scrypath_opts, opts_map, :search_many_shared),
             {:ok, mapped} <- map_search_many_entries(entries, allowlist) do
          SearchPlayground.dispatch_search_many(mapped, shared_opts)
        end
    end
  end

  def run_validated(_, _, _) do
    {:error, :invalid_playbook_shape}
  end

  defp map_search_many_entries(entries, allowlist) do
    Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
      case entry do
        [schema, q, %{} = eopts] when is_binary(q) ->
          case module_in_allowlist(schema, allowlist) do
            nil ->
              {:halt, {:error, {:config, :no_schema}}}

            mod ->
              ekw = opts_string_map_to_keyword(eopts, :search_many_entry)
              {:cont, {:ok, [{mod, q, ekw} | acc]}}
          end

        _ ->
          {:halt, {:error, {:config, :invalid_entry_shape}}}
      end
    end)
    |> case do
      {:ok, rev} -> {:ok, Enum.reverse(rev)}
      {:error, _} = err -> err
    end
  end

  defp build_dispatch_opts(scrypath_opts, opts_map, ctx) do
    playbook_kw = opts_string_map_to_keyword(opts_map, ctx)

    page_kw =
      case Keyword.get(playbook_kw, :page) do
        list when is_list(list) -> list
        _ -> []
      end

    with :ok <- validate_page_kw(page_kw),
         true <- Keyword.has_key?(scrypath_opts, :backend) do
      merged =
        scrypath_opts
        |> Keyword.merge(Keyword.delete(playbook_kw, :page))
        |> maybe_put_page(page_kw)

      {:ok, merged}
    else
      {:error, {:page_size_out_of_range, _, _} = e} ->
        {:error, e}

      false ->
        {:error, {:config, :missing_backend}}
    end
  end

  defp opts_string_map_to_keyword(map, ctx) when is_map(map) do
    allowed = keys_for_ctx(ctx)

    Enum.reduce(map, [], fn {k, v}, acc ->
      if is_binary(k) and k in allowed do
        [{String.to_existing_atom(k), coerce_opt(k, v)} | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  defp opts_string_map_to_keyword(_, _), do: []

  defp keys_for_ctx(:search),
    do: ~w(facets facet_filter filter sort page per_query)

  defp keys_for_ctx(:search_many_shared),
    do:
      keys_for_ctx(:search) ++
        ~w(
          federation_limit
          federation_offset
          federation_timeout
          hydration_timeout
          max_schemas
          global_schemas
          otp_app
        )

  defp keys_for_ctx(:search_many_entry),
    do: keys_for_ctx(:search) ++ ~w(federation_weight)

  defp coerce_opt("page", %{} = m) do
    Enum.reduce(m, [], fn
      {"size", n}, acc when is_integer(n) -> [{:size, n} | acc]
      {"number", n}, acc when is_integer(n) -> [{:number, n} | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end

  defp coerce_opt("facets", list) when is_list(list) do
    Enum.map(list, &coerce_existing_atom/1)
  end

  defp coerce_opt("per_query", %{} = m) do
    Enum.reduce(m, [], fn
      {"ranking_score_threshold", n}, acc when is_integer(n) ->
        [{:ranking_score_threshold, n} | acc]

      {"show_ranking_score", b}, acc when is_boolean(b) ->
        [{:show_ranking_score, b} | acc]

      {"show_ranking_score_details", b}, acc when is_boolean(b) ->
        [{:show_ranking_score_details, b} | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  defp coerce_opt("global_schemas", list) when is_list(list), do: list

  defp coerce_opt(key, n)
       when key in ~w(federation_limit federation_offset federation_timeout hydration_timeout max_schemas) and
              is_integer(n),
       do: n

  defp coerce_opt("federation_weight", n) when is_integer(n), do: n
  defp coerce_opt("federation_weight", n) when is_float(n), do: n

  defp coerce_opt("otp_app", s) when is_binary(s), do: s

  defp coerce_opt(_, v), do: v

  defp validate_page_kw([]), do: :ok

  defp validate_page_kw(page_kw) do
    case Keyword.get(page_kw, :size) do
      n when is_integer(n) -> SearchPlayground.validate_page_size(n)
      _ -> :ok
    end
  end

  defp maybe_put_page(opts, []), do: opts
  defp maybe_put_page(opts, page_kw), do: Keyword.put(opts, :page, page_kw)

  defp coerce_existing_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> value
    end
  end

  defp coerce_existing_atom(value), do: value

  defp module_in_allowlist(bin, allowlist) when is_binary(bin) do
    mod =
      try do
        bin |> String.split(".") |> Enum.map(&String.to_existing_atom/1) |> Module.concat()
      rescue
        ArgumentError -> nil
      end

    if mod in allowlist, do: mod, else: nil
  end

  defp module_in_allowlist(_, _), do: nil
end
