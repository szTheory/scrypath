# Phase 50 — Pattern map

**Purpose:** Closest analogs in-repo for accessibility + verification work (**OPSUX-06**, **OPSUX-07**).

## Shell / layout

| New / touched | Analog | Notes |
|---------------|--------|-------|
| Skip link + `main#ops-main` | `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` `:ops` branch | Today: `<main class="px-4…">` without stable id; add first-focus skip per **50-CONTEXT D-02**. |
| `aria-live` on flash | `core_components.ex` `flash_group` | Polite live region precedent — coordinate new status regions (**D-10**). |

## LiveView + HEEx

| Surface | File | Pattern to extend |
|---------|------|-------------------|
| Posture | `live/posture_live.ex` (`render/1` HEEx) | `ops_page_header`, panels; evolve `aria-label` regions → `section` + `h2` + `aria-labelledby` (**D-04**). |
| Failed sync | `live/failed_sync_live.ex` | Tables: semantic `<table>`, sort `<button>` in `<th>` when sort exists, **`aria-sort`** (**D-12**–**D-13**). |
| Sync / drift | `live/sync_drift_live.ex` | Same table discipline; expandable rows (**D-14**). |
| Search | `live/search_live.ex` | Single outer `<.form>` in `render/1`; add **`fieldset`/`legend`** chapters (**D-06**–**D-08**); narrow **`aria-live`** (**D-10**). |

## Tests

| New work | Analog | Command |
|----------|--------|---------|
| DOM semantics contracts | `ops_shell_contract_test.exs`, `operator_ia_contract_test.exs` | `Phoenix.LiveViewTest` + `has_element?/2`; optional Floki on `render/1` (**D-18**). |
| Canonical verify | `lib/mix/tasks/verify.opsui.ex` (repo root) | Document + optional `@tag :opsui_a11y` subset (**D-19**, **50-RESEARCH**). |

---

## PATTERN MAPPING COMPLETE
