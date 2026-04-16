unless System.get_env("SCRYPATH_INTEGRATION") in ["1", "true", "TRUE"] do
  ExUnit.configure(exclude: [:integration])
end

ExUnit.start()

"test/support/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
