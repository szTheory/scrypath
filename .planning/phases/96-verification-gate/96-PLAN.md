# Plan: Phase 96 Verification Gate

Goal: All new facet value search surfaces are regression-guarded by a single hermetic task.

## Tasks

### 1. Verification Task Implementation
- [ ] Create `lib/mix/tasks/verify.phase96.ex`.
- [ ] Implement `run/1` to execute focused tests:
  - `test/scrypath/search_test.exs`
  - `test/scrypath/meilisearch_test.exs`
  - `test/scrypath/docs_contract_test.exs`
- [ ] Include `mix docs --warnings-as-errors` in the task.

### 2. Documentation & Contract Updates
- [ ] Enhance `search_facet_values/4` doc in `lib/scrypath.ex` with type-ahead examples.
- [ ] Add Phase 96 constants and test case to `test/scrypath/docs_contract_test.exs`.
- [ ] Register `verify.phase96` in `mix.exs` aliases (if applicable, though most phase tasks are just run directly).

### 3. CI Integration
- [ ] Add `mix verify.phase96` to `.github/workflows/ci.yml`.

## Verification Strategy
- [ ] Run `mix verify.phase96` locally and ensure it passes.
- [ ] Verify `mix docs` generates without warnings.
