defmodule ScrypathOps.Test.CatalogChecks do
  @moduledoc """
  Pure checks over the rendered catalog, used by `catalog_contract_test.exs`. No ExUnit macros: each
  function takes data (digests, an HTML document) and returns tagged problems, so a planted input can
  assert its exact cause and the real tree can assert `[]`.

    * `identical_variations/1` finds two variations of one story that render the same page in a
      theme, so a story never lists a state twice.
    * `dom_problems/2` finds broken DOM hygiene in one rendered story: a duplicate id, an ARIA
      reference to nothing (or the literal `"false"`), a control with no accessible name, and, for a
      surface-tier or jobs-tier story (each renders a whole page inside the shell), anything but
      exactly one main landmark.
    * `coverage_problems/4` finds a component or LiveView route that no story shows and that is not
      listed, with a reason, in the test's literal `@no_story` map, and an `@no_story` key that has
      become stale (it names something that is covered or no longer exists).
    * `provenance_problems/4` finds a variation whose provenance line, description or named proof
      claims more than it can back (see its doc).
    * `copy_rows/1` and `copy_problems/2` find rendered text that breaks a `copy_rules.json` row.

  Hashing and checks only look at `[data-phx-main] > *` and `[data-phx-main]`. The LiveView container
  itself carries per-mount session tokens, so hashing it would make two identical renders differ.
  """

  alias ScrypathOps.Test.CopyRules
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
    * `{:main_count, n}` - for tiers `:surface` and `:job` only, when the story has `n` main
      landmarks, not one

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

  @typedoc "A component is `{module, function_name}`; a route is its LiveView module."
  @type coverage_key :: {module(), atom()} | module()

  @doc """
  Compares what exists with what stories show.

    * `components` - every `{module, name}` function component of the app
    * `routes` - every LiveView module the router serves
    * `story_index` - `%{components: [{module, name}], routes: [module]}`: the functions stories
      render, and the LiveViews that surface-tier and jobs-tier stories cover
    * `no_story` - `%{key => reason}`: what is knowingly not storied, each with a one-line reason

  Reports, in a stable order:

    * `{:uncovered, key}` - exists, no story shows it, and `no_story` does not list it
    * `{:stale_no_story, key}` - `no_story` lists a key that a story now covers, or that no longer
      exists
    * `{:no_reason, key}` - `no_story` lists a key with a blank reason
  """
  @spec coverage_problems([coverage_key()], [module()], map(), %{coverage_key() => String.t()}) ::
          [tuple()]
  def coverage_problems(components, routes, story_index, no_story) do
    keys = components ++ routes
    covered = MapSet.new(story_index.components ++ story_index.routes)
    existing = MapSet.new(keys)

    uncovered =
      for key <- keys, not MapSet.member?(covered, key), not Map.has_key?(no_story, key) do
        {:uncovered, key}
      end

    stale =
      for {key, _reason} <- no_story,
          MapSet.member?(covered, key) or not MapSet.member?(existing, key) do
        {:stale_no_story, key}
      end

    no_reason =
      for {key, reason} <- no_story, not present?(reason) or reason =~ "\n" do
        {:no_reason, key}
      end

    Enum.sort(uncovered) ++ Enum.sort(stale) ++ Enum.sort(no_reason)
  end

  @provenance ~r/\AAdopter: (?<adopter>[A-Z][A-Za-z]+) \(fictional\) · Persona: (?<persona>[^()]+) \((?<role>ROLE-[A-Z]+)\) · Job: (?<job>JOB-\d+) · Proof: (?:render only|Mounted (?<path>\S+)(?: · Claim: (?<claim>.+))?)\z/u
  @max_description 140

  @typedoc """
  What `provenance_problems/4` checks against:

    * `:adopters` - the registered fictional adopter names (for example `"Shopadelic"`)
    * `:roles` and `:jobs` - the `ROLE-*` and `JOB-*` ids that `OPERATOR-UI-QUALITY.md` defines
    * `:scenario_ids` - every registered fixture scenario id, as strings
    * `:read_file` - `(repo-relative path -> {:ok, text} | {:error, term})`
  """
  @type known :: %{
          adopters: [String.t()],
          roles: [String.t()],
          jobs: [String.t()],
          scenario_ids: [String.t()],
          read_file: (String.t() -> {:ok, String.t()} | {:error, term()})
        }

  @doc """
  What one variation claims, and whether it can back the claim. `variation` is the story's
  `%Variation{}` (read for `id`, `description` and `note`); `story_module` answers `job/0`.

  The first line of the note must read
  `Adopter: <Name> (fictional) · Persona: <label> (ROLE-X) · Job: JOB-NN · Proof: render only` or
  `... · Proof: Mounted <test path>`, with an optional ` · Claim: <literal>` after the path. Then:

    * the adopter, role and job are registered (`{:unknown_adopter, name}`, `{:unknown_role, id}`,
      `{:bad_job, id}`), and the job is the story's own `job/0` (`{:job_mismatch, note, story}`)
    * a jobs-tier story file names its job: `JOB-03` needs `job_03` in the path
      (`{:job_not_in_path, job, path}`)
    * a `Mounted` file exists (`{:missing_test, path}`) and contains the variation's scenario id (the
      longest registered scenario id its own id starts with) or, when the note declares a `Claim`,
      that literal (`{:unbacked_proof, path, needle}`), so a description cannot claim more than the
      linked test mentions; a `Mounted` label with neither gives `{:proof_without_needle, id}`
    * the description is present and at most #{@max_description} characters
      (`{:missing_description, id}`, `{:long_description, length}`)

  A note whose first line does not match gives `{:no_provenance, id}` and stops there. Primitive
  stories are exempt: they are adopter-independent, so the caller does not lint them.
  """
  @spec provenance_problems(String.t(), module(), struct(), known()) :: [tuple()]
  def provenance_problems(story_path, story_module, variation, known) do
    id = to_string(variation.id)

    description_problems(id, variation.description) ++
      case parse_provenance(variation.note) do
        nil -> [{:no_provenance, id}]
        parsed -> note_problems(id, story_path, story_module, parsed, known)
      end
  end

  defp parse_provenance(note) when is_binary(note) do
    first = note |> String.split("\n", parts: 2) |> hd() |> String.trim()
    Regex.named_captures(@provenance, first)
  end

  defp parse_provenance(_note), do: nil

  defp description_problems(id, description) do
    cond do
      not present?(description) ->
        [{:missing_description, id}]

      String.length(description) > @max_description ->
        [{:long_description, String.length(description)}]

      true ->
        []
    end
  end

  defp note_problems(id, story_path, story_module, parsed, known) do
    %{"adopter" => adopter, "role" => role, "job" => job, "path" => path, "claim" => claim} =
      parsed

    registered(adopter, known.adopters, :unknown_adopter) ++
      registered(role, known.roles, :unknown_role) ++
      registered(job, known.jobs, :bad_job) ++
      job_matches(job, story_module) ++
      job_in_path(job, story_path) ++
      proof_problems(id, path, claim, known)
  end

  defp registered(value, known_values, tag),
    do: if(value in known_values, do: [], else: [{tag, value}])

  defp job_matches(job, story_module) do
    story_job = if function_exported?(story_module, :job, 0), do: story_module.job()
    if story_job == job, do: [], else: [{:job_mismatch, job, story_job}]
  end

  defp job_in_path(job, story_path) do
    if tier(story_path) == :job do
      needle = job |> String.downcase() |> String.replace("-", "_")
      if String.contains?(story_path, needle), do: [], else: [{:job_not_in_path, job, story_path}]
    else
      []
    end
  end

  defp proof_problems(_id, "", _claim, _known), do: []

  defp proof_problems(id, path, claim, known) do
    needle =
      if claim != "",
        do: claim,
        else: scenario_prefix(id, known.scenario_ids)

    case known.read_file.(path) do
      {:error, _reason} ->
        [{:missing_test, path}]

      {:ok, _text} when is_nil(needle) ->
        [{:proof_without_needle, id}]

      {:ok, text} ->
        if String.contains?(text, needle), do: [], else: [{:unbacked_proof, path, needle}]
    end
  end

  # The longest registered scenario id that the variation id starts with.
  defp scenario_prefix(id, scenario_ids) do
    scenario_ids
    |> Enum.filter(&String.starts_with?(id, &1))
    |> Enum.max_by(&String.length/1, fn -> nil end)
  end

  @doc """
  The `copy_rules.json` rows that govern every rendered story: the rows that scan all of
  `scrypath_ops/lib` or all files (a non-empty `source_scope`) and forbid something. A row with an
  empty `source_scope` describes one screen state (for example the Clear word beside a retained
  observation), so applying it to an unrelated story would flag legitimate copy.
  """
  @spec copy_rows(map()) :: [map()]
  def copy_rows(%{"rules" => rules}),
    do: Enum.filter(rules, &(&1["source_scope"] != [] and &1["forbidden"] != []))

  @doc """
  The forbidden text of each row found in the rendered markup, as `{:copy, row_id, matched_text}`.
  Required text is not checked (a story shows one state, not a whole screen).
  """
  @spec copy_problems(String.t(), [map()]) :: [{:copy, String.t(), String.t()}]
  def copy_problems(html, rows) do
    for row <- rows,
        violation <- CopyRules.evaluate_surface(Map.put(row, "required", []), "story", html) do
      {:copy, violation.row, violation.text}
    end
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

  # A surface story and a jobs-tier story each render a whole page inside the operator shell, so each
  # has exactly one main landmark. Areas, patterns and primitives render fragments and have none.
  defp main_problems(elements, tier) when tier in [:surface, :job] do
    count =
      Enum.count(elements, fn {{tag, attrs, _children}, _ancestors} ->
        tag == "main" or attr(attrs, "role") == "main"
      end)

    if count == 1, do: [], else: [{:main_count, count}]
  end

  defp main_problems(_elements, _tier), do: []
end
