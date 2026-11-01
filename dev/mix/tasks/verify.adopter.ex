defmodule Mix.Tasks.Verify.Adopter do
  use Mix.Task

  alias Mix.Tasks.Verify.PhoenixExample.LockGraph

  @shortdoc "Runs fast adopter contracts, or the live Phoenix example proof with --live"

  @moduledoc """
  Runs the maintainer-facing adopter verification flow from the repository root.

  Default mode is the fast, auth-free, service-free adopter contract slice:

  - `mix test test/scrypath/readiness_contract_test.exs`
  - `mix test test/scrypath/phase110_contract_test.exs`
  - `mix test test/mix/tasks/verify_adopter_test.exs`

  Pass `--live` to run the canonical Phoenix example proof path under
  `examples/phoenix_meilisearch`:

  - `cd examples/phoenix_meilisearch`
  - `mix deps.get --check-locked` and verify the resolved Mix lock graph
  - `mix test`

  The path proof reports the source checkout SHA, lock hashes and sorted package/version
  identities, then verifies the source lock remains byte-identical after fetching and tests.

  Live mode requires these environment variables before it will run:

  - `SCRYPATH_EXAMPLE_INTEGRATION`
  - `PGPORT`
  - `SCRYPATH_MEILISEARCH_URL`

  Live mode also expects the example's Postgres and Meilisearch services to
  already be running. This task checks those prerequisites, but it still stays
  orchestration-only.

  This task stays orchestration-only. It does not start Docker, provision services,
  or silently downgrade from `--live` back to fast mode. For the full maintainer
  matrix and CI job names, see [CONTRIBUTING.md](CONTRIBUTING.md).
  """

  @fast_tests [
    "test/scrypath/readiness_contract_test.exs",
    "test/scrypath/phase110_contract_test.exs",
    "test/mix/tasks/verify_adopter_test.exs"
  ]

  @required_live_envs [
    "SCRYPATH_EXAMPLE_INTEGRATION",
    "PGPORT",
    "SCRYPATH_MEILISEARCH_URL"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [fast: :boolean, live: :boolean]
      )

    ensure_valid_args!(opts, argv, invalid)

    if opts[:live] do
      run_live!()
    else
      run_fast!()
    end
  end

  defp run_fast! do
    Mix.shell().info("==> verify.adopter: running fast adopter contracts")
    run_test!(@fast_tests, "fast adopter contracts")
  end

  @doc false
  def run_live!(opts \\ []) do
    example_dir =
      Keyword.get(opts, :example_dir, Path.expand("examples/phoenix_meilisearch", File.cwd!()))

    command_runner = Keyword.get(opts, :command_runner, &System.cmd/3)
    service_check = Keyword.get(opts, :service_check, &ensure_live_prerequisites!/0)

    unless File.dir?(example_dir) do
      Mix.raise("verify.adopter: expected #{example_dir} to exist")
    end

    run_service_check!(service_check)

    lock_path = Path.join(example_dir, "mix.lock")
    source_lock = read_lock!(lock_path, :setup)
    source_identity = graph_identity!(source_lock, :setup)
    source_sha = source_checkout_sha!(command_runner, example_dir)

    Mix.shell().info("==> verify.adopter: resolving the checked Phoenix path graph")

    run_preserving_lock!(
      command_runner,
      :fetch,
      ["deps.get", "--check-locked"],
      example_dir,
      lock_path,
      source_lock
    )

    resolved_lock = read_lock!(lock_path, :fetch)
    LockGraph.assert_unchanged!(source_lock, resolved_lock)
    resolved_identity = graph_identity!(resolved_lock, :fetch)
    report_graph_identity!("path", source_sha, source_identity, resolved_identity)

    Mix.shell().info("==> verify.adopter: running Phoenix consumer tests")
    run_preserving_lock!(command_runner, :test, ["test"], example_dir, lock_path, source_lock)

    Mix.shell().info(
      "PASS verify.adopter: Phoenix path proof completed with source lock unchanged"
    )

    :ok
  rescue
    error in Mix.Error -> reraise(error, __STACKTRACE__)
    error -> Mix.raise("verify.adopter --live failed: #{redact(Exception.message(error))}")
  end

  defp run_service_check!(service_check) do
    service_check.()
  rescue
    error ->
      Mix.raise(
        "verify.adopter --live failed during service preflight: #{redact(Exception.message(error))}"
      )
  end

  defp read_lock!(path, stage) do
    File.read!(path)
  rescue
    error ->
      Mix.raise(
        "verify.adopter --live #{stage} stage could not read the Phoenix lockfile: #{redact(Exception.message(error))}"
      )
  end

  defp graph_identity!(lock, stage) do
    LockGraph.identity!(lock)
  rescue
    error in [ArgumentError] ->
      Mix.raise(
        "verify.adopter --live #{stage} stage has an invalid lock graph: #{error.message}"
      )
  end

  defp source_checkout_sha!(runner, example_dir) do
    {output, status} =
      runner.("git", ["rev-parse", "HEAD"], cd: example_dir, stderr_to_stdout: true)

    if output != "", do: Mix.shell().info(redact(output))

    if status != 0 do
      Mix.raise("verify.adopter --live source stage: git rev-parse HEAD exited #{status}")
    end

    source_sha = String.trim(output)

    unless Regex.match?(~r/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/, source_sha) do
      Mix.raise(
        "verify.adopter --live source stage: git rev-parse did not return a valid source SHA"
      )
    end

    source_sha
  rescue
    error in Mix.Error ->
      reraise(error, __STACKTRACE__)

    error ->
      Mix.raise(
        "verify.adopter --live source stage could not run git rev-parse (#{redact(Exception.message(error))})"
      )
  end

  defp run_preserving_lock!(runner, stage, args, example_dir, lock_path, source_lock) do
    command_result =
      try do
        invoke_live!(runner, stage, args, example_dir)
        :ok
      rescue
        error -> {:error, error, __STACKTRACE__}
      end

    lock_result =
      try do
        LockGraph.assert_unchanged!(source_lock, File.read!(lock_path))
        :unchanged
      rescue
        error -> {:changed, error}
      end

    case {command_result, lock_result} do
      {:ok, :unchanged} ->
        :ok

      {{:error, command_error, stacktrace}, :unchanged} ->
        reraise(command_error, stacktrace)

      {:ok, {:changed, lock_error}} ->
        Mix.raise(
          "verify.adopter --live #{stage} stage failed: #{redact(Exception.message(lock_error))}"
        )

      {{:error, command_error, _stacktrace}, {:changed, lock_error}} ->
        Mix.raise(
          "verify.adopter --live #{stage} stage failed (#{redact(Exception.message(command_error))}); " <>
            redact(Exception.message(lock_error))
        )
    end
  end

  defp invoke_live!(runner, stage, args, example_dir) do
    Mix.shell().info("==> verify.adopter live [#{stage}]: mix #{Enum.join(args, " ")}")
    {output, status} = runner.("mix", args, cd: example_dir, stderr_to_stdout: true)
    safe_output = redact(output)
    if safe_output != "", do: Mix.shell().info(safe_output)

    if status != 0 do
      Mix.raise(
        "verify.adopter --live #{stage} stage: mix #{Enum.join(args, " ")} exited #{status}"
      )
    end

    :ok
  rescue
    error in Mix.Error ->
      reraise(error, __STACKTRACE__)

    error ->
      Mix.raise(
        "verify.adopter --live #{stage} stage could not run mix #{Enum.join(args, " ")} (#{redact(Exception.message(error))})"
      )
  end

  defp report_graph_identity!(mode, source_sha, source_identity, resolved_identity) do
    Mix.shell().info(
      "Phoenix example proof source_sha=#{source_sha} mode=#{mode} " <>
        "source_lock_sha256=#{source_identity.sha256} resolved_lock_sha256=#{resolved_identity.sha256}"
    )

    packages =
      Enum.map_join(resolved_identity.packages, ", ", fn {name, version} ->
        "#{name}@#{version}"
      end)

    Mix.shell().info("Phoenix example proof packages=#{packages}")
  end

  defp redact(output) when is_binary(output) do
    System.get_env()
    |> Enum.filter(fn {name, value} ->
      value != "" and
        (String.match?(name, ~r/(TOKEN|PASSWORD|SECRET|KEY|URL)/i) or
           name in ["SCRYPATH_MEILISEARCH_URL"])
    end)
    |> Enum.reduce(output, fn {_name, value}, acc -> String.replace(acc, value, "[REDACTED]") end)
  end

  @doc false
  def ensure_live_prerequisites! do
    ensure_live_env!()
    ensure_live_services!()
    :ok
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_valid_args!(opts, [], []) do
    if opts[:fast] && opts[:live] do
      Mix.raise("verify.adopter accepts either --fast or --live, not both")
    end
  end

  defp ensure_valid_args!(_opts, argv, invalid) do
    invalid_flags =
      Enum.map(invalid, fn
        {name, _value} -> format_invalid_flag(name)
        name when is_atom(name) -> "--#{name}"
        other -> format_invalid_flag(other)
      end)

    tokens = argv ++ invalid_flags

    Mix.raise("verify.adopter does not accept arguments, got: #{Enum.join(tokens, " ")}")
  end

  defp ensure_live_env! do
    missing =
      Enum.filter(@required_live_envs, fn name ->
        System.get_env(name) in [nil, ""]
      end)

    if missing != [] do
      Mix.raise("""
      verify.adopter --live requires environment variables: #{Enum.join(missing, ", ")}

      Example:
        SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live
      """)
    end
  end

  defp ensure_live_services! do
    postgres_port = postgres_port!()
    {meilisearch_host, meilisearch_port} = meilisearch_endpoint!()

    unreachable =
      [
        {"Postgres", "localhost", postgres_port},
        {"Meilisearch", meilisearch_host, meilisearch_port}
      ]
      |> Enum.reject(fn {_label, host, port} -> reachable?(host, port) end)

    if unreachable != [] do
      failures =
        Enum.map_join(unreachable, ", ", fn {label, host, port} ->
          "#{label} on #{host}:#{port}"
        end)

      Mix.raise("""
      verify.adopter --live requires running Postgres and Meilisearch services before it shells into the example app.
      Unreachable: #{failures}

      Start the example stack first:
        cd examples/phoenix_meilisearch
        docker compose up -d

      Then rerun:
        SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live
      """)
    end
  end

  defp postgres_port! do
    "PGPORT"
    |> System.fetch_env!()
    |> String.to_integer()
  rescue
    ArgumentError ->
      Mix.raise("verify.adopter --live requires PGPORT to be an integer TCP port")
  end

  defp meilisearch_endpoint! do
    url = System.fetch_env!("SCRYPATH_MEILISEARCH_URL")

    case URI.parse(url) do
      %URI{host: host, scheme: scheme, port: port} when is_binary(host) and host != "" ->
        {host, port || URI.default_port(scheme) || 80}

      _ ->
        Mix.raise(
          "verify.adopter --live requires SCRYPATH_MEILISEARCH_URL to include a valid host"
        )
    end
  end

  defp reachable?(host, port) do
    case :gen_tcp.connect(String.to_charlist(host), port, [:binary, active: false], 1_000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _reason} ->
        false
    end
  end

  defp format_invalid_flag(<<"--", _::binary>> = value), do: value
  defp format_invalid_flag(value), do: "--#{value}"
end
