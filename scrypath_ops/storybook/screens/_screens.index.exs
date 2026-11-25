defmodule ScrypathOps.Catalog.Indexes.Screens do
  # Tier 4 of 5 (primitives, patterns, areas, screens, flows): one whole page inside the operator
  # shell, such as Search health or Failed sync.
  use PhoenixStorybook.Index

  def folder_name, do: "Screens"
  def folder_open?, do: true
  def folder_index, do: 3
end
