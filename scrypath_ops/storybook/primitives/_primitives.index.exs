defmodule ScrypathOps.Catalog.Indexes.Primitives do
  # The tiers follow the glossary ladder: primitives, patterns, areas, surfaces, jobs. The index
  # numbers keep the sidebar in that order instead of alphabetical.
  use PhoenixStorybook.Index

  def folder_name, do: "Primitives"
  def folder_open?, do: true
  def folder_index, do: 0
end
