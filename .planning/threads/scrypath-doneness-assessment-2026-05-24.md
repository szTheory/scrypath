# Scrypath Done-Ness Assessment — 2026-05-24

## Purpose

Durable summary of the repo-grounded assessment that opened `v1.23`.

Use this thread when future milestone conversations start drifting toward more
internal breadth without revisiting whether Scrypath is already close to done
for its stated scope.

## Current call

- **Rough done-%:** ~86%
- **Territory:** finish the last important wedges, not keep pushing broad feature work
- **Default next pull:** outside-adopter evidence and support-truth reconciliation

## Why the library already looks strong

- First-schema and first-search adoption is real.
- Sync semantics are explicit and honest across `:inline`, `:manual`, and `:oban`.
- Phoenix integration through contexts is real and well-defended.
- Facets, multi-index search, request-edge normalization, and bounded composition are all real public surfaces.
- Operator recovery is a real product surface, not an appendix.

## Highest-leverage remaining gaps

1. **Outside-adopter evidence and support-truth reconciliation**
2. **Related-data propagation and dependency semantics**
3. **Tenant-safe search access**
4. **High-cardinality facet value search**

## Work that is likely near diminishing returns

- More generic ergonomics breadth
- More Phoenix helper sugar
- Deeper OPSUI productization
- Multi-backend expansion
- Suggestion/autocomplete work before correctness and SaaS-boundary gaps close

## Concrete drift found during the assessment

- `v1.20` archive claims `Scrypath.SearchModule`, but the checked-out tree does not expose it.
- Planning history still references `guides/support-and-compatibility.md`, but that guide is absent from the current tree.
- `mix verify.adopter` still cites `test/scrypath/readiness_contract_test.exs`, which is absent from the current tree.

## Decision rule for future milestone selection

- If `v1.23` outside-adopter evidence is mostly green, bias toward **stopping soon**.
- If feature work reopens, rank it:
  1. related-data propagation
  2. tenant-safe access
  3. high-cardinality facet-value search
