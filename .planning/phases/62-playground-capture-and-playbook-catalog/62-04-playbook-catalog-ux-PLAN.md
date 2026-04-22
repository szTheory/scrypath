---
phase: 62
plan: "04"
type: execute
wave: 3
depends_on:
  - "01"
  - "02"
files_modified:
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
autonomous: true
requirements:
  - OPS2-02
  - OPS2-03
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-62-04: Destructive rename without confirm | Rename on collision = **error flash only** (CONTEXT D-13); no overwrite modal in Phase 62. For duplicate, non-destructive. |
| T-62-04: LV crash on corrupt JSON | Rescue decode/validate per row; show basename + muted error without dropping whole page. |
</threat_model>

<objective>
Upgrade **`PlaybookLive`** catalog list/detail to show **title** (primary) and **description** (secondary, truncated) with **Untitled playbook** default; add **Rename** and **Duplicate** row actions wired to **`Store.rename_workspace_file/3`** and **`duplicate_workspace_file/3`** with modals/flows per **62-UI-SPEC.md** and CONTEXT D-13–D-15; align save CTA copy toward **Save playbook to workspace** where that string already exists in spec.
</objective>

<tasks>
<task id="62-04-01" type="execute">
<read_first>
- scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
- scrypath_ops/lib/scrypath_ops/playbook/store.ex
- scrypath_ops/lib/scrypath_ops/playbook/v1.ex
- scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
- .planning/phases/62-playground-capture-and-playbook-catalog/62-UI-SPEC.md
</read_first>
<action>
1. When listing workspace files, for each **`name`**, **`read_workspace_file`** + **`Jason.decode`** + **`V1.validate`** (or decode-only + shallow key read if validate too strict for broken files — prefer validate: on `{:error,_}` show row with **Untitled playbook** and no description rather than crashing).
2. Render row: line1 = **`title` or "Untitled playbook"`**; line2 = truncated description; keep basename in **`font-mono text-xs`** per UI-SPEC §Interaction 3.
3. Add **Duplicate** flow: pre-fill suggested basename from **`suggest_duplicate_basename/2`** if implemented in Plan 02; else inline **`{stem}-1.json`** algorithm; editable input; commit calls **`duplicate_workspace_file`**; success refreshes list.
4. Add **Rename** flow: modal with old name display + new basename input; on submit call **`rename_workspace_file`**; surface **`{:error, :target_exists}`** with flash/body containing **That playbook name is already in use** per UI-SPEC.
5. Unify button copy: change section heading + button from **Save playbook to disk** to **Save playbook to workspace** (and matching submit label) per UI-SPEC FLAG resolution.
6. Tests in **`playbook_live_test.exs`**: list shows Untitled for legacy JSON without title; duplicate creates second file; rename collision shows error substring.
</action>
<acceptance_criteria>
- `grep -n 'Untitled playbook' scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` has ≥ 1 match in **`~H"""`**.
- `grep -n 'Save playbook to workspace' scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` has ≥ 1 match.
- `grep -n 'rename_workspace_file' scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` has ≥ 1 reference (call or handle_event branch).
- `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` then `mix verify.opsui`.
</verification>

<success_criteria>
- Catalog is legible without opening raw JSON for normal files.
- Rename/duplicate behave on happy path and collision path.
</success_criteria>

<must_haves>
- OPS2-02 rename + duplicate with safe basenames.
- OPS2-03 list presentation with documented default for legacy files.
</must_haves>

## PLANNING COMPLETE
