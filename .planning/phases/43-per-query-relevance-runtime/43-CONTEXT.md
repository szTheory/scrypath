# Phase 43: Per-query relevance runtime - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **`TUNE-PQ-01`…`TUNE-PQ-03`**: application-level **Plane B** per-query overrides for **`Scrypath.search/3`**, **`search_within_facet/4`**, and **`search_many/2`**, implemented **only** against the locked **`guides/per-query-tuning-pipeline.md`** (precedence, allowlists, errors, telemetry, federation pointers). Includes **tests**, a **thin `mix verify.phase43`** slice, and **`docs_contract_test.exs`** anchors so published docs cannot drift silently.

**Process note:** User selected **all** discuss gray areas and requested **parallel research subagents** plus a **single synthesized recommendation set** coherent with Scrypath vision, Phase 42 decisions, and Elixir ecosystem norms.

</domain>

<decisions>
## Implementation Decisions

### 1) Public keyword shape for Plane B tuning (v1.9 slice)

- **D-01 (Nested bag — primary):** Expose the first runtime slice under **one top-level keyword** **`:per_query`** whose value is a **map** of **strictly allowlisted** atom keys (normalized the same way as existing search options per Phase 19 / Phase 42 **D-15**). Call sites keep **Plane B visually scoped** and avoid a growing flat keyword soup that collides with transport, repo, federation, or future library keys.
- **D-02 (Why not flat-only or hybrid):** **Reject** a large flat expansion of Meilisearch pass-throughs on `search/3` for this slice and **reject** a **hybrid** (flat “common” + nested “advanced”) for v1.9 — both increase **namespace collision** and **dual mental models**; hybrid needs a precedence matrix that violates least surprise.
- **D-03 (Ecosystem pattern):** Search stacks that optimize DX with **unbounded flat hashes** (permissive Rails-style) trade away **typo safety** and **semver clarity**; Algolia’s newer **typed / nested request** shapes and Laravel’s **builder vs raw** split teach that **one bounded bag** plus validation is the right default for an **Ecto-grade** library. Scrypath already invests in **NimbleOptions** and **`{:invalid_options, _}`** — the nested bag extends that story instead of mimicking loose clients.
- **D-04 (Optional sugar):** If ergonomics demand, add a **small builder or `put_per_query/3` helper** in a secondary module **later** — do **not** introduce a second supported shape on `search/3` itself in Phase 43.
- **D-05 (Phoenix edge):** Document the pattern: controllers take **`Map.take/2`** / changesets at the boundary; only **allowlisted** keys enter **`:per_query`** so raw params never flow unvalidated into Plane B.

### 2) `search_many/2`: shared vs per-entry for `:per_query`

- **D-10 (Allow on both):** **`:per_query` is allowed in `shared_opts` and in each entry’s keyword list**, consistent with Meilisearch’s “each query object is independent” mental model while preserving Scrypath’s existing **shared + entry** ergonomics.
- **D-11 (Merge semantics — explicit, footgun-aware):** After the usual **top-level** keyword merge where **entry wins on duplicate top-level keys**, if both sides contribute **`:per_query`**, the effective map is **`Map.merge(shared_per_query, entry_per_query)`** (elixir **right-biased on inner keys**). This is an **intentional, documented exception** to “replace the entire nested value wholesale” so a federated entry can override **one** knob without silently dropping shared defaults for other keys inside the bag.
- **D-12 (Federation rails unchanged):** Federation-only keys remain **shared-only** as today; **`:per_query` is not** a federation rail key — do not use the rail exception list as precedent to hide Plane B knobs.
- **D-13 (Future `:deep`):** If a future phase introduces **`:deep`** merge for nested bags, it must be **opt-in**, semver-documented, and tested — Phase 43 stays **shallow inner merge** only for **`:per_query`**.

### 3) `show_ranking_score_details` (and expensive debug knobs)

- **D-20 (No `Mix.env` in core):** Do **not** gate library behavior on **`Mix.env/0`** inside `scrypath` — compiled Hex deps do not reliably reflect the host app’s runtime environment; that pattern is a **footgun** for adopters.
- **D-21 (Ship + discipline):** **Include** `show_ranking_score_details` in the **`:per_query` allowlist** as the spec’s exemplar for **debug / tuning** — rejecting it entirely in v1.9 would push operators to **bypass** Scrypath for forensics (**worse** operational honesty).
- **D-22 (Operational hygiene):** Pair the keyword with **(a)** guide + `@doc` language that **discourages production hot paths**, **(b)** **telemetry span metadata** when enabled (documented key, **low-cardinality**, suitable for SRE sampling / dashboards), and **(c)** clear **cost / payload shape** callouts in **`guides/per-query-tuning-pipeline.md`** (already framed; keep aligned).
- **D-23 (Optional escape hatch — later):** If real-world abuse appears, a **follow-up** can add an explicit **`Application.get_env`** “strict” switch that rejects the key unless enabled — **out of scope** for Phase 43 unless implementation discovers a concrete need.

### 4) Verification / CI (`mix verify`)

- **D-30:** Add a **dedicated thin composer** **`mix verify.phase43`** mirroring **`verify.phase36`…`verify.phase41`** — **do not** bolt TUNE-PQ coverage onto **`verify.phase41`** (different roadmap concern; hurts **failure locality** and couples unrelated gates).
- **D-31:** Extend **`test/scrypath/docs_contract_test.exs`** with anchors for **`verify.phase43`** (same hygiene as **`@verify_phase41`** / task string pins) so renames or accidental scope creep fail CI.
- **D-32 (Coupling only when real):** If a regression requires federation + per-query interaction, **compose** from **`verify.phase43`** by invoking the **minimal** additional test slice (pattern like **`verify.phase37`** calling **`verify.phase36`**), not by merging unrelated requirements into one task file.

### Cross-cutting (research synthesis)

- **D-40:** These choices are **mutually coherent**: one **`:per_query`** map, validated and logged as a unit; **search_many** inner merge rules prevent silent loss of shared tuning; **verify.phase43** gives **`TUNE-PQ-02`** a named home; telemetry + docs carry **operational honesty** without unsafe compile-time env hacks.
- **D-41:** Stay **Meilisearch-first**, **explicit `{:error, _}`**, **tagged tuples** for domain failures — unchanged from Phase 42 / project vision.

### Claude's Discretion

- Exact inner key names (`:ranking_score_threshold` vs `:rankingScoreThreshold` after normalization) as long as **wire projection** matches the spec’s Meilisearch field names.
- Whether telemetry for details is **span attribute** vs **attached execute event** — pick the pattern already dominant in **`lib/scrypath/search.ex`** for consistency.
- Minor Mix task file layout / alias naming inside **`lib/mix/tasks/`**.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Normative spec and requirements

- `guides/per-query-tuning-pipeline.md` — Plane A/B, precedence stack, pipeline stages, v1.9 exemplars, errors, telemetry catalog, `search_many` notes
- `.planning/REQUIREMENTS.md` — **TUNE-PQ-01** … **TUNE-PQ-03** acceptance text
- `.planning/ROADMAP.md` — Phase 43 goal and success criteria (table + milestone)

### Locked prior context

- `.planning/phases/42-per-query-tuning-pipeline-spec/42-CONTEXT.md` — canonical guide path, merge / validation posture, doc-contract philosophy
- `.planning/phases/19-relevance-tuning/19-CONTEXT.md` — Plane A settings, normalize-on-entry, `settings_merge` semantics
- `.planning/phases/41-federation-docs-contracts/41-CONTEXT.md` — verify slice + `docs_contract_test.exs` patterns
- `.planning/phases/21-multi-index-search/21-CONTEXT.md` — `search_many/2` baseline semantics

### Implementation anchors (code)

- `lib/scrypath/search.ex` — `search/3`, `search_many/2`, telemetry emit points
- `lib/scrypath/options.ex` — NimbleOptions schemas, validation mapping
- `lib/scrypath/multi_search/entries.ex` — shared vs entry merge
- `lib/scrypath/config.ex` — `Config.resolve!/1` cascade (do not conflate with Plane B map)
- `test/scrypath/docs_contract_test.exs` — contract-test patterns (`verify.phase41` pins)
- `lib/mix/tasks/verify.phase41.ex` — thin composer template for new `verify.phase43.ex`

### External

- Meilisearch Search / Multi-search API reference (version per README / spec minimum)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Scrypath.Options.validate_search_options/2`** — extend or layer validation so **`:per_query`** participates in the same normalize / allowlist / `__unrecognized__` story as Phase 19/42.
- **`Scrypath.MultiSearch.Entries`** — central place to implement **D-11** inner `Map.merge/2` for `:per_query` after top-level keyword merge.
- **`docs_contract_test.exs`** — copy the **`verify.phase41`** pinning pattern for **`verify.phase43`**.

### Established Patterns

- **Right-biased keywords** at the outer `search_many` layer; **shallow** defaults for nested structures unless `:deep` is explicitly opt-in (Phase 19/42).
- **Thin `mix verify.phaseNN`** tasks as milestone-scoped CI composers.

### Integration Points

- **Meilisearch adapter projection** — map normalized atoms → camelCase wire fields for ranking score knobs.
- **Telemetry** — `[:scrypath, :search]` / `[:scrypath, :search_many]` spans receive optional metadata when expensive debug knobs are used.

</code_context>

<specifics>
## Specific Ideas

- User requested **research-backed**, **one-shot** decisions with **no further user choices** — all gray areas resolved in this file for planners/executors.
- Ecosystem lessons emphasized: **avoid** silent unknown keys and **unbounded** flat passthrough; prefer **validated nested bag** + explicit merge semantics + **thin verify slice**.

</specifics>

<deferred>
## Deferred Ideas

- **Optional strict prod rejection** for `show_ranking_score_details` via explicit `Application` config — only if post-ship telemetry shows abuse; not required for Phase 43 closure.
- **Fluent / builder API** for `:per_query` — nice-to-have ergonomic layer, not v1.9 scope unless planning discovers unavoidable complexity in call sites.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 43-per-query-relevance-runtime*
*Context gathered: 2026-04-20*
