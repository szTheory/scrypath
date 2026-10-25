---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 07
subsystem: examples
status: complete
tags: [examples, oban, fan-out, related-sync, fan-01, ecommerce, phoenix-example]
requires:
  - 179-01 (Loader tolerance for owner-only schemas without :preload)
  - 179-05 (RelatedWorker loads trigger structs; RelatedEnqueue calls Loader.ensure_loadable!/2)
provides:
  - "ScrypathEcommerce.Catalog.Category.search_records/2: loads categories by id with explicit skip_tenant_id: true"
  - "phoenix_meilisearch Oban related smoke passes repo: ScrypathDemo.Repo"
  - "Example resolver docs describe records-in for every sync mode"
affects: []
tech-stack:
  added: []
  patterns:
    - "owner schema with a tenant-guarded repo and no :scrypath repo defines search_records/2 so Oban fan-out can enqueue and reload it"
key-files:
  created: []
  modified:
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex
    - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex
decisions:
  - "Category.search_records/2 uses ScrypathEcommerce.Repo directly (the context :repo is nil because the app configures no :scrypath repo)"
  - "Ecommerce keeps the [_id | _] clause of resolve_products_for_categories/1 (catalog_test.exs calls it with ids); phoenix example removes its [_id | _] clause because no test or caller passes ids"
metrics:
  duration: ~15m
  completed: 2026-10-25
estimate:
  tokens: 25000
  tasks: 2
actuals:
  tokens: 1500
  tasks: 2
  commits: 2
plan_head_before: 655e79853f12677b43e738e6b31a2a134c58f0e2
plan_head_after: 5f1df5950b5a7b962abab8580245fbd60d8f42ae
---

# Phase 179 Plan 07: Example apps follow the new related-sync contract Summary

Both example apps' Oban fan-out paths work with the new related-sync contract. The ecommerce `Category` now loads through an explicit, tenant-bypassing `search_records/2`. The phoenix example's Oban related smoke passes `repo:`. Example resolver docs no longer say Oban passes ids.

## What was built

- **`ScrypathEcommerce.Catalog.Category.search_records/2`** loads `where: c.id in ^ids` via `ScrypathEcommerce.Repo.all(query, skip_tenant_id: true)`. Because of it, `Loader.custom_loader?/1` is true for `Category`, so `update_category/3` passes `ensure_loadable!` at enqueue even though no `:scrypath` repo is configured. The RelatedWorker then reloads `%Category{}` structs without tripping the repo's tenant guard. `update_category/3` is unchanged.
- **`resolve_products_for_categories/1`** (ecommerce) has a new one-line comment: Scrypath passes `%Category{}` records in every mode, and the id clause is kept for direct callers. `catalog_test.exs` calls it with ids, and the test file is unchanged.
- **Phoenix Oban related smoke** now has `repo: ScrypathDemo.Repo` in `sync_opts`. `Author` still has no `:preload` clause.
- **`ScrypathDemo.Blog`**: the moduledoc and the `resolve_posts_for_authors/1` `@doc` now say Author records arrive in both `:inline` and `:oban`. The dead `[_id | _]` clause is removed, since `grep -rn "resolve_posts_for_authors(\[" examples/phoenix_meilisearch/test` finds no direct id caller.
- **`ScrypathDemo.Blog.Author`**: the fan_outs comment no longer says "BOTH arities ... oban -> author IDs". The moduledoc's `:document_id` explanation is kept, because Oban jobs still carry owner document ids.

## Verification

- Ecommerce: `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs` gave 10 tests, 0 failures, with no "expected :tenant_id" or "needs :repo" errors. This includes "update_category/3 enqueues related product sync" and "resolve_products_for_categories/1 reloads category products with category names". `MIX_ENV=test mix compile --warnings-as-errors` exited 0.
- Phoenix example: `mix compile --warnings-as-errors` (dev and test) exited 0. The full example suite with integration enabled (`SCRYPATH_EXAMPLE_INTEGRATION=1`, live Meilisearch) gave 18 tests, 0 failures. `meilisearch_related_oban_stack_test.exs --trace` gave 1 test, 0 failures: the RelatedWorker reloaded the Author and the renamed author was searchable.
- `mix format --check-formatted` passed on all 5 modified files.
- Acceptance greps: `def search_records` = 1, `skip_tenant_id: true` = 1 in category.ex. `repo: ScrypathDemo.Repo` = 1 in the smoke test. `both arities` = 0/0 (baseline 1/2). `author IDs` in author.ex = 0 (baseline 1). `git diff --name-only HEAD -- examples/scrypath_ecommerce/test` is empty.
- Required `ecommerce-mounted` lane (regression check): `bash examples/scrypath_ecommerce/scripts/verify-e2e.sh focused` (the body of `make verify-mounted` / `mix verify.ecommerce_mounted`, in an isolated compose project with no host ports) exited 0: "4 passed", "Docker verifier passed (scope=focused)", and no leftover containers.
- Tracer gate (Task 1): the `<verify>` passed on the content that was committed, before Task 2 started.

### What was not executed exactly as written (environment, not code)

- **`make -C examples/scrypath_ecommerce infra-pg` was not run.** It runs `docker compose -f compose.yaml -f compose.host-ports.yaml up -d postgres meilisearch` under the default `scrypath_ecommerce` project. That would recreate the maintainer's retained preview postgres/meilisearch containers with host ports, which the execution brief forbids. The catalog test ran instead against the native Postgres already listening on 127.0.0.1:5432 (`PGHOST=127.0.0.1`). The log shows harmless `too_many_connections` noise because the pool size (schedulers x 2) is above that server's `max_connections`.
- **`mix verify.phoenix_example` was not run.** Its `docker compose up` binds host 5433, which `threadline-postgres-1` already holds. The same `mix test` it runs was executed directly with `SCRYPATH_EXAMPLE_INTEGRATION=1` against native Postgres (`PGPORT=5432`, `MIX_TEST_PARTITION=_17907`) and a throwaway `getmeili/meilisearch:v1.15` container on 127.0.0.1:7711. Afterwards the container was removed and the partition DB dropped. The hosted advisory `phoenix-example` lane re-runs the exact task on the phase PR.

## Deviations from Plan

None in code. The only differences are in how the verify commands were run, listed above. The phoenix `[_id | _]` clause was removed, which is the plan's conditional branch: no direct id caller exists.

## Deferred / out of scope

- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:2055` gives a compile warning ("clauses with the same name and arity ... format_run_error/1") when compiled as a path dep. It existed before this plan and lives outside this plan's files. It does not fail the examples' `--warnings-as-errors`, which applies only to the example project.
- `guides/related-data-and-reindexing.md` still shows the `[_id | _]` resolver clause. That guide belongs to plan 179-06, which runs in parallel.

## Known Stubs

None.

## Threat Flags

None. T-179-19 (accepted) covers the cross-tenant load in `Category.search_records/2`. It loads only the job's exact ids, the bypass is explicit (`skip_tenant_id: true`), and the downstream resolver scopes products by `category_id` and `tenant_id`.

## Commits

- `822286c1` fix(179-07): load ecommerce categories via search_records/2 for Oban fan-out
- `5f1df595` fix(179-07): pass repo to phoenix Oban related smoke and drop id resolver clause

## Self-Check: PASSED

- All 5 modified files exist; both task commits (822286c1, 5f1df595) are ancestors of HEAD.
- No STATE.md or ROADMAP.md changes.
