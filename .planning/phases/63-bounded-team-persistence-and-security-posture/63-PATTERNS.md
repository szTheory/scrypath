# Phase 63 — Pattern map

Analogs and excerpts for executors (from CONTEXT + codebase).

## Mix tasks (`scrypath_ops`)

- **Pattern:** `lib/mix/tasks/scrypath_ops/check_nav_contract.ex` — `use Mix.Task`, `@shortdoc`, `run/1`, raise on failure.
- **Apply:** New playbook directory validator should follow the same module naming (`Mix.Tasks.ScrypathOps.*`) and live under `scrypath_ops/lib/mix/tasks/`.

## PLAN.md structure

- **Pattern:** `.planning/phases/62-playground-capture-and-playbook-catalog/62-01-playbook-v1-metadata-PLAN.md` — YAML frontmatter (`phase`, `plan`, `wave`, `requirements`, `autonomous`), `<threat_model>` table, single `<task>` with `<read_first>`, `<action>`, `<acceptance_criteria>`, closing `## PLANNING COMPLETE`.

## Playbook codec

- **`ScrypathOps.Playbook.V1`:** `decode/1` → `validate/1`; tests in `scrypath_ops/test/scrypath_ops/playbook/v1_test.exs`.
- **`Store`:** `list_workspace_json/1`, `read_workspace_file/2`, `save_workspace_file/3`, `delete_workspace_file/2` — all basename-only.

## LiveView destructive flow

- **`PlaybookLive`:** `request_delete` → modal → `confirm_delete` with exact string match before `Store.delete_workspace_file/2`.

## PATTERN MAPPING COMPLETE
