# Phase 169: Library Fix Delivery and PR Triage - Research

**Researched:** 2026-09-29
**Domain:** Elixir public-contract correction delivery, source provenance, finite dependency PR triage
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

The following approved decisions, discretion, and deferred ideas are copied verbatim. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:18-43,118-122]

<!-- DATA_J7Q4V2M9_START -->
### Frozen Dependabot cohort
- **D-01:** Apply one evidence gate per frozen PR. Keep or update a PR when current evidence demonstrates a concrete security or supported-compatibility need, or a material adopter, workflow-reliability, or maintainer-quality benefit that warrants the verification cost. A green check alone is not sufficient reason to merge an update.
- **D-02:** Close or defer updates without that demonstrated value. Record an evidence-based reason and a specific revisit trigger for deferrals. No disposition should be inferred from PR age or `BEHIND` status alone; refresh its head/base, release notes, and checks before action.
- **D-03:** Do not make clearing the inbox a goal. New routine updates stay in normal maintenance; material new security or compatibility evidence can reopen the scope. Keep the existing required/advisory verification split and avoid a broad upgrade or new required CI job.
- **D-04:** The frozen cohort is #65 `actions/cache`, #68 `dependency-review-action`, #69 `stream_data`, #70 `actions/setup-node`, #71 `actions/checkout`, #72 `actions/deploy-pages`, #73 `req`, #74 `ex_doc`, #75 `dialyxir`, and #76 `oban`. The discussion-time heads/bases are preserved below as baseline identifiers only; these are not valid evidence for a later action without refresh.
  - #65 head `6b70b673347ec3e31af22f044aecbab6fe6c3a98`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #68 head `949fafb68635b2fee2c0ac5ff4b6cc4a2eb116dd`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #69 head `b4bd46d244fa3db8e1bb6a35e651bf1250372c1d`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #70 head `a7695881de49fe4e812435d3a148d56b37e633d7`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #71 head `a46d9db1e8ffae1499c13fff1a8091d7cd22c267`, base `40c9978c975dbfb42db75511f44ff0369c8d7d88`
  - #72 head `2bb02e546a0ea685a873bf09e0f104f466d28cfd`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #73 head `f6feeb157527e4ac1d58cecdd7a58bcb84975968`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #74 head `ecb00d502c8800c79581e769904c75520c71fcb4`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #75 head `b3b5f495cf9f6adb34612b7da31c5a555dee842c`, base `2832e91d725d70eff9ba11d08052260ba17e2747`
  - #76 head `cc40b53b0009eb404c75258ab44b210fb064d9f4`, base `2832e91d725d70eff9ba11d08052260ba17e2747`

### Owned planning-only delta
- **D-05:** Use current planning authority plus a compact, source-linked inventory to explain what is selected, what reached which source identity, what evidence applies, and how each remaining owned change is disposed. Keep the inventory in the existing canonical planning records; do not create a competing summary or import the accumulated planning history wholesale.
- **D-06:** Carry historical archive material into reviewed public delivery only when it is needed to understand a current decision or proof. Use a separate bounded archive change when that makes review clearer, and do not make archive review a prerequisite for the runtime fixes.
- **D-07:** Preserve dated historical assessments and receipts as written. Record current status and pointers in current authority; never transfer an old run's identity to a rewritten or new source SHA.
- **D-08:** Maintain separate identities for candidate source, PR merge ref, squash-merged `main`, locally built package, and published package. Phase 169 records the rationale for a normal patch; Phase 170 owns the release decision and publication/parity evidence.

### the agent's Discretion
- Refresh the frozen PR metadata and evidence before each candidate action, then make candidate-specific dispositions under D-01–D-03 with explicit reasons and revisit triggers.
- Choose a coherent PR grouping and the smallest reliable verification for each changed surface. Reuse prior semantic evidence only after relevant-source comparison; preserve the limits of each historical receipt.
- Build the dated owned-change inventory from refreshed public `main`, preserving unrelated worktree state and selecting only planning records needed by current maintainer jobs.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within the approved Phase 169 boundary.
<!-- DATA_J7Q4V2M9_END -->
</user_constraints>

## Summary

Deliver one coherent tenant/facet correction PR from refreshed public main, including the existing public-entry regressions, Phoenix host fixture and both dependency modes, and bounded repair scenario. Run the owned-delta inventory first; conduct the finite PR triage independently; join both outcomes in current phase authority before handoff. The approved acceptance is “merged and verified there,” so a prepared PR or historical local implementation cannot complete DELIV-02. [VERIFIED: .planning/REQUIREMENTS.md:20-21]

The decisive research finding is source divergence: the research checkout's committed source is dbcbfc9a6421280a223515c9a50c0a84ef619f52 and its remote-tracking main is still 40c9978c975dbfb42db75511f44ff0369c8d7d88. Live public main is 2832e91d725d70eff9ba11d08052260ba17e2747. A complete recursive GitHub tree comparison found 200 differing blob paths: 158 planning and 42 outside planning. Those differences include public-only Phase 168 protection that must be retained, not “owned unpublished work” to overwrite. This observation compares committed trees; dirty changes require a separate ownership ledger. [VERIFIED: git rev-parse/git ls-tree and GitHub GET repos/szTheory/scrypath/git/trees/2832e91d725d70eff9ba11d08052260ba17e2747?recursive=1, 2026-09-29; truncated=false]

Use existing tooling and proof. The historical tenant/facet regressions and live scenarios already exist, but Phase 168 changed dependencies and package staging on public main. Obtain fresh joined candidate and post-merge evidence for the reconstructed source while preserving old receipts at their original identities. Record compatible library bugfix rationale for the normal patch; publication remains Phase 170. [VERIFIED: .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:21-43,83-103; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:35-38]

**Primary recommendation:** Plan four bounded outcomes: source/ownership inventory, coherent fix-and-proof delivery, finite cohort dispositions, and a joined Phase 170 handoff. Parallelize triage after the baseline is frozen; never make low-value upgrades or historical archives prerequisites for the runtime correction. [VERIFIED: .planning/ROADMAP.md:70-79; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-38]

## Architectural Responsibility Map

This is the prescribed task ownership map, grounded in the approved host/library boundary and current implementations. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md:17-30]

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Actor membership and trusted tenant selection | Host API/context | Host database | Host policy runs before library dispatch. |
| Tenant predicate composition and runtime-option separation | Library/API | Internal backend adapter | Preserve the public filter input while keeping strict runtime configuration. |
| Facet keyword rendering | Internal Meilisearch adapter | Meilisearch service | Reuse the existing filter grammar before JSON encoding. |
| Raw hits, counts, facets | Search service/library result | Host assertions | Observe each output independently before host hydration. |
| Tenant-safe hydration | Host context/database | Library raw result | Query by authorized tenant and returned IDs together. |
| Bounded repair | Library orchestration | Ecto source and Meilisearch tasks | Explicit ID selection, exact task success, then the same raw-search oracle. |
| PR and source provenance | Repository/CI | Current planning authority | Record source identities, relevant comparisons, jobs, and disposition separately. |
| Package publication | Release automation, Phase 170 | Hex/HexDocs | Local artifact consumption does not establish publication. |

<phase_requirements>
## Phase Requirements

Descriptions below are verbatim acceptance contracts. [VERIFIED: .planning/REQUIREMENTS.md:20-21]

<!-- DATA_R8N3K6P1_START -->
| ID | Description | Research Support |
|---|---|---|
| DELIV-02 | The unpublished v1.39/v1.40 delta is inventoried against refreshed public `main`; the confirmed tenant-option and facet-filter corrections and their coherent regression/adopter proof are merged and verified there. Every remaining owned change has a reviewable delivery path or evidence-backed disposition. A selected fix may be deferred only by an explicit maintainer scope decision; a prepared PR is not completed delivery. | Refreshed source comparison, selected component set, retained Phase 168 changes, three proof surfaces, candidate/merge/main identity join. |
| TRIAGE-01 | Each Dependabot PR in a dated cohort frozen at Phase 169 start has an evidence-based keep, update, close or defer disposition and revisit trigger where relevant. Refresh head/base and check evidence before action. Newly arriving routine PRs enter maintenance; material security/compatibility evidence can reopen scope. An empty inbox is not required. | Ten-row frozen inventory, upstream change evidence, value gate, change-specific verification and refresh-before-action protocol. |
<!-- DATA_R8N3K6P1_END -->
</phase_requirements>

## Project Constraints (from AGENTS.md)

These directives are planning constraints, not optional improvements. [VERIFIED: AGENTS.md:10-19,26-65,78,90-105,110-115]

- Consult relevant prompt material for search architecture, Elixir/Ecto/Phoenix, release engineering, and positioning.
- Keep the library Ecto-first and Phoenix-friendly; preserve Meilisearch-first public scope and the internal adapter seam.
- Preserve inline, optional Oban-backed, and manual synchronization, with explicit consistency, deletion, backfill, and reindex semantics.
- Prioritize low-friction setup and operational correctness; maintain the release-quality bar.
- Preserve support policy: “support floor `1.17`, target current stable through `1.19`” and “support floor `26`, test through `28`.” These are repository policy statements, not a claim about today's latest upstream runtime.
- Use explicit functions and the existing schema macro; avoid a public multi-backend facade, Phoenix-only architecture, mandatory core supervision, or adding PostgreSQL search.
- Retain first-class telemetry and the established GitHub Actions, setup-beam, Release Please, Hex, ExDoc, Credo, Dialyxir, and testing conventions; follow existing source patterns.
- Follow CONTRIBUTING checks for the changed surface. Keep edits focused and update current product authority only when scope or shipped claims intentionally change.
- Use PR-first delivery, keep the lean required gates green, and base completion on executable or exact-SHA hosted evidence.
- Resolve subjective choices before implementation or keep them nonblocking. Never simulate review or silently approve a trust gate.
- Preserve the expected idle-state interpretation when applicable; do not reopen historical phases or invent work without approved scope/evidence.
- Do not manually edit the managed developer profile.

The prompt material supports explicit library APIs, compatible corrections, SHA-pinned workflow dependencies, normal release automation, bounded tests, and minimal package contents. Its older broad CI suggestions do not override the current required/advisory split. [VERIFIED: prompts/elixir-opensource-libs-best-practices-deep-research.md:5-16,24-26,45-75,386-413; prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:5-36,195-209; prompts/scrypath-milestone-ratchet-roadmap.txt:123-175,189-203]

## Standard Stack

### Core and supporting components

Retain the current public-main dependency graph for the fix PR. The entries below describe existing dependencies, not proposed upgrades or a “latest versions” policy. Full public-main lock entries were read through GitHub's Contents API at the pinned main SHA; Hex release metadata independently confirmed the versions and publication dates. [VERIFIED: GitHub contents/mix.lock?ref=2832e91d725d70eff9ba11d08052260ba17e2747, lines 9-36; Hex release APIs listed below]

| Component | Existing version / publication date | Purpose and provenance |
|---|---|---|
| Elixir/Mix + ExUnit | Local selected 1.19.5 / OTP 28.5 | Existing available toolchain; ExUnit is initialized by “ExUnit.start()”. [VERIFIED: selected Mix version probe, 2026-09-29; test/test_helper.exs:7] |
| Ecto | 3.14.0 / 2026-05-19 | Schema/query boundary; lock quote: “:ecto, \"3.14.0\"”. [VERIFIED: public-main mix.lock:11] [CITED: https://hex.pm/api/packages/ecto/releases/3.14.0] |
| Req / Req.Test | 0.6.3 / 2026-07-16 | Transport and encoded-request regression; quote: “:req, \"0.6.3\"”. [VERIFIED: public-main mix.lock:33; test/scrypath/facet_values_contract_test.exs:29-43] [CITED: https://hex.pm/api/packages/req/releases/0.6.3] |
| NimbleOptions | 1.1.1 / 2024-05-25 | Existing configuration validation; quote: “{:nimble_options, \"~> 1.1\"}”. [VERIFIED: mix.exs:110] [CITED: https://hex.pm/api/packages/nimble_options/releases/1.1.1] |
| Jason | 1.4.5 / 2026-05-05 | Existing literal encoder; quote: “:jason, \"1.4.5\"”. [VERIFIED: public-main mix.lock:21; lib/scrypath/meilisearch/query.ex:108-109] [CITED: https://hex.pm/api/packages/jason/releases/1.4.5] |
| Oban | 2.23.0 / 2026-05-27 | Optional async integration, not a new required dependency; quote: “{:oban, \"~> 2.21\", optional: true}”. [VERIFIED: mix.exs:111; public-main mix.lock:30] [CITED: https://hex.pm/api/packages/oban/releases/2.23.0] |
| StreamData | 1.3.0 / 2026-03-09 | Existing property tests; quote: “:stream_data, \"1.3.0\"”. No new property suite needed for this integration. [VERIFIED: public-main mix.lock:35] [CITED: https://hex.pm/api/packages/stream_data/releases/1.3.0] |
| ExDoc / Dialyxir | 0.40.3 / 2026-05-21; 1.4.7 / 2025-11-06 | Existing docs/static analysis; quotes: “:ex_doc, \"0.40.3\"”, “:dialyxir, \"1.4.7\"”. [VERIFIED: public-main mix.lock:9,16] [CITED: https://hex.pm/api/packages/ex_doc/releases/0.40.3] [CITED: https://hex.pm/api/packages/dialyxir/releases/1.4.7] |

**Installation:** Add no package for the selected corrections. Resolve existing locks in the clean candidate using the established Mix setup. Bot upgrades require separate value selection; do not couple them to the tenant/facet fix. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-21; mix.exs:107-121]

### Alternatives considered

| Decision | Prescribed approach | Rejected alternative and reason |
|---|---|---|
| Delivery unit | One coherent fix/proof PR, with separate bot changes only if selected | Entire accumulated branch obscures corrections and risks reverting public fixes. |
| Test layer | Existing recorder, Req.Test, Phoenix path/package and backend proof | New framework or required lane adds cost without a named missing boundary. |
| Historical evidence | Relevant-source comparison plus fresh candidate/main gates | Relabeling an old run as a new SHA destroys provenance. |
| Inventory | Current phase authority plus source-linked rows | Whole archive import or a second competing readiness summary conflicts with D-05/D-06. |

These are applications of the locked delivery, verification-cost, and inventory decisions. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-43]

## Package Legitimacy Audit

No new package is recommended for installation. Existing Hex identities were confirmed from project manifests and official Hex release metadata; they are not npm packages. The GSD legitimacy command was attempted with the actual ecosystem and rejected it with “Usage: gsd-tools package-legitimacy check --ecosystem <npm|pypi|crates> <pkg1> ...”. Therefore this research awards no invented OK verdict to a Hex upgrade. [VERIFIED: gsd-tools package-legitimacy invocation, 2026-09-29]

| Package set | Registry | Verdict | Disposition |
|---|---|---|---|
| Existing fix/proof dependencies | Hex | Existing dependencies; no new-install recommendation | Preserve public-main locks. |
| Any cohort dependency selected later | Hex or upstream GitHub Action repository | Pending candidate-specific validation | Verify official project identity, release metadata, exact diff and advisories before installation/update; do not run npm legitimacy checks for Hex names. |

No SLOP/SUS verdict was returned. Registry lookup alone is not a compatibility or supply-chain approval. This is a tooling limitation, not a reason to block the already scoped library correction. [VERIFIED: legitimacy command result; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-21]

## Architecture Patterns

### System architecture and evidence flow

The diagram expresses the prescribed integration and proof sequence. The runtime half follows the existing host, adapter and repair boundaries. [VERIFIED: examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:35-98,128-144; lib/scrypath/meilisearch/client.ex:104-136; test/scrypath/live_operator_verification_test.exs:184-320]

~~~mermaid
flowchart TD
  U[Host request and synthetic principal] --> A{Persisted membership and input allowed?}
  A -->|No| X[Reject before search]
  A -->|Yes| T[Host derives tenant scope]
  T --> V[Library validates and composes filters]
  V --> C[Separate search options from runtime config]
  C --> F[Existing Meilisearch filter renderer]
  F --> M[Meilisearch]
  M --> R[Raw hits counts and facets]
  R --> H[Host hydration by tenant and returned IDs]
  DB[Ecto rows with explicit selected IDs] --> B[Manual backfill]
  B --> K[Exact backend task]
  K -->|Terminal success| M
  P[Refreshed public main plus selected source] --> Q[Candidate regressions and named service proof]
  Q --> PR[PR merge-ref required checks]
  PR --> S[Squash main]
  S --> G[Post-merge checks and source comparison]
  G --> L[Current phase inventory and Phase 170 release rationale]
~~~

### Recommended structure and component responsibilities

Keep existing module/test locations; reconstruct selected changes by patch or explicit file selection from refreshed public main. These are source-navigation locations, not new filesystem-creation requirements. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:84-103]

| Existing source surface | Responsibility | Selection guidance |
|---|---|---|
| Single, Many, FacetValues search modules | Exclude composed search input from strict runtime config | Select the three narrow changes together. |
| Meilisearch client and query renderer | Render common keyword facet filters through the established grammar | Select both modules together; preserve existing empty and rendered-list forms. |
| Tenant-scope and facet-values contract tests | Public-entry happy/error/escaping/pre-dispatch evidence | Include both complete test modules. |
| Phoenix Blog context, Post projection and additive migration | Persisted membership-derived scope and explicit hydration | Include the host fixture as one coherent unit. |
| Phoenix tenant recorder/live tests and shared index setup | Both positive controls, no foreign raw/metadata leakage, explicit primary key | Retain all four existing smoke-fixture callsite adjustments. |
| Root live operator verification | ID-scoped repair, no-action report, task completion, raw visibility | Include the existing bounded scenario and helpers. |
| Phoenix README | Explain the selected host proof and its limits | Merge only the needed addition onto the public README; preserve Phase 168 graph-proof text. |
| Current phase/state/roadmap authority | Owned-change and cohort disposition, proof links, Phase 170 handoff | Select minimal current records; preserve historical assessments unchanged. |

### Pattern 1: Preserve the validated search predicate

The existing correction drops “:tenant_scope” from all three runtime-option lists, after search validation has composed the predicate. Do not add that key to the runtime configuration schema or drop it from the validated search query. [VERIFIED: lib/scrypath/search/single.ex:44-54; lib/scrypath/search/many.ex:187-198; lib/scrypath/search/facet_values.ex:33-43]

### Pattern 2: Reuse the filter grammar at the adapter boundary

The branch condition is “{:filter, filters} when is_list(filters) and filters != []”; keyword input calls “MeilisearchQuery.render_common_filter(filters)”, while the other list form is retained. The delegated renderer uses the existing JSON literal encoder. Keep request expectations independent of that production renderer. [VERIFIED: lib/scrypath/meilisearch/client.ex:110-126; lib/scrypath/meilisearch/query.ex:15-17,80-109; test/scrypath/facet_values_contract_test.exs:84-111]

### Pattern 3: Bound proof to the source actually exercised

Use one receipt row per evidence identity: candidate commit, PR head/base and merge ref, squash-main commit, local package artifact/graph, and later published package. A tree comparison supports semantic reuse but cannot transform an old run into a run of a new commit. GitHub documents that pull-request workflows normally run on the PR merge ref. [VERIFIED: .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:17-19,51-57,87-103] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request]

Required current gates still run after reconstructing history. Obtain named Phoenix path/package and repair evidence explicitly; the historical passing candidate used different dependency/staging inputs from public main. Keep the older receipt as bounded historical support. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md:5-19,53-58; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:83-103]

### Pattern 4: Inventory both directions before selecting changes

Record observation time, public SHA, local SHA, dirty-state ownership, and each changed path/group with its disposition, delivery source and evidence. Classify public-only changes as retained public work, not as deletions to deliver. Classify remaining local work into selected now, already delivered/equivalent, bounded later delivery, local historical reference, or unrelated preservation; each owned remainder needs a concrete reason/path. These are descriptive inventory categories, not new runtime enums. [VERIFIED: .planning/ROADMAP.md:76-79; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:35-43]

The refreshed comparison identifies the already delivered package graph checker, four-graph audit, security locks, verification changes, and mounted-readiness fix among the public-side differences. Retain them. In particular, copy neither the old complete library directory nor old lockfiles from the historical checkout. [VERIFIED: GitHub recursive tree comparison, 2026-09-29; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:21-45,63-68]

## Frozen Cohort: Current Research Snapshot

At the read-only refresh on 2026-09-29 (approximately 14:57–15:04 UTC), all ten frozen PRs remained open and their heads matched the verbatim context baseline above. The following merge states/check observations are ephemeral; refresh again immediately before action. They do not constitute final dispositions. [VERIFIED: gh pr list --repo szTheory/scrypath --state open, 2026-09-29]

| PR | Proposed update | Observed state / failed checks | Evidence to prioritize under D-01 |
|---|---|---|---|
| #65 | actions/cache 5.1.0 → 6.1.0 | DIRTY; core, repository contracts, compatibility, deep-quality failures | Read-only cache handling changed; inspect whether this workflow uses the affected permissions/cache behavior. Do not spend a rebase merely to clear the inbox. |
| #68 | dependency-review-action 4.9.0 → 5.0.0 | BEHIND; deep-quality failure | Official major release moves to Node 24, declares runner minimum, and includes security fixes. Determine applicability and retained workflow protections. |
| #69 | stream_data 1.3.0 → 1.4.0 | BEHIND; deep-quality failure | Float generation boundary correction and changed shrinking may help only specific existing properties. Establish a named benefit first. |
| #70 | setup-node 6.5.0 → 7.0.0 | BEHIND; deep-quality failure | ESM/runtime tooling and cache/auth changes; examine current website use rather than assuming a library benefit. |
| #71 | checkout 6.1.0 → 7.0.1 | BEHIND; core, repository contracts, compatibility, deep-quality failures | Unsafe-PR behavior and git-value escaping changed. Read the major upgrade notes and failed contract logs before choosing a bounded update. |
| #72 | deploy-pages 5.0.0 → 5.0.1 | CLEAN; no failed rollup entries | Polling backoff/jitter is a concrete reliability change; tie its benefit to the existing deployment job and verification cost. |
| #73 | req 0.6.3 → 0.7.4 | BLOCKED; deep-quality, Phoenix, mounted ecommerce and Ops failures | Manifest range changes as well as the lock; upstream changes adapters and request semantics. Diagnose actual failures before calling it compatible or declaring them flaky. |
| #74 | ex_doc 0.40.3 → 0.40.4 | CLEAN; no failed rollup entries | Reproducible output and anchor/navigation fixes may offer adopter/maintainer value; keep broad docs cleanup in Phase 170. |
| #75 | dialyxir 1.4.7 → 1.4.8 | CLEAN; no failed rollup entries | OTP 28 warning support and line/column ignore matching provide a supported-toolchain benefit to assess. |
| #76 | oban 2.23.0 → 2.24.1 | CLEAN; no failed rollup entries | Execution-acknowledgement and notifier corrections deserve review, but this PR also changes multiple Ecto/SQLite-related lock entries. Bound the graph before accepting it. |

Upstream observations above come from official release/changelog pages, not from an inference that newer means necessary. [CITED: https://github.com/actions/cache/releases/tag/v6.1.0] [CITED: https://github.com/actions/dependency-review-action/releases/tag/v5.0.0] [CITED: https://github.com/whatyouhide/stream_data/blob/v1.4.0/CHANGELOG.md] [CITED: https://github.com/actions/setup-node/releases/tag/v7.0.0] [CITED: https://github.com/actions/checkout/releases/tag/v7.0.1] [CITED: https://github.com/actions/deploy-pages/releases/tag/v5.0.1] [CITED: https://github.com/wojtekmach/req/blob/v0.7.4/CHANGELOG.md] [CITED: https://github.com/elixir-lang/ex_doc/blob/v0.40.4/CHANGELOG.md] [CITED: https://github.com/jeremyjh/dialyxir/releases/tag/1.4.8] [CITED: https://github.com/oban-bg/oban/blob/v2.24.1/CHANGELOG.md]

PR #73 changes the requirement from “{:req, \"~> 0.6.1\"}” to “{:req, \"~> 0.7.4\"}”. PR #76 updates Oban plus db_connection, ecto, ecto_sqlite3, elixir_make and exqlite. Treat their actual diffs as the verification scope; do not label either as a single-package lock refresh. [VERIFIED: GitHub GET repos/szTheory/scrypath/pulls/73/files and pulls/76/files, 2026-09-29]

**Prescribed disposition protocol:** For every row, refresh head/base, release notes, applicable advisories, changed manifests/locks/workflows and exact check runs; state the concrete value or why evidence does not meet D-01; select keep/update/close/defer; record the reason, next action, and event-based revisit trigger. A defer may finish the cohort requirement when properly evidenced; it does not defer the selected library correction. Prioritize #68/#71 security-related changes, #73's public dependency boundary, and #76's graph expansion for decision work before routine cosmetic/tooling churn. These priorities are research recommendations, not approval to merge. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-22]

Release Please #83 was open at head e1c9e3562af5a383993a80af70dabaa73e136cfd with title “chore(main): release scrypath 0.3.14” and state BLOCKED. Preserve Phase 170 ownership; the title is not a publication receipt. [VERIFIED: gh pr list snapshot, 2026-09-29; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:11]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Facet filter encoding | Another serializer or escaping grammar | Existing Meilisearch query renderer and Jason | Existing correction delegates rather than introducing divergent grammar. |
| Host authorization | Library login/session/tenant policy | Existing persisted host membership context | Approved proof covers one host policy only. |
| Backend completion | Sleeps or queue acceptance as visibility | Existing exact task polling plus raw-query assertions | Acceptance, task completion and visible data are separate observations. |
| Package proof | A Git tag or dependency name as sufficient proof | Public-main staging and resolved-graph checks | Phase 168 already added graph-preservation protection. |
| Delivery attestation | Bespoke “all green” boolean | Existing CI monitor and source-specific job/artifact identities | Existing closeout validates required jobs and immutable artifacts. |
| Bot triage | New dependency dashboard/service or broad upgrade framework | Ten-row canonical disposition record | The approved objective is finite decision evidence. |

[VERIFIED: lib/scrypath/meilisearch/client.ex:114-122; lib/scrypath/meilisearch/query.ex:15-17,108-109; examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:35-98; test/scrypath/live_operator_verification_test.exs:225-258,303-320; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:83-103; CONTRIBUTING.md:67-83; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-38]

## Runtime State Inventory

Included because the selected host proof carries an additive Ecto migration. This is a research inventory, not evidence that all local or external runtime state has been exhaustively scanned. [VERIFIED: examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs:4-23]

| Category | Items found / observation | Required plan treatment |
|---|---|---|
| Stored data | The migration creates “:host_actors” and “:host_memberships”, a unique “[:actor_id, :tenant_id]” index, and adds “:tenant_id” / “:category” to “:posts”. [VERIFIED: examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs:5-23] | Run the existing migration in disposable host proof databases; do not migrate adopter databases. Existing host data, if intentionally reused, needs this schema migration rather than a code-only update. |
| Live service config | Named tests create synthetic indexes and settings; historical fixtures needed an explicit primary key after projection expansion. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md:33-35] | Reuse index setup/cleanup and await setting tasks; do not alter shared production indexes. External service UI state was not surveyed. |
| OS-registered state | No rename or OS-registration change is prescribed by the approved phase; machine-wide registrations were not audited. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:9-11] | Track only task-owned worktrees/branches/services created during execution; no blanket cleanup. |
| Secrets/env vars | Existing live proof requires “SCRYPATH_EXAMPLE_INTEGRATION”, “PGPORT”, and “SCRYPATH_MEILISEARCH_URL”. [VERIFIED: CONTRIBUTING.md:98] | Reuse existing CI service configuration; no secret rename or environment dump. Host readiness ports were unavailable in this research session. |
| Build artifacts / installed packages | Fresh local artifacts may carry “v0.3.13” while differing from the published package. [VERIFIED: .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:87-103] | Rebuild from the selected candidate, record source/artifact/graph identity, and explicitly retain or remove owned staging files. Leave registry publication to Phase 170. |

## Common Pitfalls

1. **Reverting delivered security work during extraction.** The old checkout differs from current main in both directions. Select patches on public main and compare all resulting paths; the Phoenix README is an overlap requiring a semantic merge. Warning sign: removed audit/graph-protection code or downgraded locks in a tenant-fix PR. [VERIFIED: recursive tree comparison, 2026-09-29; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:21-45]
2. **A green result that never ran the selected scenario.** The historical Phase 166 Phoenix proof ran “16 tests”; Phase 168's public-main proof ran “10 tests”. Require the named host and repair markers and underlying assertions, not a job name alone. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md:13-15; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:87-88]
3. **Hiding a raw tenant leak with database filtering.** Preserve separate raw hits/count/facet and hydrated-record assertions, including the second tenant's positive control. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md:20-24]
4. **Calling a request-construction test service acceptance.** The facet defect failed before HTTP; Req.Test proves encoded request behavior, while the named live/package scenario proves the configured backend/artifact boundary. [VERIFIED: .planning/milestones/v1.40-phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md:134-150,169-171]
5. **Treating obsolete checks as a current merge decision.** Snapshot states and even green checks do not establish D-01 value or current-base compatibility. Refresh selected PR heads/bases before action, and diagnose failures without assuming they are the old Mint or readiness issue. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-22]
6. **Expanding closeout into another readiness assessment.** Preserve the historical “Decision: NOT READY.” Phase 170 owns the terminal record and release, while Phase 169 supplies integrated source and patch rationale. [VERIFIED: .planning/milestones/v1.40-phases/167-dated-readiness-and-closeout/167-ASSESSMENT.md:20-26; .planning/ROADMAP.md:79-95]
7. **Evidence loops caused by tracking writes.** Finalize tracked inputs before the exact final-source closeout; retain that terminal run receipt outside the tested tree. A later tracked write needs its own source treatment. [VERIFIED: CONTRIBUTING.md:76-83]

## Code Examples

These are verbatim extracts from source opened during research; they document reuse, not new API proposals.

### Existing internal renderer seam

[VERIFIED: lib/scrypath/meilisearch/query.ex:15-17]

<!-- DATA_Z3H7N2C8_START -->
~~~elixir
  @doc false
  @spec render_common_filter(keyword()) :: [String.t()] | nil
  def render_common_filter(filters) when is_list(filters), do: translate_filter(filters)
~~~
<!-- DATA_Z3H7N2C8_END -->

### Existing bounded repair selection

The selected IDs are a query predicate, not a total-work claim inferred from batch size. [VERIFIED: test/scrypath/live_operator_verification_test.exs:303-304]

<!-- DATA_B5P9X1L4_START -->
~~~elixir
    selected_ids = [target.id]
    selected_query = from(post in QueryablePost, where: post.id in ^selected_ids)
~~~
<!-- DATA_B5P9X1L4_END -->

### Existing host hydration boundary

[VERIFIED: examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:132-136]

<!-- DATA_A4Q8F2R6_START -->
~~~elixir
      Repo.all(
        from(post in Post,
          where: post.tenant_id == ^tenant_id and post.id in ^hit_ids
        )
      )
~~~
<!-- DATA_A4Q8F2R6_END -->

## State of the Art

This phase changes delivery state rather than the architectural stack. [VERIFIED: .planning/ROADMAP.md:70-79]

| Earlier state | Current planning baseline | Impact |
|---|---|---|
| Historical locally verified tenant/facet correction | Still absent from the refreshed public tree at research time | Reconstruct and deliver the coherent source/proof slice. |
| Pre-Phase-168 audit/package staging | Public main has four-graph audit and resolved-package-graph checks | Preserve this newer baseline during extraction. |
| Historical broad bot “BEHIND” snapshot | Current cohort includes CLEAN, BLOCKED, BEHIND and DIRTY states | Use each refreshed PR's actual evidence. |
| Local package artifact | Public publication remains separately owned | Carry patch rationale into Phase 170, not a “released” claim. |

[VERIFIED: GitHub tree/PR refresh, 2026-09-29; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:59-103]

## Environment Availability

Read-only probes ran on 2026-09-29. No test suite, CI dispatch, service startup, PR mutation, source edit, merge, push or publication was performed for research. [VERIFIED: research tool invocation record]

| Dependency | Required by | Available | Observed version / boundary | Fallback |
|---|---|---|---|---|
| GitHub CLI/API | PR/source/check inventory | Yes | gh 2.101.0; authenticated reads succeeded | Existing GitHub connector/API |
| Node | GSD and CI monitor | Yes | v22.14.0 | Existing runtime |
| Elixir/Mix and Erlang | Local proof | Yes with explicit selection | Mix 1.19.5; installed OTP 28.5 selected through ASDF variables | Hosted existing CI tuple |
| Docker engine | Isolated services/mounted proof | Yes | Client/server 29.5.2 | Existing hosted service lanes |
| Docker Compose | Mounted proof | Yes | v5.1.3 | Existing hosted lane |
| Meilisearch on local default probe | Live host/repair proof | No response | Connection refused at loopback port 7700 | Start an isolated task-owned service or use exact-source hosted lane |
| Postgres on historical proof port | Host fixture | No response | pg_isready on loopback port 55433 | Isolated service or hosted Postgres |
| Local Git metadata writes | Fetch/commit in this sandbox | Restricted | Fetch failed: “cannot open '.git/FETCH_HEAD': Operation not permitted” | Read-only API for research; authorized Git write escalation or separate writable checkout for execution |
| Context7/Jina | Documentation lookup | Not callable | No matching tools; ctx7 not found | Built-in web tool, official sources |

[VERIFIED: command/version/network probes and tool discovery, 2026-09-29]

**Blocking dependencies:** None for planning. Execution must establish writable isolation and service-backed evidence before it can complete delivery. The tool failures above are environmental observations, not dependency incompatibility claims. [VERIFIED: probe results; .planning/ROADMAP.md:76-79]

## Validation Architecture

Enabled by “\"nyquist_validation\": true”. [VERIFIED: .planning/config.json:15-20]

### Test framework

| Property | Existing source / planned command |
|---|---|
| Framework | ExUnit bundled with selected Elixir; “ExUnit.start()”. [VERIFIED: test/test_helper.exs:7] |
| Integration default | “ExUnit.configure(exclude: [:integration, :requires_clean_workspace])” unless the integration environment is enabled. [VERIFIED: test/test_helper.exs:1-5] |
| Fast public regression | mix test test/scrypath/tenant_scope_contract_test.exs test/scrypath/facet_values_contract_test.exs |
| Fast suite | mix test --exclude integration --exclude docs_contract |
| Full phase acceptance | Existing required gates, named Phoenix path/package and repair proof, PR/main source join, and finite ownership/cohort dispositions |

The public-regression command reuses two existing modules. Its historical receipt was “17 tests, 0 failures”; current runtime has not been measured in this research. Do not promise a fresh under-30-second wall time including dependency fetch/compile. [VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-VERIFICATION.md:71-75; CONTRIBUTING.md:43-47]

### Phase requirements → test map

Commands here are planned reuse of existing entrypoints; paths are navigation references, not new-file creation claims. [VERIFIED: CONTRIBUTING.md:30-46,85-107,126-130]

| Req ID | Behavior / acceptance | Type | Automated command or source evidence | Exists? |
|---|---|---|---|---|
| DELIV-02 | Tenant composition and rejection on all three public paths | Contract | mix test test/scrypath/tenant_scope_contract_test.exs | Yes, local historical source; select into PR |
| DELIV-02 | Facet defaults, keyword encoding, escaping, error/no-fallback | Contract | mix test test/scrypath/facet_values_contract_test.exs | Yes, local historical source |
| DELIV-02 | Named persisted membership policy before dispatch | Host integration | In Phoenix example: mix test test/scrypath_demo/blog_tenant_search_test.exs | Yes, requires Postgres fixture |
| DELIV-02 | Same tenant/facet scenario from path and fresh package | Service/consumer | mix verify.phoenix_example; mix verify.phoenix_example --package | Harness public; selected scenario local |
| DELIV-02 | Known mismatch, no-action report, ID repair, exact task, same raw query | Service integration | mix verify.backend; focused development may use the existing bounded_repair tag with integration enabled | Existing backend wrapper; selected scenario local |
| DELIV-02 | Repository/package/public main delivery | CI/integration | Existing required candidate jobs; source-bound PR merge ref; post-merge main; exact final closeout | Existing machinery |
| DELIV-02 | Every owned remainder accounted for | Deterministic inventory plus source review | Enumerate both committed-tree deltas and dirty paths, require one disposition per owned row | No new generic framework needed |
| TRIAGE-01 | Exactly the frozen ten PRs have current evidence and disposition | API/record validation | Refresh the frozen PR IDs, compare head/base/run identity, check complete reasons and revisit triggers | Existing gh/API; finite record authored during execution |

### Sampling rate and Wave 0 gaps

- During extraction, run the independent focused tenant/facet regressions; when test support changes, use CONTRIBUTING's warnings-as-errors compilation/test command.
- Before the fix PR is ready, run the selected service/consumer scenarios using the public-main harness and inspect actual named outputs and graph receipts.
- At merge, require current protected checks and record merge-ref identity. After merge, require green exact-main proof; compare candidate-to-main relevant inputs before reusing candidate semantic receipts.
- At phase completion, apply the existing exact-final-SHA closeout protocol after tracked updates, then stop writing tracked success notes.
- Wave 0 needs source selection, an isolated writable candidate, and named evidence mapping. It does not need a new framework or default broad test suite.

[VERIFIED: CONTRIBUTING.md:67-107,145-157; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:35-43]

Live branch protection at research time specifies strict required “backend (required)”, “core (required)”, “ecommerce-mounted (required)”, “package (required)”, and “repository-contracts (required)”; linear history is enabled and force pushes are disabled. The review rule response is null; this is not permission to fabricate a review or bypass protections. [VERIFIED: GitHub GET repos/szTheory/scrypath/branches/main/protection, 2026-09-29]

## Security Domain

Use the existing bounded security review, with **ASVS 4.0.3 taxonomy explicitly identified** for the category labels below. This is a threat mapping, not an ASVS certification or a new compliance target. The official chapter sources were checked rather than assuming the older labels match the latest standard. [CITED: https://github.com/OWASP/ASVS/tree/v4.0.3/4.0/en]

| ASVS category | Applies to selected scope? | Standard control / boundary |
|---|---|---|
| V2 Authentication | Host-owned prerequisite only | Synthetic principal represents upstream authentication; no new login proof. |
| V3 Session Management | No new session behavior | Preserve host ownership; do not expand the fixture into a session product. |
| V4 Access Control | Yes, named host fixture | Persisted membership, trusted scope, deny overrides before dispatch, tenant-and-ID hydration. |
| V5 Validation, Sanitization and Encoding | Yes | Existing schema-aware validation, allowlisted host inputs, common renderer, JSON literals and parameterized Ecto predicates. |
| V6 Stored Cryptography | No new cryptographic design | No cryptography implementation or key policy change; preserve existing dependencies. |

[VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md:17-25; examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:86-144; lib/scrypath/meilisearch/query.ex:108-109] [CITED: https://raw.githubusercontent.com/OWASP/ASVS/v4.0.3/4.0/en/0x12-V4-Access-Control.md] [CITED: https://raw.githubusercontent.com/OWASP/ASVS/v4.0.3/4.0/en/0x13-V5-Validation-Sanitization-Encoding.md]

| Threat pattern | STRIDE | Existing mitigation to preserve |
|---|---|---|
| Caller supplies another tenant or overrides filter/runtime options | Spoofing / elevation | Resolve persisted host membership and reject caller overrides before dispatch. |
| Hydration conceals foreign raw hits or counts/facets | Information disclosure | Assert raw hits and metadata independently, with second-tenant positive control. |
| Keyword literals reach JSON as tuples or unsafe strings | Tampering / availability | Existing renderer/encoder plus encoded public-entry regression. |
| Repair silently touches additional source rows | Tampering | Explicit selected-ID predicate, out-of-scope controls and exact task references. |
| Extraction restores vulnerable or unproved dependency graph | Tampering | Preserve Phase 168 locks and audit/staging protection; inspect the full selected diff. |
| Receipt reassigned to another source | Repudiation | Immutable source/run/job/artifact identities and relevant-input comparison. |

[VERIFIED: .planning/milestones/v1.40-phases/166-host-tenant-and-repair-evidence/166-CONTEXT.md:17-38; .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md:19-43,59-103; test/scrypath/facet_values_contract_test.exs:57-111]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|

None. No claim tagged ASSUMED is promoted into a locked decision. Future PR-specific value and compatibility decisions remain execution work governed by the approved evidence gate.

The evidence establishes current source shape and historical receipts, not a successful new candidate. No fresh behavior pass, unpublished merge, package publication, production authorization guarantee or inferred owner approval is claimed. [VERIFIED: research execution scope; .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:9-11,35-43]

## Open Questions

These questions are **RESOLVED at the planning-decision level** by the approved five-plan breakdown. The execution facts identified below remain pending; no upgrade, receipt, delivery or release outcome is inferred.

1. **RESOLVED — Which cohort upgrades meet the value gate?** Plan 169-05 owns the finite, evidence-gated benefit evaluation and keep/update/close/defer disposition for exactly #65 and #68–76 under D-01–D-04. Each decision requires refreshed heads/bases, actual diff/check evidence, a concrete reason and a revisit trigger where relevant. Candidate-specific benefit and update outcomes remain **pending execution**; a green check alone does not select an upgrade. [PLANNING DECISION: 169-05-PLAN.md, Task 2; historical research inputs: PR refresh and official sources above]
2. **RESOLVED — Which historical planning records must travel publicly?** Plan 169-05 owns closed-set, source-linked archive selection and disposition of every remaining owned change under D-05/D-06. There is no automatic archive import or archive prerequisite for the runtime correction. The standard 169-05-SUMMARY.md owns the final detailed rows and STATE points to it. The exact necessary archive set and supporting comparison remain **pending execution**. [PLANNING DECISION: 169-05-PLAN.md, Tasks 1 and 3; approved context D-05/D-06]
3. **RESOLVED — What exact integration receipts will the new candidate produce?** Plan 169-04 owns the fresh joined-candidate and integrated-main receipt set, including distinct PR head/base/merge-ref and local-artifact/graph identities. Fields are populated only from actual runs and source comparisons. Those receipts remain **pending execution**. Scheduled run 36534036786 belongs to the then-existing public-main SHA and cannot prove the undelivered scenario. [PLANNING DECISION: 169-04-PLAN.md, Tasks 1 and 2; historical observation: GitHub Actions run inventory, 2026-09-29]
4. **RESOLVED — What is the final release outcome?** Phase 170 owns the release/publication decision and its consumer/parity evidence. Phase 169 records only the normal patch rationale for compatible public behavior corrections and uses fix semantics for its reviewed squash. Publication and the terminal six-condition readiness outcome remain **pending Phase 170**, with no release or readiness assessment added to this phase. [PLANNING DECISION: 169-04-PLAN.md and 169-05-PLAN.md, Task 3; .planning/ROADMAP.md Phase 170; docs/releasing.md] [CITED: https://github.com/googleapis/release-please#how-should-i-write-my-commits]

## Sources

### Primary repository and live source

- Approved Phase 169 context, roadmap, requirements and current project/state authority; all read this session.
- Phase 168 context and delivery receipt: preserve public security, package staging, audit and startup corrections.
- Archived Phase 165 context/facet summary, Phase 166 context/evidence/verification/summary, and Phase 167 assessment/closeout: original semantic evidence and limits.
- Opened runtime, host context, migration, regression tests and root repair source cited inline.
- GitHub branch, recursive tree, PR metadata/files, branch protection and Actions APIs refreshed on 2026-09-29; live source compared with committed local blobs without modifying refs.
- CONTRIBUTING, release runbook, AGENTS and all three assigned prompt documents.

These are source observations and recorded policy, not additional runtime validation. [VERIFIED: research read/API invocation record]

### Official external documentation

- GitHub workflow events and Dependabot version-update documentation: merge-ref and update semantics.
- Release Please official repository: fix/patch release handling.
- Official upstream release/changelog links in the frozen-cohort section.
- Hex release APIs: version existence and publication dates for the retained graph.
- OWASP ASVS versioned 4.0.3 chapters: scope-specific threat categories.

### Research method and confidence

The research-plan seam selected Jina for the four documentation questions. Jina/Context7 were unavailable, so the built-in web tool retrieved official sources. The confidence seam returned “MEDIUM” for “websearch --verified”; that tier governs external guidance and the overall report. Digests were cached from a temporary working directory to preserve the unrelated repository cache. Local source and API observations carry explicit provenance; mutable action readiness always requires refresh. The Hex legitimacy seam does not support this ecosystem, as recorded above. [VERIFIED: research-plan, classify-confidence and research-store command outputs, 2026-09-29]

## Metadata

**Confidence breakdown:** Standard stack MEDIUM (retained public graph and official Hex metadata, no upgrade compatibility assumed); architecture MEDIUM (opened implementation and locked boundaries, no new candidate run); pitfalls MEDIUM (historical failure records plus current source divergence). [VERIFIED: confidence seam and cited research observations]

**Research date:** 2026-09-29.
**Validity:** Refresh PR/head/base/check/advisory observations immediately before each action. Reuse architecture guidance only while the approved phase and relevant source inputs remain unchanged. [VERIFIED: .planning/phases/169-library-fix-delivery-and-pr-triage/169-CONTEXT.md:19-22,35-43]

**Write-tool adaptation:** This runtime exposes apply_patch rather than a tool named Write; the canonical file was created with that structured filesystem editor, not shell redirection or a heredoc. [VERIFIED: available tool surface and research write invocation]
