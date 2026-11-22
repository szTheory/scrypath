defmodule ScrypathFixtures.Check do
  @moduledoc """
  The no-database consistency check for every fixture scenario. The data is fictional and for
  development and tests only.

  `run/1` returns `{:ok, %{scenarios: n}}` or `{:error, problems}`. A problem is a
  `{scenario_id, tag_tuple}` pair whose tag tuple starts with one of `invariants/0`. A problem in
  the failure table itself has `:failures` where the scenario id would be, a problem in a source
  file has `:source`, and a problem in the bulk data has `:bulk`. Callers can pass `:scenarios`,
  `:builders`, `:now`, `:failures` (a list of table entries), `:source_files`, `:bulk_sample` and
  `:labels`, so a test can plant a broken scenario, builder, table, source file, bulk sample or
  label without a special mode.

  The check never reads the operator UI and never touches a database. It does these kinds of work:

    * invariants on the raw data (key sets, index names, time order, Oban attempt rules), taken from
      Meilisearch's documented behaviour and Oban's executor;
    * invariants on the registry and its labels: unique ids, every label says "(fictional)", every
      stress scenario says "stress", every Oban job names an allowlisted schema;
    * relative time: a scenario built three days later must differ by exactly three days in every
      stamp and in nothing else, so no stamp is pinned to a calendar date;
    * shape checks against the recorded Meilisearch v1.15 payloads (`ScrypathFixtures.Recordings`):
      every task's value types equal the recorded task of its status, and its `details` keys equal
      the recorded ones for its type. Key sets and types only, never values;
    * failure text: every task `error` and every Oban `errors` entry must be what an entry of the
      closed table (`ScrypathFixtures.Failures`) renders, every table entry's `:source` must
      resolve to a recording or an existing repository path, and no entry may be on the table's
      `cannot_produce/0` list;
    * a round trip through the real Scrypath code: every task map must pass
      `Scrypath.Meilisearch.TaskPayload.normalize/2`, and `Scrypath.sync_status/2` and
      `Scrypath.failed_sync_work/2` must answer as the scenario's `:expect` says.

  Three more kinds of check read the project's own text and its bulk data:

    * source lints over every file of the project: no raw bidirectional control, zero-width
      character or byte-order mark (hostile text is written as escapes, never typed), and no
      wall-clock, random, operating-system or repository call in `lib/` (every time is `now` minus an
      offset);
    * labels and data: no compliance-claim word and no sibling-brand canon id in a scenario label,
      any string inside a scenario, the README or `lib/` source, and a provenance line (fictional,
      Scrypath-owned, no records copied) in every adopter module and schema;
    * the bulk data: the digest of the fixed sample must equal the golden digest in
      `ScrypathFixtures.Bulk`.

  Anything that reaches `Scrypath.Config.resolve!/1` or `Scrypath.index_contract_drift/2` is given
  `ScrypathFixtures.Scenario.runtime_opts/1`; `sync_status/2` and `failed_sync_work/2` take the
  full options because they split the operator keys off themselves.
  """

  alias Scrypath.Meilisearch.TaskPayload
  alias ScrypathFixtures.Bulk
  alias ScrypathFixtures.Failures
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.Recordings
  alias ScrypathFixtures.Scenario
  alias ScrypathFixtures.Scenarios

  @invariants [
    :wire_guard,
    :unexpected_outcome,
    :task_keys,
    :index_uid,
    :time_order,
    :unparsable_time,
    :meili_cancelled_spelling,
    :task_shape,
    :details_keys,
    :unknown_failure,
    :failure_source_missing,
    :forbidden_failure,
    :job_index,
    :retryable_attempts,
    :discarded_attempts,
    :job_in_future,
    :duplicate_id,
    :job_schema,
    :time_not_relative,
    :unlabelled,
    :stress_unmarked,
    :raw_format_char,
    :impure_source,
    :denylisted_word,
    :provenance_missing,
    :bulk_digest
  ]

  @type problem :: {atom(), tuple()}

  @doc """
  Every problem tag `run/1` can emit.

  The first element of each problem's tag tuple is one of these atoms. A new invariant adds its
  tag here in the same change that adds the check.
  """
  @spec invariants() :: [atom()]
  def invariants, do: @invariants

  @doc "The scenarios `run/1` checks by default: every registered scenario, built at `now`."
  @spec scenarios(DateTime.t()) :: [Scenario.t()]
  def scenarios(%DateTime{} = now), do: Scenarios.all(now)

  @doc """
  Checks scenarios and returns `{:ok, %{scenarios: n}}` or `{:error, [problem]}`.

  Options:

    * `:now` (default `ScrypathFixtures.preview_epoch/0`);
    * `:builders` (default `ScrypathFixtures.Scenarios.builders/0`): a list of `{id, fun}` where
      `fun` takes `now` and returns a scenario. The relative-time invariant needs a builder, not
      a built scenario, because it builds the same scenario at two instants;
    * `:scenarios` (default: every builder's scenario built at `now`);
    * `:failures` (default `ScrypathFixtures.Failures.all/0`);
    * `:source_files` (default: every file of this project outside `_build` and `deps`): a list of
      paths to read, or `{path, content}` pairs to scan without a file. A path decides what a file
      is: `.../lib/...ex` is source, `.../lib/scrypath_fixtures/<adopter>.ex` and
      `.../lib/scrypath_fixtures/<adopter>/...` are adopter files;
    * `:bulk_sample` (default `ScrypathFixtures.Bulk.sample/0`): the term whose digest is compared
      with the golden one;
    * `:labels` (default: `{id, label}` of every scenario): the labels scanned for denied words.

  The relative-time check runs over `:builders`. A caller that passes only `:scenarios` gave no
  builders, so that check is skipped for that call.
  """
  @spec run(keyword()) :: {:ok, %{scenarios: non_neg_integer()}} | {:error, [problem()]}
  def run(opts \\ []) do
    now = Keyword.get(opts, :now, ScrypathFixtures.preview_epoch())
    failures = Keyword.get_lazy(opts, :failures, &Failures.all/0)

    {scenarios, builders} =
      case {Keyword.fetch(opts, :scenarios), Keyword.fetch(opts, :builders)} do
        {{:ok, scenarios}, {:ok, builders}} -> {scenarios, builders}
        {{:ok, scenarios}, :error} -> {scenarios, []}
        {:error, {:ok, builders}} -> {build_all(builders, now), builders}
        {:error, :error} -> {scenarios(now), Scenarios.builders()}
      end

    sources = opts |> Keyword.get_lazy(:source_files, &default_source_files/0) |> read_sources()
    sample = Keyword.get_lazy(opts, :bulk_sample, &Bulk.sample/0)
    labels = Keyword.get_lazy(opts, :labels, fn -> Enum.map(scenarios, &{&1.id, &1.label}) end)

    problems =
      table_problems(failures) ++
        registry_problems(scenarios) ++
        Enum.flat_map(scenarios, &check_scenario/1) ++
        Enum.flat_map(builders, &time_problems(&1, now)) ++
        word_problems(labels, scenarios, sources) ++
        source_problems(sources, scenarios) ++
        bulk_problems(sample)

    case problems do
      [] -> {:ok, %{scenarios: length(scenarios)}}
      problems -> {:error, problems}
    end
  end

  defp build_all(builders, now), do: Enum.map(builders, fn {_id, build} -> build.(now) end)

  # -- the registry and the labels -------------------------------------------------------------

  defp registry_problems(scenarios) do
    duplicates =
      scenarios
      |> Enum.frequencies_by(& &1.id)
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> {id, {:duplicate_id, id}} end)

    duplicates ++ Enum.flat_map(scenarios, &label_problems/1)
  end

  defp label_problems(%Scenario{id: id, label: label, kind: kind}) do
    unlabelled =
      if String.contains?(label, "(fictional)"), do: [], else: [{id, {:unlabelled, id}}]

    unmarked =
      if kind == :stress and not String.contains?(String.downcase(label), "stress"),
        do: [{id, {:stress_unmarked, id}}],
        else: []

    unlabelled ++ unmarked
  end

  # -- the project's own text: source lints, denied words, provenance ---------------------------

  # The project root, computed once at compile time (research A6): this check only runs from a
  # source checkout, never from a release.
  @fixtures_root Path.expand("../..", __DIR__)

  # The characters Trojan Source hides behind: zero-width and direction marks (U+200B to U+200F),
  # bidirectional embeddings and overrides (U+202A to U+202E), isolates (U+2066 to U+2069) and the
  # byte-order mark (U+FEFF). Written as code points, so this file holds none of them itself.
  @format_codepoints Enum.to_list(0x200B..0x200F) ++
                       Enum.to_list(0x202A..0x202E) ++
                       Enum.to_list(0x2066..0x2069) ++ [0xFEFF]

  defp default_source_files do
    @fixtures_root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.reject(&build_artifact?/1)
    |> Enum.sort()
  end

  defp build_artifact?(path) do
    case path |> Path.relative_to(@fixtures_root) |> Path.split() do
      [top | _rest] -> top in ["_build", "deps"]
      [] -> false
    end
  end

  # A source is `{path, content}`: a bare path is read, a pair is scanned as given.
  defp read_sources(files) do
    Enum.map(files, fn
      {path, content} when is_binary(path) and is_binary(content) -> {path, content}
      path when is_binary(path) -> {path, File.read!(path)}
    end)
  end

  defp relative(path), do: Path.relative_to(path, @fixtures_root)

  defp lib_source?(path), do: String.ends_with?(path, ".ex") and String.contains?(path, "/lib/")

  defp source_problems(sources, scenarios) do
    adopters = scenarios |> Enum.map(&Atom.to_string(&1.adopter)) |> Enum.uniq()
    patterns = impure_patterns()

    Enum.flat_map(sources, fn {path, content} ->
      raw_format_problems(path, content) ++
        impure_problems(path, content, patterns) ++
        provenance_problems(path, content, adopters)
    end)
  end

  defp raw_format_problems(path, content) do
    for codepoint <- @format_codepoints,
        :binary.match(content, <<codepoint::utf8>>) != :nomatch,
        do: {:source, {:raw_format_char, relative(path), codepoint}}
  end

  # The calls a pure builder must not make. Each is written in two pieces so this file does not
  # contain the text it searches for: this file stays under its own lint instead of being exempt.
  defp impure_tokens do
    [
      "DateTime" <> ".utc_now",
      "NaiveDateTime" <> ".utc_now",
      "Date" <> ".utc_today",
      ":rand" <> ".",
      "System" <> ".",
      ":os" <> ".",
      "Repo" <> ".",
      "~U" <> "["
    ]
  end

  # A token counts only where a word starts, so a call on `NaiveDateTime` is one problem and not
  # also one for the `DateTime` token it contains.
  defp impure_patterns do
    for token <- impure_tokens() do
      {token, Regex.compile!("(?<![A-Za-z0-9_])" <> Regex.escape(token))}
    end
  end

  # The one datetime literal in the project lives in `lib/scrypath_fixtures.ex` (the preview epoch).
  defp impure_problems(path, content, patterns) do
    if lib_source?(path) do
      for {token, pattern} <- patterns,
          Regex.match?(pattern, content),
          not (token == "~U" <> "[" and String.ends_with?(path, "/lib/scrypath_fixtures.ex")),
          do: {:source, {:impure_source, relative(path), token}}
    else
      []
    end
  end

  # An adopter file is a module or schema under `lib/scrypath_fixtures/<adopter>.ex` or
  # `lib/scrypath_fixtures/<adopter>/`. It needs one line that says the adopter is fictional,
  # Scrypath-owned data and that no records were copied.
  defp provenance_problems(path, content, adopters) do
    if adopter_source?(path, adopters) and not provenance_line?(content) do
      [{:source, {:provenance_missing, relative(path)}}]
    else
      []
    end
  end

  defp adopter_source?(path, adopters) do
    lib_source?(path) and
      Enum.any?(adopters, fn adopter ->
        String.ends_with?(path, "/lib/scrypath_fixtures/#{adopter}.ex") or
          String.contains?(path, "/lib/scrypath_fixtures/#{adopter}/")
      end)
  end

  defp provenance_line?(content) do
    content
    |> String.split("\n")
    |> Enum.any?(fn line ->
      line = String.downcase(line)
      Enum.all?(["fictional", "scrypath-owned", "no record"], &String.contains?(line, &1))
    end)
  end

  # Compliance claims are never made by fictional data, and the sibling brand repositories'
  # records are never copied. The words live here and nowhere else in the project: the README says
  # the rule without listing them, and the scan below skips this one file by path, because its
  # attribute is the one place that has to name them.
  @denied_words ~w(HIPAA GDPR PCI SOX compliant certified)
  @canon_sentinel "LGX-0417-DE"

  defp denied_words, do: @denied_words ++ [@canon_sentinel]

  defp denied_regex do
    words = denied_words() |> Enum.map(&Regex.escape/1) |> Enum.join("|")
    Regex.compile!("\\b(" <> words <> ")\\b", "i")
  end

  # The denied words found in `text`, each as spelled in the list (the text is matched without case).
  defp words_in(text) when is_binary(text) do
    denied_regex()
    |> Regex.scan(text, capture: :first)
    |> Enum.map(fn [found] ->
      Enum.find(denied_words(), &(String.downcase(&1) == String.downcase(found)))
    end)
    |> Enum.uniq()
  end

  defp word_problems(labels, scenarios, sources) do
    in_labels =
      for {id, label} <- labels,
          word <- words_in(label),
          do: {id, {:denylisted_word, {:label, id}, word}}

    in_data =
      for %Scenario{id: id} = scenario <- scenarios,
          word <-
            [scenario.scrypath_opts, scenario.expect]
            |> strings_in()
            |> Enum.flat_map(&words_in/1)
            |> Enum.uniq(),
          do: {id, {:denylisted_word, {:scenario, id}, word}}

    in_files =
      for {path, content} <- sources,
          scanned_for_words?(path),
          word <- words_in(content),
          do: {:source, {:denylisted_word, {:file, relative(path)}, word}}

    in_labels ++ in_data ++ in_files
  end

  # The README and the `lib/` source, except the check itself (see `@denied_words`).
  defp scanned_for_words?(path) do
    not String.ends_with?(path, "/lib/scrypath_fixtures/check.ex") and
      (Path.basename(path) == "README.md" or lib_source?(path))
  end

  # Every binary inside a term: map and keyword values, list and tuple members, struct fields.
  defp strings_in(term) when is_binary(term), do: [term]
  defp strings_in(term) when is_struct(term), do: term |> Map.from_struct() |> strings_in()
  defp strings_in(term) when is_map(term), do: term |> Map.to_list() |> strings_in()
  defp strings_in(term) when is_tuple(term), do: term |> Tuple.to_list() |> strings_in()
  defp strings_in(term) when is_list(term), do: Enum.flat_map(term, &strings_in/1)
  defp strings_in(_term), do: []

  defp bulk_problems(sample) do
    digest = Bulk.digest(sample)
    if digest == Bulk.golden_digest(), do: [], else: [{:bulk, {:bulk_digest, digest}}]
  end

  # -- relative time ---------------------------------------------------------------------------

  # Three days, in seconds. Any whole number of seconds that moves every stamp would do; the point
  # is that the scenario built later differs from the first in time and in nothing else.
  @shift_seconds 3 * 86_400
  @stamp ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z/

  defp time_problems({id, build}, now) do
    shifted_now = DateTime.add(now, @shift_seconds, :second)

    build.(now)
    |> shift_mismatches(build.(shifted_now), [])
    |> Enum.take(5)
    |> Enum.map(&{id, {:time_not_relative, id, Enum.reverse(&1)}})
  end

  # Walks two builds in parallel and returns the path of every leaf that is not "the same value,
  # with its time moved by exactly `@shift_seconds`". A leaf is a `DateTime`, a string holding
  # Meilisearch-style stamps (a stamp field, or an Oban error text that embeds a raw task), or any
  # other term, which must be equal.
  defp shift_mismatches(%DateTime{} = first, %DateTime{} = second, path) do
    if DateTime.diff(second, first, :microsecond) == @shift_seconds * 1_000_000,
      do: [],
      else: [path]
  end

  defp shift_mismatches(first, second, path) when is_binary(first) and is_binary(second) do
    first_stamps = Regex.scan(@stamp, first)
    second_stamps = Regex.scan(@stamp, second)

    cond do
      first_stamps == [] and second_stamps == [] ->
        if first == second, do: [], else: [path]

      length(first_stamps) != length(second_stamps) ->
        [path]

      Regex.replace(@stamp, first, "<time>") != Regex.replace(@stamp, second, "<time>") ->
        [path]

      true ->
        shifted? =
          Enum.zip_with(first_stamps, second_stamps, fn [a | _], [b | _] ->
            stamp_shifted?(a, b)
          end)

        if Enum.all?(shifted?, & &1), do: [], else: [path]
    end
  end

  defp shift_mismatches(first, second, path) when is_struct(first) and is_struct(second) do
    if first.__struct__ == second.__struct__,
      do: shift_mismatches(Map.from_struct(first), Map.from_struct(second), path),
      else: [path]
  end

  defp shift_mismatches(first, second, path) when is_map(first) and is_map(second) do
    if Enum.sort(Map.keys(first)) == Enum.sort(Map.keys(second)) do
      first
      |> Map.keys()
      |> Enum.sort()
      |> Enum.flat_map(
        &shift_mismatches(Map.fetch!(first, &1), Map.fetch!(second, &1), [&1 | path])
      )
    else
      [path]
    end
  end

  # A non-empty keyword list (`scrypath_opts`) is walked by key, so a path names the option.
  defp shift_mismatches([{key, _} | _] = first, [{_, _} | _] = second, path) when is_atom(key) do
    if Keyword.keyword?(first) and Keyword.keyword?(second) and
         Keyword.keys(first) == Keyword.keys(second) do
      first
      |> Keyword.keys()
      |> Enum.flat_map(
        &shift_mismatches(Keyword.fetch!(first, &1), Keyword.fetch!(second, &1), [&1 | path])
      )
    else
      shift_list_mismatches(first, second, path)
    end
  end

  defp shift_mismatches(first, second, path) when is_list(first) and is_list(second),
    do: shift_list_mismatches(first, second, path)

  defp shift_mismatches(first, second, path) when is_tuple(first) and is_tuple(second) do
    shift_mismatches(Tuple.to_list(first), Tuple.to_list(second), path)
  end

  defp shift_mismatches(first, second, path), do: if(first == second, do: [], else: [path])

  defp shift_list_mismatches(first, second, path) do
    if length(first) == length(second) do
      first
      |> Enum.zip(second)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{a, b}, index} -> shift_mismatches(a, b, [index | path]) end)
    else
      [path]
    end
  end

  defp stamp_shifted?(first, second) do
    with {:ok, a, _} <- DateTime.from_iso8601(first),
         {:ok, b, _} <- DateTime.from_iso8601(second) do
      DateTime.diff(b, a, :microsecond) == @shift_seconds * 1_000_000
    else
      _error -> false
    end
  end

  # -- the failure table ---------------------------------------------------------------------

  # `lib/scrypath/...` paths in a `:source` are from the repository root, computed here once.
  @repo_root Path.expand("../../../..", __DIR__)

  defp table_problems(failures) do
    names = Enum.map(Failures.cannot_produce(), & &1.id)

    Enum.flat_map(failures, fn entry ->
      source_problem =
        if source_resolves?(Map.get(entry, :source)),
          do: [],
          else: [{:failures, {:failure_source_missing, entry.id}}]

      forbidden_problem =
        if to_string(entry.id) in names or Map.get(entry, :code) in names,
          do: [{:failures, {:forbidden_failure, entry.id}}],
          else: []

      source_problem ++ forbidden_problem
    end)
  end

  defp source_resolves?(source) when is_binary(source) do
    source in Recordings.files() or
      (Path.type(source) == :relative and not String.contains?(source, "..") and
         File.exists?(Path.join(@repo_root, source)))
  end

  defp source_resolves?(_source), do: false

  defp check_scenario(%Scenario{} = scenario) do
    tasks = list_opt(scenario, :meilisearch_tasks)
    jobs = list_opt(scenario, :oban_jobs)
    indexes = allowed_indexes(scenario)

    task_problems = Enum.flat_map(tasks, &task_problems(scenario, &1, indexes))
    job_problems = Enum.flat_map(jobs, &job_problems(scenario, &1, indexes))

    task_problems ++ job_problems ++ round_trip_problems(scenario)
  end

  defp list_opt(%Scenario{scrypath_opts: opts}, key) do
    case Keyword.get(opts, key, []) do
      list when is_list(list) -> list
      _other -> []
    end
  end

  # -- index names ---------------------------------------------------------------------------

  defp allowed_indexes(%Scenario{allowlist: allowlist, scrypath_opts: opts}) do
    naming_opts = Keyword.take(opts, [:index_prefix])

    Enum.flat_map(allowlist, fn schema ->
      live = Scrypath.Meilisearch.index_name(schema, naming_opts)
      [live, live <> "__reindex"]
    end)
  end

  # -- tasks ---------------------------------------------------------------------------------

  defp task_problems(scenario, task, indexes) do
    uid = task["uid"]

    List.flatten([
      wire_guard(task, uid),
      task_keys(task, uid),
      task_shape(task, uid),
      details_keys(task, uid),
      task_failure(task, uid),
      task_index(task, uid, indexes),
      task_times(scenario, task, uid),
      meili_spelling(task, uid)
    ])
    |> tag(scenario)
  end

  defp wire_guard(task, uid) do
    case TaskPayload.normalize(task, :poll) do
      {:ok, _normalized} -> []
      {:error, _reason} -> [{:wire_guard, uid}]
    end
  end

  defp task_keys(task, uid) do
    if Enum.sort(Map.keys(task)) == Enum.sort(Meili.keys()), do: [], else: [{:task_keys, uid}]
  end

  # The three stamps may each be a string or null (a waiting task has no start). Everything else
  # must have the JSON type the recorded task of the same status has. A swap has a null index.
  @stamp_keys ~w(enqueuedAt startedAt finishedAt)

  defp task_shape(%{"status" => status} = task, uid) when is_binary(status) do
    if status in Recordings.statuses() do
      exemplar = Recordings.task_exemplar!(status)

      for key <- Meili.keys(),
          Map.has_key?(task, key),
          not shape_matches?(key, task, exemplar),
          do: {:task_shape, uid, key}
    else
      # an unknown status is the wire guard's problem, not a shape problem
      []
    end
  end

  defp task_shape(_task, _uid), do: []

  defp shape_matches?(key, task, _exemplar) when key in @stamp_keys,
    do: Recordings.value_type(task[key]) in [:string, :null]

  defp shape_matches?("indexUid", %{"type" => "indexSwap"} = task, _exemplar),
    do: is_nil(task["indexUid"])

  defp shape_matches?(key, task, exemplar),
    do: Recordings.value_type(task[key]) == Recordings.value_type(exemplar[key])

  defp details_keys(%{"type" => type, "details" => details}, uid)
       when is_binary(type) and is_map(details) do
    case Recordings.details_keys(type) do
      expected when is_list(expected) ->
        if Enum.sort(Map.keys(details)) == expected, do: [], else: [{:details_keys, uid}]

      _any_or_unrecorded ->
        []
    end
  end

  defp details_keys(_task, _uid), do: []

  # A task without an error has nothing to check here; an error must be a table entry's text.
  defp task_failure(%{"error" => error, "type" => type}, uid) when is_map(error) do
    if Failures.meili_error?(error, type), do: [], else: [{:unknown_failure, uid}]
  end

  defp task_failure(_task, _uid), do: []

  defp task_index(%{"type" => "indexSwap", "indexUid" => nil}, _uid, _indexes), do: []

  defp task_index(%{"indexUid" => value}, uid, indexes) do
    if value in indexes, do: [], else: [{:index_uid, uid, value}]
  end

  defp task_times(%Scenario{now: now}, task, uid) do
    stamps = Enum.map(["enqueuedAt", "startedAt", "finishedAt"], &parse_stamp(task[&1]))

    cond do
      Enum.any?(stamps, &(&1 == :error)) ->
        [{:unparsable_time, uid}]

      ordered?(Enum.reject(stamps, &is_nil/1) ++ [now]) ->
        []

      true ->
        [{:time_order, uid}]
    end
  end

  # A stamp is a Meilisearch-style ISO 8601 string, or nil for "not yet".
  defp parse_stamp(nil), do: nil

  defp parse_stamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> :error
    end
  end

  defp parse_stamp(_value), do: :error

  defp ordered?([first, second | rest]) do
    DateTime.compare(first, second) != :gt and ordered?([second | rest])
  end

  defp ordered?(_short), do: true

  # Meilisearch spells the cancelled status with one l; "cancelled" is Oban's spelling.
  defp meili_spelling(%{"status" => "cancelled"}, uid), do: [{:meili_cancelled_spelling, uid}]
  defp meili_spelling(_task, _uid), do: []

  # -- jobs ----------------------------------------------------------------------------------

  defp job_problems(scenario, job, indexes) do
    List.flatten([
      job_index(job, indexes),
      job_schema(job, scenario),
      job_failures(job),
      job_attempts(scenario, job),
      job_times(scenario, job)
    ])
    |> tag(scenario)
  end

  defp job_failures(%{id: id, errors: errors}) when is_list(errors) do
    if Enum.all?(errors, &Failures.oban_error?/1), do: [], else: [{:unknown_failure, id}]
  end

  defp job_failures(_job), do: []

  defp job_index(%{id: id, args: args}, indexes) do
    if args["index"] in indexes, do: [], else: [{:job_index, id}]
  end

  # A job belongs to the schema its args name (that is how the inspector scopes it), so the name
  # must be one the scenario allowlists.
  defp job_schema(%{id: id, args: args}, %Scenario{allowlist: allowlist}) do
    if args["schema"] in Enum.map(allowlist, &Atom.to_string/1), do: [], else: [{:job_schema, id}]
  end

  # Oban 2.24 executor: a failure below max_attempts is `retryable` (scheduled for later); at
  # max_attempts it is `discarded` (the executor's `exhausted`).
  defp job_attempts(%Scenario{now: now}, %{state: "retryable"} = job) do
    if job.attempt < job.max_attempts and future?(job.scheduled_at, now),
      do: [],
      else: [{:retryable_attempts, job.id}]
  end

  defp job_attempts(_scenario, %{state: "discarded"} = job) do
    if job.attempt == job.max_attempts, do: [], else: [{:discarded_attempts, job.id}]
  end

  defp job_attempts(_scenario, _job), do: []

  defp job_times(%Scenario{now: now}, job) do
    if Enum.any?([job.attempted_at, job.completed_at], &after_now?(&1, now)),
      do: [{:job_in_future, job.id}],
      else: []
  end

  defp future?(%DateTime{} = stamp, now), do: DateTime.compare(stamp, now) == :gt
  defp future?(_stamp, _now), do: false

  defp after_now?(%DateTime{} = stamp, now), do: DateTime.compare(stamp, now) == :gt
  defp after_now?(_stamp, _now), do: false

  # -- round trip through the real Scrypath code -----------------------------------------------

  # A call with no expectation is not made, and an empty allowlist makes no per-schema call at all.
  # `sync_status/2` and `failed_sync_work/2` split the operator-only keys off themselves, so they
  # take the full options; `index_contract_drift/2` does not, so it takes the runtime half.
  defp round_trip_problems(%Scenario{allowlist: allowlist, expect: expect} = scenario) do
    full_opts = scenario.scrypath_opts
    runtime_opts = Scenario.runtime_opts(full_opts)

    for schema <- allowlist,
        {call, fun} <- [
          sync_status: fn -> Scrypath.sync_status(schema, full_opts) end,
          failed_sync_work: fn -> Scrypath.failed_sync_work(schema, full_opts) end,
          index_contract_drift: fn -> Scrypath.index_contract_drift(schema, runtime_opts) end
        ],
        expected = Map.get(expect, call),
        expected != nil,
        got = outcome(fun.()),
        not matches?(expected, got) do
      {scenario.id, {:unexpected_outcome, call, got}}
    end
  end

  defp outcome({:ok, _value}), do: :ok
  defp outcome({:error, reason}), do: {:error, reason}

  defp matches?(:ok, :ok), do: true
  defp matches?({:error, tag}, {:error, tag}), do: true

  defp matches?({:error, tag}, {:error, reason}) when is_tuple(reason),
    do: elem(reason, 0) == tag

  defp matches?(_expected, _got), do: false

  defp tag(problems, %Scenario{id: id}), do: Enum.map(problems, &{id, &1})
end
