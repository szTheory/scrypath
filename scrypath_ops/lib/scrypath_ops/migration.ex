defmodule ScrypathOps.Migration do
  @moduledoc """
  Versioned migrations for the tables ScrypathOps stores in the host application's database.

  ScrypathOps keeps saved searches in a `scrypath_ops_saved_searches` table in the Repo you pass
  to `scrypath_ops_routes/2`. Like `Oban.Migration`, the schema is versioned so later releases can
  add changes without asking you to copy SQL. Generate a migration in your app:

      mix ecto.gen.migration add_scrypath_ops

  Then call this module from it:

      defmodule MyApp.Repo.Migrations.AddScrypathOps do
        use Ecto.Migration

        def up, do: ScrypathOps.Migration.up(version: 1)

        # Pass `version: 1` to drop every ScrypathOps table.
        def down, do: ScrypathOps.Migration.down(version: 1)
      end

  When a later release adds a version, generate another migration that calls `up/1` with the new
  `version:` and `down/1` with the same version, so rolling back undoes only that step.

  ## Options

    * `:version` - for `up/1`, the version to migrate to (defaults to the latest, `1`). For
      `down/1`, the lowest version to remove; every version from the current one down to it is
      reverted (defaults to `1`, which removes all ScrypathOps tables).
    * `:prefix` - the Postgres schema that holds the tables (defaults to `"public"`). Pass the
      same value as the `:prefix` option of `scrypath_ops_routes/2`. The schema must already exist.

  The applied version is recorded as a comment on the `scrypath_ops_saved_searches` table, so
  `up/1` skips versions that are already applied and is safe to run again.

  ## Repos that guard queries

  If your Repo's `prepare_query/3` callback requires an option such as a tenant id, let queries
  on tables whose names start with `scrypath_ops_` through, as you would for `oban_` tables.
  """

  use Ecto.Migration

  @initial_version 1
  @current_version 1
  @default_prefix "public"
  @version_table "scrypath_ops_saved_searches"

  @doc """
  Migrates the ScrypathOps tables up to `:version`. Call it from an `Ecto.Migration`.
  """
  @spec up(keyword()) :: :ok
  def up(opts \\ []) when is_list(opts) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        change(@initial_version..opts.version//1, :up, opts)

      initial < opts.version ->
        change((initial + 1)..opts.version//1, :up, opts)

      true ->
        :ok
    end
  end

  @doc """
  Reverts the ScrypathOps tables down to, and including, `:version`. Call it from an
  `Ecto.Migration`.
  """
  @spec down(keyword()) :: :ok
  def down(opts \\ []) when is_list(opts) do
    opts = with_defaults(opts, @initial_version)
    initial = max(migrated_version(opts), @initial_version)

    if initial >= opts.version do
      change(initial..opts.version//-1, :down, opts)
    else
      :ok
    end
  end

  @doc """
  Returns the latest migration version this release provides.
  """
  @spec current_version() :: pos_integer()
  def current_version, do: @current_version

  @doc """
  Returns the version recorded in the database, or `0` when no ScrypathOps tables exist.

  Must run inside a migration, where `repo/0` is available.
  """
  @spec migrated_version(keyword() | map()) :: non_neg_integer()
  def migrated_version(opts) when is_list(opts),
    do: opts |> with_defaults(1) |> migrated_version()

  def migrated_version(%{prefix: prefix}) do
    query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = $1
    AND pg_namespace.nspname = $2
    """

    case repo().query(query, [@version_table, prefix], log: false) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
      _ -> 0
    end
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad = String.pad_leading(Integer.to_string(index), 2, "0")
      module = Module.concat([ScrypathOps.Migrations, "V#{pad}"])
      apply(module, direction, [opts])
    end

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, Enum.min(range) - 1)
    end
  end

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{quoted_prefix: quoted}, version) do
    execute("COMMENT ON TABLE #{quoted}.#{@version_table} IS '#{version}'")
  end

  defp with_defaults(opts, default_version) do
    opts = Enum.into(opts, %{prefix: @default_prefix, version: default_version})

    unless is_binary(opts.prefix) and opts.prefix != "" do
      raise ArgumentError,
            "expected :prefix to be a non-empty string, got: #{inspect(opts.prefix)}"
    end

    unless is_integer(opts.version) and opts.version in @initial_version..@current_version do
      raise ArgumentError,
            "expected :version to be an integer from #{@initial_version} to #{@current_version}, " <>
              "got: #{inspect(opts.version)}"
    end

    Map.put(opts, :quoted_prefix, inspect(opts.prefix))
  end
end
