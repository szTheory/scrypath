# Phase 58: Core library and doc QoL (B1) - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **LIB-01**, **LIB-02**, and **LIB-03** against the frozen B1 ledger (`.planning/EVID-01-b1-v1.14.md`). Each merged change cites **`EVID-57-*`** and maps to the named **LIB-*** row. No B2 playbook UI, no speculative public API churn, no Tier C CI expansion.

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting architecture (research synthesis)

- **D-01 (Error vs success contract):** **EVID-57-01** is primarily “**`{:ok, _}` but not searchable yet**,” not opaque `{:error, _}`. Fix **first** on the **success path**: make sync results and `@doc` for `Scrypath.sync_record/3`, `sync_records/3`, and related entrypoints state clearly what “accepted / enqueued / task” means vs “queryable now,” per mode. **Second**, enrich **`{:error, reason}`** for wait/transport/validation failures with the same mental model (especially task-wait paths). Do **not** rely on prettier errors alone.

- **D-02 (Shape of reasons):** Keep **`{:ok, _} | {:error, reason}`** as the library spine. Prefer **tagged tuples** (`{:error, {:tag, payload}}`) for branching; avoid **top-level map-only** `{:error, %{...}}` as the sole shape. Optional **small map tails** inside tuples are fine for metadata (task ids, HTTP hints). **Bang** helpers remain a thin **raise** layer over the **same** normalized `reason`, matching `Scrypath.Search.Error` today.

- **D-03 (Single formatter):** Introduce or extend **one internal module** (name at planner discretion, e.g. `Scrypath.Errors` / `Scrypath.DX`) implementing **`format_reason/1`** (or equivalent) so Mix tasks, exceptions, and optional logging paths share copy—no divergent prose.

- **D-04 (Doc hop):** One **stable** next-doc target for the visibility pitfall: **`guides/sync-modes-and-visibility.md`** and **`guides/common-mistakes.md`** (first pitfall), aligned with README contract language. Repeat the **same path string** in sync `@doc`, any new sync-oriented exception message, and LIB-03 anchors—**identifiers and paths**, not fragile full paragraphs.

- **D-05 (Idiomatic Elixir):** **`ArgumentError`** at invalid-option boundaries; **`defexception`** where apps should `rescue` a Scrypath class; **default `Logger` in the library** avoided—prefer **telemetry** (already present on sync) for operators; user-facing narrative in **`Exception.message/1`** and **`{:error, _}`** formatting.

- **D-06 (Other ecosystems):** Searchkick / Scout / meilisearch-rails teach **queue + worker** mental models and “saved ≠ indexed”; Algolia stresses speed but still has **task/status** stories. **Lesson:** combine **explicit status in success**, **short operator doc hops**, and **telemetry metadata**—not only string tweaks.

- **D-07 (Semver):** Phase 58 stays **patch-oriented**: additive tuple tags, additive map keys on success payloads where documented as extensible, doc and typespec clarity. **No** renaming/removing existing tuple heads without a major.

### LIB-02 — Non-macro clarity

- **D-08:** **No new public macros.** Prefer **`@moduledoc` / `@typedoc` / `@spec`** and **private** small pure helpers (e.g. normalization already in `Scrypath.Query`).

- **D-09:** **`Scrypath.Query`** (and similar pipeline types): honest **“internal normalized … not a semver-stable pattern-match target”** moduledoc; rich **`@typedoc`** on **`t`** and nested types (**`page_t`**, etc.). **Defer `@opaque`** until a real accessor boundary exists—adapters often need legitimate struct visibility.

- **D-10 (NimbleOptions):** Treat NimbleOptions as **schema**, not primary UX: improve nested `:doc` where helpful; map **`NimbleOptions.ValidationError`** into **LIB-01’s tagged reasons**—never ask callers to branch on **raw validation strings**.

- **D-11:** **`Scrypath` `@moduledoc`**: maintain or add a **grouped map of entry points** (sync, search, multi-search, operator hooks) linking to canonical guides—compensates for avoiding macro DSL discoverability.

- **D-12 (Evidence note):** After implementation, append a **short before/after** note to **EVID-57-02**’s row or triage section per ledger rules (append-only / errata), describing which surface was clarified—**no API shape change** unless evidence explicitly demands it in a future row.

### LIB-03 — Doc-contract / verify matrix

- **D-13 (Anchor style):** **Spine tokens** only—**mix task names**, **file paths**, **env keys**, **function arities**, and **at most one canonical invariant sentence** per concern (e.g. visibility vs acceptance). **Do not** lock every revised sentence of improved error copy unless introducing a **stable prefix/code** worth freezing.

- **D-14 (ExDoc extras vs contract):** Reconcile **`mix.exs` `extras:`** with **`test/scrypath/docs_contract_test.exs`** published sets: today **`guides/overview.md`** ships as an extra but is **outside** `@guide_paths` / `@published_markdown_for_hygiene`—either **add it** to the contract lists (and hygiene scan) **or** document an explicit **exclusion** with rationale in the test module. Extend the same rule for **`guides/meilisearch-operations.md`** if it remains a published extra (already in both today—ensure contract coverage matches intent).

- **D-15 (Triad for discoverability):** When LIB-01 adds a contributor-facing hop (task name, path, or flag), assert **README + CONTRIBUTING + `lib/mix/tasks/verify.opsui.ex`** stay aligned (ordering where procedural truth matters), mirroring the Phase 53 spine pattern.

- **D-16 (B2 boundary):** **No** bulk locking of Phase 59+ **playbook LiveView** copy in **`docs_contract_test.exs`** during Phase 58. UI strings drift in **`scrypath_ops`** tests later (**OPS-PB-05**). Optional **one** stable maintainer token in core docs is acceptable; paragraphs of UI copy are not.

- **D-17 (verify task lists):** If LIB-03 adds new contract slices or new **`mix verify.*`** mentions, update the relevant **`verify.phaseNN`** task moduledocs/lists that already pin **`docs_contract_test.exs`** so the **verify matrix** story stays one graph.

### PR packaging and governance

- **D-18:** **Three PRs by default**—**LIB-01**, **LIB-02**, **LIB-03**—each body contains **`Evidence: EVID-57-NN`** **and** **`Implements: LIB-0x`**. **LIB-01** and **LIB-03** both cite **EVID-57-01** but **merge separately** for bisect and changelog clarity—shared evidence row does **not** imply combined PR.

- **D-19:** **Stacked PRs** only if LIB-03 truly depends on files/strings introduced in LIB-01; otherwise **independent branches from `main`**.

- **D-20:** **CHANGELOG**: one bullet per merged LIB PR (can prefix **`LIB-0x`**); **patch** release line unless a **documented public** contract changes in a minor-worthy way.

- **D-21 (CI):** Per Phase 57 **D-12**, keep **regex body gate optional** for Phase 58; if pain appears, prefer grep for **`Evidence: EVID-57-`** on **`lib/scrypath/**`** + **`test/scrypath/**`** PRs per **D-17** in Phase 57 context.

### Claude's Discretion

- Exact module name for **D-03** formatter and whether to introduce **`Scrypath.Sync.Error`** vs extending existing exceptions—planner chooses smallest diff that satisfies **D-01–D-04**.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and evidence

- `.planning/EVID-01-b1-v1.14.md` — Frozen **`EVID-57-*`** rows and **LIB-01..03** mapping.
- `.planning/REQUIREMENTS.md` — **LIB-01..03** normative text.
- `.planning/ROADMAP.md` — Phase **58** success criteria.
- `.planning/phases/57-evidence-triage-and-b1-scope-lock/57-CONTEXT.md` — B1 gate, PR/evidence rules, path discipline.

### Product and ops narrative

- `.planning/PROJECT.md` — B1 vs B2, evidence-led QoL vision.
- `guides/common-mistakes.md` — First pitfall (visibility vs DB); authority links.
- `guides/sync-modes-and-visibility.md` — Sync semantics authority.
- `guides/golden-path.md` — Adoption router (if used as hop target).

### Code and contracts

- `lib/scrypath.ex` — Public entry `@moduledoc` / read-next pattern.
- `lib/scrypath/query.ex` — Internal query struct (LIB-02 target).
- `lib/scrypath/search/error.ex` — Bang / `Exception.message` pattern to mirror.
- `lib/scrypath/options.ex` — NimbleOptions validation surface.
- `test/scrypath/docs_contract_test.exs` — Doc-contract spine (LIB-03).
- `lib/mix/tasks/verify.opsui.ex` — Contributor verify triad.
- `mix.exs` — `:docs` **extras** list (must match contract hygiene scope per **D-14**).
- `.github/pull_request_template.md` — **Evidence:** token for B1 PRs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.Search.Error`** — Template for **`defexception`**, guide hints, and bang alignment with non-bang **`{:error, _}`**.
- **`test/scrypath/docs_contract_test.exs`** — `assert_contains_all`, ordering checks, hygiene regexes, `@guide_paths` / `@published_markdown_for_hygiene` split.
- **Sync pipeline / `decorate_result` patterns** (planner: locate current success envelope for tasks) — hook for **D-01** success-path clarity.

### Established patterns

- **Tagged errors + “do not match on message text”** — Keep machine shape in tuple heads; human strings are best-effort unless explicitly contract-tested.
- **Railway `{:ok, _} | {:error, _}`** at boundaries — Matches Ecto/Req/Oban ergonomics.

### Integration points

- **README** + **CONTRIBUTING** + **verify.opsui** — Triad for any new contributor-facing string or command (**D-15**).
- **CHANGELOG** — Per-PR user-visible notes.

</code_context>

<specifics>
## Specific Ideas

- Research consensus: **Searchkick-class** OSS wins first-hour with README + examples; Scrypath wins **first hour + month six** via **types + stable tags + anchored guides**—Phase 58 should reinforce that positioning without macro expansion.
- Confirm **`guides/overview.md`** vs **`docs_contract_test`** coverage during implementation (**D-14**).

</specifics>

<deferred>
## Deferred Ideas

- **Automated PR-body `Evidence: EVID-57-*` gate** — Phase 57 deferred unless pain; optional **paths-filter** workflow.
- **`Scrypath.Sync.Error` module** — Only if bang/sync surface needs a first-class rescue type; otherwise defer to keep diff small.
- **Playbook UI string contracts in core repo** — Belongs to **`scrypath_ops`** phases **59–61**, not Phase 58.

</deferred>

---

*Phase: 58-core-library-and-doc-qol-b1*  
*Context gathered: 2026-04-22*
