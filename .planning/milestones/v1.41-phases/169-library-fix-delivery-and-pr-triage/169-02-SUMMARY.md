---
phase: 169-library-fix-delivery-and-pr-triage
plan: "02"
subsystem: phoenix-example
tags: [phoenix, ecto, postgres, meilisearch, tenant-scope, integration]

requires:
  - phase: 169-01
    provides: validated tenant-scope search options and keyword facet-filter rendering at the selected candidate base
provides:
  - persisted host membership authorization before Phoenix search and facet dispatch
  - tenant-and-returned-ID constrained hydration with raw search data kept independently observable
  - explicit Meilisearch primary-key creation for the existing inline, Oban, and related-data smoke paths
  - named live tenant/facet consumer evidence for path and freshly built local-package modes
affects: [169-04, 169-05, phoenix-example]

actuals:
  tokens: 6961.75
  tasks: 3
  commits: 4
  plan_head_before: 2089bd8ea27a793985669e15b7a00a5eb6074562
  candidate_head: f444215ad6a02d2bb7bb9b2acc4e493f4c9fe18d

tech-stack:
  added: []
  patterns:
    - derive trusted tenant scope from a persisted host membership before constructing Scrypath options
    - inspect raw search hits, counts, categories and facet values separately from host hydration
    - create consumer test indexes with an explicit primary key and await their matching terminal task

key-files:
  created:
    - examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs
    - examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs
    - examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs
    - examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex
  modified:
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
    - examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
    - examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs
    - examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs
    - examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs
    - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs

key-decisions:
  - "Persisted host membership is the only trusted tenant source; caller-controlled scope and runtime overrides are rejected before dispatch."
  - "Keep the live test's raw hits/counts/facets separate from tenant-and-ID constrained database hydration."
  - "Record path, local artifact, and published package identities separately; this plan proves only the candidate and fresh local artifact."

patterns-established:
  - "Host search policy validates membership and allowlisted inputs before calling public Scrypath APIs."
  - "A deterministic mixed-tenant consumer fixture uses a positive control for each tenant and asserts the raw search response independently."

requirements-completed: [DELIV-02]

coverage:
  - id: D1
    description: "Persisted host membership gates search and facet dispatch, rejects string/atom overrides, and bounds hydration by tenant and returned IDs."
    requirement: DELIV-02
    verification:
      - kind: integration
        ref: "mix test test/scrypath_demo/blog_tenant_search_test.exs (5 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The four established live sync scenarios create explicit-id indexes and reach their existing search assertions."
    requirement: DELIV-02
    verification:
      - kind: integration
        ref: "mix test test/smoke/meilisearch_stack_test.exs test/smoke/meilisearch_oban_stack_test.exs test/smoke/meilisearch_related_inline_stack_test.exs test/smoke/meilisearch_related_oban_stack_test.exs --trace (4 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix precommit at candidate f444215 (16 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The named mixed-tenant search and keyword facet scenario passes through the path dependency and a fresh locally built package artifact."
    requirement: DELIV-02
    verification:
      - kind: integration
        ref: "mix verify.phoenix_example at f444215 (16 tests, 0 failures; SCRYPATH_PHASE166_HOST present)"
        status: pass
      - kind: integration
        ref: "mix verify.phoenix_example --package at f444215 (artifact and consumer graph recorded; 16 tests, 0 failures; SCRYPATH_PHASE166_HOST present)"
        status: pass
      - kind: other
        ref: "git diff --exit-code -- mix.lock examples/phoenix_meilisearch/mix.lock examples/scrypath_ecommerce/mix.lock scrypath_ops/mix.lock"
        status: pass
    human_judgment: false

duration: 24 min (approximate)
completed: 2026-09-29
status: complete
commits: 4
---

# Phase 169 Plan 02: Phoenix Host Tenant and Consumer Proof Summary

**Phoenix host search now derives tenant scope from persisted membership, filters hydration by tenant and returned IDs, and proves keyword facets through both local consumer modes.**

## Performance

- **Duration:** Approximately 24 minutes, including isolated service setup and both package modes.
- **Started:** 2026-09-29T19:42:00Z (approximate reconstruction)
- **Completed:** 2026-09-29
- **Tasks:** 3
- **Files modified:** 10 implementation and test files; this summary is committed separately in the executor worktree.

## Accomplishments

- Added persisted synthetic actors and memberships, host-owned tenant authorization, strict input allowlists, and tenant-plus-returned-ID hydration. Raw search output remains separately available for assertions.
- Added host recorder cases for authorized search/facets, missing or mismatched memberships, malformed principals and parameters, atom/string override rejection, and foreign/unreturned row exclusion.
- Added an explicit `id` primary-key helper that awaits a successful creation task for the inline, Oban, and two related-data smoke scenarios.
- Restored the named live tenant fixture with tenant A's published control, draft exclusion, tenant B's positive control and unique marker, exact raw counts, category distributions, and status-filtered keyword facet values.
- Captured path and fresh local-package receipts at candidate `f444215ad6a02d2bb7bb9b2acc4e493f4c9fe18d`. Both executed the `SCRYPATH_PHASE166_HOST` scenario and passed 16 tests.

## Task Commits

1. **Task 1: Trace persisted host membership through public search and scoped hydration**
   - `426e51e` — `test(169-02): add host tenant search entrypoint probe` (RED: 1 test, 1 assertion failure because the entrypoint was absent).
   - `c09916d` — `feat(169-02): trace persisted host membership search` (GREEN: focused recorder suite, 5 tests, 0 failures).
2. **Task 2: Preserve existing live sync scenarios with tenant-aware projections**
   - `55f1ce5` — `fix(169-02): pin Meilisearch smoke primary keys`.
3. **Task 3: Prove raw tenant isolation and keyword facets through both consumer modes**
   - `f444215` — `test(169-02): add live tenant facet consumer proof`.

Candidate branch `worktree-agent-phase169-p02-candidate` starts at Plan 01 candidate base `2089bd8ea27a793985669e15b7a00a5eb6074562` and ends at `f444215ad6a02d2bb7bb9b2acc4e493f4c9fe18d`. Four commits were measured from that base; all four are task commits.

## Verification and Evidence

- **Host recorder:** `mix test test/scrypath_demo/blog_tenant_search_test.exs` passed 5 tests with 0 failures at `c09916d`. The initial test-only commit had 1 test fail on its expected entrypoint assertion. After the implementation, the tracer suite was rerun and passed before Task 2.
- **Primary-key baseline:** Before the helper, the existing inline smoke test failed because Meilisearch inferred two primary-key candidates, `id` and `tenant_id`. After the fix, the four named smoke modules passed 4 tests with 0 failures.
- **Path consumer:** At `f444215ad6a02d2bb7bb9b2acc4e493f4c9fe18d`, `mix verify.phoenix_example` passed 16 tests. The named receipt reported A raw ID `35`, count `1`, category/facet `phone-a:1`; B raw ID and unique marker `37`, count `1`, category/facet `phone-b-forbidden:1`. Setup task IDs were `70,71`; write task IDs were `72,73,74`.
- **Fresh local-package consumer:** At the same source SHA, `mix verify.phoenix_example --package` built local artifact tag `v0.3.13`, artifact commit `aaa992ddad1979fea18fbde4acf58429b10706f2`, compiled the staged consumer, and passed 16 tests. The named receipt reported A raw ID `45` and B raw ID/marker `47`, each with count `1` and its expected category/facet. Setup task IDs were `90,91`; write task IDs were `92,93,94`. This is evidence for the local artifact, not Hex installation or publication.
- **Dependency graph:** Phoenix source lock SHA-256 was `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f`. Path resolution matched that digest. The staged package graph SHA-256 was `fd3e5ea82365d2d564670762e3453ff835daae241f86cbef3d5822a044bdba8f`; the graph guard passed with Scrypath resolving to the selected local artifact and all other locked packages unchanged.
- **Project check:** `mix precommit` passed at the final candidate and ran the integration-enabled example suite: 16 tests, 0 failures. The explicit four-lockfile `git diff --exit-code` and `git diff --check` passed.
- **Service lifecycle:** Plan-owned Postgres 16 and Meilisearch v1.15 used `PGPORT=55433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:17700`, and `SCRYPATH_EXAMPLE_INTEGRATION=1`. Both services were healthy during verification and were removed with `docker compose down` for project `scrypath-phase169-plan02`. Package staging cleanup completed on success.

## Files Created and Modified

- `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` — persisted membership authorization, allowlisted inputs, search/facet dispatch, and bounded hydration.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` — tenant/category projection, filters, facet configuration, and casts.
- `examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs` — additive synthetic actor/membership tables and post tenant/category fields.
- `examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs` — host policy and recorder assertions.
- `examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex` — explicit-id index creation and terminal task assertion.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs`, `meilisearch_oban_stack_test.exs`, `meilisearch_related_inline_stack_test.exs`, and `meilisearch_related_oban_stack_test.exs` — use the shared index setup.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs` — named live mixed-tenant search/facet scenario and sanitized receipt.

## Decisions Made

- Kept authentication and membership policy in the Phoenix host context; the synthetic principal represents an already-authenticated actor.
- Kept raw search output, totals, category distributions, facet values, and database hydration as separate assertions so hydration cannot hide a search leak.
- Used exact candidate and local artifact identities for path/package receipts. Historical Phase 166 receipts remain bound to their original source.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced merged Compose port lists in the Plan 02 override**
- **Found during:** Service setup before Task 1.
- **Issue:** Compose appended the supplied `55433`/`17700` mappings to the base `5433`/`7700` mappings; the base Postgres port was occupied, so the exact requested startup failed.
- **Fix:** Changed the Plan 02-only override to use Compose `!override` for the two port lists, preserving the requested loopback ports and project network. No repository file or other Compose project was changed.
- **Verification:** Resolved Compose config and service status showed only `127.0.0.1:55433` and `127.0.0.1:17700`; both health checks passed. The owned project was later removed.
- **Committed in:** external Plan 02 test setup only; no candidate source change.

**2. [Rule 3 - Blocking] Redirected the Hex cache into writable temporary storage**
- **Found during:** Task 1 dependency preflight.
- **Issue:** Locked dependencies resolved, but Hex could not persist its registry cache at the default location (`:eaccess`).
- **Fix:** Set a task-local `HEX_HOME` under the permitted temporary area; package names and lock versions were unchanged.
- **Verification:** `mix deps.get --check-locked` completed for both the Phoenix example and candidate root; all locked versions remained unchanged.
- **Committed in:** environment only; no candidate source change.

**3. [Rule 3 - Blocking] Used the selected additive migration because generator tasks are absent**
- **Found during:** Task 1 migration setup.
- **Issue:** `mix help ecto.gen.migration` and `mix help phx.gen.schema` reported that neither task exists in this Phoenix example's configured dependencies.
- **Fix:** Restored the exact additive migration from the selected historical source reference at the plan-owned migration path.
- **Verification:** The test alias applied the migration and the host recorder tests passed against the disposable database.
- **Committed in:** `c09916d`.

**Total deviations:** 3 auto-fixed environment/tooling blockers.
**Impact on plan:** All fixes were limited to the assigned service setup or migration generation path. The candidate scope, public APIs, dependency graph, and release claims did not expand.

## Issues Encountered

- The GSD `tdd-red-evidence` parser recognizes Node TAP summaries, while the project emits ExUnit output. The project has `workflow.tdd_mode: false` and this is an `execute` plan; actual ExUnit RED and GREEN results are recorded above, with the task 1 test-only commit preceding implementation.
- No authentication gate, skipped verify command, known stub, or unresolved implementation issue remained.

## Next Phase Readiness

- Plan 04 can consume candidate `f444215ad6a02d2bb7bb9b2acc4e493f4c9fe18d` and these source-bound path/package receipts. The example README reconciliation remains Plan 04 scope.
- This plan did not update STATE.md, ROADMAP.md, or shared phase tracking; the orchestrator owns those updates after the wave.

---
*Phase: 169-library-fix-delivery-and-pr-triage*
*Completed: 2026-09-29*

## Self-Check: PASSED

- Summary file exists in the executor worktree.
- Candidate task commits `426e51e`, `c09916d`, `55f1ce5`, and `f444215` are reachable.
- The required candidate source, migration, helper, and tenant smoke files exist at candidate `f444215`.
