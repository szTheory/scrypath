if System.get_env("SCRYPATH_TAP") == "1" do
  ExUnit.start(formatters: [ScrypathOps.Test.TapFormatter])
else
  ExUnit.start()
end
Ecto.Adapters.SQL.Sandbox.mode(ScrypathOps.Repo, :manual)
