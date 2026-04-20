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

  defp walk([entry | rest], mods, acc) do
    case entry do
      {:all, text} when is_binary(text) ->
        acc2 = Enum.reduce(mods, acc, fn m, a -> [{m, text, []} | a] end)
        walk(rest, mods, acc2)

      {:all, text, opts} when is_binary(text) and is_list(opts) ->
        if Keyword.keyword?(opts) do
          acc2 = Enum.reduce(mods, acc, fn m, a -> [{m, text, opts} | a] end)
          walk(rest, mods, acc2)
        else
          {:error, {:invalid_options, :malformed_entry}}
        end

      {:all, _, _} ->
        {:error, {:invalid_options, :malformed_entry}}

      {:all, _} ->
        {:error, {:invalid_options, :malformed_entry}}

      {schema, text} when is_atom(schema) and schema != :all and is_binary(text) ->
        walk(rest, mods, [{schema, text, []} | acc])

      {schema, text, opts}
      when is_atom(schema) and schema != :all and is_binary(text) and is_list(opts) ->
        if Keyword.keyword?(opts) do
          walk(rest, mods, [{schema, text, opts} | acc])
        else
          {:error, {:invalid_options, :malformed_entry}}
        end

      _ ->
        {:error, {:invalid_options, :malformed_entry}}
    end
  end
end
