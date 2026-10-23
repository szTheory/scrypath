defmodule ScrypathOpsWeb.Router do
  @moduledoc """
  Provides the `scrypath_ops_routes/2` macro to mount the Scrypath Ops UI in a host Phoenix application.
  """

  @doc """
  Mounts the Scrypath Ops UI routes in the host application router.

  ## Options

    * `:repo` - (Required) The Ecto Repo to use for search health checks, telemetry and saved
      searches. Run `ScrypathOps.Migration` in this Repo to create the saved searches table.
    * `:prefix` - (Optional) The Postgres schema that holds the ScrypathOps tables. Use the same
      value you passed to `ScrypathOps.Migration`. Defaults to the Repo's default schema.
  """
  defmacro scrypath_ops_routes(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      validated_opts = ScrypathOpsWeb.Router.__options__(opts)

      # Assign the mount path so the engine knows its own base path
      validated_opts = Keyword.put(validated_opts, :mount_path, path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 2, live: 3, live: 4, live_session: 3]
        import Phoenix.Router, only: [forward: 2, forward: 3]

        forward("/assets", ScrypathOpsWeb.AssetPlug, path_prefix: "assets")
        forward("/images", ScrypathOpsWeb.AssetPlug, path_prefix: "images")
        forward("/favicon.svg", ScrypathOpsWeb.AssetPlug, path_prefix: "favicon.svg")
        forward("/favicon.ico", ScrypathOpsWeb.AssetPlug, path_prefix: "favicon.ico")

        live_session :ops,
          on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}],
          session: %{"scrypath_ops_opts" => validated_opts} do
          live("/", ScrypathOpsWeb.ControlRoomLive)
          live("/health", ScrypathOpsWeb.PostureLive)
          live("/posture", ScrypathOpsWeb.PostureLive, :legacy)
          live("/failed-sync", ScrypathOpsWeb.FailedSyncLive)
          live("/sync-drift", ScrypathOpsWeb.SyncDriftLive)
          live("/search", ScrypathOpsWeb.SearchLive)
          live("/playbooks", ScrypathOpsWeb.SearchLive, :legacy_saved_searches)
          live("/help", ScrypathOpsWeb.HelpLive)
        end
      end
    end
  end

  @doc false
  def __options__(opts) do
    schema = [
      repo: [
        type: :atom,
        required: true,
        doc: "The Ecto.Repo module"
      ],
      prefix: [
        type: {:or, [:string, nil]},
        default: nil,
        doc: "The Postgres schema that holds the ScrypathOps tables"
      ]
    ]

    NimbleOptions.validate!(opts, schema)
  end
end
