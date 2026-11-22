defmodule Mix.Tasks.ScrypathOps.Catalog.Serve do
  @shortdoc "Serves the component catalog on loopback without a database"

  @moduledoc """
  Serves the component catalog (the storybook) on 127.0.0.1 and nothing else.

      CATALOG_PORT=4003 mix scrypath_ops.catalog.serve

  The port is `CATALOG_PORT`, default 4003. The server starts no Repo and no code reloader, so it
  needs no database and gives the same pages every run: the stories are code and the fixtures are
  pinned to a fixed instant. It exits with an error, naming the process that holds the port when it
  can, if something already listens there. It never signals that process.

  Development and tests only.
  """

  use Mix.Task

  @default_port 4003

  @impl Mix.Task
  def run(_args) do
    port = port()
    listening? = listener?(port)

    case port_verdict(listening?, listening? && holder(port)) do
      :free ->
        serve(port)

      {:taken, message} ->
        Mix.raise("""
        Port #{port} on 127.0.0.1 is already in use#{message}.
        Nothing was stopped. Pick another port: CATALOG_PORT=<port> mix scrypath_ops.catalog.serve
        """)
    end
  end

  @doc """
  What to do with a port: `:free` when nothing listens on it, otherwise `{:taken, text}` where
  `text` names the holder (or is empty when it is not known). Pure, so the decision is testable.
  """
  @spec port_verdict(boolean(), String.t() | nil | false) :: :free | {:taken, String.t()}
  def port_verdict(false, _holder), do: :free
  def port_verdict(true, holder) when holder in [nil, false, ""], do: {:taken, ""}
  def port_verdict(true, holder), do: {:taken, " by " <> holder}

  defp serve(port) do
    # Neither the Repo nor the main endpoint starts when the app is not standalone.
    Application.put_env(:scrypath_ops, :standalone, false)
    Application.put_env(:scrypath_ops, ScrypathOps.Catalog.Endpoint, endpoint_config(port))
    Mix.Task.run("app.start")

    {:ok, _pid} = ScrypathOps.Catalog.Endpoint.start_link([])
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
