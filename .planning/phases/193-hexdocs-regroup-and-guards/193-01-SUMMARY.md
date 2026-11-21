---
phase: 193-hexdocs-regroup-and-guards
plan: 01
subsystem: docs
tags: [exdoc, hexdocs, groups_for_extras, contract-tests, exunit, claim-owner-map]

requires:
  - phase: 192-docs-truth-and-readme
    provides: the README owner map and its shape test, the TRUTH-03 built-docs link scan, the one docs build in setup_all
provides:
  - six job-named HexDocs sidebar groups with a five-item first group and the golden path rendered second
  - a config-shape test and a built-sidebar test, both with in-memory planted failures, for the grouping ExDoc is silent about
  - guides/overview.md shrunk to a ten-item reading order plus the two example links, at the same URL
  - 193-PIN-INVENTORY.md, the audit trail for every group-shape and overview pin
affects: [193-02 guards (scans the shrunk overview), 194 website decision, docs/releasing.md release notes]

actuals:
  tokens: 12775
  tasks: 2
  commits: 2

plan_head_before: 4b8e3b8b3300ecf3027f648debfd6fc6cd7dac82
plan_head_after: 517f428eae2c9f8348890ae97089fbaf80694e37
commits: 2

tech-stack:
  added: []
  patterns:
    - "Pure check function returning {kind, detail} tuples, with the real config asserted empty and each failure kind planted in memory"
    - "Read ExDoc's own dist/sidebar_items-*.js payload from the one setup_all docs build instead of reimplementing its group matching"

key-files:
  created:
    - .planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md
  modified:
    - mix.exs
    - test/release/package_metadata_test.exs
    - test/scrypath/docs_contract_test.exs
    - guides/overview.md
    - README.md
    - lib/scrypath.ex
    - .planning/reference/CLAIM-OWNER-MAP.md

key-decisions:
  - "extras is the concatenation of the six group lists: ExDoc orders pages inside a group by extras order, so this is what makes the golden path render second"
  - "guides/overview.md stays in extras at the same URL and shrinks to a reading order; the four-layer list and the 22-row table are retired with recorded reasons"
  - "guide-routes is re-owned to doc:mix.exs and a new reading-order row keeps the overview page owning what it still says"
  - "The one lib/ touch is a moduledoc sentence that went false; no behavior change"

requirements-completed: [DOCS-01, DOCS-02]

coverage:
  - id: D1
    description: "Sidebar has six job-named groups in order; first group is README, golden path, getting started, overview, Meilisearch concepts"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the sidebar groups are the six job-named groups in order"
        status: pass
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the built sidebar renders every extra under its configured group in order"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every extra is in exactly one group; a planted missing, duplicated, dangling, oversized-first-group, non-path or misordered entry fails the check, on the config and on the built sidebar"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#every docs extra is in exactly one sidebar group"
        status: pass
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the group check reports a missing, duplicated, dangling or oversized-first-group entry"
        status: pass
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the sidebar check reports an ungrouped, misgrouped, misordered or unrendered extra"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix docs --warnings-as-errors exits 0 and no guide, doc, ARCHITECTURE, CONTRIBUTING or README file was renamed or deleted"
    requirement: DOCS-01
    verification:
      - kind: other
        ref: "mix docs --warnings-as-errors; git diff --diff-filter=DR --name-only origin/main -- guides docs ARCHITECTURE.md CONTRIBUTING.md README.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/overview.md is a short reading order at the same URL, every one of the eleven overview assertion calls passes unchanged, and no shipped sentence calls it an index of every guide"
    requirement: DOCS-02
    verification:
      - kind: unit
        ref: "doc-pin set of 13 test files (248 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-11-21
status: complete
---

# Phase 193 Plan 01: HexDocs regroup and overview shrink Summary

**The HexDocs sidebar now has six job-named groups with the golden path second in a five-item first group, a config test and a built-sidebar test fail every grouping mistake ExDoc ignores, and `guides/overview.md` is a 226-word reading order at the same URL with every pin carried.**

## Performance

- **Duration:** about 15 min (start time was not captured at launch; end 2026-11-21T13:40Z)
- **Tasks:** 2 of 2
- **Files modified:** 8 across the two task commits (7 modified, 1 created)

## Accomplishments

- Regrouped `mix.exs` `groups_for_extras` into Getting started, Guides by task, Phoenix, Operate and recover, Project policy and Maintainers, and reordered `extras` to match. Same 33 paths, nothing renamed, merged or deleted, so no HexDocs URL changed. The built sidebar renders the first group as readme, golden-path, getting-started, overview, meilisearch-concepts.
- Added two guards for something ExDoc builds clean around (an extra in no group, in two groups, or a group entry naming no extra). The config check (`docs_group_problems/3`) is fast and runs in `core` and in the package lane. The built-sidebar check (`sidebar_group_problems/2`) reads ExDoc's own payload from the one existing docs build. Each has planted in-memory failures. I also ran a real mutation (dropped `guides/multitenancy.md` from its group in `mix.exs`): three tests failed, naming `missing_from_groups` and `ungrouped`, then I restored the file.
- Shrunk `guides/overview.md` from 584 to 226 words: a purpose line, a ten-item reading order, the two example links, one support link. The old pins carried unchanged, including `Canonical mental model` and the jtbd-before-common-mistakes order (through a new tenth item).
- Reworded the two lines that called the page an index of every guide (README Next Steps, `Scrypath` moduledoc), and recorded the overview decision and its reason in `CLAIM-OWNER-MAP.md` and the pin inventory.

## Task Commits

1. **Task 1: pin inventory, regroup, config-shape and built-sidebar tests** - `fb57e627` (docs)
2. **Task 2: shrink the overview, reword two lines, owner-map rows** - `517f428e` (docs)

**Plan metadata:** the SUMMARY commit that follows this file (also fills the inventory's Task 2 commit hashes).

## Files Created/Modified

- `.planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md` - every group-shape and overview pin, inbound references, retired content table, fate log with commit hashes
- `mix.exs` - six `groups_for_extras`, `extras` reordered, one comment saying why
- `test/release/package_metadata_test.exs` - `@sidebar_groups`, `docs_group_problems/3`, four config tests (Operations pin carried to the renamed group), and in `BuiltDocsBrandTest` `built_sidebar_extras/1`, `extra_id/1`, `sidebar_group_problems/2` and two tests
- `test/scrypath/docs_contract_test.exs` - multitenancy registration test retitled and now asserts extras membership and the `Guides by task` group; two "accepted gap" comments replaced
- `guides/overview.md` - the shrunk reading order
- `README.md`, `lib/scrypath.ex` - one sentence each
- `.planning/reference/CLAIM-OWNER-MAP.md` - `guide-routes` re-owned to `doc:mix.exs`, new `reading-order` row, `mix.exs` added to the `doc:` examples, new `## Recorded decisions` section

## Decisions Made

- `extras` equals the concatenation of the six group lists. The earlier "extras order left alone" line was amended by the plan-check resolutions because ExDoc orders pages inside a group by `extras` order.
- The overview stays in `extras` (dropping it would end `overview.html` in later HexDocs versions and break the README link, the moduledoc link and the pinned assertions). Reason and date are in the owner map under `## Recorded decisions`.
- Fate-log commit hashes for Task 2 rows are filled in the SUMMARY commit, because a commit cannot contain its own hash.

## Deviations from Plan

None that change a plan outcome or acceptance criterion. Three small interpretation choices inside the plan's described kinds:

- **Single report per mistake.** `sidebar_group_problems/2` reports an extra sitting in the unnamed group only as `:ungrouped` (not also as `:wrong_group`), and computes `:order` over the ids a group actually rendered, so a missing or misgrouped extra is not reported a second time. Likewise `docs_group_problems/3` compares order only over entries that are real extras. This lets each planted case assert one exact tuple, as the plan asks.
- **Floor on the extras count is `>= 33`**, not `== 33`, so adding a guide later does not trip a floor; the exact member lists are still pinned by `@sidebar_groups`.
- **Regex planted case** appends the pattern to a clean group instead of replacing a path, so the only tuple is `:non_string_member`.

**Total deviations:** 0 auto-fixed (no Rule 1-4 events). **Impact on plan:** none.

## Issues Encountered

None. Machine load was 8 to 12 during the runs; no timing-sensitive test flaked.

## Local verification (pre-push confidence)

Ran, on this machine, from `/Users/jon/projects/scrypath` with the asdf toolchain exported:

- `mix format --check-formatted` (also inside `pre_push.sh`) and `mix credo --strict` on the two edited test files: clean.
- The two focused test files: 109 tests, 0 failures (103 at plan start, so 6 added).
- The doc-pin set of 13 files, including the `docs_contract`-tagged file named by hand: 248 tests, 0 failures (242 at research HEAD). Run on the working tree whose source files equal the Task 2 commit; the later inventory edits touch only a planning file.
- `mix compile --warnings-as-errors` and `mix docs --warnings-as-errors`: exit 0, no warnings; rename and delete check against `origin/main`: prints nothing.
- `scripts/ci/pre_push.sh` on the committed head: 11 steps passed, 0 skipped, exit 0.
- The repository-contracts subset that reads plans and CONTRIBUTING: 142 tests, 0 failures.
- `ops-ui` focused mirror from `scrypath_ops/` (Postgres on localhost:5432, forced `scrypath` recompile): 2 doctests, 553 tests, 0 failures.
- `ecommerce-mounted` host compile from `examples/scrypath_ecommerce/` (forced `scrypath` and `scrypath_ops` recompile): `--warnings-as-errors` exit 0.

Not run here, with the reason (known risk, not an assumption):

- `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package` (its `package_contents` and `consumer_smoke` files, since only `package_metadata` and `docs_contract` ran), and `mix verify.repository_contracts` (first run needs escalated permission for FETCH_HEAD): the plan assigns these to the one run on the head that is pushed after Plan 02. Plan 02's heavy list must run if the orchestrator pushes this plan's head first.
- `backend`: needs Meilisearch on localhost:7700, which is not published here, and this plan changes no library behavior.
- The Docker and browser half of `ecommerce-mounted` (about 14 minutes hosted) and the cold isolated builds in `mix verify.ops_ui`: slow for their value; the compile mirrors above exercise the change path.
- Website build: optional; hosted `build-and-check` must be green on the exact head before merge because merging deploys the site.

## What this does not prove

That the grouping matches how readers look for things, how the shrunk overview reads, and live HexDocs rendering, which changes only through a Hex release (out of scope, needs the maintainer's yes). No independent or maintainer aesthetic review took place.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema boundary; the changes are docs metadata, tests, and prose.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can scan the shrunk overview with the forbidden-phrase table (it contains no time promises, brand do-not-say words, or glossary former names). The owner-map rows that still say "Phase 193 guards this" (`install-line`, `quick-path`) are Plan 02's to update. Nothing blocks Plan 02.

## Self-Check: PASSED

- FOUND: `.planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md`, `mix.exs`, `test/release/package_metadata_test.exs`, `test/scrypath/docs_contract_test.exs`, `guides/overview.md`, `README.md`, `lib/scrypath.ex`, `.planning/reference/CLAIM-OWNER-MAP.md`
- FOUND commits: `fb57e627`, `517f428e` (both ancestors of HEAD)

---
*Phase: 193-hexdocs-regroup-and-guards*
*Completed: 2026-11-21*
