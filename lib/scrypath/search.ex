defmodule Scrypath.Search do
  @moduledoc false

  alias Scrypath.MultiSearchResult
  alias Scrypath.Search.FacetValues
  alias Scrypath.Search.Many
  alias Scrypath.Search.Single
  alias Scrypath.SearchResult
  alias Scrypath.Telemetry

  @spec search(module(), String.t(), keyword()) :: {:ok, SearchResult.t()} | {:error, term()}
  def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
    case Scrypath.Options.validate_search_options(schema_module, opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, _} = error ->
        error

      {:ok, search_opts} ->
        Single.run(schema_module, text, search_opts, opts, [])
    end
  end

  @spec search!(module(), String.t(), keyword()) :: SearchResult.t()
  def search!(schema_module, text, opts \\ []) do
    case search(schema_module, text, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  @spec search_within_facet(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          {:ok, SearchResult.t()} | {:error, term()}
  def search_within_facet(schema_module, text, bucket, opts \\ [])
      when is_binary(text) and is_list(opts) do
    merged_opts = merge_facet_bucket_into_opts!(opts, bucket)

    case Scrypath.Options.validate_search_options(schema_module, merged_opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, _} = error ->
        error

      {:ok, search_opts} ->
        Single.run(schema_module, text, search_opts, merged_opts,
          search_scope: :within_facet,
          scoped_facet: elem(bucket, 0)
        )
    end
  end

  @spec search_within_facet!(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          SearchResult.t()
  def search_within_facet!(schema_module, text, bucket, opts \\ []) do
    case search_within_facet(schema_module, text, bucket, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  @spec search_facet_values(module(), String.t(), String.t(), keyword()) ::
          {:ok, Scrypath.FacetSearchResult.t()} | {:error, term()}
  def search_facet_values(schema_module, facet_name, search_string, opts \\ [])
      when is_binary(facet_name) and is_binary(search_string) and is_list(opts) do
    case Scrypath.Options.validate_search_options(schema_module, opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, _} = error ->
        error

      {:ok, search_opts} ->
        FacetValues.run(schema_module, facet_name, search_string, search_opts, opts)
    end
  end

  @spec search_facet_values!(module(), String.t(), String.t(), keyword()) ::
          Scrypath.FacetSearchResult.t()
  def search_facet_values!(schema_module, facet_name, search_string, opts \\ []) do
    case search_facet_values(schema_module, facet_name, search_string, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  @spec search_many(list(), keyword()) :: {:ok, MultiSearchResult.t()} | {:error, term()}
  def search_many(entries, shared_opts \\ []) when is_list(entries) and is_list(shared_opts) do
    raw = length(entries)

    Telemetry.span([:scrypath, :search_many], %{schema_count: raw, raw_entry_count: raw}, fn ->
      {result, count_meta} = Many.run(entries, shared_opts)
      Many.emit_partial(result)

      stop = result |> Telemetry.stop_metadata() |> Map.merge(count_meta)
      {result, stop}
    end)
  end

  @spec search_many!(list(), keyword()) :: MultiSearchResult.t()
  def search_many!(entries, shared_opts \\ []) do
    case search_many(entries, shared_opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  defp merge_facet_bucket_into_opts!(opts, {attr, value}) when is_atom(attr) do
    existing = Keyword.get(opts, :facet_filter, [])

    if Keyword.has_key?(existing, attr) do
      raise ArgumentError,
            "search_within_facet: facet_filter already contains #{inspect(attr)}; " <>
              "omit that key from facet_filter: or use Scrypath.search/3 instead of locking the same attribute twice"
    else
      Keyword.put(opts, :facet_filter, Keyword.put(existing, attr, value))
    end
  end

  defp merge_facet_bucket_into_opts!(_opts, {bad, _value}) do
    raise ArgumentError,
          "search_within_facet: facet_bucket attribute must be an atom, got: #{inspect(bad)}"
  end

  defp merge_facet_bucket_into_opts!(_opts, bucket) do
    raise ArgumentError,
          "search_within_facet: facet_bucket must be a two-element tuple {facet_attribute, value}, got: #{inspect(bucket)}"
  end
end
