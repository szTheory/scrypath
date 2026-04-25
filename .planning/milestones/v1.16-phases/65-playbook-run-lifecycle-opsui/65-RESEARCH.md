# Phase 65 — Technical research

**Question:** What do we need to know to plan playbook run lifecycle, async LiveView, and structured errors well?

## Phoenix LiveView async execution

- **`Phoenix.LiveView.start_async/3`** (LV 1.0+) runs work off the LV process; **`handle_async/3`** receives `{:ok, result}` | `{:exit, reason}` | `{:cancel, _}`.
- **`cancel_async/3`** cancels the named task; result must not be applied if cancelled — matches D-13 / D-08 / D-09 **`run_id`** guards.
- Tests: **`Phoenix.LiveViewTest.render_async/2`** (or `assert_async`) is the supported way to flush async work in tests after triggering events.

## Catalog vs preview run path

- Today **`handle_event("load", ...)`** + **`apply_decoded`** stages `draft_playbook`; **`handle_event("run", ...)`** calls **`Runner.run_validated/3`** synchronously.
- Plan: new **`run_now`** (or equivalent) event: read file → Jason.decode → **`V1.validate`** → assign `draft_playbook` + **`preview_json`** parity with load → **`start_async`** with same payload function as preview run — satisfies D-02 / D-03.

## Runner error vocabulary

- **`Runner.run_validated/3`** returns `{:error, reason}` with reasons including `{:config, atom}`, `{:page_size_out_of_range, n, max}`, `:invalid_playbook_shape`, `:playbook_not_validated`.
- Dispatch may return backend errors; stub uses e.g. **`{:error, :stub_hard_failure}`** for **`search_many`** when `:search_stub_variant` is **`:hard_error`** — good forced-failure fixture for registry + doc links (search mode may need a small stub extension or use `search_many` for failure tests).

## Documentation URLs

- CONTEXT mandates **`DocResolver`** with configurable base (Hex vs GitHub) + stable paths into `scrypath_ops/docs/` and guides — align new doc sections with **two-hop** rule (D-19): primary page has symptom → cause → fix; one deep link max.

## Telemetry

- Follow patterns in **`SearchPlayground`** / existing OPSUI if present: **`[:scrypath_ops, :playbook_run, start|stop]`** or namespaced events with metadata **`%{run_id, result, duration_ms}`** — keep events stable strings for dashboards (D-22).

---

## Validation Architecture

Execution feedback for Phase 65 is **automated-first**:

1. **Unit tests** — `ScrypathOps.Playbook.Runner` already has tests; add tests for new **`RunFailure`** / **`DocResolver`** pure functions (map shape, URL presence, allowlist stripping).
2. **LiveView tests** — extend **`playbook_live_test.exs`**: async run success (`render_async`), catalog **Run now** path, forced failure shows **non-empty** `failure_class` + **message** + **HTTP(S) `primary`** link string in HTML (or data attribute checked in test).
3. **CI gate** — **`mix verify.opsui`** (and default contributor path) must stay green after each wave.

Sampling: run **`mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`** after LiveView tasks; full **`mix verify.opsui`** before phase verify-work.

---

## RESEARCH COMPLETE
