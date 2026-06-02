defmodule ScrypathEcommerceWeb.CoreComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:flash, :map, default: %{})

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite">
      <p :if={Phoenix.Flash.get(@flash, :info)} class="flash flash-info">
        {Phoenix.Flash.get(@flash, :info)}
      </p>
      <p :if={Phoenix.Flash.get(@flash, :error)} class="flash flash-error">
        {Phoenix.Flash.get(@flash, :error)}
      </p>
    </div>
    """
  end
end
