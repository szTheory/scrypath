defmodule ScrypathOps.Catalog.Stories.Planted.Empty do
  use PhoenixStorybook.Story, :component

  import Phoenix.Component, only: [sigil_H: 2]

  # Planted failure: the component renders nothing, so the sandbox has no child and no text.
  def empty(assigns), do: ~H""

  def function, do: &__MODULE__.empty/1
  def container, do: :iframe

  def variations do
    [%Variation{id: :empty}]
  end
end
