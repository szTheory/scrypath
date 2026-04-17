# Phase 27 — Technical research

**Question:** What do we need to know to plan schema–index contract drift (read-only) well?

## RESEARCH COMPLETE

### Meilisearch contract surface (single HTTP read)

- `Client.get_settings/2` hits `GET /indexes/{uid}/settings` and returns one map (JSON body) containing both **attribute posture** (`searchableAttributes`, `filterableAttributes`, `sortableAttributes`, `faceting`, …) and **general settings** (`rankingRules`, `synonyms`, …) Scrypath already merges for apply/verify paths.
- **Implication (D-11):** One coordinated live snapshot per report is sufficient; split pure comparers afterward.

### Declared side (compile-time schema)

- `__scrypath__/1` exposes `:fields`, `:filterable`, `:sortable`, `:faceting`, `:settings` (`lib/scrypath/schema.ex`).
- **Settings wire:** `Settings.resolve/2` merges schema settings, config overrides, and facet-derived `filterable_attributes` entries — then `translate_settings/1` produces the Meilisearch wire map used by `verify_applied/3` and `compute_drift/2` (`lib/scrypath/meilisearch/settings.ex`).
- **Implication (D-12, D-13):** Reuse `resolve → translate_settings` and `compute_drift/2` for the settings slice; do not fork drift vocabulary. Add a focused test that given the same schema/config/index, the settings slice matches `Settings.verify_applied/3` / `mix scrypath.settings.diff` normalization.

### Live attribute lists vs declared

- Declared filterable/sortable are atom lists (or mixed in filterable for facet objects); Meilisearch returns string lists or structured filterable entries. Planning must include a **normalization layer** (pure functions) that:
  - Converts declared atoms to comparable string-or-structure form consistent with `translate_settings` output for filterable.
  - Compares **sets** (order-insensitive) where Meilisearch treats them as sets, but preserves enough structure to name **which** dimension diverged (DRIFT15-02).

### Operator integration points

- **Primary API:** New `Scrypath.Operator` function + `Scrypath` delegate, same `Config.resolve!` + `Keyword.split` pattern as `failed_sync_work/2` / `reconcile_sync/2` (`lib/scrypath/operator.ex`). Extend `@operator_only_opts` only if reconcile composition ships.
- **`%Reconcile{}`:** `@enforce_keys` must stay stable; optional field **outside** enforce_keys (Phase 26 pattern for `failed_work_counts`) for `index_contract_drift: nil | report` when `include_index_contract_drift: true` (D-04–D-06).
- **Vocabulary:** Keep `%Reconcile{}.drift_signals` operational-only; do not overload with contract atoms (CONTEXT D-02).

### Report shape (JSON / structs)

- Follow `%ReasonClassCounts{}` + `Jason.Encoder` with `Jason.OrderedObject` for stable keys (`lib/scrypath/operator/reason_class_counts.ex`).
- Per-axis explicit `match` / mismatch payload (CONTEXT D-08) — avoid encoding parity only as absent keys.

### Risks / pitfalls

- **404 index:** Mirror `verify_applied` — `{:error, :index_not_found}` or consistent `{:error, term()}` tuple; report must not partially fabricate live side.
- **Double GET:** `mix scrypath.settings.diff` may call `get_settings` twice on drift path; Phase 27 may leave optimization for backlog (CONTEXT deferred) unless trivial.

---

## Validation Architecture

**Nyquist Dimension 8 — automated feedback for this phase**

| Dimension | How it is satisfied |
|-----------|----------------------|
| Unit / pure | Table-test declared-vs-live comparers with **in-memory** maps/lists (no HTTP) for each contract dimension + settings slice using `compute_drift/2`. |
| Integration | Tests using existing test doubles (`__get_settings_response__` or Req test stubs) to assert full `index_contract_drift/2` pipeline returns `{:ok, %Report{}}` and stable JSON encoding. |
| Contract lock | Assert overlap with `Settings.verify_applied/3` / `compute_drift` for settings-only scenarios (D-13). |
| Default path | Test that `reconcile_sync/2` **without** `include_index_contract_drift: true` performs **no** extra settings GET (count stub invocations or refute unexpected calls). |

**Quick command:** `mix format --check-formatted && mix compile --warnings-as-errors`

**Focused tests:** `mix test test/scrypath/operator/index_contract_drift_test.exs` (path chosen in plan; adjust if module names differ)

**Full gate (Phase 28 adds verify.phase27):** For this phase execution, run the new test file plus `mix test test/scrypath/operator/` subset as specified in PLAN verification blocks.
