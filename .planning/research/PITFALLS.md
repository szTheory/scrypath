# Pitfalls Research

**Domain:** Published Elixir library (Hex) — adding Meilisearch-native faceting, relevance tuning, multi-index federated search, and richer failure-inspection to `scrypath 0.3.0` without breaking shipped sync/search/operator contracts
**Researched:** 2026-04-17
**Confidence:** HIGH (evidence grounded in the committed v1.2 surface, the v1.2 audit, and the shipped public contract; Meilisearch semantics verified against current settings/facet API behavior)

## Critical Pitfalls

### Pitfall 1: Re-introducing the "uncommitted-on-disk vs. published-to-Hex" divergence

**What goes wrong:**
v1.2 shipped Hex `0.3.0` with only Phases 11, 12, partial 13, and 17 because Phases 13-body, 14, 15, and 16 existed on disk but were never staged/committed. `release-please` cut the tag from a clean checkout, so the tarball diverged from engineering reality (see `.planning/milestones/v1.2-MILESTONE-AUDIT.md`). v1.3 could repeat this: a feature closes locally, verification passes locally, but the release tag checked out by `publish-hex.yml` lacks the new module files, guide files, or CHANGELOG entries.

**Why it happens:**
- GSD workspaces let phase agents create files and pass verification without a single "is this on `main`?" check.
- `mix verify.phase11` validates the package build against on-disk content, not against the commit graph.
- Verification artifacts are co-located with the files they describe, so a missing commit for the body simultaneously masks the absence of the VALIDATION/VERIFICATION artifacts.
- The human reviewer sees a green local bar and assumes the next Release Please PR will carry everything forward.

**How to avoid:**
- Add a `mix verify.workspace_clean` (or extend `verify.phase11`) gate that fails if `git status --porcelain` is non-empty or if HEAD is behind `origin/main`. Run it as a CI job on every PR and as the first step of the `publish-hex` workflow.
- Add a `mix verify.release_parity X.Y.Z` that, given a version, diffs the files that `mix hex.build --unpack` would include against a canonical "expected modules per phase" manifest written during phase closure. Any file missing from the tarball that appears in `.planning/phases/*/SUMMARY.md` flips the gate red.
- Make every phase SUMMARY explicitly enumerate the files it expects to ship (module paths, guide paths, test paths). The verify task reads that list as ground truth.
- In the publish-hex workflow, immediately after `hex.publish`, run a `mix verify.release_publish X.Y.Z --expect-symbols "Scrypath.search_many,Scrypath.Operator.FailedWork.attempts,..."` step that compiles a throwaway consumer against the actual published tarball and confirms each promised function/type exists. If it fails, the release workflow fails loudly instead of quietly shipping a partial surface.

**Warning signs:**
- A PR passes CI but contains new feature tests without the module those tests exercise (caught by `mix compile --warnings-as-errors`, but trivial to miss if the module is stubbed to accept anything).
- `git status` on a workspace shows untracked `.ex` files under `lib/scrypath/` after a phase closes.
- `mix hex.build --unpack` output does not include a guide or module that a phase SUMMARY names.
- CHANGELOG entries describe functionality that does not appear in `mix hex.info scrypath @latest` once published.

**Phase to address:**
**v1.3 Phase 0 (pre-roadmap) or the first feature phase** must land the workspace-clean + release-parity gates before any feature phase. Also mandate a verification artifact naming convention in each subsequent phase SUMMARY so parity can be mechanically checked.

---

### Pitfall 2: Breaking the shipped `SearchResult.t()` shape when adding facet distribution/stats

**What goes wrong:**
`Scrypath.SearchResult` is a struct with `@enforce_keys [:query, :hits, :records, :raw, :missing_ids, :page]`. Any consumer pattern-matching on `%SearchResult{}` today, extracting map keys via `Map.keys/1`, or round-tripping through `Jason.encode!/1` will break if v1.3 adds a mandatory `:facets` (or `:facet_distribution`, `:facet_stats`) key. Adding it to `@enforce_keys` is a hard break; constructing it unconditionally but leaving consumers untouched causes schema-drift downstream (e.g., LiveView serialization diffs, Phoenix template access on `result.facets` exploding when nil).

**Why it happens:**
- "Adding a field to a struct is usually non-breaking" is a generalization that fails for `@enforce_keys`, for `struct!/1` callers who pass explicit maps, and for anything depending on the exact key set.
- The feature arc for faceting naturally reaches for "just put facets on SearchResult" without interrogating who is already touching that struct.
- Documentation examples written against the 0.3.0 shape will be wrong by default.

**How to avoid:**
- Add `:facets` (or a nested `:facets` struct) as an **optional** field with default `nil` or `%{distribution: %{}, stats: %{}}`. Do NOT add it to `@enforce_keys`.
- Keep the `SearchResult.new/4` arity stable. If more data is needed from the raw backend response, pipe it in through the existing `raw` parameter and derive the facets field from `raw` inside `new/4`.
- Document that `:facets` is `nil` unless the caller requested faceting via search opts — do not emit synthetic distributions for calls that did not request them (that would change `:raw` semantics).
- Add a regression test that compiles the previous `SearchResult.new/4` call signature and decomposes all 0.3.0 keys to ensure nothing renames or becomes enforced.
- Consider introducing a sub-struct `Scrypath.SearchResult.Facets` so future additions (stats, counts, hierarchical facets) evolve inside a well-known namespace rather than inflating the top-level struct.

**Warning signs:**
- CHANGELOG for v1.3 says "SearchResult now includes facets" without the word "optional".
- Test fixtures that build `%SearchResult{...}` literals fail to compile on new branches.
- A Phoenix LiveView guide update removes `|| %{}` guards on `result.facets`.

**Phase to address:**
**The faceted search phase** — specifically the plan that lands `SearchResult` evolution. Add a compile-time compatibility test to `test/scrypath/search_result_compatibility_test.exs` that pins the 0.3.0 shape.

---

### Pitfall 3: Breaking the `FailedWork.t()` struct by adding new `@enforce_keys` fields

**What goes wrong:**
`Scrypath.Operator.FailedWork` currently enforces `[:id, :schema, :mode, :source, :operation, :state, :retryable?]`. v1.3 wants to add `attempt_count`, `error_reason_class`, and `last_attempt_at`. If any of these lands in `@enforce_keys`, every existing `%FailedWork{...}` literal in the library's own tests, example apps, and downstream consumers breaks. Adding them as optional with surprising `nil` defaults in hot paths (e.g., retry logic that now reads `attempt_count || 0`) hides the upgrade trap.

**Why it happens:**
- "This is an operator API — nobody's constructing it by hand" is wrong: documentation examples, test doubles, and fixtures routinely build these structs.
- The instinct is to treat the richer fields as required because they feel important; required-ness is a breaking change once a struct is publicly typed.
- `@type t :: %__MODULE__{...}` with new fields silently widens the Dialyzer contract — consumers depending on an exact typed shape will get spec violations.

**How to avoid:**
- Keep new fields out of `@enforce_keys`. Default `attempt_count` to `nil` (not `0` — `0` is a lie if the data is unavailable, and `nil` is self-describing as "unknown").
- Default `error_reason_class` to `:unknown`.
- Default `last_attempt_at` to `nil` with an explicit docstring contract: "nil when the source system does not expose this."
- Update `@type t` to make the new fields `type | nil` consistently — never strengthen the current type.
- Add a `FailedWork.legacy_shape/1` helper for one release so anyone who pattern-matched on the struct literal can mechanically upgrade. Deprecate, do not remove.
- Document "when we add new optional fields to FailedWork, we do not remove, rename, or promote existing ones to `@enforce_keys`" as a library-level invariant in `ARCHITECTURE.md` and in CHANGELOG policy.

**Warning signs:**
- A PR diff adds a key name to the `@enforce_keys` list.
- New retry logic pattern-matches `%FailedWork{attempt_count: n}` where `n` is treated as present — the code will crash on older serialized forms if `nil`.
- Docstring examples start omitting legacy fields from `%FailedWork{...}` literals.

**Phase to address:**
**The operator-polish phase** (FailedWork enrichment). Add a struct-shape compatibility test pinning the 0.3.0 key set and guaranteeing all new keys are optional with documented defaults.

---

### Pitfall 4: Facet filter validation silently replacing — rather than composing with — the existing filter parser

**What goes wrong:**
The current `Scrypath.Options.validate_search_filter/1` + `validate_filterable_fields!/2` pipeline rejects boolean composition (`:or`, `:and`, `:not`) and only permits keyword-list filters over declared `filterable` fields, with a narrow range-operator allowlist (`:eq, :gt, :gte, :lt, :lte`). If v1.3 introduces a new facet-filter parser (e.g., `facet_filter:` or a string-based Meilisearch filter expression) that bypasses `validate_filterable_fields!`, users can:
- filter on fields that were never declared `filterable` (leaking the common-path guarantee)
- inject raw Meilisearch filter syntax (breaking backend-agnostic seam)
- mix incompatible filter shapes in the same query (legacy keyword `:filter` vs. new facet `:filter`) with undefined precedence

**Why it happens:**
- Meilisearch's facet filter syntax is string-based and ergonomic (`"genres = 'sci-fi' AND year > 2020"`), so there's pressure to expose it directly as a string.
- The existing keyword-list parser is restrictive and doesn't obviously cover facet needs like "values in a set" or "count by facet".
- Two separate parsers look easier than unifying the contract.

**How to avoid:**
- Route every facet filter through the **same** `Options.validate_search_filter/1` pipeline. Extend the parser to support new operators (`:in`, `:not_in`) rather than creating a second parser.
- Reject raw Meilisearch filter strings on the common path. Backend-native filter strings belong under `Scrypath.Meilisearch.search/3` (the escape hatch), not on `Scrypath.search/3`.
- If a "facets to request" list (different from "filter by facet value") is added, it must also validate against `filterable` (or a new `faceting` field list) at the same validation stage. Never accept `facets: :all` or a wildcard — explicit lists only.
- Document a single precedence rule: "`filter:` covers both attribute filters and facet-value filters; there is no second filter option." Prevents the two-parser drift.
- Add property-based tests that any filter accepted by v1.3 would also be accepted by the v0.3.0 parser when restricted to its operator subset, and that any v0.3.0 filter remains accepted unchanged.

**Warning signs:**
- A new option name like `facet_filter:` or `facets_filter:` appears in search options.
- The options module grows a second "raw passthrough" validator.
- Tests start constructing Meilisearch filter strings in the library's own test suite (filter strings should only live in backend-adapter tests).
- Search docs show two different filter syntaxes on the same page.

**Phase to address:**
**The faceted search phase** — lock `Options.validate_search_filter/1` extension as the only entrypoint and add the property test in the same PR that lands facet filtering.

---

### Pitfall 5: Applying relevance settings outside the managed reindex pipeline and causing silent search downtime

**What goes wrong:**
Meilisearch settings that change the searchable-attribute contract (`searchableAttributes`, `filterableAttributes`, `sortableAttributes`, `distinctAttribute`, `rankingRules`) trigger a full index rebuild on the Meilisearch side when applied to a live populated index. If v1.3 exposes "apply relevance settings" as a thin wrapper over `Scrypath.Meilisearch.Settings.apply/3` targeting the **live** index, the caller's search traffic will degrade or zero out for the duration of Meilisearch's internal rebuild. Worse: `synonyms`, `stopWords`, and `typoTolerance` changes apply immediately but can change ranking in ways that look like a bug to production operators who didn't realize settings are partial-upsert semantics (changed keys apply; unchanged keys retain previous values, which can reintroduce stale synonyms).

**Why it happens:**
- `Scrypath.Meilisearch.Settings.apply/3` exists today and is single-step. It looks like the obvious target.
- `Scrypath.reindex/2` already does "create target → apply settings → backfill → optional cutover" correctly (lib/scrypath/reindex.ex L20-45), but operators don't always realize that relevance changes need the same workflow.
- Meilisearch settings `PATCH` semantics are per-field-partial — callers who don't explicitly clear a field retain old values, which feels like a bug but is Meilisearch's correct contract.

**How to avoid:**
- Do **not** add a public `Scrypath.apply_settings/2` verb that targets the live index. The only public surface for applying schema-derived relevance should be `Scrypath.reindex/2`, which already sequences `create target → apply settings → backfill → cutover` (preserve that order — it is documented in ARCHITECTURE.md as the guard against two known operator mistakes).
- If operators need "hot" settings changes that do not require re-indexing (e.g., `synonyms`, `stopWords`, `typoTolerance`), expose them under `Scrypath.Meilisearch.*` (the explicit escape hatch) rather than `Scrypath.*`, and document loudly that other settings require `reindex/2`.
- Document which Meilisearch settings require a rebuild and which do not. Reference the official Meilisearch settings doc in the guide and link from the schema DSL documentation.
- Make the schema-level `settings:` declaration the single source of truth. v1.3's relevance-tuning feature should extend that map (adding `synonyms`, `stopWords`, `rankingRules`, etc.) and let `Scrypath.reindex/2` apply them, not teach the library a new mutation verb.
- Add telemetry events `[:scrypath, :reindex, :settings_applied]` and `[:scrypath, :reindex, :cutover]` so operators can see the ordering actually happened. If only one of them is emitted, alarms fire.

**Warning signs:**
- A new public function `Scrypath.apply_settings/2` or similar verb appears outside `Scrypath.Meilisearch.*`.
- A guide recommends "just run `apply_settings` on the live index".
- `Scrypath.reindex/2`'s fixed workflow order (L20-45 of reindex.ex) is relaxed to parallel steps or made optional.
- Production operators report "search went empty during deploy" after a settings change.

**Phase to address:**
**The relevance-tuning phase.** Mitigation is architectural and belongs in the plan that lands declarative relevance settings: keep the mutation path owned by `reindex/2`.

---

### Pitfall 6: `search_many/2` federation that bypasses per-schema validation

**What goes wrong:**
A naive `Scrypath.search_many([{Post, "elixir"}, {Comment, "elixir"}], opts)` implementation forwards to Meilisearch's multi-search endpoint with pooled filters/sorts. If the implementation applies `opts[:filter]` or `opts[:sort]` uniformly to every sub-query, it will:
- accept filter fields that are `filterable` for one schema but not another (violating the per-schema contract the common path established in v1.0)
- leak fields that exist in one schema but not another, returning validation errors deep inside Meilisearch instead of at the Elixir options layer
- couple schemas that previously had independent search contracts, creating unplanned API coupling
- produce a single result shape that inconsistently mixes federated hits — consumers lose per-schema validation and per-schema hydration

**Why it happens:**
- Meilisearch's multi-search takes an array of requests, each already holding its own filter/sort. The path of least resistance is "accept common opts and fan them out".
- Hydration is repo-per-schema in the current design (see `Scrypath.Search.maybe_hydrate/3`). Federation naturally tempts a developer to pick a "winning" repo or skip hydration entirely.
- Per-schema validation requires pairs of `(schema, opts)` rather than a single opts bag, which is an API shape the library doesn't yet have.

**How to avoid:**
- Design `search_many/2` to accept a **list of request records**: `[{schema, text, opts}, ...]` where each `opts` is validated independently by the same `Options.validate_search_options!/2` the single-schema path uses. Do NOT accept a single shared `opts` argument that gets copied.
- Return a Scrypath-owned `%Scrypath.MultiSearchResult{results: [%SearchResult{schema: Post, ...}, %SearchResult{schema: Comment, ...}]}` rather than a flattened federated hit list. This preserves per-schema hydration and the existing `SearchResult.t()` contract on each entry.
- If `SearchResult` currently lacks a `:schema` field, consider adding it (optional, defaulting to nil for single-schema results — see Pitfall 2 for struct evolution rules).
- Do each sub-search's hydration independently using the per-schema `repo:` option. Federated hydration across heterogeneous schemas is a non-goal; document it as out of scope.
- Never share a filter keyword list across schemas. If the caller wants to apply the same filter value to every sub-query, they pass it into every sub-request themselves.
- Explicitly reject boolean composition across schemas: `search_many` is federation, not a join.
- Never expose Meilisearch's multi-search response shape directly. Translate every sub-response through `SearchResult.new/4`.

**Warning signs:**
- `search_many` type spec accepts `keyword()` at the top level (meaning shared opts) rather than a list of per-request tuples.
- Tests pass a single `filter:` keyword list and expect it to apply to both schemas.
- Results come back as a flat list of maps instead of a list of `%SearchResult{}` structs.
- Any code path in `search_many` calls into raw Meilisearch client APIs instead of going through `Scrypath.Backend.search/3`.

**Phase to address:**
**The multi-index search phase.** Lock the per-schema validation + per-schema result contract in the initial API plan; write a property test that asserts "validation for each sub-request matches what the single-schema path would have enforced".

---

### Pitfall 7: Leaking Meilisearch-native payloads through `search_many/2` or facet APIs

**What goes wrong:**
Meilisearch responses carry backend-native fields like `facetDistribution`, `facetStats`, `processingTimeMs`, `estimatedTotalHits`, and rankingScore debug info. If v1.3 surfaces these directly by passing `raw_result` through unchanged, or by exposing Meilisearch-native field names on `SearchResult`, the public API promises backend-specific shapes that will be impossible to deliver when (if ever) a second backend lands — or when Meilisearch itself renames a field in a minor upgrade (Meilisearch has done this: `nbHits` → `estimatedTotalHits` → `totalHits` across versions).

**Why it happens:**
- It's "easier" to pass through raw backend fields than to define a Scrypath-owned shape.
- Docs written against specific Meilisearch responses leak field names into the library's own API.
- `SearchResult.page/1` already Maps many of Meilisearch's native pagination keys (search_result.ex L34-47) — the precedent exists but is internal.

**How to avoid:**
- Every facet-related public field lives in a Scrypath-owned struct or map with snake_case Elixir-idiomatic names. Never `facetDistribution` on the public struct; always `facet_distribution` (or nested `%Facets{distribution:, stats:}`).
- Keep `raw:` on `SearchResult` as the explicit escape hatch — if a caller wants Meilisearch-native fields, they reach into `:raw` knowingly. Document that `:raw` is backend-specific and not covered by the stable contract.
- For any Meilisearch field that might be renamed by Meilisearch upstream, normalize in `SearchResult.new/4` to the Scrypath-owned name.
- Add a Dialyzer spec regression test that ensures `SearchResult.t()` fields are all atoms/structs/primitives with no string-keyed maps of backend-native shape.
- Under `Scrypath.Meilisearch.*`, it is fine to expose raw shapes. That namespace is the escape hatch by design.

**Warning signs:**
- Documentation examples access `result.facetDistribution` (camelCase) on the public surface.
- A new struct field has a name that matches a Meilisearch API response field letter-for-letter.
- Code under `lib/scrypath/search*.ex` or `lib/scrypath/*_result.ex` imports a Meilisearch client module directly.

**Phase to address:**
**The faceted search phase** and **the multi-index search phase** must both hold this line.

---

### Pitfall 8: "Pencil-whipping" VALIDATION.md closures for v1.2 Phase 13, 14, 15

**What goes wrong:**
The v1.2 audit originally carried a Nyquist gap (phases 13–15 lacked runnable-test-cited `VALIDATION.md` evidence). **Closed 2026-04-17** via Phase 23 — `.planning/milestones/v1.2/*-VALIDATION.md` + `v1.2-MILESTONE-AUDIT.md` Nyquist `compliant`. The ongoing risk is the same pattern on *future* milestones: the temptation to close gaps by writing VALIDATION.md files that restate what the phase did (pencil-whipping) rather than proving the shipped behavior works under Nyquist-level scrutiny (test evidence, integration runs, human UAT steps demonstrated). A pencil-whipped VALIDATION.md is worse than no VALIDATION.md — it signals compliance where none exists and pollutes the audit trail for future milestones.

**Why it happens:**
- VALIDATION closure is low-status "bookkeeping" work that gets rushed.
- The shipped code "works" in CI, so writing a VALIDATION.md feels redundant.
- The template is lenient enough to accept vague statements.
- Under time pressure, closing three VALIDATION.md files feels equivalent to building a real feature.

**How to avoid:**
- Require each retroactive VALIDATION.md to link to a specific, runnable test path (file + line range or test name) that would fail if the claimed behavior regressed. No prose-only closures.
- Require each VALIDATION.md to name the evidence type: integration test (live Meilisearch required), unit test, doctest, manual runbook with a diff of Hex API output, etc. "Verified by inspection" is not acceptable evidence.
- Require the VALIDATION.md to run through `mix verify.phase13` / `mix verify.phase14` (both already exist per ci.yml L92-96) and include that command + a captured exit code in the document.
- For Phase 15 specifically, the VALIDATION.md must demonstrate that **live operator APIs** return real data against a running Meilisearch — the existing `phase13-verification` CI job provides this substrate. Use it.
- Require a peer reviewer to explicitly approve the VALIDATION.md separately from the feature PR that wrote it, so it cannot be rubber-stamped inside a large PR.
- If the evidence doesn't exist, the honest move is "write the missing test first, cite it second" — never the reverse.

**Warning signs:**
- A VALIDATION.md file uses the word "verified" without naming a test or command.
- A VALIDATION.md file restates phase success criteria without mapping each one to evidence.
- The VALIDATION.md closure is bundled into a feature PR and the reviewer focuses only on the feature diff.
- `mix verify.phase13` or `mix verify.phase14` is invoked but the output is not captured in the VALIDATION.md.

**Phase to address:**
**The release/tooling-debt retirement phase** (where VALIDATION.md closure happens). Prefer splitting VALIDATION closure into its own PR so it gets focused review.

---

### Pitfall 9: Widening the public contract toward non-goals (second backend, vector search, dashboard)

**What goes wrong:**
`PROJECT.md` "Out of Scope" is explicit: no second public backend before adoption pressure, no vector/hybrid search, no dashboard product. v1.3 features tempt non-goal creep:
- **Multi-index search** easily slides into "multi-backend" if the abstraction is designed around `{backend, schema, text}` triples rather than `{schema, text, opts}`.
- **Relevance tuning** easily slides into "hybrid retrieval" if `rankingRules` exposes vector-search hooks like `_vectors` semantics.
- **Operator polish** (`failed_sync_work`, `reconcile_sync`) easily slides into "dashboard" if helpers start emitting HTML or streaming JSON over HTTP rather than returning data structures.
- **Mix tasks for operator data** easily slide into a CLI product surface if they accumulate their own flags, colored output logic, and standalone documentation that no longer derives from the underlying Scrypath functions.

**Why it happens:**
- Each individual widening feels small and like a natural extension.
- Adopter feedback (real or imagined) can be used to justify widening even when the feedback is speculative.
- The line between "sensible API shape" and "implicit non-goal commitment" is not always clear at design time.

**How to avoid:**
- Before any v1.3 plan ships, grep the diff for mentions of `typesense`, `elasticsearch`, `opensearch`, `algolia`, `_vectors`, `embedding`, `hybrid`, `dashboard`, `router`. Any match requires explicit review against the non-goals list.
- Keep `search_many/2` parameter names backend-agnostic but never expose a `backend:` per-request override on the public surface. The internal seam handles backend selection; the public API never lets callers pick.
- Keep `Scrypath.search/3` signature unchanged. All facet/relevance work lands through opts extensions validated by the single options module.
- Keep Mix tasks as thin delegates (as ARCHITECTURE.md L113-119 already documents). If a Mix task grows its own arg parser beyond `OptionParser` basics, that's a signal the CLI is becoming a product surface.
- For "recovery guide" work: it must be docs-only (markdown in `guides/`), not a new API verb. "End-to-end drift recovery guide" should describe sequencing of existing `sync_status`, `failed_sync_work`, `reconcile_sync`, `reindex` — not introduce `Scrypath.recover/2`.
- In every phase's closure review, include a "non-goals check" step: did this phase add any function, option, or struct field whose name implies a non-goal?

**Warning signs:**
- A plan proposes a type that parameterizes over `backend:` on the public surface.
- A phase adds a ranking rule type that has a `vector` or `embedding` keyword.
- A Mix task starts emitting ANSI color codes by default or gains a `--watch` mode.
- A guide titled "recovery" introduces a new top-level function rather than composing existing ones.

**Phase to address:**
**Every feature phase in v1.3.** Each phase's VERIFICATION.md or VALIDATION.md must include a non-goals check.

---

### Pitfall 10: Reindex downtime from changing `filterableAttributes` to support facets without the managed pipeline

**What goes wrong:**
Meilisearch requires fields to appear in `filterableAttributes` before they can be used in facet filters or facet distribution. Adding faceting to an existing schema means extending `filterableAttributes` and `faceting` settings. Applying that change via a direct `Scrypath.Meilisearch.Settings.apply/3` call to a live index triggers a full rebuild internally — during which filtering and facet queries degrade. The user sees "I added faceting, now my live search has gaps."

**Why it happens:**
- Unlike `searchableAttributes`, `filterableAttributes` feels like a metadata-only change, so the reindex impact is surprising.
- The schema DSL doesn't currently distinguish "filterable for common-path filter" from "filterable for facet", so a user adding faceting might only update one and Meilisearch will silently reject facet queries.
- The `settings.ex` module directly calls `client.update_settings/3` with no workflow awareness (lib/scrypath/meilisearch/settings.ex L15-27).

**How to avoid:**
- Require faceting to be declared at schema level (`faceting: [:category, :price_bucket]`) and automatically append those fields to `filterableAttributes` during settings resolution. One declarative list → two derived Meilisearch settings. Users cannot drift.
- Document that adding or removing facet fields is a reindex-class change. Direct users to `mix scrypath.reindex` in the relevance-tuning guide.
- Add a Mix task option or guide section: "Check whether your pending settings change requires a reindex." A small helper function that diffs `Scrypath.schema_settings/1` against the live Meilisearch index settings (read-only) can do this without mutating anything.
- Do not expose a public "apply live settings and skip the reindex" verb. See Pitfall 5.

**Warning signs:**
- A faceting guide recommends calling `Scrypath.Meilisearch.Settings.apply/3` directly.
- Users file issues that say "I added faceting but my facet filter errors say the field is not filterable."
- `Scrypath.schema_settings/1` gains two separate lists for common-path filters and facets that can drift.

**Phase to address:**
**The faceted search phase.** The plan that lands the `faceting` schema declaration must also update the settings resolver to derive `filterableAttributes` correctly.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Pass Meilisearch filter strings through on the public search API | Faster to ship facet filters | Locks users into Meilisearch syntax; poisons the internal seam; breaks if Meilisearch changes syntax | Never — use `Scrypath.Meilisearch.*` escape hatch instead |
| Add new `FailedWork` fields as `@enforce_keys` for compile-time safety | Catches missing fields in library code | Breaks every external `%FailedWork{...}` literal and hardens Dialyzer spec beyond what's publicly promised | Never in v1.3 — the struct is now publicly typed on Hex 0.3.0 |
| Copy `Scrypath.search/3` into `Scrypath.search_many/2` by extending shared opts | Less duplicated code up front | Federates validation across schemas, couples them in the public contract | Never — federation must hold per-schema validation |
| "Hot-apply" relevance settings to the live index to skip reindex wait | Operators get instant feedback on synonym tweaks | Settings that trigger internal rebuild on Meilisearch cause silent search degradation; precedent undermines the `reindex/2` invariant | Only under `Scrypath.Meilisearch.*` escape hatch, with loud docs |
| Close v1.2 VALIDATION gaps with prose-only "verified" statements | Fast milestone closure | Pollutes audit history; future auditors cannot distinguish real evidence from placeholder | Never — evidence must be a runnable test or captured command output |
| Ship v1.3 Hex release without asserting on-disk ≡ tagged-tarball ≡ published tarball | Less CI friction | Risks repeating v1.2 divergence exactly | Never — this is the invariant that must be mechanized in v1.3 |
| Expose Meilisearch's `facetDistribution` shape on `SearchResult` unchanged | Less translation code | Field names leak; Meilisearch upstream renames break the public contract | Only inside the `:raw` escape hatch field, never as a named top-level key |
| Add a `mix scrypath.apply_settings` task for live settings mutation | Nice operator ergonomics for synonym changes | Operator CLI implies the live-settings path is blessed; teaches the wrong mental model | Never on the common path; acceptable under `Scrypath.Meilisearch.*` namespace as an escape-hatch Mix task |
| Extend Mix tasks with rich colored output and `--format` flags | Nicer operator UX | Mix tasks become their own product surface, violating the "thin delegate" contract | Only when output is explicitly a pretty-printer over data that remains available on `Scrypath.*` |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Meilisearch settings API | `update_settings` has partial-upsert semantics; unset fields retain old values | Always resolve the full intended settings map from schema + opts before applying, per-field `null` to clear |
| Meilisearch filterable attributes | Expecting `facetDistribution` to work on a field not in `filterableAttributes` | Derive `filterableAttributes` from `faceting:` declaration; fail loudly at schema compile time if a facet field is missing |
| Meilisearch ranking rules | Ranking-rule order matters semantically; replacing the list silently changes search quality | Make ranking rules schema-declared and reindex-gated; warn in docs that changing order requires a rebuild |
| Meilisearch multi-search endpoint | Sharing one filter/sort across multiple sub-queries | Per-request filter/sort validated per-schema on the Elixir side before hitting the client |
| Hex.pm package publish | Tag checked out clean by CI ≠ files on developer's disk | Mechanize `git status`-clean gate + release-parity symbol check before publish completes |
| HexDocs | `mix docs --warnings-as-errors` only catches reference errors, not missing behavior coverage | Add doctests for every new public function in v1.3 so doc examples are executable |
| Oban job failure introspection | Relying on Oban internal state shapes (keys like `:state`, `:errors`) | Keep the existing `Scrypath.Oban.Inspect` seam; do not reach into Oban internals directly from feature code |
| release-please manifest ↔ `mix.exs` ↔ CHANGELOG | Three files drifting independently | `mix verify.phase11` already checks; do not regress it by skipping the gate when adding a new release-pipeline step |
| GitHub Actions Node 20 deprecation | Upgrading transitively-pinned actions can break action input contracts | Upgrade one action at a time; each upgrade PR runs the full CI matrix and the release dry-run before merging |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Facet distribution on every search by default | Meilisearch allocates extra compute per query; p95 latency jumps | Make faceting opt-in per request via explicit `facets: [:category]` opt; never implicit | Growth-stage SaaS (>100 rps sustained) — exactly Persona 2 |
| `search_many` fan-out to N schemas without pagination caps | Linear growth in backend work per federated query | Enforce a default `page size` per sub-request and a max schema count (e.g., 10) | Any schema set >5 with unbounded page sizes |
| Retry of failed Oban sync work without jitter | Thundering herd against Meilisearch when many jobs become retryable at once | Use existing Oban backoff; document that `retry_sync_work/2` should not be called in a tight loop | Incident recovery, bulk reindex failures |
| Reindex on the live index during peak traffic | `searchableAttributes`-class settings change causes Meilisearch internal rebuild; queries degrade | Document off-peak reindex; use `cutover?: false` to verify target index before swap (lib/scrypath/reindex.ex L48-63 already supports this) | Any production system during business hours |
| Hydration preload lists that fan out to many-to-many associations | N+1 or worse on preload expansion | Keep preloads explicit per-request; never set global defaults | Any repo with association depth >2 |
| `failed_sync_work/2` pulling full Meilisearch task history | Meilisearch task list grows unbounded; paging gets slow | Paginate or time-window the task list query; document default window | Long-running Meilisearch instances with heavy write volume |
| Multi-search pretending to be search-then-join | Callers expect consistent pagination across schemas | Return per-schema paginated results; document that "combined pagination" is out of scope | Any attempt to render a unified paged result list in the UI |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Accepting raw Meilisearch filter strings on public search API | Filter injection; users can craft filters that bypass tenant isolation | Only accept validated keyword-list filters on the common path; raw strings only under the escape hatch with loud docs |
| `search_many` that bypasses per-schema authorization | Caller authorized on Schema A leaks data from Schema B | Authorization is the caller's job per schema; document that `search_many` does not unify tenancy and recommend explicit per-schema auth checks |
| Exposing raw Meilisearch task payloads in `FailedWork.metadata` | Leaks index internals (index UIDs, task UIDs) to consumers who log them | Keep `metadata:` as a documented narrow map; name every field explicitly |
| `retry_sync_work/2` replaying stale payloads against a schema whose fields changed | Reintroduces deleted/redacted fields into the index | Document that retry replays the payload captured at enqueue; if schema changed, operator must reindex, not retry |
| Logging facet filter values at DEBUG | PII (e.g., user IDs used as facet values) leaked into logs | Telemetry events should carry field names, not field values, by default |
| Hex API key exposed to the always-on CI workflow | Credential exfiltration via PR from a fork | `HEX_API_KEY` must remain scoped to the publish workflow only (docs/releasing.md L36-37 — do not regress this) |
| Installing unreviewed GitHub Actions during the Node 20 upgrade | Supply-chain risk from upgrading to a tagged version that points to a compromised ref | Pin each upgraded action to a commit SHA, not a floating tag; review the upstream changelog |
| Dialyzer spec weakening to accept any map for `FailedWork.metadata` | Loss of contract clarity masking data leakage | Keep the typespec as narrow as data permits; widening should be a deliberate decision with CHANGELOG entry |

## UX Pitfalls

Common user experience mistakes in this domain (developer experience, since Scrypath is a library).

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Facet results returned as a flat list of strings without counts | Caller can't render "Category (5)" style facet UIs — defeats the purpose | Return `%{field => %{value => count}}` or a sub-struct with counts; match Meilisearch's native shape semantically, not syntactically |
| Relevance tuning documented via raw Meilisearch JSON examples | Users learn Meilisearch-specific vocabulary instead of Scrypath-native patterns; hard to migrate backend later | Document in Elixir keyword/map syntax with a reference link to Meilisearch semantics |
| `search_many` result that pre-interleaves hits from all schemas | Consumer can't tell which hit came from which schema; hydration breaks | Return a list of per-schema `SearchResult` entries, not an interleaved stream |
| Adding a `FailedWork.retry/1` convenience alongside `Scrypath.retry_sync_work/2` | Two ways to do the same thing; docs drift; operators pick the wrong one | One canonical verb on `Scrypath.*`; FailedWork stays a data struct |
| Extending Mix tasks with custom flags not mirrored on the function | CLI becomes its own product surface; library users can't reproduce CLI behavior | Every Mix task flag must correspond to a keyword opt on the underlying function |
| CHANGELOG entries that only list module names | Users don't know if a feature is new, breaking, or deprecated | Follow release-please conventional commits: `feat:`, `fix:`, `BREAKING CHANGE:` for clarity |
| Reindex guide that buries the `cutover?: false` flag | Operators who need to verify a rebuild don't know they can | Lead with `cutover?: false` in the drift-recovery guide; explain the ordering guarantee |
| Facet filter errors surfaced as raw Meilisearch 400 responses | Elixir-idiomatic error messages replaced by HTTP-ish strings | Translate backend filter errors through the same `ArgumentError` path the common-path parser uses |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Faceted search:** Facet fields declared in schema actually appear in `filterableAttributes` derived settings — verify via a test that reads the resolved settings map
- [ ] **Faceted search:** `SearchResult.facets` is `nil` when caller did not request facets — verify via a test on the default code path
- [ ] **Faceted search:** Filter parser accepts the same shape for `filter:` whether the field is faceting or not — verify via property test
- [ ] **Relevance tuning:** `Scrypath.reindex/2` still follows `create → settings → backfill → cutover` in that exact order — verify via test that asserts call ordering on a mocked backend
- [ ] **Relevance tuning:** Schema settings changes that require rebuild are documented as such with specific examples — verify via guide review
- [ ] **Relevance tuning:** No new public verb applies settings to a live index — verify via `mix xref graph` or a doctest ensuring only `reindex/2` exposes settings mutation
- [ ] **Multi-index search:** Every sub-request's opts are independently validated — verify via per-schema property test
- [ ] **Multi-index search:** Results preserve per-schema `SearchResult` shape, not flattened — verify via type spec and integration test
- [ ] **Multi-index search:** Hydration runs per-schema — verify via test with two schemas and two repos
- [ ] **`FailedWork` evolution:** New fields are NOT in `@enforce_keys` — verify via a struct-shape regression test
- [ ] **`FailedWork` evolution:** CHANGELOG entry marks new fields as additive, not breaking — verify during release PR review
- [ ] **VALIDATION.md closures:** Each closure names a runnable test + captures `mix verify.phase*` output — verify via reviewer checklist
- [ ] **CI / Node 20 debt retirement:** Every upgraded action is pinned to a commit SHA — verify via diff review
- [ ] **CI / Node 20 debt retirement:** The release workflow still runs `mix verify.phase11` and `mix verify.release_publish` after Node upgrade — verify via workflow log
- [ ] **Hex release parity:** `git status` clean + symbol presence check runs as part of the publish workflow — verify via workflow log captured in release PR
- [ ] **Hex release parity:** Phase SUMMARY files list expected shipped files and the parity check reads from them — verify via a canary test that fails when a SUMMARY-listed file is missing from `mix hex.build --unpack`

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| On-disk ↔ Hex divergence recurs | MEDIUM | Cut an immediate patch release via Release Please that brings Hex back in sync with `main`; do NOT retag the existing version (docs/releasing.md L99-109 already covers this — do not invent a second path) |
| `SearchResult` struct broke with a mandatory new key | HIGH | Issue a patch release that demotes the field to optional; add a compatibility test; document the regression in CHANGELOG as a `fix:` entry; notify downstream via Hex announcement |
| `FailedWork` struct broke external consumers | HIGH | Same as above; additionally provide a `legacy_shape/1` helper for one minor release to ease upgrade |
| Facet filter parser diverged from core filter parser | MEDIUM | Consolidate into the single parser in a patch release; deprecate the duplicate entrypoint with a runtime warning for one minor release |
| Relevance settings applied to live index caused search downtime | LOW (one-time operator recovery) | Run `Scrypath.reindex/2` with `cutover?: false`, verify target index, then re-run with cutover; update docs to forbid the offending path |
| `search_many` leaked shared filters across schemas | MEDIUM | Deprecate the shared-opts signature; introduce per-request tuple signature in a minor release; log a warning for one release on the old signature |
| Meilisearch-native field name leaked on public struct | MEDIUM | Add the Scrypath-owned field alongside the leaked one; deprecate the leaked name with `@deprecated` for one minor release; remove in next major |
| VALIDATION.md was pencil-whipped and audit flags it | LOW (rewriting only) | Reopen the phase; attach real evidence; update the milestone audit record |
| Non-goal creep (e.g., second backend type parameter landed) | HIGH | Revert the non-goal API in a minor release as deprecation; remove in the next major — treat as a product-level regression |
| CI Node 20 upgrade broke a publish workflow step | LOW | Revert the specific action upgrade; the release workflow is untouched; continue upgrades one at a time |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| P1: Workspace ↔ Hex divergence | Phase 0 (release-parity gate) before any feature phase, OR first feature phase | `mix verify.workspace_clean` runs in PR CI and in `publish-hex.yml`; post-publish `mix verify.release_publish X.Y.Z --expect-symbols ...` passes in workflow log |
| P2: `SearchResult` shape break | Faceted search phase | Compile-time struct-shape compatibility test pinning 0.3.0 keys; CHANGELOG reviewed for "BREAKING" markers |
| P3: `FailedWork` shape break | Operator-polish phase | Struct-shape regression test; new fields defaulted to `nil`/`:unknown` with explicit docstrings |
| P4: Facet filter parser split | Faceted search phase | Property test: every 0.3.0-accepted filter is still accepted; every rejected filter is still rejected; Meilisearch filter strings rejected on public path |
| P5: Live settings mutation | Relevance tuning phase | No public function outside `Scrypath.Meilisearch.*` mutates settings; ordering test on `reindex/2` confirms `create → settings → backfill → cutover` |
| P6: `search_many` per-schema validation bypass | Multi-index search phase | Per-request validation test with two schemas having different `filterable` sets; hydration runs per repo |
| P7: Backend-native shape leakage | Faceted + multi-index phases | Dialyzer spec review; no string-keyed camelCase fields on public structs; `:raw` remains the explicit escape hatch |
| P8: VALIDATION.md pencil-whipping | Release/tooling-debt retirement phase | Each VALIDATION.md links to a test file + line range; `mix verify.phase13` / `mix verify.phase14` output captured in the doc; split PR reviewed independently |
| P9: Non-goal creep | Every feature phase | Per-phase non-goals check during VERIFICATION/VALIDATION; grep for forbidden tokens in diffs |
| P10: Facet `filterableAttributes` drift | Faceted search phase | Settings-resolution test: declaring a facet field appends it to `filterableAttributes`; integration test verifies facet queries succeed without separate declaration |

## Sources

- `/Users/jon/projects/scrypath/.planning/PROJECT.md` — non-goals list and milestone v1.3 goal (HIGH confidence, authoritative project contract)
- `/Users/jon/projects/scrypath/.planning/milestones/v1.2-MILESTONE-AUDIT.md` — v1.2 divergence narrative and Nyquist gap list (HIGH confidence, authoritative audit)
- `/Users/jon/projects/scrypath/ARCHITECTURE.md` — operational contract, sync modes, reindex ordering invariant, public-surface boundaries (HIGH confidence)
- `/Users/jon/projects/scrypath/docs/releasing.md` — release recovery runbooks and credential scoping (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/search.ex` — current search contract (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/search_result.ex` — `SearchResult.t()` struct shape and `@enforce_keys` (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/query.ex` — normalized internal query struct (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/options.ex` — filter/sort/page validator — the single parser that facet filtering must extend (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/reindex.ex` — managed reindex workflow ordering (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/settings.ex` — current settings application path; shows why live-index mutation is a trap (HIGH confidence)
- `/Users/jon/projects/scrypath/lib/scrypath/operator/failed_work.ex` — current `FailedWork.t()` struct shape and `@enforce_keys` (HIGH confidence)
- `/Users/jon/projects/scrypath/.github/workflows/ci.yml` — existing verification gates (`verify.phase11`, `verify.phase13`, `verify.phase14`) (HIGH confidence)
- Meilisearch documentation on settings partial-update semantics, `filterableAttributes`, faceting, and multi-search (MEDIUM confidence — verified against current Meilisearch v1.15 behavior referenced in ci.yml L103; specific field-rename trajectories noted from training data)
- `.planning/ROADMAP.md` v1.2 phase decomposition — used to map pitfalls back to existing phase patterns for v1.3 (HIGH confidence)

---
*Pitfalls research for: published Elixir search library adding Meilisearch-native search depth while preserving shipped public contract*
*Researched: 2026-04-17*
