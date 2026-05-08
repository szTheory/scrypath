defmodule Mix.Tasks.Scrypath.NamespaceFence do
  @moduledoc """
  Fails when Sigra references leak outside the allowed integration namespace.

  The fence scans the repo-owned `lib/scrypath/`, `scrypath_ops/lib/`, and
  `scrypath_ops/test/` trees. Only the Sigra integration namespace and the
  bounded OPSUI LiveView surfaces that consume that integration are allowed to
  contain `Sigra.` references inside `scrypath_ops`.
  """

  use Mix.Task

  @shortdoc "Fails on forbidden Sigra references outside the integration namespace"

  @pattern "Sigra."
  @fence_rules [
    {"lib/scrypath/", []},
    {"scrypath_ops/lib/",
     [
       "scrypath_ops/lib/scrypath_ops/integrations/sigra/",
       "scrypath_ops/lib/scrypath_ops_web/live/"
     ]},
    {"scrypath_ops/test/",
     [
       "scrypath_ops/test/scrypath_ops/integrations/sigra/",
       "scrypath_ops/test/scrypath_ops_web/live/"
     ]}
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    case check(File.cwd!()) do
      {:ok, _summary} ->
        Mix.shell().info("==> Namespace fence passed")
        :ok

      {:error, violations} ->
        Mix.raise(format_violations(violations))
    end
  end

  @doc """
  Pure fence evaluation for a repository root.

  Returns `{:ok, summary}` when no forbidden Sigra references are found and
  `{:error, violations}` when the fence is tripped.
  """
  @spec check(Path.t()) :: {:ok, map()} | {:error, [String.t()]}
  def check(root) when is_binary(root) do
    root = Path.expand(root)

    violations =
      @fence_rules
      |> Enum.flat_map(fn {scan_dir, allowed_prefixes} ->
        scan_root = Path.join(root, scan_dir)

        scan_root
        |> scan_files()
        |> Enum.flat_map(&collect_violations(&1, root, allowed_prefixes))
      end)

    case violations do
      [] -> {:ok, %{root: root, scanned_dirs: Enum.map(@fence_rules, &elem(&1, 0))}}
      _ -> {:error, Enum.sort(violations)}
    end
  end

  defp scan_files(scan_root) do
    if File.dir?(scan_root) do
      scan_root
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
    else
      []
    end
  end

  defp collect_violations(path, root, allowed_prefixes) do
    rel_path = Path.relative_to(path, root)

    if allowed_path?(rel_path, allowed_prefixes) do
      []
    else
      path
      |> File.stream!(:line, [])
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_no} ->
        if String.contains?(line, @pattern) do
          ["#{rel_path}:#{line_no}: #{String.trim_trailing(line)}"]
        else
          []
        end
      end)
    end
  end

  defp allowed_path?(relative_path, allowed_prefixes) do
    Enum.any?(allowed_prefixes, &String.starts_with?(relative_path, &1))
  end

  defp format_violations(violations) do
    """
    Namespace fence failed.

    Forbidden Sigra references were found outside the allowed integration namespace:

    #{Enum.map_join(violations, "\n", &("  - " <> &1))}
    """
  end

  defp ensure_no_args!([]), do: :ok

  defp ensure_no_args!(args) do
    Mix.raise("scrypath.namespace_fence does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
