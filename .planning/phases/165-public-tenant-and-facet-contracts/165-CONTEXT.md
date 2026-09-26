# Phase 165: Public Tenant and Facet Contracts - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Reproduce Scrypath's existing public tenant-scope and facet-value input contracts. The supported tenant paths are `search/3`, `search_many/2`, and `search_facet_values/4`; tenant scope must compose with ordinary filters, while undeclared tenant scope and conflicting tenant filters fail before backend dispatch. Public facet-value defaults and documented keyword filters must produce a Meilisearch v1.15-valid request. Correct only reproduced, compatible failures in these existing contracts. This phase does not add tenant authorization, new API semantics, backend support, broad service/version coverage, a new CI lane, or a forced release.
</domain>

<decisions>
## Implementation Decisions

### Existing public contract boundaries
- **D-01:** Treat the approved v1.40 requirements as fixed. Exercise the named public API paths and inputs; do not expand Phase 165 into an API redesign or a general facet/settings compatibility matrix.
- **D-02:** `tenant_scope:` is a Scrypath filter-composition input, not an authorization mechanism. For a schema with a declared tenant field, it must compose with ordinary filters. A collision with that tenant field or a tenant scope on a schema without a declared tenant field must fail before backend dispatch. Host authentication, membership, trusted tenant selection, and database response scoping remain host-owned.
- **D-03:** Validate facet-value behavior from `search_facet_values/4`'s public boundary. Its supported defaults and documented keyword filters must reach the Meilisearch v1.15 facet-search endpoint in a valid request shape; a lower-level client test with already-rendered parameters alone is insufficient evidence for the public contract.

### Evidence and compatible correction
- **D-04:** C10-R1 and C11-R1 are source-backed hypotheses, not confirmed defects. Keep a reproduced behavior, a successful contract reproduction, and missing evidence distinct. Do not label either hypothesis a defect or pass until the corresponding public-entry probe establishes its behavior.
- **D-05:** Use the smallest deterministic proof that observes the boundary: a recording backend for tenant composition/rejection and Req.Test for public facet request construction and supported error behavior. Keep the tenant and facet probes independently executable so one cannot mask the other. Use live/package service proof only if a reproduced compatible facet defect makes it decision-relevant to Phase 166.
- **D-06:** If a supported contract failure is reproduced, make only the compatible correction needed to restore the existing contract and add a focused regression. Preserve established error and raising behavior unless a separately justified compatibility decision is required. Do not add a broad property suite, new required CI lane, routine human UAT, or broad matrix without concrete decision value.
- **D-07:** Do not repeat the v1.40 ecosystem survey. The approved research already recommends minimal public-entry probes; reopen research only if reproduction reveals a concrete compatibility question or an important adopter workflow that changes the approved boundary.

### the agent's Discretion
- Choose the smallest readable test arrangement that proves the specified public inputs and observable backend/request outcomes, reusing existing test helpers and verification lanes.
- Add property-based coverage only if implementation exposes a concrete input invariant for which generated cases add meaningful confidence beyond the named boundary examples.
- Record any Phase 166 facet-service implication as conditional on Phase 165's actual result; do not infer a package/service requirement from a historical opt-out alone.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and product constraints
- `.planning/ROADMAP.md` — Phase 165 goal, success criteria, and boundaries between Phases 165–167.
- `.planning/REQUIREMENTS.md` — locked API-01/API-02 contracts, milestone exclusions, and requirement traceability.
- `.planning/PROJECT.md` — Ecto-first public product constraints, Meilisearch v1 target, and automation-first verification policy.
- `.planning/STATE.md` — approved v1.40 scope, evidence posture, and phase handoff.

### Approved evidence and technical guidance
- `.planning/research/v1.40/SUMMARY.md` — v1.40 evidence synthesis, Phase 165 acceptance, test-layer choices, and explicit research limits.
- `.planning/research/v1.40/C10-C11-HOST-BOUNDARIES.md` — C10-R1/C11-R1 source hypotheses, smallest reproduction probes, and host/library claim boundaries.
- `.planning/reference/QUALITY-LEDGER.md` — prior test-value and lean-CI decisions; use only where relevant to proof cost.
- `prompts/elixir-best-practices-deep-research.md` — Elixir library API and developer-ergonomics guidance.
- `prompts/ecto-best-practices-deep-research.md` — Ecto boundary and composition guidance relevant to public consumer inputs.
- `prompts/elixir-search-lib-deep-research.md` — historical ecosystem research only; its older backend recommendation is superseded by the current project stack and is not a Phase 165 decision.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Options.Search.validate/4` in `lib/scrypath/options/search.ex` already performs schema-aware filter/facet validation and tenant-scope injection.
- `test/scrypath/options_test.exs`, `test/scrypath/search_test.exs`, and `test/scrypath/search_many_test.exs` are existing homes for option and public search-path contracts.
- `test/scrypath/meilisearch/client_test.exs` exercises the Meilisearch facet-search client; use the public-path boundary as well when proving keyword option handling.

### Established Patterns
- `Scrypath.Search.Single`, `Scrypath.Search.Many`, and `Scrypath.Search.FacetValues` resolve runtime configuration before invoking the configured backend; their runtime-option extraction is a key seam for the tenant probe.
- Search options are validated against declared schema metadata before composing filters. Existing collision and undeclared-field failures are explicit public behavior; preserve their observed return/error shape.
- `Scrypath.Meilisearch.Client.facet_search/5` maps top-level option keys and merges the endpoint's base fields. The C11-R1 concern is specifically about public common-filter rendering/defaults, which the existing lower-level client test may bypass.

### Integration Points
- Public functions `Scrypath.search/3`, `Scrypath.search_many/2`, and `Scrypath.search_facet_values/4` connect option validation, runtime configuration, and backend calls.
- The tenant contract connects `Scrypath.Options.Search` to the single-search, multi-search, and facet-values runtime paths.
- The facet-value contract connects `Scrypath.Search.FacetValues`, the configured backend callback, and `Scrypath.Meilisearch.Client.facet_search/5` / Req.Test.

</code_context>

<specifics>
## Specific Ideas

- The existing research identifies a possible runtime-option leak for tenant scope and a possible mismatch between common keyword filters and the Meilisearch facet-search request. Both remain unverified until public entry points are exercised.
- Keep evidence claim-bounded: a recording backend or Req.Test proves library request composition, not host identity, authorization, or live backend behavior.
- UI and visual design are not applicable to this API-contract phase.
</specifics>

<deferred>
## Deferred Ideas

None added. Authentication and tenant-policy products, broad facet/settings or backend-version matrices, public backend abstraction, operator UI, new required CI lanes, and forced publication remain outside the approved milestone scope.
</deferred>

---

*Phase: 165-public-tenant-and-facet-contracts*
*Context gathered: 2026-09-26*
