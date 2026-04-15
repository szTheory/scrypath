# Phase 2: Meilisearch Core Sync - Research

**Researched:** 2026-04-15
**Status:** Ready for planning

## Research Question

What do I need to know to PLAN this phase well?

## Executive Summary

Phase 2 is where Scrypath stops being a contract-only library and becomes useful end to end for one real backend. The planning target is not "support all search operations," but "deliver honest, explicit indexing sync for Meilisearch without reopening the Phase 1 API boundary."

The strongest planning direction, based on the locked context and current codebase, is:

- add a narrow public sync surface under `Scrypath.*` with explicit upsert and delete verbs
- implement a real `Scrypath.Meilisearch` backend module plus a small Meilisearch-specific namespace for raw task handling
- keep inline and manual as execution strategies on the same verbs, not separate conceptual APIs
- resolve delete identity from schema metadata or a dedicated hook before deletion, never by reloading deleted rows
- model inline success as terminal Meilisearch task success, not task acceptance
- keep tests contract-heavy and transport-light by isolating document building, config normalization, identity resolution, and backend response handling

If the phase plan stays disciplined around those boundaries, Scrypath gains a usable Meilisearch write path without prematurely shipping the broader search, Oban, and reindex surfaces owned by later phases.

## What Phase 2 Must Actually Deliver

Per the roadmap and requirements, this phase must cover:

- `BACK-01`: public Meilisearch support for v1
- `SYNC-01`: synchronize searchable records on insert
- `SYNC-02`: synchronize searchable records on update
- `SYNC-03`: remove searchable records from the index on delete without requiring the row to still exist
- `SYNC-04`: support inline synchronization
- `SYNC-06`: support manual synchronization

That means the phase plan should produce four concrete outcomes:

1. A public sync runtime API under `Scrypath.*`.
2. A concrete Meilisearch backend implementation and task-waiting support.
3. A delete identity contract that works from pre-delete data or explicit ids.
4. Documentation and tests that make inline versus manual guarantees explicit.

## Planning Constraints That Should Stay Locked

### 1. Phase 1 boundaries must survive intact

Phase 1 already locked the product shape:

- `use Scrypath` stays metadata-only
- runtime behavior stays under `Scrypath.*`
- the adapter seam stays internal
- backend-specific power is explicit and namespaced

Planning implication:

- do not add generated schema runtime APIs
- do not widen `Scrypath.Backend` beyond what Meilisearch sync actually needs
- do not start exposing generic adapter registration or public backend-agnostic extension points

### 2. Upsert and delete should be distinct public verbs

The context is clear that insert and update collapse into one upsert-oriented sync path, while delete remains explicit because it has different identity and failure semantics.

Planning implication:

- common API should plan around one upsert verb plus one delete verb
- any batch and manual helpers should preserve those semantics instead of inventing a new API family
- return values should make the execution mode obvious without relying on docs alone

### 3. Delete identity must be independent from projection

`Scrypath.Projection.document/2` is good for upsert payloads but is not the right authority for deletes. Phase 2 needs a stable identity path that works before the row disappears.

Planning implication:

- add a dedicated identity helper under Scrypath-managed runtime modules
- default to `document_id` metadata for the canonical id
- support an explicit hook for custom ids when metadata alone is not enough
- support manual delete by explicit document id so no source struct is required

### 4. Inline mode must wait for terminal backend success

The discussion context already decided that `sync_mode: :inline` returns success only after Meilisearch reports terminal success. That means the implementation cannot stop at `202 Accepted`.

Planning implication:

- Meilisearch task polling and timeout handling are in scope for Phase 2
- result types need to preserve task metadata and failure detail
- timeout, transport failure, and backend task failure must remain distinguishable

### 5. Manual mode is the operator path, not a weaker inline mode

Manual sync is not just "inline without waiting." It is the explicit path for imports, migrations, and operator-controlled workflows where returning task references is the honest contract.

Planning implication:

- manual mode should return accepted task metadata without pretending completion
- docs should show both single-record and batch operator flows
- manual behavior should compose with the same document and identity helpers used by inline mode

## Recommended Public Shape To Plan Around

These are the planning targets that fit the current codebase and locked context.

### Common sync surface

Plan around explicit verbs under `Scrypath.*`, for example:

- `Scrypath.sync_record(schema_module, record, opts)`
- `Scrypath.sync_records(schema_module, records, opts)`
- `Scrypath.delete_record(schema_module, record, opts)`
- `Scrypath.delete_document(schema_module, document_id, opts)`

The exact names can vary, but the plan should lock:

- one clear upsert path for insert and update
- one clear delete path
- support for explicit runtime opts including `backend`, `repo`, `index_prefix`, and `sync_mode`
- stable tuple returns such as `{:ok, result}` or `{:error, reason}`

### Internal runtime helpers

The current code suggests Phase 2 should add a small set of support modules instead of pushing everything into `Scrypath`:

- `Scrypath.Sync` or equivalent common runtime orchestration module
- `Scrypath.Identity` or equivalent helper for canonical document ids
- `Scrypath.Meilisearch` for backend-specific runtime entrypoints
- `Scrypath.Meilisearch.Client` or equivalent HTTP boundary
- `Scrypath.Meilisearch.Tasks` or equivalent task polling/result normalization module

The exact grouping can change, but the plan should keep:

- projection concerns in `Scrypath.Projection`
- runtime config in `Scrypath.Config` and `Scrypath.Options`
- backend callbacks in `Scrypath.Backend`
- Meilisearch transport and task logic out of the top-level `Scrypath` facade

### Backend-specific escape hatch

The context explicitly allows a small public `Scrypath.Meilisearch.*` surface in Phase 2.

Planning target:

- expose task or backend-native helpers only where the common API would otherwise lie or become option-heavy
- keep the common path focused on upsert, delete, identity, index resolution, and sync mode
- reserve larger settings, reindex, and broader operator flows for later phases

## Current Codebase Implications

The existing code already gives the plan a usable foundation:

- `Scrypath.Projection.document/2` already builds `Scrypath.Document` for upsert flows
- `Scrypath.document_id_field/1` already exposes the default identity source
- `Scrypath.Config.resolve!/1` already centralizes runtime option merging and validation
- `Scrypath.Backend` already declares `index_name/2`, `upsert_documents/3`, and `delete_documents/3`
- `Scrypath.TestSupport.FakeBackend` and `test/scrypath/backend_test.exs` already establish the pattern for backend contract verification

Planning implication:

- Phase 2 should extend these foundations instead of replacing them
- `Scrypath.Options` will likely need additional runtime validation for Meilisearch-specific config only where the common surface genuinely needs it
- tests should continue to isolate contract logic from transport details, then add focused backend/client tests around Meilisearch behavior

## Meilisearch-Specific Design Notes

### 1. Index naming should stay backend-driven

`Scrypath.Backend.index_name/2` already exists. Phase 2 should use that instead of inventing top-level index naming logic duplicated across the runtime path.

### 2. Upsert should operate on document lists

The backend behavior already expects `[Document.t()]`. Planning should keep that list-oriented contract even for single-record public verbs so batch and single-record flows reuse the same execution path.

### 3. Delete should operate on canonical ids

The backend behavior already expects a list of ids for `delete_documents/3`. Planning should preserve that boundary and resolve ids before backend execution begins.

### 4. Task normalization deserves its own seam

Meilisearch writes are task-based. The plan should isolate:

- accepted task response parsing
- task polling
- terminal status normalization
- timeout/cancellation/failure mapping

Doing that in a dedicated module keeps `Scrypath.Sync` or the top-level facade from accumulating transport and polling detail.

## Key Decisions The Plan Must Make Explicit

The planner should not leave these ambiguous:

1. What exact public verbs exist for upsert and delete in Phase 2?
2. How are single-record and batch operations split or shared?
3. What module resolves canonical delete identity, and what hook name is used if custom identity is supported?
4. What result struct or map represents inline success versus manual acceptance?
5. Which Meilisearch modules are public and which stay internal?
6. How are HTTP transport and task polling tested without making the whole phase brittle?
7. Which docs land now: README additions, module docs, usage guide, or all three?

If those stay vague, execution is likely to oscillate between API design and backend detail instead of moving linearly.

## Suggested Plan Breakdown

The natural decomposition for this phase is:

1. Common sync API and identity resolution.
2. Meilisearch client/backend and inline task handling.
3. Manual/batch workflows plus docs and focused tests.

That split matches the current codebase:

- common runtime behavior extends `Scrypath.*`
- backend-specific work lands under `lib/scrypath/meilisearch/*`
- tests can start with common semantics, then add backend and docs coverage

## Testing Surface The Plan Should Include

At minimum, planning should include:

- public sync API tests for single-record upsert and delete
- identity resolution tests for default `document_id` and custom-id paths
- tests proving delete does not reload missing rows
- manual mode tests proving task metadata is returned without waiting
- inline mode tests proving task polling waits for terminal success
- timeout and backend failure tests for inline mode
- backend/client tests that normalize Meilisearch responses and task statuses
- docs verification showing the public contract and operational caveats are visible

The phase should avoid a test strategy that requires a live Meilisearch instance for every fast-path check. Most logic can stay deterministic with client stubs, fake responses, or a transport boundary.

## Documentation Outcomes Required

Phase 2 docs should be treated as deliverables, not cleanup.

The plan should include docs that explain:

- the public sync verbs and their return shapes
- the meaning of `:inline` versus `:manual`
- that inline waits for terminal backend success but does not make DB and search writes atomic
- how delete identity is determined
- when to use explicit document ids
- where Meilisearch-specific escape hatches live

Minimum planning target:

- update `README.md` for the new sync surface
- add or extend module docs for the new runtime modules
- include at least one user-facing example of explicit context-level sync orchestration

## Operational Pitfalls To Avoid In Planning

- Do not hide Meilisearch task behavior behind a fake synchronous abstraction.
- Do not make delete depend on `search_document/1` output or row reloads.
- Do not create separate, conceptually different APIs for inline and manual sync.
- Do not let Meilisearch-specific options leak into the common path unless the common contract actually depends on them.
- Do not over-design a generic adapter framework before the Meilisearch flow is excellent.

## Recommended Planning Bias

Bias toward a small number of executable plans with clear ownership boundaries:

- one plan for common sync contracts and identity
- one plan for Meilisearch backend execution and inline waiting
- one plan for manual workflows, docs, and completion-level tests

That should be enough to cover the phase without fragmenting a still-small codebase.
