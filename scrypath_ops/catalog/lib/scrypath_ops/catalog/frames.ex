defmodule ScrypathOps.Catalog.Frames do
  @moduledoc false

  # The library's default frame is a centred column, which shrinks a component to fit its text. An
  # area fills the content column on its real screen, so its frame stretches it the same way.
  @area_style "display: flex; flex-direction: column; align-items: stretch; margin: 0; gap: 5px; padding: 5px;"

  @spec area() :: {:iframe, keyword()}
  def area, do: {:iframe, style: @area_style}
end
