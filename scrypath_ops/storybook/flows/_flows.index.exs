defmodule ScrypathOps.Catalog.Indexes.Flows do
  # Tier 5 of 5 (primitives, patterns, areas, screens, flows): one screen state in one persona's job
  # situation, such as the on-call engineer holding a retry receipt. Each story names the mounted test
  # that proves what its caption claims. The cross-screen walk itself is the journey test, not a story.
  use PhoenixStorybook.Index

  def folder_name, do: "Flows"
  def folder_open?, do: true
  def folder_index, do: 4
end
