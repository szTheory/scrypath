# Phase 1: Core Contracts and API Shape - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the core public and internal contracts for Scrypath: the schema declaration surface, projection contract, public API shape, adapter boundary, and runtime configuration model. This phase establishes how the library should feel and where responsibilities live; it does not yet deliver the full Meilisearch sync or query workflows from later phases.

</domain>

<decisions>
## Implementation Decisions

### Schema declaration surface
- **D-01:** `use Scrypath` should be small, metadata-focused, and reflective rather than a heavy DSL.
- **D-02:** The macro should validate declarative options, register schema metadata, and generate inspectable helpers such as `__scrypath__/1`.
- **D-03:** The macro may generate narrow defaults such as document id helpers, but it must not inject hidden sync callbacks, runtime orchestration, or model-centric runtime APIs.

### Projection contract
- **D-04:** Scrypath v1 should use a hybrid projection model: declarative `fields: [...]` for the default path plus an explicit override hook such as `search_document/1` for custom document shaping.
- **D-05:** `fields` should define the default same-row projection and remain introspectable at runtime.
- **D-06:** The explicit projection hook is opt-in and takes precedence when present.
- **D-07:** Projection involving associations or denormalized data must require deliberate preloads or dedicated projection queries; Scrypath should not imply magical association loading.
- **D-08:** Projection shape changes should be documented as potentially requiring managed reindex workflows.

### Public module and API shape
- **D-09:** Scrypath should expose one obvious top-level `Scrypath` facade for common verbs, with deeper modules underneath for more specialized concerns.
- **D-10:** `use Scrypath` is for schema declaration and metadata only, not for injecting runtime APIs onto user schema modules.
- **D-11:** Avoid model-centric generated APIs such as `Post.search/2` or `Post.reindex/1`; keep runtime contracts centralized under Scrypath-managed modules.

### Adapter boundary and escape hatches
- **D-12:** Scrypath should provide a stable common happy path for declaration, projection, sync modes, search, hydration, and managed reindex orchestration.
- **D-13:** Backend-specific power should be exposed explicitly through namespaced modules such as `Scrypath.Meilisearch.*`, not flattened into a fake universal abstraction.
- **D-14:** The internal adapter seam should stay narrow and behavior-driven so future backend support remains possible without forcing premature public parity.

### Runtime configuration and dependency model
- **D-15:** Explicit runtime options are the canonical configuration model for Scrypath.
- **D-16:** Application config may exist only as convenience sugar for project-local defaults; it must not become the primary or hidden contract.
- **D-17:** Oban integration must be optional and explicit.
- **D-18:** The core path should not require mandatory supervision or hidden global processes.
- **D-19:** Options should be normalized and validated centrally, likely with `NimbleOptions` or an equivalent pattern.

### the agent's Discretion
- The exact names and grouping of support modules beneath the top-level `Scrypath` facade.
- The exact reflection helper set, as long as it remains small, inspectable, and consistent with the decisions above.
- The exact option schema organization and validation layout.

</decisions>

<specifics>
## Specific Ideas

- The product should feel like the missing Searchkick or Laravel Scout for Ecto and Phoenix, but translated into idiomatic Elixir rather than copied from Rails.
- The first mile should stay tiny: one obvious schema declaration, clear projection path, and simple docs ergonomics.
- Phoenix users are a primary audience, so API decisions should support strong Phoenix-facing docs and examples even though the architecture remains Ecto-first.
- Backend power should stay available through explicit escape hatches instead of pretending all search engines are equivalent.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and phase boundary
- `.planning/PROJECT.md` — Project framing, non-negotiable constraints, and locked product decisions
- `.planning/REQUIREMENTS.md` — Phase-linked requirements for schema declaration, projection, and backend foundation
- `.planning/ROADMAP.md` — Phase 1 goal and success criteria
- `.planning/STATE.md` — Current project state and persisted reference-material rules

### Search library strategy
- `prompts/search-lib-use-cases-deep-research.md` — Ecosystem gap analysis, Searchkick and Scout lessons, adapter tradeoffs, and v1 product-shape guidance

### Elixir and library design guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Public API, macro usage, configuration, supervision, and OSS library ergonomics guidance
- `prompts/elixir-best-practices-deep-research.md` — Idiomatic Elixir API and module design guidance for library authors
- `prompts/ecto-best-practices-deep-research.md` — Ecto-centered guidance relevant to schema boundaries, explicitness, and data-flow decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No implementation code exists yet; this phase is defining the initial contracts and module surface from scratch.

### Established Patterns
- Planning artifacts already lock in Meilisearch-first v1, Ecto-first architecture, Phoenix-friendly ergonomics, inline plus Oban plus manual sync modes, and explicit consultation of `prompts/` as project memory.

### Integration Points
- Phase 1 outputs should be shaped so later phases can implement Meilisearch sync, query APIs, Oban integration, reindexing, and Phoenix-facing docs without revisiting the core API model.

</code_context>

<deferred>
## Deferred Ideas

- Public multi-backend support remains deferred to later phases or later milestones.
- Advanced relevance features such as vector search, hybrid retrieval, analytics, and richer backend-native search features remain out of scope for this phase.
- Postgres-native full-text search remains outside the v1 product boundary.

</deferred>

---
*Phase: 01-core-contracts-and-api-shape*
*Context gathered: 2026-04-15*
