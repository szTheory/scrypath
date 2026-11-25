defmodule ScrypathOps.Catalog.Indexes.Patterns do
  # Tier 2 of 5 (primitives, patterns, areas, screens, flows): small groups of primitives that more
  # than one area or screen reuses, such as a filter group or a receipt. The index numbers keep the
  # sidebar in ladder order instead of alphabetical.
  use PhoenixStorybook.Index

  def folder_name, do: "Patterns"
  def folder_open?, do: true
  def folder_index, do: 1
end
