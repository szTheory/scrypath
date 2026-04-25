---
phase: 69-adopter-verify-spine
plan: "02"
subsystem: docs
tags: [docs, ci, contracts, example, support]
requires:
  - phase: 69-01
    provides: root `mix verify.adopter` command surface
provides:
  - docs and CI aligned to the adopter verify command family
  - docs-contract coverage for fast/live mapping
  - support-guide alignment with `:inline`, `:manual`, and `:oban` verification scope
key-files:
  created: []
  modified:
    - test/scrypath/docs_contract_test.exs
    - README.md
    - CONTRIBUTING.md
    - guides/support-and-compatibility.md
    - examples/phoenix_meilisearch/README.md
    - .github/workflows/ci.yml
requirements-completed: [INTG-02]
completed: 2026-04-23T01:25:33Z
---

# Phase 69 Plan 02: Docs, support guide, and CI adopter spine Summary

**README, CONTRIBUTING, the support guide, the Phoenix example README, and GitHub Actions now all point at the same adopter verify command family: `mix verify.adopter` for the fast path and `mix verify.adopter --live` for the canonical example proof.**

## Accomplishments

- Extended `test/scrypath/docs_contract_test.exs` to pin the new task help surface, README/CONTRIBUTING wayfinding, support-guide scope, example README mapping, and CI fast/live command usage.
- Updated README and CONTRIBUTING so maintainers have one obvious root command family, with explicit fast-vs-live wording and explicit live prerequisites.
- Added verification-scope language to `guides/support-and-compatibility.md` so the support contract now states what fast mode protects and what only live mode proves.
- Updated `examples/phoenix_meilisearch/README.md` to describe `mix verify.adopter --live` as the root maintainer entry point while preserving `cd examples/phoenix_meilisearch && mix deps.get && mix test` as the canonical example path.
- Added a dedicated no-services `adopter-verify` CI job and rewired `phoenix-example-integration` to run `mix verify.adopter --live`.

## Files Modified

- `test/scrypath/docs_contract_test.exs`
- `README.md`
- `CONTRIBUTING.md`
- `guides/support-and-compatibility.md`
- `examples/phoenix_meilisearch/README.md`
- `.github/workflows/ci.yml`

## Verification

- `mix test test/scrypath/docs_contract_test.exs`
- `mix verify.adopter`
- `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live`

## Issues Encountered

- Existing older docs-contract assertions still expected the live CI path to reference `cd examples/phoenix_meilisearch` directly; those assertions were updated to accept the new root-task indirection while keeping the canonical example path pinned elsewhere.
- `mix deps.get` in the example app emitted a Hex re-auth prompt message, but it fell back cleanly and the live run completed successfully without requiring new authentication.
- The repo already had unrelated local modifications in tracked files, so this plan was executed without task commits to avoid mixing unrelated user changes into a commit.

## Self-Check: PASSED
