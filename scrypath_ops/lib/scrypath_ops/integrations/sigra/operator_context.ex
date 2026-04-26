if Code.ensure_loaded?(Sigra.Session) do
  defmodule ScrypathOps.Integrations.Sigra.OperatorContext do
    @moduledoc false

    @enforce_keys [:user_id, :active_org_id]
    defstruct [:user_id, :active_org_id, :impersonator_user_id, :sudo_at]

    @type t :: %__MODULE__{
            user_id: term(),
            active_org_id: term(),
            impersonator_user_id: term() | nil,
            sudo_at: DateTime.t() | nil
          }

    @spec build(scope :: struct() | nil, sigra_session :: struct() | nil) :: t() | nil
    def build(%{user: %{id: user_id}} = scope, sigra_session) do
      %__MODULE__{
        user_id: user_id,
        active_org_id: active_org_id(scope),
        impersonator_user_id: impersonator_user_id(scope, sigra_session),
        sudo_at: sudo_at(sigra_session)
      }
    end

    def build(_scope, _sigra_session), do: nil

    @spec from_socket(Phoenix.LiveView.Socket.t()) :: t() | nil
    def from_socket(%{assigns: assigns}) do
      build(Map.get(assigns, :current_scope), Map.get(assigns, :sigra_session))
    end

    defp active_org_id(%{active_organization: %{id: id}}), do: id
    defp active_org_id(_), do: nil

    defp impersonator_user_id(%{impersonating_from: %{id: id}}, _sigra_session), do: id
    defp impersonator_user_id(_scope, %{impersonator_user_id: id}) when not is_nil(id), do: id
    defp impersonator_user_id(_scope, _sigra_session), do: nil

    defp sudo_at(%{sudo_at: %DateTime{} = sudo_at}), do: sudo_at
    defp sudo_at(_sigra_session), do: nil
  end
else
  defmodule ScrypathOps.Integrations.Sigra.OperatorContext do
    @moduledoc false

    @enforce_keys [:user_id, :active_org_id]
    defstruct [:user_id, :active_org_id, :impersonator_user_id, :sudo_at]

    @type t :: %__MODULE__{
            user_id: term(),
            active_org_id: term(),
            impersonator_user_id: term() | nil,
            sudo_at: DateTime.t() | nil
          }

    @spec build(scope :: struct() | nil, sigra_session :: struct() | nil) :: t() | nil
    def build(%{user: %{id: user_id}} = scope, sigra_session) do
      %__MODULE__{
        user_id: user_id,
        active_org_id: active_org_id(scope),
        impersonator_user_id: impersonator_user_id(scope, sigra_session),
        sudo_at: sudo_at(sigra_session)
      }
    end

    def build(_scope, _sigra_session), do: nil

    @spec from_socket(Phoenix.LiveView.Socket.t()) :: t() | nil
    def from_socket(%{assigns: assigns}) do
      build(Map.get(assigns, :current_scope), Map.get(assigns, :sigra_session))
    end

    defp active_org_id(%{active_organization: %{id: id}}), do: id
    defp active_org_id(_), do: nil

    defp impersonator_user_id(%{impersonating_from: %{id: id}}, _sigra_session), do: id
    defp impersonator_user_id(_scope, %{impersonator_user_id: id}) when not is_nil(id), do: id
    defp impersonator_user_id(_scope, _sigra_session), do: nil

    defp sudo_at(%{sudo_at: %DateTime{} = sudo_at}), do: sudo_at
    defp sudo_at(_sigra_session), do: nil
  end
end
