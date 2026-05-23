---
phase: 83-composition-presets-and-scope-contract
plan: 03
subsystem: api
tags: [elixir, search, composition, guide]
requires:
  - phase: 83-01
    provides: public composition seam
  - phase: 83-02
    provides: focused verification lane
provides:
  - working normalization and merge engine
  - passing phase verifier
  - jtbd guide composition flow
affects: [phase-84, phase-85, composition, search_many]
tech-stack:
  added: []
  patterns: [field-scoped merge semantics, explicit composition conflicts]
key-files:
  created: [lib/scrypath/composition/normalize.ex, lib/scrypath/composition/merge.ex]
  modified: [lib/scrypath/composition.ex, lib/scrypath/composition/result.ex, guides/jtbd-and-user-flows.md]
key-decisions:
  - "Used whole-value override for sort/page/facets and caller-biased merges for filter-bearing fields."
  - "Returned stable field-scoped tuples for fixed conflicts instead of silent precedence."
patterns-established:
  - "Composition remains a pure data transform that stops at `{text, keyword_opts}`."
requirements-completed: [CMP-01, CMP-02, CMP-03, CMP-04]
duration: 1h
completed: 2026-05-23
---

# Phase 83: Composition Presets And Scope Contract Summary

**The new composition engine now resolves presets and scopes into canonical single-search args with deterministic precedence, explicit fixed conflicts, and a passed phase verifier.**

## Accomplishments
- Implemented fragment normalization, caller/default precedence, and fixed-constraint conflict handling.
- Kept visibility metadata derived from the same final canonical state used by `to_search_args/1`.
- Updated the JTBD guide so the adopter story includes reusable composition without widening the runtime boundary.

## Task Commits

No task commits were created in this run because the working tree already contained overlapping uncommitted edits in phase-targeted files.

## Deviations from Plan

Fixed one pre-existing docs metadata test drift in `test/release/package_metadata_test.exs` so the broader non-integration regression lane matched the current `mix.exs` docs grouping.
