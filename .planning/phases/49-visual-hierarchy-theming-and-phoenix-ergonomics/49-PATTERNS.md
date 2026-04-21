# Phase 49 — Pattern Map

Analogs and extension points for executor agents.

---

## Layout and shell

| Target | Role | Closest analog | Notes |
|--------|------|----------------|-------|
| `layouts.ex` `app/1` `:ops` clause | Global ops chrome | Same file `:default` clause | Add attrs/slots only to `:ops`; keep **`Nav.primary/0`** loop intact (**Phase 48**). |
| `root.html.heex` | Document head, theme bootstrap | Current inline IIFE | Extend cautiously; preserve **`phx:theme`** / **`data-theme`** semantics. |
| `app.css` | Tailwind + daisyUI | Lines 94–100 variants | **`@custom-variant dark`** is the lever for **D-07**. |

---

## Components

| Target | Role | Closest analog | Notes |
|--------|------|----------------|-------|
| New **`OpsUi`** HEEx functions | Page scaffold | `core_components.ex` `flash`, `icon`, table helpers | Use **`use ScrypathOpsWeb, :html`** + **`embed_templates`** or function components alongside **`CoreComponents`** imports in LiveViews. |
| Severity banners | Posture / search warnings | daisyUI **`alert`**, existing `alert-*` in LiveViews | Map degraded → `alert-warning`, failed → `alert-error` per **D-11**. |

---

## LiveViews

| File | Pattern | Notes |
|------|---------|-------|
| `posture_live.ex` | `Layouts.app` + assigns | JTBD summary blocks → wrap with **`ops_panel`** / headers. |
| `failed_sync_live.ex` | Table-heavy | **`text-sm`**, **`tabular-nums`**, **`overflow-x-auto`** wrapper. |
| `sync_drift_live.ex` | Forms + tables | Same density patterns. |
| `search_live.ex` | Playground + inspector | Pass **`ops_main_width={:wide}`** (name per implementation); nested function components (`empty_or_hits_single`) stay colocated or move carefully. |

---

## Tests

| Target | Analog |
|--------|--------|
| `ops_shell_contract_test.exs` (new) | `operator_ia_contract_test.exs` structure — **assert structure only**, not nav labels/order (**D-19**). |

---

## PATTERN MAPPING COMPLETE
