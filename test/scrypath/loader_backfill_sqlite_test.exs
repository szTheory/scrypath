defmodule Scrypath.LoaderBackfillSQLiteTest do
  use ExUnit.Case, async: false
  use Scrypath.TestSupport.LoaderBackfillCases, repo: Scrypath.TestSupport.SQLiteSandboxRepo
end
