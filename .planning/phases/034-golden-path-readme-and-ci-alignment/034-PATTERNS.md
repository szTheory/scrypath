# Phase 34 — Pattern map

Analogs for doc + contract-test execution (reuse conventions; do not fork harnesses).

## Primary analog: Phase 33 plan + contracts

| Artifact | Why |
|----------|-----|
| `.planning/phases/033-example-smoke-paths-and-doc-contracts/033-01-PLAN.md` | Frontmatter shape, `<threat_model>` table, `<task>` XML with `<read_first>`, `<acceptance_criteria>`, grep-based verify |
| `.planning/phases/033-example-smoke-paths-and-doc-contracts/033-RESEARCH.md` | How **Validation Architecture** section feeds **034-VALIDATION.md** |

## Code / test patterns

| File | Pattern |
|------|---------|
| `test/scrypath/docs_contract_test.exs` | `@readme`, `@guides`, `assert_contains_all/2`, `ordered?/3`, module attrs read at compile time — edit tests in same PR as markdown |
| `README.md` / `guides/golden-path.md` | Published markdown; must pass **`published markdown avoids internal planning...`** hygiene patterns |

## Schema truth

| File | Pattern |
|------|---------|
| `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` | **`field(:status, :string)`** — doc snippets should match for first-schema story |

## PATTERN MAPPING COMPLETE
