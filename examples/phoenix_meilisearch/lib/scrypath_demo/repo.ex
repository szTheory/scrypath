defmodule ScrypathDemo.Repo do
  use Ecto.Repo,
    otp_app: :scrypath_demo,
    adapter: Ecto.Adapters.Postgres
end
