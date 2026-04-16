# Architecture Patterns

**Domain:** Ecto-native search indexing and orchestration library
**Project:** Scrypath
**Researched:** 2026-04-16
**Overall confidence:** HIGH

## Executive Recommendation

Scrypath should treat the next milestone as a consolidation milestone before it becomes a breadth milestone. The current shape is already good: a narrow public `Scrypath` surface, an internal `Scrypath.Backend` seam, explicit `Scrypath.Meilisearch.*` escape hatches, and orchestration modules such as `Scrypath.Sync` and `Scrypath.Reindex`. The main architectural risk is not missing abstractions. It is letting release work, operator workflows, or backend-native power leak into the common path in ways that create public API regret.

For v1.2, the best move is to harden three layers without widening the top-level API much:

1. Extract a clearer internal operations seam for index lifecycle and task inspection so `Scrypath.Reindex` and future tooling stop depending directly on `Scrypath.Meilisearch.*` internals.
2. Add a first-class operator surface in the library itself, backed by typed structs, telemetry, and thin Mix tasks.
3. Keep backend-native search power under `Scrypath.Meilisearch.*`, with request/result structs or explicit functions, and only graduate features to `Scrypath.search/3` after they prove to be stable common-path concepts.

Do not make public multi-backend support the next milestone by default. The current codebase still has Meilisearch-specific orchestration assumptions in `Scrypath.Sync` and `Scrypath.Reindex`, and broadening the public promise before those assumptions are isolated would create an engine facade that looks portable while still behaving like Meilisearch.

## Current Shape in This Codebase

The existing code already suggests the right center of gravity:

- `lib/scrypath.ex` keeps the public runtime surface small and function-oriented.
- `lib/scrypath/backend.ex` defines an internal behavior with only five callbacks: `name/0`, `index_name/2`, `upsert_documents/3`, `delete_documents/3`, and `search/3`.
- `lib/scrypath/search.ex` normalizes common-path input into `%Scrypath.Query{}` and returns `%Scrypath.SearchResult{}`.
- `lib/scrypath/meilisearch.ex` is already the explicit backend-native escape hatch.
- `lib/scrypath/sync.ex` and `lib/scrypath/reindex.ex` are where Meilisearch-specific operational assumptions currently leak upward, especially task waiting and index lifecycle steps.
- `lib/scrypath/telemetry.ex` already establishes stable common metadata and is the right place to keep building from.

That means Scrypath does not need a new architectural center. It needs cleaner boundaries around the one it already has.

## Recommended Architecture

```text
Ecto schema + Scrypath metadata
  -> Projection and identity
  -> Common write/search API (`Scrypath.*`)
  -> Internal operations layer
       - sync dispatch
       - index lifecycle
       - task references / status reads
       - reindex / backfill orchestration
  -> Backend adapter layer
       - common path behavior (`Scrypath.Backend`)
       - backend-native namespace (`Scrypath.Meilisearch.*`)
  -> Operator surface
       - library APIs returning structs
       - thin Mix tasks
       - telemetry and docs
```

The key rule is simple:

- `Scrypath.*` stays small, boring, and Ecto-first.
- `Scrypath.Meilisearch.*` remains the explicit native power lane.
- internal operations modules absorb lifecycle complexity so future backend breadth does not force a facade rewrite.

## Recommended Component Boundaries

| Component | Status | Responsibility | Communicates With |
|-----------|--------|----------------|-------------------|
| `Scrypath`, `Scrypath.Schema`, `Scrypath.Projection`, `Scrypath.Identity` | Keep mostly as-is | Public Ecto-first schema metadata, projection, canonical document identity | `Scrypath.Sync`, `Scrypath.Search`, `Scrypath.Backfill` |
| `Scrypath.Backend` | Modify internally | Keep the common-path adapter contract small; add only the minimum admin/introspection hooks needed for orchestration | `Scrypath.Config`, operations layer, backend modules |
| `Scrypath.Sync` | Modify | Stay as the public sync entrypoint, but delegate backend task handling to an internal operations/task module instead of `Scrypath.Meilisearch.Tasks` directly | `Scrypath.Config`, `Scrypath.Operator.Tasks`, `Scrypath.Oban.Enqueue` |
| `Scrypath.Search` | Keep stable | Common-path text/filter/sort/page + explicit hydration only | `Scrypath.Backend`, `Scrypath.Hydration` |
| `Scrypath.Meilisearch` | Keep public, narrow | Explicit backend-native read/write escape hatch | Meilisearch-specific client and native request structs |
| `Scrypath.Backfill` | Modify lightly | Batch rebuild over explicit repo/query inputs, emit richer operator-facing results | operations layer, backend |
| `Scrypath.Reindex` | Refactor | Orchestrate rebuilds through internal lifecycle APIs instead of reaching into Meilisearch directly | operations layer, backend |
| `Scrypath.Operator.*` or `Scrypath.Operations.*` | New public namespace | Operator-facing APIs, typed status structs, task refs, index lifecycle reports, introspection | `Scrypath.Reindex`, `Scrypath.Backfill`, backend admin APIs, telemetry |
| `Mix.Tasks.Scrypath.*` | New thin wrappers | CLI ergonomics for maintainers and operators, but no business logic | `Scrypath.Operator.*` |
| `Scrypath.Telemetry` | Expand | Stable event naming, result metadata, operator correlation ids, docs contract for emitted fields | every orchestrator module |

## Specific Recommendations

### 1. Preserve the adapter seam without promising a public engine facade

Keep `Scrypath.Backend` internal. Do not turn it into a plugin API yet.

The right v1.2 change is to give internal orchestration one more layer of indirection, not to expose backend polymorphism publicly. Today, `Scrypath.Reindex.run/2` calls Meilisearch-specific functions directly and `Scrypath.Sync` knows about `Scrypath.Meilisearch.Tasks.wait_for_task/2`. That is enough evidence that the current seam is not yet deep enough for public multi-backend claims.

Recommended internal evolution:

- Keep the existing common-path callbacks for search and document writes.
- Add one internal admin capability surface for operations that are not part of the normal application path.
- Make capabilities explicit rather than inferred from module names.

Recommended shape:

```elixir
defmodule Scrypath.Backend.Admin do
  @callback capabilities() :: %{
              task_tracking?: boolean(),
              managed_reindex?: boolean(),
              settings_apply?: boolean(),
              alias_swap?: boolean()
            }

  @callback create_target_index(module(), keyword()) :: {:ok, map()} | {:error, term()}
  @callback apply_settings(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  @callback swap_live_index(module(), keyword()) :: {:ok, map()} | {:error, term()}
  @callback fetch_task(term(), keyword()) :: {:ok, map()} | {:error, term()}
end
```

This should stay internal and documented as such. The benefit is sequencing safety:

- backend breadth can arrive later without changing `Scrypath.search/3` or `Scrypath.sync_*`
- operator tooling can depend on stable internal capabilities instead of hard-coded Meilisearch branches
- Scrypath can say "Meilisearch-first library with an internal seam" and still be telling the truth

What not to do yet:

- no `Scrypath.Backends.register/2`
- no user-authored adapter API
- no generic `backend_options: %{...}` bag on common-path calls
- no promise that every backend will support reindex/settings/task inspection equally

### 2. Operator tooling should be library-first, Mix-second, not a separate package

For an Ecto-native library, the operator surface should live in the main package first.

Why:

- operator workflows already share the same runtime contracts as sync, backfill, and reindex
- a separate package now would force duplicate versioning, docs drift, and cross-package compatibility policy before there is proof it is needed
- Elixir users expect library APIs they can call from Mix tasks, releases, tests, and app code

Recommended operator surface:

- public library APIs under `Scrypath.Operator.*` or `Scrypath.Operations.*`
- thin Mix tasks for shell ergonomics
- typed structs for machine-readable results
- telemetry on every long-running or multi-step operator action
- docs and ExDoc guides, not a separate service

Recommended new public modules:

| Module | Purpose |
|--------|---------|
| `Scrypath.Operator.Reindex` | start, inspect, and summarize managed rebuild workflows |
| `Scrypath.Operator.Backfill` | explicit repair/backfill runs with dry-run and count reporting |
| `Scrypath.Operator.Tasks` | normalize backend task refs and status inspection |
| `Scrypath.Operator.Introspection` | resolve schema config, index names, settings, sync mode expectations, and backend capability visibility |

Recommended result structs:

```elixir
defmodule Scrypath.Operator.TaskRef do
  defstruct [:backend, :uid, :index, :type, :status]
end

defmodule Scrypath.Operator.ReindexRun do
  defstruct [
    :schema,
    :backend,
    :live_index,
    :target_index,
    :cutover?,
    :status,
    :task_refs,
    :documents,
    :batches,
    :started_at,
    :finished_at
  ]
end
```

Recommended Mix tasks:

- `mix scrypath.inspect SchemaModule`
- `mix scrypath.backfill SchemaModule --dry-run`
- `mix scrypath.reindex SchemaModule`
- `mix scrypath.tasks --backend meilisearch --status failed`

Those tasks should do parsing, output formatting, and calls into `Scrypath.Operator.*`. They should not contain workflow logic.

What to defer:

- a Phoenix LiveDashboard page
- a hosted admin panel
- a separate `scrypath_ops` package

Add those only after there is evidence that the library APIs and telemetry are not enough.

### 3. Expose backend-native search power through explicit native modules, not common-path passthroughs

The current direction is correct: `Scrypath.search/3` is the stable common path, and `Scrypath.Meilisearch.*` is the escape hatch.

For v1.2, strengthen this split:

- keep `Scrypath.search/3` limited to concepts Scrypath owns: text, validated filters, validated sorts, paging, hydration
- add explicit Meilisearch-native request/result types for advanced backend features
- keep native outputs visibly native

Recommended additions:

```elixir
defmodule Scrypath.Meilisearch.SearchRequest do
  defstruct [
    :query,
    :filter,
    :sort,
    :facets,
    :attributes_to_retrieve,
    :attributes_to_highlight,
    :ranking_score_threshold,
    :hybrid,
    :tenant_token
  ]
end

defmodule Scrypath.Meilisearch.SearchResult do
  defstruct [:raw, :hits, :facet_distribution, :estimated_total_hits]
end
```

This gives Scrypath room to support richer backend-native power such as facets, tenant-token-driven queries, ranking controls, or later semantic/hybrid search without contaminating `Scrypath.Query`.

Graduation rule for the common path:

- only promote a capability into `Scrypath.search/3` if it is backend-agnostic in shape, easy to validate, and easy to explain in Ecto terms

Examples:

- `facets` should stay native for now
- tenant-token or search-rule auth should stay native
- hybrid/semantic knobs should stay native
- common pagination, common filter, and common sort remain common

What not to do:

- no `native: %{...}` option on `Scrypath.search/3`
- no opaque passthrough map on common calls
- no fake portability layer that normalizes inherently different ranking or facet semantics

### 4. Release/publication confidence is part of architecture, not just process

Scrypath is a library, so release confidence is part of the product architecture.

The current repo already has the right building blocks:

- `mix.exs` pins `@version` and `@source_ref`
- docs include `ARCHITECTURE.md` and maintainer docs
- `.github/workflows/release-please.yml` publishes only when `release_created == true`
- `docs/releasing.md` keeps manual publish validation separate from CI

The next milestone should preserve that discipline:

- release tags remain the single source of truth for published source refs
- semver changes should be treated as public contract changes, not just release notes
- docs must build against the tagged source ref that HexDocs points to
- publish automation stays thin and obvious

Architectural recommendation:

1. Make the first real tagged/public release the gating event before backend breadth.
2. Add one release contract test that verifies:
   - `mix.exs` version matches the tag shape Scrypath expects
   - docs source links point to the tagged ref
   - release workflow still publishes from the created tag
3. Keep Hex publishing in the existing workflow, not in bespoke scripts.

Why sequencing matters:

- until the library has one successful public release, widening the surface only increases support burden
- real semver pressure reveals which APIs feel stable and which are still internal convenience wrappers
- release ergonomics affect trust as much as runtime behavior for an OSS library

### 5. Architecture sequencing for v1.2 and beyond

Recommended build order:

1. **Real release proof and release-contract hardening**
   - validate the first public tag/publish path
   - confirm docs/source/version/tag alignment
   - do not widen runtime API during the same slice

2. **Internal operations seam extraction**
   - refactor `Scrypath.Sync` to depend on a task/status abstraction, not directly on `Scrypath.Meilisearch.Tasks`
   - refactor `Scrypath.Reindex` to depend on backend admin/lifecycle hooks, not direct `Scrypath.Meilisearch` calls

3. **Operator API layer**
   - introduce `Scrypath.Operator.*` modules and result structs
   - expose introspection, task refs, and lifecycle summaries
   - emit stable telemetry for all long-running workflows

4. **Thin Mix tasks**
   - wrap the operator API with small tasks for maintainers and operators
   - keep tasks output-oriented, not logic-heavy

5. **Meilisearch-native power lane**
   - add explicit request/result modules under `Scrypath.Meilisearch.*`
   - extend docs with "common path vs native path" guidance

6. **Only then decide on backend breadth**
   - if adoption pressure is for Typesense or another engine, the seam is ready enough to evaluate honestly
   - if adoption pressure is instead for stronger operations or Meilisearch-native features, keep going deeper instead of wider

## Integration Points

### Modified integration points

| Current integration | Problem | Recommended change |
|---------------------|---------|--------------------|
| `Scrypath.Sync` -> `Scrypath.Meilisearch.Tasks.wait_for_task/2` | common sync orchestration knows backend task details | route through `Scrypath.Operator.Tasks` or an internal task adapter |
| `Scrypath.Reindex` -> `Scrypath.Meilisearch.create_index/apply_settings/swap_indexes` | rebuild flow is Meilisearch-shaped at the top level | route through internal backend admin/lifecycle callbacks |
| public docs -> Meilisearch-specific operator guidance mixed into core architecture | harder to preserve "common path vs native path" story | split docs into common operations, operator APIs, and Meilisearch-native extensions |

### New integration points

| New point | Why |
|-----------|-----|
| `Scrypath.Operator.Introspection.schema_report/2` | lets tasks, docs examples, and future dashboards use one normalized schema/backend report |
| `Scrypath.Operator.Tasks.fetch/2` | gives operator tooling one backend-neutral task inspection shape |
| telemetry correlation ids for reindex/backfill runs | ties Mix tasks, logs, and task polls together without new runtime services |
| ExDoc guide for "Choosing common path vs native path" | keeps DX crisp as features widen |

## Patterns to Follow

### Pattern 1: Keep the common path small and typed

`Scrypath.search/3`, `sync_record/3`, `backfill/2`, and `reindex/2` should remain predictable and validated. The current `%Scrypath.Query{}` shape is a good example of the right restraint.

### Pattern 2: Put native power in explicit namespaces

Laravel Scout succeeds here: it has a common engine interface, but still allows engine-specific behavior rather than forcing all features through one universal builder. Scrypath should do the same, but with more restraint because backend breadth is not yet public.  
Source: https://laravel.com/docs/12.x/scout

### Pattern 3: Prefer queue-backed or operator-visible indexing, not hidden "magic realtime"

Search libraries repeatedly run into trouble when indexing is implicit and invisible. Haystack documents that in-process realtime indexing can make request users "sit & wait". Scrypath already chose explicit sync modes; keep leaning into that.  
Source: https://django-haystack.readthedocs.io/en/master/signal_processors.html

### Pattern 4: Treat reindex as staged lifecycle, not an implementation detail

Searchkick and Meilisearch both reinforce the need for zero-downtime rebuild workflows and explicit swaps. Scrypath already has `cutover?: false` and target indexes in `Scrypath.ReindexTest`; that should become the foundation for richer operator tooling, not be hidden.  
Sources: https://github.com/ankane/searchkick, https://www.meilisearch.com/blog/zero-downtime-index-deployment

### Pattern 5: Telemetry first, dashboards later

Phoenix explicitly encourages library telemetry adoption. Scrypath already emits stable common metadata in `Scrypath.Telemetry.common_metadata/3`; v1.2 should deepen that instead of building a UI first.  
Source: https://hexdocs.pm/phoenix/telemetry.html

## Anti-Patterns to Avoid

### Anti-Pattern 1: Public multi-backend claims while orchestration is still Meilisearch-shaped

**What goes wrong:** users are told the library is backend-agnostic, but only Meilisearch supports the real operator story.  
**Why bad:** creates semantic version pressure and support burden before the seam is honest.  
**Instead:** keep the seam internal, extract lifecycle/task abstractions first, then evaluate breadth.

### Anti-Pattern 2: Generic passthrough options on the common search path

**What goes wrong:** `Scrypath.search/3` becomes a transport for backend payloads.  
**Why bad:** validation weakens, docs get muddy, and portable code becomes accidental backend lock-in.  
**Instead:** use `Scrypath.Meilisearch.SearchRequest` or explicit native functions.

### Anti-Pattern 3: CLI-only operator workflows

**What goes wrong:** Mix tasks become the real API and app code cannot reuse them safely.  
**Why bad:** harder testing, weaker docs, and no typed result contracts.  
**Instead:** library APIs first, Mix task wrappers second.

### Anti-Pattern 4: Separate package too early

**What goes wrong:** `scrypath_ops` or similar ships before the core operator contracts are stable.  
**Why bad:** duplicated semver surface and docs drift.  
**Instead:** keep operator APIs in the main package until there is a concrete need for optional runtime/UI tooling.

### Anti-Pattern 5: Hidden callback-style sync magic

**What goes wrong:** search writes become implicit side effects with unclear failure semantics.  
**Why bad:** least surprise is lost and recovery paths get harder.  
**Instead:** preserve explicit sync verbs and explicit sync modes.

## Deferrals

These should stay out of the next milestone unless adoption pressure is overwhelming:

| Defer | Why |
|------|-----|
| public backend-agnostic adapter/plugin API | the internal seam is not yet operationally complete |
| second backend in the same milestone as operator seam extraction | mixes two sources of change and hides where pain actually is |
| common-path facets / semantic / hybrid search | these are backend-native today and would poison the common path |
| separate operator package or Phoenix UI | library APIs and telemetry should prove out first |
| automatic drift detection and self-healing rebuilds | good future direction, but too much policy for v1.2 |
| old-index garbage collection as automatic reindex behavior | too easy to surprise operators; keep cleanup explicit |

## Scalability Considerations

| Concern | v1.2 / early adopters | Later after adoption signal |
|---------|------------------------|-----------------------------|
| backend breadth | preserve internal seam only | add second backend only if operator/lifecycle abstractions hold |
| operator workflows | library APIs + Mix tasks + telemetry | optional UI or separate package if there is repeated demand |
| native search power | explicit `Scrypath.Meilisearch.*` modules | graduate only proven cross-backend concepts |
| release confidence | one successful public release plus contract tests | keep CI/publish path boring and documented |

## Architectural Sequencing Recommendation

The next milestone should be sequenced as:

1. release/publication confidence in the real world
2. internal lifecycle/task seam extraction
3. public operator API layer
4. thin Mix task ergonomics
5. Meilisearch-native power lane improvements
6. only then, decide whether backend breadth is actually the next problem

That order best preserves least surprise, keeps the public API honest, and avoids a fake abstraction layer that would be expensive to undo.

## Sources

- Local codebase:
  - `lib/scrypath.ex`
  - `lib/scrypath/backend.ex`
  - `lib/scrypath/sync.ex`
  - `lib/scrypath/reindex.ex`
  - `lib/scrypath/search.ex`
  - `lib/scrypath/meilisearch.ex`
  - `lib/scrypath/telemetry.ex`
  - `test/scrypath/backend_test.exs`
  - `test/scrypath/reindex_test.exs`
  - `test/scrypath/meilisearch/tasks_test.exs`
  - `.github/workflows/ci.yml`
  - `.github/workflows/release-please.yml`
  - `docs/releasing.md`
- Official / primary references:
  - Laravel Scout docs: https://laravel.com/docs/12.x/scout
  - Searchkick repository/docs: https://github.com/ankane/searchkick
  - Meilisearch tasks and async docs: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations
  - Meilisearch filtering/sorting/faceting docs: https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/overview
  - Meilisearch task API: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks
  - Meilisearch tenant token docs: https://www.meilisearch.com/docs/learn/security/tenant_token_reference
  - Meilisearch zero-downtime index deployment article: https://www.meilisearch.com/blog/zero-downtime-index-deployment
  - Meilisearch Rails repository/docs: https://github.com/meilisearch/meilisearch-rails
  - Haystack signal processor docs: https://django-haystack.readthedocs.io/en/master/signal_processors.html
  - Oban unique jobs docs: https://hexdocs.pm/oban/unique_jobs.html
  - Hex publishing docs: https://hex.pm/docs/publish
  - Phoenix telemetry docs: https://hexdocs.pm/phoenix/telemetry.html
