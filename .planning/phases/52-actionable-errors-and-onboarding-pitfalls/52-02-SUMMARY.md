---
phase: 52-actionable-errors-and-onboarding-pitfalls
plan: "02"
subsystem: search
requirements-completed: [ONBD-04]
key-files:
  created: [lib/scrypath/search/error.ex]
  modified:
    - lib/scrypath/search.ex
    - lib/scrypath.ex
    - lib/scrypath/options.ex
    - test/scrypath/search_test.exs
    - test/scrypath/search_many_test.exs
completed: 2026-04-22
---

# Phase 52 plan 02 summary

Introduced **`Scrypath.Search.Error`** with **`message/1`** guide pointers for **`{:transport_failed, _}`** and **`{:invalid_options, _}`**, replaced **`RuntimeError`** bang wrappers in **`Scrypath.Search`**, documented **Errors vs raises** on search entrypoints (including the **`Scrypath`** facade), extended **`validate_search_options/2`** docs toward **`guides/multi-index-search.md`**, and added regression tests (including a native **`search_many`** transport stub).

## Task commits

1. **Exception module** — `123b506`
2. **Bang raises + docs** — `377beff`
3. **Tests** — `9a609c6`
4. **Options doc** — `013172e`

## Self-Check: PASSED

- `mix test` — pass (413 tests)
