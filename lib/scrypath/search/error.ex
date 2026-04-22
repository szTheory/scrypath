defmodule Scrypath.Search.Error do
  @moduledoc "Raised by bang search helpers when the matching non-bang API would return `{:error, reason}`."
  defexception [:reason]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    Scrypath.Errors.format_reason(reason)
  end
end
