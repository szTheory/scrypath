defmodule Scrypath.TestSupport.PostgresRepo do
  @moduledoc false

  # Real-Postgres repo for the shared loader/backfill cases (`:postgres` tag).
  #
  # Reads only the namespaced SCRYPATH_POSTGRES_URL. The harness drops and
  # recreates this repo's database, so the database name is forced to the
  # throwaway `scrypath_test<MIX_TEST_PARTITION>` after URL parsing: a URL that
  # points at a real dev server can only ever drop the test database. The URL
  # is parsed here (not passed as `url:`), because `url:` would win over
  # `database:`.

  use Ecto.Repo,
    otp_app: :scrypath,
    adapter: Ecto.Adapters.Postgres

  @impl true
  def init(_type, config) do
    database = "scrypath_test#{System.get_env("MIX_TEST_PARTITION")}"
    url = System.fetch_env!("SCRYPATH_POSTGRES_URL")

    {:ok,
     config
     |> Keyword.merge(Ecto.Repo.Supervisor.parse_url(with_database_path(url, database)))
     |> Keyword.merge(
       database: database,
       pool: Ecto.Adapters.SQL.Sandbox,
       pool_size: 10,
       log: false
     )}
  end

  # parse_url/1 rejects a URL without a database path, and the documented
  # server-only URL (postgres://user:pass@host:port) has none. Any path in the
  # URL is overridden by the forced database name above.
  defp with_database_path(url, database) do
    case URI.parse(url) do
      %URI{path: path} = uri when path in [nil, "", "/"] ->
        URI.to_string(%{uri | path: "/" <> database})

      _uri ->
        url
    end
  end
end
