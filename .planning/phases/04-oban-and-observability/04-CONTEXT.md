# Phase 4: Oban and Observability - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the production async sync path and first-class instrumentation needed for serious application use. This phase extends Scrypath's existing explicit sync model with Oban-backed durable enqueueing and Telemetry coverage for key search and indexing workflows. It must preserve the current product boundary: runtime behavior stays under `Scrypath.*`, Oban remains optional and explicit, backend-specific detail stays visible instead of being flattened into a fake abstraction, and operational reality remains part of the public contract.

</domain>

<decisions>
## Implementation Decisions

### Oban public integration shape
- **D-01:** Oban-backed async sync should remain on the existing `Scrypath.*` sync verbs through `sync_mode: :oban`.
- **D-02:** Phase 4 should not introduce a second full public sync API under `Scrypath.Oban.*`; the common verbs remain the primary runtime surface.
- **D-03:** Scrypath should add a narrow `Scrypath.Oban` helper only for transactional enqueue composition in `Ecto.Multi` / `Repo.transact`.
- **D-04:** Oban configuration and queue-specific options should stay explicit and local to the call or explicit defaults, not hidden behind magical global behavior.
- **D-05:** If `sync_mode: :oban` is used without the required dependency or runtime configuration, Scrypath should fail clearly and directly.

### Async job payload and execution model
- **D-06:** Phase 4 should use separate operation-specific workers, centered on an upsert worker and a delete worker.
- **D-07:** Upsert jobs should carry normalized, JSON-safe projected document payloads rather than source-row reload instructions.
- **D-08:** Delete jobs should carry resolved document ids plus index context and must not reload deleted rows.
- **D-09:** Projection and identity resolution should stay in the explicit application-side orchestration path before enqueue, not move into hidden worker reload logic.
- **D-10:** `:manual` and `:oban` should preserve the same normalized sync semantics; only execution strategy and durability guarantees change.
- **D-11:** Batch semantics in `:oban` mode should follow the caller's explicit API shape such as `sync_records/3` and `delete_documents/3`, not hidden cross-job aggregation.
- **D-12:** Oban job args must stay JSON-safe and validation-friendly; do not serialize Ecto structs or atom-keyed opaque terms into jobs.
- **D-13:** Phase 4 should not make debounce or buffer-flush orchestration the default async model; heavier batching strategy can be revisited in later operational phases.

### Telemetry surface and event naming
- **D-14:** Scrypath should expose a layered Telemetry model: stable common-path spans on `Scrypath.*` plus explicit backend-specific spans under `Scrypath.Meilisearch.*`.
- **D-15:** Public workflow events should use `:telemetry.span/3` conventions with `:start`, `:stop`, and `:exception` semantics rather than outcome-specific event names.
- **D-16:** Common Telemetry metadata must stay low-cardinality and stable, centered on fields such as schema, backend, sync mode, index, repo, document count, hit count, and missing count where relevant.
- **D-17:** Meilisearch-specific details such as task uid, task status, request ids, poll counts, and backend wait timing should live only on explicit Meilisearch event prefixes, not on the common event contract.
- **D-18:** Scrypath should emit batch- or workflow-level events, not one public Telemetry event per record.

### Consistency and operator contract
- **D-19:** Phase 4 docs should define sync modes through an explicit contract matrix, not through a vague \"automatic background sync\" story.
- **D-20:** `sync_mode: :inline` means Scrypath waits for terminal backend task success before returning success, while still documenting that DB and search are not atomic.
- **D-21:** `sync_mode: :manual` means Scrypath accepts work intentionally and returns control immediately for operator-controlled execution.
- **D-22:** `sync_mode: :oban` means durable enqueue accepted, not search visibility completed; a successful enqueue does not mean the document is already searchable.
- **D-23:** Phase 4 should document one shared async lifecycle for operators: `requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`.
- **D-24:** Retry exhaustion, discarded jobs, stale deletes, and search drift are normal operational realities that must be documented plainly rather than treated as rare edge cases.

### the agent's Discretion
- Exact worker module names, option names, and internal payload field layout, as long as the public semantics above remain intact.
- Exact retry classification and backoff defaults, as long as transient failures retry and permanent data-shape or config errors do not loop forever.
- Exact stable common Telemetry metadata field names and result-struct shape, as long as the public instrumentation contract stays small, low-cardinality, and explicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and locked phase boundaries
- `.planning/PROJECT.md` — project framing, non-negotiable constraints, and the Ecto-first and operationally explicit product posture
- `.planning/REQUIREMENTS.md` — Phase 4 requirement mapping for `SYNC-05` and `OPER-04`
- `.planning/ROADMAP.md` — Phase 4 goal and success criteria
- `.planning/STATE.md` — current project state and continuity notes
- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md` — locked decisions about runtime surface, optional Oban, and explicit orchestration
- `.planning/phases/02-meilisearch-core-sync/02-CONTEXT.md` — locked decisions about explicit sync verbs, delete identity, and honest completion semantics
- `.planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md` — locked decisions about the common path, backend escape hatches, and stable result contracts

### Current implementation surface
- `lib/scrypath.ex` — top-level public runtime facade that Phase 4 must extend without splitting the product into parallel sync APIs
- `lib/scrypath/sync.ex` — existing sync orchestration and the current placeholder `:oban` mode behavior
- `lib/scrypath/options.ex` — runtime option schema including existing `sync_mode: :oban`
- `lib/scrypath/config.ex` — runtime option resolution rules
- `lib/scrypath/identity.ex` — delete identity rules that async jobs must preserve
- `lib/scrypath/projection.ex` — explicit projection behavior and no-hidden-preload policy
- `lib/scrypath/document.ex` — normalized document boundary for projected sync payloads
- `lib/scrypath/search.ex` — common search path that Phase 4 instrumentation must cover
- `lib/scrypath/meilisearch.ex` — explicit Meilisearch escape hatch and backend boundary
- `lib/scrypath/meilisearch/tasks.ex` — Meilisearch task waiting semantics that inform async observability design
- `README.md` — current public product boundary and sync/search documentation that Phase 4 must extend consistently

### Existing tests and fixtures
- `test/scrypath/sync_test.exs` — current sync semantics, delete identity behavior, and inline wait contract
- `test/scrypath/search_test.exs` — common search path behavior and stable result expectations
- `test/scrypath/meilisearch_test.exs` — existing Meilisearch adapter behavior and task/client expectations
- `test/support/fake_backend.ex` — backend contract test-double pattern that may need async-aware extensions

### Local research context
- `prompts/elixir-search-lib-deep-research.md` — search-library architecture, queue-backed indexing lessons, and operational design guidance
- `prompts/search-lib-use-cases-deep-research.md` — lessons from Searchkick, Scout, Meilisearch Rails, Haystack, and adjacent library shapes
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library API design, optional integration, and Telemetry ergonomics guidance
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and instrumentation guidance
- `prompts/ecto-best-practices-deep-research.md` — Ecto orchestration, transaction boundaries, and explicit loading guidance

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Sync` already centralizes the public write-path orchestration and is the natural place to preserve shared sync semantics across `:inline`, `:manual`, and `:oban`.
- `Scrypath.Options` and `Scrypath.Config` already provide validated runtime option resolution and can carry explicit Oban-related configuration without inventing a parallel configuration model.
- `Scrypath.Projection`, `Scrypath.Document`, and `Scrypath.Identity` already define the normalized payload and delete-id boundaries that async jobs should reuse.
- `Scrypath.Search` and `Scrypath.Meilisearch.Tasks` provide the existing workflow boundaries for common-path and backend-specific instrumentation.

### Established Patterns
- Runtime behavior stays under `Scrypath.*`; schema modules remain metadata-first and do not get runtime sync helpers.
- Sync invocation is explicit in application orchestration code rather than hidden behind schema callbacks or repo hooks.
- Backend-specific power lives under `Scrypath.Meilisearch.*` instead of being tunneled through opaque common-path options.
- Operational honesty already shapes the library: inline completion is real completion, delete identity is explicit, and stale or missing data stays visible.

### Integration Points
- Phase 4 should extend `lib/scrypath/sync.ex` with enqueue behavior and stable accepted-result semantics for `:oban`.
- A narrow `Scrypath.Oban` helper can integrate with `Ecto.Multi` / `Repo.transact` without becoming a second full sync API family.
- New Oban workers should connect to the existing backend seam and normalized payload contracts rather than introduce reload-oriented runtime coupling.
- Telemetry should instrument the shared sync and search paths plus the explicit Meilisearch task boundary, and compose with Oban's own Telemetry events rather than duplicate them.

</code_context>

<specifics>
## Specific Ideas

- The DX target is one obvious public sync surface with explicit execution modes, not parallel APIs or hidden callback behavior.
- Searchkick remains the benchmark for obvious verbs and queue-minded DX, but Scrypath should translate that into explicit Ecto context orchestration instead of model callbacks.
- Laravel Scout remains the benchmark for a clean common path plus explicit engine split, but Scrypath should stay blunter about consistency windows and failure semantics than Scout-style \"background sync\" language usually is.
- Meilisearch Rails is a useful operational reference for backend tasks and engine-specific behavior, but its automatic ActiveRecord callback syncing is a footgun Scrypath should not copy.
- Haystack's warnings about real-time signal-based indexing reinforce the decision to avoid hidden sync callbacks and to treat retries, drift, and operator recovery as first-class concerns.

</specifics>

<deferred>
## Deferred Ideas

- Source-id reload workers that reload rows and re-project inside the job — deferred because they conflict with the current explicit projection and preload posture.
- Debounce or buffer-flush worker orchestration as the default async path — deferred to later operational or reindex phases where higher-volume batching is first-class scope.
- A separate companion package such as `scrypath_oban` — deferred because it would add adoption friction for a core v1 sync mode.
- A second full public API under `Scrypath.Oban.*` for normal sync verbs — deferred because it would fragment the product surface and weaken the existing `sync_mode` model.

</deferred>

---
*Phase: 04-oban-and-observability*
*Context gathered: 2026-04-15*
