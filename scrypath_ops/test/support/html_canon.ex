defmodule ScrypathOps.Test.HtmlCanon do
  @moduledoc """
  Canonical form of rendered HTML, for comparing what two renders say rather than how the
  serializer happened to spell it.

  Raw HTML text is never compared. Phoenix function components spread `{@rest}` global
  attributes, and the order of those attributes is not stable between builds: one unrelated
  recompile moved `phx-click` on an untouched button and a whitespace-normalized text diff then
  reported every capture as different. This helper parses the HTML (`LazyHTML`), sorts every
  element's attributes by name, drops comments, collapses whitespace, and replaces the values a
  render invents on its own (the `ops-time-<n>` counter, LiveView session and static tokens,
  `phx-` generated ids, long csrf tokens) with fixed markers. Each element and text node becomes
  one line, indented by depth.

  Used by the Search health seam tests (the mounted page contains exactly the shared component's
  output) and by the local parity capture script. Plain copy, no dependency (house preference).
  """

  @type input :: String.t() | LazyHTML.t()

  @doc """
  The canonical tree of a document string, a fragment string, or an already parsed `LazyHTML`
  selection, one node per line.
  """
  @spec canon(input()) :: String.t()
  def canon(html) when is_binary(html) do
    html |> parse() |> canon()
  end

  def canon(%LazyHTML{} = html) do
    html
    |> LazyHTML.to_tree()
    |> Enum.flat_map(&lines(&1, 0))
    |> Enum.join("\n")
  end

  @doc "SHA-256 of `canon/1`, lowercase hex. Two renders with the same digest say the same thing."
  @spec digest(input()) :: String.t()
  def digest(html) do
    :sha256 |> :crypto.hash(canon(html)) |> Base.encode16(case: :lower)
  end

  defp parse(html) do
    if Regex.match?(~r/\A\s*(<!doctype|<html)/i, html),
      do: LazyHTML.from_document(html),
      else: LazyHTML.from_fragment(html)
  end

  defp lines({:comment, _text}, _depth), do: []

  defp lines(text, depth) when is_binary(text) do
    case text |> String.replace(~r/\s+/, " ") |> String.trim() do
      "" -> []
      trimmed -> [indent(depth) <> inspect(trimmed)]
    end
  end

  defp lines({tag, attrs, children}, depth) do
    attrs =
      attrs |> Enum.map(fn {name, value} -> {name, norm_attr(name, value)} end) |> Enum.sort()

    [
      indent(depth) <> "<#{tag} #{inspect(attrs)}>"
      | Enum.flat_map(children, &lines(&1, depth + 1))
    ]
  end

  defp indent(depth), do: String.duplicate(" ", depth)

  defp norm_attr(name, value) do
    value = Regex.replace(~r/ops-time-\d+/, value, "ops-time-N")

    cond do
      name in ["data-phx-session", "data-phx-static"] ->
        "TOKEN"

      name == "content" and String.length(value) > 40 ->
        "TOKEN"

      name in ["id", "data-phx-id", "data-phx-root-id", "data-phx-parent-id"] and
          String.starts_with?(value, "phx-") ->
        "phx-ID"

      name == "class" ->
        value |> String.split() |> Enum.join(" ")

      true ->
        value
    end
  end
end
