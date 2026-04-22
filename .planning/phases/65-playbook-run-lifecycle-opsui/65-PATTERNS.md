# Phase 65 — Pattern map

Analogs and anchors for implementation.

## LiveView playbook surface

| New / changed | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| Async run + state machine | Session-scoped UX | `playbook_live.ex` `handle_event("run", ...)` today | Replace synchronous `Runner.run_validated` body with `start_async` + `handle_async` |
| Catalog row actions | Mutation + navigation | `phx-click="load"` block ~L635 | Add sibling button **`run_now`** with new event |
| Alerts / flash | Feedback | `put_flash` + `alert alert-error` in render | Flash stays supplemental; terminal state in assigns (CONTEXT D-11) |

## Error formatting

| New / changed | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| Run failure map | Pure transform | `format_run_flash/1` private fns in `playbook_live.ex` | Extract to **`ScrypathOps.Playbook.RunFailure`** (name per plan) + registry table |
| Doc URLs | Configurable links | `@guide_href` module attribute | Replace ad hoc with **`DocResolver`** reading `:playbook_doc_base` or similar from `Application.get_env` |

## Tests

| New / changed | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| Async LV test | Determinism | `playbook_live_test.exs` sync `render_click` | Add **`render_async`** after run trigger |
| Stub failure | Forced `{:error, _}` | `search_live_test.exs` `:hard_error` | Reuse `:search_stub_variant` for `search_many` failure playbook JSON |

## PATTERN MAPPING COMPLETE
