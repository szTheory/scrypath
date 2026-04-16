# Technology Stack

**Project:** Scrypath
**Researched:** 2026-04-16
**Scope:** stack and release choices for the next milestone only
**Overall posture:** keep the core library small, explicit, and Meilisearch-first; add release-confidence tooling and backend capability infrastructure before widening the public backend promise.

## Executive Recommendation

Scrypath's next milestone should stay narrow. The warranted stack move is not "add more engines now"; it is "make the first public release path trustworthy, add capability-aware seams that keep future backend work survivable, and deepen operator visibility without turning the library into a dashboard product."

That yields one coherent v1.2 recommendation:

1. Keep the runtime core unchanged: `Ecto`, `NimbleOptions`, `Req`, `Telemetry`, optional `Oban`.
2. Strengthen release operations: keep Release Please, move release PR automation off bare `GITHUB_TOKEN`, and gate Hex publishing behind a protected GitHub Environment with a publisher-scoped `HEX_API_KEY`.
3. Add dev/test-only contract tooling for future backend work: `Mox` and `StreamData`.
4. Add backend-specific power through explicit Meilisearch-namespaced APIs and validated option schemas, not through a pretend-generic advanced search DSL.
5. Add operator visibility through library APIs, Telemetry, and optional Phoenix/Oban integration patterns, not by taking hard dependencies on dashboard/reporting packages.

## Recommended Stack For v1.2

### Core runtime

No new mandatory runtime dependencies are warranted for v1.2.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | keep support floor `~> 1.17`, test through `1.19` | library runtime | Current floor is still reasonable for OSS adoption; no milestone requirement justifies a floor bump. |
| OTP | keep floor `26`, test through `28` | runtime support window | Matches the current release posture and avoids avoidable compatibility churn before first public adoption. |
| Ecto | keep `~> 3.13` | primary integration surface | Scrypath's product identity is still Ecto-native indexing and orchestration. |
| NimbleOptions | keep `~> 1.1` | public option validation and docs generation | Already present and exactly the right tool for capability-scoped, documented backend options. |
| Req | keep `~> 0.5` | HTTP transport | Already owned internally; no reason to widen the consumer contract. |
| Telemetry | keep `~> 1.4` via dependency tree and public event contract | instrumentation | Operator honesty depends more on stable events than on more runtime packages. |
| Oban | keep `~> 2.21`, optional | durable async sync path | Still the idiomatic Phoenix/Ecto production queue path; keep optional. |

### New dev/test dependencies

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mox` | `~> 1.2` | adapter contract and failure-mode tests | Add now for backend capability contract tests and release-path isolation tests. |
| `stream_data` | `~> 1.1` | property tests for option validation, result normalization, and idempotent contract behavior | Add now if v1.2 introduces richer Meilisearch option schemas or backend capability descriptors. |
| `rhysd/actionlint` | current GitHub Action | workflow validation | Add now to catch release workflow regressions before the first public release. |
| `actions/dependency-review-action` | current GitHub Action | dependency/security review on PRs | Add now for release-confidence operations, especially with workflow and dependency changes. |
| Dependabot for `mix` and `github-actions` | GitHub-native | update hygiene | Add now if not already configured; the release path is now part of the product. |

## Recommended Choices

| Area | Choice | Why | v1.2 or Later |
|------|--------|-----|---------------|
| Release automation | Keep `googleapis/release-please-action@v4`, but authenticate release PR creation with a dedicated GitHub App token or fine-grained bot token | `GITHUB_TOKEN`-created PRs do not trigger downstream workflows; that weakens release-confidence at the exact point Scrypath needs it most. | v1.2 |
| Hex publishing | Keep `mix hex.publish --yes` from CI, but only from a protected GitHub Environment holding a publisher-scoped `HEX_API_KEY` | Hex does not yet offer trusted publishing; current best practice is scoped API keys plus explicit gating. | v1.2 |
| Maintainer auth model | Update maintainer docs/process to Hex 2.4 OAuth + 2FA expectations | As of 2026-03-31, Hex requires 2FA for write-capable OAuth flows; release docs should match reality. | v1.2 |
| Backend breadth | Do not add a second public backend in core `scrypath` yet; instead add internal capability descriptors and adapter contract tests | The first real release should prove the current product before widening the public promise. | v1.2 |
| Second backend target | If real demand appears, choose Typesense as the next backend candidate | It is the closest product shape to Meilisearch and has the cleanest OSS self-hosted HA story among plausible next engines. | later |
| Operator tooling | Build `Scrypath.Operator` / `Scrypath.Status`-style APIs on top of existing Telemetry, Meilisearch task inspection, and optional Oban inspection | This stays idiomatic for Elixir libraries and avoids dashboard-package coupling. | v1.2 |
| Advanced search power | Add explicit `Scrypath.Meilisearch.*` APIs or a `backend_options: [meilisearch: ...]` namespace validated by `NimbleOptions` | This keeps generic search ergonomic while exposing native engine power honestly. | v1.2 |
| Dashboard/reporting dependencies | Do not add `phoenix_live_dashboard`, `telemetry_metrics`, `prom_ex`, or `oban_web` as library dependencies | Those are app-level choices, not core library requirements. Document integration instead. | later/docs only |

## Release-Confidence Stack

### What to add in v1.2

| Choice | Why it fits Scrypath |
|--------|----------------------|
| Protected GitHub Environment for publish job | Keeps `HEX_API_KEY` scoped to release publishing and allows required reviewer approval before public publish. |
| Dedicated release bot identity for Release Please | Release PRs can run CI normally, which matters for a library whose release artifact includes docs and package metadata. |
| `actionlint` workflow | Release workflows are code; linting them is cheaper than debugging a broken first public tag. |
| Dependency Review + Dependabot | Supply-chain discipline is part of release trust for a public Hex package. |
| Keep `mix verify.phase10` and `mix hex.publish --dry-run --yes` as maintainer-owned gates | Matches Hex's warning that fully automated publishing can hide important warnings. |

### What not to add yet

| Not Yet | Why |
|---------|-----|
| Trusted publishing flow for Hex | Hex said on 2026-03-31 that trusted publishing is planned, not available now. |
| Separate release orchestration service or custom release scripts | Release Please plus a protected publish environment is enough. |
| Multi-stage artifact signing stack | Too much ceremony for the current library maturity; fix the release path basics first. |

### Release tradeoffs

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| `GITHUB_TOKEN` for Release Please | simplest setup | release PRs and tags do not trigger follow-on workflows | reject for v1.2 |
| Fine-grained PAT | simple and practical | long-lived secret, tied to a user identity | acceptable fallback |
| GitHub App token | least-privilege, repo/org scalable, avoids personal identity coupling | more setup work | preferred |

## Backend Breadth Recommendation

### v1.2 position

Do **not** ship a second public backend in v1.2.

Ship the infrastructure that makes a second backend safe later:

- adapter capability descriptors
- contract tests shared across adapters
- backend-specific modules for advanced behavior
- docs that state clearly which APIs are generic and which are Meilisearch-only

This is the least-surprise move. Laravel Scout is useful here as a lesson, not a blueprint: the driver model is good, but once multiple engines exist, engine-specific schema and query rules leak into the public contract immediately. Scrypath should learn from the clean seam, not copy the public breadth too early.

### Second backend candidates

| Candidate | Ecosystem Fit | What It Gets Right | Why Not v1.2 |
|----------|----------------|--------------------|---------------|
| Typesense | closest to current Meilisearch-first product shape | strong self-hosted OSS HA story, familiar document/search/facet model, natural next engine for Phoenix/Ecto teams | still widens the surface before the first release proves demand |
| OpenSearch / Elasticsearch | powerful and mature | huge ecosystem and advanced relevance features | much heavier ops story and much broader API surface; would distort Scrypath's product shape |
| Algolia | polished managed DX | clear search product ergonomics | commercial/managed-first fit does not match current Scrypath positioning |

### Product-shape lesson from adjacent libraries

| Library | Lesson Scrypath should copy | Footgun Scrypath should avoid |
|--------|------------------------------|-------------------------------|
| Searchkick | async and reindex workflows are first-class product surface | broad convenience APIs can tempt the library into hiding backend realities |
| Laravel Scout | clean driver seam plus engine-specific escape hatches | "driver interchangeable" perception breaks down once backend-specific schema and query features diverge |
| meilisearch-rails | explicit settings, async queue hooks, zero-downtime reindex patterns, direct delete-by-id in background jobs | automatic callbacks can hide operational cost and delete races |

## Operator Tooling Stack

### What is warranted in v1.2

Use the existing Elixir-native building blocks instead of adding a monitoring subsystem:

| Choice | Why |
|--------|-----|
| Stable Telemetry event schema as a compatibility surface | This is the idiomatic library observability contract in Elixir. |
| Meilisearch task inspection via `/tasks`, `/health`, and `/stats` | This gives real backend status, failed work details, and queue state without inventing Scrypath-specific truth. |
| Oban inspection only when `sync_mode: :oban` is configured | Keeps queue visibility accurate and optional. |
| Library APIs returning structured status structs/maps | Fits Ecto/Phoenix usage better than a built-in admin UI. |
| Phoenix docs/examples for LiveDashboard and Oban integration | Gives users an operator story without taking on UI dependencies. |

### What not to add yet

| Not Yet | Why |
|---------|-----|
| Built-in Phoenix LiveDashboard page as a hard dependency | Phoenix is important for adoption, but Scrypath must remain Ecto-first and Phoenix-friendly, not Phoenix-bound. |
| `telemetry_metrics` or `prom_ex` as core deps | Metrics reporters belong to applications. Scrypath should emit events, not choose reporters for users. |
| Polling GenServers just for status bookkeeping | Process-heavy operator code would violate the current "mostly functions" library posture. |

## Richer Backend-Native Search Power

### What is warranted in v1.2

Expose more Meilisearch power, but only under explicit Meilisearch namespacing.

Recommended public shape:

- keep `Scrypath.search/3` focused on the cross-backend common path
- add `Scrypath.Meilisearch.search/3` or `backend_options: [meilisearch: ...]`
- validate all backend-native options with `NimbleOptions`
- return explicit result structs or maps that keep raw backend payloads accessible without making them the only contract

### Meilisearch features worth exposing next

| Feature | Why it belongs | Notes |
|---------|----------------|-------|
| facets / facet distribution | standard search UX need; Meilisearch supports this cleanly | generic API can stay simple; expose richer facet output in Meilisearch-specific API |
| highlighting / cropping | practical Phoenix UI value | keep hydration explicit; do not blur backend hit payload and Ecto record |
| ranking score and ranking score details | useful for debugging relevance | keep this clearly backend-native |
| performance details | valuable for operator honesty and search tuning | especially useful when users say "search feels slow" |
| multi-search | useful, but only as explicit engine-native functionality | do not pretend cross-backend parity exists yet |

### What not to add yet

| Not Yet | Why |
|---------|-----|
| A normalized advanced search DSL across all future backends | Premature abstraction; the engines diverge exactly where "advanced" starts. |
| Vector / semantic / hybrid search surface | This widens product scope faster than operator and release maturity. |
| Backend-native analytics/recommendations | not aligned with Scrypath's current Ecto-native indexing wedge |

## Versioning And Release Implications

| Decision | Implication |
|---------|-------------|
| Keep advanced engine power in namespaced Meilisearch APIs | Allows additive minor releases without destabilizing `Scrypath.search/3`. |
| Keep capability descriptors internal until a second backend is real | Avoids locking in a public abstraction too early. |
| Treat Telemetry event names and metadata keys as semver-relevant once documented | Operator tooling will depend on them. |
| Keep release automation changes inside the existing Release Please + Hex flow | The milestone can improve trust without re-teaching the release process. |
| Stay pre-1.0 until the first real release and early adoption feedback land | Scrypath still needs room to adjust public shape, especially around operator and engine-specific APIs. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Release PR auth | GitHub App token | `GITHUB_TOKEN` | GitHub says events triggered by `GITHUB_TOKEN` do not create new workflow runs. |
| Publish secret model | protected environment + publisher-scoped `HEX_API_KEY` | broad repo secret shared across workflows | weaker blast-radius control |
| Backend breadth | delay second public backend | ship Typesense now | splits focus before first release learns from real users |
| Advanced search API | Meilisearch-namespaced options | one giant generic options bag | violates least surprise and makes later semver harder |
| Operator tooling | status APIs + docs integrations | built-in dashboard runtime | too heavy and too Phoenix-coupled for current product stage |

## What Not To Use Yet

- Public multi-backend facade as a first-class v1.2 selling point
- OpenSearch or Elasticsearch support in the core package
- Built-in dashboard/reporting dependencies in the library runtime
- Vector or hybrid search dependencies
- Hex "trusted publishing" assumptions before Hex actually ships it
- A catch-all raw map API that makes advanced search behavior undocumented and unvalidated

## Concrete v1.2 Checklist

1. Add `mox` and `stream_data` to `:test` deps.
2. Update release workflow to use a dedicated release bot identity instead of bare `GITHUB_TOKEN`.
3. Move Hex publish to a protected environment with required reviewer approval.
4. Update `docs/releasing.md` for Hex 2.4 OAuth + 2FA reality.
5. Add workflow linting and dependency review.
6. Introduce Meilisearch-native validated option schemas for the next tranche of search features.
7. Add contract tests that separate generic search behavior from Meilisearch-only behavior.
8. Add status/inspection APIs that surface Meilisearch tasks and optional Oban job state without adding runtime UI deps.

## Later, After v1.2

- Decide on Typesense only if real users push on backend breadth.
- If Typesense happens, prefer a clearly isolated adapter surface and keep advanced engine behavior backend-specific.
- Revisit Hex trusted publishing only when Hex actually ships it.
- Revisit app-level dashboard helpers only after the operator API settles.

## Sources

### Official / primary

- Hex publish docs: https://hex.pm/docs/publish
- Hex v2.4 release notes, 2026-03-31: https://hex.pm/blog/hex-v24-released
- GitHub `GITHUB_TOKEN` behavior: https://docs.github.com/en/actions/concepts/security/github_token
- Release Please action docs: https://github.com/marketplace/actions/release-please-action
- Meilisearch filtering/sorting/faceting docs: https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/overview
- Meilisearch task API: https://www.meilisearch.com/docs/reference/api/tasks
- Meilisearch task management guide: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/manage_task_database
- Meilisearch ranking score docs: https://meilisearch.dev/docs/capabilities/full_text_search/relevancy/ranking_score
- Meilisearch performance debugging docs: https://www.meilisearch.com/docs/capabilities/full_text_search/advanced/debug_search_performance
- Typesense search API: https://typesense.org/docs/30.0/api/search.html
- Typesense multi-search API: https://typesense.org/docs/29.0/api/federated-multi-search.html
- Oban error handling / telemetry example: https://hexdocs.pm/oban/error_handling.html
- Telemetry docs: https://hexdocs.pm/telemetry/telemetry.html
- NimbleOptions docs: https://hexdocs.pm/nimble_options/NimbleOptions.html

### Adjacent library patterns

- Laravel Scout docs: https://laravel.com/docs/11.x/scout
- Searchkick README: https://github.com/ankane/searchkick
- meilisearch-rails README: https://github.com/meilisearch/meilisearch-rails

### Local project context

- `/Users/jon/projects/scrypath/.planning/PROJECT.md`
- `/Users/jon/projects/scrypath/docs/releasing.md`
- `/Users/jon/projects/scrypath/.github/workflows/release-please.yml`
