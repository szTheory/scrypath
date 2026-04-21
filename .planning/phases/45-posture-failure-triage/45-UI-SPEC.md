# Phase 45 — UI design contract (Posture & failure triage)

**Selected framework:** Phoenix LiveView 1.8+ (same stock patterns as phase 44)

**Status:** Ready for planning  
**Source:** `45-CONTEXT.md` (D-04–D-19) + ROADMAP OPSUI-01..03

---

## Product surface

- **Audience:** Operators triaging sync posture and failed work; same assumptions as phase 44 shell.
- **Routes (existing):** `/ops/posture`, `/ops/failed-sync`, `/ops/sync-drift` — replace stub copy with **read-only** data from **`Scrypath.sync_status/2`**, **`Scrypath.failed_sync_work/2`**, **`Scrypath.reconcile_sync/2`**, **`Scrypath.index_contract_drift/2`** per CONTEXT.
- **Depth:** Real tables and controls for refresh; **no** retry/reindex/write verbs (links to Mix + guides only).

---

## Information architecture

**Canonical doc:** `scrypath_ops/docs/operator-ia.md` — update JTBD rows for jobs 1–3 when screens ship (phase 44 D-08 / phase 45 CONTEXT).

**Per screen:**

| Route | Primary job | Key signals |
|-------|-------------|-------------|
| `/ops/posture` | Fleet posture | Per allowlisted schema: index UID, `sync_mode`, backend vs queue counts and last success, `queue.observed?` honesty, row-level `{:ok, Status}` vs `{:error, _}` |
| `/ops/failed-sync` | Failed work triage | `failed_sync_work(..., reason_class_counts: true)` → `%FailedSyncWorkInspection{}`; rollup strip from `counts`; table parity with `mix scrypath.failed`; compact toggle hides strip visually only |
| `/ops/sync-drift` | Sync + contract drift context | Section A: `reconcile_sync/2` **without** `include_index_contract_drift: true` on default load; Section B: `index_contract_drift/2` only after explicit “Load contract drift”; scoped errors; doc/Mix links |

---

## Visual and layout

- **Posture (OPSUI-01):** Dense **sortable** table default; expandable row or side detail for backend vs queue breakdown; cards-only **not** primary fleet view.
- **Failed sync (OPSUI-02):** Table + header rollup strip (`reason_class`); `:unknown` labeled explicitly.
- **Sync/drift (OPSUI-03):** Two **labeled** sections; neutral empty states; timestamps on successful loads.

---

## Interaction patterns

- **Refresh:** Manual refresh **primary** on all three screens; optional slow auto-refresh (30–60s) **only while tab visible**, default **off** in prod until characterized.
- **Concurrency:** Staggered per-schema fetches with bounded concurrency, per-schema timeout, overall deadline (`Task.async_stream` pattern).
- **Telemetry (UI-originated):** Low-cardinality only (refresh outcome, schema count, duration) — **not** per-schema module names on hot paths (`docs/search-backend-sre.md`).
- **Streams:** `stream_*` reserved for long `State` lists in drill-down; landing assigns stay small.

---

## Accessibility (baseline)

- Sort controls and refresh buttons have visible text; tables use `<th>` scope where applicable; expanded panels keyboard-reachable.

---

## Out of scope (explicit)

- Recovery buttons, Oban.Web, LiveDashboard in `/ops`, search/federation UI (phase 46), CI hardening slice (phase 47).
- Runtime discovery of schema modules without allowlist (CONTEXT D-01).

---

*UI-SPEC for phase 45 — aligns plans with OPSUI-01, OPSUI-02, OPSUI-03.*
