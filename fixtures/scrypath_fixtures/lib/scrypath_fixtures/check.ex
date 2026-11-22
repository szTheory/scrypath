defmodule ScrypathFixtures.Check do
  @moduledoc """
  The no-database consistency check for every fixture scenario. The data is fictional and for
  development and tests only.

  `run/1` returns `{:ok, %{scenarios: n}}` or `{:error, problems}`. A problem is a
  `{scenario_id, tag_tuple}` pair whose tag tuple starts with one of `invariants/0`. A problem in
  the failure table itself has `:failures` where the scenario id would be. Callers can pass
  `:scenarios`, `:builders`, `:now` and `:failures` (a list of table entries), so a test can plant
  a broken scenario, a broken builder or a broken table without a special mode.

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

  Anything that reaches `Scrypath.Config.resolve!/1` or `Scrypath.index_contract_drift/2` is given
  `ScrypathFixtures.Scenario.runtime_opts/1`; `sync_status/2` and `failed_sync_work/2` take the
  full options because they split the operator keys off themselves.
  """

  alias Scrypath.Meilisearch.TaskPayload
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
    :stress_unmarked
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
    * `:failures` (default `ScrypathFixtures.Failures.all/0`).

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

    problems =
      table_problems(failures) ++
        registry_problems(scenarios) ++
        Enum.flat_map(scenarios, &check_scenario/1) ++
        Enum.flat_map(builders, &time_problems(&1, now))

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
