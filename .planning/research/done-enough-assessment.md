# Scrypath "Done Enough" Assessment — 2026-05-25

**Replaces:** `.planning/threads/scrypath-doneness-assessment-2026-05-24.md`
**Prior estimate:** ~86% (as of 2026-05-24, pre-v1.23/v1.24)
**Updated estimate:** ~91–93%

---

## What shipped since the last assessment

Since the 86% call on 2026-05-24:

- **v1.23** closed: outside-adopter evidence reviewed, support-truth reconciled, evidence-backed papercuts fixed with regression guards.
- **v1.24** closed: `sync_related/3` public API with inline + Oban fan-out, `RelatedWorker` actionable error returns, canonical related-data guide, hermetic verify gate, Phoenix fan-out example.

The two highest-leverage correctness gaps identified in the prior assessment (#1 outside-adopter evidence, #2 related-data propagation) both shipped. The remaining ranked gaps are:

1. Tenant-safe search access (`AUTH-01`)
2. High-cardinality facet value search (`FACET-UX-01`)
3. Autocomplete / suggestions (Tier B5, explicitly deferred)

---

## How comparable libraries are structured

### Searchkick (Ruby/Rails, ~6,700 GitHub stars)

Searchkick is the closest analog. It provides:

- Schema declaration: `searchkick` macro on the model
- Sync modes: inline, async, queue, manual (four strategies, matches Scrypath)
- Explicit projection: `search_data` method (matches Scrypath's declaration + settings)
- Autocomplete and "did you mean" suggestions (built-in; Scrypath does not have this)
- Facets / aggregations (Scrypath has this, with more explicit facet APIs)
- Typo tolerance, misspelling correction, synonyms (via Elasticsearch; Scrypath delegates to Meilisearch settings)
- Highlighting, similar items, geospatial (Scrypath does not provide these wrappers)
- Personalization + conversion tracking via Searchjoy (out-of-scope for Scrypath by design)
- Hybrid/semantic search via KNN (explicitly out of scope for Scrypath)
- Zero-downtime reindex, parallel reindex (Scrypath has `reindex/2` and `backfill/2`)
- **Multi-tenancy:** application-level concern. Searchkick documents using a Proc on `:index_name` for per-tenant indexes, but multi-tenant isolation via token-based filtering is left entirely to the application. No native Searchkick API for this.

What Searchkick does NOT provide that Scrypath does: explicit operator recovery APIs (`sync_status/2`, `failed_sync_work/2`, `retry_sync_work/2`, `reconcile_sync/2`), an admin LiveView UI, a playbook system, or explicit fan-out propagation. Searchkick's position is: associated record syncing is the application's job (no `sync_related` equivalent is built in).

### Laravel Scout (PHP/Laravel, official package)

Scout is the canonical architecture template. It provides:

- Trait-based declaration: `use Searchable` on Eloquent model
- Auto-sync via model observers (implicit; Scrypath is explicit by design)
- Explicit projection hook: `toSearchableArray()` (matches Scrypath's declaration)
- Conditional indexing: `shouldBeSearchable()`, `searchIndexShouldBeUpdated()` (Scrypath does not expose these hooks; it is explicit at the call site)
- Queue integration: configurable, automatic (Scrypath requires explicit Oban wiring, which is a different tradeoff)
- Soft-delete support (Scrypath does not have a soft-delete first-class concept)
- Batch import commands (Scrypath has `backfill/2`)
- Index pause: `withoutSyncingToSearch` (Scrypath does not expose this)
- Per-model engine selection: `searchableUsing()` (out of scope for Scrypath v1)
- Multiple engine drivers: Algolia, Meilisearch, Typesense, database, collection (explicitly out of scope for Scrypath v1)
- **Multi-tenancy:** no built-in support. The official Scout docs contain nothing about tenant isolation. Applications must implement via index naming or filter-based scoping themselves.
- **Autocomplete/suggestions:** not built in. Engine-specific APIs or custom application code.
- **Operator recovery, admin UI, drift tooling:** none. Scrypath is ahead here.

### meilisearch-rails (official Meilisearch Ruby gem)

- Model-based indexing with macro declaration
- After-save / after-destroy hooks (implicit; Scrypath is explicit)
- `touch` / `after_touch` for association propagation (documented but manual; equivalent to Scrypath's `sync_related/3`)
- Scoped search (add filter conditions at query time)
- Delete race condition documented and addressed: jobs must carry enough payload to delete without reloading the row (Scrypath handles this)
- **Multi-tenancy / tenant tokens:** open enhancement issue (#152, unresolved as of 2025). The gem does not yet have standardized tenant token support. Applications must manually instantiate the client with tenant tokens. The community is still debating whether this is library scope or application scope.

### Django Haystack (Python/Django, ~3,800 GitHub stars)

- Multi-backend support: Elasticsearch, Solr, Whoosh, Xapian (explicitly what Scrypath avoids)
- Autocomplete via NgramField / EdgeNgramField (Scrypath does not have this)
- Multiple index routing (Scrypath has multi-index federation via `search_many/2`)
- Cautionary tale: Open edX ripped Haystack out because the abstraction layer became an obstacle. Scrypath's explicit-over-magic posture directly learns from this failure.
- No built-in multi-tenancy.

---

## What Phoenix SaaS developers actually need from a search library

Based on the research brief and ecosystem evidence, the top 5 jobs-to-be-done:

1. **First searchable schema**: One declaration, a working search flow in under 30 minutes. Scrypath covers this with `use Scrypath`, golden-path guide, and example app.

2. **Request-edge Phoenix flow**: URL params, LiveView state, context-owned search calls. Scrypath covers this with the v1.20–v1.22 query toolkit, `SearchModule`, and Phoenix helper wrappers.

3. **Write-path sync that does not surprise them**: Inline for low traffic, Oban for production, manual for imports. Scrypath covers all three modes explicitly.

4. **Operator recovery when things go wrong**: Failed sync inspection, retry, drift detection, reconcile. Scrypath covers this more thoroughly than any comparable library with `sync_status/2`, `failed_sync_work/2`, `retry_sync_work/2`, `reconcile_sync/2`, and the `scrypath_ops` admin UI.

5. **Related-data propagation**: When an author name changes, blog posts need to reindex. Scrypath now covers this with `sync_related/3`.

What Phoenix SaaS developers also want but is not covered:

- **Tenant-safe search access**: The top remaining gap. Not covered by any comparable library out-of-the-box either (see below), but developers expect guidance and ergonomic helpers, not just "index filtering is your problem."
- **Autocomplete / suggestions**: Commonly expected, but typically wired manually against the engine API. Not covered by Scout or meilisearch-rails natively. A gap, but not a blocker for most initial adoption decisions.
- **Soft-delete awareness**: Scout handles this natively; Scrypath does not expose a `shouldBeSearchable?`-style hook. Low-severity gap.

---

## The tenant auth question specifically

### Is this a library problem or an application problem?

The answer from the ecosystem evidence: **it is both, but the library must own the ergonomics layer**.

Searchkick's answer: application responsibility. Use a Proc on `:index_name` or filter with `.where(tenant_id: current_tenant.id)`. No native tenant token support.

meilisearch-rails' answer: unresolved. Open enhancement issue. Developers are confused about whether to instantiate the client themselves or wait for gem support.

Laravel Scout's answer: not in scope. Documentation is silent on multi-tenancy entirely.

Meilisearch's own framing: tenant tokens are a **shared responsibility**. The application must:
1. Ensure documents carry a tenant identifier
2. Generate tenant tokens on the backend with embedded filter rules
3. Pass tokens to the frontend for scoped search requests

Meilisearch handles enforcement (the filter is baked into the token; it cannot be bypassed at query time).

**What this means for Scrypath:** The comparables have set a low bar. None of the major Rails-ecosystem libraries provide first-class tenant token generation, delivery, or search-call wrapping. Scrypath does not need to fully automate multi-tenancy to be credible. What would make Scrypath meaningfully better than the field:

- A documented `tenant_scope:` option on `use Scrypath` to declare the tenant identifier field
- A `Scrypath.tenant_token/3` helper (or guidance on where to put token generation) that wraps Meilisearch's JWT generation with the right search rules
- A guide: "Scrypath and multi-tenant SaaS" that shows the correct shared-index + tenant token architecture, explicitly contrasting with the index-prefix anti-pattern

This is a documentation + thin API gap, not a fundamental architecture gap. The underlying mechanism (Meilisearch tenant tokens) is already available. Scrypath just needs to make it ergonomic and documented.

---

## Gap analysis against comparable library feature sets

| Capability | Searchkick | Laravel Scout | Scrypath | Delta |
|---|---|---|---|---|
| Schema declaration macro | Yes | Yes | Yes | Parity |
| Explicit projection hook | Yes (search_data) | Yes (toSearchableArray) | Yes (field declarations) | Parity |
| Inline sync | Yes | Yes (auto + queue) | Yes | Parity |
| Async/queue sync | Yes (4 modes) | Yes (automatic) | Yes (Oban) | Parity |
| Manual sync | Yes | Yes | Yes | Parity |
| Backfill / import | Yes | Yes (scout:import) | Yes (backfill/2) | Parity |
| Zero-downtime reindex | Yes | Via engine | Yes (reindex/2) | Parity |
| Facets | Yes | Config only | Yes (hierarchical, disjunctive) | Scrypath ahead |
| Multi-index search | Yes | Via engine | Yes (search_many/2, federation) | Parity+ |
| Per-query tuning | Via opts | Via callback | Yes (pipeline) | Parity+ |
| Operator recovery APIs | No | No | Yes (full surface) | Scrypath ahead |
| Admin UI | No | No | Yes (scrypath_ops) | Scrypath ahead |
| Related-data propagation | Manual callbacks | Via observers | Yes (sync_related/3) | Parity+ |
| Soft-delete awareness | Yes | Yes | No | Gap (minor) |
| Conditional indexing hook | No (should_index?) | Yes | No | Gap (minor) |
| Multi-tenancy (tenant tokens) | App responsibility | Not documented | Not yet | Gap (significant) |
| Autocomplete / suggestions | Yes (built-in) | No | No | Gap (moderate, deferred) |
| Highlighting | Yes | Via engine | No | Gap (minor) |
| Typo tolerance | Via Elasticsearch | Via engine | Via Meilisearch settings | Parity (engine-level) |
| Multi-backend support | Yes | Yes (4 engines) | Meilisearch only | By design, not a gap |
| Hybrid/semantic search | Yes (KNN) | No | No (out of scope) | By design |

**Significant gaps (bloc adoption): 1** — tenant-safe search access.
**Moderate gaps (friction, not blockers): 1** — autocomplete/suggestions (but none of the comparables provide this natively; it is engine-level work).
**Minor gaps (edge cases, unlikely to block initial adoption): 3** — soft-delete awareness, conditional indexing hook, highlighting wrappers.
**By-design non-gaps: 3** — multi-backend, hybrid/semantic, analytics/personalization.

---

## The "good enough to stop" test

The prior assessment identified five signals to watch. Here is the current state of each.

### Signal 1: Does Scrypath cover the five JTBD jobs completely?

- First searchable schema: Yes.
- Request-edge Phoenix flow: Yes (post v1.20-v1.22).
- Write-path sync: Yes (all three modes, always was).
- Operator recovery: Yes (more thorough than any comparable).
- Related-data propagation: Yes (shipped in v1.24).

Four of five jobs are fully covered. The fifth (tenant-safe access) is partially covered: the filtering mechanism exists (Meilisearch tenant tokens), the declaration pattern is not yet ergonomic, and the guide does not exist.

### Signal 2: Are outside adopters blocked on something Scrypath doesn't have?

The v1.23 outside-adopter evidence reconciliation shipped. The post-v1.19 guardrail is still holding: do not reopen feature work without concrete adopter friction evidence. The top candidate for that friction is `AUTH-01`.

### Signal 3: Do the comparables have something that would cause a Phoenix team to pick them over Scrypath?

If a Phoenix team is looking at this today, they would find that Scrypath is ahead of or equal to all comparables on operator ergonomics, facet APIs, and related-data propagation. The one area where they might look elsewhere is autocomplete (Searchkick has it). But autocomplete is typically wired against the engine API directly in every ecosystem — even Searchkick's autocomplete is just word-start matching piped through a controller endpoint. That is a thin integration, not a fundamental feature gap.

Multi-tenancy is more credible as a switching concern: a team building a B2B SaaS product might decide Scrypath does not help them enough with tenant isolation. Currently, neither Searchkick nor Scout provides this natively either, but the Meilisearch ecosystem is actively developing guides and library support. Scrypath is currently behind the Meilisearch official guides on this topic.

### Signal 4: Has the library hit stable API shape?

Yes. The core API has been stable since v1.0. The v1.19 audit declared the surface production-ready. v1.20-v1.24 added ergonomics layers without touching the core runtime. The `%Scrypath.Query{}` struct remains internal. The post-v1.19 guardrail has held across six milestones.

### Signal 5: Is there a "failure mode" from continued development that now outweighs the benefit?

Yes, and it has been present since v1.19. The failure mode is scope creep beyond the library's natural boundary — adding Phoenix controller/LiveView macros, hidden Ecto callbacks, autocomplete sugar that competes with the engine's native SDKs, or OPSUI productization that turns Scrypath into a dashboard product rather than a library. Every milestone since v1.19 has been explicitly bounded against these failure modes, but the risk grows with each new milestone. The post-v1.19 guardrail exists precisely because this failure mode is now the main risk.

---

## Verdict: keep going vs. stop

### Updated done-% estimate: ~91–93%

The jump from 86% reflects: v1.23 closed the outside-adopter evidence gap and the support-truth reconciliation; v1.24 closed the related-data propagation gap. Those were the top two remaining correctness gaps. What remains is a single significant credibility gap (`AUTH-01`), one moderate deferred feature (autocomplete), and three minor feature gaps (soft-delete awareness, conditional indexing, highlighting).

### The honest verdict

**Scrypath is done enough to seek broad outside adoption as-is.** The core library does the job it was designed to do, does it more thoroughly than any comparable in its ecosystem, and is backed by 24 internal planning milestones of deliberate, scope-disciplined development.

**Do not open another internal feature milestone without adopter evidence.** The post-v1.19 guardrail is correct and should hold. The next thing that should drive a milestone is one of:

1. A real outside adopter hitting `AUTH-01` in the wild and reporting it as blocking.
2. A real outside adopter needing autocomplete and finding the current "use Meilisearch's API directly" guidance insufficient.
3. A maintenance need (Elixir version compatibility, Meilisearch API change, Hex dependency update).

**`AUTH-01` is the right next wedge if feature work reopens**, but the framing matters. It should be positioned as a thin ergonomics + documentation layer over Meilisearch tenant tokens, not as a framework-level auth system. Specifically: a `tenant_scope:` declaration option, a `Scrypath.tenant_token/3` helper that wraps JWT generation with the correct search rules, and a canonical guide. The work should take one milestone, not three.

**The comparables have lower bars than Scrypath on the things Scrypath is strong on.** Searchkick has no operator recovery, no admin UI, no explicit fan-out API. Scout has no operator tooling and no multi-tenancy. The Elixir ecosystem has no comparable at all. Scrypath's SaaS credibility gap on tenant isolation is real, but it is not "behind the field" — the field has not solved this either.

**The strongest signal to stop is the absence of external signal to continue.** The library is production-ready on its defended surface. The correct posture now is not "what can we add?" but "who is using this and what are they actually stuck on?"

---

## What "complete for its stated scope" looks like

A library in Scrypath's category is complete when:

1. The five JTBD jobs are covered: declaration, sync, search, operator recovery, related-data. — **Done.**
2. The primary sync failure modes are documented and recoverable. — **Done.**
3. The onboarding path works without maintainer help. — **Done (golden-path guide, common-mistakes guide, actionable errors).**
4. The API shape is stable enough that adopters can version-pin without fear. — **Done.**
5. The operator surface gives real teams enough to go on-call with search. — **Done (scrypath_ops, playbooks, reconcile, drift detection).**
6. The one remaining SaaS credibility gap has either shipped or been explicitly acknowledged as application-scope with a guide. — **Not done (`AUTH-01`).**

Point 6 is the only remaining item that could be called a "scope gap" rather than a "nice to have." It is also the most likely thing a serious adopter will hit. Shipping it closes the gap and clears the way for a confident "this library is done for v1" declaration.

---

## Lifecycle comparison: Elixir library precedents

**ex_machina** reached feature completeness around v2.5 (2019) and has been in maintenance since. The pattern: substantial feature work in early versions, then a clear shift to bug fixes, compatibility updates, and CI maintenance. No major new features for ~5 years. The library is considered stable and complete for its scope.

**Plug** continues to receive incremental updates (connection upgrades, deprecation cleanup, SSL improvements) but has not added fundamentally new capabilities in years. Its scope is stable. Each release is bounded by the spec.

**Ecto** reached a stable API declaration with v3.0 and has evolved cautiously with additive features since. No scope-breaking changes. Deliberate deprecation.

**Pattern across these:** Elixir ecosystem libraries tend to stop major feature work once the core abstraction is stable and the ecosystem has settled. They do not announce "maintenance mode" — they simply stop opening feature milestones and shift to compatibility maintenance. The signal is always adoption-pull, not internal roadmap push.

Scrypath is at the same inflection point. The correct move is: stop internal roadmap push, watch for adoption pull.

---

## Sources

- Searchkick README: [github.com/ankane/searchkick](https://github.com/ankane/searchkick)
- Laravel Scout docs: [laravel.com/docs/12.x/scout](https://laravel.com/docs/12.x/scout)
- Meilisearch multi-tenancy guide: [meilisearch.com/blog/multi-tenancy-guide](https://www.meilisearch.com/blog/multi-tenancy-guide)
- Meilisearch tenant tokens docs: [meilisearch.com/docs/learn/security/tenant_tokens](https://www.meilisearch.com/docs/learn/security/tenant_tokens)
- meilisearch-rails tenant token issue: [github.com/meilisearch/meilisearch-rails/issues/152](https://github.com/meilisearch/meilisearch-rails/issues/152)
- ex_machina changelog: [github.com/beam-community/ex_machina/blob/main/CHANGELOG.md](https://github.com/beam-community/ex_machina/blob/main/CHANGELOG.md)
- Django Haystack autocomplete: [django-haystack.readthedocs.io/en/latest/autocomplete.html](https://django-haystack.readthedocs.io/en/latest/autocomplete.html)
- Scrypath planning: `/Users/jon/projects/scrypath/.planning/` (PROJECT.md, milestone-candidates.md, threads/)
- Scrypath research prompt: `/Users/jon/projects/scrypath/prompts/search-lib-use-cases-deep-research.md`
