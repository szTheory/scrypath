defmodule Scrypath.TestSupport.FakeRepo do
  @moduledoc false

  # Oban job args name the repo; workers only accept a module that looks like an Ecto repo.
  def __adapter__, do: Ecto.Adapters.SQLite3

  def put_records(records) when is_list(records) do
    Process.put({__MODULE__, :records}, records)
    :ok
  end

  def reset do
    Process.delete({__MODULE__, :records})
    :ok
  end

  def all(%Ecto.Query{} = query) do
    send(self(), {:fake_repo_all, query})
    Process.get({__MODULE__, :records}, [])
  end
end
