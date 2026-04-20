---
phase: 41-federation-docs-contracts
plan: 02
subsystem: documentation
tags: [federation, search_many, :all, docs_contract]

requires:
  - plan: 41-01
    provides: mix verify.phase41 and CI wiring for doc contracts
provides:
  - Canonical multi-index guide coverage for :all expansion and score vs merge ordering
  - search_many/2 moduledoc invariant for per-index scores
  - README and golden-path wayfinding to multi-index guide
  - FED-02 marked complete in internal requirements
affects: [FED-03, adopters, HexDocs]

tech-stack:
  added: []
  patterns: [two-layer federation narrative, doc contract anchors]

key-files:
  created: []
  modified:
    - guides/multi-index-search.md
    - guides/golden-path.md
    - README.md
    - lib/scrypath/search.ex
    - test/scrypath/docs_contract_test.exs
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Guide references exact error tuples from AllExpansion and search_many docs without copying full API surface."

patterns-established:
  - "phase_41 docs contract test reads guide + search.ex for stable substrings."

requirements-completed: [FED-03]

duration: 20min
completed: 2026-04-20
---

# Phase 41 Plan 02 Summary

**Aligned public docs and contracts with v1.8 federation semantics: `:all` expansion, global schema resolution, and explicit per-index score vs merged ordering story.**

## Task Commits

1. **Tasks 1–2: Multi-index guide** — `a58bd32`
2. **Task 3: Golden path + README** — `2b1ba4a`
3. **Task 4: search_many @doc** — `9944c3c`
4. **Task 5: Doc contracts** — `3f7352e`
5. **Task 6: REQUIREMENTS FED-02** — `e55fdbb`

## Verification

- `mix compile --warnings-as-errors` — PASS
- `mix verify.phase41` — PASS
- Spot-check: `guides/multi-index-search.md` contains `## :all expansion`, federation bold invariant, and `merged ordering`.

## Self-Check: PASSED
