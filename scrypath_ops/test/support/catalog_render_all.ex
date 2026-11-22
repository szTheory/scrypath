defmodule ScrypathOps.Catalog.RenderAll do
  @moduledoc false

  # Pure helpers for the catalog render-all check. The `live/2` loop stays in the test module so the
  # same code path runs against the real endpoint and the planted one.

  @css_import ~r|@import "/assets/css/app\.css\?hash=[0-9a-f]{32}" layer\(app\)|
  @js_hash ~r|\?hash=[0-9a-f]{32}\z|

  @doc """
  Every `{path, variation_id}` the catalog can render for a backend. A component story gives one
  target per variation, an example gives `{path, nil}`, a page story gives `{path, :page}` (rendered
  through the storybook shell, not an iframe) and any other kind is `{path, {:unsupported, kind}}`.
  """
  def targets(backend) do
    for entry <- backend.leaves(),
        {:ok, story} = backend.load_story(String.trim_leading(entry.path, "/")),
        target <- story_targets(entry.path, story),
        do: target
  end

  defp story_targets(path, story) do
    case story.storybook_type() do
      :component -> for variation <- story.variations(), do: {path, to_string(variation.id)}
      :example -> [{path, nil}]
      :page -> [{path, :page}]
      other -> [{path, {:unsupported, other}}]
    end
  end

  def url(mount, path, variation_id, theme) do
    query =
      if variation_id,
        do: "?variation_id=#{variation_id}&theme=#{theme}",
        else: "?theme=#{theme}"

    "#{mount}/iframe#{path}#{query}"
  end

  @doc "Labels of every failing check for one rendered iframe document; an empty list means it passed."
  def problems(html) do
    doc = LazyHTML.from_document(html)
    sandbox = LazyHTML.query(doc, "[data-phx-main] > *")
    inner = LazyHTML.query(doc, "[data-phx-main] > * > *")
    styles = doc |> LazyHTML.query("style") |> LazyHTML.text()
    scripts = LazyHTML.query(doc, ~s(script[src^="/assets/js/storybook.js?hash="]))

    [
      {Enum.empty?(sandbox), "no LiveView sandbox container"},
      {Enum.empty?(inner) and sandbox |> LazyHTML.text() |> String.trim() == "", "empty output"},
      # Kept for the requirement wording: LiveView 1.1.34 and the storybook never emit this
      # attribute server-side, so the crash, empty and unknown-variation plants are the real signals.
      {not Enum.empty?(LazyHTML.query(doc, "[data-phx-error]")), "data-phx-error present"},
      {not Regex.match?(@css_import, styles), "css_path did not resolve (no ?hash=)"},
      {not js_hash?(scripts), "js_path did not resolve (no ?hash=)"}
    ]
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp js_hash?(scripts) do
    case LazyHTML.attribute(scripts, "src") do
      [src | _] -> Regex.match?(@js_hash, src)
      [] -> false
    end
  end

  @doc "The shell route of a page story, for example `/storybook/welcome`."
  def page_url(mount, path), do: "#{mount}#{path}"

  @doc """
  The story's own markup in a rendered storybook page. A `:page` story renders inside the storybook
  shell, in the sandbox div, so this leaves out the sidebar and toolbar (which are upstream's).
  """
  def page_markup(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("[data-phx-main] .psb-sandbox")
    |> LazyHTML.to_html()
  end

  @doc "Labels of every failing check for one rendered page story; an empty list means it passed."
  def page_problems(html) do
    doc = LazyHTML.from_document(html)
    content = LazyHTML.query(doc, "[data-phx-main] .psb-sandbox")

    [
      {Enum.empty?(LazyHTML.query(doc, "[data-phx-main]")), "no LiveView container"},
      {Enum.empty?(content), "no page content"},
      {not Enum.empty?(content) and content |> LazyHTML.text() |> String.trim() == "",
       "empty page content"},
      {not Enum.empty?(LazyHTML.query(doc, "[data-phx-error]")), "data-phx-error present"}
    ]
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  @doc "A problem label when the body does not carry the requested theme, else nil."
  def theme_problem(html, theme) do
    doc = LazyHTML.from_document(html)

    if Enum.empty?(LazyHTML.query(doc, ~s(body[data-theme="#{theme}"]))),
      do: "body data-theme is not #{theme}"
  end
end
