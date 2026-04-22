---
phase: 62
plan: "02"
type: execute
wave: 1
depends_on: []
files_modified:
  - scrypath_ops/lib/scrypath_ops/playbook/store.ex
  - scrypath_ops/test/scrypath_ops/playbook/store_test.exs
autonomous: true
requirements:
  - OPS2-02
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-62-02: Path traversal on rename/duplicate | Reuse **`resolved_path/2`** for both source and target; reject unless `under_root?/2`. |
| T-62-02: Target overwrite by accident | **`rename_workspace_file/3`**: if destination exists → **`{:error, :target_exists}`** (no overwrite). |
</threat_model>

<objective>
Add **`ScrypathOps.Playbook.Store`** APIs to **rename** and **duplicate** workspace JSON files using basename-only arguments, preserving the existing traversal controls and collision semantics from CONTEXT (rename target exists = error).
</objective>

<tasks>
<task id="62-02-01" type="execute">
<read_first>
- scrypath_ops/lib/scrypath_ops/playbook/store.ex
- scrypath_ops/test/scrypath_ops/playbook/store_test.exs
- .planning/phases/62-playground-capture-and-playbook-catalog/62-CONTEXT.md
</read_first>
<action>
1. Add **`rename_workspace_file(root, from_name, to_name)`** → `:ok | {:error, term()}`:
   - Require **`safe_basename?/1`** for both names.
   - Resolve both paths; if `to_name` path exists on disk → **`{:error, :target_exists}`**.
   - Use **`File.rename/2`** from source resolved path to target; map POSIX errors to `{:error, :rename_failed}` or similar single tag.
2. Add **`duplicate_workspace_file(root, from_name, to_name)`** → `:ok | {:error, term()}`:
   - Read source via **`read_workspace_file/2`**; write via **`save_workspace_file/3`** (overwrite rule: if `to_name` exists → **`{:error, :target_exists}`** before write).
3. Add helper **`suggest_duplicate_basename(root, from_name)`** optional in same module: strip `.json`, compute next free **`"{stem}-#{n}.json"`** for **`n ≥ 1`** using **`list_workspace_json/1`** (CONTEXT D-14).
4. Extend **`store_test.exs`** with `tmp_dir` fixtures: rename success; rename collision; duplicate success; duplicate collision; unsafe basename rejected.
</action>
<acceptance_criteria>
- `grep -n 'rename_workspace_file' scrypath_ops/lib/scrypath_ops/playbook/store.ex` returns at least one **`def rename_workspace_file`** line.
- `grep -n 'duplicate_workspace_file' scrypath_ops/lib/scrypath_ops/playbook/store.ex` returns at least one **`def duplicate_workspace_file`** line.
- `mix test scrypath_ops/test/scrypath_ops/playbook/store_test.exs` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `mix test scrypath_ops/test/scrypath_ops/playbook/store_test.exs`.
</verification>

<success_criteria>
- Rename and duplicate are basename-safe and fail closed on target collision.
</success_criteria>

<must_haves>
- OPS2-02 filesystem operations with **`safe_basename?`** parity to save/delete.
</must_haves>

## PLANNING COMPLETE
