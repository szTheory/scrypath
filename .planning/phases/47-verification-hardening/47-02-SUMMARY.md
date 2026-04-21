---
phase: 47
plan: "02"
completed: 2026-04-21
---

# Plan 47-02 summary

## Delivered

- **`Mix.Tasks.Verify.Opsui`** (`lib/mix/tasks/verify.opsui.ex`): runs the same **`mix deps.get` + `mix test`** sequence as CI from **`scrypath_ops/`**, with **`CI=true`** and stdin guard so Hex does not block non-interactive shells.
- **`preferred_envs`** entry **`"verify.opsui": :test`** in root **`mix.exs`**.
- **`.formatter.exs`** inputs extended for **`scrypath_ops/{config,lib,test}`** and **`scrypath_ops/mix.exs`**.
- **`CONTRIBUTING.md`**: **`mix verify.opsui`** plus **`scrypath-ops`** / **`scrypath-ops-path-check`** CI table row.

## Key files

- `lib/mix/tasks/verify.opsui.ex`
- `mix.exs`
- `.formatter.exs`
- `CONTRIBUTING.md`

## Self-Check: PASSED

- `mix verify.opsui` and `mix format --check-formatted` green after related changes.
