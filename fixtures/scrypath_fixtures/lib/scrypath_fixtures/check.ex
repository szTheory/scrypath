defmodule ScrypathFixtures.Check do
  @moduledoc """
  The no-database consistency check for every fixture scenario. The data is fictional and for
  development and tests only.

  `run/1` returns `{:ok, %{scenarios: n}}` or `{:error, problems}`. A problem is a
  `{scenario_id, tag_tuple}` pair whose tag tuple starts with one of `invariants/0`. A problem in
  the failure table itself has `:failures` where the scenario id would be. Callers can pass
  `:scenarios`, `:now` and `:failures` (a list of table entries), so a test can plant a broken
  scenario or a broken table without a special mode.

  The check never reads the operator UI and never touches a database. It does these kinds of work:

    * invariants on the raw data (key sets, index names, time order, Oban attempt rules), taken from
      Meilisearch's documented behaviour and Oban's executor;
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
    :job_in_future
  ]

  @type problem :: {atom(), tuple()}

  @doc """
  Every problem tag `run/1` can emit.

  The first element of each problem's tag tuple is one of these atoms. A new invariant adds its
  tag here in the same change that adds the check.
  """
  @spec invariants() :: [atom()]
  def invariants, do: @invariants

  @doc "The scenarios `run/1` checks by default."
  @spec scenarios(DateTime.t()) :: [Scenario.t()]
  def scenarios(%DateTime{} = now) do
    [ScrypathFixtures.Logistify.scenario(:deep_queue, now: now)]
  end

  @doc """
  Checks scenarios and returns `{:ok, %{scenarios: n}}` or `{:error, [problem]}`.

  Options: `:now` (default `ScrypathFixtures.preview_epoch/0`), `:scenarios` (default
  `scenarios/1` at `now`) and `:failures` (default `ScrypathFixtures.Failures.all/0`).
  """
  @spec run(keyword()) :: {:ok, %{scenarios: non_neg_integer()}} | {:error, [problem()]}
  def run(opts \\ []) do
    now = Keyword.get(opts, :now, ScrypathFixtures.preview_epoch())
    scenarios = Keyword.get_lazy(opts, :scenarios, fn -> scenarios(now) end)

    failures = Keyword.get_lazy(opts, :failures, &Failures.all/0)

    case table_problems(failures) ++ Enum.flat_map(scenarios, &check_scenario/1) do
      [] -> {:ok, %{scenarios: length(scenarios)}}
      problems -> {:error, problems}
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

  defp round_trip_problems(%Scenario{allowlist: allowlist, expect: expect} = scenario) do
    for schema <- allowlist,
        {call, fun} <- [
          sync_status: &Scrypath.sync_status/2,
          failed_sync_work: &Scrypath.failed_sync_work/2
        ],
        expected = Map.get(expect, call),
        expected != nil,
        got = outcome(fun.(schema, scenario.scrypath_opts)),
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
