# Phase 166: Host Tenant and Repair Evidence - Pattern Map

**Mapped:** 2026-09-26
**Files analyzed:** 8 proposed implementation files, plus evidence and existing execution surfaces
**Analogs found:** 8 / 8 at file-role level; membership authorization itself has no existing consumer analog

## File Classification

Names marked proposed are implementation discretion, not locked contracts. Paths below are relative to repository root. `consumer` in prose means `examples/phoenix_meilisearch`.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` (modify) | service | request-response / CRUD | Same file | exact scaffolding; new policy |
| `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` (modify) | model | transform / CRUD | Same file | exact |
| `examples/phoenix_meilisearch/lib/scrypath_demo/accounts/actor.ex` (proposed new) | model | CRUD | `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` | role-match |
| `examples/phoenix_meilisearch/lib/scrypath_demo/accounts/membership.ex` (proposed new) | model | CRUD | `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` | role-match |
| `examples/phoenix_meilisearch/priv/repo/migrations/<timestamp>_add_host_memberships_and_post_tenants.exs` (proposed new) | migration | CRUD | `examples/phoenix_meilisearch/priv/repo/migrations/20250420000000_add_authors_and_post_author_fields.exs` | exact |
| `examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs` (proposed new) | test | request-response / CRUD | `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` | role-match |
| `examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs` (proposed new; may extend existing stack file instead) | test | request-response / event-driven | `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` | exact |
| `test/scrypath/live_operator_verification_test.exs` (modify) | test | batch / event-driven / request-response | Same file | exact |

Five primary analogs cover these eight files. Actor and membership can use a scalar tenant identifier; a separate tenant schema is not a phase requirement. Keep persisted membership lookup in the host context. Additional fixture/support files are optional, not necessary defaults.

Referenced existing surfaces `test/support/meilisearch_integration.ex`, `examples/phoenix_meilisearch/test/support/data_case.ex`, `test/scrypath/backfill_test.exs`, `test/scrypath/facet_values_contract_test.exs`, `lib/mix/tasks/verify/phoenix_example/package.ex`, and `.github/workflows/ci.yml` are reuse dependencies, not automatically edit targets. No root library API edit is indicated by the research.

## Pattern Assignments

### `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex`

**Analog:** same tracked file, service, request-response / CRUD.

**Imports** (lines 19–23):

```elixir
import Ecto.Query

alias ScrypathDemo.Repo
alias ScrypathDemo.Blog.Author
alias ScrypathDemo.Blog.Post
```

**Explicit context orchestration and tuple return** (lines 44–48):

```elixir
# explicit fan-out the context invokes (D-05) — not a callback.
{:ok, result} =
  Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

{:ok, result, updated}
```

**Query composition** (lines 66–67):

```elixir
defp reload_posts(author_ids),
  do: Repo.all(from(p in Post, where: p.author_id in ^author_ids))
```

Adapt the explicit query to `post.tenant_id == ^authorized_tenant_id` AND `post.id in ^returned_ids`. Resolve persisted membership first; construct fresh options from allowed ordinary inputs and trusted service configuration. Reject caller scope/filter overrides before invoking search or facet search. The existing function pattern-matches successful mutations; do not copy that as authorization error handling. New expected rejection outcomes need explicit error tuples and tests. There is no existing host auth guard to copy. Keep synthetic authentication outside the new function's claim.

### `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex`

**Analog:** same tracked file, model, transform / CRUD.

**Declaration and schema** (lines 3–16):

```elixir
use Ecto.Schema

use Scrypath,
  fields: [:title, :body, :author_name],
  filterable: [:status],
  sortable: [:inserted_at]

schema "posts" do
  field(:title, :string)
  field(:body, :string)
  field(:status, :string)
  field(:author_name, :string)
  belongs_to(:author, ScrypathDemo.Blog.Author)
  timestamps()
```

**Validation** (lines 19–23):

```elixir
def changeset(post, attrs) do
  post
  |> Ecto.Changeset.cast(attrs, [:title, :body, :status, :author_id, :author_name])
  |> Ecto.Changeset.validate_required([:title, :body, :status])
end
```

Extend projection/settings with the selected tenant declaration and string facet. Preserve existing fixture compatibility or deliberately update affected fixture inserts. Tenant declaration is library filtering configuration; it does not establish membership authorization.

### `examples/phoenix_meilisearch/lib/scrypath_demo/accounts/actor.ex`

**Analog:** Post schema above, lines 3, 10–16 and 19–23. Copy `use Ecto.Schema`, ordinary fields, timestamps, and narrow cast/required validation. Omit `use Scrypath`: principals are persisted host fixtures, not indexed documents. No authentication/session machinery is required. Persistence errors remain Ecto changeset errors.

### `examples/phoenix_meilisearch/lib/scrypath_demo/accounts/membership.ex`

**Analog:** Post schema above, especially `belongs_to` at line 15 and changeset at lines 19–23. Define persisted actor linkage and tenant identifier, using the migration's corresponding database constraint. Membership resolution uses the trusted principal's identity, never caller-provided scope. Existing schema conventions provide structure; actor-to-tenant authorization rules are new work.

### `examples/phoenix_meilisearch/priv/repo/migrations/<timestamp>_add_host_memberships_and_post_tenants.exs`

**Analog:** `examples/phoenix_meilisearch/priv/repo/migrations/20250420000000_add_authors_and_post_author_fields.exs`, lines 1–15:

```elixir
defmodule ScrypathDemo.Repo.Migrations.AddAuthorsAndPostAuthorFields do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add(:name, :string)

      timestamps(type: :utc_datetime)
    end

    alter table(:posts) do
      add(:author_id, references(:authors))
      add(:author_name, :string)
    end
  end
```

Copy additive `change/0`, related-table creation, references and post alteration. Choose a fresh migration timestamp. Add the membership uniqueness/foreign-key constraints required by the named policy; avoid destructive rewrites of prior migrations. Ensure existing smoke fixtures can still insert records.

### `examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs`

**Analog:** `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs`, lines 1–8 and 35–38:

```elixir
defmodule ScrypathDemo.Smoke.MeilisearchStackTest do
  @moduledoc false
  use ScrypathDemo.DataCase, async: false

  @moduletag :integration

  alias ScrypathDemo.Blog.Post
  alias ScrypathDemo.Repo
```

```elixir
{:ok, post} =
  %Post{}
  |> Post.changeset(%{title: "Smoke title", body: "Body", status: "published"})
  |> Repo.insert()
```

Reuse DataCase and persisted fixture insertion. Tag according to the consumer's database prerequisite policy; do not accidentally require database startup in a service-free path. Supply a recording backend/HTTP seam to assert zero dispatch on missing membership, unowned selection, and scope/filter override attempts. A backend returning empty results does not prove zero dispatch. A positive authorized call must establish that the observation seam works. This policy assertion has no complete existing consumer analog.

### `examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs`

**Analog:** `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs`.

**Service configuration and unique index lifecycle** (lines 17–28):

```elixir
prefix = "phx_demo_#{System.unique_integer([:positive])}"

config = [
  index_prefix: prefix,
  meilisearch_url: url
]

live_index = Scrypath.Meilisearch.index_name(Post, config)

on_exit(fn -> delete_index(url, live_index) end)

%{index_prefix: prefix, meilisearch_url: url, live_index: live_index}
```

**Mutation completion** (lines 40–47):

```elixir
assert {:ok, %{mode: :inline, status: :completed}} =
         Scrypath.sync_record(Post, post,
           backend: Scrypath.Meilisearch,
           sync_mode: :inline,
           index_prefix: prefix,
           meilisearch_url: url,
           inline_poll_interval: 50
         )
```

**Error handling:** setup raises when service URL is absent (lines 11–15); cleanup is best-effort `Req.request` plus rescue (lines 61–69). Keep assertion/setup failures loud; cleanup lenience must not extend to acceptance assertions.

Add A published/A draft/B published fixtures and two valid principals. Assert exact permitted raw IDs, host-hydrated IDs, counts and requested facet distribution; B must retrieve its distinct positive-control marker. Add the public facet-value invocation shown under Shared Patterns with tenant plus ordinary keyword status filter and meaningful tenant-specific values/counts. Wait for settings and indexing completion before the search oracle. The same named test must execute in both existing dependency modes.

### `test/scrypath/live_operator_verification_test.exs`

**Analog:** same tracked file.

**Imports and repository lifecycle** (lines 1–16):

```elixir
defmodule Scrypath.LiveOperatorVerificationTest do
  use ExUnit.Case, async: false

  alias Scrypath.TestSupport.IntegrationRepo
  alias Scrypath.TestSupport.MeilisearchIntegration

  @moduletag :integration

  setup_all do
    database = MeilisearchIntegration.setup_repo!()

    on_exit(fn ->
      MeilisearchIntegration.cleanup_repo!(database)
    end)

    :ok
```

**No-action report invocation** (lines 135–141):

```elixir
case Scrypath.reconcile_sync(QueryablePost,
       backend: Scrypath.Meilisearch,
       index_prefix: prefix,
       sync_mode: :manual,
       target_index: target_index,
       meilisearch_url: MeilisearchIntegration.meilisearch_url!()
     ) do
```

Reuse reset/unique-prefix/cleanup at lines 19–34. Add `import Ecto.Query` for the explicit selected-ID predicate. Establish known source/index mismatch with target A missing, out-of-scope B absent and already-visible C present. Observe tasks/write activity around the no-action report, together with unchanged raw results; counts alone cannot prove no write. Call backfill using `where: post.id in ^selected_ids`. Inspect every returned batch task, poll that UID to terminal success and verify its expected index. Repeat the original public Scrypath query and assert exact repaired raw ID/projected value and controls. Existing `last_succeeded` checks (lines 69–90) and search-count checks are scaffolding, not sufficient repair oracles. Do not replace this proof with reindexing.

## Shared Patterns

### SQL Sandbox ownership

**Source:** `examples/phoenix_meilisearch/test/support/data_case.ex`, lines 38–40. **Apply to:** both host test files.

```elixir
def setup_sandbox(tags) do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(ScrypathDemo.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
```

### Public tenant-plus-common-filter facet contract

**Source:** `test/scrypath/facet_values_contract_test.exs`, lines 229–235. **Apply to:** live host scenario in both consumer modes.

```elixir
assert {:ok, %Scrypath.FacetSearchResult{facet_query: "pho"}} =
         Scrypath.search_facet_values(
           FacetPost,
           "category",
           "pho",
           request_options(stub) ++ [tenant_scope: 123, filter: [status: "published"]]
         )
```

Adapt schema/options to the host's authorized context and real backend. Preserve the keyword filter input shape. Mock evidence does not close the live/package acceptance criterion.

### Query-scoped backfill and task observation

**Source:** `test/scrypath/backfill_test.exs`, lines 162–170. **Apply to:** root repair scenario.

```elixir
scoped_query = from(post in QueryablePost, where: post.status == ^"published")

assert {:ok, %{documents: 2, batches: 1, index: "scrypath_queryable_post", mode: :manual}} =
         Scrypath.backfill(QueryablePost,
           backend: RecordingBackend,
           repo: BackfillRepo,
           query: scoped_query,
           batch_size: 10
         )
```

Use real IntegrationRepo/backend and selected IDs. Batch size is not total scope; query limit is stripped by backfill per RESEARCH.md. The same contract test's lines 26–27 show a direct message-based mutation observation:

```elixir
def upsert_documents(schema_module, documents, config) do
  send(self(), {:upsert_documents, schema_module, documents, config})
```

Use an equivalent observable seam where appropriate for no-dispatch unit assertions; live report no-write evidence still requires an observation tied to the actual report invocation.

### Bounded visibility polling

**Source:** `test/support/meilisearch_integration.ex`, lines 138–144. **Apply to:** root repair visibility checks.

```elixir
defp wait_until_retry!(fun, deadline, failure_message) do
  if System.monotonic_time(:millisecond) >= deadline do
    raise failure_message
  else
    Process.sleep(100)
    wait_until!(fun, deadline, failure_message)
  end
```

Call the existing public `wait_until!/3` (lines 122–135); do not create another unbounded poller. Use exact task polling from the existing task API identified in RESEARCH.md, then a same-query raw-result oracle.

### Existing execution surfaces

**Source:** `lib/mix/tasks/verify/phoenix_example/package.ex`, lines 4–5:

```elixir
@example "examples/phoenix_meilisearch"
@staged_files ["mix.exs", "mix.lock", "config", "lib", "priv", "test"]
```

The package task runs staged `mix test` with `SCRYPATH_EXAMPLE_INTEGRATION=1` (lines 112–117). New consumer source, migrations and tests are already staged. No new harness is necessary.

**Source:** `.github/workflows/ci.yml`, lines 152–155 and 176–178:

```yaml
phoenix-example:
  name: phoenix-example (advisory)
  runs-on: ubuntu-latest
  continue-on-error: true
```

```yaml
- run: mix deps.get
- run: mix verify.phoenix_example
- run: mix verify.phoenix_example --package
```

Retain existing PostgreSQL 16 / Meilisearch v1.15 service tuple and advisory topology. Record actual named scenario execution, exact SHA, run/job/attempt, dependency mode, service tuple, result, and relevant task/index IDs. No environment dumps or secrets. Run root repair through `mix verify.backend`; retain integration module isolation. Contributor commands are `mix verify.phoenix_example` and `mix verify.phoenix_example --package` for the consumer boundary.

## No Analog Found

| File / behavior | Role | Data Flow | Reason |
|---|---|---|---|
| New membership authorization inside `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` | service | request-response | Context structure exists, but persisted actor membership, override rejection and zero-dispatch policy are new. Use locked D-01–D-05. |
| New host rejection tests | test | request-response | Consumer has persistence and service test scaffolding, not this authorization contract. |
| Phase evidence record (planner-selected Markdown artifact) | documentation | transform | Exact-SHA host/package and repair receipts do not exist yet. Use RESEARCH.md validation fields; never synthesize a passing receipt. |

All eight proposed implementation files have structural analogs; the missing entries identify behavior that cannot be copied wholesale.

### Deletion receipt assessment

The evidence artifact must record receipt source `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`, final assessment SHA, relevant-path comparison and bounded disposition. RESEARCH.md's reusable disposition covers only its inspected SHA. Reassess deletion/search runtime, host/configuration/fixture/workflow dependencies at the final source. Relevant invalidation requires targeted fresh evidence or UNKNOWN. Do not add package deletion work by default. This is evidence maintenance, not a reason to edit deletion implementation.

## Metadata

**Analog search scope:** Phoenix consumer context/schema/migrations/tests, root operator/backfill/facet tests, shared integration support, package task and existing workflow.
**Primary analogs:** 5; supporting source files inspected: 6.
**Tracked-source gate:** all 11 source paths used as analogs or supporting excerpt sources were confirmed by nonempty `git ls-files -- <path>` output. No install/runtime mirrors are named.
**Project guidance:** AGENTS.md and contributor verification guidance consulted. No project skill files were listed under `.agents/skills` or `.codex/skills`. Local Ecto/Phoenix/Elixir brief context reinforces explicit host orchestration, thin schemas and query composition.
**Pattern extraction date:** 2026-09-26.
**Execution:** read-only source analysis; no implementation or tests run. Only this pattern map was written.
