defmodule Mix.Tasks.ScrypathOps.Catalog.Serve do
  @shortdoc "Serves the component catalog on loopback without a database"

  @moduledoc """
  Serves the component catalog (the storybook) on 127.0.0.1 and nothing else.

      CATALOG_PORT=4003 mix scrypath_ops.catalog.serve

  The port is `CATALOG_PORT`, default 4003. The server starts no Repo and no code reloader, so it
  needs no database and gives the same pages every run: the stories are code and the fixtures are
  pinned to a fixed instant. If something already listens on the port, the task looks at its
  `/storybook/welcome` page: a page carrying the catalog's build markers is this catalog already
  serving (the task says so and exits 0), anything else is another program (the task exits with an
  error naming it when it can). It never signals that process.

  Before it starts, the task stores `build_info/1` (the checkout, `main` and `HEAD` shas, whether the
  checkout has uncommitted changes, and the fixtures time) so the welcome page can print where the
  storybook comes from.

  Development and tests only.
  """

  use Mix.Task

  @default_port 4003
  @landing_path "/storybook/welcome"
  # The welcome story reads this key at render time.
  @build_info_key {ScrypathOps.Catalog, :build_info}
  @unknown "unknown"

  @impl Mix.Task
  def run(_args) do
    port = port()
    listening? = listener?(port)

    case port_verdict(listening?, listening? && holder(port), listening? && landing_body(port)) do
      :free ->
        serve(port)

      :ours ->
        Mix.shell().info(
          "This catalog is already serving on http://127.0.0.1:#{port}#{@landing_path}. Nothing was started or stopped."
        )

      {:held, message} ->
        Mix.raise("""
        Port #{port} on 127.0.0.1 is already in use#{message}.
        Nothing was stopped. Pick another port: CATALOG_PORT=<port> mix scrypath_ops.catalog.serve
        """)
    end
  end

  @doc """
  What to do with a port, from three facts about it: whether something listens, what holds it (a
  description, or nil when unknown) and the body that `#{@landing_path}` returned (nil when the
  request failed). Pure, so the decision is testable.

    * `:free` - nothing listens
    * `:ours` - the listener's landing page carries the `data-catalog-main-sha` build marker, so it
      is this catalog already serving
    * `{:held, text}` - anything else; `text` names the holder (or is empty when it is not known)
  """
  @spec port_verdict(boolean(), String.t() | nil | false, String.t() | nil | false) ::
          :free | :ours | {:held, String.t()}
  def port_verdict(false, _holder, _body), do: :free

  def port_verdict(true, holder, body) do
    if ours?(body), do: :ours, else: {:held, held_text(holder)}
  end

  # The marker is an attribute the welcome page renders. `lazy_html` is a test-only dependency, so
  # the dev task looks for the attribute with its value quote instead of parsing the document.
  defp ours?(body) when is_binary(body), do: String.contains?(body, ~s(data-catalog-main-sha="))
  defp ours?(_body), do: false

  defp held_text(holder) when holder in [nil, false, ""], do: ""
  defp held_text(holder), do: " by " <> holder

  @doc """
  Where this catalog comes from, as strings the welcome page prints: `:main_sha` (the checkout's
  `origin/main`), `:head_sha`, `:dirty` (`"true"`, `"false"`), `:checkout` (the top-level directory)
  and `:epoch` (the fixtures time). A value git cannot give is `"unknown"`.

  `run` takes the git arguments and returns what `System.cmd/3` returns (`{output, exit_status}`);
  it defaults to running git in the current directory. A runner that fails or raises gives
  `"unknown"` for every git value.
  """
  @spec build_info((list(String.t()) -> {String.t(), non_neg_integer()})) :: %{
          atom() => String.t()
        }
  def build_info(run \\ &git/1) do
    %{
      main_sha: sha(run, "refs/remotes/origin/main"),
      head_sha: sha(run, "HEAD"),
      dirty: dirty(run),
      checkout: checkout(run),
      epoch: DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
    }
  end

  defp git(args), do: System.cmd("git", args, cd: File.cwd!(), stderr_to_stdout: true)

  defp git_output(run, args) do
    case run.(args) do
      {output, 0} -> {:ok, String.trim(output)}
      _failed -> :error
    end
  rescue
    _error -> :error
  end

  defp sha(run, ref) do
    with {:ok, sha} <- git_output(run, ["rev-parse", "--short=12", ref]),
         true <- Regex.match?(~r/\A[0-9a-f]{12,40}\z/, sha) do
      String.slice(sha, 0, 12)
    else
      _ -> @unknown
    end
  end

  defp dirty(run) do
    case git_output(run, ["status", "--porcelain"]) do
      {:ok, ""} -> "false"
      {:ok, _changes} -> "true"
      :error -> @unknown
    end
  end

  defp checkout(run) do
    case git_output(run, ["rev-parse", "--show-toplevel"]) do
      {:ok, ""} -> @unknown
      {:ok, path} -> path
      :error -> @unknown
    end
  end

  defp serve(port) do
    info = build_info()
    :persistent_term.put(@build_info_key, info)

    # Neither the Repo nor the main endpoint starts when the app is not standalone.
    Application.put_env(:scrypath_ops, :standalone, false)
    Application.put_env(:scrypath_ops, ScrypathOps.Catalog.Endpoint, endpoint_config(port))
    Mix.Task.run("app.start")

    {:ok, _pid} = ScrypathOps.Catalog.Endpoint.start_link([])

    Mix.shell().info(
      "Catalog from #{info.checkout} at main@#{info.main_sha} (HEAD #{info.head_sha}, uncommitted changes: #{info.dirty})"
    )

    Mix.shell().info("Catalog on http://127.0.0.1:#{port}/storybook (Ctrl+C twice to stop)")
    Process.sleep(:infinity)
  end

  # The configured endpoint with the port resolved at run time, so CATALOG_PORT works without a
  # recompile.
  defp endpoint_config(port) do
    config = Application.get_env(:scrypath_ops, ScrypathOps.Catalog.Endpoint, [])
    http = config |> Keyword.get(:http, []) |> Keyword.put(:port, port)
    Keyword.put(config, :http, http)
  end

  defp port do
    case System.get_env("CATALOG_PORT") do
      nil -> @default_port
      "" -> @default_port
      raw -> parse_port!(raw)
    end
  end

  defp parse_port!(raw) do
    case Integer.parse(raw) do
      {port, ""} when port in 1..65_535 -> port
      _ -> Mix.raise("CATALOG_PORT must be a port number from 1 to 65535, got #{inspect(raw)}")
    end
  end

  # Anything accepting a connection on loopback holds the port.
  defp listener?(port) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 500) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _reason} ->
        false
    end
  end

  # The landing page body of whatever listens on the port, or nil when it does not answer in time.
  # Loopback only, short timeout, no redirects, no retries.
  defp landing_body(port) do
    {:ok, _apps} = Application.ensure_all_started(:req)

    case Req.get("http://127.0.0.1:#{port}#{@landing_path}",
           receive_timeout: 2_000,
           connect_options: [timeout: 1_000],
           redirect: false,
           retry: false
         ) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) -> body
      _other -> nil
    end
  rescue
    _error -> nil
  end

  # Best effort: `lsof` names the process and its command; without it the message just says the port is taken.
  defp holder(port) do
    with lsof when is_binary(lsof) <- System.find_executable("lsof"),
         {output, 0} <-
           System.cmd(lsof, ["-nP", "-iTCP:#{port}", "-sTCP:LISTEN", "-Fpc"],
             stderr_to_stdout: true
           ) do
      describe_holder(output)
    else
      _ -> nil
    end
  end

  # `-Fpc` prints `p<pid>` and `c<command>` lines.
  defp describe_holder(output) do
    fields =
      output
      |> String.split("\n", trim: true)
      |> Enum.reduce(%{}, fn
        "p" <> pid, acc -> Map.put_new(acc, :pid, pid)
        "c" <> command, acc -> Map.put_new(acc, :command, command)
        _other, acc -> acc
      end)

    case fields do
      %{pid: pid, command: command} -> "#{command} (pid #{pid})"
      %{pid: pid} -> "pid #{pid}"
      _ -> nil
    end
  end
end
