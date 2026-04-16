defmodule Scrypath.TestSupport.IntegrationRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :scrypath,
    adapter: Ecto.Adapters.SQLite3
end
