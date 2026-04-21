defmodule Mix.Tasks.ScrypathOps.CheckNavContract do
  @shortdoc "Compare operator-ia.md nav-contract fence to ScrypathOpsWeb.Nav.primary/0"

  @moduledoc """
  Verifies the machine-readable JSON block in `docs/operator-ia.md` matches
  `ScrypathOpsWeb.Nav.primary/0` (order, routes, labels).

  Run from the `scrypath_ops` app directory:

      mix scrypath_ops.check_nav_contract

  Pass `--write` to replace the fenced JSON from `Nav.primary/0`.
  """

  use Mix.Task

  @begin_marker "<!-- scrypath:nav-contract-begin -->"
  @end_marker "<!-- scrypath:nav-contract-end -->"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [write: :boolean])

    Mix.Task.run("compile")
    # Verified route paths resolve against the endpoint at runtime (~p in `Nav.primary/0`).
    Mix.Task.run("app.start")

    doc_path = Path.join([File.cwd!(), "docs", "operator-ia.md"])
    doc = File.read!(doc_path)

    json_fragment = extract_fence(doc)
    from_doc = Jason.decode!(json_fragment)

    from_nav =
      ScrypathOpsWeb.Nav.primary()
      |> Enum.map(fn %{path: p, label: l} ->
        %{"route" => p |> to_string(), "label" => l}
      end)

    cond do
      opts[:write] ->
        new_body = rewrite_fence(doc, from_nav)
        File.write!(doc_path, new_body)
        Mix.shell().info("Wrote nav-contract fence from Nav.primary/0 to #{doc_path}")

      from_doc == from_nav ->
        Mix.shell().info("Nav contract OK: operator-ia.md matches Nav.primary/0")

      true ->
        Mix.raise("""
        operator-ia.md nav-contract fence does not match Nav.primary/0.

        Doc:   #{inspect(from_doc, pretty: true)}
        Nav:   #{inspect(from_nav, pretty: true)}

        Re-run with --write to sync the doc from code, or update Nav / doc manually.
        """)
    end
  end

  defp extract_fence(doc) do
    case String.split(doc, @begin_marker, parts: 2) do
      [_] ->
        Mix.raise("missing #{@begin_marker} in docs/operator-ia.md")

      [_, after_begin] ->
        case String.split(after_begin, @end_marker, parts: 2) do
          [_] ->
            Mix.raise("missing #{@end_marker} after nav-contract begin in docs/operator-ia.md")

          [inner, _] ->
            String.trim(inner)
        end
    end
  end

  defp rewrite_fence(doc, from_nav) do
    encoded = Jason.encode!(from_nav)

    [head, rest] = String.split(doc, @begin_marker, parts: 2)
    [_old, tail] = String.split(rest, @end_marker, parts: 2)

    head <>
      @begin_marker <>
      "\n" <>
      encoded <>
      "\n" <>
      @end_marker <>
      tail
  end
end
