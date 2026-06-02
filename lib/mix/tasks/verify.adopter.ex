defmodule Mix.Tasks.Verify.Adopter do
  use Mix.Task

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
  - `mix deps.get`
  - `mix test`

  Equivalent shell chain: `cd examples/phoenix_meilisearch && mix deps.get && mix test`.

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

  defp run_live! do
    example_dir = Path.expand("examples/phoenix_meilisearch", File.cwd!())

    unless File.dir?(example_dir) do
      Mix.raise("verify.adopter: expected #{example_dir} to exist")
    end

    ensure_live_env!()
    ensure_live_services!()

    Mix.shell().info(
      "==> verify.adopter: cd examples/phoenix_meilisearch && mix deps.get && mix test"
    )

    script = "printf 'n\\n' | mix deps.get && mix test"

    {out, status} =
      System.cmd("bash", ["-lc", script], cd: example_dir, stderr_to_stdout: true)

    Mix.shell().info(out)

    if status != 0 do
      Mix.raise("verify.adopter failed: `#{script}` (in #{example_dir}) exited #{status}")
    end
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
          "verify.adopter --live requires SCRYPATH_MEILISEARCH_URL to include a valid host, got: #{inspect(url)}"
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
