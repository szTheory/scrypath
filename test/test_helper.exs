unless System.get_env("SCRYPATH_INTEGRATION") in ["1", "true", "TRUE"] do
  # :requires_clean_workspace — `Mix.Tasks.Verify.WorkspaceClean` hits the real
  # repo; skip locally when packaged paths are dirty (see CI: --include below).
  ExUnit.configure(exclude: [:integration, :requires_clean_workspace])
end

ExUnit.start()

"test/support/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
