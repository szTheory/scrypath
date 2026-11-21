defmodule ScrypathOps.Catalog.Stories.Primitives.OpsPanel do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_panel/1
  def container, do: :iframe

  # The class attribute only appends a caller class, which has no visible effect on its own, so
  # there is a single variation.
  def variations do
    [
      %Variation{id: :default, slots: ["<p>Panel body copy</p>"]}
    ]
  end
end
