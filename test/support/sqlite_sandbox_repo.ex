defmodule Scrypath.TestSupport.SQLiteSandboxRepo do
  @moduledoc false

  # Dedicated repo for the shared loader/backfill cases (not the shared
  # IntegrationRepo singleton). The database file path is computed once per VM
  # and cached so `config/0` and the started repo always agree.
  #
  # pool_size must stay above one: Ecto.Migrator checks out a second connection
  # for its lock, and a single-connection sandbox pool deadlocks.

  use Ecto.Repo,
    otp_app: :scrypath,
    adapter: Ecto.Adapters.SQLite3

  @impl true
  def init(_type, config) do
    {:ok,
     Keyword.merge(config,
       database: database_path(),
       pool: Ecto.Adapters.SQL.Sandbox,
       pool_size: 2,
       journal_mode: :wal,
       busy_timeout: 5_000,
       log: false
     )}
  end

  @doc false
  def database_path do
    key = {__MODULE__, :database}

    case :persistent_term.get(key, nil) do
      nil ->
        path =
          Path.join(
            System.tmp_dir!(),
            "scrypath-lb-#{System.os_time()}-#{System.unique_integer([:positive])}.db"
          )

        :persistent_term.put(key, path)
        path

      path ->
        path
    end
  end
end
