unless System.get_env("SCRYPATH_EXAMPLE_INTEGRATION") in ["1", "true", "TRUE"] do
  ExUnit.configure(exclude: [:integration])
end

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ScrypathDemo.Repo, :manual)
