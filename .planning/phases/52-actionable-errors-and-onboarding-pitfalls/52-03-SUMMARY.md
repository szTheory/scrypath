---
phase: 52-actionable-errors-and-onboarding-pitfalls
plan: "03"
subsystem: docs
requirements-completed: [ONBD-06]
key-files:
  modified:
    - lib/scrypath.ex
    - lib/mix/tasks/scrypath.status.ex
    - lib/mix/tasks/scrypath.reconcile.ex
    - lib/mix/tasks/scrypath.retry.ex
    - lib/mix/tasks/scrypath.failed.ex
    - test/scrypath/docs_contract_test.exs
completed: 2026-04-22
---

# Phase 52 plan 03 summary

Reframed **`Scrypath`** **`@moduledoc`** as the library lobby (product narrative, ordered **Read next** links with **`guides/golden-path.md`** before **`guides/sync-modes-and-visibility.md`**, overview + common-mistakes pointers, **`Scrypath.Schema`** deferral). Mirrored the same two-hop block on **`scrypath.status`**, **`scrypath.reconcile`**, **`scrypath.retry`**, and **`scrypath.failed`**. Added a **`DocsContractTest`** guard so the lobby cannot silently reorder those anchors.

## Task commits

1. **Lobby moduledoc** — `9920509`
2. **Operator Mix task moduledocs** — `93b3bd5`
3. **Contract test** — `d4c0b1f`

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` — pass
