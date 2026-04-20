# Phase 41: Federation docs & contracts - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **FED-03**: **README**, **guides**, and **`test/scrypath/docs_contract_test.exs`** stay aligned with **v1.8 federation** behavior—**per-entry `federation_weight:`** (Phase 39 / **FED-01**) and **`:all` expansion** (Phase 40 / **FED-02**)—so adopters and future **OPSUI** work can rely on **stable wording**, **discoverable cross-links**, and a **green verify slice** in CI. No new search APIs or runtime semantics in this phase unless a doc-driven bug is unavoidable.

**Process note:** User requested **all** discuss gray areas with **parallel research subagents** and a **single synthesized recommendation set** (no further interactive passes). This file locks those recommendations as implementation decisions for planning and execution.

</domain>

<decisions>
## Implementation Decisions

### A) Verify slice and CI (`mix verify.phase41`)

- **D-01:** Add **`mix verify.phase41`** and **`lib/mix/tasks/verify.phase41.ex`**, matching the **phase-numbered verify** pattern already used through **`verify.phase38`**—**least surprise** for contributors and roadmap traceability.
- **D-02:** Implement the Mix task as a **thin composer** only: delegate to **`mix test`** (and any already-standard checks such as **`mix compile --warnings-as-errors`** if the repo’s other verify tasks do so). **Do not** embed novel verification logic inside the task body beyond orchestration and clear **`Mix.shell().info`** output.
- **D-03 (Two-tier CI model):** **Default PR path** runs **fast, in-repo static work**: doc contract tests that **`File.read!`** markdown and assert strings/patterns—**no Meilisearch daemon**. **Heavier or integration-tagged** work (if introduced later) stays on **`mix test --only`** / **exclude** tags or a **separate workflow** (nightly, label, or `workflow_dispatch`)—honest ops posture: do not pretend federation integration is “free” inside doc-only jobs.
- **D-04:** Register **`verify.phase41`** in **`mix.exs`** `aliases` next to existing phase verifies. Document the **two-tier** model in **CONTRIBUTING** (or the verify matrix doc the repo already uses) in **one short paragraph** plus a **one-line** pointer from any umbrella **`mix verify`** help text if present.

### B) `docs_contract_test.exs` strictness

- **D-05 (Baseline — hygiene first):** Keep and extend **forbidden-token / internal-ID hygiene** tests (no **`REQ-`**, **`.planning/`**, phase decision markers in **published** markdown paths already listed in the module). These are **high signal, low churn** for Hex/adopter trust.
- **D-06 (Avoid prose locks):** Do **not** add long lists of **exact paragraph** assertions or full **body copy** locks for guides—high brittleness, discourages editorial improvement. **Heading order locks** only where the repo already uses them sparingly (e.g. README section spine).
- **D-07 (Structural lite):** Prefer **minimal structural rules** where they prevent real regressions: e.g. **single H1** on README, **ordered top-level README sections** the project treats as API-stable, or **“must mention”** short phrases for **safety-critical** install/config paths (env vars, mix task names, **`:all` / `global_schemas:`** vocabulary once public names are frozen in Phase 40).
- **D-08 (Optional machine facts):** If a **golden list** is needed (documented env vars, mix tasks), extract to a **small normalized list** compared in test—not full Markdown snapshots. Pair doc contracts with **API/doctest layers** elsewhere when behavior must be proven; doc tests assert **leaks and discoverability**, not literary quality.
- **D-09:** Tag doc-heavy groups with **`@moduletag :docs`** (or project convention) so contributors can run **`mix test --only docs`** for bisect; **`verify.phase41`** should run the **same** tests the phase owns.

### C) Documentation placement (README vs guides vs golden path)

- **D-10 (Billboard README):** README stays **short**: positioning, install, tiny example, compatibility, **links**—**Hex/ExDoc** norm. Federation **depth** does not live in the README body beyond **one sentence + link** to the canonical guide section.
- **D-11 (Single concept source):** **`guides/multi-index-search.md`** is the **canonical narrative** for **multi-index tuple API**, **federation weights**, **merge trace / projection**, **`:all` / allowlist** semantics, and **error shapes**—aligned with Phases **21**, **39**, **40** CONTEXT. **Do not** duplicate full explanations in README or golden path; use **“Canonical:”** links when a short recap is unavoidable.
- **D-12 (Golden path):** **`guides/golden-path.md`** gets **pointers only** (multi-index + federation “read next”) unless a single sentence improves the happy path; avoid turning it into a second federation manual.
- **D-13 (OPSUI / future UI):** At most **one clearly labeled** subsection or callout (e.g. **“Directional / future operator UI”**) for merge-order **data** consumers—**no** mixed tutorial steps that read as shipped LiveView. Aspirational UI belongs in planning/roadmap, not procedural guide steps.
- **D-14 (ExDoc):** When adjusting **`mix.exs` extras**, keep **groups** coherent (**Start here / Concepts / How-to / Operations** if the project already trends that way); federation additions go under the **multi-index / search** concept group, not scattered extras.

### D) Score narrative vs federation (reconcile Phase 21 tension)

- **D-15 (Two-layer story):** Public docs use a **fixed metaphor**: **Layer 1** = independent retrieval + **per-index** ranking geometry; **Layer 2** = explicit **merge policy** (Meilisearch federation weights, Scrypath merge trace / projection). This matches Meilisearch/Elasticsearch “scores not portable across indices” truth without contradicting weights.
- **D-16 (Invariant callout):** At **first substantive mention** of **`federation_weight:`** in the guide, include a **short bold invariant**: per-index scores **stay local**; weights are **merge knobs**, not normalization into a single global relevance metric.
- **D-17 (Canonical paragraph — `@doc`):** Add (or align) a **compact canonical paragraph** on **`search_many/2` `@doc`** stating: merged stream ordering; scores comparable **within** one index only; cross-index weights adjust **merge ordering** under engine policy—not a claim of score commensurability. **One line** in README pointing to **`guides/multi-index-search.md`**; the guide holds the expanded narrative and examples.
- **D-18 (Naming discipline):** Prefer **“merged ordering under federation settings”** over **“best match globally”** in examples and headings; mirror Elixir developers’ expectation of **explicit boundaries** (like **changeset** / **Multi** step visibility).

### Cross-cutting (vision alignment)

- **D-19:** **Operational honesty**, **Meilisearch-native** vocabulary, **Ecto-first** discoverability, **DX** (fast PR loop, obvious verify command, docs that teach the model once), **least surprise** (verify and doc patterns match prior phases **36–40**).

### Claude's Discretion

- Exact **`mix verify.phase41`** composition if the repo later standardizes a shared **`Mix.Task.Verify`** helper—behavior must stay **orchestration-only**.
- Minor wording edits inside the canonical paragraph as long as **D-15–D-18** invariants are preserved.
- Whether to add **optional** `lychee` / link-check job is **out of scope** unless already in repo patterns—do not block Phase 41 on it.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 41 goal, success criteria, **FED-03**, v1.8 table
- `.planning/REQUIREMENTS.md` — **FED-03** acceptance text; traceability table (note: reconcile **FED-02** row with shipped Phase 40 if still stale when editing)

### Locked prior implementation context

- `.planning/phases/21-multi-index-search/21-CONTEXT.md` — tuple API, **`ordered`**, federation metadata, partial failures
- `.planning/phases/39-federation-scoring-weights/39-CONTEXT.md` — **`federation_weight:`**, merge trace, sequential-backend error, **D-16/D-17** doc coordination
- `.planning/phases/40-all-expansion/40-CONTEXT.md` — **`{:all, …}`**, **`global_schemas:`**, **`{:all_expansion, _}`**, explicit **Phase 41** README/verify ownership

### Project principles

- `.planning/PROJECT.md` — v1.8 federation goals, Meilisearch-first, operational honesty

### Code and docs to touch

- `test/scrypath/docs_contract_test.exs` — contract suite (hygiene + targeted strings)
- `guides/multi-index-search.md` — canonical federation + multi-index narrative
- `README.md` — billboard + pointers
- `guides/golden-path.md` — minimal pointers
- `mix.exs` — **`verify.phase41`** alias, ExDoc extras if needed
- `lib/scrypath/search.ex` — **`search_many/2`** `@doc` canonical paragraph (**D-17**)
- `.github/workflows/ci.yml` — ensure **phase41** / doc job wiring matches **D-03**

### External (writer reference, not copied into user docs)

- [Meilisearch multi-search / federation](https://www.meilisearch.com/docs/reference/api/multi_search) — merge + weight semantics
- Elasticsearch / community patterns on **cross-index score comparability** and **rank fusion** — informs **D-15** wording only

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`test/scrypath/docs_contract_test.exs`**: Established patterns—**`@readme` / `@guides`**, **`assert_contains_all`**, **`ordered?/2`**, published-path hygiene regex suite; extend with **federation / `:all`** anchors consistent with **D-05–D-09**.
- **`lib/mix/tasks/verify.phase36.ex`** (and **37**, **38**): Templates for **thin** phase verify tasks to mirror for **`verify.phase41`**.
- **`mix.exs`**: Existing **`verify.phase36`..`verify.phase38`** aliases—add **`verify.phase41`** alongside them.

### Established Patterns

- **Phase-numbered verify** is the repo’s **contract with contributors** for large doc+behavior slices.
- **Doc contracts** focus on **adopter-facing** artifacts under **`@published_markdown_for_hygiene`** and selected **`File.read!`** task sources—not full snapshot prose.

### Integration Points

- **CI**: Default PR workflow should invoke **`mix verify.phase41`** (or equivalent **`mix test`** subset) in the same **tier** as other phase verifies.
- **ExDoc**: `mix.exs` **`:docs`** extras list must stay consistent with **`@guide_paths`** in **`docs_contract_test.exs`** when adding or renaming guides.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (2026-04-20) emphasized: **Searchkick / multi-search** footgun is sorting a merged list by **raw `_score` across indices**—Scrypath docs must always tie **order** to **documented merge policy** and scope **scores** to **per-index** namespaces (**D-15–D-18**).
- Successful OSS pattern: **Oban-style** split of **usage vs operations**; **Req-style** small examples at the door, depth in reference/guides (**D-10–D-14**).
- User asked for **one-shot** coherent recommendations—**no open “pick one of three”** items remain for planner beyond **Claude's Discretion** above.

</specifics>

<deferred>
## Deferred Ideas

- **Optional link checker** (`lychee`, `markdown-link-check`) in CI—only if the project adopts it broadly; not required to close **FED-03**.
- **REQUIREMENTS.md** checklist row for **FED-02** still showing pending—**doc/traceability hygiene**; fix when touching requirements for **FED-03** closure (not a new capability).

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 41-federation-docs-contracts*
*Context gathered: 2026-04-20*
