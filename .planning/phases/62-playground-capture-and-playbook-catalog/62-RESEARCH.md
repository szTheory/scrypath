# Phase 62 — Technical research

**Question:** What do we need to know to plan playground → playbook capture, catalog metadata, and rename/duplicate well?

## RESEARCH COMPLETE

### Codec (`ScrypathOps.Playbook.V1`)

- Top-level keys are mode-specific lists `@search_top` / `@search_many_top`; extras fail with `{:unknown_top_level_keys, extras}`.
- Optional metadata (`title`, `description`, `tags`) must be added to **both** mode lists and validated: strings for title/description; `tags` optional array of strings with bounded count/length (CONTEXT D-04).
- `validate_top_level_keys/1` runs before `validate_by_mode/1`; optional keys should not require presence.
- `encode/1` assumes input already passed `validate/1` — capture flow must call `validate/1` before preview/save (same as `PlaybookLive.apply_decoded/3`).

### Store (`ScrypathOps.Playbook.Store`)

- `safe_basename?/1` regex `\A[\w.\-]+\.json\z` — reuse for all new file ops.
- `save_workspace_file/3`, `read_workspace_file/2`, `delete_workspace_file/2` exist; **rename** = atomic preference `File.rename(src, dst)` after `resolved_path` checks for both, or read+write+delete if cross-filesystem — prefer `File.rename` when same root.
- **Duplicate**: read JSON → optionally merge metadata from form → `save_workspace_file` with generated `{stem}-{n}.json` (CONTEXT D-14); never overwrite without explicit destructive path.

### Search playground (`SearchLive` + `SearchPlayground`)

- Single run: `run_single/6` sets `:result_single`, uses `build_opts/2` → keyword merged into `dispatch_search(mod, q, opts)`.
- Multi run: `entries = Enum.map(selected, fn mod -> {mod, q, []} end)` then `dispatch_search_many(entries, opts)`.
- Capture payload must mirror **inputs** only (schema module → string via same helper as forms, `q`, `page_size` → `opts` shape with string keys in JSON). Federation keys already flow through `params` in multi branch — research `search_live.ex` `run_multi` for full `opts` construction vs playbook `opts` (shared vs entry) to stay aligned with `Runner.build_dispatch_opts` expectations.
- **Clear rules** (CONTEXT): assign `playbook_capture_source` (or similar) on successful dispatch; `nil` on `mount`, on `set_mode`, on `handle_params` mode change, and at start of `search` event before re-run (already clears results).

### Playbook UI (`PlaybookLive`)

- List today is basename-only `menu` rows — needs secondary fetch: `read_workspace_file` + `Jason.decode` + `V1.validate` to read `title`/`description` (or skip validate for display-only if file corrupt — prefer validate and show error row vs crashing LV).
- Delete modal pattern is the template for any new destructive modal.
- Preview uses `max-h-96`, `data-testid="playbook-preview-marker"` — reuse for capture preview on Search.

### Testing

- `scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` — extend for metadata.
- `store_test.exs` — add rename/duplicate coverage with tmp dir.
- `search_live_test.exs` / `playbook_live_test.exs` — LV tests with stub backend (`Phoenix.LiveViewTest`) following existing patterns; `mix verify.opsui` is the contributor gate.

### Risks

- **Partial multi-search:** `{:ok, %MultiSearchResult{failures: failures}}` with non-empty failures still counts as dispatch success — product decision: CONTEXT D-08 says “latest successful run”; treat `{:ok, _}` as capturable, document partial semantics in playbook JSON if needed (likely OK — inputs still valid).
- **Keyword vs string opts:** Ensure serialized `opts` in playbook map use **string keys** at every level expected by `V1` (Runner already consumes string-keyed maps).

---

## Validation Architecture

Execution should keep **fast feedback** on the Elixir test surface:

1. **Unit / property:** `Playbook.V1` — unknown keys rejected; optional `title`/`description`/`tags` accepted when well-formed; existing fixtures unchanged.
2. **Unit:** `Playbook.Store` — rename collision, duplicate `stem-1.json` / `stem-2.json`, traversal rejected.
3. **LiveView:** Search capture assigns + at least one happy-path save with `TmpDir`; playbook list shows title default for legacy JSON missing keys.
4. **Gate:** `mix test scrypath_ops/test/...` scoped per plan; full `mix verify.opsui` before phase verify-work.

Nyquist dimension 8 (validation) is satisfied by mapping each plan’s tasks to ExUnit commands in `62-VALIDATION.md`.

---

*Phase 62 — research for planning — 2026-04-22*
