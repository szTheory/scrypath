# Phase 62 — Pattern map

Analogues for new / touched files (from CONTEXT + codebase scan).

| Planned surface | Role | Closest analog | Excerpt / convention |
|-----------------|------|----------------|----------------------|
| `v1.ex` top-level allow-list | strict codec | existing `@search_top` / `validate_top_level_keys/1` | Reject extras; string keys only |
| `store.ex` mutations | path-safe FS | `resolved_path/2` + `save_workspace_file/3` | `safe_basename?` before any IO |
| `search_live.ex` capture | LV form + assign pipeline | `playbook_live.ex` `apply_decoded/3`, preview `pre.max-h-96` | Validate with `V1.validate/1` before treating as draft |
| `playbook_live.ex` list rows | catalog + row actions | current `phx-click="load"` row + delete modal | `btn-ghost` / `btn-error btn-outline` row actions |
| JSON preview marker | test hook | `data-testid="playbook-preview-marker"` | Reuse string **Validated playbook preview** for capture preview |

## Files likely created or modified

- `scrypath_ops/lib/scrypath_ops/playbook/v1.ex`
- `scrypath_ops/lib/scrypath_ops/playbook/store.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`
- `scrypath_ops/docs/playbook-schema-v1.md`
- `scrypath_ops/test/scrypath_ops/playbook/v1_test.exs`
- `scrypath_ops/test/scrypath_ops/playbook/store_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`

---

## PATTERN MAPPING COMPLETE
