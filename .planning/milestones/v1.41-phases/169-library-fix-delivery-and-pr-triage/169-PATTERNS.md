# Phase 169: Library Fix Delivery and PR Triage - Pattern Map

**Mapped:** 2026-09-29
**Files classified:** 24 selected or implied paths, plus conditional dependency/workflow surfaces
**Analogs found:** 24 / 24 (existing implementation or document-role match)

This is an extraction/delivery map. Most selected implementation already exists in the local historical tree; its presence does not establish delivery on public main. Reconstruct the selected changes on refreshed public main. Preserve Phase 168 dependency locks, package graph checks, audit coverage, and readiness corrections. Paths and line numbers below refer to the inspected local tree; re-resolve them on the candidate. All named existing analogs were confirmed by `git ls-files` in this repository. No installed/runtime mirror is an analog.

## File Classification

`E/` below expands to `examples/phoenix_meilisearch/`; `P/` expands to `.planning/phases/169-library-fix-delivery-and-pr-triage/`. These abbreviations do not designate new directories. Documentation uses role `config` and flow `file-I/O` to fit the planner's role vocabulary.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scrypath/search/single.ex` | service | request-response | Existing implementation; `lib/scrypath/search/facet_values.ex:33-43` | exact |
| `lib/scrypath/search/many.ex` | service | request-response | Existing implementation; `lib/scrypath/search/facet_values.ex:33-43` | exact |
| `lib/scrypath/search/facet_values.ex` | service | request-response | Same file, lines 10-43 | exact |
| `lib/scrypath/meilisearch/client.ex` | service | request-response | Same file, lines 104-136 | exact |
| `lib/scrypath/meilisearch/query.ex` | utility | transform | Existing renderer; client delegation at `lib/scrypath/meilisearch/client.ex:114-122` | exact |
| `test/scrypath/tenant_scope_contract_test.exs` | test | request-response | Same file, recording backend and public-entry assertions | exact |
| `test/scrypath/facet_values_contract_test.exs` | test | request-response | Existing module; `test/scrypath/search_within_facet_test.exs:43-70` | exact |
| `test/scrypath/search_within_facet_test.exs` | test | request-response | Same file, lines 43-70 | exact |
| `E/lib/scrypath_demo/blog.ex` | service | request-response | Same file, lines 35-147 | exact |
| `E/lib/scrypath_demo/blog/post.ex` | model | CRUD | Same file, lines 3-34 | exact |
| `E/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs` | migration | CRUD | Same file, lines 4-23 | exact |
| `E/test/scrypath_demo/blog_tenant_search_test.exs` | test | request-response | Existing recorder fixture; root tenant recorder | exact |
| `E/test/smoke/meilisearch_tenant_stack_test.exs` | test | request-response | Same file, lines 90-142 | exact |
| `E/test/support/meilisearch_test_index.ex` | utility | request-response | Same file, lines 7-19 | exact |
| `E/test/smoke/meilisearch_stack_test.exs` | test | request-response | Existing test plus shared index helper | exact |
| `E/test/smoke/meilisearch_oban_stack_test.exs` | test | event-driven | Existing test plus shared index helper | exact |
| `E/test/smoke/meilisearch_related_inline_stack_test.exs` | test | request-response | Existing test plus shared index helper | exact |
| `E/test/smoke/meilisearch_related_oban_stack_test.exs` | test | event-driven | Existing test plus shared index helper | exact |
| `test/scrypath/live_operator_verification_test.exs` | test | batch | Same file, bounded repair scenario, lines 184-370 | exact |
| `E/README.md` | config | file-I/O | Existing README and `CONTRIBUTING.md` capability runbook | role-match |
| `P/169-DELIVERY.md` (proposed canonical phase receipt) | config | file-I/O | `.planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md` | role-match |
| `.planning/STATE.md` | config | file-I/O | Existing current-position/evidence/handoff sections | exact |
| `.planning/ROADMAP.md` | config | file-I/O | Existing Phase 169/170 boundary | exact |
| `.planning/REQUIREMENTS.md` | config | file-I/O | Existing DELIV-02/TRIAGE-01 checklist and traceability | exact |

The receipt filename is a planning suggestion, not an instruction to add a competing readiness report. Keep inventory, frozen-cohort dispositions, and delivery identities together in current phase authority; summaries/state should link to it. Update `.planning/PROJECT.md` only if intentionally changing product scope or shipped claims. Historical assessments and receipts remain read-only references. Research navigation paths are not automatically changed files.

Conditional bot surfaces are `mix.exs`, `mix.lock`, consumer manifests/locks actually touched by a selected PR, and `.github/workflows/ci.yml`, `.github/workflows/workflow-security.yml`, or `.github/workflows/website.yml` as shown by refreshed PR diffs. Classify these as **config / file-I/O**, with their existing tracked file as the exact structural analog. They are not preselected edits: D-01 value analysis comes first, and lock graphs are resolved by Mix rather than copied from the historical checkout. No new generic triage framework or required job is implied.

## Pattern Assignments

### 1. Search modules and adapter (`single.ex`, `many.ex`, `facet_values.ex`, `client.ex`, `query.ex`)

**Primary analog:** `lib/scrypath/search/facet_values.ex`. Explicit aliases and result tuples are the local service convention (lines 4-9):

```elixir
alias Scrypath.Config
alias Scrypath.FacetSearchResult
alias Scrypath.Telemetry

@spec run(module(), String.t(), String.t(), keyword(), keyword()) ::
        {:ok, FacetSearchResult.t()} | {:error, term()}
```

Copy the option partition in lines 33-43 into the corresponding existing option lists, preserving each module's other behavior:

```elixir
defp runtime_opts(opts) do
  Keyword.drop(opts, [
    :filter,
    :sort,
    :page,
    :facets,
    :facet_filter,
    :global_schemas,
    :per_query,
    :tenant_scope
  ])
end
```

`:tenant_scope` has already contributed to the validated predicate. Remove it only from strict runtime configuration. Do not extend the runtime schema or remove the composed predicate. Preserve Many's existing preflight/error contract.

**Adapter imports:** `lib/scrypath/meilisearch/client.ex:4-8` aliases Config, Document, `Scrypath.Meilisearch.Query` as `MeilisearchQuery`, `Scrypath.Query` as `CommonQuery`, and Telemetry. Copy the existing facet branch at lines 114-122:

```elixir
{:filter, filters} when is_list(filters) and filters != [] ->
  rendered_filter =
    if Keyword.keyword?(filters) do
      MeilisearchQuery.render_common_filter(filters)
    else
      filters
    end

  {"filter", rendered_filter}
```

Carry the existing internal `render_common_filter/1` seam in `query.ex` with this caller. Retain empty and pre-rendered list behavior and the established Jason literal grammar. No new serializer, public API, or dependency is needed.

**Errors and instrumentation:** `client.ex:150-162` wraps Req in a telemetry span. Lines 181-191 preserve distinct successful map, HTTP error, and transport error tuples:

```elixir
defp normalize_response({:ok, %Req.Response{status: status, body: body}})
     when status >= 200 and status < 300 and is_map(body) do
  {:ok, body}
end

defp normalize_response({:ok, %Req.Response{status: status, body: body}}) do
  {:error, {:http_error, status, body}}
end

defp normalize_response({:error, exception}) do
  {:error, {:transport_error, exception}}
end
```

### 2. Public regression modules

**Assignments:** retain the full existing tenant and facet contract modules; retain the scoped-search regression in `search_within_facet_test.exs`. Their exact existing implementations are stronger analogs than introducing a framework.

The recorder asserts the public result and actual dispatched query independently. `test/scrypath/tenant_scope_contract_test.exs:87-89`:

```elixir
assert MapSet.new(filter) == MapSet.new(tenant_id: 123, status: "published")
assert_receive {:tenant_search, TenantPost, %Query{text: "ecto", filter: recorded_filter}}
assert MapSet.new(recorded_filter) == MapSet.new(tenant_id: 123, status: "published")
```

Preserve single/many/facet happy paths, omitted/empty filters, collision rejection, undeclared tenant fields, and Many's preflight-before-any-dispatch assertions. Error tests must refute recorder messages, not just check an error result.

**Req.Test structure:** `test/scrypath/search_within_facet_test.exs:44-55`:

```elixir
stub = Module.concat(__MODULE__, ScopedFacetReqStub)

Req.Test.stub(stub, fn conn ->
  send(self(), {:scoped_search_body, conn.body_params})

  Req.Test.json(conn, %{
    "hits" => [],
    "page" => 1,
    "hitsPerPage" => 20,
    "totalHits" => 0
  })
end)
```

Request options use `req_options: [plug: {Req.Test, stub}]`; assertions in lines 66-70 inspect `body["filter"]` and `body["facetFilters"]` using literal expected grammar. The facet-values module additionally preserves escaping, no-fallback/error, and composed tenant filter coverage. Expected strings must not be derived with the production renderer. The scoped-search module is `async: false` because its telemetry handlers are global (lines 2-4).

### 3. Phoenix host fixture, projection, migration, and host tests

**Primary analog:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex`. Imports/aliases at lines 19-23 use `import Ecto.Query` and explicit Repo/Author/Post aliases. Its search entrypoint starts with membership authorization, parameter validation, then runtime-option validation (lines 35-38):

```elixir
def search_posts(principal, selected_tenant_id, params, runtime_opts) do
  with {:ok, tenant_id} <- authorized_tenant(principal, selected_tenant_id),
       {:ok, normalized} <- validate_params(params, @search_param_keys),
       true <- valid_runtime_opts?(runtime_opts) do
```

Copy the complete existing functions together, including their private helpers. Membership comes from persisted `host_actors` joined to `host_memberships` (lines 86-106), never a client tenant claim. The allowlist at lines 108-121 rejects unknown keys/non-string values. Errors propagate as `{:error, reason}`; invalid input returns `{:error, :invalid_search_input}`.

Hydration at lines 132-137 explicitly scopes both tenant and returned IDs:

```elixir
Repo.all(
  from(post in Post,
    where: post.tenant_id == ^tenant_id and post.id in ^hit_ids
  )
)
|> Map.new(&{to_string(&1.id), &1})
```

**Model assignment:** retain `blog/post.ex:5-10` projection fields, filterable tenant/category, category faceting, and `tenant_field: :tenant_id`; retain schema fields and changeset casts in lines 12-34. **Migration assignment:** copy the existing additive migration, whose lines 18-23 preserve the unique membership pair and add post fields:

```elixir
create(unique_index(:host_memberships, [:actor_id, :tenant_id]))

alter table(:posts) do
  add(:tenant_id, :integer)
  add(:category, :string)
end
```

**Host test assignment:** carry `blog_tenant_search_test.exs` with its persisted membership fixture and recorder; preserve raw hits even when host hydration filters foreign records. Carry the live `meilisearch_tenant_stack_test.exs` as the same selected scenario in both path/package modes. Its lines 99-107 separate raw response and hydration proof:

```elixir
assert raw_hit_ids(result_a) == [to_string(post_a.id)]
assert result_a.raw["totalHits"] == 1
post_a_id = post_a.id
assert [%Post{id: ^post_a_id, tenant_id: ^tenant_a}] = records_a
assert result_a.records == []
assert distribution(result_a) == [{"phone-a", 1}]
refute Jason.encode!(result_a.raw) =~ "phone-b-forbidden"
refute Jason.encode!(result_a.raw) =~ "phase166-b-unique-marker"
refute Jason.encode!(result_a.raw) =~ "phone-draft"
```

Keep tenant B's positive control (lines 90-94), both facet results (109-118), and the `SCRYPATH_PHASE166_HOST` receipt (124-142). These are named synthetic host scenarios, not new authentication or production-isolation claims.

### 4. Shared index setup and bounded repair

**Assignments:** keep `test/support/meilisearch_test_index.ex` and all four existing smoke callsite adjustments together. Exact helper pattern, lines 10-16:

```elixir
{:ok, response} = Client.create_index(index_uid, "id", config)
task_uid = Map.fetch!(response, "taskUid")

{:ok, task} = Tasks.wait_for_task(%{"uid" => task_uid, "status" => "enqueued"}, config)

unless task.state == :succeeded and task.reference.index_uid == index_uid do
  raise "Meilisearch test index creation task did not succeed for #{index_uid}"
end
```

Explicit primary key creation is needed when projections also contain tenant/author IDs. Preserve existing inline/Oban/related-data scenario bodies, cleanup, and service gating.

**Root repair assignment:** select the existing `@tag :bounded_repair` scenario and its helpers from `test/scrypath/live_operator_verification_test.exs`. The existing selection at lines 303-304 is an explicit ID predicate:

```elixir
selected_ids = [target.id]
selected_query = from(post in QueryablePost, where: post.id in ^selected_ids)
```

Carry source/control rows, deliberately missing raw document, no-action report, exact task/index assertions, and re-querying with the same raw query. Final raw checks at lines 329-339:

```elixir
repaired_hits = search_raw_hits!(token, search_options)

assert MapSet.new(Enum.map(repaired_hits, &raw_id!/1)) ==
         MapSet.new([target.id, visible_control.id])

assert raw_projection(repaired_hits, target.id) == expected_projection(target)

assert raw_projection(repaired_hits, visible_control.id) ==
         expected_projection(visible_control)

refute Enum.any?(repaired_hits, &(raw_id!(&1) == source_only.id))
```

`batch_size: 1` alone is not the repair boundary. Retain the selected query and distinct repeat task assertions (341-369).

### 5. Canonical delivery records, runbook, and triage

**Receipt analog:** `.planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:1-10` has distinct `base_sha`, `candidate_sha`, `pr`, `merge_ref_sha`, `main_sha`, and `main_run_id` fields. Its lines 51-57 pair evidence with source/event and immutable artifact digests; lines 87-93 separately identify locally built package/graph/artifact provenance. Copy that shape with fresh values only. Do not copy historical success statuses or IDs into a new receipt.

The same canonical Phase 169 receipt should contain two finite tables:

```markdown
| Owned path/group | Local/public source | Ownership | Selection/disposition | Delivery source | Evidence or revisit trigger |
|---|---|---|---|---|---|

| Frozen PR | Observed at | Head/base | Changed surface | Concrete value/evidence | Disposition/reason | Next action/revisit trigger |
|---|---|---|---|---|---|---|---|
```

These headers are proposed extensions to the existing receipt pattern. Inventory committed-tree differences in both directions and dirty-state ownership separately. Include public-only work as retained; a deleted public-only path must not become an extracted change. Preserve unrelated dirty files. Frozen rows are exactly #65, #68, #69, #70, #71, #72, #73, #74, #75, #76. Refresh actual metadata/check identities before action; green checks alone do not meet the value gate. #83 and final release/readiness remain Phase 170 work.

**README assignment:** merge only the selected host-proof explanation into the public README. Preserve newer Phase 168 package graph text. Route to existing `CONTRIBUTING.md` capability commands: `mix verify.phoenix_example`, `mix verify.phoenix_example --package`, and `mix verify.backend`; do not add another canonical runbook.

**State/roadmap/requirements assignments:** update current status and source-linked pointers after evidence exists. Preserve dated historical outcomes. DELIV-02 requires reviewed public-main delivery and verified integration, not a prepared PR. State the normal patch rationale; do not claim publication. Freeze tracked inputs before final exact-SHA attestation and retain terminal success outside the tested tree per CONTRIBUTING.

## Shared Patterns

- **Authentication/authorization:** host-owned persisted membership and allowlisted input (`blog.ex:86-121`); library tenant filtering is not authentication.
- **Validation:** preserve validated search predicates while dropping search-only configuration keys. Many keeps all-entry preflight and its existing error tuple semantics.
- **Errors/telemetry:** explicit `{:ok, value}` / `{:error, reason}` tuples and existing telemetry spans; no serializer fallback hiding request errors.
- **Tests:** recorder messages for dispatch boundaries; Req.Test body assertions for encoding; live service proof for backend acceptance; raw results and hydration asserted independently.
- **Async operations:** exact task UID plus index and terminal success; bounded repair by explicit Ecto predicate.
- **Provenance:** candidate, PR merge ref, integrated main, local package, and published artifact remain distinct. Relevant-source equality supports limited evidence reuse without rewriting run identity.
- **Verification:** retain current required/advisory split. Reuse focused regressions and named path/package/repair scenarios; do not invent a new required lane. This mapping ran no tests, services, or hosted workflows.

## No Analog Found

No selected runtime or fixture file requires a new architecture. The frozen-cohort value decisions and owned-change dispositions have no reusable factual answers: execution must produce those from current evidence. Their record structure reuses the prior delivery receipt. Conditional bot diffs must be refreshed before assigning any additional affected test/config files.

## Metadata

**Analog search scope:** tracked root library/search/Meilisearch source, root contract/operator tests, Phoenix example context/schema/migration/tests, current phase authority, Phase 168 delivery receipt, contributor policy.
**Search stopping rule:** five pattern families cover the selected work; no broader architectural analog hunt was needed. Exact existing targets were inspected where needed to bind related fixture files.
**Coverage:** 22 exact assignments; 2 document role matches; 0 selected files without an analog. Conditional bot paths are excluded from the fixed count.
**Pattern extraction date:** 2026-09-29.
**Tool adaptation:** Read/Write-named tools are not exposed in this runtime. Read-only shell commands provided source content; the structured `apply_patch` editor wrote only this PATTERNS.md. No source or repository/GitHub state was changed.
