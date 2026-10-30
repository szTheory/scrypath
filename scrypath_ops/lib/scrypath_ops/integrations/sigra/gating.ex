if Code.ensure_loaded?(Sigra.Audit) do
  defmodule ScrypathOps.Integrations.Sigra.Gating do
    @moduledoc false

    alias ScrypathOps.Integrations.Sigra.OperatorContext
    alias ScrypathOps.Security

    @action_config %{
      saved_search_delete: "scrypath.ops.saved_search_delete",
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
      if Security.auth_mode() == "sigra" do
        gate_sigra_action(socket, action, fun)
      else
        gate_host_authenticated_action(socket, action, fun)
      end
    end

    @doc false
    def __audit_arguments__(action, operator_context, socket)
        when action in @actions and is_struct(operator_context, OperatorContext) do
      current_scope = Map.get(socket.assigns, :current_scope)

      {action_prefix(action), current_scope,
       [
         actor_id: operator_context.user_id,
         organization_id: operator_context.active_org_id,
         impersonator_user_id: operator_context.impersonator_user_id,
         sudo_at: operator_context.sudo_at
       ]}
    end

    defp gate_host_authenticated_action(socket, action, fun) do
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

    defp gate_sigra_action(socket, action, fun) do
      case operator_context(socket) do
        %OperatorContext{} = operator_context ->
          cond do
            not valid_identity?(operator_context.user_id) or
                not valid_identity?(operator_context.active_org_id) ->
              deny(
                socket,
                "Sigra identity and organization context are required for this action."
              )

            not is_nil(operator_context.impersonator_user_id) ->
              socket
              |> Phoenix.LiveView.put_flash(
                :error,
                "Impersonation must be cleared before this action."
              )

            true ->
              case sudo_status(operator_context.sudo_at) do
                :fresh ->
                  audit_action(action, operator_context, socket)
                  fun.()

                :stale ->
                  confirm_sudo(socket)

                :invalid ->
                  deny(socket, "A valid, current Sigra sudo confirmation is required.")
              end
          end

        _malformed_context ->
          deny(socket, "A valid Sigra operator context is required for this action.")
      end
    end

    defp operator_context(%{assigns: assigns}) when is_map(assigns),
      do: Map.get(assigns, :operator_context)

    defp operator_context(_socket), do: nil

    defp valid_identity?(value) when is_binary(value),
      do: String.valid?(value) and String.trim(value) != ""

    defp valid_identity?(value), do: not is_nil(value)

    defp deny(socket, message), do: Phoenix.LiveView.put_flash(socket, :error, message)

    defp confirm_sudo(socket) do
      confirm_path = confirm_path()
      return_to = return_to(socket)

      Phoenix.LiveView.push_navigate(socket,
        to: confirm_path <> "?" <> URI.encode_query(return_to: return_to)
      )
    end

    defp audit_action(action, operator_context, socket) do
      {audit_action, current_scope, opts} = __audit_arguments__(action, operator_context, socket)
      Sigra.Audit.log_safe(audit_action, current_scope, opts)
    end

    defp action_prefix(action) when action in @actions do
      Map.fetch!(@action_config, action)
    end

    defp sudo_status(%DateTime{} = sudo_at) do
      case sudo_window_seconds() do
        window when is_integer(window) and window >= 0 ->
          try do
            age = DateTime.diff(DateTime.utc_now(), sudo_at, :second)

            cond do
              age < 0 -> :invalid
              age > window -> :stale
              true -> :fresh
            end
          rescue
            _error -> :invalid
          catch
            _kind, _reason -> :invalid
          end

        _invalid_window ->
          :invalid
      end
    end

    defp sudo_status(nil), do: :stale
    defp sudo_status(_), do: :invalid

    defp sudo_window_seconds, do: Keyword.get(sigra_config(), :sudo_window, 300)

    defp stale_sudo?(%DateTime{} = sudo_at) do
      DateTime.diff(DateTime.utc_now(), sudo_at, :second) > sudo_window_seconds()
    end

    defp stale_sudo?(_), do: true

    defp confirm_path do
      Keyword.get(sigra_config(), :sudo_confirm_path, "/sudo/confirm")
    end

    defp return_to(%{assigns: assigns, host_uri: %URI{path: path}}) do
      Map.get(assigns, :return_to) || path || "/"
    end

    defp return_to(%{assigns: assigns}), do: Map.get(assigns, :return_to, "/")

    defp sigra_config do
      case Application.get_env(:scrypath_ops, :sigra, []) do
        config when is_list(config) -> config
        _ -> []
      end
    end
  end
else
  defmodule ScrypathOps.Integrations.Sigra.Gating do
    @moduledoc false

    alias ScrypathOps.Security

    @action_config %{
      saved_search_delete: "scrypath.ops.saved_search_delete",
      failed_work_retry: "scrypath.ops.failed_work_retry",
      swap_live: "scrypath.ops.swap_live",
      reindex: "scrypath.ops.reindex",
      delete_documents: "scrypath.ops.delete_documents",
      hot_apply: "scrypath.ops.hot_apply"
    }

    @spec __action_config__() :: %{required(atom()) => String.t()}
    def __action_config__, do: @action_config

    def gate_sensitive_action(socket, _action, fun) when is_function(fun, 0) do
      if Security.auth_mode() == "sigra" do
        Phoenix.LiveView.put_flash(
          socket,
          :error,
          "The Sigra integration is unavailable; this sensitive action was blocked."
        )
      else
        fun.()
      end
    end
  end
end
