defmodule ScrypathOps.Catalog.Indexes.Areas do
  # Tier 3 of 5 (primitives, patterns, areas, surfaces, jobs); `patterns/` (index 1) arrives with
  # its first story.
  use PhoenixStorybook.Index

  def folder_name, do: "Areas"
  def folder_open?, do: true
  def folder_index, do: 2
end
