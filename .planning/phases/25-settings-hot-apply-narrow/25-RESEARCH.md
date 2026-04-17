# Phase 25 — Technical Research

**Phase:** 25 — Settings hot apply (narrow)  
**Question:** What do we need to know to plan implementation well?

## Summary

Replace the `hot_apply/3` stub with a **bounded** PATCH path: only canonical keys `:synonyms`, `:stop_words`, and `:typo_tolerance` may appear in the hot payload. Reuse `translate_settings/1` on a **filtered** canonical map so wire shape matches managed `apply/3`. Reuse `Client.update_settings/3` + `Meilisearch.normalize_task/1` + `Tasks.wait_for_task/2` for the same async semantics as other mutating calls. Enforce **`acknowledge_live_index: true`** in the options keyword before any HTTP. Validate **before** `update_settings`; on backend failure normalize into **`{:error, {:hot_apply_failed, details}}`** per CONTEXT. Do **not** call `verify_applied/3` by default after success (D-10). Emit **`Telemetry.span`** on the hot path with stable event name under `[:scrypath, :settings, :hot_apply]` (or sibling to `[:scrypath, :reindex, ...]`).

## Meilisearch API

- `PATCH /indexes/{uid}/settings` accepts a **partial** JSON object; omitted keys are unchanged ([settings API](https://www.meilisearch.com/docs/reference/api/settings)).
- Response includes `taskUid`; poll `/tasks/{uid}` until terminal state — already implemented in `Scrypath.Meilisearch.Tasks.wait_for_task/2`.

## Codebase anchors

| Concern | Location | Notes |
|--------|----------|-------|
| Stub to replace | `lib/scrypath/meilisearch/settings.ex` `hot_apply/3` | Currently `{:error, :hot_apply_disabled}` |
| PATCH + GET | `lib/scrypath/meilisearch/client.ex` | `update_settings/3`, `get_settings/2` |
| Task wait + telemetry | `lib/scrypath/meilisearch/tasks.ex` | `wait_for_task/2`, `[:scrypath, :meilisearch, :task_wait]` |
| Synonym expansion | `Settings.translate_settings/1` | Already expands list-of-groups synonyms |
| Operator CLI pattern | `lib/mix/tasks/scrypath.settings.diff.ex`, `scrypath.settings.read.ex` | `OperatorTask.parse!/2`, `Config.resolve!/1`, exit codes |
| Integration harness | `test/support/meilisearch_integration.ex`, `test/scrypath/search_many_integration_test.exs` | `@moduletag :integration`, `SCRYPATH_INTEGRATION` |

## Error atoms (proposal)

- Missing ack: **`{:error, :live_ack_required}`** (grep-able, stable).
- Bad keys: **`{:error, {:unsupported_hot_apply_keys, keys}}`** with `keys` sorted/deduped **atoms** (or uniform type — planner locks one).
- Post-validation failures: **`{:error, {:hot_apply_failed, details}}`** where `details` is a small map (`:code`, `:message`, `:task_uid`, `:raw` subset) derived from `{:http_error, status, body}` or task failure payload.

## Non-goals (locked)

- No `ranking_rules`, `distinct_attribute`, or other keys on hot path (TUNE14-01, REQUIREMENTS out-of-scope table).
- No default full `verify_applied/3` after hot apply (25-CONTEXT D-10).
- Optional subset verify (D-11) **deferred** unless trivial — do not block Phase 25.

## Risks

- **False drift:** if callers chain `verify_applied/3` after hot apply without reading docs — mitigated by TUNE14-02 guide table.
- **Empty PATCH:** sending `{}` after filtering — validate at least one allow-listed key present with a value worth sending, or document idempotent no-op; recommend explicit error `:empty_hot_apply_payload` if map empty after extraction.

## Validation Architecture

Execution should sample feedback on three dimensions:

1. **Correctness (TUNE14-01):** Unit tests in `test/scrypath/meilisearch/settings_test.exs` for validation order, ack gate, unsupported keys aggregation, and **no** `update_settings` calls on fakes when validation fails. Integration module (new or extended) exercises real Meilisearch with `@moduletag :integration` when `SCRYPATH_INTEGRATION=1`.
2. **Operator ergonomics:** `mix scrypath.settings.hot_apply` requires `--ack-live`, mirrors diff/read exit semantics (`OperatorTask.error!/2`), prints task UID on success.
3. **Documentation contract (TUNE14-02):** `guides/relevance-tuning.md` section with hot vs managed table + explicit non-goals; CHANGELOG Unreleased bullet for real `hot_apply` replacing stub.

After each plan wave: `mix test` scoped to touched test files; before phase sign-off: `mix format --check-formatted` and full `mix test` (or integration subset per `test_helper.exs`).

## RESEARCH COMPLETE
