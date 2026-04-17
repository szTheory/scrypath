# Project Research Summary

**Project:** Scrypath — v1.3 "Search Power That Phoenix Teams Reach For"
**Domain:** Published Elixir OSS library (Ecto-native, Meilisearch-first search indexing and orchestration) — additive extension to shipped `scrypath 0.3.0` on Hex
**Researched:** 2026-04-17
**Confidence:** HIGH

## Executive Summary

Scrypath v1.3 is a tightly-scoped additive extension of an already-shipped public contract (`scrypath 0.3.0`). Every dependency pin, backend choice, and public-surface boundary is fixed; v1.3 only layers four new capability categories (faceted search, relevance tuning, multi-index federated search, operator polish) plus a small debt-retirement slice (Node 20 CI cleanup + three missing v1.2 VALIDATION.md artifacts) onto the v1.2 architecture. The four research agents converge strongly on scope, mechanism, and the non-goals; they diverge only on *phase ordering*, which this synthesis resolves below.

The recommended approach is uniformly additive. No Elixir dependency changes are needed — `Req ~> 0.5`, `Ecto ~> 3.13`, `Oban ~> 2.21`, `NimbleOptions ~> 1.1`, `Jason ~> 1.4` all stay on current pins. The only stack delta is a two-line `.github/workflows/ci.yml` cleanup (`actions/checkout@v4 → @v6`, `actions/cache@v4 → @v5`) that clears the Node 20 deprecation before GitHub removes the runtime in September 2026. Meilisearch server pinning stays at `v1.15` (all v1.3 feature payloads are shapes stable at or before v1.15). Every new public feature lands through additive, defaulted struct fields on `%Scrypath.Query{}`, `%Scrypath.SearchResult{}`, and `%Scrypath.Operator.FailedWork{}` — none enter `@enforce_keys`, preserving full wire compatibility with 0.3.0 consumers. The only genuinely new module is `Scrypath.Meilisearch.MultiSearch` plus a thin `multi_search/2` wrapper on the existing HTTP client.

The dominant risks are operational and contractual, not technical: (1) **re-occurrence of the v1.2 on-disk / Hex divergence** — the published 0.3.0 shipped only a subset of what landed on disk because phases closed locally without a workspace-clean gate; v1.3 must mechanize this check up front. (2) **silent settings mutation of the live index** — relevance tuning must flow through the managed `create target → apply settings → backfill → cutover` pipeline, not a new "hot-apply" verb. (3) **facet filter parser drift** — facet filtering must extend the existing narrow `validate_filterable_fields!/2` parser, not spawn a second grammar. (4) **`search_many/2` per-schema validation bypass** — federation must accept a list of per-request tuples, each independently validated, returning a `%{schema => %SearchResult{}}` map (grouped) rather than a flat federated hit list. (5) **struct evolution breaking 0.3.0 consumers** — all new fields on `SearchResult`, `Query`, and `FailedWork` stay *outside* `@enforce_keys` with benign defaults.

## Key Findings

### Recommended Stack

Zero dependency churn. The v1.3 feature surface is entirely expressible through existing transports and validators; the only pin changes live in CI workflow YAML.

**Core technologies (all unchanged):**
- `ecto ~> 3.13`: schema-attached metadata reflection for `faceting:` and structured `settings:` subkeys — no Ecto-query features introduced.
- `req ~> 0.5`: all four v1.3 server-side shapes (`/indexes/{uid}/search` with `facets`, `/indexes/{uid}/settings` with new keys, `/multi-search` federation, task-status) are JSON POST/PATCH — route-agnostic `run_request/5` already covers them.
- `nimble_options ~> 1.1`: new `facet_filter`, `facets`, and `search_many/2` options validate through the existing `@schema_options`/`@search_options` schemas; replaces the current unstructured `validate_settings/1` with nested subkey validation.
- `oban ~> 2.21, optional`: no new worker types; `FailedWork` enrichment reads existing Oban job fields (`attempt`, `max_attempts`).
- `meilisearch server v1.15` (CI pin held; tested range documented up through v1.42): every v1.3 API shape is stable at or before v1.15. `foreignKeys` (experimental, v1.39+) is explicitly **not** adopted.

**Required CI workflow diff (only file touched: `.github/workflows/ci.yml`):**
```yaml
- uses: actions/checkout@v4   →   - uses: actions/checkout@v6
- uses: actions/cache@v4      →   - uses: actions/cache@v5
```
`erlef/setup-beam@v1` is floating-major and already Node 24-ready; `release-please-action@v4` is already Node 24-compatible. No other workflow needs edits.

### Expected Features

Five categories, calibrated against Searchkick / Laravel Scout + Meilisearch / Typesense as the "first-backend-complete" bar. Scrypath's declarative-first posture (facets + settings as schema metadata, not runtime config) is legitimately more explicit than any of the three reference libraries.

**Must have (table stakes — milestone fails without these):**
- Declarative `faceting:` schema field; auto-add to `filterableAttributes` via managed reindex; `facets: [...]` option on `search/3`; `facet_distribution` + `facet_stats` on `%SearchResult{}`; facet filters routed through the **existing** filter validator; Phoenix LiveView faceted-search guide.
- Structured `settings:` subkeys for `synonyms`, `typo_tolerance`, `ranking_rules`, `distinct_attribute`, `stop_words`; all five applied **only** via the managed reindex pipeline; translation layer `snake_case → camelCase` in `Scrypath.Meilisearch.Settings`.
- `Scrypath.search_many/2` accepting `[{schema, opts}, …]` + shared top-level opts, returning `{:ok, %{schema => %SearchResult{}}}` (grouped-by-schema, not flat); per-schema validation and per-schema hydration preserved; Meilisearch-native federation under `Scrypath.Meilisearch.MultiSearch`.
- `FailedWork.t()` gains `attempt` + `max_attempts` + `reason_class` (`:transport_timeout | :validation_error | :backend_rejected | :queue_discard | :unknown`) + `last_attempt_at`; all **optional** fields with `nil` / `:unknown` defaults.
- End-to-end drift recovery guide chaining `sync_status → failed_sync_work → retry_sync_work → reconcile_sync → reindex`.
- GitHub Actions Node 20 deprecation cleanup + three missing v1.2 VALIDATION.md artifacts (phases 13/14/15).

**Should have (differentiators — ship if capacity allows):**
- Scrypath-owned `%Scrypath.SearchResult.Facets{}` sub-struct wrapping distribution + stats (insulates from future Meilisearch field renames).
- Reconcile flags setting-drift and facet-drift (report-first, never auto-heal).
- Failure-class rollup on `failed_sync_work/2` (`%{count_by_class: %{...}, entries: [...]}`).
- Partial-failure envelope for `search_many/2` (one sub-query errors → others still return; failed one yields `{:error, reason}` in the map).
- Numeric range-facet helper built on `facet_stats`.
- Per-environment setting overrides via runtime config (e.g. weaker typo in test).

**Defer (v1.4+ — explicit backlog, not v1.3 decisions):**
- Hierarchical facet grammar; disjunctive facet counts; per-query ranking overrides on the common path; deeper drift/schema-diff operator tooling; second public backend; vector/hybrid/semantic; dashboard product. All either lack adopter pressure or are locked non-goals in `PROJECT.md`.

### Architecture Approach

Entirely additive file-level extension. Two new modules; twelve extended; zero public-surface rewrites.

**Major components (ownership map):**
1. **Schema DSL extension** (`lib/scrypath/options.ex`, `lib/scrypath/schema.ex`, `lib/scrypath.ex`) — add `faceting:` to `@schema_options`; replace unstructured `validate_settings/1` with NimbleOptions-nested subkey validation for the five relevance keys; add `__scrypath__(:faceting)` reflection + `schema_faceting/1` helper. Compile-time guard: every atom in `faceting.attributes` must also be in `filterable:`.
2. **Query struct extension** (`lib/scrypath/query.ex`) — `defstruct text: nil, filter: [], sort: [], page: %{}, facet_filter: [], facets: []`. Two new defaulted fields, no `@enforce_keys` change.
3. **SearchResult struct extension** (`lib/scrypath/search_result.ex`) — add `facets: %{}` default outside `@enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]`. Populated from `raw` inside `SearchResult.new/4`; signature arity unchanged.
4. **Meilisearch translation layer** (`lib/scrypath/meilisearch/query.ex`, `settings.ex`) — extend `to_payload/1` with `translate_facets/1` and `translate_facet_filter/1` (array-of-arrays OR-syntax); add `translate_settings/1` for snake_case → camelCase; add optional `verify_settings_applied/3` read-back in `reindex.ex` before cutover.
5. **New: `Scrypath.Meilisearch.MultiSearch`** (`lib/scrypath/meilisearch/multi_search.ex`) — builds `/multi-search` federated payload, unpacks per-schema response via `_federation.indexUid`.
6. **Backend behaviour extension** (`lib/scrypath/backend.ex`) — add `@optional_callback search_many: 2` with a default N-sequential-calls fallback implemented in `Scrypath.Search.search_many/2`.
7. **Client HTTP surface** (`lib/scrypath/meilisearch/client.ex`) — thin `multi_search/2` wrapper over existing `run_request/5`.
8. **FailedWork struct extension** (`lib/scrypath/operator/failed_work.ex`) — four additive optional fields; `from_backend_task/3` and `from_queue_job/3` populate them from Meilisearch task + Oban job fields that already flow in.

The internal operations seam (`Scrypath.Operations.Task`, `Scrypath.Operations.Result`) is untouched. The `Scrypath.Meilisearch.*` namespace remains the single public escape hatch — all backend-native shapes (camelCase JSON keys, raw facet-filter strings, federation mode) stay confined inside it.

### Critical Pitfalls

1. **v1.2 on-disk ↔ Hex divergence recurrence** — `scrypath 0.3.0` shipped partial content because phases closed locally without a commit-graph check. *Mitigation:* add `mix verify.workspace_clean` (fails on non-empty `git status --porcelain` or HEAD behind `origin/main`) as a PR CI gate and first step of `publish-hex.yml`; add `mix verify.release_parity X.Y.Z` that diffs `mix hex.build --unpack` output against a per-phase SUMMARY manifest of expected shipped files. Land this **before** any feature phase.
2. **Struct shape break via `@enforce_keys`** — any new field on `SearchResult`, `Query`, or `FailedWork` that lands in `@enforce_keys` breaks every 0.3.0 consumer pattern-match and `struct!/1` caller. *Mitigation:* all new fields are optional with benign defaults (`nil`, `%{}`, `:unknown`); add compile-time struct-shape regression tests pinning the 0.3.0 key sets.
3. **Facet filter parser split** — a second facet-filter grammar (especially one accepting raw Meilisearch filter strings) would bypass `validate_filterable_fields!/2` and reopen the grammar boundary v1.2 closed. *Mitigation:* add `facet_filter:` as a sibling kwarg that validates through a field-is-declared check against `__scrypath__(:faceting)` and then composes into the same `%Query{}`; reject raw Meilisearch strings on the common path (they remain available under `Scrypath.Meilisearch.*`); property-test that every 0.3.0-accepted filter remains accepted.
4. **Live-index settings mutation** — any public `apply_settings/2` verb outside `Scrypath.Meilisearch.*` teaches the wrong mental model and causes Meilisearch's internal rebuild to silently degrade live search (especially for `filterableAttributes`, `searchableAttributes`, `rankingRules`, `distinctAttribute` changes). *Mitigation:* keep `Scrypath.reindex/2` as the sole public path for settings mutation; preserve the `create target → apply settings → backfill → cutover` ordering (enforced by an ordering test on a mocked backend); add a read-back `verify_settings_applied/3` before cutover so misapplied ranking rules fail loudly instead of silently ruining search quality.
5. **`search_many/2` per-schema validation bypass** — a naive `search_many(schemas, shared_opts)` that fans out a single opts keyword list couples schemas that had independent `filterable`/`sortable` contracts and loses per-schema `missing_ids` / `page` metadata. *Mitigation:* signature is `[{schema, opts}, …]` + shared top-level opts (e.g. `repo:`); every sub-request runs through `Options.validate_search_options!/2` independently; return shape is `%{schema => %SearchResult{}}` grouped (not flat); hydration stays per-schema-per-repo; partial failures yield per-schema `{:error, reason}` entries in the map.

## Implications for Roadmap

### Phase Ordering — Resolving the Four-Agent Divergence

The four research agents propose four different orderings, which must be reconciled:

| Agent | Proposed ordering |
|---|---|
| STACK | debt retirement early (CI bump first, since it's a 2-line diff) |
| FEATURES | debt → relevance → facet → multi-index → operator polish |
| ARCHITECTURE | relevance → facet → multi-index → operator polish → debt last |
| PITFALLS | release-parity gate FIRST, then facet → relevance → multi-index |

**Recommended ordering (synthesized):**

1. **Phase A — Release-parity & CI hygiene gate** (combines PITFALLS P1 + STACK Node 20 cleanup + FEATURES debt retirement)
2. **Phase B — Relevance tuning** (ARCHITECTURE's argument wins: narrowest change, establishes the snake_case → camelCase translation pattern that faceting reuses)
3. **Phase C — Faceted search** (reuses the phase-B translation pattern; extends `%Query{}` and `%SearchResult{}` additively; includes LiveView guide)
4. **Phase D — Multi-index search** (`search_many/2` fans out through the now-stabilized `%Query{}` / `%SearchResult{}` path)
5. **Phase E — Operator polish + drift recovery guide** (`FailedWork` additive fields + narrative guide referencing the new search features landed in B/C/D)
6. **Phase F — v1.2 VALIDATION.md closure + milestone-close verification sweep** (phases 13/14/15; kept separate from Phase A so its evidence-gathering review isn't mixed with code-bearing PRs)

**Why this ordering and not any of the four originals:**

- **PITFALLS' "parity gate first" is load-bearing and must be Phase A.** The v1.2 divergence is the one failure mode that silently poisons every subsequent v1.3 release. Landing `mix verify.workspace_clean` + `mix verify.release_parity` before any feature phase means every later phase's closure is mechanically audited.
- **STACK's "CI cleanup is tiny, do it early" folds naturally into Phase A.** The `actions/checkout@v4 → @v6` / `actions/cache@v4 → @v5` diff is six line-edits in one file; it belongs with the release-parity gate because both are "set the release pipeline right before we ship anything new" concerns, and doing them together avoids a separate PR whose only purpose is pin bumps.
- **ARCHITECTURE's "relevance before faceting" wins over FEATURES' reverse ordering.** Relevance tuning only touches the schema DSL (`settings:` subkey restructure), the `Scrypath.Meilisearch.Settings` translation layer, and the reindex verification step — *no* `%Query{}` or `%SearchResult{}` changes. Faceting extends both structs *and* needs the translation pattern. Proving the snake_case → camelCase pattern on the smaller change de-risks the larger one; if the smaller change breaks any public contract, the fix is narrower. FEATURES' counter-argument ("faceting is higher-visibility, do it first") is product-intuitive but adds rework risk.
- **Multi-index stays third** (all four agents agree). Federation fans out through per-schema validation + per-schema hydration, which must be solid from phases B and C first.
- **Operator polish stays fourth** (all four agents agree). `FailedWork` extension is orthogonal to search features; putting it fourth means the drift-recovery guide can reference the new relevance / facet / multi-index features honestly.
- **VALIDATION.md closure gets its own terminal phase** (combining PITFALLS P8's "don't pencil-whip" discipline with FEATURES' debt-retirement bucket). Pitfall-8 specifically warns that bundling VALIDATION closure into a feature PR lets reviewers rubber-stamp it; a dedicated phase with its own review gate is the only honest path.

### Phase 1 (A): Release-Parity Gate + Node 20 CI Cleanup
**Rationale:** PITFALLS P1 is the single failure mode most likely to undo v1.3; STACK's Node 20 debt is a 2-line YAML change with a September-2026 hard deadline. Bundling both lets us ship a clean release-pipeline baseline before feature work starts and before `publish-hex.yml` encounters a second partial release.
**Delivers:** `mix verify.workspace_clean`, `mix verify.release_parity X.Y.Z --expect-symbols ...`, `ci.yml` bumped (`checkout@v4 → @v6`, `cache@v4 → @v5`), per-phase SUMMARY.md manifest convention for parity checks.
**Addresses:** FEATURES → "GitHub Actions Node 20 deprecation cleanup" (table stakes, debt category).
**Avoids:** PITFALLS P1 (divergence), P8's infrastructure precondition.

### Phase 2 (B): Relevance Tuning — Declarative Settings via Managed Reindex
**Rationale:** ARCHITECTURE's dependency argument — smallest surface change (no `%Query{}` / `%SearchResult{}` edits), establishes the Scrypath-owned → Meilisearch-native translation pattern that faceting then reuses.
**Delivers:** Structured `settings:` subkeys (`synonyms`, `typo_tolerance`, `ranking_rules`, `distinct_attribute`, `stop_words`) validated via NimbleOptions; `Scrypath.Meilisearch.Settings.translate_settings/1` for snake_case → camelCase; `Scrypath.Reindex.verify_settings_applied/3` read-back before cutover; relevance-tuning guide.
**Uses:** Existing `settings: %{}` slot in `@schema_options`; existing `create target → apply settings → backfill → cutover` ordering in `reindex.ex`.
**Avoids:** PITFALLS P5 (live-index settings mutation) by keeping `reindex/2` as the sole public mutation verb; PITFALLS P10 by deriving `filterableAttributes` from schema declarations in one flow.

### Phase 3 (C): Faceted Search + Phoenix LiveView Guide
**Rationale:** Highest-visibility persona-facing feature; builds directly on Phase B's translation-pattern groove. Additive extensions to both `%Query{}` and `%SearchResult{}` prove the "defaulted-field, outside `@enforce_keys`" pattern that Phase E's `FailedWork` extension then reuses.
**Delivers:** `faceting:` schema key (list or map with `attributes`/`max_values_per_facet`/`sort_facet_values_by`); compile-time guard that facet attributes must appear in `filterable:`; `__scrypath__(:faceting)` reflection; `facet_filter:` + `facets:` search options validated against declared faceting; `facets` field on `%SearchResult{}` (default `%{}`, outside `@enforce_keys`); `translate_facet_filter/1` + `translate_facets/1` in `Meilisearch.Query`; auto-derivation of `filterableAttributes` from declared facets via the managed reindex pipeline; Phoenix LiveView faceted-search guide.
**Uses:** Phase B's translation layer; existing `validate_filterable_fields!/2` parser extended (not replaced).
**Avoids:** PITFALLS P2 (SearchResult break) via defaulted-field-outside-`@enforce_keys` pattern; PITFALLS P4 (parser split) by extending the single filter validator; PITFALLS P7 (backend-native leakage) by naming the field `facet_distribution` / `facets`, not `facetDistribution`.

### Phase 4 (D): Multi-Index Search — `Scrypath.search_many/2`
**Rationale:** Federation fans out through the stabilized `%Query{}` / `%SearchResult{}` path; doing this before faceting would force rework of every facet addition through the federated path.
**Delivers:** `Scrypath.search_many/2` with `[{schema, opts}, …] + shared_opts` signature; `{:ok, %{schema => %SearchResult{}}}` grouped return shape; `Scrypath.Backend.search_many/3` `@optional_callback` with N-sequential-calls fallback; new `Scrypath.Meilisearch.MultiSearch` module; `Client.multi_search/2` HTTP wrapper; per-schema validation preserved; per-schema hydration preserved; multi-index guide.
**Uses:** Meilisearch `/multi-search` federation endpoint (stable since v1.12, confirmed v1.15); `_federation.indexUid` for per-schema unpacking.
**Avoids:** PITFALLS P6 (per-schema validation bypass) via the per-request tuple signature; PITFALLS P7 (raw federated hits) via per-schema `SearchResult` decoration; non-goal creep ("multi-backend" API shape) by keeping `backend:` off the public surface.

### Phase 5 (E): Operator Polish + Drift Recovery Guide
**Rationale:** Orthogonal to search features; landing last lets the drift-recovery narrative reference the new relevance / facet / multi-index surface.
**Delivers:** `%FailedWork{}` gains `attempt` + `max_attempts` + `reason_class` (`:transport_timeout | :validation_error | :backend_rejected | :queue_discard | :unknown`) + `last_attempt_at` (all optional, outside `@enforce_keys`); `from_backend_task/3` + `from_queue_job/3` populate them from already-flowing data; end-to-end drift recovery guide chaining `sync_status → failed_sync_work → retry_sync_work → reconcile_sync → reindex`; optional failure-class rollup on `failed_sync_work/2` (`%{count_by_class: %{...}, entries: [...]}`).
**Avoids:** PITFALLS P3 (FailedWork break) via additive-optional pattern; PITFALLS P9 (non-goal creep) by explicitly keeping the guide markdown-only — no new `Scrypath.recover/2` verb.

### Phase 6 (F): v1.2 VALIDATION.md Closure + Milestone-Close Verification Sweep
**Rationale:** PITFALLS P8 warns that bundling VALIDATION closure into feature PRs invites pencil-whipping; a terminal phase with dedicated review keeps the audit trail honest.
**Delivers:** VALIDATION.md for v1.2 phases 13, 14, 15 — each linking to a specific runnable test path (file + line range), capturing `mix verify.phase13` / `mix verify.phase14` output, naming the evidence type (integration vs. unit vs. doctest); full-milestone verification sweep; v1.3 CHANGELOG review; release-parity canary.
**Avoids:** PITFALLS P8 (prose-only closure) via the mechanized "link-to-runnable-test" rule; PITFALLS P1 recurrence via the release-parity canary.

### Phase Ordering Rationale

- **Dependency-driven:** Phase A's gates must exist before any feature phase can ship cleanly. Phase B's translation pattern is reused in phase C. Phase C's struct-extension pattern is reused in phase E. Phase D depends on phases B + C being solid. Phase F depends on nothing, closes everything.
- **Risk-front-loaded:** The single highest-risk failure mode (v1.2 divergence) is mitigated in phase A. The second-highest (silent settings mutation) is mitigated in phase B. The third (parser split + struct break) in phase C. Each subsequent phase inherits a mitigated baseline.
- **Review-discipline-driven:** Phase F is separated specifically so VALIDATION.md closure gets focused review that pitfall-8 explicitly warns cannot happen inside a feature PR.

### Research Flags

Phases likely needing deeper `/gsd-research-phase` work during planning:
- **Phase D (multi-index search):** confirm at plan time whether `Backend.search_many/3` ships with an actual default N-sequential-calls fallback in `Scrypath.Search`, or requires backends to implement it (open question from ARCHITECTURE §6). Also verify at plan time that all filterable types — especially booleans — round-trip correctly through `translate_facet_filter/1`'s array-of-arrays syntax.
- **Phase E (operator polish):** decide canonical `reason_class` enum values before implementation; classification taxonomy is narrow by design (3–4 classes + `:unknown`) per FEATURES' anti-feature posture. Plan must specify how `from_backend_task/3` and `from_queue_job/3` map Meilisearch task-error strings + Oban error tuples to the canonical set.

Phases with well-documented patterns (no additional research expected):
- **Phase A:** GitHub Actions pin bumps are mechanical; release-parity gate design has known-good prior art in `mix verify.phase11`.
- **Phase B:** Meilisearch settings API semantics are established; relevance-tuning translation is straightforward snake_case → camelCase.
- **Phase C:** Meilisearch faceting API shape is stable and documented; LiveView guide tone matches existing `guides/phoenix-liveview.md`.
- **Phase F:** VALIDATION.md template exists; evidence-gathering is mechanical (test path citation + captured command output).

### Phase Count Estimate

**Six phases.** If scope pressure hits, phases A and F can be merged (both are debt-retirement) at the cost of diluting PITFALLS P8's "dedicated review gate" discipline; phases C and D can never be merged (different structs, different validation paths, different public verbs). Phases B/C/D/E are the four feature phases the milestone explicitly scopes; phase A is the pre-feature gate; phase F is the post-feature milestone close.

## Open Questions for Planning-Phase Decisions

1. **Facet filter — OR-within-single-field on common path?** FEATURES notes that the existing validator currently rejects boolean composition but that facet UIs commonly want `[tag: ["elixir", "phoenix"]]` (OR within a single field). The "widening, not narrowing" decision is backward-compatible but must be explicit in the Phase C plan. *Recommendation:* accept OR-within-single-field (`[tag: ["elixir", "phoenix"]]` → Meilisearch `[["tag = elixir", "tag = phoenix"]]`) — it is the smallest widening that unlocks the common facet UX, and it does not open the door to arbitrary `:or`/`:and`/`:not` boolean composition.

2. **`Backend.search_many/3` — required or optional callback?** ARCHITECTURE recommends `@optional_callbacks` with a default N-sequential-calls fallback in `Scrypath.Search`; this keeps v1.3 Meilisearch-only without structurally blocking a future backend that lacks native federation. *Phase D plan decision:* whether to actually implement the fallback now or leave the optional callback unimplemented until a second backend appears. *Recommendation:* ship the fallback — it costs little and documents the seam's intent.

3. **`reason_class` canonical enum values.** The milestone goal says "error reason class" in the abstract; pitfall research and features research converge on `:transport_timeout | :validation_error | :backend_rejected | :queue_discard | :unknown` but the exact set is a Phase E plan decision. *Recommendation:* ship with exactly those five; `metadata:` remains the escape valve for finer-grained detail.

4. **`validate_settings/1` strict vs. permissive on unknown subkeys.** ARCHITECTURE §6 flags the semver risk: users with unusual in-map settings keys may start getting validation errors under a stricter NimbleOptions-nested validator. *Recommendation (Phase B plan):* validate **known** subkeys strictly; pass unknown subkeys through unchanged to preserve backward compatibility. Surface a `@deprecated`-style doc warning only if a subkey is known to be renamed.

5. **`SearchResult.facets` — bare map or sub-struct?** ARCHITECTURE prefers `facets: %{}` as a plain map; PITFALLS P2 suggests a `%Scrypath.SearchResult.Facets{}` sub-struct for future-proofing. *Recommendation (Phase C plan):* ship the sub-struct — it's listed as a P2 differentiator in FEATURES and insulates the public surface from Meilisearch field renames (`nbHits` → `estimatedTotalHits` → `totalHits` trajectory is the cautionary precedent).

6. **`last_attempt_at` vs. `failed_at` rename.** FEATURES suggests retaining `failed_at` as an alias for one release cycle; ARCHITECTURE is silent. *Recommendation (Phase E plan):* add `last_attempt_at` as a new field; keep `failed_at` populated and equal to `last_attempt_at` for one minor release; document deprecation in CHANGELOG. No breakage, graceful migration.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero dep changes; every CI pin verified against GitHub changelog 2025-09-19 and release notes for `actions/checkout@v6.0.2`, `actions/cache@v5.0.5`, `erlef/setup-beam@v1.24.0`. Meilisearch `v1.15`–`v1.42` shape stability verified against official multi-search and settings API references. |
| Features | HIGH | Calibration against Searchkick, Laravel Scout + Meilisearch, Typesense is explicit. Every v1.3 feature maps to an established user expectation in one of those three. Non-goals are checked against `PROJECT.md` "Out of Scope" and every tempting widening has an explicit verdict. |
| Architecture | HIGH | Grounded in direct reading of every relevant module at HEAD (`schema.ex`, `search.ex`, `search_result.ex`, `query.ex`, `options.ex`, `meilisearch/*`, `reindex.ex`, `operator/failed_work.ex`, `operations/result.ex`). File-level integration points are named; extensions are explicitly additive. |
| Pitfalls | HIGH | Grounded in v1.2 audit (`v1.2-MILESTONE-AUDIT.md`), shipped struct shapes, reindex workflow ordering, and the existing release contract. The divergence pitfall is historical, not speculative. |

**Overall confidence:** HIGH

### Gaps to Address

- **Meilisearch task-error string taxonomy.** The exact text Meilisearch emits for common task failures (rate-limit, missing attribute, malformed filter) needs to be sampled from a live v1.15 server during Phase E planning to validate the `reason_class` mapping logic. Gap: no sampled corpus exists yet. *Mitigation:* Phase E plan pulls a small sample via the existing `phase13-verification` CI substrate.
- **Downstream adopter impact survey.** FEATURES calibration draws from reference libraries, not from Scrypath's actual adopters (few at 0.3.0). Any "would adopters actually use this?" questions are answered by extrapolation. *Mitigation:* PROJECT.md already acknowledges v1.3 is extrapolated; v1.4 is explicitly gated on real adopter feedback collected during v1.3.
- **`search_many/2` payload size ceiling.** No research on practical federated-query cardinality (how many schemas × how many hits × how much hydration preload is too much?). *Mitigation:* Phase D plan should define default page-size caps and a max-schema-count (PITFALLS suggests ≤ 10) as safety rails, flagged for loosening after real usage signal.
- **`filterableAttributes` migration during upgrade.** Users already running `scrypath 0.3.0` against a populated Meilisearch index who add `faceting:` on upgrade will trigger a Meilisearch-internal rebuild. *Mitigation:* Phase C plan must include upgrade-guide copy that directs users to `Scrypath.reindex/2` on first `faceting:` addition rather than expecting a transparent upgrade.

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/scrypath/.planning/research/STACK.md` — stack decisions (researched 2026-04-17).
- `/Users/jon/projects/scrypath/.planning/research/FEATURES.md` — feature scope with reference-library calibration.
- `/Users/jon/projects/scrypath/.planning/research/ARCHITECTURE.md` — file-level ownership, integration points, phase-ordering rationale grounded in direct module reads.
- `/Users/jon/projects/scrypath/.planning/research/PITFALLS.md` — pitfalls grounded in `v1.2-MILESTONE-AUDIT.md`, shipped struct shapes, and the release contract.
- `/Users/jon/projects/scrypath/.planning/PROJECT.md` — authoritative milestone goals, non-goals, and Core Value.
- `/Users/jon/projects/scrypath/.planning/milestones/v1.2-MILESTONE-AUDIT.md` — divergence narrative that grounds PITFALLS P1.
- Meilisearch v1.15 + multi-search API references — shape stability for all v1.3 server-side payloads.
- GitHub Changelog 2025-09-19 — Node 20 deprecation timeline anchoring the CI cleanup deadline.

### Secondary (MEDIUM confidence)
- Reference-library comparison (Searchkick, Laravel Scout + Meilisearch, Typesense) — informs table-stakes calibration but not Scrypath-specific behavior.
- Meilisearch task-error-string corpus — not sampled against live server; inferred from documentation.

### Tertiary (LOW confidence)
- Downstream adopter expectations at `scrypath 0.3.0` tier — PROJECT.md acknowledges this is extrapolated rather than surveyed; v1.4 gating on adopter feedback is the mitigation.

---
*Research completed: 2026-04-17*
*Ready for roadmap: yes*
