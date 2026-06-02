defmodule ScrypathOpsWeb.Router do
  @moduledoc """
  Provides the `scrypath_ops_routes/2` macro to mount the Scrypath Ops UI in a host Phoenix application.
  """

  @doc """
  Mounts the Scrypath Ops UI routes in the host application router.

  ## Options

    * `:repo` - (Required) The Ecto Repo to use for posture and telemetry.
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

        live_session :ops,
          on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}],
          session: %{"scrypath_ops_opts" => validated_opts} do
          live("/", ScrypathOpsWeb.ControlRoomLive)
          live("/posture", ScrypathOpsWeb.PostureLive)
          live("/failed-sync", ScrypathOpsWeb.FailedSyncLive)
          live("/sync-drift", ScrypathOpsWeb.SyncDriftLive)
          live("/search", ScrypathOpsWeb.SearchLive)
          live("/playbooks", ScrypathOpsWeb.PlaybookLive)
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
      ]
    ]

    NimbleOptions.validate!(opts, schema)
  end
end
