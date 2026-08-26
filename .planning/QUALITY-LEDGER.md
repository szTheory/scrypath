# Quality Evidence Ledger

**Scope:** Phase 148 code-quality baseline
**Updated:** 2026-08-26

This ledger ranks durable quality evidence by the risk it controls. It is an
implementation record, not a coverage target or a substitute for feature-level
tests.

| Rank | Evidence | Command / owner | Risk controlled | Acceptance signal |
|---:|---|---|---|---|
| 1 | Warning-free root compilation without optional dependencies | `mix verify.no_optional_deps` | An optional integration becomes an undeclared runtime requirement; compiler warnings conceal API or compatibility defects | Forced fresh compile exits 0 with `--no-optional-deps --warnings-as-errors` |
| 2 | Warning-free fast test loading | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract` | Misnamed tests or noisy support discovery hides newly introduced warnings | Exit 0 and no support-file discovery or local Telemetry handler warnings |
| 3 | Deterministic service-free correctness | `mix verify --exclude integration` | Regressions in library behavior, formatting, linting, packaged workspace truth, documentation, or test-compilation warnings | Existing standard gate passes with test warnings promoted to failures |
| 4 | Informational line coverage | `mix verify.coverage` | Untested areas are harder to spot during review | Built-in report and HTML output generated; no percentage threshold is enforced |
| 5 | Deep and live evidence | Existing Dialyzer, Hex audit, compatibility, Meilisearch, example, and ecommerce proofs | Type, dependency, compatibility, backend, and adopter-flow regressions | Retained as their established CI/release evidence; Phase 148 does not alter workflow policy |

## Decision record

- Coverage is deliberately informational. Line coverage cannot prove branch,
  integration, or operational behavior; a minimum percentage would encourage
  low-value tests.
- `test/support/**` remains explicitly loaded by `test/test_helper.exs`. Mix
  receives a narrow ignore filter only for non-`*_test.exs` support files, so
  accidentally misnamed tests outside that boundary still warn.
- Telemetry assertions use module-qualified handlers because the Telemetry
  library warns about local captures and anonymous functions.
- This phase adds local capability commands only. It intentionally does not
  change CI workflows, branch protection, release automation, or historical
  phase-task wrappers.
