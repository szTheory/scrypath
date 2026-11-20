defmodule ScrypathOps.Test.CopyRules do
  @moduledoc false
  # Pure helpers for the copy rules table (`copy_rules.json`). There are no ExUnit macros here:
  # the real contract test and its planted-failure tests call these same functions, so a guard
  # that is calibrated by a planted failure is calibrated through its own code path.
  #
  # Text is matched against rendered HTML as a raw string. A phrase inside one text node is
  # found as written; attribute text is incidentally scanned but is not a promise (the table's
  # `not_covered` list says so).

  @row_fields ~w(id rule glossary forbidden required allowed_in source_scope surfaces)
  @entry_fields ~w(text match case)
  @id_pattern ~r/^[a-z0-9]+(-[a-z0-9]+)*(--[a-z0-9]+(-[a-z0-9]+)*)?$/
  @dir_glob_pattern ~r{^[A-Za-z0-9_.][A-Za-z0-9_./-]*/\*\*$}

  @doc "Absolute path of the table file, next to this module."
  def rules_path, do: Path.join(__DIR__, "copy_rules.json")

  @doc "Reads and decodes the table."
  def load!, do: rules_path() |> File.read!() |> Jason.decode!()

  @doc """
  Repository root, found by asking git from the table's directory. Fails with a message that
  names the cause instead of returning something that would make a scan pass on nothing.
  """
  def repo_root! do
    git = git!()

    case System.cmd(git, ["rev-parse", "--show-toplevel"],
           cd: Path.dirname(rules_path()),
           stderr_to_stdout: true
         ) do
      {out, 0} ->
        String.trim(out)

      {out, status} ->
        raise "copy rules scan could not find the repository root " <>
                "(`git rev-parse --show-toplevel` exited #{status}): #{String.trim(out)}"
    end
  end

  @doc "Bold terms in `GLOSSARY.md` (lines that start with `**Term**:`)."
  def glossary_terms(root) do
    root
    |> Path.join("GLOSSARY.md")
    |> File.read!()
    |> then(&Regex.scan(~r/^\*\*(.+?)\*\*:/m, &1, capture: :all_but_first))
    |> List.flatten()
    |> MapSet.new()
  end

  @doc """
  Bold terms in the `## Status wording` section of `GLOSSARY.md`: the entries the table is
  there to enforce. The section runs to the next `## ` heading or the end of the file.
  """
  def status_terms(root) do
    root
    |> Path.join("GLOSSARY.md")
    |> File.read!()
    |> String.split("\n")
    |> Enum.drop_while(&(&1 != "## Status wording"))
    |> Enum.drop(1)
    |> Enum.take_while(&(not String.starts_with?(&1, "## ")))
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\*\*(.+?)\*\*:/, line, capture: :all_but_first) do
        [term] -> [term]
        nil -> []
      end
    end)
  end

  @doc """
  Tracked text files, relative to `root`. Lists with `git ls-files -z` (the index), drops paths
  under `exempt_paths`, anything that is not a regular file, and any file that is not valid
  text (a NUL byte or invalid UTF-8). Raises when the list would be empty.
  """
  def tracked_paths(root, exempt_paths) do
    # `git ls-files -z`: a fixed argument list through System.cmd, never a shell string.
    case System.cmd(git!(), ["ls-files", "-z"], cd: root, stderr_to_stdout: true) do
      {out, 0} ->
        paths =
          out
          |> String.split(<<0>>, trim: true)
          |> Enum.reject(fn path -> Enum.any?(exempt_paths, &String.starts_with?(path, &1)) end)
          |> Enum.filter(&match?({:ok, _}, read_text(root, &1)))

        if paths == [] do
          raise "`git ls-files` from #{root} yielded no scannable files; " <>
                  "refusing to let a scan pass on an empty list"
        end

        paths

      {out, status} ->
        raise "copy rules scan could not list tracked files " <>
                "(`git ls-files` exited #{status} in #{root}): #{String.trim(out)}"
    end
  end

  @doc "Reads a regular text file; `:skip` for symlinks, binaries and invalid UTF-8."
  def read_text(root, path) do
    full = Path.join(root, path)

    with {:ok, %File.Stat{type: :regular}} <- File.lstat(full),
         {:ok, bytes} <- File.read(full),
         false <- :binary.match(bytes, <<0>>) != :nomatch,
         true <- String.valid?(bytes) do
      {:ok, bytes}
    else
      _ -> :skip
    end
  end

  @doc """
  True when `path` is in the scope. Two glob shapes exist: `**` (every scanned file) and a
  literal directory prefix followed by `/**`.
  """
  def in_scope?(path, scope) when is_list(scope), do: Enum.any?(scope, &in_glob?(path, &1))

  defp in_glob?(_path, "**"), do: true

  defp in_glob?(path, glob) do
    if valid_glob?(glob) do
      prefix = String.replace_suffix(glob, "**", "")
      String.starts_with?(path, prefix)
    else
      raise ArgumentError, "unsupported source_scope glob #{inspect(glob)}"
    end
  end

  @doc "The only two glob shapes the table accepts."
  def valid_glob?("**"), do: true
  def valid_glob?(glob) when is_binary(glob), do: Regex.match?(@dir_glob_pattern, glob)
  def valid_glob?(_other), do: false

  @doc """
  Validates the decoded table. Options: `:glossary_terms` (terms found in the glossary),
  `:surfaces` (a map of registered surface id to its state anchor) and the optional
  `:status_terms` (the glossary's Status wording entries; each must be cited by some row).

  Returns `:ok` or `{:error, messages}`.
  """
  def validate(rules, opts) when is_map(rules) do
    terms = opts |> Keyword.fetch!(:glossary_terms) |> MapSet.new()
    surfaces = Keyword.fetch!(opts, :surfaces)
    status_terms = Keyword.get(opts, :status_terms, [])

    errors = top_level_errors(rules)

    rows = Map.get(rules, "rules")

    errors =
      if is_list(rows) do
        errors ++
          (rows
           |> Enum.with_index(1)
           |> Enum.flat_map(fn {row, index} -> row_errors(row, index, terms, surfaces) end)) ++
          cross_row_errors(rows, surfaces) ++ uncited_term_errors(rows, status_terms)
      else
        errors ++ ["rules must be a list of rows"]
      end

    if errors == [], do: :ok, else: {:error, errors}
  end

  def validate(_other, _opts), do: {:error, ["the table must be a JSON object"]}

  defp top_level_errors(rules) do
    version = if rules["version"] == 1, do: [], else: ["version must be 1"]

    exempt =
      if string_list?(rules["exempt_paths"]),
        do: [],
        else: ["exempt_paths must be a list of strings"]

    not_covered =
      case rules["not_covered"] do
        [_ | _] = list ->
          if Enum.all?(list, &(is_binary(&1) and &1 != "")),
            do: [],
            else: ["not_covered entries must be non-empty sentences"]

        _ ->
          ["not_covered must list what the table does not guard"]
      end

    version ++ exempt ++ not_covered
  end

  defp row_errors(row, index, terms, surfaces) when is_map(row) do
    label = row_label(row, index)
    missing = for f <- @row_fields, not Map.has_key?(row, f), do: "#{label}: missing field #{f}"
    unknown = for f <- Map.keys(row) -- @row_fields, do: "#{label}: unknown field #{f}"

    if missing == [] do
      unknown ++ field_errors(row, label, terms, surfaces)
    else
      missing ++ unknown
    end
  end

  defp row_errors(_other, index, _terms, _surfaces), do: ["row #{index}: must be an object"]

  defp row_label(%{"id" => id}, _index) when is_binary(id) and id != "", do: "row #{id}"
  defp row_label(_row, index), do: "row #{index}"

  defp field_errors(row, label, terms, surfaces) do
    id_errors =
      if is_binary(row["id"]) and Regex.match?(@id_pattern, row["id"]),
        do: [],
        else: ["#{label}: id must be lower-case words joined by - (a variant follows --)"]

    rule_errors =
      if is_binary(row["rule"]) and String.trim(row["rule"]) != "",
        do: [],
        else: ["#{label}: rule must be a sentence"]

    glossary_errors =
      if is_binary(row["glossary"]) and MapSet.member?(terms, row["glossary"]),
        do: [],
        else: ["#{label}: glossary #{inspect(row["glossary"])} is not a bold term in GLOSSARY.md"]

    entry_errors =
      entries_errors(row["forbidden"], "forbidden", label) ++
        entries_errors(row["required"], "required", label)

    shape_errors =
      if entry_errors == [] and row["forbidden"] == [] and row["required"] == [],
        do: ["#{label}: needs a non-empty forbidden or required list"],
        else: []

    allowed_errors =
      if is_list(row["allowed_in"]) and
           Enum.all?(row["allowed_in"], &(is_binary(&1) and &1 != "")),
         do: [],
         else: ["#{label}: allowed_in must be a list of non-empty phrases"]

    scope_errors = scope_errors(row["source_scope"], label)
    surface_errors = surface_errors(row["surfaces"], label, surfaces)

    id_errors ++
      rule_errors ++
      glossary_errors ++
      entry_errors ++ shape_errors ++ allowed_errors ++ scope_errors ++ surface_errors
  end

  defp entries_errors(entries, field, label) when is_list(entries) do
    entries
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {entry, index} -> entry_errors(entry, "#{label}: #{field} ##{index}") end)
  end

  defp entries_errors(_other, field, label), do: ["#{label}: #{field} must be a list"]

  defp entry_errors(%{} = entry, where) do
    missing = for f <- @entry_fields, not Map.has_key?(entry, f), do: "#{where}: missing #{f}"
    unknown = for f <- Map.keys(entry) -- @entry_fields, do: "#{where}: unknown field #{f}"

    if missing == [] do
      unknown ++ entry_value_errors(entry, where)
    else
      missing ++ unknown
    end
  end

  defp entry_errors(_other, where), do: ["#{where}: must be an object"]

  defp entry_value_errors(entry, where) do
    text_errors =
      if is_binary(entry["text"]) and entry["text"] != "",
        do: [],
        else: ["#{where}: text must be a non-empty string"]

    match_errors =
      if entry["match"] in ["literal", "regex"],
        do: [],
        else: ["#{where}: match must be literal or regex"]

    case_errors =
      if entry["case"] in ["sensitive", "insensitive"],
        do: [],
        else: ["#{where}: case must be sensitive or insensitive"]

    compile_errors =
      if text_errors == [] and match_errors == [] and case_errors == [] do
        case compile(entry) do
          {:ok, regex} ->
            if Regex.match?(regex, ""),
              do: ["#{where}: pattern matches the empty string"],
              else: []

          {:error, {message, _}} ->
            ["#{where}: pattern does not compile (#{message})"]
        end
      else
        []
      end

    text_errors ++ match_errors ++ case_errors ++ compile_errors
  end

  defp scope_errors(scope, label) when is_list(scope) do
    for glob <- scope, not valid_glob?(glob) do
      "#{label}: source_scope glob #{inspect(glob)} is not ** or a literal directory followed by /**"
    end
  end

  defp scope_errors(_other, label), do: ["#{label}: source_scope must be a list"]

  defp surface_errors([_ | _] = ids, label, surfaces) do
    for id <- ids, not (is_binary(id) and Map.has_key?(surfaces, id)) do
      "#{label}: surface #{inspect(id)} is not registered"
    end
  end

  defp surface_errors(_other, label, _surfaces),
    do: ["#{label}: surfaces must be a non-empty list"]

  defp cross_row_errors(rows, surfaces) do
    maps = Enum.filter(rows, &is_map/1)

    ids = for %{"id" => id} <- maps, is_binary(id), do: id

    duplicate_errors =
      for {id, count} <- Enum.frequencies(ids), count > 1, do: "row #{id}: duplicate id"

    used =
      maps
      |> Enum.flat_map(fn row ->
        case row["surfaces"] do
          list when is_list(list) -> list
          _ -> []
        end
      end)
      |> MapSet.new()

    unused_errors =
      for {id, _anchor} <- surfaces, not MapSet.member?(used, id) do
        "surface #{id} is registered but no row uses it"
      end

    anchor_errors =
      for {id, anchor} <- surfaces, not (is_binary(anchor) and anchor != "") do
        "surface #{id} has no state anchor"
      end

    overlap_errors =
      for row <- maps,
          id <- surface_ids(row),
          anchor = Map.get(surfaces, id),
          is_binary(anchor) and anchor != "",
          entry <- entries(row),
          entry_valid?(entry),
          entry_hits?(entry, anchor) do
        "surface #{id}: the state anchor contains text row #{row["id"]} #{entry["text"] |> inspect()} " <>
          "forbids or requires"
      end

    duplicate_errors ++ unused_errors ++ anchor_errors ++ Enum.uniq(overlap_errors)
  end

  # A glossary term in the Status wording section that no row cites is a rule nobody enforces.
  defp uncited_term_errors(rows, status_terms) do
    cited = for %{"glossary" => term} <- rows, is_binary(term), into: MapSet.new(), do: term

    for term <- status_terms, not MapSet.member?(cited, term) do
      "glossary term #{inspect(term)} (Status wording) is cited by no row"
    end
  end

  defp surface_ids(row) do
    case row["surfaces"] do
      list when is_list(list) -> Enum.filter(list, &is_binary/1)
      _ -> []
    end
  end

  defp entries(row) do
    Enum.filter(List.wrap(row["forbidden"]) ++ List.wrap(row["required"]), &is_map/1)
  end

  defp entry_valid?(entry) do
    match?({:ok, _}, compile(entry))
  rescue
    _ -> false
  end

  defp entry_hits?(entry, text) do
    {:ok, regex} = compile(entry)
    Regex.match?(regex, text)
  end

  @doc """
  Rows with a `source_scope` glob that matches no scanned file. A typo in a scope would otherwise
  make its static scan pass on nothing.
  """
  def unmatched_scopes(rows, paths) do
    for row <- rows,
        dead =
          Enum.reject(row["source_scope"], fn glob -> Enum.any?(paths, &in_glob?(&1, glob)) end),
        dead != [] do
      %{row: row["id"], globs: dead}
    end
  end

  @doc """
  Scans the row's `source_scope` for forbidden text, comments included. `rel_paths` are paths
  relative to `root` (normally `tracked_paths/2`). Returns violations with the row id, the path
  and the matching text.
  """
  def scan_source(row, root, rel_paths) do
    case row["source_scope"] do
      [] ->
        []

      scope ->
        entries = compile_all!(row["forbidden"])

        for path <- rel_paths,
            in_scope?(path, scope),
            {:ok, text} <- [read_text(root, path)],
            hit <- forbidden_hits(entries, row["allowed_in"], text) do
          %{
            kind: :forbidden,
            row: row["id"],
            path: path,
            line: line_of(text, hit.index),
            text: hit.text
          }
        end
    end
  end

  @doc """
  Evaluates one row against one rendered surface: every `required` entry must be present and
  every `forbidden` entry absent (a hit inside an `allowed_in` phrase is excused).
  """
  def evaluate_surface(row, surface_id, html) when is_binary(html) do
    missing =
      for entry <- row["required"], not entry_hits?(entry, html) do
        %{kind: :required_missing, row: row["id"], surface: surface_id, text: entry["text"]}
      end

    present =
      for hit <-
            forbidden_hits(compile_all!(row["forbidden"]), row["allowed_in"], html) do
        %{kind: :forbidden, row: row["id"], surface: surface_id, text: hit.text}
      end

    missing ++ present
  end

  @doc """
  Checks one registered surface: its state anchor first, then every row that names it. When the
  anchor is absent the surface never reached its intended state, so no row is evaluated (a
  forbidden-only row would otherwise pass on a page that never showed the state).
  """
  def check_surface(rows, surface_id, anchor, html) when is_binary(html) do
    if String.contains?(html, anchor) do
      for row <- rows,
          surface_id in row["surfaces"],
          violation <- evaluate_surface(row, surface_id, html),
          do: violation
    else
      [%{kind: :anchor_missing, row: nil, surface: surface_id, text: anchor}]
    end
  end

  @doc "One line per violation, naming the row, the surface or file, and the matching text."
  def format_violation(%{kind: :forbidden, path: path, line: line} = v),
    do: "row #{v.row}: forbidden text #{inspect(v.text)} in #{path}:#{line}"

  def format_violation(%{kind: :forbidden} = v),
    do: "row #{v.row}: forbidden text #{inspect(v.text)} on surface #{v.surface}"

  def format_violation(%{kind: :required_missing} = v),
    do: "row #{v.row}: required text #{inspect(v.text)} missing on surface #{v.surface}"

  def format_violation(%{kind: :anchor_missing} = v),
    do: "surface #{v.surface}: state anchor #{inspect(v.text)} missing, so no row was evaluated"

  # Matching ------------------------------------------------------------------------------

  defp compile(%{"text" => text, "match" => match, "case" => kase}) do
    source = if match == "literal", do: Regex.escape(text), else: text
    Regex.compile(source, if(kase == "insensitive", do: "iu", else: "u"))
  end

  defp compile_all!(entries) do
    Enum.map(entries, fn entry ->
      {:ok, regex} = compile(entry)
      regex
    end)
  end

  defp forbidden_hits(regexes, allowed_in, text) do
    excused = allowed_ranges(allowed_in, text)

    for regex <- regexes,
        [{start, length} | _] <- Regex.scan(regex, text, return: :index),
        not excused?(excused, start, length) do
      %{text: binary_part(text, start, length), index: start}
    end
  end

  # An allowed_in phrase excuses only a hit that lies wholly inside one occurrence of that exact
  # phrase, never a wider region and never a neighbouring hit.
  defp allowed_ranges(allowed_in, text) do
    Enum.flat_map(allowed_in, fn phrase -> :binary.matches(text, phrase) end)
  end

  defp excused?(ranges, start, length) do
    Enum.any?(ranges, fn {from, len} -> from <= start and start + length <= from + len end)
  end

  defp line_of(text, index) do
    text |> binary_part(0, index) |> :binary.matches("\n") |> length() |> Kernel.+(1)
  end

  defp string_list?(list), do: is_list(list) and Enum.all?(list, &is_binary/1)

  defp git! do
    System.find_executable("git") ||
      raise "copy rules scan needs git on PATH: it lists tracked files with `git ls-files`"
  end
end
