defmodule ScrypathOps.Catalog.Stories.Primitives.OpsBadge do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_badge/1
  def container, do: :iframe

  # One variation per kind the component declares; the kind only sets `data-badge-kind`.
  def variations do
    for {kind, word} <- [
          neutral: "Idle",
          info: "Queued",
          success: "Complete",
          warning: "Slow",
          error: "Failed",
          partial: "Partly synced",
          running: "Running"
        ] do
      %Variation{id: kind, attributes: %{kind: kind}, slots: [word]}
    end
  end
end
