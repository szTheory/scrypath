# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans, and the full Meilisearch-first v1 surface archived in [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans, release hardening and launch-readiness evidence archived in [.planning/milestones/v1.1-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans, public release trust, operator visibility, and the first live public release proof archived in [.planning/milestones/v1.2-ROADMAP.md](/Users/jon/projects/scrypath/.planning/milestones/v1.2-ROADMAP.md)
- [ ] `v1.3` active — 6 phases, deepens Meilisearch-native search power (faceting, relevance tuning, multi-index) plus narrow operator polish and release/tooling debt retirement. Every v1.3 addition is strictly additive over shipped `scrypath 0.3.0`; releases naturally during the milestone.

## Active Milestone

### v1.3 Search Power That Phoenix Teams Reach For

**Goal:** Land the three Meilisearch-native capabilities every growth-stage Phoenix SaaS reaches for immediately after install — faceted search, relevance tuning (typo tolerance, synonyms, ranking rules), and multi-index federated search — through Scrypath-owned APIs that preserve the shipped sync, backfill, and operator contracts. Retire remaining release and tooling debt in the same cycle so v1.4 starts clean.

**Non-goals honored in every phase below:** no second public backend, no vector/hybrid/semantic search, no breaking changes to v1.2 `%SearchResult{}` / `%Query{}` / `%FailedWork{}` `@enforce_keys`, no dashboard product surface, no new public `Scrypath.recover/*` verb.

## Phases

- [x] **Phase 18: Release-Parity Gate + Node 20 CI Cleanup** — Maintainers ship a v1.3 release that mechanically cannot diverge from what they approved on disk. (completed 2026-04-17)
- [x] **Phase 19: Relevance Tuning** — Phoenix devs declare synonyms, typo tolerance, ranking rules, distinct attribute, and stop words on the schema and see them applied safely through the managed reindex pipeline. (implementation + docs landed 2026-04-17; optional `feat(19):` release-please commit still at maintainer discretion)
- [x] **Phase 20: Faceted Search + LiveView Guide** — Phoenix devs declare `faceting:` on a schema and power a complete faceted LiveView UI (checkbox sidebar, chip row, range, search-within-facet) from one `Scrypath.search/3` call. (implementation landed 2026-04-17)
- [x] **Phase 21: Multi-Index Search** — Phoenix devs run a single federated `Scrypath.search_many/2` across N schemas and get back one ordered, schema-grouped result with per-schema facets and an explicit partial-failure envelope. (completed 2026-04-17)
- [x] **Phase 22: Operator Polish + Drift Recovery Guide** — Operators triage failed sync work by reason class and recover from every common drift scenario using only existing `Scrypath.*` + `mix scrypath.*` verbs. (completed 2026-04-17)
- [x] **Phase 23: v1.2 VALIDATION.md Closure** — v1.2 Nyquist audit flips from `partial` to `compliant` with runnable-test-cited evidence for phases 13, 14, 15. (completed 2026-04-17)

## Phase Details

### Phase 18: Release-Parity Gate + Node 20 CI Cleanup
**Goal:** Maintainers ship a v1.3 release that mechanically cannot diverge from what they approved on disk, and CI runs on GitHub Actions runtimes that will still exist after September 2026.
**Depends on:** Nothing (milestone foundation; mitigates the single failure mode most likely to undo v1.3)
**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. Maintainer attempting to publish with untracked or uncommitted changes under `lib/`, `test/`, `guides/`, or `docs/` sees `mix verify.workspace_clean` fail and block `mix hex.publish` before any tarball is built.
  2. Maintainer running `mix verify.release_parity X.Y.Z` sees a non-zero exit when the live Hex tarball's `lib/` + `guides/` + `docs/` file list diverges from the git tag of the same version, and a clean pass otherwise.
  3. Maintainer watching CI sees zero Node 20 deprecation warnings on `checkout` and `cache` actions; `actions/checkout@v6` and `actions/cache@v5` are live in `.github/workflows/ci.yml`.
  4. Maintainer observes a scheduled daily `verify-published-release.yml` run that re-checks release parity against the latest published Hex version without human intervention.
**Plans:** 7/7 plans complete
- [x] 18-01-PLAN.md — Wave 0 test scaffolding + mix.exs cli.preferred_envs (covers INFRA-01..04 via Wave-0 anchors)
- [x] 18-02-PLAN.md — verify.workspace_clean Mix task (INFRA-01)
- [x] 18-03-PLAN.md — verify.release_parity Mix task (INFRA-02)
- [x] 18-04-PLAN.md — ci.yml Node 20 pin swaps (INFRA-03, 8 @v4 → @v6/@v5)
- [x] 18-05-PLAN.md — workspace_clean wired into ci.yml + release-please.yml + publish-hex.yml (INFRA-01 cross-workflow)
- [x] 18-06-PLAN.md — verify-published-release.yml release_parity step + drift-issue wiring + issue template (INFRA-02 cron + INFRA-04)
- [x] 18-07-PLAN.md — docs/releasing.md + CHANGELOG.md + closing feat(18): commit ritual (D-22, D-23, D-24)

### Phase 19: Relevance Tuning
**Goal:** Phoenix devs declare synonyms, typo tolerance, ranking rules, distinct attribute, and stop words on their schema and see them applied safely through the existing managed reindex pipeline — with drift detection, a ranking-rules safety rail, and no hot-apply escape hatch on live indexes.
**Depends on:** Phase 18 (release-parity gate inherits into every subsequent feature phase)
**Requirements:** TUNE-01, TUNE-02, TUNE-03, TUNE-04, TUNE-05, TUNE-06, TUNE-07, TUNE-08
**Success Criteria** (what must be TRUE):
  1. Phoenix dev declares `settings: %{synonyms: [["nyc", "new york"]], typo_tolerance: ..., ranking_rules: [...], distinct_attribute: ..., stop_words: [...]}` and, on the next `Scrypath.reindex/2`, sees the declared values live against Meilisearch with no hot-apply path available.
  2. Phoenix dev who supplies a `ranking_rules:` list missing any of the six Meilisearch defaults sees an actionable compile-time error pointing at the missing rule, unless they explicitly opt in with `ranking_rules_strict?: false`.
  3. Phoenix dev who declares `synonyms` using bidirectional list-of-groups sugar (`[["nyc", "new york"]]`) OR Meilisearch-native map form (`%{"nyc" => ["new york"]}`) gets the same applied result, with `one_way: true` disabling bidirectional expansion when requested.
  4. Operator running `mix scrypath.settings.diff MyApp.Post` sees a three-column declared-vs-applied table and receives exit code 2 on drift; `mix scrypath.settings.read MyApp.Post` prints the current applied settings for debugging.
  5. Operator running `Scrypath.reindex/2` with drifted settings sees cutover blocked by the post-apply read-back verification step unless `skip_settings_verification?: true` is set.
**Plans:** 7/7 plans complete
- [x] 19-01-PLAN.md — NimbleOptions nested schema + validate/normalize/canonicalize + :settings_merge opt + hot_apply stub (TUNE-01, TUNE-02, TUNE-03, TUNE-04, TUNE-06)
- [x] 19-02-PLAN.md — expand_synonyms + translate_settings + resolve/2 normalize-both-sides + deep_merge (TUNE-01, TUNE-02, TUNE-06)
- [x] 19-03-PLAN.md — Client.get_settings/2 + Settings.verify_applied/3 drift primitive (TUNE-05)
- [x] 19-04-PLAN.md — Reindex verify step + ranking-rules reindex-time error + skip_settings_verification? + per-repo cascade (TUNE-03, TUNE-04, TUNE-05, TUNE-06)
- [x] 19-05-PLAN.md — mix scrypath.settings.diff (exit 0/2/1, --json) (TUNE-07)
- [x] 19-06-PLAN.md — mix scrypath.settings.read (pretty-print) (TUNE-08)
- [x] 19-07-PLAN.md — guides/relevance-tuning.md + CHANGELOG + mix.exs extras/cli (closing `feat(19):` commit optional — not required for bookkeeping)

### Phase 20: Faceted Search + LiveView Guide
**Goal:** Phoenix devs declare `faceting:` on a schema and power a complete faceted Phoenix LiveView UI (checkbox sidebar, chip row, numeric range, search-within-facet) from a single `Scrypath.search/3` call — without reopening the narrow filter grammar or leaking backend-native shapes onto the common surface.
**Depends on:** Phase 18 (release-parity gate), Phase 19 (reuses the Scrypath-owned → Meilisearch-native translation pattern established in `Scrypath.Meilisearch.Settings`)
**Requirements:** FACET-01, FACET-02, FACET-03, FACET-04, FACET-05, FACET-06, FACET-07, FACET-08, FACET-09, FACET-10
**Success Criteria** (what must be TRUE):
  1. Phoenix dev declares `faceting: [attributes: [:genre, :year], max_values_per_facet: 100, sort_facet_values_by: %{...}]` and sees compile-time errors when a faceting attribute is not also in `filterable:`, with the error pointing at the offending attribute.
  2. Phoenix dev passing `facets: [:genre, :year]` and `facet_filter: [genre: ["fiction", "horror"], year: [2024]]` to `Scrypath.search/3` gets back a `%SearchResult{facets: %Scrypath.SearchResult.Facets{distribution: ..., stats: ...}}` with ordered buckets, numeric stats default-on, and disjunctive-within-field + conjunctive-across-field semantics.
  3. Phoenix dev requesting an unknown or non-declared facet attribute sees `{:error, {:unknown_facet, attr}}` — never a silent empty distribution.
  4. Phoenix dev runs `Scrypath.reindex/2` on a schema with `faceting:` declared and sees Meilisearch's `filterableAttributes` auto-derived into the object form with `features: ["facetSearch"]`, with zero user-facing configuration.
  5. Phoenix dev opening `guides/faceted-search-with-phoenix-liveview.md` finds a movies-by-genre-year-rating-director worked example covering all four canonical UI patterns (sidebar checklist, chip row, range slider, search-within-facet) plus a 7+ entry anti-pattern appendix.
**Plans:** 4/4 plans complete
- [x] 20-01-PLAN.md — `faceting:` schema option, `__scrypath__(:faceting)`, `Scrypath.schema_faceting/1`, FACET-02/FACET-10 compile enforcement + `FacetableMovie` fixture (FACET-01, FACET-02, FACET-10)
- [x] 20-02-PLAN.md — `validate_search_options/2`, `%Query{}` facets, `Meilisearch.Query` payload + `%SearchResult.Facets{}` decode (FACET-03, FACET-04, FACET-05, FACET-06, FACET-09)
- [x] 20-03-PLAN.md — `Settings.resolve/2` merges facet-derived `filterableAttributes` + `verify_applied/3` coverage (FACET-07)
- [x] 20-04-PLAN.md — `guides/faceted-search-with-phoenix-liveview.md`, ExDoc wiring, docs contracts, CHANGELOG (FACET-08)
**UI hint**: yes

### Phase 21: Multi-Index Search
**Goal:** Phoenix devs run a single federated `Scrypath.search_many/2` across N schemas and get back one declaration-ordered, schema-grouped result — with per-schema facet output identical to single-schema search, per-schema validation preserved, concurrent hydration, an explicit partial-failure envelope, and never-silent cardinality rails.
**Depends on:** Phase 18 (release-parity gate), Phase 19 (relevance translation layer), Phase 20 (per-schema facet parity asserted via MULTI-08; reuses `%SearchResult{}` facet sub-struct)
**Requirements:** MULTI-01, MULTI-02, MULTI-03, MULTI-04, MULTI-05, MULTI-06, MULTI-07, MULTI-08, MULTI-09, MULTI-10, MULTI-11, MULTI-12, MULTI-13
**Success Criteria** (what must be TRUE):
  1. Phoenix dev passes `[{Post, "elixir", filter: [published: true]}, {User, "elixir"}, {Event, "elixir"}]` plus shared `repo: MyApp.Repo` to `Scrypath.search_many/2` and receives `{:ok, %Scrypath.MultiSearchResult{ordered: [...], by_schema: %{...}, failures: []}}` with declaration order preserved and per-schema validation applied independently.
  2. Phoenix dev requesting per-schema `facets:` in a multi-index call sees `result.by_schema[S].facets` match byte-for-byte what a single `Scrypath.search(S, ...)` call produces for the same facet opt — with `mergeFacets` never set on the wire.
  3. Phoenix dev whose one sub-query fails (validation, transport, or hydration timeout) still receives `{:ok, %MultiSearchResult{}}` with the failed schema moved to `failures: [%{schema: ..., reason: ...}]` and all other schemas successful; complete failure surfaces as `{:error, {:all_failed, ...}}` or the canonical error tuples (`:empty_schema_list`, `:too_many_schemas`, `:invalid_options`).
  4. Phoenix dev exceeding cardinality rails (`max_schemas: 10`, per-entry `page.size: 50`, `federation_limit: 200`, `hydration_timeout: 5000`, `federation_timeout: 7500`) sees an explicit error — never silent truncation.
  5. Phoenix dev opening `guides/multi-index-search.md` finds a worked 4-schema LiveView dashboard example with per-schema facets, partial-failure banner, and cross-links to the faceted-search and sync-modes guides.
**Plans:** 4/4 complete (`21-01` structs + entries rails, `21-02` backend + `/multi-search`, `21-03` orchestration + telemetry + `!`, `21-04` guide + MULTI-08 integration)
**UI hint**: yes

- [x] 21-01-PLAN.md — `%MultiSearchResult{}`, federation meta, `MultiSearch.Entries` rails + tests (MULTI-01..04, MULTI-10)
- [x] 21-02-PLAN.md — optional `Backend.search_many/2`, `/multi-search` client, federated decode, `FakeBackend` stub (MULTI-08, MULTI-12)
- [x] 21-03-PLAN.md — `Scrypath.search_many/2`, sequential fallback, telemetry, concurrent hydration (MULTI-05..07, MULTI-09, MULTI-12, MULTI-13)
- [x] 21-04-PLAN.md — `guides/multi-index-search.md`, ExDoc extras, docs contract, README, integration test (MULTI-08, MULTI-11)

### Phase 22: Operator Polish + Drift Recovery Guide
**Goal:** Operators triage failed sync work with enough context to pick a next action without reading library internals, and recover from every common drift scenario using only already-shipped `Scrypath.*` and `mix scrypath.*` verbs.
**Depends on:** Phase 18 (release-parity gate); orthogonal to Phases 19–21 but the drift-recovery guide references the search features they land.
**Requirements:** OPS-05, OPS-06, OPS-07, OPS-08, OPS-09, OPS-10
**Success Criteria** (what must be TRUE):
  1. Operator inspecting a `%Scrypath.Operator.FailedWork{}` value sees `attempt`, `max_attempts`, `reason_class` (`:transport | :validation | :backend_rejected | :queue_exhausted | :unknown`), and `last_attempt_at` populated deterministically — with every 0.3.0 pattern match and constructor still working unchanged.
  2. Operator inspecting an inline or manual failure sees `attempt: nil, max_attempts: nil` (never a misleading `1/1`) and recognizes `nil` as "the source system does not expose retry attempts."
  3. Operator opening `guides/drift-recovery.md` finds six concrete SRE-runbook-style scenarios (empty index, stale results after sync success, backfill/count divergence, failed-work pileup, settings drift, stuck reindex mid-cutover), each following symptom → diagnosis → action → verify and using only existing `mix scrypath.*` + `Scrypath.*` verbs.
  4. Operator wiring a telemetry handler on `[:scrypath, :operator, :failed_work, :observed]` receives one event per constructed `FailedWork.t()` with `reason_class`, `schema`, and `mode` in metadata.
**Plans:** 2/2 complete
- [x] 22-01-PLAN.md — `FailedWork` fields, classifier, telemetry, tests (OPS-05..08, OPS-10)
- [x] 22-02-PLAN.md — `guides/drift-recovery.md`, ExDoc, docs contract (OPS-09)

### Phase 23: v1.2 VALIDATION.md Closure
**Goal:** v1.2 Nyquist audit flips from `partial` to `compliant` with runnable-test-cited evidence; no pencil-whitewashing, no prose-only closures.
**Depends on:** Phase 18 (release-parity gate); fully parallelizable with Phase 22 — the two phases touch disjoint files (Phase 22 edits `lib/scrypath/operator/failed_work.ex` and `guides/drift-recovery.md`; Phase 23 edits only `.planning/milestones/` archive entries and `v1.2-MILESTONE-AUDIT.md`).
**Requirements:** VALID-01, VALID-02, VALID-03
**Success Criteria** (what must be TRUE):
  1. Maintainer opening the v1.2 milestone archive finds a `VALIDATION.md` for phase 13 (operator primitives) that cites runnable tests in `test/scrypath/operator/*_test.exs` and captured `mix verify.phase13 --skip-integration` output.
  2. Maintainer opening the v1.2 milestone archive finds a `VALIDATION.md` for phase 14 (mix tasks and guides) that cites runs of `test/scrypath/mix_tasks/operator_tasks_test.exs` plus captured `mix verify.phase14` output.
  3. Maintainer opening the v1.2 milestone archive finds a `VALIDATION.md` for phase 15 (verify operator primitives) that cites `test/scrypath/live_operator_verification_test.exs` live integration, and sees `v1.2-MILESTONE-AUDIT.md` nyquist coverage flipped from `partial` to `compliant`.
**Plans:** 1/1 complete (milestone-archive documentation + audit YAML/narrative alignment)
- [x] 23-01 — `.planning/milestones/v1.2/{README,13-VALIDATION,14-VALIDATION,15-VALIDATION}.md` + `v1.2-MILESTONE-AUDIT.md` Nyquist `partial` → `compliant`

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 18. Release-Parity Gate + Node 20 CI Cleanup | 7/7 | Complete    | 2026-04-17 |
| 19. Relevance Tuning | 2/7 | Executing   | - |
| 20. Faceted Search + LiveView Guide | 4/4 | Complete    | 2026-04-17 |
| 21. Multi-Index Search | 4/4 | Complete    | 2026-04-17 |
| 22. Operator Polish + Drift Recovery Guide | 2/2 | Complete    | 2026-04-17 |
| 23. v1.2 VALIDATION.md Closure | 1/1 | Complete    | 2026-04-17 |

## Backlog

- Additional backend support after the release contract and operator surface prove the common path against real Meilisearch adoption (locked non-goal through v1.3).
- Hot-apply escape hatch `Scrypath.Meilisearch.Settings.hot_apply/3` for synonyms/stop_words/typo_tolerance — v1.3 ships the stub returning `:hot_apply_disabled`; real implementation deferred to v1.4.
- Hierarchical / nested facet declarations (`categories.lvl0`), disjunctive facet counts as a first-class opt, and `search_within_facet/4` in-facet value search — deferred to v1.4.
- Cross-schema ranking normalization, custom weighting / boost parameters, and `:all`-schema wildcard via registry for `search_many/2` — deferred to v1.4.
- Failure-class rollup counts on `failed_sync_work/2` and `reason_class`-driven recovery action branching inside `reconcile_sync/2` — deferred to v1.4 (narrow-polish discipline holds for v1.3).
- Deeper drift/schema-diff operator tooling — reserved for v1.4 once v1.3 feature work produces real-world recovery scenarios.

---
*Last updated: 2026-04-17 — Phase 23 complete; v1.2 Nyquist validation artifacts under `.planning/milestones/v1.2/`*
