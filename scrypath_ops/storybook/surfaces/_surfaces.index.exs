defmodule ScrypathOps.Catalog.Indexes.Surfaces do
  # Tier 4 of 5 (primitives, patterns, areas, surfaces, jobs): one whole page inside the operator
  # shell, such as Search health or Failed sync.
  use PhoenixStorybook.Index

  def folder_name, do: "Surfaces"
  def folder_open?, do: true
  def folder_index, do: 3
end
