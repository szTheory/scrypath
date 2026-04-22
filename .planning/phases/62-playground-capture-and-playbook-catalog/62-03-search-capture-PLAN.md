---
phase: 62
plan: "03"
type: execute
wave: 2
depends_on:
  - "01"
files_modified:
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
autonomous: true
requirements:
  - OPS2-01
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-62-03: Serializing backend secrets into JSON | Only persist fields already allowed by **`V1`** / search opts allow-lists; never add raw **`scrypath_opts`** keyword to JSON. |
| T-62-03: XSS in title/description | Render via HEEx text interpolation only (no `raw/1`); user input is plain text. |
</threat_model>

<objective>
On **`SearchLive`**, implement **Save search as playbook**: keep last successful dispatch **inputs** per mode, clear them on mode switch and mount, let operators set **title** / **description** (Phase 62 UI — **no tag authoring UI**), preview JSON validated by **`V1.validate/1`**, and save to workspace via **`Store.save_workspace_file/3`** with basename validation.
</objective>

<tasks>
<task id="62-03-01" type="execute">
<read_first>
- scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
- scrypath_ops/lib/scrypath_ops/playbook/v1.ex
- scrypath_ops/lib/scrypath_ops/playbook/store.ex
- scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
- .planning/phases/62-playground-capture-and-playbook-catalog/62-UI-SPEC.md
- scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
</read_first>
<action>
1. Add assigns e.g. **`:capture_draft`**, **`:capture_preview_json`**, **`:capture_preview_ok?`**, **`:capture_title`**, **`:capture_description`**, **`:capture_basename`** (exact names flexible but must exist as documented in SUMMARY).
2. After **`{:ok, _}`** dispatch in **`run_single`** / **`run_multi`**, store a plain map (string keys) buildable into a valid **`search` / `search_many`** playbook **without** metadata; merge operator title/description (and omit **`tags`** key in UI-generated JSON for Phase 62, or set `[]` only if required — follow CONTEXT D-06: codec accepts tags but LV does not author them — **omit `tags` key** when empty).
3. **`mount/3`**: set capture assigns to empty/nil per CONTEXT D-10. **`handle_event("set_mode", ...)`** path and **`handle_params`** when mode value changes: clear capture source D-09.
4. At start of **`handle_event("search", ...)`** pipeline where results cleared, also clear capture draft so stale capture is not saved after failed runs (align with “latest successful”).
5. HEEx: new card **below** `#search-honesty-panel` (or existing honesty id — locate actual id in file) with primary copy **Save search as playbook**; empty state copy includes **Run a search first** per UI-SPEC; preview **`pre`** uses **`max-h-96 overflow-auto rounded-md bg-base-200 p-sm text-xs font-mono`**. On successful validation show marker text **Validated playbook preview** with **`data-testid`** matching playbook preview pattern where applicable.
6. Save handler: if workspace not configured, flash error using UI-SPEC substring **`Playbook workspace is not configured`** OR documented env name from spec; on basename collision use substring **`That playbook name is already in use`**.
7. Tests: at minimum one test that stubbed successful search sets capture assign and preview validates; align with existing conn setup in **`search_live_test.exs`**.
</action>
<acceptance_criteria>
- `grep -n 'Save search as playbook' scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` finds at least one occurrence in **`~H"""`** template.
- `grep -n 'Run a search first' scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` finds at least one occurrence.
- `mix test scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `mix test scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` then `mix compile --warnings-as-errors` in **`scrypath_ops`** if that is the project standard (else `mix compile`).
</verification>

<success_criteria>
- Operators can preview and save a playbook derived from the last successful playground run without hand-writing JSON.
</success_criteria>

<must_haves>
- OPS2-01 capture + preview + save path on **`/ops/search`**.
- Clear capture state on mount and mode change per CONTEXT D-09–D-10.
</must_haves>

## PLANNING COMPLETE
