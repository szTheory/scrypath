integration? = System.get_env("SCRYPATH_INTEGRATION") in ["1", "true", "TRUE"]
postgres? = System.get_env("SCRYPATH_POSTGRES_URL") not in [nil, ""]

# One composed exclude list: ExUnit.configure/1 replaces :exclude, so every
# lane-gating tag is decided here and configured once.
#
# :requires_clean_workspace — `Mix.Tasks.Verify.WorkspaceClean` hits the real
# repo; skip locally when packaged paths are dirty (see CI: --include below).
#
# :postgres — real-Postgres loader/backfill cases; excluded unless
# SCRYPATH_POSTGRES_URL is set, independent of SCRYPATH_INTEGRATION.
exclude =
  if(integration?, do: [], else: [:integration, :requires_clean_workspace]) ++
    if(postgres?, do: [], else: [:postgres])

ExUnit.configure(exclude: exclude)

ExUnit.start()

"test/support/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
