# Phase 27: Schema–index drift report (read-only) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a **read-only**, **structured** comparison of **declared** Scrypath metadata for a searchable schema vs the **live** Meilisearch index contract operators care about (fields, filterable, sortable, faceting where present, and **settings families the library applies**), with **named dimensions** of difference (DRIFT15-01, DRIFT15-02). Expose from **`Scrypath.*`** with **report-first** posture and **no new recovery verbs** (OPS15-01). **Mix tasks, `--json`, guide updates, and `mix verify.phase28`** stay in **Phase 28** (OPS15-02..04).

**Non-goals (requirements):** No silent auto-repair; no full corpus diff; no public multi-backend facade.

**Semantic guard:** `%Scrypath.Operator.Reconcile{}.drift_signals` today means **operational** posture (queue, failed work, reindex) — **not** declared-vs-live **index contract** parity. Phase 27 vocabulary MUST NOT overload that list with contract atoms.

</domain>

<decisions>
## Implementation Decisions

### Public entry (OPS15-01) — primary vs reconcile

- **D-01:** Add a **dedicated** `Scrypath.<name>/2` (planner picks final name; candidate: `index_contract_drift/2`) as the **primary** documented entry: **`{:ok, %Report{}} | {:error, term()}`**, implemented under **`Scrypath.Operator`** with the same thin-delegate pattern as **`failed_sync_work/2`** and **`reconcile_sync/2`**.
- **D-02:** **Do not** fold contract drift into **`%Reconcile{}.drift_signals`** or reuse the word “drift” there for attribute/settings contract — avoids **least-surprise** collision with existing operator semantics and CLI copy.
- **D-03:** **Do not** overload **`Settings.verify_applied/3`** to become the full Phase 27 report — it stays the **focused** primitive for **settings-only** parity (reindex gate, existing docs). Phase 27 **orchestrates** broader contract reads + compares.

### Optional reconcile composition (DX, not default)

- **D-04:** **Optional opt-in** on **`reconcile_sync/2`** (keyword parallel to Phase 26’s **`reason_class_counts: true`**), e.g. **`include_index_contract_drift: true`**, attaching an **additive** optional field on **`%Reconcile{}`** (e.g. **`index_contract_drift: nil | %Report{}`**) **outside** `@enforce_keys`, computed by **calling the same builder** as the standalone API (single source of truth; mirrors Phase 26 “one aggregator, many consumers”).
- **D-05:** **Default unchanged:** when the opt-in is **absent**, reconcile performs **no** extra Meilisearch GET for contract drift — preserves cost for callers that only need queue/reindex/failed-work triage.
- **D-06:** **Reject** “always embed contract drift on every reconcile” — raises default latency/noise and blurs OPS15-03’s mental model (health vs definition parity).

### Report carrier, density, JSON (Phase 28–ready)

- **D-07:** Root and nested **public structs** under **`Scrypath.Operator`** (not bare maps as the documented API), with **`@type t`**, **`@moduledoc`**, and root **`version: integer()`** (start at **`1`**) — align with **`%ReasonClassCounts{}`** / **`Jason.OrderedObject`** discipline from Phase 26.
- **D-08:** **Machine JSON path:** **dense or explicit-status** per compared axis — never encode “parity” only as **absent keys** (footgun for `jq` and for “skipped vs match”). Prefer per-axis **`match` / `state` / explicit both sides** so empty drift lists are unambiguous.
- **D-09:** **Human path (Phase 28 Mix):** may render **sparse** (diffs only) while JSON remains explicit; one-line “remaining dimensions match” footer when useful.
- **D-10:** Implement **`Jason.Encoder`** on the report root (and nested structs as needed) with **stable key order**; maps only at **private** boundaries or raw HTTP payloads.

### Layering vs `settings.diff` / `compute_drift`

- **D-11:** **Single orchestrated snapshot** per report build: build **declared contract projection** (pure), fetch **live** once (or minimal coordinated GETs behind one module), run **pure** comparers per dimension — same **`declared_wire` / `applied_wire`** pair feeds any settings-shaped slice.
- **D-12:** **Reuse** **`Scrypath.Meilisearch.Settings.compute_drift/2`** for the **settings** portion of the contract — **do not** fork a second drift vocabulary for the same keys.
- **D-13:** **Document and test** that overlapping keys between **`mix scrypath.settings.diff`** and the report’s settings slice **agree** given the same schema, index, and config (same normalization path as today: **`resolve` → `translate_settings`** vs live GET).
- **D-14:** **Internal boundary (planner discretion on module names):** IO in a thin reader/snapshot builder; **pure** compare functions (table-testable) including delegation to **`compute_drift/2`**; orchestration function composes them — matches existing Elixir testability patterns in **`Settings`**.

### Naming and discoverability

- **D-15:** Name the API and struct so **`grep` / ExDoc** disambiguate **index contract** drift from **`drift_signals`** and from **release tarball drift** language elsewhere in the repo.

### Claude's Discretion

- Exact function atom (`index_contract_drift` vs `schema_contract_drift`, etc.) after collision grep and ExDoc scan.
- Exact struct module names and field tree granularity (flat vs nested sections).
- Whether **`!`** bang variant exists for scripting — default **no** unless a clear caller need appears in plan.
- Telemetry hooks for the orchestration path — only if consistent with existing **`[:scrypath, …]`** patterns and low noise.

### Folded Todos

None — `gsd-sdk query todo.match-phase` unavailable in this environment.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — DRIFT15-01, DRIFT15-02, OPS15-01; out-of-scope table; traceability (Phase 27 vs 28)
- `.planning/ROADMAP.md` — Phase 27 row; v1.5 goals
- `.planning/PROJECT.md` — v1.5 operator drift milestone; report-first; composes with settings diff / reconcile / reindex

### Prior phase context

- `.planning/phases/026-operator-failure-rollups/26-CONTEXT.md` — opt-in enriched return; dense keyed structs; `Jason.OrderedObject`; single aggregator reused across API and Mix
- `.planning/phases/025-settings-hot-apply-narrow/25-CONTEXT.md` — `verify_applied` / full settings parity story vs bounded `hot_apply`
- `.planning/phases/022-operator-polish-drift-recovery-guide/22-CONTEXT.md` — operator doc posture; `reason_class` discipline

### Code (integration and reuse)

- `lib/scrypath.ex` — public delegate pattern for operator functions
- `lib/scrypath/operator.ex` — `@operator_only_opts` split; extension point for new opt keys if reconcile composition ships
- `lib/scrypath/operator/reconcile.ex` — `%Reconcile{}` shape; **`drift_signals`** semantics (operational only)
- `lib/scrypath/meilisearch/settings.ex` — **`verify_applied/3`**, **`compute_drift/2`**, **`resolve` / `translate_settings`**
- `lib/mix/tasks/scrypath.settings.diff.ex` — operator CLI pattern; drift path behavior (reference for Phase 28, not Phase 27 scope)
- `lib/scrypath/operator/reason_class_counts.ex` — **`version`**, **`Jason.Encoder`**, dense map pattern

### Research / features

- `.planning/research/FEATURES.md` — operator surface preferences where relevant

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Settings.compute_drift/2`** — canonical pure comparer for declared-vs-applied **settings wire** maps; Phase 27 should compose, not duplicate.
- **`Settings.verify_applied/3`** — existing settings-only gate; keep semantics focused.
- **`Client.get_settings/2`** — live settings read primitive.
- **`Scrypath.schema_*` reflection** — declared fields/settings/faceting source of truth for projection inputs.
- **Phase 26 patterns** — **`ReasonClassCounts`**, optional **`reason_class_counts`** on **`failed_sync_work/2`**, additive **`failed_work_counts`** on **`%Reconcile{}`**.

### Established patterns

- **`{:ok, struct} | {:error, term}`** for operator I/O; structs for versioned operator payloads.
- **Keyword opt-in** for heavier report branches without breaking defaults.

### Integration points

- New **`Scrypath`** delegate + **`Scrypath.Operator`** implementation.
- Optional **`Operator.reconcile_sync`** / **`Reconcile.run`** extension only if **D-04** is in plan scope and `@operator_only_opts` is updated consistently.

</code_context>

<specifics>
## Specific Ideas

User requested **all four** discuss areas with **parallel subagent research** (ecosystem: Searchkick / Scout-style separation of data vs definition vs settings; Elixir tuple/struct idioms; Stripe/OTel-style additive evolution). Synthesized recommendations: **standalone `Scrypath.*` + dedicated struct + `version` + orchestrated single snapshot + reuse `compute_drift` + optional reconcile opt-in, default off** — single coherent architecture.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 28:** `mix scrypath.*` task(s), **`--json`**, **`guides/drift-recovery.md`** / **`docs/operator-support.md`** cross-links (OPS15-03), **`mix verify.phase28`** (OPS15-04).
- **Follow-up:** Reduce **`mix scrypath.settings.diff`** double-`get_settings` on drift path using shared snapshot builder — only if small and does not widen Phase 27 scope inappropriately; otherwise note for backlog.

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 27-schema-index-drift-report*
*Context gathered: 2026-04-17*
