defmodule ScrypathOps.Catalog.Stories.Primitives.OpsEmptyState do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_empty_state/1
  def container, do: :iframe

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Nothing to show"},
        slots: ["No rows yet."]
      },
      %Variation{
        id: :with_action,
        attributes: %{title: "Nothing to show"},
        slots: [
          "No rows yet.",
          "<:actions><.link href=\"#\">Open help</.link></:actions>"
        ]
      }
    ]
  end
end
