defmodule ScrypathOps.Catalog.Indexes.Areas do
  # Tier 3 of 5 (primitives, patterns, areas, surfaces, jobs): one part of a page, built from
  # patterns and primitives, such as a verdict or one failed row.
  use PhoenixStorybook.Index

  def folder_name, do: "Areas"
  def folder_open?, do: true
  def folder_index, do: 2
end
