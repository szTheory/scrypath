# Phase 166: Host Tenant and Repair Evidence - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove one host-owned, authorized tenant-search workflow and one bounded manual repair through visible Scrypath search. Reuse the existing Phoenix path/package consumer harness and root backend service lane. Reuse the v1.39 hard-delete receipt only after relevant-path freshness comparison. Preserve the approved v1.40 boundaries: no authentication product, operator UI, new public API category, broad compatibility matrix, new required service lane, or forced release.

</domain>

<decisions>
## Implementation Decisions

### Named Phoenix host policy
- **D-01:** Extend the existing examples/phoenix_meilisearch consumer with the smallest persisted actor/membership and host-context fixture needed to prove tenant authorization. Run the same named scenario through the existing repository-path and freshly built package-artifact modes. The e-commerce demo already has tenant-aware data, but its visitor-selected URL tenant is not membership authorization and its current workflow is not the existing path/package consumer harness.
- **D-02:** Treat the test-supplied actor as a synthetic principal that has already passed authentication. The host context resolves membership from that actor, derives tenant scope itself, and rejects missing membership, forged/unowned tenant selection, and caller-controlled tenant-scope/filter overrides before Scrypath search dispatch. This proves the named host policy only; it does not prove login, sessions, production identity, or arbitrary adopter security.
- **D-03:** Keep authorization in the host context. Build Scrypath options from the verified membership and an allowlist of ordinary search inputs. Do not treat Scrypath's tenant filter as authentication or authorization.
- **D-04:** Rehydrate returned IDs through a host query scoped by both the authorized tenant and the returned ID set. Assert raw hits separately from hydrated records, counts, and requested facets; host hydration must not hide a foreign raw hit or metadata leak.
- **D-05:** Use a small mixed-tenant fixture with tenant A's allowed published record and excluded draft, plus an overlapping tenant B published positive-control record with a unique forbidden marker. Prove a valid B member can retrieve B's control, while A receives only permitted IDs and no B marker in raw hits, hydrated records, counts, or facets. Limit the claim to the deterministic fixture and configured service tuple; do not imply a general stale-index or session-authentication guarantee.

### Public facet-value follow-up
- **D-06:** Include the exact Phase 165 common-keyword-filter facet-value scenario in the named Phoenix path/package service proof. Exercise public search_facet_values/4 with the trusted tenant scope and the ordinary published-status filter against Meilisearch v1.15, then assert the expected tenant-scoped values/counts and exclusion of the other tenant's marker/value. Phase 165 reproduced and fixed the pre-HTTP serialization failure; Req.Test evidence alone does not close this live/package handoff.
- **D-07:** Reuse the existing advisory phoenix-example job and its Postgres/Meilisearch services for both dependency modes. Require the named scenario to pass on its recorded exact SHA for milestone evidence, while keeping the job advisory and avoiding a new required lane or broad matrix. A built local package artifact is not a public Hex installation or publication receipt.

### Bounded repair visibility
- **D-08:** Add the repair proof to the existing root live operator/backend integration surface using its Ecto/SQLite repository, separate from the Phoenix host tenant fixture. Establish a known missing search document while its source row remains, and keep out-of-scope and already-visible controls.
- **D-09:** Inspect the known mismatch with the no-action reconcile/report path and prove that report step causes no write. Treat the source/search comparison as the test's known precondition; do not claim reconcile itself discovers missing database rows.
- **D-10:** Bound manual backfill with an explicit Ecto where predicate over the selected IDs. A query limit or batch size is not a total repair-scope bound. Capture the exact returned task references, require terminal success for the expected index, and repeat the same Scrypath search to assert the exact repaired raw ID and projected value while excluded and already-visible controls remain correct. Repeating the same fixed ID scope once may establish bounded repeatability only; it does not establish exactly-once, concurrent-ordering, arbitrary Oban-retry, or full-reindex guarantees.

### Reuse of the deletion receipt
- **D-11:** Reuse the v1.39 C-09 hard-delete-to-raw-search receipt only after comparing the receipt source against the assessment source for relevant deletion, search, host, configuration, fixture, and workflow paths. If a relevant invalidator exists, require targeted fresh evidence or state the bounded claim as UNKNOWN. Age alone does not require a rerun; do not add package deletion proof solely because a package harness exists.

### the agent's Discretion
- Choose concrete schema/context names, fixture helpers, and the smallest Ecto query arrangement consistent with the existing Phoenix example and integration-test patterns.
- Keep the host policy scenario and root repair scenario independently executable. Reuse existing task polling, unique index prefixes, SQL Sandbox/service setup, diagnostics, and cleanup patterns.
- Keep all identities and markers synthetic. Record exact scenario, SHA, run/job, dependency mode, service tuple, and task/index IDs without secrets or environment dumps.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, requirements, and product boundaries
- .planning/ROADMAP.md — Phase 166 goal, acceptance criteria, dependency, and fixed phase boundaries.
- .planning/REQUIREMENTS.md — HOST-01, HOST-02, PKG-04, REPAIR-01, REPAIR-02, and DELETE-01 contracts.
- .planning/PROJECT.md — Ecto-first product constraints, host/library ownership, and automation-first verification policy.
- .planning/STATE.md — Approved v1.40 scope, evidence posture, and Phase 165 handoff.

### Approved v1.40 research and prior decisions
- .planning/research/v1.40/SUMMARY.md — Selected host, repair, deletion, and CI evidence strategy.
- .planning/research/v1.40/C10-C11-HOST-BOUNDARIES.md — Host authorization boundary, named fixture criteria, package proof, and conditional facet follow-up.
- .planning/research/v1.40/C16-REPAIR-VISIBILITY.md — Known-mismatch setup, read-only report boundary, ID-scoped repair, exact task, and final search oracle.
- .planning/research/v1.40/C09-DELETE-VISIBILITY.md — Existing hard-delete receipt and relevant-path freshness conditions.
- .planning/phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md — Locked public tenant/facet contracts and host-versus-library responsibility.
- .planning/phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md — Reproduced facet keyword serialization defect, compatible fix, and required live/package follow-up.

### Phoenix, Ecto, and verification patterns
- prompts/elixir-best-practices-deep-research.md — Existing Elixir API and test conventions.
- prompts/ecto-best-practices-deep-research.md — Ecto context/query and tenancy guidance.
- prompts/phoenix-best-practices-deep-research.md — Phoenix context and host-boundary guidance.
- examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex — Existing explicit host context pattern.
- examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex — Existing indexed Ecto schema and filterable status field.
- examples/phoenix_meilisearch/lib/scrypath_demo/repo.ex — Current consumer Repo boundary.
- examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs — Existing Postgres, Meilisearch, Scrypath search, and hydration scenario.
- examples/phoenix_meilisearch/test/support/data_case.ex — SQL Sandbox integration test setup.
- lib/mix/tasks/verify/phoenix_example/package.ex — Existing built-artifact staging and integration execution.
- .github/workflows/ci.yml — Existing advisory Phoenix path/package service job and lane topology.
- CONTRIBUTING.md — Canonical local/CI verification commands and evidence limits.
- test/scrypath/live_operator_verification_test.exs — Existing live operator/task verification surface for bounded repair.
- test/scrypath/backfill_test.exs — Existing Ecto query scope and backfill batch contracts.
- test/support/meilisearch_integration.ex — Existing real-service task polling and index helpers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- examples/phoenix_meilisearch uses the ScrypathDemo.Blog context, Post schema, Postgres Repo, and integration test support. Its package task runs the same consumer scenarios against the repository path and a freshly built local artifact.
- The consumer's Post schema already indexes title/body/author_name and declares status filterable; its current tenant policy and membership fixture are absent.
- The root test/scrypath/live_operator_verification_test.exs, test/scrypath/backfill_test.exs, and test/support/meilisearch_integration.ex provide task, bounded-query, real-search, and service-lifecycle patterns for repair evidence.
- examples/scrypath_ecommerce has a tenant-aware Repo/Catalog and mixed-tenant domain data, but its search UI selects tenant from URL parameters and does not establish actor membership authorization.

### Established Patterns
- Phoenix host contexts make application policy explicit; the library receives the trusted scope only after the host resolves it.
- The Phoenix consumer's SQL Sandbox setup and path/package harness are already used for service-backed tests.
- Scrypath's generic result hydration queries by returned IDs without adding the host's tenant predicate. The host response path must scope rehydration independently; it cannot replace raw-hit/count/facet assertions.
- Backend task acceptance, terminal task success, and visible results are separate observations. The repair oracle is the same Scrypath search after the exact repair task succeeds.

### Integration Points
- The host proof connects a trusted test principal and persisted membership to a Phoenix context, tenant-scoped public Scrypath search, host-scoped rehydration, and the existing path/package smoke test.
- The facet follow-up connects public search_facet_values/4 to the already-rendered tenant/status filters on the v1.15 service.
- The repair proof connects the operator read-only report, Ecto ID-scoped Scrypath.backfill/2, exact Meilisearch task polling, and same-query search in the root backend job.

</code_context>

<specifics>
## Specific Ideas

- Use the two valid principals as positive controls: tenant A's authorized search must exclude tenant B, and tenant B's authorized search must retrieve its own indexed marker.
- Caller-provided tenant selection/filter overrides must fail before backend dispatch. Assert this directly rather than relying on an empty result.
- Prove the confirmed facet keyword-filter correction through the fresh package and pinned live backend, not only through the local Req.Test contract.
- Keep C-09 receipt reuse conditional on source freshness and preserve the original receipt's narrow hard-delete claim.
- The multi-role review converged on the existing Phoenix package consumer because it satisfies both dependency modes without introducing ecommerce UI work or a new CI lane.
</specifics>

<deferred>
## Deferred Ideas

No new ideas were added. Production authentication/session proof, operator UI, broader ecommerce UI work, stale-index tenant-move guarantees, new required CI lanes, and compatibility matrices remain outside this phase.

</deferred>

---

*Phase: 166-host-tenant-and-repair-evidence*
*Context gathered: 2026-09-26*
