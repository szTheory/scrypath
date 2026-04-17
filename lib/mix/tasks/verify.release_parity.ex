defmodule Mix.Tasks.Verify.ReleaseParity do
  @moduledoc """
  Verifies that the file list inside the published Hex tarball for `X.Y.Z`
  matches the file list inside `lib/ + guides/ + docs/` at git tag
  `scrypath-vX.Y.Z`.

  ## Usage

      mix verify.release_parity 0.3.0
      mix verify.release_parity 0.3.0 --json

  ## Exit codes

    * `0` — parity (no drift)
    * `2` — drift detected (POSIX "intentional failure")
    * `1` — runtime error (network failure, missing tag, tarball fetch failure)

  ## Retry behavior

  Inherits `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` (default 10) and
  `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` (default 15_000) from
  `verify.release_publish` so daily cron runs do not false-fail during
  CDN propagation of a freshly-cut release.

  ## Implementation notes

  Path-set equality only (D-08). Content-digest comparison is deliberately
  deferred — `git archive` at a tag and `mix hex.build` from the same
  commit produce byte-equal contents because they read the same locked
  git tree, so content drift would require post-tag file mutation
  (orthogonal to the v1.2 incident class).

  The module is split into a pure `compute/2` + a thin `run/1` so the
  drift-exit-code semantics (via `System.halt(2)`) can be unit-tested
  without killing the ExUnit runner (Pitfall 11).
  """

  @shortdoc "Compares the Hex tarball against the git tag for a released version"

  use Mix.Task

  @default_attempts 10
  @default_sleep_ms 15_000

  # Matches canonical semver + optional pre-release/build suffix.
  # Security V5: this is the ONLY path a user-supplied string can reach a
  # subprocess. Reject anything else before it touches `git ls-tree`.
  @version_regex ~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _invalid} = OptionParser.parse(args, strict: [json: :boolean])
    version = parse_version!(argv)

    attempts = env_integer("SCRYPATH_RELEASE_VERIFY_ATTEMPTS", @default_attempts)
    sleep_ms = env_integer("SCRYPATH_RELEASE_VERIFY_SLEEP_MS", @default_sleep_ms)

    tmp_root = unique_tmp_dir!()

    try do
      hex_paths = fetch_hex_paths!(version, tmp_root, attempts, sleep_ms)
      git_paths = fetch_git_paths!(version)

      case compute(git_paths, hex_paths) do
        :parity ->
          emit_parity!(version, opts)
          :ok

        {:drift, only_in_git, only_in_hex} ->
          emit_drift_and_halt!(version, only_in_git, only_in_hex, opts)
      end
    after
      # Non-bang per Pitfall 4 — do not mask original exception.
      File.rm_rf(tmp_root)
    end
  end

  @doc """
  Pure path-set comparison. Returns `:parity` when the two MapSets are equal,
  otherwise a `{:drift, only_in_git_sorted, only_in_hex_sorted}` tuple.

  Exposed publicly for Pitfall 11 unit testability.
  """
  @spec compute(MapSet.t(String.t()), MapSet.t(String.t())) ::
          :parity | {:drift, [String.t()], [String.t()]}
  def compute(%MapSet{} = git_paths, %MapSet{} = hex_paths) do
    only_in_git =
      git_paths |> MapSet.difference(hex_paths) |> MapSet.to_list() |> Enum.sort()

    only_in_hex =
      hex_paths |> MapSet.difference(git_paths) |> MapSet.to_list() |> Enum.sort()

    case {only_in_git, only_in_hex} do
      {[], []} -> :parity
      {og, oh} -> {:drift, og, oh}
    end
  end

  @doc """
  Renders the `--json` output shape documented in D-11.

  `:parity` status renders as `"ok"` in the JSON envelope.
  """
  @spec render_json(String.t(), :parity | :drift, [String.t()], [String.t()]) ::
          String.t()
  def render_json(version, status, only_in_git, only_in_hex)
      when status in [:parity, :drift] do
    status_str = if status == :parity, do: "ok", else: "drift"

    Jason.encode!(%{
      "version" => version,
      "status" => status_str,
      "only_in_git" => Enum.sort(only_in_git),
      "only_in_hex" => Enum.sort(only_in_hex)
    })
  end

  @doc """
  Retry loop copied from `verify.release_publish.ex:58-75` — same env-var
  names, same semantics — so maintainers learn one retry model.

  Exposed publicly for Pitfall 1 unit testability (stub the fun with a
  counter-backed Agent).
  """
  @spec retry_until!(String.t(), pos_integer(), non_neg_integer(), (-> :ok | {:error, term()})) ::
          :ok | no_return()
  def retry_until!(label, attempts, sleep_ms, fun) do
    Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
      Mix.shell().info("==> #{label} (attempt #{attempt}/#{attempts})")

      case fun.() do
        :ok ->
          {:halt, :ok}

        {:error, reason} when attempt < attempts ->
          Mix.shell().info(to_string(reason))
          Process.sleep(sleep_ms)
          {:cont, nil}

        {:error, reason} ->
          Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
      end
    end)
  end

  @doc """
  Validates the one-and-only user-supplied argument against a canonical
  semver regex before it reaches any subprocess (Security V5 / Pitfall 7).
  """
  @spec parse_version!([String.t()]) :: String.t() | no_return()
  def parse_version!([version]) when is_binary(version) and version != "" do
    if Regex.match?(@version_regex, version) do
      version
    else
      Mix.raise(
        "verify.release_parity expects a semver version (e.g. 0.3.0 or 1.0.0-rc.1), got: #{inspect(version)}"
      )
    end
  end

  def parse_version!(_argv) do
    Mix.raise(
      "verify.release_parity expects exactly one version argument, e.g. mix verify.release_parity 0.3.0"
    )
  end

  # ---------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------

  defp fetch_hex_paths!(version, tmp_root, attempts, sleep_ms) do
    retry_until!("hex.package fetch scrypath #{version}", attempts, sleep_ms, fn ->
      do_fetch_hex(version, tmp_root)
    end)

    # Pitfall 6 — trim tmp_root prefix to normalize against git-side paths.
    Path.wildcard(Path.join(tmp_root, "{lib,guides,docs}/**/*"))
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, tmp_root))
    |> MapSet.new()
  end

  defp do_fetch_hex(version, tmp_root) do
    {output, exit_status} =
      System.cmd(
        "mix",
        ["hex.package", "fetch", "scrypath", version, "--unpack", "-o", tmp_root],
        stderr_to_stdout: true
      )

    case exit_status do
      0 ->
        # Pitfall 5 — empty unpack is a CDN hiccup; treat as transient.
        if File.exists?(Path.join(tmp_root, "mix.exs")) do
          :ok
        else
          {:error,
           "hex.package fetch succeeded but tmp_dir lacks mix.exs (empty tarball?):\n\n#{output}"}
        end

      _ ->
        {:error, "mix hex.package fetch failed:\n\n#{output}"}
    end
  end

  defp fetch_git_paths!(version) do
    tag = "scrypath-v#{version}"

    {output, exit_status} =
      System.cmd(
        "git",
        ["ls-tree", "-r", "--name-only", tag, "--", "lib/", "guides/", "docs/"],
        stderr_to_stdout: true
      )

    case exit_status do
      0 ->
        # Pitfall 7 — empty stdout with exit 0 would be wrong; tag should
        # always yield at least one lib/ entry. If empty, flag it.
        paths = output |> String.split("\n", trim: true) |> MapSet.new()

        if MapSet.size(paths) == 0 do
          Mix.raise(
            "git ls-tree for tag #{tag} returned no paths. Does the tag exist?\n\nRun: git fetch --tags"
          )
        end

        paths

      _ ->
        Mix.raise("git ls-tree failed for tag #{tag}:\n\n#{output}")
    end
  end

  defp emit_parity!(version, opts) do
    output =
      if opts[:json] do
        render_json(version, :parity, [], [])
      else
        "Release parity OK for scrypath #{version}: tag and Hex tarball agree on lib/ + guides/ + docs/."
      end

    Mix.shell().info(output)
  end

  @spec emit_drift_and_halt!(String.t(), [String.t()], [String.t()], keyword()) :: no_return()
  defp emit_drift_and_halt!(version, only_in_git, only_in_hex, opts) do
    output =
      if opts[:json] do
        render_json(version, :drift, only_in_git, only_in_hex)
      else
        human_diff(version, only_in_git, only_in_hex)
      end

    Mix.shell().info(output)

    # D-10: exit 2 distinguishes drift from runtime errors.
    System.halt(2)
  end

  defp human_diff(version, only_in_git, only_in_hex) do
    """
    Release parity drift detected for scrypath #{version}:
      #{length(only_in_git)} files only in git tag (missing from Hex tarball)
      #{length(only_in_hex)} files only in Hex tarball (not in git tag)

    Only in git tag (missing from Hex tarball):
    #{format_paths(only_in_git)}

    Only in Hex tarball (not in git tag):
    #{format_paths(only_in_hex)}
    """
  end

  defp format_paths([]), do: "  (none)"

  defp format_paths(paths) do
    Enum.map_join(paths, "\n", &"  #{&1}")
  end

  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "scrypath-release-parity-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp env_integer(name, default) do
    case System.get_env(name) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {parsed, ""} when parsed > 0 -> parsed
          _ -> Mix.raise("#{name} must be a positive integer, got: #{inspect(value)}")
        end
    end
  end
end
