defmodule ScrypathOps.Catalog.Stories.Primitives.OpsButton do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_button/1
  def container, do: :iframe

  def variations do
    [
      %Variation{id: :default, slots: ["Retry"]},
      %Variation{id: :primary, attributes: %{variant: :primary}, slots: ["Retry failed work"]},
      %Variation{
        id: :secondary,
        attributes: %{variant: :secondary, size: :sm},
        slots: ["Dismiss"]
      }
    ]
  end
end
