# Domain Pitfalls

**Domain:** Ecto-native search indexing and orchestration library
**Project:** Scrypath
**Researched:** 2026-04-16
**Overall confidence:** HIGH for release/versioning and backend DX pitfalls, MEDIUM for second-backend timing because adoption pressure is still unknown

## Scope-Shaping Pitfalls

These are severe enough that they should shape the next milestone now, not wait for later cleanup.

### Pitfall 1: Turning the internal backend seam into a public "universal search API"
**Severity:** Critical

**What goes wrong:** Scrypath adds a second backend by widening the public API around the lowest common denominator. Backend-specific capabilities then leak back in through escape hatches, inconsistent options, or backend-name conditionals. The public surface gets harder to learn and harder to keep honest.

**Why it happens:** Once a library has one successful backend, maintainers often assume the existing adapter seam is already the product boundary. It usually is not. Search engines disagree on settings, schema mutation, filter syntax, ranking, aliases, task models, and hydration expectations. Forcing one common API too early creates fake portability.

**What successful libraries did better:**
- Laravel Scout stayed driver-based but kept the common path narrow and explicit, while still documenting backend-specific setup and caveats for Meilisearch and Typesense instead of pretending they behave the same.  
  Source: https://laravel.com/docs/11.x/scout
- Searchkick exposes a strong default path, but also makes advanced search behavior explicitly engine-specific and requires explicit reindexing when indexed shape changes.  
  Source: https://github.com/ankane/searchkick

**What unsuccessful libraries did worse:** Older multi-backend search layers such as Haystack often paid a complexity tax from trying to make very different engines feel uniform, then pushed users into backend-specific settings and signal tweaks anyway.  
Source: https://django-haystack.readthedocs.io/en/latest/best_practices.html and https://django-haystack.readthedocs.io/_/downloads/en/v3.2.1/pdf/

**Why it is especially dangerous for Scrypath:** Scrypath already has the right shape for restraint:
- `Scrypath.Backend` is explicitly documented as an internal seam.
- `Scrypath.Options` encodes a structured common path for `filter`, `sort`, `page`, sync mode, and schema metadata.

If the next milestone expands that seam into a supported extension API before real second-backend pressure exists, the current clean split between common path and backend-specific code will erode quickly.

**Prevention:**
1. Keep `Scrypath.Backend` internal for the full next milestone.
2. Define a written "common-path contract" before any second backend work:
   - document indexing
   - delete by canonical document ID
   - common query text
   - declared filterable/sortable fields only
   - pagination
   - explicit hydration
3. Add a separate backend-specific escape hatch rather than widening common options:
   - `backend_opts` or backend-specific modules for advanced features
   - never mix backend-native knobs into `filter`, `sort`, or schema metadata defaults
4. Require adapter contract tests before adapter implementation work starts.
5. Only expose a second backend publicly if Scrypath can explain, in docs, which features are common, which are backend-native, and which are unsupported.

**Milestone owner:** Phase 1 "Backend boundary decision" before any second-backend implementation phase.

### Pitfall 2: Making the happy path magical enough that users cannot see operational truth
**Severity:** Critical

**What goes wrong:** Scrypath makes sync feel automatic, but users cannot tell when writes are inline vs queued, whether deletes are durable, how long indexing may lag, or when reindex/settings changes require operational action. The result is support load, surprise data drift, and distrust.

**Why it happens:** Search libraries get adopted through DX, so maintainers optimize for "just add one macro" and under-document the operational model. The hidden cost appears later in production incidents.

**What successful libraries did better:**
- Searchkick documents multiple sync strategies (`inline`, `async`, `queue`, `manual`) and calls out when bulk queueing is more performant than per-record async indexing.  
  Source: https://github.com/ankane/searchkick
- Typesense’s syncing guide is blunt about deleted-record handling, buffered sync, worker parallelism, and nightly reindex as a gap-repair tool.  
  Source: https://typesense.org/docs/guide/syncing-data-into-typesense.html

**What unsuccessful libraries did worse:**
- Haystack’s realtime signal processor performs updates in-process and its docs explicitly warn that this can make request/response users wait and can churn heavily on write-heavy systems.  
  Source: https://django-haystack.readthedocs.io/_/downloads/en/v3.2.1/pdf/

**Why it is especially dangerous for Scrypath:** Scrypath’s value proposition is "native to Ecto without hiding reality." If the next milestone adds more automation or operator tooling without doubling down on visible operational states, it will cut directly against the product thesis.

**Prevention:**
1. Keep docs opinionated about sync modes:
   - `:inline` is for local development and low-volume cases
   - `:oban` is the recommended production path
   - `:manual` is for controlled migrations/imports/recovery
2. Expose lag and task state as first-class concepts in docs and telemetry, not hidden implementation details.
3. Keep schema macros metadata-only; do not introduce auto-hooking that hides when external calls occur.
4. Add guide-level "failure mode" sections to every feature that touches indexing, delete, reindex, or backend-native search behavior.
5. Add test helpers and examples that force users to acknowledge eventual consistency instead of assuming immediate visibility.

**Milestone owner:** Phase 0 "Public release confidence and docs truth" if the next milestone includes release/publication confidence; otherwise the first phase of any operator or advanced-feature milestone.

### Pitfall 3: Letting release tags, package version, and automation drift apart
**Severity:** Critical

**What goes wrong:** Git tags, `mix.exs` version, Hex package version, and Release Please state diverge. Releases become hard to trust and hard to reproduce, especially once the first real public release happens.

**Why it happens:** OSS release automation often looks finished before it has handled the first live publication path. Maintainers assume local dry runs are enough and do not verify the exact credential, tag, manifest, and package metadata chain end to end.

**What successful libraries did better:**
- Release Please documents exact outputs like `release_created`, `tag_name`, and `version`, and recommends explicit token strategy plus manifest config for more advanced setups.  
  Source: https://github.com/googleapis/release-please-action
- GitHub’s workflow docs are explicit that events caused by `GITHUB_TOKEN` generally do not trigger new workflow runs, except `workflow_dispatch` and `repository_dispatch`.  
  Source: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow

**What goes wrong in practice for Scrypath right now:** Scrypath’s release workflow publishes Hex in the same workflow, which is fine, but the repo still has the classic footgun that future tag-triggered or release-triggered verification workflows will silently not fire if they rely on actions created with `GITHUB_TOKEN`. The risk is not hypothetical; both GitHub and Release Please document it directly.

**Prevention:**
1. Treat the first public Hex release as a milestone on its own, not a side task.
2. Add a release invariant check in CI:
   - `.release-please-manifest.json`
   - `mix.exs @version`
   - changelog release entry
   - created tag name
   - Hex package version after publish
3. Decide now whether downstream automation needs:
   - same-workflow conditional publish only, or
   - a GitHub App / PAT for follow-on workflow triggers
4. Add a maintainer runbook for "tag exists, Hex publish failed" and "Hex published, docs/package metadata mismatch."
5. Gate future release workflow changes behind a verification command that checks version alignment from repo files and the generated release outputs.

**Milestone owner:** Phase 0 "Release confidence under real publication."

## Critical Pitfalls

### Pitfall 4: Building operator tooling that acts like a dashboard product inside a library
**Direction:** operator tooling
**Severity:** High

**What goes wrong:** The library grows a pseudo-dashboard that tries to own queue status, backend tasks, drift state, reindex progress, and health visualization. It becomes noisy, backend-specific, and expensive to maintain, while still being worse than the host app’s actual admin surface.

**Why it happens:** Once users ask for visibility, maintainers feel pressure to "surface everything." But a library does not own the app’s deployment topology, auth model, or operations UI.

**What successful libraries did better:**
- Searchkick mostly exposes operational primitives: queueing modes, reindex, reindex status, promote. It does not try to become a full admin console.  
  Source: https://github.com/ankane/searchkick
- Meilisearch and Typesense each keep backend operational views in their own APIs and dashboards rather than expecting client libraries to replicate them.  
  Sources: https://www.meilisearch.com/docs/learn/async/task_webhook and https://typesense.org/docs/30.1/api/collection-alias.html

**Prevention:**
1. Keep Scrypath operator tooling API-first:
   - telemetry events
   - queryable status structs
   - mix tasks / maintainers commands
   - documented host-app embedding points
2. Do not ship a standalone UI in the library milestone.
3. Prefer "small truth surfaces":
   - pending backend tasks
   - last successful sync timestamp
   - failed sync counts
   - reindex generation / alias target
   - drift indicators
4. Leave visualization to Phoenix LiveDashboard, custom app pages, or backend-native consoles.
5. Set a hard rule that every operator surface must answer a remediation question, not just expose raw state.

**Milestone owner:** Phase 2 "Operator primitives" before any presentation/helpers phase.

### Pitfall 5: Coupling operator tooling to Oban or one backend so tightly that the model cannot survive a second backend
**Direction:** operator tooling, second backend
**Severity:** High

**What goes wrong:** Scrypath’s operational language becomes "Oban jobs + Meilisearch tasks," so any second backend or non-Oban environment requires either fake compatibility layers or a parallel operator API.

**Why it happens:** Oban and Meilisearch are the strongest current production path, so the easiest implementation is to mirror them directly.

**Why it is architecture-sensitive for Scrypath:** The codebase already has the right boundaries:
- sync mode in validated runtime options
- narrow Oban wrappers under `Scrypath.Oban`
- backend-specific task code under `Scrypath.Meilisearch.Tasks`

If operator tooling ignores those boundaries and reads backend/job-runner internals directly, Scrypath loses the ability to add a second backend without redesigning ops APIs.

**Prevention:**
1. Define operator concepts at the Scrypath layer:
   - sync attempt
   - sync outcome
   - document drift
   - reindex generation
   - backend task handle
2. Build adapters from Oban jobs and Meilisearch tasks into those concepts.
3. Keep any Oban- or Meilisearch-specific detail nested, optional, and clearly marked as implementation detail.
4. For manual sync mode, ensure the same operator concepts still exist, even if fewer signals are available.
5. Refuse milestone work that requires users to run Oban Web or parse backend-native task payloads just to use Scrypath’s core operator story.

**Milestone owner:** Phase 2 "Operator primitives."

### Pitfall 6: Shipping backend-native search power through the common query API
**Direction:** richer backend-native search power
**Severity:** High

**What goes wrong:** Backend-native features such as richer filters, ranking controls, facets, typo behavior, nested fields, or future semantic features are exposed by stretching the existing common query struct. The common path becomes confusing, defaults stop being portable, and hydration semantics get surprising.

**Why it happens:** Once the library has a common `Query` struct, maintainers try to keep "one way to search" even when the engines no longer align.

**What successful libraries did better:**
- Scout exposes engine-specific configuration and driver behavior explicitly instead of pretending advanced features are equal across drivers.  
  Source: https://laravel.com/docs/11.x/scout
- Searchkick keeps a common feel but still points users to engine docs for advanced options and requires explicit reindexing when mappings/indexed data change.  
  Source: https://github.com/ankane/searchkick

**Prevention:**
1. Freeze the current common path for one more milestone: text query, declared filters, declared sorts, pagination, raw hits, explicit hydration.
2. Put backend-native power behind a separate namespace:
   - `Scrypath.Meilisearch.search/3` style backend modules, or
   - an explicit `backend_query` input that bypasses common-path validation
3. Never overload `filter` or `sort` to mean backend-native query DSL.
4. Document that backend-native search returns backend-native semantics and may weaken portability.
5. Require examples showing both raw-hit access and hydration behavior for every backend-native feature added.

**Milestone owner:** Phase 1 "Search surface policy" before feature implementation.

## Moderate Pitfalls

### Pitfall 7: Confusing defaults around filtering, sorting, and settings
**Direction:** second backend, backend-native power
**Severity:** Moderate to High

**What goes wrong:** Scrypath picks "helpful" defaults that are cheap in one engine and expensive or invalid in another. Users do not understand which fields are searchable, filterable, sortable, or merely returned.

**Why it happens:** Search engines treat field settings differently:
- Meilisearch defaults all fields to searchable/displayed and requires explicit filterable/sortable settings; changing settings later can trigger full reindex.  
  Sources: https://www.meilisearch.com/docs/getting_started/good_practices and https://www.meilisearch.com/docs/reference/features/filtering
- Typesense can infer/coerce schema when using flexible types, but schema updates can block writes and field typing mistakes show up at indexing time.  
  Source: https://typesense.org/docs/28.0/api/collections.html

**Prevention:**
1. Keep Scrypath schema metadata explicit and minimal.
2. Add backend-specific settings translators that fail loudly on unsupported or ambiguous settings.
3. For any second backend, ship a "default behavior differences" guide before claiming support.
4. Never silently enable more searchability/filterability than the schema declared.
5. Require rebuild/reindex warnings whenever effective backend settings change.

**Milestone owner:** Phase 1 "Adapter contract and settings translation."

### Pitfall 8: Surprising hydration and association behavior
**Direction:** backend-native power, docs/DX
**Severity:** Moderate to High

**What goes wrong:** Users assume search results are hydrated records with full relational semantics, but advanced query behavior is actually operating on indexed projections. Changes to associations, projections, preloads, or backend-native filtering then create mismatches between hits and hydrated records.

**Why it happens:** Search libraries often market "search your models" while the real unit of truth is the projection document.

**What successful libraries did better:**
- Searchkick explicitly notes that association updates are not automatically synced and recommends explicit callbacks when desired. It also provides `search_import` to avoid N+1 import behavior.  
  Source: https://github.com/ankane/searchkick
- Meilisearch Rails lets users disable auto-indexing and perform explicit reindex/import behavior.  
  Source: https://github.com/meilisearch/meilisearch-rails

**Prevention:**
1. Keep "projection first, hydration second" explicit in guides and API docs.
2. For advanced backend-native features, document whether the behavior applies to:
   - indexed projection only
   - hydrated records only
   - or both
3. Add preload/import hooks to second-backend contract work from day one.
4. Refuse feature work that changes hydration semantics implicitly.
5. Add examples where missing hydrated records, stale associations, and partial projections are handled explicitly.

**Milestone owner:** Phase 3 "Advanced query semantics and hydration docs."

### Pitfall 9: Reindex and schema evolution workflows that are technically correct but operationally unsafe
**Direction:** second backend, operator tooling, backend-native power
**Severity:** Moderate to High

**What goes wrong:** Scrypath supports schema/settings mutation, but not safe cutover. Users perform live changes that block writes, temporarily drop capabilities, or leave old/new indexes inconsistent.

**Why it happens:** Search engines make this easy to underestimate:
- Meilisearch recommends configuring settings before adding documents because later changes trigger reindex.  
  Source: https://www.meilisearch.com/docs/getting_started/good_practices
- Typesense warns that in-place schema changes are synchronous and block writes, and explicitly recommends aliases for zero-downtime schema changes.  
  Sources: https://typesense.org/docs/28.0/api/collections.html and https://typesense.org/docs/30.1/api/collection-alias.html

**Prevention:**
1. Make "new generation + backfill + cutover" the only recommended reindex story for any backend that supports aliases/indirection.
2. Require dual-write or catch-up strategy documentation before adding second-backend reindex support.
3. Persist generation/cutover state in operator primitives, not in ad hoc scripts.
4. Add rollback guidance before shipping mutation-heavy features.
5. Do not expose "update settings in place" as the default maintainer guidance.

**Milestone owner:** Phase 2 "Reindex and cutover contract."

## Minor Pitfalls

### Pitfall 10: Treating backend upgrades as a backend-adapter concern instead of a user-facing operational concern
**Direction:** release confidence, second backend
**Severity:** Moderate

**What goes wrong:** Scrypath claims support for a backend version range without teaching users how upgrades actually behave. When the backend changes storage, task, or schema behavior, users blame Scrypath.

**Why it happens:** Library maintainers focus on API compatibility and forget backend upgrade compatibility.

**Evidence:**
- Laravel Scout explicitly tells users to ensure Meilisearch PHP SDK compatibility with the Meilisearch binary and to review Meilisearch breaking changes when upgrading.  
  Source: https://laravel.com/docs/11.x/scout
- Meilisearch documents that databases are only compatible with the version that created them and that dump-based migration remains part of the official upgrade path.  
  Source: https://www.meilisearch.com/docs/resources/migration/updating

**Prevention:**
1. Publish supported backend-version ranges in docs.
2. Add backend-upgrade notes to release notes whenever compatibility assumptions change.
3. Add live matrix verification for supported backend versions before claiming new support.
4. Separate "Scrypath version support" from "backend migration guidance" in docs so users see both.

**Milestone owner:** Phase 0 "Release confidence" and every future backend-support phase.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Release/publication confidence | First public release proves less than expected because tag, changelog, manifest, Hex, and workflow behavior are not checked as one chain | Make the first real Hex release its own phase with version-alignment assertions and a maintainer rollback runbook |
| Second backend exploration | Shipping a public abstraction before proving the second backend through contract tests and docs | Keep the backend seam internal; do contract testing and a written common-path policy first |
| Operator tooling | Shipping too much raw state and recreating a dashboard in the library | Limit the milestone to operator primitives, telemetry, and mix/API surfaces |
| Operator tooling | Binding visibility directly to Oban or Meilisearch internals | Normalize to Scrypath-level concepts with optional backend/job-runner details |
| Backend-native search power | Leaking backend-native knobs into `Scrypath.Query` and common options | Create a clearly separate advanced namespace or escape hatch |
| Backend-native search power | Surprising hydration/filter behavior because indexed projection and Ecto record semantics diverge | Document projection-first semantics, add explicit examples, and keep hydration opt-in/explicit |
| Backend-native search power | Reindex/settings changes become implicit behavior changes | Require explicit rebuild/cutover docs and warnings before feature release |

## Recommended Scope Guardrails For The Next Milestone

1. Do not combine second-backend support and backend-native search-power expansion in the same milestone.
2. If the next milestone is release-confidence-led, reserve at least one phase purely for real publication verification and adoption feedback collection.
3. If the next milestone is second-backend-led, start with contract definition and settings translation, not user-facing API growth.
4. If the next milestone is operator-tooling-led, stop at primitives plus host-app integration guidance; do not build UI product surface.
5. If the next milestone is backend-native-power-led, keep the common query API frozen and add clearly non-portable advanced entrypoints.

## Sources

- Laravel Scout docs: https://laravel.com/docs/11.x/scout (HIGH)
- Searchkick README/docs: https://github.com/ankane/searchkick (MEDIUM-HIGH; repository docs rather than formal versioned docs)
- Haystack best practices: https://django-haystack.readthedocs.io/en/latest/best_practices.html (MEDIUM)
- Haystack signal processor docs PDF: https://django-haystack.readthedocs.io/_/downloads/en/v3.2.1/pdf/ (MEDIUM)
- Meilisearch Rails README: https://github.com/meilisearch/meilisearch-rails (MEDIUM-HIGH)
- Release Please Action README: https://github.com/googleapis/release-please-action (HIGH)
- GitHub Actions workflow triggering docs: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow (HIGH)
- Meilisearch indexing good practices: https://www.meilisearch.com/docs/getting_started/good_practices (HIGH)
- Meilisearch filtering docs: https://www.meilisearch.com/docs/reference/features/filtering (HIGH)
- Meilisearch task webhooks docs: https://www.meilisearch.com/docs/learn/async/task_webhook (HIGH)
- Meilisearch upgrade/migration docs: https://www.meilisearch.com/docs/resources/migration/updating (HIGH)
- Typesense syncing guide: https://typesense.org/docs/guide/syncing-data-into-typesense.html (HIGH)
- Typesense collections/schema update docs: https://typesense.org/docs/28.0/api/collections.html (HIGH)
- Typesense collection alias docs: https://typesense.org/docs/30.1/api/collection-alias.html (HIGH)
