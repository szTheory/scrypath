defmodule Scrypath.LoaderBackfillPostgresTest do
  use ExUnit.Case, async: false

  # Excluded unless SCRYPATH_POSTGRES_URL is set (see test/test_helper.exs).
  @moduletag :postgres

  use Scrypath.TestSupport.LoaderBackfillCases, repo: Scrypath.TestSupport.PostgresRepo
end
