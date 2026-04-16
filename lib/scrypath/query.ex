defmodule Scrypath.Query do
  @moduledoc """
  Internal normalized search query struct used by the common search path and
  backend adapters.
  """

  @enforce_keys [:text]
  defstruct text: nil, filter: [], sort: [], page: %{}

  @typedoc "Normalized pagination options."
  @type page_t :: %{optional(:number) => pos_integer(), optional(:size) => pos_integer()}

  @typedoc "Internal normalized search query."
  @type t :: %__MODULE__{
          text: String.t(),
          filter: keyword(),
          sort: keyword(),
          page: page_t()
        }

  @spec new(String.t(), keyword()) :: t()
  def new(text, opts) when is_binary(text) and is_list(opts) do
    %__MODULE__{
      text: text,
      filter: Keyword.get(opts, :filter, []),
      sort: Keyword.get(opts, :sort, []),
      page: normalize_page(Keyword.get(opts, :page, %{}))
    }
  end

  defp normalize_page(page) when is_map(page), do: page
  defp normalize_page(page) when is_list(page), do: Enum.into(page, %{})
end
