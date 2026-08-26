defmodule Scrypath.Composition do
  @moduledoc """
  Public plain-data composition seam for reusable search presets and additive scopes.

  Host apps define feature-level or context-owned fragments such as `%{defaults: ...}`
  and `%{fixed: ...}`. This module composes those fragments into the same plain-data
  criteria vocabulary already accepted by `Scrypath.search/3`.

  `Scrypath.Composition` is data-only:

  - it never executes search
  - it never exposes `%Scrypath.Query{}`
  - it does not move composition ownership onto schemas or `Scrypath.Phoenix`

  The composed result stays a plain map that includes final criteria plus coarse
  visibility buckets: `applied`, `defaulted`, `fixed`, and optional `sources`
  or `warnings`.
  """

  alias Scrypath.Composition.Compose
  alias Scrypath.Composition.Multi
  alias Scrypath.Composition.Result

  @typedoc "Public fragment envelope used to compose presets and scopes."
  @type fragment :: %{
          optional(:defaults) => fragment_criteria(),
          optional(:fixed) => fixed_criteria(),
          optional(:sources) => map(),
          optional(:warnings) => map()
        }

  @typedoc "Caller-facing criteria vocabulary aligned with `Scrypath.search/3`."
  @type criteria :: %{
          optional(:text) => String.t(),
          optional(:filter) => keyword(),
          optional(:sort) => keyword(),
          optional(:page) => keyword(),
          optional(:facets) => [atom()],
          optional(:facet_filter) => keyword(),
          optional(:per_query) => map()
        }

  @typedoc "Allowed fragment defaults for all public search fields."
  @type fragment_criteria :: criteria()

  @typedoc "Allowed fragment fixed constraints for filter-bearing fields only."
  @type fixed_criteria :: %{
          optional(:filter) => keyword(),
          optional(:facet_filter) => keyword()
        }

  @typedoc "Stable public result returned by `compose/2`."
  @type result :: Result.t()

  @typedoc """
  Public multi-search entry spec consumed by `compose_many/2`.
  """
  @type many_entry_spec :: %{
          required(:schema) => module() | :all,
          required(:text) => String.t(),
          optional(:fragments) => fragment() | [fragment()],
          optional(:criteria) => criteria()
        }

  @typedoc """
  Public multi-search composition result. Shared composition lowers defaults only,
  per-entry composition stays canonical, and `to_search_many_args/1` emits the
  existing tuple/shared-option contract for `Scrypath.search_many/2`.
  """
  @type many_result :: %{
          required(:shared) => result(),
          required(:entries) => [map()]
        }

  @doc """
  Composes one fragment or a list of fragments with caller criteria.
  """
  @spec compose(fragment() | [fragment()], criteria()) :: {:ok, result()} | {:error, term()}
  def compose(fragments, criteria \\ %{}) do
    Compose.compose(fragments, criteria)
  end

  @doc """
  Like `compose/2`, but raises `ArgumentError` instead of returning `{:error, reason}`.
  """
  @spec compose!(fragment() | [fragment()], criteria()) :: result()
  def compose!(fragments, criteria \\ %{}) do
    case compose(fragments, criteria) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "composition failed: #{inspect(reason)}"
    end
  end

  @doc """
  Converts the composed plain-data result into `{text, keyword_opts}` for a
  context-owned `Scrypath.search/3` call.
  """
  @spec to_search_args(result()) :: {String.t(), keyword()}
  def to_search_args(%{} = composition) do
    Compose.to_search_args(composition)
  end

  @doc """
  Composes multi-search entries into the existing tuple/shared-option contract.

  Shared composition lowers defaults only. Shared fixed constraints are not
  supported, and multi-search-only rails such as federation weights or
  `max_schemas` stay outside this helper.
  """
  @spec compose_many([many_entry_spec() | tuple()], keyword()) ::
          {:ok, many_result()} | {:error, term()}
  def compose_many(entries, opts \\ []) do
    Multi.compose_many(entries, opts)
  end

  @doc """
  Like `compose_many/2`, but raises `ArgumentError` instead of returning
  `{:error, reason}`.
  """
  @spec compose_many!([many_entry_spec() | tuple()], keyword()) :: many_result()
  def compose_many!(entries, opts \\ []) do
    Multi.compose_many!(entries, opts)
  end

  @doc """
  Lowers a multi-search composition result into `{entries, shared_opts}` for a
  context-owned `Scrypath.search_many/2` call.
  """
  @spec to_search_many_args(many_result()) :: {list(), keyword()}
  def to_search_many_args(%{entries: _entries, shared: _shared} = composition) do
    Multi.to_search_many_args(composition)
  end
end
