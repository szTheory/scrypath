# Phase 22: Operator Polish + Drift Recovery Guide - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship richer `%Scrypath.Operator.FailedWork{}` (additive fields + deterministic `reason_class`), one telemetry observation event for constructed failed-work rows, and `guides/drift-recovery.md` with six SRE-style scenarios using only existing `Scrypath.*` and `mix scrypath.*` verbs. No new public recovery verbs, no new Mix tasks, no changes to `@enforce_keys` on `FailedWork`. Scope is narrow operator polish aligned with OPS-05..OPS-10 and roadmap non-goals.

</domain>

<decisions>
## Implementation Decisions

### Telemetry (`[:scrypath, :operator, :failed_work, :observed]` — OPS-10)

- **D-01:** **Contract layering.** OPS-10 is treated as a **minimum** contract: metadata **must** include `reason_class`, `schema`, and `mode`. Handlers may rely on these three keys across Scrypath versions.
- **D-02:** **Optional metadata (v1.3):** Also emit **`operation`** (bounded atom vocabulary owned by Scrypath — same family as `FailedWork.operation`: `:upsert | :delete | :unknown` or the struct’s current set) and **`retryable?`** (boolean, same semantics as the struct field). These answer “what failed” and “does Scrypath imply automatic replay?” without opening a high-cardinality hole.
- **D-03:** **Do not** add to default metadata for this event in v1.3: raw **`id`**, freeform **`source`**, full error strings, HTTP bodies, or unstructured blobs. Correlation to Meilisearch `taskUid`, Oban `job` id, etc. stays in **logs, `FailedWork` fields, and operator-facing APIs** — not as default telemetry dimensions (cardinality + PII footguns; matches Oban/Ecto pattern of rich *optional* handler filtering, but Scrypath keeps the **default emission** metrics-safe).
- **D-04:** **Measurements:** Emit **`%{count: 1}`** unless the construction is already wrapped in measured work; **do not** add `duration` unless it is real wall time from an existing span — avoid fake measurements. Align envelope style with existing `Scrypath.Telemetry` usage elsewhere in the library.
- **D-05:** **Documentation obligation:** HexDocs / guide copy must state: required vs optional metadata keys; warn that **`schema` module** and any future optional keys are **unsafe as Prometheus/OpenTelemetry metric labels** without sampling/rollup — safe for logs, traces, and structured handlers.

### `guides/drift-recovery.md` structure and cross-links (OPS-09)

- **D-06:** **Hybrid doc posture (default A, surgical B).** Each of the six scenarios is **self-contained through symptom → diagnosis → action → verify** using only shipped APIs/tasks. No “link before verify” ladders.
- **D-07:** **At most one inline “escape hatch” link per scenario** where symptoms overlap faceting, relevance tuning, or multi-index behavior — link to the **smallest anchor** that disambiguates (e.g. settings vs facet vs federation), not the whole guide.
- **D-08:** **Discoverability layer:** After the intro, a short **Guide map** (3–5 lines) pointing to `guides/relevance-tuning.md`, `guides/faceted-search-with-phoenix-liveview.md`, `guides/multi-index-search.md` with one-line “when to open this.” End with a consolidated **Related guides** section (Kubernetes/Elastic/Oban pattern: local procedure + hub links).
- **D-09:** **Operational honesty in prose:** When a scenario touches concepts from 19–21, state the **coupling in one sentence** in-scenario (“wrong results but healthy tasks” vs “settings/facet drift”) so operators are not sent to related guides only at the bottom.

### `metadata.discard_reason` (`:exhausted` | `:explicit`) for `:queue_exhausted`

- **D-10:** **Defer `metadata.discard_reason` for v1.3.** Ship `reason_class: :queue_exhausted` plus **`attempt` / `max_attempts`** on Oban-backed rows and rely on **Oban `state` (`:discarded` vs `:cancelled`)** and existing **`reason` / queue metadata** for disambiguation. Modern Oban steers intentional stop toward **`{:cancel, _}` → `:cancelled`**, reducing the historic “discarded means two stories” pain; optional `discard_reason` would add **doc + test matrix debt** in a **narrow-polish** phase for mostly legacy discard paths.
- **D-11:** **v1.4+ trigger to reconsider:** Adopter evidence of heavy **deprecated `{:discard, _}`** use, or repeated support questions where `attempt`/`max_attempts` + state are insufficient — then add optional `discard_reason` with explicit presence rules and tests.

### Classifier and tests (OPS-06)

- **D-12:** **Architecture: normalize → classify.** Adapters (`from_backend_task/3`, `from_queue_job/3`) map vendor/job shapes to a **small internal map** (e.g. HTTP status, Meilisearch `error.type` / `code`, Oban state, structured error tuples). **Private pure functions** classify that map to one of the five atoms; **default `:unknown`** when signals are missing or ambiguous — never silent wrong class.
- **D-13:** **Primary test suite: table-driven unit tests** on the **normalized input** (minimal maps, only keys the classifier reads — acts as living spec). Prefer **stable machine fields** (`error.type`, `error.code`, status integers) over English message substrings; isolate any unavoidable message heuristics in one module with its own tiny table.
- **D-14:** **Secondary: thin contract tests** at the boundary (fakes / `Req.Test` / recorded minimal payloads) proving **realistic Meilisearch + Oban shapes** still map into expected normalized inputs — keep count small, tag `:integration` or `:slow` if needed. Avoid large JSON snapshot churn.
- **D-15:** **Property tests (optional, low priority):** If `stream_data` (or hand-rolled generation) is added later, test **invariants only**: classification always returns one of the five atoms; missing fields → `:unknown`; idempotent normalization. Do **not** property-test random strings for meaningful classes.

### Coherence across decisions

- **D-16:** **Single story for operators:** `reason_class` + optional `operation` + `retryable?` in telemetry matches what they see on `%FailedWork{}`; the drift guide explains **what to do** without requiring them to read feature guides mid-scenario; tests lock **OPS-06** without brittle integration everywhere; **no** extra metadata keys like `discard_reason` until v1.4 signal.

### Claude's Discretion

- Exact atom set for `operation` in telemetry if it is extended beyond task-derived values for edge cases.
- Wording of the Guide map one-liners and which single anchor to use per scenario.
- Whether one contract test runs against live Meilisearch in `mix test` vs only `Req.Test` — prefer **no live server** in default unit path unless the repo already establishes that pattern for operator tests.
- Exact `ExUnit` structure (one `test` per table row vs grouped) — prefer **one test per row** or **describe + named rows** for clear failures.

### Folded Todos

None (no `gsd-sdk` todo match in this environment).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — § Phase 22: Operator Polish + Drift Recovery Guide (goal, success criteria, disjoint-file note with Phase 23)
- `.planning/REQUIREMENTS.md` — § Operator Polish & Drift Recovery (OPS-05..OPS-10)
- `.planning/PROJECT.md` — Current milestone, operator-polish bullet, constraints (operational clarity, Meilisearch-first, no breaking public contracts)

### Deep research

- `.planning/research/deep/OPERATOR_POLISH.md` — `reason_class` taxonomy, struct field rationale, telemetry naming, guide shape, classifier placement in `FailedWork`, anti-patterns (no public classifier, no `@enforce_keys` changes)

### Cross-phase alignment (guide references only)

- `.planning/research/deep/RELEVANCE.md` — settings drift and verify/cutover language (reference only; Phase 19 implements TUNE)
- `.planning/research/deep/FACETING.md` — facet / `filterableAttributes` drift language
- `.planning/research/deep/MULTI_INDEX.md` — `search_many/2` operator note (sync vs search failure primitives)

### Code (integration targets)

- `lib/scrypath/operator/failed_work.ex` — struct, `from_backend_task/3`, `from_queue_job/3`, list pipeline
- `lib/scrypath/telemetry.ex` — `Telemetry.span/3` and metadata conventions; compare `:telemetry.execute` in `lib/scrypath/reindex.ex` (e.g. `[:scrypath, :reindex, :verify_skipped]`)
- `lib/scrypath/cli/operator_task.ex` — operator CLI consumption of `FailedWork`
- `mix.exs` — `:extras` for new guide (mirror other guides)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Scrypath.Operator.FailedWork` already centralizes backend vs Oban listing, `recovery_action/1`, timestamps, and `metadata` maps — classification and telemetry attach here without new modules (per OPERATOR_POLISH.md).

### Established Patterns

- Additive struct fields **outside** `@enforce_keys` match v1.3 SearchResult/Query/FailedWork evolution pattern.
- Telemetry elsewhere in Scrypath should inform event/measurement shape (D-04).

### Integration Points

- Operator Mix tasks and `Scrypath.failed_sync_work/2` / `reconcile_sync/2` consumers see enriched rows automatically once constructors populate new fields.
- HexDocs extras list for new `guides/drift-recovery.md`.

</code_context>

<specifics>
## Specific Ideas

Research synthesis (2026-04-17) across four areas — telemetry minimal-vs-rich, doc cross-links, `discard_reason`, classifier tests — converged on: **bounded optional telemetry** (`operation`, `retryable?`), **hybrid runbook**, **defer discard_reason**, **normalize→classify + tables + thin contracts**. User asked for a single coherent recommendation set without further interactive passes.

</specifics>

<deferred>
## Deferred Ideas

- **`metadata.discard_reason`** (`:exhausted` | `:explicit`) — v1.4+ if legacy Oban discard traffic warrants it (D-10, D-11).
- **Richer telemetry** (raw ids, freeform `source`, durations) — only with explicit opt-in or separate events after adopter signal (D-03).
- **Property-based classifier fuzz** beyond invariants — deferred (D-15).

### Reviewed Todos (not folded)

None recorded.

</deferred>

---

*Phase: 22-operator-polish-drift-recovery-guide*
*Context gathered: 2026-04-17*
