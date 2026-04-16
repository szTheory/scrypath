defmodule Mix.Tasks.Verify.ReleasePublish do
  use Mix.Task

  @shortdoc "Verifies the live Hex publish for a released Scrypath version"

  @moduledoc """
  Verifies the live publish contract for a released Scrypath version.

  This task is intended for the real post-publish workflow, not the always-on CI
  gate. It polls Hex package availability, compiles a clean consumer app against
  the published Hex version, and confirms the versioned HexDocs URL responds.
  """

  @default_attempts 10
  @default_sleep_ms 15_000

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    version = parse_version!(args)
    attempts = env_integer("SCRYPATH_RELEASE_VERIFY_ATTEMPTS", @default_attempts)
    sleep_ms = env_integer("SCRYPATH_RELEASE_VERIFY_SLEEP_MS", @default_sleep_ms)
    hexdocs_url = "https://hexdocs.pm/scrypath/#{version}"

    Mix.shell().info("==> Verifying live Hex publish for Scrypath #{version}")

    retry_until!(
      "Hex package availability",
      attempts,
      sleep_ms,
      fn -> published_package_available?(version) end
    )

    retry_until!(
      "published package consumer smoke",
      attempts,
      sleep_ms,
      fn -> published_consumer_smoke_passes?(version) end
    )

    retry_until!(
      "versioned HexDocs availability",
      attempts,
      sleep_ms,
      fn -> hexdocs_available?(hexdocs_url) end
    )
  end

  defp parse_version!([version]) when version != "", do: version

  defp parse_version!(_args) do
    Mix.raise(
      "verify.release_publish expects exactly one version argument, e.g. mix verify.release_publish 0.1.0"
    )
  end

  defp retry_until!(label, attempts, sleep_ms, fun) do
    Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
      Mix.shell().info("==> #{label} (attempt #{attempt}/#{attempts})")

      case fun.() do
        :ok ->
          {:halt, :ok}

        {:error, reason} when attempt < attempts ->
          Mix.shell().info(reason)
          Process.sleep(sleep_ms)
          {:cont, nil}

        {:error, reason} ->
          Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
      end
    end)
  end

  defp published_package_available?(version) do
    case System.cmd("mix", ["hex.info", "scrypath"], stderr_to_stdout: true) do
      {output, 0} ->
        if String.contains?(output, version) do
          :ok
        else
          {:error, "mix hex.info scrypath does not list #{version} yet\n\n#{output}"}
        end

      {output, _status} ->
        {:error, "mix hex.info scrypath failed\n\n#{output}"}
    end
  end

  defp published_consumer_smoke_passes?(version) do
    tmp_root = unique_tmp_dir!()
    app_dir = Path.join(tmp_root, "scrypath_consumer")

    try do
      run_command!("mix", ["new", "scrypath_consumer", "--module", "ScrypathConsumer"],
        cd: tmp_root
      )

      File.write!(Path.join(app_dir, "mix.exs"), consumer_mix_exs(version))
      write_consumer_schema!(app_dir)

      run_command!("mix", ["deps.get"], cd: app_dir)
      run_command!("mix", ["compile"], cd: app_dir)

      beam_path =
        Path.join(
          app_dir,
          "_build/dev/lib/scrypath_consumer/ebin/Elixir.ScrypathConsumer.Post.beam"
        )

      if File.exists?(beam_path) do
        :ok
      else
        {:error, "consumer smoke compile succeeded but #{beam_path} was not created"}
      end
    after
      File.rm_rf(tmp_root)
    end
  rescue
    error in Mix.Error -> {:error, Exception.message(error)}
  end

  defp hexdocs_available?(url) do
    case System.cmd("curl", ["-IfsS", url], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _status} -> {:error, "curl could not reach #{url}\n\n#{output}"}
    end
  end

  defp consumer_mix_exs(version) do
    """
    defmodule ScrypathConsumer.MixProject do
      use Mix.Project

      def project do
        [
          app: :scrypath_consumer,
          version: "0.1.0",
          elixir: "~> 1.17",
          start_permanent: Mix.env() == :prod,
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        [
          {:ecto, "~> 3.13"},
          {:scrypath, "~> #{version}"}
        ]
      end
    end
    """
  end

  defp write_consumer_schema!(app_dir) do
    schema_dir = Path.join(app_dir, "lib/scrypath_consumer")
    File.mkdir_p!(schema_dir)
    File.write!(Path.join(schema_dir, "post.ex"), consumer_schema())
  end

  defp consumer_schema do
    """
    defmodule ScrypathConsumer.Post do
      use Ecto.Schema

      use Scrypath,
        fields: [:title, :body],
        filterable: [:status],
        sortable: [:inserted_at]

      schema "posts" do
        field :title, :string
        field :body, :string
        field :status, Ecto.Enum, values: [:draft, :published]
        timestamps()
      end
    end
    """
  end

  defp run_command!(command, args, opts) do
    {output, exit_status} =
      System.cmd(command, args, Keyword.merge([stderr_to_stdout: true], opts))

    if exit_status == 0 do
      output
    else
      raise Mix.Error,
            """
            command failed: #{command} #{Enum.join(args, " ")}

            #{output}
            """
    end
  end

  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "scrypath-release-publish-#{System.unique_integer([:positive])}"
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
