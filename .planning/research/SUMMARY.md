# Project Research Summary

**Project:** Scrypath
**Domain:** Ecto-native search indexing and orchestration library for Elixir/Phoenix
**Researched:** 2026-04-16
**Confidence:** HIGH

## Executive Summary

**Executive recommendation:** Scrypath's next milestone should be `v1.2: Public Release Trust and Operator Visibility`, focused on validating the first real public Hex release and adding a small, explicit operator surface for sync status, failure inspection, and recovery.

This is the right next milestone now because the research is aligned on one point: Scrypath is functionally complete for its current Meilisearch-first product boundary, but it still lacks the public release confidence and operator legibility that determine whether early adopters actually trust it in production. STACK.md and FEATURES.md both argue that the highest-leverage work is not backend breadth or richer query power, but hardening the release path, confirming package-consumer reality, and making async/manual sync states inspectable. ARCHITECTURE.md reinforces that the current public surface is already the right shape and should be kept small; the next work should deepen internal operations seams and add thin operator APIs rather than widen the top-level API. PITFALLS.md is explicit that pretending portability or hiding operational truth now would create API regret.

The recommended approach is therefore conservative and opinionated: keep Scrypath Ecto-first, Meilisearch-first, and operationally honest; ship release-confidence and operator primitives before new backend promises; and preserve a clean split between the common path (`Scrypath.*`) and backend-native power (`Scrypath.Meilisearch.*`). The main risks are public API widening, operator tooling that becomes a pseudo-dashboard, and release automation drift. The mitigation is to keep the common path narrow, keep operator tooling API-first and Mix-second, and treat release/version alignment as a product contract. The milestone recommendation itself is an inference from the combined research set, not a verbatim source position, but it is strongly supported by all four research documents.

## Why This Is The Right Next Milestone Now

Scrypath does not currently have a basic product-gap problem. Per [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md) and [PROJECT.md](/Users/jon/projects/scrypath/.planning/PROJECT.md), the library already covers schema metadata, projection, sync modes, search, hydration, backfill, reindexing, and Phoenix-friendly docs. The unresolved question is which pressure matters next under real adoption: release trust, operator depth, backend breadth, or richer backend-native power.

The research points to release trust plus operator visibility as the best next move because those two concerns directly convert internal confidence into external adoption. This recommendation is partly direct and partly inferred: FEATURES.md directly recommends a "public release trust and operator visibility" milestone; STACK.md recommends release-confidence work, capability-aware seams, and operator visibility before backend widening; ARCHITECTURE.md recommends keeping the public surface narrow while adding an operator namespace and internal operations seam; PITFALLS.md warns that both premature multi-backend abstraction and hidden operational state are critical mistakes. Taken together, the clear milestone-shaping conclusion is that `v1.2` should make Scrypath safe to adopt, not broader to market.

## Key Findings

### Recommended Stack

The stack recommendation is stable: keep the runtime core small and unsurprising with Elixir `1.17+`, OTP `26+`, Ecto, Telemetry, Req, NimbleOptions, and optional Oban. For the next milestone, the meaningful additions are not new runtime features; they are release-confidence and contract-testing tools such as `Mox`, `StreamData`, workflow linting, dependency review, protected publish environments, and a dedicated release identity. This is a direct summary of [STACK.md](/Users/jon/projects/scrypath/.planning/research/STACK.md).

**Core technologies:**
- `Elixir` / `OTP`: runtime and support window stability for OSS adoption.
- `Ecto`: primary integration surface and product identity anchor.
- `Req`: boring internal HTTP transport with no need to widen the consumer contract.
- `Telemetry`: stable observability contract required for operator trust.
- `Oban` (optional): recommended production async path without making the core queue-dependent.
- `NimbleOptions`: validated public options and backend-specific option schemas.
- `Mox` and `StreamData` (test-only): adapter contract and property coverage for future-safe seams.

### Expected Features

The next milestone should treat package trust and operator clarity as table stakes for public adoption, not as optional polish. [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md) argues that the functional search core is already there; what early adopters need next is a verified public release path, excellent install-to-first-index docs, sync status visibility, failure inspection, retry/reconcile flows, and explicit operational guidance.

**Must have (table stakes):**
- Verified real Hex publish path with publisher-scoped credentials and post-publish smoke validation.
- HexDocs-first install flow and compatibility/support policy.
- Status visibility for queued and manual indexing workflows.
- Failed work inspection plus retry and reconcile entry points.
- Production guides for inline vs Oban vs manual sync, reindexing, and recovery.

**Should have (competitive):**
- Thin operator APIs and Mix tasks that answer "is search caught up?" and "what failed?"
- Stable telemetry event schema and operator-facing structured results.
- Clear backend-native escape hatch examples for power users without widening the common path.

**Defer (later):**
- Second public backend support.
- A universal backend-agnostic advanced query DSL.
- Richer first-class backend-native search features as the milestone headline.
- Built-in dashboard/UI dependencies, vector/hybrid search, and analytics-style features.

### Architecture Approach

The architecture recommendation is to preserve the current shape and deepen the seams that support release and operator workflows. [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md) recommends keeping `Scrypath.*` small and Ecto-first, keeping `Scrypath.Meilisearch.*` as the explicit native power lane, extracting a clearer internal operations/admin seam for lifecycle and task inspection, and adding a public operator namespace backed by structs, telemetry, and thin Mix wrappers.

**Major components:**
1. `Scrypath.*` common path: schema metadata, projection, sync dispatch, and common search/hydration.
2. Internal backend/admin operations layer: lifecycle, task inspection, reindex orchestration, and capability-aware indirection.
3. `Scrypath.Meilisearch.*`: explicit backend-native read/write/search power kept out of the generic path.
4. `Scrypath.Operator.*`: status, reindex inspection, backfill/reconcile, and task/result structs.
5. `Mix.Tasks.Scrypath.*`: CLI ergonomics only, with workflow logic staying in library modules.

### Critical Pitfalls

The risk profile is unusually coherent across the research. The severe mistakes are about API honesty and operations, not missing features.

1. **Premature public multi-backend abstraction** — Keep `Scrypath.Backend` internal, define the common-path contract narrowly, and do not turn future backend work into a public promise yet. Source: [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).
2. **Hiding operational truth behind a magical happy path** — Keep sync mode tradeoffs, lag, delete semantics, and reindex/recovery states explicit in docs, telemetry, and APIs. Source: [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).
3. **Release/version drift between tags, `mix.exs`, Hex, and automation** — Treat the first public release as a product event, add release invariants, and document failure recovery. Source: [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).
4. **Operator tooling that becomes a dashboard product** — Keep the operator story API-first and Mix-second, not UI-first. Source: [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).
5. **Leaking backend-native power into the common query API** — Keep advanced Meilisearch features explicitly namespaced until they prove they belong in the shared path. Source: [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).

## What To Include In v1.2

The recommended `v1.2` scope is:

1. Validate one real tagged/public Hex release end to end.
2. Harden release automation and maintainer release docs.
3. Add a first-class operator surface for status, failed work inspection, retry, and reconcile.
4. Refactor internals so sync/reindex/operator flows depend on an internal operations seam rather than reaching directly into Meilisearch task internals.
5. Publish opinionated guides for sync mode choice, rollout, reindexing, and recovery.

Concretely, that implies:

- protected publish environment and publisher-scoped `HEX_API_KEY`
- dedicated release identity for Release Please downstream behavior
- release smoke verification from a clean consumer app
- telemetry event contract treated as semver-relevant once documented
- `Scrypath.Operator.*` APIs and thin `mix scrypath.*` tasks
- operator result structs for status, task refs, and reindex/backfill summaries
- explicit retry/reconcile/status flows for Oban and manual sync modes

This section is an inference from the combined research, but every item is directly supported by at least one of [STACK.md](/Users/jon/projects/scrypath/.planning/research/STACK.md), [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md), or [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md).

## What To Defer To Later

Later milestones should handle:

- second public backend support, only after real adoption pressure exists
- public multi-backend positioning or plugin-style adapter promises
- richer first-class Meilisearch-native search power as a milestone theme
- dashboard-style operator UI helpers or separate ops packages
- vector, hybrid, semantic, analytics, or recommendation features

This deferral is direct from [STACK.md](/Users/jon/projects/scrypath/.planning/research/STACK.md), [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md), and [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).

## Architecture Posture To Preserve

- Keep the public common path small, function-heavy, and Ecto-first.
- Preserve Meilisearch as the public v1 backend target.
- Keep the adapter seam internal and capability-aware, not user-extensible.
- Keep backend-native power in explicit `Scrypath.Meilisearch.*` modules.
- Keep operator tooling library-first, struct-based, and telemetry-backed.
- Keep the core mostly functional; do not add mandatory supervision or process-heavy runtime machinery.

This posture is directly grounded in [STACK.md](/Users/jon/projects/scrypath/.planning/research/STACK.md) and [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md).

## DX/UX Posture For Elixir/Ecto/Phoenix Users And Maintainers

For users, the posture should be: minimal setup, explicit sync-mode choice, clear install-to-first-index docs, and no illusion that search consistency is magical. For Phoenix teams, the best experience is still "copy a small amount of code, get productive fast, and understand the tradeoffs." For Ecto users outside Phoenix, the library should remain usable without dragging Phoenix assumptions into the core.

For maintainers, the posture should be: release engineering is product work, operator state is part of the contract, and docs should answer operational questions before support issues do. This is partly direct from the research and partly inference from the project constraints in [PROJECT.md](/Users/jon/projects/scrypath/.planning/PROJECT.md).

## Release/Versioning Guidance

Stay on the current support floor unless real compatibility pressure appears: Elixir `1.17+`, OTP `26+`, Ecto `3.13+`. Keep Scrypath pre-`1.0` until the first real public release and early feedback confirm that the release path, operator surface, and Meilisearch-native boundaries are stable. Recommend naming the next milestone `v1.2`, but keep the package semver under `0.x` if that is the repo's actual published state; the milestone name should describe the product increment, not force a premature semver promise. This version-shape guidance is an inference from the research because the source docs discuss milestone naming and release discipline more strongly than exact package semver.

Versioning rules to adopt now:

- treat telemetry event names and documented metadata keys as semver-relevant once public
- treat operator structs and Mix task output contracts as public only after they are documented
- keep advanced Meilisearch-native APIs additive and namespaced
- do not let tag, changelog, `mix.exs`, and Hex package versions drift

## Implications For Roadmap

Based on the combined research, the recommended next milestone is:

**Milestone name:** `Public Release Trust and Operator Visibility`
**Version suggestion:** `v1.2` milestone label, with package semver staying pre-`1.0` unless the first public release is already on `1.x`

Suggested phase structure:

### Phase 1: Public Release Contract
**Rationale:** This must come first because public package reality is the current gating unknown.  
**Delivers:** Verified release path, protected publish environment, release identity choice, smoke verification, version invariants, maintainer runbook.  
**Addresses:** release confidence and compatibility table stakes from FEATURES.md.  
**Avoids:** release/version drift from PITFALLS.md.  
**Research flag:** likely skip extra research; the patterns are already well-documented.

### Phase 2: Internal Operations Seam
**Rationale:** Operator features should not be built on direct Meilisearch internals if Scrypath wants to preserve a future backend seam.  
**Delivers:** internal admin/capability layer for lifecycle and task inspection, `Sync`/`Reindex` refactors, contract tests.  
**Uses:** Mox, StreamData, Telemetry, existing backend seam.  
**Avoids:** premature public backend abstraction and Meilisearch leakage into shared orchestration.  
**Research flag:** may need targeted phase research for exact callback/capability shape.

### Phase 3: Operator Primitives
**Rationale:** Once the internal seam exists, the library can expose a durable operator surface without baking in backend-specific details.  
**Delivers:** `Scrypath.Operator.*` modules, task/status/reindex structs, retry/reconcile/status APIs.  
**Addresses:** operator visibility, failure inspection, and recovery table stakes.  
**Avoids:** turning Scrypath into a dashboard product.  
**Research flag:** likely needs targeted research around operator API naming and telemetry contract shape.

### Phase 4: Mix Tasks And Guides
**Rationale:** CLI ergonomics and docs should sit on top of the operator APIs, not drive them.  
**Delivers:** thin `mix scrypath.*` tasks, install guide refresh, sync mode guide, rollout guide, reindex/recovery guide.  
**Addresses:** Phoenix/Ecto DX and maintainer UX.  
**Avoids:** magical behavior and docs that overpromise consistency.  
**Research flag:** skip extra research; this is standard packaging/doc work.

### Phase 5: Post-Release Feedback Checkpoint
**Rationale:** The research is clear that breadth decisions should follow adoption evidence, not precede it.  
**Delivers:** criteria for choosing the next milestone between backend breadth and richer Meilisearch-native power.  
**Addresses:** the active milestone question in PROJECT.md.  
**Avoids:** roadmap drift into hypothetical demand.  
**Research flag:** yes, this phase should explicitly use `/gsd-research-phase` if there is real user pressure for either direction.

### Phase Ordering Rationale

- Release trust comes before everything because it creates the first real external signal.
- Internal operations work comes before operator APIs so the public operator surface does not depend on private Meilisearch assumptions.
- Operator APIs come before Mix tasks and docs so user-facing ergonomics rest on stable library contracts.
- Post-release feedback comes last because only then should Scrypath choose between breadth and deeper backend-native power.

## Why Not Choose Backend Breadth Now

Backend breadth is the wrong next milestone because it increases the test matrix, docs surface, and API pressure before Scrypath has public adoption evidence. More importantly, the research shows that the current architecture still contains Meilisearch-shaped operational assumptions in sync and reindex flows. Adding a second backend now would force either a fake portability layer or a rushed internal redesign. This is a direct conclusion from [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md) and [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md).

## Why Not Choose Richer Backend-Native Power Now

Richer Meilisearch-native power has real value, but it is not the highest-leverage milestone because it mostly helps once teams already trust installation, synchronization, and recovery. If Scrypath promotes advanced native search power before release trust and operator clarity are settled, it will improve demo appeal more than adoption safety. The research supports keeping this work explicitly namespaced and deferring it as a headline milestone until early adopters show that query power is the next bottleneck. This is direct from [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md) and [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md), with the prioritization itself inferred from the combined set.

## Risk Register

1. **Risk:** Release automation and published artifact drift undermine trust.
   **Mitigation:** Add release invariants, protected publish environment, smoke verification, and maintainer recovery docs.

2. **Risk:** Operator tooling bakes in Meilisearch and Oban specifics too early.
   **Mitigation:** Introduce a Scrypath-level operations seam and operator vocabulary before public status APIs.

3. **Risk:** Pressure for backend breadth or richer native power widens the common path prematurely.
   **Mitigation:** Keep the common-path contract narrow, keep backend-native features namespaced, and use post-release demand to choose the next expansion.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strongly supported by official-tooling-oriented research and consistent with project constraints. |
| Features | HIGH | Strong convergence around release trust and operator visibility as the next adoption lever. |
| Architecture | HIGH | Grounded in the current codebase shape and specific module boundary recommendations. |
| Pitfalls | HIGH | The same failure modes recur across comparable libraries and map cleanly onto Scrypath. |

**Overall confidence:** HIGH

### Gaps To Address

- Real adoption pressure is still unknown; backend breadth vs native-power sequencing after `v1.2` should follow actual user demand.
- Exact operator API naming, result shapes, and semver posture need phase-level planning before implementation.
- Exact package semver recommendation depends on whether the first public release is still pre-`1.0` at execution time.

## Sources

### Primary (HIGH confidence)
- [PROJECT.md](/Users/jon/projects/scrypath/.planning/PROJECT.md) — current project goals, constraints, and active milestone questions
- [STACK.md](/Users/jon/projects/scrypath/.planning/research/STACK.md) — runtime, release, backend, and operator stack recommendations
- [FEATURES.md](/Users/jon/projects/scrypath/.planning/research/FEATURES.md) — table stakes, differentiators, and milestone comparison
- [ARCHITECTURE.md](/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md) — component boundaries and API posture
- [PITFALLS.md](/Users/jon/projects/scrypath/.planning/research/PITFALLS.md) — critical failure modes and prevention strategies

### Secondary (from cited research files)
- Hex publishing and release docs
- GitHub Actions and Release Please docs
- Meilisearch and Typesense official docs
- Searchkick, Laravel Scout, Meilisearch Rails, and related ecosystem references

---
*Research completed: 2026-04-16*
*Ready for roadmap: yes*
