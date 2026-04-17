---
phase: 20-faceted-search-liveview-guide
plan: "04"
---

## Outcome

Shipped `guides/faceted-search-with-phoenix-liveview.md` (≥200 lines, UI-SPEC copy, appendix with API / Meilisearch / UI bands), ExDoc `mix.exs` extras + Phoenix group, `DocsContractTest` anchors, `FacetedBrowseLive` compile fixture + test, `guides/phoenix-liveview.md` cross-link, and CHANGELOG Unreleased entry.

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs`
- `mix test --exclude external_meilisearch`

## Key files

- `guides/faceted-search-with-phoenix-liveview.md`
- `mix.exs`
- `test/scrypath/docs_contract_test.exs`
- `test/support/docs/phoenix_example_case.ex`
- `test/support/docs/phoenix_examples_test.exs`
- `guides/phoenix-liveview.md`
- `CHANGELOG.md`
