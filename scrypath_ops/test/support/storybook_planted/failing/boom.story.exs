defmodule ScrypathOps.Catalog.Stories.Planted.Boom do
  use PhoenixStorybook.Story, :component

  # Planted failure: the component itself raises, so the iframe LiveView exits when it renders.
  def boom(_assigns), do: raise("planted render failure")

  def function, do: &__MODULE__.boom/1
  def container, do: :iframe

  def variations do
    [%Variation{id: :boom}]
  end
end
