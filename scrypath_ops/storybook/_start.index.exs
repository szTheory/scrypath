defmodule ScrypathOps.Catalog.Indexes.Start do
  # The root of the storybook tree: only the landing page's place and label. The five tier folders
  # carry their own indexes (primitives 0 to jobs 4); the landing page goes first and reads "Start
  # here", the heading the page itself uses.
  use PhoenixStorybook.Index

  def entry("welcome"), do: [name: "Start here", index: -1]
end
