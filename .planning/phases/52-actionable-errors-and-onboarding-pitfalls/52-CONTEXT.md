# Phase 52: Actionable errors and onboarding pitfalls - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **ONBD-04**–**ONBD-06** for **v1.12**: bounded, honest **{:error, _}** / **documented** raise surfaces that tell developers **what failed** and **which shipped guide section** to read next—**without** inventing recovery verbs the library does not implement; one **evidence-led** pitfalls / common-mistakes guide (≥3 items); **`Scrypath`** **`@moduledoc`** and **primary** **`mix scrypath.*`** task docs so a newcomer reaches **`guides/golden-path.md`** and **`guides/sync-modes-and-visibility.md`** within **two hops**. No new write-side capabilities; no README bloat that violates Phase **51** doc roles.

</domain>

<decisions>
## Implementation Decisions

### 1. Bounded error paths (ONBD-04) — what to cover first

- **D-01:** Prioritize paths where **frequency × first-hour pain** is high **and** the library can name a **true** precondition: **(1)** application / backend config resolution (missing URL, key, or backend module—name the **env keys** or config surface the code actually reads); **(2)** unknown or unsearchable schema module (not `use Scrypath`, wrong module, index not registered); **(3)** **`search_many/2`** structural and federation / **`:all`** / `global_schemas` / `federation_weight` **preflight** failures—**keep existing tagged tuples**, improve human legibility and doc anchors only where a guide already states the rule; **(4)** single-call **transport** failures surfaced as `{:error, {:transport_failed, _}}`—clarify failure class and link to **existing** operator / Meilisearch guidance (**`guides/meilisearch-operations.md`**, **`guides/drift-recovery.md`**, or **`guides/sync-modes-and-visibility.md`** as appropriate), not ad-hoc “fix your network” fiction.
- **D-02:** **Defer** in this phase: unbounded HTTP edge enumeration, reshaping **partial** **`search_many`** success semantics (already documented `failures:` on **`{:ok, %MultiSearchResult{}}`**), and any message that would **promise** recovery the code path does not perform.
- **D-03:** **Message shape:** one factual sentence (what broke, with safe structured context already in the tuple where applicable) plus a **literal** stable pointer **`guides/<file>.md`** and **`#anchor`** when the guide section exists; align anchors with **`docs_contract_test`** if new anchors are introduced.

### 2. Error vocabulary — tuples, raises, semver (cohesive with D-01)

- **D-04:** **Keep tagged tuples** as the public discriminant for non-bang APIs; treat **tag shape** as semver-sensitive once documented. Prefer improving **human-readable substrings or small map keys** (`:hint`, metadata map) **inside** the existing second element over string-only errors or a sprawling public “error code” enum.
- **D-05:** **Splitting rule (document and narrow, do not invent a third path):** **`{:error, _}`** for operational / backend / validation outcomes callers should branch on; **`ArgumentError`** (or equivalent) only for **true API misuse** where that is already the pattern—**document** which **`search/3`** validations use which path. Do not silently turn raises into tuples (or the reverse) without a **major** story.
- **D-06:** **Bang functions:** move away from long-term reliance on bare **`RuntimeError`** + **`inspect(reason)`** for **`search!/3`** (and peers)—prefer a **small, named exception** (e.g. domain **`Scrypath.Search`** error exception) with **`message/1`** that carries the same **guide pointer** discipline as tuples. Callers rescuing **`RuntimeError`** broadly are already fragile; a named exception is **least surprise** for a bang.
- **D-07:** **Optional formatter:** if log ergonomics need it in-phase, add a **single** documented helper (e.g. **`Scrypath.Error.message/1`**) that formats **`{:error, reason}`** for operators—**not** required to wrap every reason as an exception struct.

### 3. Pitfalls / common mistakes slice (ONBD-05) — placement and discipline

- **D-08:** Add **one** canonical guide **`guides/common-mistakes.md`** (evidence-led; ≥3 items for **ONBD-05**, hard ceiling ~8). Each item: **symptom → wrong mental model → fix pattern → authority link** (sync semantics **link** to **`guides/sync-modes-and-visibility.md`**, do not duplicate).
- **D-09:** **Do not** embed the pitfalls body in **README** or **`guides/golden-path.md`**—README at most **one** new sentence pointing to the guide; golden path stays a **forward-only** first-hour narrative (Phase **51** contract).
- **D-10:** **Discoverability:** add a row in **`guides/overview.md`**; add a prominent link in **`CONTRIBUTING.md`** (integrator + contributor path); optionally **`README.md`** one-liner next to existing depth pointers. Add **`docs_contract_test`** anchors for the new guide path and any README line if used as a contract.
- **D-11:** **Evidence gate:** each pitfall must cite **evidence** (failing test name, CI class, issue, telemetry, or repeated support theme)—reject speculative “some people think…” entries.

### 4. **`Scrypath`** lobby **`@moduledoc`** and Mix task help (ONBD-06)

- **D-12:** Reframe **`lib/scrypath.ex`** as the **library lobby**: short **product narrative** (schema → sync → search), then **defer** declaration grammar to **`Scrypath.Schema`** (link only; no duplicated option tables).
- **D-13:** **Link order in lobby + Mix `@moduledoc` blocks:** **`guides/golden-path.md`** first, **`guides/sync-modes-and-visibility.md`** second; optional third hop **`guides/overview.md`** only as TOC—not a chain through README for maintainer-class content.
- **D-14:** **`mix help` surfaces:** tighten **`@shortdoc`** only where vague; ensure **`@moduledoc`** for **operator-adjacent** tasks includes the same **two-hop** link block: **`scrypath.status`**, **`scrypath.reconcile`**, **`scrypath.retry`**, **`scrypath.failed`** (primary “is sync lying to me?” door = **`scrypath.status`**). **`scrypath.settings.*`** may receive a **minimal** pointer block in-phase if touched; do not block the phase on duplicating settings prose.
- **D-15:** **`guides/common-mistakes.md`** is linked from the **`Scrypath`** lobby (and optionally overview)—satisfies “pitfalls within two hops” alongside **ONBD-06** without stuffing errors into README.

### Claude's Discretion

- Exact exception module name under **`Scrypath.Search.*`** if introduced.
- Whether **`Scrypath.Error.message/1`** ships in **52** or is deferred to a follow-up hygiene pass, as long as **D-04**–**D-06** messaging quality ships for the bounded set.
- Precise **`#anchor`** strings once guide sections exist.

### Folded Todos

(None — `todo.match-phase` returned no matches.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **ONBD-04**, **ONBD-05**, **ONBD-06**; out-of-scope table (no invented recovery verbs).
- `.planning/ROADMAP.md` — Phase **52** goal, success criteria, dependency on Phase **51**.
- `.planning/PROJECT.md` — **v1.12** vision, operational honesty, doc-first scope.

### Prior phase context (doc roles — do not regress)

- `.planning/phases/051-adoption-path-truth-and-discoverability/051-CONTEXT.md` — README vs CONTRIBUTING vs guides; sync authority; doc-contract patterns (**D-01**–**D-14** there).

### Shipped guides (error pointers and semantics)

- `guides/golden-path.md` — First-hour spine; primary **ONBD-06** hop **1**.
- `guides/sync-modes-and-visibility.md` — Sync lifecycle authority; primary **ONBD-06** hop **2** for modes and honesty language.
- `guides/overview.md` — TOC / discovery; extend with link to **`guides/common-mistakes.md`** (**D-10**).
- `guides/multi-index-search.md` — Federation / **`search_many`** rules for **D-01** anchors.
- `guides/meilisearch-operations.md` — Operator-facing Meilisearch reality for transport / cluster-ish failures (**D-01**, **D-03**).
- `guides/drift-recovery.md` — Drift and recovery language where relevant to errors.

### Contributor and consumer entry

- `README.md` — Thin front door; optional one-line pointer **D-09**.
- `CONTRIBUTING.md` — Link block for pitfalls guide **D-10**.

### Implementation touchpoints (bounded errors)

- `lib/scrypath.ex` — **`@moduledoc`** lobby (**D-12**–**D-15**).
- `lib/scrypath/search.ex` — Tuple vs raise paths, **`search!`**, **`search_many/2`** errors (**D-01**, **D-04**–**D-06**).
- `lib/scrypath/options.ex` — Validation and federation-related errors surfaced to callers (**D-01**, **D-04**).
- `lib/mix/tasks/scrypath.status.ex` — **`scrypath.status`** (and peers per **D-14**).

### Contracts

- `test/scrypath/docs_contract_test.exs` — Extend for new guide + anchors (**D-10**, **D-11**).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`lib/scrypath/search.ex`** — Central **`{:error, _}`** surface for **`search/3`**, **`search_many/2`**, federation preflight; bang helpers currently **`raise RuntimeError`** with **`inspect(reason)`**—primary target for **D-06** clarity.
- **`lib/scrypath/options.ex`** — Rich validation errors; align messaging with **D-04** (tags + human text) without destabilizing match clauses.
- **`test/scrypath/docs_contract_test.exs`** — Phase **51** pattern for locking doc strings and cross-file anchors.

### Established patterns

- Tagged tuples for invalid options (e.g. **`{:invalid_options, _}`**) already documented in **`search_many/2`** **`@doc`**—extend **messages** and **@doc** “raises when” notes per **D-05**, not tuple taxonomy churn.
- Mix tasks under **`lib/mix/tasks/scrypath.*.ex`** already use **`@shortdoc`**; mirror **lobby** links in **`@moduledoc`** (**D-14**).

### Integration points

- **ExDoc** “extras” and **`guides/overview.md`** — discovery path for **`guides/common-mistakes.md`**.
- **README / CONTRIBUTING** — single-line / short pointer only (**D-09**, **D-10**).

</code_context>

<specifics>
## Specific Ideas

- Cross-ecosystem pattern: **Rails Searchkick / Laravel Scout** succeed with small public surfaces and obvious **queue vs sync** mental models—Scrypath’s errors should reinforce **eventual consistency** honesty, not imply “reindex fixed everything.” **Prisma-style** enumerable errors teach **stable codes + actionable first line**—here implemented as **stable tuple tags + message discipline**, not stringly-typed enums.
- **Ecto / Req-shaped** ergonomics: machine tag + human text (and optional **`Exception.message/1`** for exceptions)—avoid naked **`inspect`** as the only operator signal.

</specifics>

<deferred>
## Deferred Ideas

- **`Scrypath.Error.message/1`** if not shipped in **52** (**D-07** discretion).
- Broad HTTP / vendor error taxonomy beyond the bounded set (**D-02**).
- Reshaping partial **`search_many`** **{:ok, _}** failure aggregation (**D-02**).

### Reviewed Todos (not folded)

(None.)

</deferred>

---

*Phase: 52-actionable-errors-and-onboarding-pitfalls*  
*Context gathered: 2026-04-21*
