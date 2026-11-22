defmodule ScrypathFixtures.Scenario do
  @moduledoc """
  One named fixture state for one fictional adopter. The data is fictional and for development and
  tests only.

  A scenario is plain data: it never touches application env. `scrypath_ops` tests put it into app
  env through their own helper, and a later preview can reuse `scrypath_opts` unchanged.

    * `:id` and `:adopter` name the scenario; `:label` is display text and must contain
      "(fictional)".
    * `:kind` is `:ordinary` or `:stress`.
    * `:now` is the instant every stamp is measured from.
    * `:allowlist` is the list of schema modules the operator UI would show.
    * `:scrypath_opts` uses only the keys `ScrypathOps.Schemas` forwards to Scrypath.
    * `:expect` maps a call name (`:sync_status`, `:failed_sync_work`, `:index_contract_drift`,
      `:posture`) to `:ok` or `{:error, tag}`.

  This module also owns the one list of operator-only option keys. `Scrypath.Operator` splits those
  keys off in `sync_status/2` and `failed_sync_work/2`, but `index_contract_drift/2` passes its
  options straight to `Scrypath.Config.resolve!/1`, which raises `ArgumentError` for them. Anything
  that reaches `resolve!/1` or `index_contract_drift/2` must therefore pass `runtime_opts/1`.
  """

  @enforce_keys [:id, :adopter, :label, :kind, :now, :allowlist, :scrypath_opts, :expect]
  defstruct [:id, :adopter, :label, :kind, :now, :allowlist, :scrypath_opts, :expect]

  @type kind :: :ordinary | :stress
  @type expectation :: :ok | {:error, term()}

  @type t :: %__MODULE__{
          id: atom(),
          adopter: atom(),
          label: String.t(),
          kind: kind(),
          now: DateTime.t(),
          allowlist: [module()],
          scrypath_opts: keyword(),
          expect: %{optional(atom()) => expectation()}
        }

  # Copied from `@operator_only_opts` in lib/scrypath/operator.ex. A test pins the two lists
  # together with an AST read, so this is the only place the copy lives.
  @operator_keys ~w(
    meilisearch_tasks task_history_limit oban_jobs oban_inspector target_index
    reason_class_counts include_index_contract_drift
  )a

  @doc "The option keys only the operator functions understand."
  @spec operator_keys() :: [atom()]
  def operator_keys, do: @operator_keys

  @doc "Splits `opts` into `{runtime_opts, operator_opts}`."
  @spec split_opts(keyword()) :: {keyword(), keyword()}
  def split_opts(opts) when is_list(opts) do
    {operator_opts, runtime_opts} = Keyword.split(opts, @operator_keys)
    {runtime_opts, operator_opts}
  end

  @doc "The half of `opts` that `Scrypath.Config.resolve!/1` accepts."
  @spec runtime_opts(keyword()) :: keyword()
  def runtime_opts(opts) when is_list(opts) do
    {runtime_opts, _operator_opts} = split_opts(opts)
    runtime_opts
  end
end
