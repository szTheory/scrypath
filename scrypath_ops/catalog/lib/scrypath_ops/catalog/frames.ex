defmodule ScrypathOps.Catalog.Frames do
  @moduledoc false

  # The library's default frame is a centred column, which shrinks a component to fit its text. An
  # area, a screen and a flow fill their width in the product, so their frame stretches them too.
  @full_width_style "display: flex; flex-direction: column; align-items: stretch; margin: 0; gap: 5px; padding: 5px;"

  @spec full_width() :: {:iframe, keyword()}
  def full_width, do: {:iframe, style: @full_width_style}
end
