defmodule ScrypathOps.Repo do
  use Ecto.Repo,
    otp_app: :scrypath_ops,
    adapter: Ecto.Adapters.Postgres
end
