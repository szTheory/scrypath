# Phase 19: Relevance Tuning - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `19-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 19-relevance-tuning
**Areas discussed:** Opt-out flag surface, Settings-merge scope, Plan splitting / wave shape, Backward-compat cutover

---

## Gray-area selection

**Question:** Which gray areas do you want to discuss for Phase 19 (Relevance Tuning)?

| Option | Description | Selected |
|--------|-------------|----------|
| Opt-out flag surface | Where do `ranking_rules_strict?` and `skip_settings_verification?` live — settings map, schema-level, or runtime opts? TUNE-04/TUNE-05 contradict. | ✓ |
| Settings-merge scope | Does `settings_merge: :deep` apply only to `Scrypath.reindex/2`, or also to runtime + backfill option sets? Affects test-env ergonomics. | ✓ |
| Plan splitting / wave shape | How to break TUNE-01..08 into plans? Monolith / 3 medium / 6+ thin? | ✓ |
| Backward-compat cutover | Current `validate_settings/1` is permissive (camelCase string-key passthrough works today). After TUNE-01 lands structured validation, keep passthrough as escape hatch or hard-deprecate? | ✓ |

**User's choice:** All four selected.
**Notes:** "for each of these...research using subagents, what is pros/cons/tradeoffs of each considering the example for each approach, what is idiomatic for elixir/plug/ecto/phoenix for this type of lib and in this ecosystem, lessons learned from other libs in same space even from other languages/frameworks if they are popular successful, what did they do right that we should learn from, what did they do wrong/footguns we can learn from, great developer ergonomics/dx emphasized... think deeply one-shot a perfect set of recommendations so I dont have to think, all recommendations are coherent/cohensive with each other and move us toward the goals/vision of this project... using great software architecture/engineering, principle of least surprise and great UI/UX where applicable great dev experience."

---

## Opt-out flag surface

**Research:** 4 parallel subagents (general-purpose) ran ~225s producing structured comparison-table-plus-rationale outputs. The opt-out-flag agent surveyed Ecto.Schema (`on_replace:` co-location), Ash.Policies (`authorize?:` call-time bypass), Plug init/call split, Oban.Worker `unique:`, Searchkick `reindex(refresh:)`, algoliasearch-rails `check_settings:` (the documented anti-pattern of class-level placement).

| Option | Description | Selected |
|--------|-------------|----------|
| **A. Both flags on schema top-level** | Single namespace; both declared once. Risk: catastrophic set-and-forget for `skip_settings_verification?` — exactly the algoliasearch-rails `check_settings: false` documented anti-pattern. | |
| **B. Both flags inside `settings:` map** | Co-located with config they modify. Risk: `skip_settings_verification?` is semantically incoherent in `settings:` (verify is a pipeline step, not a Meilisearch setting). | |
| **C. Both flags as runtime opts on `Scrypath.reindex/2`** | Explicit at every call. Risk: `ranking_rules_strict?` requires operator to remember the flag every time; impossible to compile-time-validate. | |
| **D. SPLIT: `ranking_rules_strict?` in `settings:`, `skip_settings_verification?` as runtime opt** | Different *classes* of flag get different placements. `ranking_rules_strict?` is a safety rail modifying a declared config value (mirrors Ecto's `on_replace:`); `skip_settings_verification?` is an emergency bypass of a pipeline step (mirrors Ash's `authorize?:` and Searchkick's `reindex(refresh:)`). Resolves TUNE-04 vs TUNE-05 contradiction. | ✓ |

**User's choice:** D (synthesized from research; locked).
**Notes:** Coherent unifying rule — "Safety rails declared at the boundary they protect; emergency bypasses at the call site of the action they bypass." Reserves `*_strict?` suffix as Scrypath-internal namespace stripped before Meilisearch translation.

---

## Settings-merge scope

| Option | Description | Selected |
|--------|-------------|----------|
| **A. Reindex-only** | `settings_merge` on `@reindex_options` only. Test-env recipe (`config :my_app, MyApp.Repo.scrypath, ...`) unsupported. | |
| **B. All three (reindex + backfill + runtime)** | Maximum reach. But `@backfill_options` accepting it is incoherent (TUNE-03 says backfill never applies settings; the existing `:settings` opt is inert plumbing). | |
| **C. Reindex + runtime only; NOT backfill; NEW per-repo cascade source** | Per-call at `reindex/2` AND app-wide via `config :my_app, MyApp.Repo.scrypath, settings_merge: :deep` cascading through a NEW source added to `Scrypath.Config.resolve!/1`. Removes inert `:settings` opt from `@backfill_options` in same plan. | ✓ |

**User's choice:** C (synthesized; locked).
**Notes:** Critical research finding — `Scrypath.Config.resolve!/1` only reads `:scrypath, :defaults` today, so the RELEVANCE.md test-env recipe doesn't work against shipped 0.3.0. Phase 19 must add the per-repo cascade source. Right-biased precedence (`:scrypath, :defaults` < per-repo < per-call). Hand-roll deep_merge (~12 LOC) instead of taking the dep. RELEVANCE.md's "DeepMerge ~40% footgun" citation was found unsubstantiated; real arguments for shallow-default are phoenix#5758 + Oban's `queues: []` gotcha.

---

## Plan splitting / wave shape

| Option | Description | Selected |
|--------|-------------|----------|
| **A. Monolith (1 plan)** | Fastest start, hard to review, no parallelism, high mid-phase rework risk. Phase 18 explicitly avoided this. | |
| **B. Medium (3 plans)** | Schema-side / runtime-side / docs split. Plans still ~400-500 LOC each — past Google's 200-LOC review-effectiveness inflection point. | |
| **C. Granular (7 plans / 6 waves)** | Mirrors Phase 18 precedent (7 plans, file-disjoint waves, single closing `feat(NN):` commit). 80–450 LOC per plan. Each TUNE-ID maps tightly to ≤2 plans. Robust to other gray-area resolutions. | ✓ |

**User's choice:** C (synthesized; locked).
**Notes:** Plan roster captured in 19-CONTEXT.md decisions D-23. Wave structure: 1→P01, 2→P02, 3→P03, 4→P04, 5→P05+P06 parallel, 6→P07 closing. Closing commit `feat(19): add declarative relevance tuning ...` triggers release-please cut 0.4.0 → 0.5.0.

---

## Backward-compat cutover

| Option | Description | Selected |
|--------|-------------|----------|
| **A. Strict migration (deprecate camelCase, remove in v2.0)** | Logger.warn at compile time; multi-version transition. | |
| **B. Permanent dual-support (both forms work forever)** | Accept everything. Worst footgun risk: silent typos in any-form become Meilisearch silent-ignores. Violates operational-honesty core value. | |
| **C. Mixed-form rejected (atom XOR string-keyed)** | Validator branches on key type; rejects mixed maps. Doesn't catch single-form typos. | |
| **D. Normalize-on-entry (3 input shapes → 1 canonical internal form)** | All three in-the-wild shapes (atom-camel, string-camel, atom-snake) accepted; `normalize_settings/1` produces canonical atom-snake form with `:__unrecognized__` bucket for passthrough. Doubled-key footgun impossible by construction. Zero deprecation needed; strictly additive over 0.3.0. | ✓ |

**User's choice:** D (synthesized; locked).
**Notes:** Critical research discovery — shipped v0.3.0 test fixtures use atom-keyed CAMELCASE (`%{searchableAttributes: [...]}`), not string-keyed. The original A/B/C postures didn't account for this shape. Posture D is the only posture that handles all three in-the-wild shapes without breakage. Optional `mix scrypath.upgrade.0.4` task deferred to v1.4 nice-to-have (not load-bearing). Operational-honesty alignment: Posture D is the only posture surveyed where typos in recognized-key names land somewhere observable (`:__unrecognized__` bucket, surfaced in `mix scrypath.settings.diff` output) instead of being silently ignored by Meilisearch.

---

## Lock-in question

**Question:** Lock in all 4 synthesized recommendations and proceed to write CONTEXT.md, or revisit any?

| Option | Description | Selected |
|--------|-------------|----------|
| Lock all 4 — write CONTEXT.md | Adopt: split opt-out placement, settings_merge on reindex+runtime + per-repo cascade source, 7 plans in 6 waves, Posture D normalize-on-entry. Coherent set; no deprecations; strictly additive over 0.3.0; closes Phase 19 with feat(19): → release-please → 0.5.0. | ✓ |
| Revisit opt-out placement | Re-open Gray Area 1. | |
| Revisit settings-merge / cascade | Re-open Gray Area 2. | |
| Revisit plan splitting | Re-open Gray Area 3. | |

**User's choice:** Lock all 4 — write CONTEXT.md.

---

## Claude's Discretion

Captured in 19-CONTEXT.md `<decisions>` "Claude's Discretion" subsection:
- Telemetry measurements/metadata shape for new `[:scrypath, :reindex, :settings_verified]` and `[:scrypath, :reindex, :verify_skipped]` events
- Exact text of optional informational compile-time hint for camelCase usage (D-19)
- JSON field ordering in `mix scrypath.settings.diff --json` output
- Hand-rolled `deep_merge/2` implementation details
- `Macro.underscore/1` strategy for string keys at canonicalize time
- Exact CHANGELOG entry copy for `:settings` opt removal from `@backfill_options`

## Deferred Ideas

Captured in 19-CONTEXT.md `<deferred>` section:
- Real `Scrypath.Meilisearch.Settings.hot_apply/3` implementation (v1.4)
- `mix scrypath.upgrade.0.4` migration task (v1.4 nice-to-have)
- Ranking-rules-strict warning telemetry (v1.4 nice-to-have)
- Per-query ranking overrides on `Scrypath.search/3` (hard non-goal; v2.0)
- `Scrypath.apply_settings/2` public verb (hard architectural rule; never)
- Auto-synonym generation, vector knobs, locale-aware stop words, per-environment ranking via mix opts (hard non-goals)
- Hot-applicable settings capability signal (`:hot_when_possible` schema flag) (v1.4)
- SHA-256 hash comparison in `mix scrypath.settings.diff` (additive ~20-LOC if ever needed)
- Cross-schema relevance blending in `search_many/2` (v1.4 namespaced under `Scrypath.Meilisearch.MultiSearch.federate/2`)
