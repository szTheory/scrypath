# Test-only adapter for the GSD prohibition producer. Any mutant is compiled only
# into this disposable MIX_ENV=test BEAM; repository source is read-only here.
if Mix.env() != :test, do: raise("prohibition checks require MIX_ENV=test")

root = File.cwd!()
subject = System.get_env("GSD_PROHIB_SUBJECT")
source_path = Path.join(root, "lib/scrypath_ops_web/live/sync_drift_live.ex")
target = System.get_env("PHASE175_EXUNIT_TARGET") || raise "missing target"
source = File.read!(source_path)

source =
  if is_binary(subject) do
    fixture = subject |> Path.expand(root) |> File.read!() |> Jason.decode!()

    case fixture do
      %{"kind" => "clean"} ->
        source

      %{"kind" => "mutation", "find" => find, "replace" => replace} ->
        parts = String.split(source, find)

        if length(parts) != 2 do
          raise "expected one exact in-memory mutation anchor; found #{length(parts) - 1}"
        end

        Enum.join(parts, replace)

      other ->
        raise "invalid prohibition subject fixture: #{inspect(other)}"
    end
  else
    source
  end

# Compile the current source for clean controls too, avoiding stale BEAM evidence.
Code.compile_string(source, source_path)
Mix.Task.run("test", ["--no-compile", "--trace", target])
