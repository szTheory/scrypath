# Phase 45: Posture & failure triage - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **real read-only** operator LiveViews in **`scrypath_ops/`** for **OPSUI-01** (per-schema/index posture from **`Scrypath.sync_status/2`** and related visibility), **OPSUI-02** (failed sync triage aligned with **`Scrypath.failed_sync_work/2`** including **`reason_class`** rollups), and **OPSUI-03** (sync/drift context from **`reconcile_sync/2`** / **`index_contract_drift/2`** with **links only** to Mix tasks and guides—**no** new recovery verbs in the UI). Scope stays inside the phase-44 shell (**`live_session :ops`**, nav order, public **`Scrypath.*`** only).

</domain>

<decisions>
## Implementation Decisions

### Schema coverage and host configuration

- **D-01:** OPSUI resolves **which schema modules** to show using a **required explicit allowlist** in **`scrypath_ops` host configuration** (e.g. env-driven list under `:scrypath_ops` or equivalent documented in **`scrypath_ops/README.md`**). **No** runtime discovery as the default path (`Code.all_loaded/0`, broad `Application.spec/2` scans, or loose “implements behaviour” filters). Rationale: **deterministic CI**, **production safety**, **least surprise**—same philosophy as Sidekiq Web / Laravel Horizon explicit wiring, avoiding Kubernetes-dashboard-style “show everything loaded.”
- **D-02:** **Optional DX helpers only at dev/build time:** a Mix task or doc snippet may **suggest** candidate modules for copy-paste into config; that must **not** replace the allowlist at runtime.
- **D-03:** Allowlist entries remain **`schema` module atoms** for v1.10; if multiple logical indexes per schema appear later, entries may evolve to **`{module, opts}`** without adopting reflection as the primary mechanism.

### Posture / health landing (OPSUI-01)

- **D-04:** **Layout:** **Dense sortable table** as the default fleet view for allowlisted schemas; **expandable row or side detail** for one schema’s **backend vs queue** breakdown (hybrid). Cards-only layouts are **out** for the primary fleet view (acceptable on a per-schema drill panel if added later).
- **D-05:** **First-class columns (landing):** schema module, resolved **index** UID, **`sync_mode`**, **backend** pending/failed counts and **last success** timing, **queue** observed flag + pending/retrying/failed counts and **last success**—as separate signals (never a single merged “green/red” for the fleet). Honor **`queue.observed?`** semantics for non-`:oban` modes (**queue not observed**).
- **D-06:** **Per-row fetch outcome:** each schema row reflects **`{:ok, %Scrypath.Operator.Status{}}`** or **`{:error, term}`**; errors sort first; **no** collapsed “global healthy” chip across schemas—only **honest aggregates** (“N schemas with fetch errors”, “M with queue backlog”) plus per-row truth.
- **D-07:** **Refresh model:** **manual refresh primary** (prominent control, optional keyboard shortcut). **Optional** slow auto-refresh (suggested band **30–60s**) **only while the browser tab is visible**; default auto-refresh **off** in production until load is characterized. **Staggered** fetches with bounded concurrency (**`Task.async_stream`**-style, small `max_concurrency`, per-schema timeout, overall deadline) to avoid Meilisearch/Oban stampedes.
- **D-08:** **LiveView data patterns:** **assigns** for the small summary table; reserve **`stream_*`** for long lists of **`State`** rows in drill-down. UI telemetry stays **low-cardinality** (e.g. refresh outcome, schema **count**, duration)—**not** per-schema module names on high-frequency metric labels (align **`docs/search-backend-sre.md`** and **`FailedWork`** moduledoc warnings).

### Failed sync work triage (OPSUI-02)

- **D-09:** **Default API path:** call **`Scrypath.failed_sync_work/2` with `reason_class_counts: true`** so the LiveView holds **`%Scrypath.Operator.FailedSyncWorkInspection{}`** with **`entries`** and **`counts`** from **one** snapshot—structurally impossible to desync rollups from the row list **within** that snapshot.
- **D-10:** **Rollup strip:** always surface **`reason_class`** class counts for the default view (CLI-equivalent to human **`mix scrypath.failed`** with class summary). A **“compact mode”** UI toggle may **hide** the visual strip but must **not** drop **`counts`** from assigns or recompute rollups from a truncated list.
- **D-11:** **Table parity:** columns and sort default align with operator expectations from **`mix scrypath.failed`** / **`guides/operator-mix-tasks.md`**—sort default **newest / most recently observed first**; show **`reason_class`** per row (map **`:unknown`** explicitly, never blank **`nil`**).
- **D-12:** **Pagination / virtualization:** paginate or virtualize **only** over the **`entries`** already returned; **never** recompute **`counts`** from a sliced subset without labeling the UI as subset-only. If row counts grow large, prefer **client-side paging** or **streams** of the **full** fetched list while the header rollups reflect **`counts.total`** for that snapshot.
- **D-13:** **Row detail:** default **collapsed** summary row; **expand** for long **`reason`**, **`metadata`**, **`recovery`** presence—**read-only**; **no** retry/backfill/reindex buttons in phase 45; deep links to **`guides/drift-recovery.md`** and **`guides/operator-mix-tasks.md`** (and related Mix copy) for actions.
- **D-14:** **Operator opts parity:** expose the same **runtime / operator** keyword families the CLI uses (**backend, sync_mode, index_prefix, meilisearch_url, oban, oban_queue**, etc.) so screens match pasted invocations from the operator Mix guide.

### Sync / drift read-only (OPSUI-03)

- **D-15:** **Single LiveView, two labeled sections** on **`/ops/sync-drift`**: (1) **“Sync & queue posture”** from **`Scrypath.reconcile_sync/2` without `include_index_contract_drift: true`** on default load and primary refresh; (2) **“Index contract (declared vs live)”** from **`Scrypath.index_contract_drift/2` only behind an explicit “Load / refresh contract drift” control.** Do **not** use **`include_index_contract_drift: true` on `reconcile_sync/2`** for the default interactive load path (avoids extra **`get_settings`** on every visit and avoids failing the **entire** reconcile when settings read fails).
- **D-16:** **Signal-family honesty:** copy and headings must **not** conflate reconcile **`drift_signals`** with **index contract drift**—they are different families per **`lib/scrypath.ex`** `@doc`.
- **D-17:** **Scoped errors:** contract drift failures render in the **drift section only**; reconcile section remains usable when drift errors.
- **D-18:** **Empty / idle states:** neutral copy when drift was never loaded; show **last fetched** timestamps whenever drift or reconcile was successfully loaded; link to **`mix scrypath.reconcile`**, **`mix scrypath.index.contract_drift`**, **`guides/drift-recovery.md`**, **`guides/sync-modes-and-visibility.md`**, **`guides/meilisearch-operations.md`**, **`docs/operator-support.md`** as appropriate (paths consistent with **`scrypath_ops/docs/operator-ia.md`**).
- **D-19:** **Manual refresh** for reconcile and **separate** control for contract drift; visible timestamps so operators know what refreshed.

### Cross-cutting

- **D-20:** **Testing:** prefer **`Scrypath`** operator opts injection (**`:meilisearch_tasks`**, **`:oban_jobs`**, **`:oban_inspector`**, etc. per **`lib/scrypath/operator.ex`**) for LiveView tests—keep UI thin over public APIs.

### Claude's Discretion

- Exact **config key names** and env var spelling for the schema allowlist (must be documented in **`scrypath_ops/README.md`**).
- Exact auto-refresh interval when enabled; optional short-lived **ETS** snapshot cache for hot refresh (TTL, key shape).
- Visual microcopy, sort keys beyond the stated default, and whether expandable rows use drawer vs inline panel.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone, requirements, prior phase

- `.planning/ROADMAP.md` — Phase 45 goal and success criteria (**OPSUI-01**..**OPSUI-03**).
- `.planning/REQUIREMENTS.md` — Acceptance text and out-of-scope table (no new recovery verbs in UI).
- `.planning/PROJECT.md` — Product boundary, operational honesty, OPSUI outside Hex.
- `.planning/phases/44-opsui-foundations/44-CONTEXT.md` — Packaging, nav order, **`live_session :ops`**, security, telemetry discipline.

### Library contracts (implementation truth)

- `lib/scrypath.ex` — **`sync_status/2`**, **`failed_sync_work/2`**, **`reconcile_sync/2`**, **`index_contract_drift/2`** `@doc` (especially **`reason_class_counts`** and **`include_index_contract_drift`** semantics).
- `lib/scrypath/operator/status.ex` — **`%Scrypath.Operator.Status{}`** backend vs queue separation, **`queue.observed?`**, list shapes.
- `lib/scrypath/operator/failed_work.ex` — **`%FailedWork{}`**, **`reason_class`**, rollup invariants (counts from **same** row list).
- `lib/scrypath/operator/reconcile.ex` — **`%Reconcile{}`**, optional **`index_contract_drift`** attachment.

### Operator guides and ops discipline

- `guides/operator-mix-tasks.md` — CLI parity and flags for **`mix scrypath.failed`**, **`mix scrypath.status`**, reconcile / contract drift tasks.
- `guides/drift-recovery.md` — Read-only triage narrative and Mix-first actions.
- `guides/sync-modes-and-visibility.md` — Sync mode semantics for UI copy.
- `guides/meilisearch-operations.md` — Linked from **`operator-ia.md`** for posture context.
- `docs/search-backend-sre.md` — Low-cardinality telemetry expectations.
- `docs/operator-support.md` — Maintainer-facing operator support pointers.

### OPSUI shell (integration)

- `scrypath_ops/lib/scrypath_ops_web/router.ex` — **`/ops/*`** routes.
- `scrypath_ops/docs/operator-ia.md` — JTBD ↔ nav ↔ doc/Mix mapping (must stay in sync when copy or routes change).
- `scrypath_ops/README.md` / `scrypath_ops/docs/SECURITY.md` — Host config and prod guard patterns from phase 44.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Stub LiveViews** — `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`, `failed_sync_live.ex`, `sync_drift_live.ex`: replace stub copy with assigns/streams wired to **`Scrypath.*`**.
- **Example integration patterns** — `examples/phoenix_meilisearch/` for conventional Phoenix wiring (reference only; OPSUI stays under **`scrypath_ops/`** per phase 44).

### Established patterns

- **`%Scrypath.Operator.Status{}`** — Backend task lists vs Oban queue lists are **already** separate; the UI must preserve that model.
- **`FailedSyncWorkInspection`** — Single snapshot for rows + rollups when **`reason_class_counts: true`**.
- **Report-first reconcile** — Default reconcile avoids live **`get_settings`** unless opted in; phase 45 follows that for default UX.

### Integration points

- **Host config** — `scrypath_ops/config/*.exs` and **`runtime.exs`** for allowlist + operator opts; no new secrets inside the **`scrypath`** package.
- **`operator-ia.md` table** — Update rows for jobs 1–3 when screens ship real data (phase 44 **D-08**).

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** gray areas in one pass with **subagent research** (schema allowlist, posture landing, failed-work parity, sync/drift composition); decisions above synthesize that research into one coherent architecture: **explicit config**, **honest per-schema signals**, **`FailedSyncWorkInspection` as default**, **reconcile default + lazy `index_contract_drift`**, **manual-first refresh** with optional slow polling while visible.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 46:** Bounded search playground and federation inspector (**OPSUI-04**..**05**).
- **Phase 47:** CI verification slice for OPSUI wiring (**OPSUI-10**).
- **Optional:** Single-call **`reconcile_sync(..., include_index_contract_drift: true)`** export or power tooling—only if a separate maintainer workflow needs one atomic JSON blob; not the default **`/ops/sync-drift`** load path.

### Reviewed Todos (not folded)

- None from **`todo.match-phase`**.

</deferred>

---

*Phase: 45-posture-failure-triage*
*Context gathered: 2026-04-21*
