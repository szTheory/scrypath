---
phase: 62
plan: "04"
status: complete
---

## Outcome

Upgraded **`PlaybookLive`** workspace list with **title** / **description** / mono basename rows (**Untitled playbook** default), **Rename** and **Duplicate** modals wired to **`Store.rename_workspace_file/3`** and **`duplicate_workspace_file/3`**, catalog reload after mutations, and **Save playbook to workspace** CTA copy.

## Key files

- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`

## Self-Check: PASSED

- `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — 0 failures
