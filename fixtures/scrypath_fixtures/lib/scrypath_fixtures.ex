defmodule ScrypathFixtures do
  @moduledoc """
  Fictional adopter data for Scrypath's operator UI, for development and tests only.

  Every adopter here (Shopadelic, Logistify, Wikily) is invented, and nothing is copied from a real
  product. The builders emit raw Meilisearch task maps and Oban job maps, so the real Scrypath code
  does the normalizing and only states the library can produce exist (ADR 0002).

  This project is a path dependency of `scrypath_ops` with `only: [:dev, :test]`. It must never
  appear in a release, a production build or the Hex tarball.
  """

  @preview_epoch ~U[2026-11-20 14:00:00Z]

  @doc """
  The one pinned instant that scenarios and previews use as "now".

  Builders never read the wall clock: every stamp is this instant (or any `now` a caller passes)
  minus an offset. This function holds the only datetime literal in the project.
  """
  @spec preview_epoch() :: DateTime.t()
  def preview_epoch, do: @preview_epoch
end
