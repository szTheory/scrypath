defmodule ScrypathOps.SearchPlayground do
  @moduledoc """
  Bounded search playground limits and adapter dispatch for `/ops/search`.

  Validates `page.size` before any `Scrypath` call so operators see explicit
  errors instead of silent library rejection. Schema breadth aligns with the library default (`max_schemas: 10`).
  The host controls the response budget; this is not the per-query multi-search page cap.
  """

  alias ScrypathOps.SearchPlayground.Adapter

  @default_max_page 50
  @library_default_max_schemas 10

  @doc """
  Default page size for playground queries (**15**) unless configured.
  """
  @spec default_page_size() :: pos_integer()
  def default_page_size do
    max = max_page_size_allowed()

    case Application.get_env(:scrypath_ops, :search_playground_default_page_size) do
      n when is_integer(n) and n >= 1 -> min(n, max)
      _ -> min(15, max)
    end
  end

  @doc """
  Effective maximum `page.size` allowed in the playground (default **50**).

  Hosts may set `:search_playground_max_page_size` under `:scrypath_ops`; values
  must be positive. This bounds one single or combined response, not all matches.
  The core per-query multi-search page guard is separate and remains unchanged.
  """
  @spec max_page_size_allowed() :: pos_integer()
  def max_page_size_allowed do
    raw =
      Application.get_env(:scrypath_ops, :search_playground_max_page_size) || @default_max_page

    raw = if is_integer(raw), do: raw, else: @default_max_page
    max(raw, 1)
  end

  @doc """
  Maximum number of schemas selectable for multi-search (**1..10**).

  Invalid configured values are ignored and the library default (**10**) applies.
  """
  @spec max_schemas_allowed() :: pos_integer()
  def max_schemas_allowed do
    case Application.get_env(:scrypath_ops, :search_playground_max_schemas) do
      n when is_integer(n) and n >= 1 and n <= @library_default_max_schemas -> n
      _ -> @library_default_max_schemas
    end
  end

  @doc """
  Validates a requested page size without calling `Scrypath`.
  """
  @spec validate_page_size(term()) ::
          :ok | {:error, {:page_size_out_of_range, integer(), pos_integer()}}
  def validate_page_size(n) when is_integer(n) do
    max = max_page_size_allowed()

    cond do
      n < 1 -> {:error, {:page_size_out_of_range, n, max}}
      n > max -> {:error, {:page_size_out_of_range, n, max}}
      true -> :ok
    end
  end

  def validate_page_size(n), do: {:error, {:page_size_out_of_range, n, max_page_size_allowed()}}

  @doc false
  @spec adapter() :: module()
  def adapter do
    Application.get_env(
      :scrypath_ops,
      :search_playground_adapter,
      Adapter.Scrypath
    )
  end

  @doc false
  @spec dispatch_search(module(), String.t(), keyword()) :: Adapter.search_result()
  def dispatch_search(schema, text, opts) do
    adapter().search(schema, text, opts)
  end

  @doc false
  @spec dispatch_search_many(list(), keyword()) :: Adapter.search_many_result()
  def dispatch_search_many(entries, opts) do
    adapter().search_many(entries, opts)
  end
end
