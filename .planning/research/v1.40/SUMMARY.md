# Scrypath v1.40 Research Summary

**Proposed milestone:** v1.40 — Readiness Evidence Closure  
**Domain:** Ecto-native search synchronization, tenant-scoped consumption, and operational proof  
**Research date:** 2026-09-26  
**Source checkout:** `6e61380555361b6bb03c07a7f0f7c2a944ef960d`  
**Overall confidence:** MEDIUM  
**Status:** Recommendation for requirements and roadmap; no readiness decision or implementation result.

## Executive Summary

Scrypath's next useful increment is a small milestone that establishes whether representative adopters can safely search tenant-owned data and recover a missing search document through existing APIs. Recommend three phases: classify two concrete public-entry risks and correct confirmed contract failures within the existing API; prove the selected host and repair workflows using existing service harnesses; then publish a fresh, timestamped readiness assessment with precise release and cleanup evidence. This advances adopter confidence and may repair existing functionality. It earns a milestone because the work crosses public API contracts, a packaged Phoenix consumer, real backend visibility, and a six-condition readiness decision. Condition 6 bookkeeping alone would fit a quick task.

The research materially reduces the scope. C-09 already has a successful exact-SHA deletion receipt: reuse it with source freshness checks. C-16 needs one bounded missing-document recovery scenario in the existing required backend lane. C-10 needs a clear distinction between Scrypath preserving a supplied tenant filter and the host authenticating and authorizing a principal. C-11 needs inexpensive public facet-input reproduction before committing to a live regression; historical endpoint opt-outs alone do not justify a feature matrix. The suspected tenant runtime-option and facet serialization failures are source-backed hypotheses, not reproduced defects.

The main risk is declaring a broader guarantee than the oracle establishes. Backend acceptance, terminal task success, raw search visibility, database hydration, host policy, package loading, and published release identity are separate facts. Keep that separation in acceptance and documentation. Preserve the historical v1.39 NOT READY/UNKNOWN assessment, allow a new assessment to remain NOT READY if evidence warrants it, and do not automatically start operator UI work after a pass. No tests, services, CI dispatches, or implementation changes were performed during this research.

## Research Inputs and Evidence Vocabulary

The four inputs intentionally follow readiness claims rather than generic stack/features headings:

| Report | Main contribution |
|---|---|
| [C-09 deletion visibility](C09-DELETE-VISIBILITY.md) | Existing successful raw-hit deletion receipt, reusable without a new service case |
| [C-16 repair visibility](C16-REPAIR-VISIBILITY.md) | Smallest new real-service repair oracle and exact limits |
| [C-10/C-11 host boundaries](C10-C11-HOST-BOUNDARIES.md) | Public-entry hypotheses, host policy ownership, conditional package proof |
| [Condition 6 reassessment](CONDITION-6-REASSESSMENT.md) | Historical/current source identities, publication truth, metadata debt, cleanup and closeout boundaries |

**Observed fact** means source or hosted evidence inspected by the named researcher. **Inference** connects those observations and can be disproved. **Recommendation** describes prospective work. All four reports retain MEDIUM confidence from their research classifier; synthesis does not upgrade it. Their exact evidence links and limitations remain authoritative for individual claims.

## Key Findings

### Jobs and ownership

| Consumer and situation | Input and action | Useful outcome | Owner of the boundary |
|---|---|---|---|
| Phoenix feature owner removes a searchable record | Existing tenant/schema identity, explicit context deletion and synchronization | Known target disappears from raw search while sibling remains | Host DB operation; Scrypath synchronization; Meilisearch execution |
| Operator knows one source row is missing from search | Known source/search mismatch, read-only report, explicit ID selection and backfill | Same query returns exact repaired ID and projected value without repairing unrelated rows | Operator selects remedy; Scrypath scopes/submits repair; backend executes |
| SaaS developer implements member search | Trusted principal/membership, allowlisted user filters, configured tenant field | Authorized tenant's records and metadata only | Host identity/policy/hydration; Scrypath supplied-filter composition |
| Maintainer decides readiness or release | Source SHA, scenario receipts, support and package identities, owned-resource inventory | Auditable decision with no hidden pending work | Maintainer assessment and existing closeout protocol |

### Recommended stack and architecture

Retain Elixir, Ecto, optional Oban, Req.Test, the existing internal Meilisearch seam, and Meilisearch v1.15 proof target. Use recording backends and Req.Test for public option/request contracts; root Ecto/SQLite integration for the one bounded repair; existing Phoenix/Postgres path-and-package harness for the named host consumer. No dependency or support-floor change is needed. Current upstream documentation does not certify newer backend versions.

Use explicit functions and context boundaries: authenticate/authorize in the host, derive trusted tenant scope, allowlist caller input, pass the scope to Scrypath, await the operation's actual task where the claim needs completion, then inspect the relevant result. Do not introduce ORM callbacks, a new policy framework, public backend abstraction, or a generalized evidence engine. A query `limit` is not a repair bound: backfill removes it, so the selected IDs must appear in an Ecto `where` predicate.

### Claim dispositions

| Claim | Observed fact | Recommended action and acceptance boundary |
|---|---|---|
| C-09 | Full advisory E2E scenario passed at `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`, first attempt; endpoint maps raw `result.hits`; sibling survives | Preserve sanitized receipt and reuse after checking relevant source invalidators. Claim this source-backed hard-delete/Oban example only |
| C-16 | Current report test stops before repair; mounted retry is conditional and does not prove repaired search | Add one missing-document → report → ID-scoped manual backfill → exact task success → same-query raw ID/value scenario in existing backend lane |
| C10-R1 | Tenant option injection tests stop before runtime extraction; three runtime extractors appear to retain `tenant_scope` for runtime validation | Reproduce through public API with recording backend before declaring a bug. If confirmed, minimally restore existing composition contract and cover distinct affected entry paths |
| C-10 host | Ecommerce's visitor-selected tenant demonstrates filtering, not membership authorization; generic hydration does not inject tenant policy | Use one explicit trusted-principal/membership context fixture; reject missing/forged tenant inputs before search; verify raw and returned data boundaries |
| C11-R1 | Public facet options reach a client with top-level key conversion but no common-filter rendering; lower-level test bypasses public input | Reproduce keyword filter and default request through Req.Test. If confirmed, correct existing endpoint contract and add one tenant-filtered package/service regression |
| C-11 remaining | Settings readback, facet values, and multi-search have distinct package opt-outs | Include only settings needed by selected host job, read back their subset, and disposition other operations individually. Native federation requires its own named job to justify expansion |
| Condition 6 | Archived closeout now exists; current research HEAD has no matching hosted run; actual package tag differs from some release-reference text | Separate timestamped assessment, source identities, current owned cleanup, explicit metadata debt and tag-reference disposition; obey final-SHA closeout for new work |

## Options and Tradeoffs

| Approach | Advantage | Limitation/cost | Decision |
|---|---|---|---|
| Reuse exact historical receipt with freshness analysis | Zero duplicate service execution; strong existing scenario evidence | Only establishes the recorded source/tuple/claim; artifact retention is finite | Choose for C-09 and archived closeout/publication evidence |
| Public-entry fake/HTTP contract | Cheap, deterministic, pinpoints supplied input to observable output | Cannot prove real backend behavior or host identity | Choose first for C10-R1/C11-R1 and error edges |
| Narrow root live integration | Real task and search behavior with small existing infrastructure | SQLite and checkout proof; no Phoenix/package/Oban replay claim | Choose for representative C-16 backfill |
| Existing Phoenix packaged consumer | Real host composition and built artifact on Postgres/Meilisearch | Runs in path and package modes; advisory lane needs explicit scenario result | Choose for one tenant-member workflow and conditional facet regression |
| New browser/matrix/generalized digital twin | Could exercise additional selected seams | More setup and maintenance; synthetic model may encode the same assumptions; no new UI job needs it | Defer unless a concrete uncovered boundary changes the decision |
| Documentation-only narrowing | Honest and inexpensive for noncritical/unselected features | Cannot erase a confirmed supported API failure or prove missing recovery | Use for explicit residual boundaries, never as substitute for a failed important operation |

## Implications for Roadmap

### Proposed Phase 165: Public search contract classification

**Rationale:** Cheap public-entry reproduction determines whether there is product correction work before expensive consumer proof. It prevents service failures from being confused with host authorization problems.

**Delivers:** Executable classification of C10-R1 and C11-R1; minimal compatible corrections only when reproduced; documented claim/fixture choices for the next phase. Keep the two probes independently executable because one can mask the other.

**Acceptance:** Public tenant search reaches the recording backend with tenant and ordinary narrowing filter; collision and undeclared tenant fail before dispatch. Cover distinct facet/multi runtime extraction paths only where needed. Public facet defaults and keyword filter reach Req.Test with an endpoint-valid rendered payload. Check both request construction and supported error behavior. Preserve existing error/raising contracts unless a separate compatibility decision is justified.

**Decision gates:** A passing probe closes the hypothesis without manufacturing a change. A reproduced failure warrants a bounded existing-contract fix and regression. If the remedy requires new API semantics, architecture, or broader authorization, return to scope decision with evidence. Facet service proof becomes required if its supported public operation is confirmed broken; otherwise keep it conditional on the selected vocabulary job. No tests have yet classified either hypothesis.

### Proposed Phase 166: Representative tenant and repair outcomes

**Rationale:** Once input contracts are trustworthy, prove the two missing consumer outcomes at their cheapest credible real boundary. Host and repair workstreams can proceed independently in their existing fixtures; they should not share a new abstraction solely to reduce test lines.

**Delivers:** One representative member-search case in the existing Phoenix package harness, one bounded root live recovery case, and the durable reused C-09 receipt. Include a facet-value service case only under Phase 165's decision gate.

**Tenant acceptance:** Explicit trusted actor/membership scopes a context operation. Missing scope, invalid membership, forged tenant and caller overrides are rejected before search. Seed tenant A allowed published row, A excluded draft, and tenant B overlapping published row with a unique marker. Establish B is indexed and a legitimate B principal can retrieve it; authorized A results contain only the allowed A IDs and no B marker in every output the context exposes, including raw hits/counts/requested facets. Configure the required tenant/status attributes, await exact settings tasks, and read back that subset. Use host-scoped reloading for a database-authorization claim and reject stale hits whose row moved tenants; otherwise explicitly limit generic hydration proof to stable, correctly projected rows. Synthetic principal injection does not prove real authentication/session security. Add Plug/ConnCase proof only if an HTTP boundary is actually claimed.

**Repair acceptance:** Establish A and C searchable, remove A from the index while preserving its source, and leave B source-only/outside scope. Confirm A/B absent and C present through the affected query. Run reconcile without an action; verify report/index and unchanged absence, reusing existing fast no-write contracts. Reconcile is not a source-row diff detector. Backfill `where id in ^[A.id]` in manual mode; require exactly one record/batch, capture exact task UID, await `succeeded` on expected index, repeat the same search, and assert raw A ID/projected value, B absence, C unchanged. Repeat that fixed-scope upsert once to establish bounded repeatability, not global ordering. Existing deterministic tests cover failure/canceled/malformed/transport/deadline outcomes. Use unique indexes, existing serialized repository pattern, bounded monotonic polling, sanitized diagnostics and teardown.

**Deletion acceptance:** Preserve run/job/SHA/artifact digest, retry 0, scenario result and raw-hit source rationale from C-09. Compare relevant delete/search/host/configuration/fixture/workflow paths against final assessment source. A relevant invalidator requires focused fresh evidence or UNKNOWN. Do not add package deletion solely because that harness exists.

### Proposed Phase 167: Timestamped readiness and closeout reconciliation

**Rationale:** Readiness depends on the completed evidence and dispositions from the earlier phases. Reconciliation alone cannot establish the missing product outcomes.

**Delivers:** Separate uniquely identified assessment with UTC cutoff, current source identity and evidence dates; current posture links; explicit residual claim limits and debt ownership; final task-owned cleanup and required closeout.

**Acceptance:** Preserve historical Phase 164 assessment unchanged. Bind archived v1.39/tag/run to its exact SHA; identify Hex 0.3.13 by its actual package release tag and publication/parity receipts. Refresh named source invalidators and current support facts. Verify/disposition the observed `vX.Y.Z` versus `scrypath-vX.Y.Z` documentation/source-link mismatch; no retag/republish follows from it. Record Phase 163 validation normalization, Phase 164 validation evidence mapping, and summary requirement cross-reference debt as evidence-backed cleanup or explicit carry-forward with responsibility/revisit trigger. Inventory only task-owned branch/worktree/services/temp/generated output and preserve unrelated state. Assess all six conditions independently; PASS requires all six and no gate-rank finding. Keep current-task final verification pending until the existing exact-final-SHA protocol completes, and avoid editing tracked artifacts afterward merely to record the external receipt.

### Ordering and research flags

165 precedes tenant/facet service work; C-16 and C-09 preservation can proceed independently after scope selection. 167 consumes all dispositions and receipts. Three phases keep contract diagnosis, real consumer proof, and decision/closeout separately reviewable without creating one phase per historical claim.

No additional broad ecosystem research is recommended. Phase 165 needs execution of the minimal probes, not another opinion survey. Phase 166 needs fixture-level planning for trusted membership, host hydration, task identity and existing harness isolation. Phase 167 needs fresh read-only receipt/source/cleanup observations. Reopen research only for an actual reproduced incompatibility or newly selected user job.

## Cross-Cutting Lessons and Design Boundaries

Elixir/Ecto/Phoenix ergonomics favor explicit host contexts and trusted scope arguments, small functions with stable result/error contracts, and visible ownership of synchronization. Ecto.Multi can compose database mutation and durable enqueue; external indexing does not become rollback-safe inside that transaction. Oban manual testing proves persisted enqueue/control execution where inline testing does not; neither controlled drain nor uniqueness promises production scheduling or exactly-once ordering.

The maintained integration precedents support specific lessons: Meilisearch Rails captures IDs for deletion after a record disappears; Scout distinguishes application queueing from backend asynchrony and warns against post-retrieval ORM filtering as engine filtering; Searchkick separates raw and loaded results and isolates live search tests; Hibernate Search distinguishes applied changes, durability and visibility. Borrow these boundaries and selective proof, without importing their callbacks, backend-specific refresh operations, or feature breadth. Sources appear below and in the individual reports.

For security and least surprise, tenant entry overrides remain a host allowlisting/authentication boundary. A shared multi-search tenant option is not immutable against untrusted per-entry options. Projection correctness and database reload policy remain host responsibilities; removing hydrated records cannot erase leaked raw hits, counts, or facet values. Use synthetic tenants and forbidden markers; diagnostics must omit credentials, authorization headers and real user data.

For performance and reliability, preserve bounded queries/repairs, explicit task deadlines, and small corpora; measure before changing CI topology. For maintainability, extend existing helpers only when needed by a real shared invariant; avoid tautological fake search assertions. For documentation and DX, state the user's outcome and exact remaining operational limits in runbooks. Accessibility, visual design, dark/light modes and brand are not deliverables because no UI is scoped. No browser or UX redesign is needed to prove these library jobs. Local `prompts/` research informed these principles through the four reports; current code/support policy overrides older Typesense-first or speculative API proposals.

## CI Economics and Evidence Contract

Reuse existing fast, backend-required and Phoenix path/package jobs; preserve advisory lane posture. Milestone acceptance still requires the particular relevant advisory scenario to pass on its recorded candidate/final SHA. Do not multiply synchronization modes or version matrices for input serialization. Do not rerun the broad E2E solely to rediscover the C-09 receipt when its relevant source remains unchanged.

The inspected v1.39 run observed backend 26s, Phoenix example 1m38s, required mounted 3m47s and full E2E 8m32s; deletion itself took 1.222s. These are one-run elapsed measurements, not marginal cost estimates, billed minutes, baselines or flake rates. Measure new scenario duration and job delta during execution. Keep artifact size/retention and diagnosis time visible. A final required closeout for new work is distinct from unnecessary rerunning of old claim evidence.

Every new service receipt must include exact SHA/run/job/attempt, named scenario and pass/skip status, dependency mode, service tuple and available image/version identity, command and bounded oracle. Record task/index/selected IDs where needed without sensitive payloads. A skipped integration case, aggregate green badge, arbitrary succeeded task or hydration-only result cannot pass its claim. Research ran no tests; all prospective acceptance remains unexecuted.

## Confidence Assessment and Remaining Gaps

| Area | Confidence | Limit |
|---|---|---|
| Existing deletion and archived closeout evidence | MEDIUM overall; exact observations itemized in reports | Relevant-path freshness and artifact availability must be reevaluated at assessment |
| Public entry risks | MEDIUM source-backed hypotheses | No executable reproduction yet; no defect/pass claim |
| Proposed repair architecture | MEDIUM | Existing components fit; combined scenario not executed |
| Host/package proof | MEDIUM | Named policy fixture and hydration response boundary need implementation planning |
| Ecosystem lessons | MEDIUM | Official documents are design evidence, not Scrypath execution receipts or support upgrades |
| Current readiness | Undecided | Conditions 3/6 and final current-task receipt require new assessment |

Hard exclusions: operator/admin UI, brand work, authentication product, browser-direct tenant tokens, public backend abstraction, generalized federation, exhaustive endpoint/package matrices, production latency/SLA, arbitrary retry/reindex recovery, concurrent ordering/exactly-once, and forced release. Confirmed compatible runtime fixes may warrant a patch release under the existing release train; proof/docs alone do not force one. Release identity remains separate from milestone v1.40.

The milestone can complete with a truthful NOT READY decision if a residual condition remains unknown and its disposition is explicit. It cannot complete by silently narrowing away a confirmed important supported-operation failure. Research does not authorize implementation or resolve subjective trust gates; the orchestrator uses this recommendation to define the concrete milestone scope.

## Sources

Evidence and primary-source links were collected by the four reports on 2026-09-26; this synthesis introduces no independent live verification.

- [Exact v1.39 run 36257182675](https://github.com/szTheory/scrypath/actions/runs/36257182675), [deletion job 108446076619](https://github.com/szTheory/scrypath/actions/runs/36257182675/job/108446076619), [E2E artifact 10910932671](https://github.com/szTheory/scrypath/actions/runs/36257182675/artifacts/10910932671): raw-hit deletion and archived closeout. C-09 report preserves artifact/report digests and scenario result.
- [Publication monitor 36224458339](https://github.com/szTheory/scrypath/actions/runs/36224458339), [Scrypath 0.3.13 release](https://github.com/szTheory/scrypath/releases/tag/scrypath-v0.3.13), [Hex package API](https://hex.pm/api/packages/scrypath): dated publication/parity facts, distinct from planning tags.
- [Meilisearch asynchronous operations](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations), [facet-value API](https://www.meilisearch.com/docs/reference/api/facet-search/search-for-facet-values), [settings readback](https://www.meilisearch.com/docs/reference/api/settings/list-all-settings): task completion and selected backend request boundaries.
- [Ecto.Multi](https://ecto.hexdocs.pm/3.14.0/Ecto.Multi.html), [Ecto tenancy](https://ecto.hexdocs.pm/multi-tenancy-with-foreign-keys.html), [Phoenix scopes](https://phoenix.hexdocs.pm/scopes.html), [Phoenix contexts](https://phoenix.hexdocs.pm/contexts.html), [Plug.Builder](https://plug.hexdocs.pm/Plug.Builder.html): explicit transactional and host policy seams.
- [Oban testing](https://oban.hexdocs.pm/testing.html), [Oban uniqueness](https://oban.hexdocs.pm/2.23.0/unique_jobs.html): persisted job testing and delivery limits.
- [Meilisearch Rails](https://github.com/meilisearch/meilisearch-rails#queues--background-jobs), [Laravel Scout](https://laravel.com/docs/12.x/scout#queueing), [Searchkick](https://github.com/ankane/searchkick#testing), [Hibernate Search synchronization](https://docs.hibernate.org/search/8.1/reference/en-US/html_single/#indexing-plan-synchronization): bounded cross-ecosystem lessons, not popularity or reliability claims.
- [GitHub artifact API](https://docs.github.com/en/rest/actions/artifacts), [workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts), [Hex publishing](https://hex.pm/docs/publish): provenance, retention and package/documentation publication boundaries.
- Local authority: `.planning/reference/PRE-OPERATOR-UI-READINESS.md`, archived v1.39 phases 162–164, v1.38 phases 160–161, `CONTRIBUTING.md`, and source/test/prompt paths itemized in the four input reports. Historical findings remain unchanged.

---
Research synthesized for requirements and roadmap; proposed phases are recommendations, not active milestone state. No tests ran during research.
