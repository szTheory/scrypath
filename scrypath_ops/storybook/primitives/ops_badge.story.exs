defmodule ScrypathOps.Catalog.Stories.Primitives.OpsBadge do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_badge/1
  def container, do: :iframe

  # A badge is plain muted text and its `kind` has no visual effect (see `ops_badge/1`), so one
  # variation shows it. Seven kinds would render seven identical looks and imply states that do not
  # exist; sync states are the `ops_sync_status` story.
  def variations do
    [
      %Variation{id: :default, slots: ["Idle"]}
    ]
  end
end
