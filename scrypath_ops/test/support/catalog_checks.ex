defmodule ScrypathOps.Test.CatalogChecks do
  @moduledoc """
  Pure checks over the rendered catalog, used by `catalog_contract_test.exs`. No ExUnit macros: each
  function takes data (digests, an HTML document) and returns tagged problems, so a planted input can
  assert its exact cause and the real tree can assert `[]`.

    * `identical_variations/1` finds two variations of one story that render the same page in a
      theme, so a story never lists a state twice.
    * `dom_problems/2` finds broken DOM hygiene in one rendered story: a duplicate id, an ARIA
      reference to nothing (or the literal `"false"`), a control with no accessible name, and, for a
      surface-tier story, anything but exactly one main landmark.

  Hashing and checks only look at `[data-phx-main] > *` and `[data-phx-main]`. The LiveView container
  itself carries per-mount session tokens, so hashing it would make two identical renders differ.
  """

  alias ScrypathOps.Test.HtmlCanon

  @aria_refs ["aria-labelledby", "aria-describedby", "aria-controls"]
  @button_value_types ["submit", "button", "reset"]

  @type digest_result ::
          {path :: String.t(), variation_id :: String.t(), theme :: String.t(), String.t()}
  @type tier :: :primitive | :pattern | :area | :surface | :job | :other

  @doc """
  SHA-256 of the canonical tree of the story's own markup (`[data-phx-main] > *`) in a rendered
  iframe document.
  """
  @spec main_digest(String.t()) :: String.t()
  def main_digest(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("[data-phx-main] > *")
    |> HtmlCanon.digest()
  end

  @doc """
  Groups results by story path and theme and reports every set of two or more variations that share a
  digest, as `{:identical, path, theme, [variation_id, ...]}` sorted by path, theme and ids.
  """
  @spec identical_variations([digest_result()]) ::
          [{:identical, String.t(), String.t(), [String.t()]}]
  def identical_variations(results) do
    results
    |> Enum.group_by(fn {path, _id, theme, _digest} -> {path, theme} end)
    |> Enum.flat_map(fn {{path, theme}, group} ->
      group
      |> Enum.group_by(fn {_path, _id, _theme, digest} -> digest end, fn {_p, id, _t, _d} ->
        id
      end)
      |> Enum.filter(fn {_digest, ids} -> length(ids) > 1 end)
      |> Enum.map(fn {_digest, ids} -> {:identical, path, theme, Enum.sort(ids)} end)
    end)
    |> Enum.sort()
  end

  @doc "The tier a story path belongs to, from its first segment (`/surfaces/failed_sync` is `:surface`)."
  @spec tier(String.t()) :: tier()
  def tier(path) do
    case path |> String.trim_leading("/") |> String.split("/", parts: 2) do
      ["primitives" | _] -> :primitive
      ["patterns" | _] -> :pattern
      ["areas" | _] -> :area
      ["surfaces" | _] -> :surface
      ["jobs" | _] -> :job
      _ -> :other
    end
  end

  @doc """
  DOM hygiene problems of one rendered iframe document, in a stable order:

    * `{:duplicate_id, id}` - two elements share an `id`
    * `{:dangling_aria, attribute, token}` - an `aria-labelledby`, `aria-describedby` or `aria-controls`
      token that is not an id in the story, including the literal `"false"` a boolean left behind
    * `{:unnamed_control, tag}` - a button, link, input, select or textarea with no accessible name
    * `{:main_count, n}` - for tier `:surface` only, when the story has `n` main landmarks, not one

  A control is named by its own text (ignoring `aria-hidden` subtrees), `aria-label`,
  an `aria-labelledby` target with text, `title`, an image `alt`, a button's `value`, a `label[for]`,
  or a wrapping `<label>` with text (the Failed sync cause chips are named that way).
  """
  @spec dom_problems(String.t(), tier()) :: [tuple()]
  def dom_problems(html, tier) do
    root =
      html |> LazyHTML.from_document() |> LazyHTML.query("[data-phx-main]") |> LazyHTML.to_tree()

    elements = elements(root)
    ids = Enum.flat_map(elements, &id_of/1)
    id_texts = id_texts(elements)
    label_for = label_for_texts(elements)

    duplicate_ids(ids) ++
      dangling_aria(elements, MapSet.new(ids)) ++
      unnamed_controls(elements, id_texts, label_for) ++
      main_problems(elements, tier)
  end

  # ── Elements ───────────────────────────────────────────────────────────────

  # Every element in document order, each with its ancestors (nearest first).
  defp elements(nodes), do: Enum.flat_map(nodes, &collect(&1, []))

  defp collect({_tag, _attrs, children} = node, ancestors) do
    [{node, ancestors} | Enum.flat_map(children, &collect(&1, [node | ancestors]))]
  end

  defp collect(_text_or_comment, _ancestors), do: []

  defp id_of({{_tag, attrs, _children}, _ancestors}) do
    case attr(attrs, "id") do
      nil -> []
      "" -> []
      id -> [id]
    end
  end

  defp attr(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {^name, value} -> value
      nil -> nil
    end
  end

  # ── Ids ────────────────────────────────────────────────────────────────────

  defp duplicate_ids(ids) do
    ids
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)
    |> Enum.map(fn {id, _count} -> {:duplicate_id, id} end)
    |> Enum.sort()
  end

  defp dangling_aria(elements, id_set) do
    for {{_tag, attrs, _children}, _ancestors} <- elements,
        name <- @aria_refs,
        value = attr(attrs, name),
        token <- String.split(value),
        token == "false" or not MapSet.member?(id_set, token) do
      {:dangling_aria, name, token}
    end
    |> Enum.uniq()
  end

  # ── Names ──────────────────────────────────────────────────────────────────

  # id => full text of the element with that id (an aria-labelledby target counts even when hidden).
  defp id_texts(elements) do
    for {{_tag, attrs, children} = node, _ancestors} <- elements,
        id = attr(attrs, "id"),
        id != "",
        into: %{} do
      {id, text_of(node, children)}
    end
  end

  # for-id => text of the label that points at it.
  defp label_for_texts(elements) do
    for {{"label", attrs, _children} = node, _ancestors} <- elements,
        for_id = attr(attrs, "for"),
        for_id != "",
        reduce: %{} do
      acc -> Map.update(acc, for_id, accessible_text(node), &(&1 <> " " <> accessible_text(node)))
    end
  end

  defp unnamed_controls(elements, id_texts, label_for) do
    for {{tag, attrs, _children} = node, ancestors} <- elements,
        control?(tag, attrs),
        not named?(node, ancestors, id_texts, label_for) do
      {:unnamed_control, tag}
    end
  end

  defp control?("button", _attrs), do: true
  defp control?("a", attrs), do: attr(attrs, "href") != nil
  defp control?("select", _attrs), do: true
  defp control?("textarea", _attrs), do: true
  defp control?("input", attrs), do: attr(attrs, "type") != "hidden"
  defp control?(_tag, _attrs), do: false

  defp named?({tag, attrs, _children} = node, ancestors, id_texts, label_for) do
    present?(attr(attrs, "aria-label")) or
      present?(attr(attrs, "title")) or
      labelledby_named?(attrs, id_texts) or
      present?(accessible_text(node)) or
      value_named?(tag, attrs) or
      present?(Map.get(label_for, attr(attrs, "id"))) or
      wrapped_by_named_label?(ancestors)
  end

  defp labelledby_named?(attrs, id_texts) do
    attrs
    |> attr("aria-labelledby")
    |> List.wrap()
    |> Enum.flat_map(&String.split/1)
    |> Enum.any?(&present?(Map.get(id_texts, &1)))
  end

  defp value_named?("input", attrs) do
    case attr(attrs, "type") do
      type when type in @button_value_types -> present?(attr(attrs, "value"))
      "image" -> present?(attr(attrs, "alt"))
      _other -> false
    end
  end

  defp value_named?(_tag, _attrs), do: false

  defp wrapped_by_named_label?(ancestors) do
    Enum.any?(ancestors, fn
      {"label", _attrs, _children} = label -> present?(accessible_text(label))
      _other -> false
    end)
  end

  defp present?(nil), do: false
  defp present?(text) when is_binary(text), do: String.trim(text) != ""

  # Text a screen reader would read for the element: text nodes and image alts, skipping subtrees
  # marked `aria-hidden="true"`.
  defp accessible_text({_tag, _attrs, children} = node), do: text_of(node, children, true)

  defp text_of(node, children, skip_hidden? \\ false) do
    node
    |> text_parts(children, skip_hidden?)
    |> Enum.join(" ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp text_parts({_tag, attrs, _children}, children, skip_hidden?) do
    if skip_hidden? and attr(attrs, "aria-hidden") == "true" do
      []
    else
      Enum.flat_map(children, &child_text(&1, skip_hidden?))
    end
  end

  defp child_text(text, _skip_hidden?) when is_binary(text), do: [text]
  defp child_text({:comment, _text}, _skip_hidden?), do: []

  defp child_text({"img", attrs, _children}, _skip_hidden?) do
    case attr(attrs, "alt") do
      alt when is_binary(alt) -> [alt]
      nil -> []
    end
  end

  defp child_text({_tag, _attrs, children} = node, skip_hidden?),
    do: text_parts(node, children, skip_hidden?)

  # ── Landmarks ──────────────────────────────────────────────────────────────

  defp main_problems(elements, :surface) do
    count =
      Enum.count(elements, fn {{tag, attrs, _children}, _ancestors} ->
        tag == "main" or attr(attrs, "role") == "main"
      end)

    if count == 1, do: [], else: [{:main_count, count}]
  end

  defp main_problems(_elements, _tier), do: []
end
