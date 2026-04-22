---
phase: 62
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - scrypath_ops/lib/scrypath_ops/playbook/v1.ex
  - scrypath_ops/docs/playbook-schema-v1.md
  - scrypath_ops/test/scrypath_ops/playbook/v1_test.exs
autonomous: true
requirements:
  - OPS2-03
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-62-01: Untrusted JSON expanded into atoms / crash | Keep **string keys** only; no `String.to_atom` on user fields. |
| T-62-01: Oversized metadata DoS | Enforce **max lengths** and tag count in `V1` validators (reject, not truncate silently). |
| T-62-01: Unknown keys slipping into persisted files | `validate_top_level_keys/1` must list new keys explicitly for **both** modes. |
</threat_model>

<objective>
Extend **`playbook_format: 1`** so optional **`title`**, **`description`**, and **`tags`** pass `ScrypathOps.Playbook.V1.validate/1`, remain strict on unknown keys, and are documented in **`playbook-schema-v1.md`** with legacy-default semantics for missing keys.
</objective>

<tasks>
<task id="62-01-01" type="execute">
<read_first>
- scrypath_ops/lib/scrypath_ops/playbook/v1.ex
- scrypath_ops/docs/playbook-schema-v1.md
- scrypath_ops/test/scrypath_ops/playbook/v1_test.exs
- .planning/phases/62-playground-capture-and-playbook-catalog/62-CONTEXT.md
</read_first>
<action>
1. In **`v1.ex`**, extend `@search_top` and `@search_many_top` to include **`"title"`**, **`"description"`**, and **`"tags"`** (exact strings) after the existing keys for each mode.
2. Add private validators invoked from `validate/1` pipeline after `validate_top_level_keys/1` (or inside `validate_by_mode` return path) so that:
   - Absent keys → OK.
   - **`title`** / **`description`**: when present, must be **binary** with byte size **≤ 200** for title, **≤ 2000** for description (UTF-8 byte length).
   - **`tags`**: when present, must be a **list** of **≤ 20** binaries, each **≤ 64** bytes, non-empty strings; reject wrong shapes with tagged `{:invalid_playbook, {:invalid_metadata, ...}}` reasons consistent with existing error style.
3. Update **`playbook-schema-v1.md`** with a **“Operator metadata (optional)”** section documenting the three keys, caps above, and that listings treat missing title as **Untitled playbook** (per CONTEXT D-05).
4. Add ExUnit cases in **`v1_test.exs`**: valid playbook with all three keys; reject unknown key still; reject oversized title; reject `tags` with 21 entries; golden path existing minimal search playbook unchanged.
</action>
<acceptance_criteria>
- `grep -n 'title' scrypath_ops/lib/scrypath_ops/playbook/v1.ex` shows **`"title"`** in both `@search_top` and `@search_many_top` attribute lists (or equivalent module attributes feeding them).
- `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` exits **0**.
- `scrypath_ops/docs/playbook-schema-v1.md` contains the heading **`Operator metadata`** (or **`## Operator metadata`**) and the substring **`Untitled playbook`**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` and confirm no compiler warnings introduced in `v1.ex`.
</verification>

<success_criteria>
- `V1.validate/1` accepts optional metadata on both modes and rejects bad shapes.
- Schema doc matches codec allow-list and documents caps.
</success_criteria>

<must_haves>
- OPS2-03 wire format for title/description/tags without bumping **`playbook_format`**.
</must_haves>

## PLANNING COMPLETE
