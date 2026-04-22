---
phase: 52-actionable-errors-and-onboarding-pitfalls
plan: "01"
subsystem: docs
requirements-completed: [ONBD-05]
key-files:
  created: [guides/common-mistakes.md]
  modified:
    - guides/overview.md
    - CONTRIBUTING.md
    - README.md
    - mix.exs
    - test/scrypath/docs_contract_test.exs
completed: 2026-04-22
---

# Phase 52 plan 01 summary

Shipped an evidence-led **`guides/common-mistakes.md`** (four `##` sections, test-path citations, no internal planning tokens) and wired discoverability through overview, CONTRIBUTING, README (single sentence), ExDoc extras + `groups_for_extras`, and **`Scrypath.DocsContractTest`** guide lists.

## Task commits

1. **Author common-mistakes guide** — `ce92d5b`
2. **Discoverability + STATE repair** — `016ce10`

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` — pass
- Acceptance greps from PLAN — pass (repo-wide `mix format --check-formatted` still reports pre-existing **`scrypath_ops`** formatting drift unrelated to this plan)
