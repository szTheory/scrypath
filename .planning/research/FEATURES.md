# Feature Landscape

**Domain:** Ecto-native search indexing and orchestration library for Elixir/Phoenix
**Project:** Scrypath
**Researched:** 2026-04-16
**Overall recommendation:** Make the next milestone a public release trust milestone with operator visibility, not a breadth milestone.

## Executive Summary

Scrypath has already shipped the functional core that comparable libraries use to win adoption: schema integration, sync modes, reindexing, search, hydration, and Phoenix-friendly docs. The next milestone should not behave like v1 is missing basic search features. The real gap is turning launch-readiness evidence into public trust: one real Hex release path, excellent first-install flow, explicit operational recovery guidance, and enough status tooling that teams can trust Scrypath in production without treating it as opaque magic.

Across the four candidate directions, the highest adoption leverage is the combination of:

1. real public/package release confidence, and
2. operator tooling for drift, failed work, and recovery status.

That pairing matches what strong integration libraries actually optimize for. Searchkick, Laravel Scout, and Meilisearch Rails all make adoption easy first, then make background sync, imports, reindexing, and failure recovery explicit. They do not win by launching a grab bag of advanced query features or by advertising backend interchangeability before the operational model is proven.

For Scrypath specifically, second-backend breadth and richer backend-native search power both have real eventual value, but they are weaker next-milestone bets. A second public backend increases maintenance and API pressure before public users have validated the current contract. Richer Meilisearch-native query features can create demo appeal, but they mostly help once teams already trust install, sync, recovery, and release quality.

## Direction Comparison

| Direction | User value | Adoption leverage | Ecosystem fit | Recommendation |
|-----------|------------|-------------------|---------------|----------------|
| First real public/package release path and release-confidence work | Very high | Very high | Elixir OSS users expect `mix deps.get`, HexDocs, stable versions, and predictable package ownership | **In next milestone** |
| Operator tooling for drift / failed work / recovery status | High | High | Matches Oban/Telemetry/Ecto expectations and production reality | **In next milestone** |
| Richer backend-native search power | Medium to high for power users | Medium | Valuable once core adoption exists; Meilisearch supports many advanced settings already | **Later milestone** |
| Backend breadth (second public backend) | Medium | Low to medium until repeated user demand exists | Raises abstraction and support burden immediately | **Keep out for now** |

## Table Stakes

These are the features users will expect from the next Scrypath milestone if the goal is real public adoption rather than internal readiness.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Verified Hex publish path with publisher-scoped credentials | Elixir libraries are judged first by whether install/publish/docs work cleanly from Hex | Medium | Hex explicitly centers package metadata, docs publication, and CI publishing keys |
| Copy-pasteable install-to-first-index docs using Hex package flow | Great library DX in Elixir starts with a short, explicit setup path and HexDocs examples | Low | The first 15 minutes matter more than adding more search features |
| Compatibility/support policy visible in docs | OSS library users expect clear Elixir/OTP/Ecto support boundaries before adopting infra-adjacent deps | Low | Include supported versions and upgrade guidance |
| Release smoke verification after publish | Public release confidence is not real until package install, docs publish, and example usage are tested from the published artifact | Medium | This closes the gap between CI evidence and real user experience |
| Operator-visible sync status for queued/manual flows | Once sync can fail asynchronously, teams expect to answer “is search caught up?” | High | Oban and Telemetry make this idiomatic in Elixir |
| Failed work inspection and retry/recovery guidance | Background indexing failure is an operational event, not a hidden edge case | Medium | Similar libraries all surface reindex/import/retry workflows |
| Drift/reconciliation entry point | Search state will eventually drift in real systems; teams expect a supported way to detect and reconcile it | High | Start with explicit coarse-grained checks, not “perfect automatic healing” |
| Escape hatches to raw backend operations | Search integration libraries earn trust by covering the 80% path without trapping advanced users | Medium | Searchkick and engine integrations keep backend-native escape hatches available |

### Table-Stakes Feature Shape

Recommended shape for the next milestone:

- **Release confidence**
  - published package smoke check from a clean sample app
  - explicit ownership/publisher docs
  - HexDocs-first install guide
  - changelog/versioning/release notes users can trust
- **Maintainer/developer UX**
  - one “start here” guide for Phoenix/Ecto users
  - one “production sync modes” guide comparing inline vs Oban vs manual
  - one “reindex and recovery” guide with copy-pasteable commands
- **Operations**
  - status API or mix task that answers basic questions:
    - pending work count
    - last successful sync/reindex timestamp
    - failed jobs or failed batches
    - active reindex status
  - retry/reconcile entry points for failed or stale work

Concrete example shapes:

```elixir
# Example shape, not a locked API
Scrypath.status(Post)
#=> %{mode: :oban, pending: 14, failed: 2, last_success_at: ~U[...] }

Scrypath.reconcile(Post, limit: 1_000)
Scrypath.retry_failed(Post)
```

```bash
# Example operator ergonomics
mix scrypath.status Post
mix scrypath.retry_failed Post
mix scrypath.reconcile Post --since 2026-04-01
```

The important point is not the exact command names. It is that Scrypath should make operational state legible without forcing every team to invent its own visibility layer first.

## Differentiators

These are the features that would make the next milestone feel unusually strong for the Elixir ecosystem.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Public-release trust loop | Scrypath becomes installable, documentable, and verifiably usable as a package, not just “ready in theory” | Medium | High leverage because it turns roadmap confidence into real adoption feedback |
| Operator clarity as part of the product | Most libraries stop at callbacks/jobs; Scrypath can stand out by treating lag, drift, and recovery as first-class | High | Strong fit with Oban + Telemetry + operational honesty |
| Explicit sync-mode guidance with tradeoffs | Elixir teams value explicitness over magic; good docs can reduce support burden and failed adoption | Low | “Use inline for dev, Oban for production, manual for imports and controlled workflows” should be obvious |
| Better escape hatches than competitor-style magic | A small public API plus backend access for advanced cases is more trustworthy than a giant abstraction | Medium | This is especially important before adding backend breadth |
| Docs flow designed for Phoenix teams | The best analogs win because the first mile is tiny; Scrypath can match that while remaining Ecto-first | Low | README -> HexDocs guide -> sync mode guide -> operator guide -> raw API docs |

### Why this beats other directions right now

- **Release confidence** has the strongest immediate adoption leverage because no one can validate trust in a library they cannot consume as a normal package.
- **Operator tooling** compounds that value because the first serious production question after install is “how do I know search is healthy?”
- **Backend-native search power** helps later, once users are already indexing successfully.
- **Backend breadth** only helps if adoption pressure is already coming from users who cannot adopt Meilisearch-first Scrypath.

## Anti-Features

These should stay out of the next milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Second public backend now | Premature public breadth increases API pressure, testing matrix cost, docs surface, and support burden before demand is proven | Keep the internal adapter seam healthy and collect real requests first |
| “Universal” backend-agnostic query DSL | Search engines differ materially in settings, tasks, ranking, filters, and reindex workflows; fake sameness creates bad APIs | Keep a compact common API and explicit backend-native escape hatches |
| Rich relevance features as headline milestone scope | Synonyms, typo tuning, facets, ranking rules, and other backend-native power are useful, but they do not fix adoption/trust bottlenecks first | Document raw access now; productize the highest-demand capabilities later |
| Automatic silent drift healing | Hidden repair behavior makes operational debugging worse and can surprise users with load spikes or unexpected writes | Start with visibility, explicit reconcile commands, and documented tradeoffs |
| Heavy runtime/dashboard requirement in the core package | Elixir libraries should stay explicit and composable; a required UI or supervisor-heavy control plane would fight ecosystem norms | Prefer mix tasks, Telemetry hooks, and optional integrations |
| Docs that imply strong consistency or “it just stays in sync” | That breaks the project’s stated operational honesty and sets users up for production surprises | Keep eventual consistency, delete races, and reindex semantics explicit |

### Concrete Footguns to Avoid

- Delete jobs that reload the source row after the DB delete has committed.
  - Meilisearch Rails and Algolia’s Rails docs both call out this failure mode directly.
- Shipping a second backend before drift/recovery/status semantics are stable.
  - This multiplies operational ambiguity, not just code.
- Adding Meilisearch-specific settings DSL for every engine knob immediately.
  - It creates a public API that is hard to generalize later and easy to regret.
- Treating release automation success as equivalent to package-consumer success.
  - Hex publish, docs publish, install, and sample app boot all need to be validated from the published artifact.
- Hiding operational state inside logs only.
  - Phoenix/Oban teams expect inspectable state and Telemetry, not “grep production logs.”

## Sequencing Recommendation

## Recommended Next Milestone

**Milestone theme:** `Public Release Trust and Operator Visibility`

This should be one cohesive milestone, not two unrelated tracks. The point is to make Scrypath feel safe to adopt and operable in production as a Meilisearch-first library.

### Include in the next milestone

1. **First real public/package release path**
   - real Hex publish with publisher-scoped credentials
   - post-publish smoke verification from a clean consumer app
   - HexDocs install/start guide validated against the published package
   - release checklist and compatibility matrix visible to users

2. **Operator tooling for trust**
   - status visibility for queued/manual indexing
   - failed work inspection + retry path
   - basic drift/reconcile workflow
   - explicit docs for recovery, backfills, and “what happened?” questions

3. **DX polish that serves adoption**
   - “choose your sync mode” guide
   - “first production rollout” guide
   - “reindex without panic” guide
   - backend-native escape hatch examples for advanced teams

### Defer to later milestones

1. **Richer backend-native Meilisearch search power**
   - Promote only after real users consistently ask for first-class support for:
     - ranking rules
     - synonyms
     - facets/facet search
     - typo tuning
     - advanced filters/sort ergonomics
   - Until then, prefer raw backend access plus focused examples.

2. **Second public backend**
   - Revisit only after:
     - public users request it repeatedly,
     - operator/status/recovery semantics are stable,
     - the common API boundary is proven under public adoption.

## Sequencing Tradeoffs

```text
Release confidence -> Operator visibility -> Adoption feedback -> Search power OR backend breadth
```

Why this order:

- A real package release creates the earliest possible external signal.
- Operator tooling prevents the first adopters from becoming support incidents.
- Adoption feedback then tells Scrypath whether the next pressure is “we need more Meilisearch power” or “we need another backend.”
- Doing breadth or deeper search power first would optimize for hypothetical users while delaying trust for actual users.

## MVP Recommendation

Prioritize:

1. Real public Hex release path and post-publish smoke validation
2. Operator status/retry/reconcile surface for async/manual workflows
3. Docs flow that makes install, sync-mode choice, and recovery obvious

Defer:

- **Second backend**: too much API and maintenance pressure before public demand is established
- **Large backend-native search feature surface**: useful, but not the highest-leverage trust/adoption move for the next milestone

## Sources

- Project context: `/Users/jon/projects/scrypath/.planning/PROJECT.md`
- Local research context: `/Users/jon/projects/scrypath/prompts/elixir-opensource-libs-best-practices-deep-research.md`
- Local research context: `/Users/jon/projects/scrypath/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- Local research context: `/Users/jon/projects/scrypath/prompts/elixir-search-lib-deep-research.md`
- Hex publishing docs: https://hex.pm/docs/publish
- Laravel Scout docs: https://laravel.com/docs/12.x/scout
- Searchkick README: https://github.com/ankane/searchkick
- Meilisearch Rails README: https://github.com/meilisearch/meilisearch-rails
- Algolia Rails queue docs: https://www.algolia.com/doc/framework-integration/rails/indexing/queues
- Meilisearch docs on settings, tasks, and indexes:
  - https://www.meilisearch.com/docs/reference/api/settings/list-all-settings
  - https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations
  - https://www.meilisearch.com/docs/resources/internals/indexes
- Oban docs:
  - https://hexdocs.pm/oban/Oban.html
  - https://hexdocs.pm/oban/Oban.Telemetry.html
- Typesense docs:
  - https://typesense.org/docs/guide/laravel-full-text-search.html
  - https://typesense.org/docs/26.0/api/collections.html
