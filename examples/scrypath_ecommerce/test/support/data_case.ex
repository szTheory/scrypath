defmodule ScrypathEcommerce.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      alias ScrypathEcommerce.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import ScrypathEcommerce.DataCase
    end
  end

  setup tags do
    ScrypathEcommerce.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(ScrypathEcommerce.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
