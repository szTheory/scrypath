# Stack Research — v1.3 "Search Power That Phoenix Teams Reach For"

**Domain:** Elixir OSS library — Ecto-native search indexing and orchestration (Scrypath)
**Researched:** 2026-04-17
**Confidence:** HIGH

## Scope

This milestone is an **additive extension to an existing, publicly-released library** (`scrypath 0.3.0` on Hex). The v1.0–v1.2 stack is fixed and validated. This research answers only the three concrete stack questions relevant to v1.3:

1. Does the Meilisearch API shape for faceting / ranking / distinct / multi-search require any `Req` / HTTP-client changes?
2. Do multi-index federated search tests need any new Elixir test dependencies?
3. Which specific GitHub Actions upgrades clear the Node 20 deprecation warnings across the four current workflows (`ci.yml`, `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml`)?

**Non-goal for this research:** re-validating the Meilisearch-first backend choice, the Ecto-first API choice, or the Oban write-path — all three are validated and must not change in v1.3.

## Recommended Stack Additions / Changes

### Elixir dependencies (mix.exs) — NO CHANGES REQUIRED

| Dependency | Current pin | Status for v1.3 | Rationale |
|------------|-------------|-----------------|-----------|
| `{:ecto, "~> 3.13"}` | 3.13.x | **Keep as-is** | No Ecto API surface in v1.3 needs features newer than 3.13. Declarative `faceting`, `settings`, `distinct_attribute` live in schema macros Scrypath already owns — they are metadata reflection, not Ecto-query features. |
| `{:req, "~> 0.5"}` | 0.5 (latest 0.5.16, Nov 2025) | **Keep as-is** | All four new feature API surfaces — faceted search, settings patch, multi-search, distinct — are JSON-over-HTTP `POST` / `PATCH` against existing-shape endpoints. No streaming, multipart, SSE, or WebSocket is introduced. `Scrypath.Meilisearch.Client.run_request/5` already handles arbitrary JSON bodies via `[json: payload]` and is route-agnostic. |
| `{:jason, "~> 1.4"}` | 1.4 | **Keep as-is** | Payloads remain JSON-encodable maps/lists. No new encoding requirements. |
| `{:oban, "~> 2.21", optional: true}` | 2.21 (latest 2.21.0, Mar 2026) | **Keep as-is** | v1.3 does not add new worker types. Sync path is unchanged. |
| `{:nimble_options, "~> 1.1"}` | 1.1 | **Keep as-is** | New `facet_filter`, `search_many/2` opts validate through the same option-schema pattern v1.2 already uses. |
| `{:plug, "~> 1.18", only: :test}` | 1.18 | **Keep as-is** | Test harness for bypass-style HTTP mocks. |
| `{:ecto_sqlite3, "~> 0.22", only: :test}` | 0.22 | **Keep as-is** | Test Repo backing. |
| `{:credo, "~> 1.7"}` | 1.7 | **Keep as-is** | |
| `{:dialyxir, "~> 1.4"}` | 1.4 | **Keep as-is** | |
| `{:ex_doc, "~> 0.37"}` | 0.37 | **Keep as-is** | |

**Deliberate non-additions** (downstream consumer asked these be called out):
- No new HTTP client (e.g. Finch, Tesla, HTTPoison) — Req is sufficient and already the standard.
- No Elasticsearch-compat shim library — out of scope, and the product boundary explicitly avoids second-backend bleed.
- No Postgres FTS library (e.g. `pg_search`, `ecto_tsvector`) — locked non-goal per `PROJECT.md` "Out of Scope".
- No new facet-DSL library — facet filter expression validation lives inside Scrypath's query builder (same module family as the existing filter/sort translation in `Scrypath.Meilisearch.Query`).
- No new Elixir test framework or HTTP mock library (e.g. Mox, Bypass) — the existing `meilisearch_client` injection seam in `Scrypath.Meilisearch.Settings.apply/3` and `Client.search/3` already supports swap-in test clients; multi-index federated search tests reuse that seam without new dependencies.

### Meilisearch server version — RAISE CI PIN

| Component | Current CI pin | v1.3 recommendation | Rationale |
|-----------|----------------|---------------------|-----------|
| `getmeili/meilisearch` (services image in `ci.yml`) | `v1.15` (in two jobs: `phase5-verification`, `phase13-verification`) | **`v1.15`** (hold the lower bound) — but document tested range up through **`v1.42`** in README. | Every v1.3 feature lands on API shape that is already stable in v1.15: `/multi-search` federation (stable since v1.12), object-form `filterableAttributes` with granular `{features: {facetSearch, filter}}` (stable pre-v1.15), `facetDistribution`/`facetStats` in search response (stable), `distinctAttribute` setting (stable), `rankingRules`, `synonyms`, `stopWords`, and `typoTolerance` including `disableOnNumbers` (new in v1.15). Pinning lower at v1.15 keeps the CI matrix honest about the minimum tested server. Releases v1.16–v1.42 are additive (multimodal embeddings, chat completions, export route, experimental `foreignKeys` cross-index hydration) and do not change the shape Scrypath uses. |

**What this unlocks per v1.3 feature:**

| v1.3 Feature | Meilisearch API surface used | Minimum server | Scrypath integration point |
|--------------|------------------------------|----------------|-----------------------------|
| Faceted search — `faceting` field + `facet_filter` + `facet_distribution` + `facet_stats` | `POST /indexes/{uid}/search` with `facets: [...]` → response carries `facetDistribution` and (for numeric facets) `facetStats` | v1.12 (stable), confirmed in v1.15 | Extend `Scrypath.Meilisearch.Query.to_payload/1` with a `facets` key and optional facet-filter branch in `translate_filter/1`. Extend the search result struct to carry `facet_distribution` and `facet_stats`. No new `Client` route. |
| Relevance tuning — declarative synonyms / typo tolerance / ranking rules / distinct / stop words | `PATCH /indexes/{uid}/settings` with a merged settings map: `synonyms`, `typoTolerance` (incl. `disableOnNumbers`), `rankingRules`, `distinctAttribute`, `stopWords`, and `filterableAttributes` in its granular object form | v1.15 | `Scrypath.Meilisearch.Settings.resolve/2` already merges schema-declared settings with config overrides and hands them to `Client.update_settings/3`. v1.3 adds schema macros that populate new keys in that map — no new HTTP call. |
| Multi-index federated search — `Scrypath.search_many/2` | `POST /multi-search` with `{queries: [...], federation: {limit, offset, facetsByIndex, mergeFacets?, distinct?}}` → response carries `hits[]._federation.{indexUid, queriesPosition}` + merged `facetsByIndex` / `facetDistribution` / `facetStats` | v1.12 (stable), confirmed v1.15 | **New route** added to `Scrypath.Meilisearch.Client`: `multi_search/2` wrapping `POST /multi-search`. Per-schema validation runs first through each schema's query builder; payloads are stitched into a federation request. Hydration reads `indexUid` from each hit's `_federation` to route back to the correct schema. |
| Operator polish — richer `FailedWork.t()` + drift guide | No new Meilisearch API. Reads existing Oban / Repo data through the internal operations seam shipped in v1.2. | n/a | Additive fields on `FailedWork` struct + guide authoring. |
| Node 20 deprecation cleanup | No Meilisearch surface. | n/a | Workflow YAML bumps (below). |

**Why Req needs no change:** All four new endpoints (`/indexes/{uid}/search` with facets, `/indexes/{uid}/settings` with extra keys, `/multi-search`, existing task-status routes) are JSON `POST`/`PATCH` against a single base URL with an optional API-key header. The existing `run_request/5` → `Req.request/2` path is already route-agnostic — pass a new path, a new JSON body, done. `multi_search/2` is literally ten lines of wrapper code over `run_request/5`.

### GitHub Actions — REQUIRED version bumps for Node 20 deprecation

**Timeline (verified against GitHub Changelog 2025-09-19):** Node 20 reaches end-of-life April 2026 (this month). Actions are forced onto Node 24 runtime by default starting **June 2, 2026**. Node 20 binary is removed from runners on **September 16, 2026**. Workflows emitting `Node 20 deprecated` warnings today will start hard-failing after the September removal.

Current workflow pins (scanned across all four files):

| Action | Currently pinned | Node runtime of current pin | Target pin | Node runtime of target | Verified |
|--------|------------------|------------------------------|------------|-------------------------|----------|
| `actions/checkout` | **Mixed** — `@v4` in `ci.yml` (all 3 jobs), `@v6` in `release-please.yml` (both jobs), `publish-hex.yml`, `verify-published-release.yml` | v4 → Node 20 | **`@v6`** (v6.0.2, Jan 2026) | Node 24 | `ci.yml` is the only workflow still on v4 — this is the only checkout bump required for v1.3. v5.0.1 (Nov 2025) was the transitional Node 24 release; v6.0.0 is the stable Node 24 default. |
| `actions/cache` | **`@v4`** in `ci.yml` (all 3 jobs) | v4 → Node 20 | **`@v5`** (v5.0.5, Apr 2026) | Node 24 | v5.0.0 release note: *"actions/cache@v5 runs on the Node.js 24 runtime and requires a minimum Actions Runner version of 2.327.1."* GitHub-hosted runners satisfy this minimum. |
| `erlef/setup-beam` | **`@v1`** (floating major) in all four workflows | v1 tracks latest; as of v1.24.0 → Node 24 | **`@v1`** (no change to pin) OR **`@v1.24.0`** (pin hash for reproducibility) | Node 24 | v1.24.0 (Mar 30, 2026) release note: *"Since GitHub is phasing out Node 20 runners, the erlef/setup-beam action has updated its requirements (see PR #426). Please ensure your workflow files are updated…"* Because the existing pins use the floating `@v1` major tag, the Node 24 migration already flows in automatically — but the runner/action compatibility call-out below still applies. |
| `actions/upload-artifact` | **Not currently used** (scanned: not referenced in any of the four workflow files) | n/a | n/a — if added later, use **`@v7`** (v7.0.1, Apr 2026, Node 24) | Node 24 | Mentioned in downstream consumer note but not actually present; no action required in v1.3. Listed here so future workflow additions know the target. |
| `googleapis/release-please-action` | **`@v4`** in `release-please.yml` | v4 tracks latest; v4.4.1 (Apr 2026) runs on Node 24–compatible runtime | **`@v4`** (no change) | n/a — composite / Node-24-ready | Already current through the floating major tag. |

**Concrete diff required for Node 20 cleanup** (all changes are in `.github/workflows/ci.yml` only):

```yaml
# .github/workflows/ci.yml — change each occurrence (3 jobs × 2 actions = 6 pin bumps)
- uses: actions/checkout@v4   →   - uses: actions/checkout@v6
- uses: actions/cache@v4      →   - uses: actions/cache@v5
```

The other three workflows (`release-please.yml`, `publish-hex.yml`, `verify-published-release.yml`) already use `actions/checkout@v6` and do not use `actions/cache`, so they are already clean.

**Why this is the full cleanup:** Enumerating every `uses:` across all four workflow files yields only three distinct JavaScript actions under GitHub's Node-runtime deprecation umbrella: `actions/checkout`, `actions/cache`, and `erlef/setup-beam`. `googleapis/release-please-action@v4` is a Node action but its v4 line is already on a Node-24-compatible release. There is no `setup-node`, no `upload-artifact`, no `download-artifact`, no `cache/restore` or `cache/save`, and no third-party Node actions in the workflow set. Bumping the two pins above resolves 100% of the Node 20 deprecation warnings.

### Runner image — NO CHANGE

All four workflows run on `ubuntu-latest`. GitHub's `ubuntu-latest` image already ships runner version ≥ 2.327.1 as of early 2026, which satisfies both `actions/cache@v5` and `actions/checkout@v6` minimums. No `runs-on` change is required. Self-hosted runners are not in use.

### Development tooling — NO CHANGE

| Tool | Version | Status | Notes |
|------|---------|--------|-------|
| Elixir | `1.17.3` (min), `1.19.0` (primary) — matrix in `ci.yml` | Keep | No v1.3 feature requires newer Elixir. |
| OTP | `26.2.5` / `28.0` / `28.1` — matrix in `ci.yml` | Keep | Minor inconsistency: `phase13-verification` pins OTP `28.0` while `phase5-verification` and `quality` pin `28.1`. Leave for v1.3 unless the verify sweep chooses to align them as a cosmetic fix. |
| Credo | 1.7 | Keep | |
| Dialyzer | 1.4 | Keep | |
| ExDoc | 0.37 | Keep | |
| `mix hex.audit` | built-in | Keep | Already in the `quality` job. |

## Installation

No new `mix deps.get` action is needed. The only stack change is a two-line diff in `.github/workflows/ci.yml`:

```yaml
# Three occurrences in ci.yml (test job, quality job, phase5-verification job,
# phase13-verification job) — bump each checkout/cache pin:
- uses: actions/checkout@v6   # was @v4
- uses: actions/cache@v5      # was @v4
```

## Alternatives Considered

| Recommended | Alternative | When Alternative Would Apply | Why not now |
|-------------|-------------|------------------------------|-------------|
| Keep Req `~> 0.5` | Switch to Finch + direct JSON | If Scrypath needed raw HTTP/2 multiplexing or streaming for high-throughput federated search | Federated search volumes for Phoenix SaaS teams at v1.3's target tier are fine on Req/Mint; no evidence of throughput pressure from existing adopters. |
| Extend `Scrypath.Meilisearch.Query` for facets in-module | Extract a new `Scrypath.Meilisearch.FacetFilter` module | If facet-filter grammar grows complex enough to warrant its own test surface | v1.3 facet filters are a strict extension of existing filter tuples (same `{field, op, value}` shape) — splitting the module would create friction without payoff. Revisit in v1.4 only if grammar complexity warrants. |
| Add `multi_search/2` as a thin wrapper in `Client` | Build a dedicated `Scrypath.Meilisearch.MultiSearch` module | If multi-search evolves beyond a single federation request shape (e.g. query batching, streaming) | Single federation request shape is sufficient; a second module is premature abstraction. |
| Bump CI image pin to tested-through `v1.15` and document the range | Pin CI to `v1.42` (latest) | If v1.3 depended on v1.42-specific features | None of the v1.3 features require anything newer than v1.15, and raising the minimum-tested version would create a false adoption barrier for users on older Meilisearch installs. Keep minimum honest; test range is a README note. |
| Keep `erlef/setup-beam@v1` floating major | Pin `erlef/setup-beam@<commit-sha>` | Supply-chain hardening for a security-sensitive library | Scrypath's threat model is "install via Hex"; the release contract is already verified through `mix verify.phase11` + `mix verify.release_publish`. Pinning setup-beam by SHA is a separate, later concern. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Adding a second HTTP client | Splits the transport surface and doubles test/mock work | Extend `Scrypath.Meilisearch.Client.run_request/5` with the two new routes. |
| Adopting the experimental `foreignKeys` Meilisearch feature (v1.39+) for multi-index | Marked *experimental* in Meilisearch's own release notes, requires `/experimental-features` toggle, and does not work in a remote sharding environment | Use the stable `/multi-search` federation endpoint (`federation: {...}`) for `search_many/2`. If real adopters ask for cross-index joins in v1.4+, revisit `foreignKeys` once Meilisearch promotes it to stable. |
| Introducing Mox or Bypass in `:test` | Adds dependency surface without solving a problem | Continue using the `meilisearch_client` injection seam already present in `Scrypath.Meilisearch.Settings.apply/3` and the client functions. A simple in-process stub module is sufficient for multi-index federated search tests. |
| Adding a facet-expression parser library (e.g. `nimble_parsec`-based DSL) | Over-engineering the v1.3 facet-filter grammar, which is a small closed set of operators | Keep facet filter translation inline in `Scrypath.Meilisearch.Query` using the same `translate_operator/1` style already there. |
| `actions/checkout@v5` (Node 24 transitional) | Already superseded by `@v6` | `actions/checkout@v6`. |
| Continuing to use `actions/checkout@v4` or `actions/cache@v4` after June 2, 2026 | Hard-fails once Node 20 is removed from runners (Sep 16, 2026) | Bump to `@v6` / `@v5` in `ci.yml` as part of this milestone. |
| Postgres full-text search libraries (`pg_search`, `ecto_tsvector`, `paraphrase`) | Explicit `PROJECT.md` non-goal — muddies product boundary | Stay Meilisearch-first; Postgres FTS is not part of v1.x. |
| Elasticsearch / OpenSearch compatibility shims | Locked non-goal for v1.3 ("no second public backend") | Preserve the internal adapter seam; do not expose it publicly. |
| Vector / hybrid / semantic search features (Meilisearch v1.16 multimodal embeddings, v1.25 Cohere rerank, v1.17 chat completions) | Locked non-goal ("no vector/hybrid/semantic search") | Ignore these Meilisearch feature paths even though the server supports them. |

## Stack Patterns by Variant

**If running self-hosted GitHub Actions runners:**
- Before bumping `actions/cache@v5` and `actions/checkout@v6`, verify the runner binary is ≥ 2.327.1.
- Scrypath itself uses GitHub-hosted `ubuntu-latest`, so this is an adopter concern, not a library concern.

**If a downstream Phoenix app targets Meilisearch < v1.12:**
- `search_many/2` (requires `/multi-search`) will return a 404 from the server.
- Facet distribution and facet stats on single-index search work back to very early Meilisearch versions, so faceted search alone is safely backwards-compatible.
- Document this in the v1.3 faceted-search guide: "Faceted search works on any supported Meilisearch version; `search_many/2` requires Meilisearch ≥ v1.12."

**If an adopter already pinned `typoTolerance` via a manual settings override:**
- v1.3's declarative synonyms/typo/ranking/distinct/stopwords settings must preserve the existing "schema-declared merged with config override" precedence in `Scrypath.Meilisearch.Settings.resolve/2`. Manual overrides continue to win.

## Version Compatibility

| Pin | Compatible With | Notes |
|-----|-----------------|-------|
| `actions/checkout@v6` | `ubuntu-latest` runner ≥ 2.327.1 | GitHub-hosted runners satisfy this; only relevant if self-hosted. |
| `actions/cache@v5` | `ubuntu-latest` runner ≥ 2.327.1 | Same requirement as checkout@v6. |
| `erlef/setup-beam@v1.24.0+` | Node 24 runtime | Tracks automatically via the floating `@v1` pin already in use. No explicit bump required. |
| Meilisearch server `v1.15`–`v1.42+` | Req `~> 0.5`, Scrypath HTTP body shape | `/multi-search` stable; `filterableAttributes` granular object form stable; `facetDistribution` + `facetStats` stable. No behavior drift observed across the range for the subset of routes Scrypath uses. |
| Elixir `1.17.3` / `1.19.0` matrix | OTP `26.2.5` / `28.0` / `28.1` | Already validated in v1.2 CI. |
| Oban `~> 2.21` | Elixir ≥ 1.15 | No change from v1.2. |

## Sources

- [Meilisearch v1.15.0 release notes](https://github.com/meilisearch/meilisearch/releases/tag/v1.15.0) — confirmed `typoTolerance.disableOnNumbers`, stable comparison operators on string filters. **HIGH**
- [Meilisearch v1.16.0 release notes](https://github.com/meilisearch/meilisearch/releases/tag/v1.16.0) — confirmed multimodal embeddings (ignored for v1.3) and `/export` route (ignored). **HIGH**
- [Meilisearch v1.42.0 release notes](https://github.com/meilisearch/meilisearch/releases/tag/v1.42.0) — confirmed experimental `foreignKeys` cross-index hydration (explicitly NOT adopted in v1.3). **HIGH**
- [Meilisearch multi-search / federation API reference](https://www.meilisearch.com/docs/reference/api/multi_search) — confirmed stable federation request shape (`queries` + `federation.{limit, offset, facetsByIndex, mergeFacets, distinct}`) and `_federation` hit metadata. **HIGH**
- [Meilisearch search API reference — facets and facetStats/facetDistribution](https://www.meilisearch.com/docs/reference/api/search) — confirmed stable single-index facet request shape. **HIGH**
- [Meilisearch settings API reference — filterableAttributes granular form](https://www.meilisearch.com/docs/reference/api/settings) — confirmed object-form `{attributePatterns, features: {facetSearch, filter}}` is the current stable shape. **HIGH**
- [GitHub Changelog: Deprecation of Node 20 on GitHub Actions runners (2025-09-19)](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/) — confirmed Node 24 forced-default on 2026-06-02, Node 20 removed 2026-09-16. **HIGH**
- [actions/checkout v6.0.0 release notes](https://github.com/actions/checkout/releases/tag/v6.0.0) — confirmed Node 24 default, minimum runner v2.327.1. **HIGH**
- [actions/checkout v6.0.2 release notes (Jan 2026)](https://github.com/actions/checkout/releases/tag/v6.0.2) — latest stable at time of research. **HIGH**
- [actions/cache v5.0.0 release notes](https://github.com/actions/cache/releases/tag/v5.0.0) — confirmed Node 24 runtime and v2.327.1 runner minimum. **HIGH**
- [actions/cache v5.0.5 release (Apr 13, 2026)](https://github.com/actions/cache/releases/tag/v5.0.5) — latest stable. **HIGH**
- [erlef/setup-beam v1.24.0 release notes (Mar 30, 2026)](https://github.com/erlef/setup-beam/releases/tag/v1.24.0) — confirmed Node 24 support and alignment with GitHub's deprecation schedule (PR #426). **HIGH**
- [actions/upload-artifact v7.0.0 release notes](https://github.com/actions/upload-artifact/releases/tag/v7.0.0) and [v6.0.0](https://github.com/actions/upload-artifact/releases/tag/v6.0.0) — reference only; action not currently used by Scrypath. **HIGH**
- [googleapis/release-please-action releases](https://github.com/googleapis/release-please-action/releases) — confirmed v4.4.1 (Apr 13, 2026) is current; already pinned via `@v4`. **HIGH**
- `mix.exs` at `HEAD` — enumerated current dependency pins. **HIGH**
- `.github/workflows/{ci,release-please,publish-hex,verify-published-release}.yml` at `HEAD` — enumerated every `uses:` pin and confirmed only `ci.yml` carries the v4 checkout/cache pins. **HIGH**
- `lib/scrypath/meilisearch/{client,query,settings}.ex` at `HEAD` — confirmed Req integration is route-agnostic via `run_request/5` and that `Settings.resolve/2` already supports merged declared-plus-config settings. **HIGH**

---
*Stack research for: v1.3 Meilisearch-native search power + CI Node 20 cleanup on scrypath 0.3.0+*
*Researched: 2026-04-17*
