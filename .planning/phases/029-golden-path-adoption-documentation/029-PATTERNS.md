# Phase 29 — Pattern Map

Analogs for **documentation edits** and **ExDoc registration** in this repo.

## Doc structure and tone

| Target | Closest analog | Excerpt / rule |
|--------|----------------|----------------|
| Operator / adoption docs cross-linking | `.planning/phases/028-operator-cli-docs-verify-gate/028-CONTEXT.md` | Prefer **link over duplication**; name CLI vs API explicitly |
| Mix task + guide alignment | `guides/operator-mix-tasks.md` + `lib/mix/tasks/scrypath/*` | Guides describe behavior; tasks stay thin wrappers |
| README “Quick Path” + deep guides | Current `README.md` + `guides/getting-started.md` | README shows **one** snippet block; depth lives in `guides/` |

## ExDoc extras registration

| New file | Pattern | Location |
|----------|---------|----------|
| `guides/golden-path.md` | Every guide under HexDocs is listed in **`mix.exs`** → **`defp docs` → `:extras`** and usually **`groups_for_extras`** | Copy the entry style of **`guides/getting-started.md`** |

## Runnable stack references

| Concern | Source of truth |
|---------|-----------------|
| Meilisearch image / port | `examples/phoenix_meilisearch/compose.yaml` and `examples/phoenix_meilisearch/README.md` |
| Env vars for smoke | `SCRYPATH_MEILISEARCH_URL`, `SCRYPATH_EXAMPLE_INTEGRATION` in example README |

## PATTERN MAPPING COMPLETE
