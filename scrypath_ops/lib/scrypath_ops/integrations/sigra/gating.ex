if Code.ensure_loaded?(Sigra.Audit) do
  defmodule ScrypathOps.Integrations.Sigra.Gating do
    @moduledoc false

    alias ScrypathOps.OperatorSelection

    @action_config %{
      playbook_delete: "scrypath.ops.playbook_delete",
      failed_work_retry: "scrypath.ops.failed_work_retry",
      swap_live: "scrypath.ops.swap_live",
      reindex: "scrypath.ops.reindex",
      delete_documents: "scrypath.ops.delete_documents",
      hot_apply: "scrypath.ops.hot_apply"
    }

    @actions Map.keys(@action_config)

    @spec __action_config__() :: %{required(atom()) => String.t()}
    def __action_config__, do: @action_config

    def gate_sensitive_action(socket, action, fun)
        when action in @actions and is_function(fun, 0) do
      case Map.get(socket.assigns, :operator_context) do
        nil ->
          fun.()

        %{impersonator_user_id: impersonator_user_id} = _operator_context
        when not is_nil(impersonator_user_id) ->
          socket
          |> Phoenix.LiveView.put_flash(
            :error,
            "Impersonation must be cleared before this action."
          )

        %{sudo_at: sudo_at} = operator_context ->
          if stale_sudo?(sudo_at) do
            confirm_path = confirm_path()
            return_to = return_to(socket)

            socket
            |> Phoenix.LiveView.push_navigate(
              to: confirm_path <> "?" <> URI.encode_query(return_to: return_to)
            )
          else
            audit_action(action, operator_context, socket)
            fun.()
          end
      end
    end

    defp audit_action(action, operator_context, socket) do
      current_scope = Map.get(socket.assigns, :current_scope)

      Sigra.Audit.log_safe(action_prefix(action), current_scope,
        actor_id: operator_context.user_id,
        organization_id: operator_context.active_org_id,
        impersonator_user_id: operator_context.impersonator_user_id,
        sudo_at: operator_context.sudo_at
      )
    end

    defp action_prefix(action) when action in @actions do
      Map.fetch!(@action_config, action)
    end

    defp stale_sudo?(%DateTime{} = sudo_at) do
      sudo_window_seconds = Keyword.get(sigra_config(), :sudo_window, 300)

      DateTime.diff(DateTime.utc_now(), sudo_at, :second) > sudo_window_seconds
    end

    defp stale_sudo?(_), do: true

    defp confirm_path do
      Keyword.get(sigra_config(), :sudo_confirm_path, "/sudo/confirm")
    end

    defp return_to(%{assigns: assigns, host_uri: %URI{path: path}}) do
      assigns
      |> Map.get(:return_to)
      |> local_return_path(path || "/")
      |> append_selected_schema(validated_schema(assigns))
    end

    defp return_to(%{assigns: assigns}) do
      assigns
      |> Map.get(:return_to)
      |> local_return_path("/")
      |> append_selected_schema(validated_schema(assigns))
    end

    defp local_return_path(candidate, fallback) do
      if local_path?(candidate),
        do: candidate,
        else: if(local_path?(fallback), do: fallback, else: "/")
    end

    defp local_path?(path) when is_binary(path) do
      uri = URI.parse(path)

      uri.path != nil and String.starts_with?(uri.path, "/") and
        not String.starts_with?(uri.path, "//") and is_nil(uri.scheme) and is_nil(uri.host) and
        not Regex.match?(~r/%(?:2f|5c)/i, uri.path) and
        not String.contains?(path, ["\\", "\r", "\n"])
    rescue
      ArgumentError -> false
    end

    defp local_path?(_path), do: false

    defp validated_schema(assigns) do
      case Map.get(assigns, :selected_schema) do
        schema when is_atom(schema) and not is_nil(schema) ->
          canonical = OperatorSelection.canonical(schema)

          case OperatorSelection.resolve(
                 %{"schema" => canonical},
                 ScrypathOps.Schemas.allowlist()
               ) do
            {:ok, ^schema} -> canonical
            _ -> nil
          end

        _ ->
          nil
      end
    end

    defp append_selected_schema(path, schema) do
      uri = URI.parse(path)

      query =
        try do
          uri.query |> decode_query() |> Map.delete("schema")
        rescue
          ArgumentError -> %{}
        end

      query = if schema, do: Map.put(query, "schema", schema), else: query
      encoded_query = if map_size(query) == 0, do: nil, else: URI.encode_query(query)

      URI.to_string(%{uri | query: encoded_query})
    end

    defp decode_query(nil), do: %{}
    defp decode_query(query), do: URI.decode_query(query)

    defp sigra_config do
      Application.get_env(:scrypath_ops, :sigra, [])
    end
  end
else
  defmodule ScrypathOps.Integrations.Sigra.Gating do
    @moduledoc false

    @action_config %{
      playbook_delete: "scrypath.ops.playbook_delete",
      failed_work_retry: "scrypath.ops.failed_work_retry",
      swap_live: "scrypath.ops.swap_live",
      reindex: "scrypath.ops.reindex",
      delete_documents: "scrypath.ops.delete_documents",
      hot_apply: "scrypath.ops.hot_apply"
    }

    @spec __action_config__() :: %{required(atom()) => String.t()}
    def __action_config__, do: @action_config

    def gate_sensitive_action(_socket, _action, fun) when is_function(fun, 0), do: fun.()
  end
end
