# Phase 2: Meilisearch Core Sync - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the first real backend integration for Scrypath by implementing Meilisearch-backed indexing sync for insert, update, delete, and manual workflows. This phase makes the library operational for one supported backend without changing the Phase 1 product boundary: runtime behavior stays under `Scrypath.*`, the backend seam remains internal, and later phases still own Oban, richer Meilisearch operations, search APIs, and managed reindex orchestration.

</domain>

<decisions>
## Implementation Decisions

### Sync API shape
- **D-01:** Phase 2 public sync APIs should live under `Scrypath.*`, not on schema modules.
- **D-02:** Insert and update should collapse into one upsert-oriented sync path because Meilisearch itself treats document writes as upserts.
- **D-03:** Delete should be a separate public path with explicit identity semantics instead of being inferred from a generic polymorphic `sync` call.
- **D-04:** The documented primary API should use explicit lifecycle verbs rather than a single action-dispatcher API with option-heavy branching.
- **D-05:** `:inline` and `:manual` should share the same public verb semantics; only execution strategy and completion guarantees differ.
- **D-06:** Sync invocation should be explicit in contexts and write orchestration code, not injected automatically by `use Scrypath` or hidden callback magic.
- **D-07:** Manual workflows should support intentional single-record and batch sync without introducing a separate conceptual API family.

### Delete identity contract
- **D-08:** Delete operations are keyed by canonical document identity, not by full document projection.
- **D-09:** Scrypath must capture delete identity from the source struct before the row becomes unavailable.
- **D-10:** `document_id` metadata remains the default identity source.
- **D-11:** If custom identity is needed, Scrypath should support a dedicated identity hook such as `search_document_id/1`.
- **D-12:** `search_document/1` must not be the authoritative source for delete identity in v1.
- **D-13:** Manual delete APIs should accept explicit document IDs for cases where no source struct is available.
- **D-14:** Future async delete payloads should carry schema, document id, and resolved index context, not instructions to reload a deleted row.
- **D-15:** Custom document ids must be stable, deterministic, and derivable from pre-delete data alone.

### Inline failure semantics
- **D-16:** `sync_mode: :inline` means Scrypath waits for Meilisearch task completion before returning success.
- **D-17:** Scrypath must not treat Meilisearch task acceptance or `202 Accepted` as inline success.
- **D-18:** The public write-path contract should use stable Elixir tuples: `{:ok, sync_result}` or `{:error, reason}`.
- **D-19:** `sync_result` should expose backend task metadata so Meilisearch’s asynchronous execution remains visible instead of being hidden behind fake synchrony.
- **D-20:** Manual sync is the explicit enqueue/operator path and may return task references without waiting.
- **D-21:** Inline timeout before terminal task completion is an error outcome, not a silent partial success.
- **D-22:** Phase 2 docs must state clearly that inline improves immediacy but does not make database and search writes atomic.
- **D-23:** Scrypath should encourage calling inline sync after successful repo persistence, not from inside uncommitted transaction steps.
- **D-24:** Backend failure details should preserve enough structure to distinguish transport failure, backend task failure, timeout, and cancellation.

### Meilisearch-specific surface
- **D-25:** `Scrypath.*` remains the canonical runtime surface for common sync verbs in Phase 2.
- **D-26:** Phase 2 should expose a small public `Scrypath.Meilisearch.*` namespace for backend-native operations instead of hiding them behind generic options.
- **D-27:** The common path should cover only the stable cross-backend core: document identity, index resolution, upsert, delete, sync mode selection, and explicit runtime config.
- **D-28:** Meilisearch-only concepts such as raw responses, task handling, and index or settings operations should live under `Scrypath.Meilisearch.*`.
- **D-29:** Backend-specific power should be opt-in and explicit, never silently tunneled through the common API.
- **D-30:** `use Scrypath` should stay metadata-first; avoid adding Meilisearch-heavy schema DSL in Phase 2 unless the backend coupling is obvious and immediately valuable.
- **D-31:** Phase 2 docs should distinguish the common happy path from the Meilisearch-specific escape hatch.

### the agent's Discretion
- Exact function names and module grouping beneath the `Scrypath.*` and `Scrypath.Meilisearch.*` surfaces, as long as the public semantics above remain intact.
- Exact polling, timeout, and result-struct layout for inline task waiting, as long as inline success still means terminal backend success.
- Exact validation rules for a dedicated custom identity hook, as long as identity stays single-source and stable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and phase boundary
- `.planning/PROJECT.md` — project goals, product posture, and locked constraints for backend strategy, sync modes, and operational honesty
- `.planning/REQUIREMENTS.md` — Phase 2 requirement mapping for `BACK-01`, `SYNC-01`, `SYNC-02`, `SYNC-03`, `SYNC-04`, and `SYNC-06`
- `.planning/ROADMAP.md` — Phase 2 goal and success criteria
- `.planning/STATE.md` — current project state and reference-material rules
- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md` — locked Phase 1 decisions that Phase 2 must extend without reshaping

### Current product and architecture docs
- `README.md` — current public product boundary and roadmap language
- `ARCHITECTURE.md` — public surface, projection flow, internal backend seam, and deferred-work boundaries

### Current implementation surface
- `lib/scrypath.ex` — top-level public runtime surface from Phase 1
- `lib/scrypath/backend.ex` — narrow internal backend behavior contract
- `lib/scrypath/config.ex` — runtime config resolution rules
- `lib/scrypath/options.ex` — existing schema and runtime option contracts
- `lib/scrypath/projection.ex` — document projection rules and custom projection precedence
- `lib/scrypath/document.ex` — shared document struct used at the backend boundary

### Local research context
- `prompts/search-lib-use-cases-deep-research.md` — lessons from Searchkick, Scout, Meilisearch Rails, and other search-library shapes
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and library design guidance
- `prompts/ecto-best-practices-deep-research.md` — Ecto-side orchestration, transaction, and explicit data-flow guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS API, naming, configuration, and DX guidance

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Projection.document/2` and `Scrypath.Document` already provide a concrete projected-document boundary that Phase 2 can reuse for upsert flows.
- `Scrypath.Config.resolve!/1` and `Scrypath.Options.validate_runtime_options!/1` already centralize runtime option validation and sync-mode selection.
- `Scrypath.Backend` already defines the narrow backend seam for `index_name/2`, `upsert_documents/3`, `delete_documents/3`, and `search/3`.
- `test/support/fake_backend.ex` and `test/scrypath/backend_test.exs` establish the pattern for backend contract verification.

### Established Patterns
- Runtime behavior is centralized under `Scrypath.*`; schema modules expose metadata only.
- Explicit runtime options are canonical; app config is convenience sugar, not the hidden contract.
- Projection involving association-derived data must be caller-prepared and preload-explicit.
- The codebase already frames Meilisearch-first support as real product scope while keeping public multi-backend promises deferred.

### Integration Points
- Phase 2 implementation should extend `lib/scrypath.ex` with the common sync surface.
- Meilisearch-specific runtime code should land under `lib/scrypath/meilisearch/*` without widening the internal behavior beyond what Phase 2 actually needs.
- Delete identity logic should connect to existing schema metadata and projection rules without introducing a second implicit source of truth.
- Tests should build on the existing backend and projection contract suite rather than inventing a parallel shape.

</code_context>

<specifics>
## Specific Ideas

- Scrypath should learn from Searchkick and Scout’s obvious verbs and minimal first-mile ergonomics, but translate them into explicit Elixir context calls instead of callback-driven model magic.
- Meilisearch Rails is the strongest operational reference for Phase 2 semantics: manual indexing and deletion are explicit, and backend work remains task-based even when the application path feels synchronous.
- Great DX here means a caller can tell, from the function name and return shape alone, whether Scrypath is waiting for completion or merely enqueuing backend work.
- The public API should read like an idiomatic Elixir library, not a port of Rails callback conventions.

</specifics>

<deferred>
## Deferred Ideas

- Automatic callback-style sync wiring on repo or schema writes — deferred because it conflicts with the explicit Ecto-first design and would be a separate product decision.
- Broader Meilisearch settings, raw client access, and richer operator workflows beyond the minimum escape hatch — deferred to later phases where settings and reindex orchestration are first-class scope.
- Shared-index and multi-schema identity ergonomics beyond the stable-id contract needed now — defer broader strategy until reindex and operational workflows are in scope.

</deferred>

---
*Phase: 02-meilisearch-core-sync*
*Context gathered: 2026-04-15*
