defmodule Scrypath.MultiSearch.AllExpansion do
  @moduledoc false

  @doc """
  Expands `{:all, text}` / `{:all, text, keyword}` entries into explicit
  `{schema, text, keyword}` tuples before `Entries.normalize/2`.
  """
  @spec expand(list(), keyword()) :: {:ok, list()} | {:error, term()}
  def expand(entries, shared_opts) when is_list(entries) and is_list(shared_opts) do
    if contains_all?(entries) do
      do_expand(entries, shared_opts)
    else
      {:ok, entries}
    end
  end

  defp contains_all?(entries) do
    Enum.any?(entries, fn
      {:all, _} -> true
      {:all, _, _} -> true
      _ -> false
    end)
  end

  defp do_expand(entries, shared_opts) do
    case validate_all_shapes(entries) do
      :ok ->
        with {:ok, mods} <- resolve_allowlist(shared_opts) do
          if mods == [] do
            {:error, {:invalid_options, {:all_expansion, :empty_registry}}}
          else
            walk(entries, mods, [])
          end
        end

      {:error, _} = err ->
        err
    end
  end

  defp validate_all_shapes(entries) do
    Enum.reduce_while(entries, :ok, fn entry, _ ->
      case entry do
        {:all, text} when is_binary(text) ->
          {:cont, :ok}

        {:all, text, opts} when is_binary(text) and is_list(opts) ->
          if Keyword.keyword?(opts) do
            {:cont, :ok}
          else
            {:halt, {:error, {:invalid_options, :malformed_entry}}}
          end

        {:all, _, _} ->
          {:halt, {:error, {:invalid_options, :malformed_entry}}}

        {:all, _} ->
          {:halt, {:error, {:invalid_options, :malformed_entry}}}

        _ ->
          {:cont, :ok}
      end
    end)
  end

  defp resolve_allowlist(shared_opts) do
    if Keyword.has_key?(shared_opts, :global_schemas) do
      {:ok, Keyword.fetch!(shared_opts, :global_schemas)}
    else
      case Keyword.get(shared_opts, :otp_app) do
        nil ->
          {:error, {:invalid_options, {:all_expansion, :missing_otp_app}}}

        otp_app when is_atom(otp_app) ->
          {:ok, Application.get_env(otp_app, :scrypath_global_search_schemas, [])}
      end
    end
  end

  defp walk([], _mods, acc), do: {:ok, Enum.reverse(acc)}

  defp walk([{:all, text} | rest], mods, acc) when is_binary(text),
    do: walk(rest, mods, expand_all(mods, text, [], acc))

  defp walk([{:all, text, opts} | rest], mods, acc) when is_binary(text) and is_list(opts),
    do: walk_all_with_opts(rest, mods, acc, text, opts)

  defp walk([{schema, text} | rest], mods, acc)
       when is_atom(schema) and schema != :all and is_binary(text),
       do: walk(rest, mods, [{schema, text, []} | acc])

  defp walk([{schema, text, opts} | rest], mods, acc)
       when is_atom(schema) and schema != :all and is_binary(text) and is_list(opts),
       do: walk_schema_with_opts(rest, mods, acc, schema, text, opts)

  defp walk([_entry | _rest], _mods, _acc), do: {:error, {:invalid_options, :malformed_entry}}

  defp walk_all_with_opts(rest, mods, acc, text, opts) do
    if Keyword.keyword?(opts) do
      walk(rest, mods, expand_all(mods, text, opts, acc))
    else
      {:error, {:invalid_options, :malformed_entry}}
    end
  end

  defp walk_schema_with_opts(rest, mods, acc, schema, text, opts) do
    if Keyword.keyword?(opts) do
      walk(rest, mods, [{schema, text, opts} | acc])
    else
      {:error, {:invalid_options, :malformed_entry}}
    end
  end

  defp expand_all(mods, text, opts, acc) do
    Enum.reduce(mods, acc, fn m, a -> [{m, text, opts} | a] end)
  end
end
