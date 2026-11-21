defmodule ScrypathOps.Catalog.Stories.Primitives.OpsSyncStatus do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_sync_status/1
  def container, do: :iframe

  # The four statuses the component accepts: each is a word plus a shape that reads without color.
  def variations do
    for status <- [:failed, :retrying, :pending, :clear] do
      %Variation{id: status, attributes: %{status: status}}
    end
  end
end
