# Phase 87 Plan 01 Summary

## Completed Tasks

1. **Created `guides/outside-adopter-intake.md`**: This guide now serves as the single canonical authority for outside-adopter attempts, detailing the defended Phoenix + Meilisearch repo-clone path, the `mix verify.adopter` fast/live command family, and required evidence formats.
2. **Created `docs/templates/outside-adopter-evidence.md`**: Provided a structured template for adopters to submit required evidence (context, matrix, commands, outcomes).
3. **Updated Routing**: Modified `mix.exs`, `guides/overview.md`, `README.md`, `guides/support-and-compatibility.md`, and `CONTRIBUTING.md` to point to the new intake guide without duplicating information or creating a secondary support matrix.
4. **Added Regression Guards**: Added bounded assertions in `test/scrypath/readiness_contract_test.exs` and `test/scrypath/docs_contract_test.exs` to ensure the intake guide stays discoverable and the repo-clone vs. Hex-package boundary remains explicit.

## Next Steps

Update `STATE.md` to reflect the completion of Phase 87 Plan 01, and continue with the next plan in Phase 87 or the next phase as dictated by `STATE.md` and `ROADMAP.md`.
