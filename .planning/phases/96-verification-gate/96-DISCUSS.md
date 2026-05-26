# Discussion: Phase 96 Verification Gate

## Phase Overview
Phase 96 provides the hermetic verification gate for the high-cardinality facet value search feature. It ensures that the API introduced in Phase 95 is stable, documented, and regression-guarded.

## Requirements
- **TEST-01**: Ensure there are hermetic docs-contract tests and unit tests verifying the request structure and the parsed response.
- **TEST-02**: Add a `mix verify.phase96` hermetic gate to prevent regressions.

## Proposed Approach

### 1. Hermetic Verification Task
Create `lib/mix/tasks/verify.phase96.ex` following the existing pattern for phase gates.
- **Focused test suite:**
  - `test/scrypath/search_test.exs` (Core routing and validation)
  - `test/scrypath/meilisearch_test.exs` (Provider implementation)
  - `test/scrypath/docs_contract_test.exs` (Documentation and public API contracts)
- **Documentation check:** Runs `mix docs --warnings-as-errors` to ensure ExDoc remains clean.

### 2. Documentation Contract Bolstering
The `search_facet_values/4` documentation in `lib/scrypath.ex` currently lacks the rich examples requested in `DOC-01` (specifically UI type-ahead patterns).
- **Update:** Enhance `lib/scrypath.ex` documentation for `search_facet_values/4` with a concrete example of how a developer might use it (e.g., in a LiveView search component).
- **Test:** Add an assertion in `test/scrypath/docs_contract_test.exs` that verifies this example snippet exists.

### 3. CI Wiring
Register `mix verify.phase96` in `.github/workflows/ci.yml` under the `quality` job to automate verification.

## Assumptions
- No new infrastructure is needed for this gate.
- Existing `FakeBackend` is sufficient for hermetic testing of the request/response cycle.

## Open Questions
- Should we add a dedicated `test/scrypath/facet_search_contract_test.exs`?
  - *Decision:* No, existing `search_test.exs` and `docs_contract_test.exs` are sufficient for this scope to keep the test suite focused.
