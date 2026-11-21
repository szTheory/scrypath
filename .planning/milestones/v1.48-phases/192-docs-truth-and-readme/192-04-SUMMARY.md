---
phase: 192-docs-truth-and-readme
plan: 04
subsystem: testing
tags: [readme, quick-path, contract-test, pin-rehoming, hexdocs-links, exunit]

requires:
  - phase: 192-docs-truth-and-readme
    provides: "Plan 01 ShippedDocs scanner, Plan 02 invariant, owner map and moved claims, Plan 03 absolute repo-path links and the built-docs link scan"
provides:
  - "README trimmed to 590 words: fit and non-fit, installation, one quick path, three absolute HexDocs links after it; header lines 1-7 byte-identical"
  - "Quick path that states the Meilisearch prerequisite and eventual consistency before its first code block and ends in a three-argument Scrypath.search/3 call and its result"
  - "guides/golden-path.md config snippet in the shape Scrypath.Config reads (config :scrypath, :defaults)"
  - "readme_contract_test.exs: 18 README tests (quick path, word cap equal to the owner map, onward-link cap counted from the last code block, section shape, link rules, brand and time-promise word lists, operator UI sentence)"
  - "ShippedDocs.links_to_guide?/2 accepting the relative and HexDocs link forms"
  - "Every README-asserting pin re-pointed, kept or retired with one fate each in 192-PIN-INVENTORY.md, plus a README token ledger"
affects: [193-guards, 194-website-decision]

actuals:
  tokens: 14300
  tasks: 4
  commits: 4
plan_head_before: b011cc89cacc838dcd148dba26304f0e9c84cbc2
plan_head_after: f4d5a2c62286047a5fc94f03a9fb40a8c26eda77

tech-stack:
  added: []
  patterns:
    - "Re-point pins against the old README first, trim second: every commit leaves every pin green"
    - "Copy-aside README mutation sweep script: 15 mutations, each must fail a named test, README restored byte-identical"
    - "Onward links counted from the closing line of the README's last code block, which the test proves lies inside the quick path"

key-files:
  created:
    - .planning/phases/192-docs-truth-and-readme/192-04-SUMMARY.md
  modified:
    - README.md
    - guides/golden-path.md
    - test/scrypath/readme_contract_test.exs
    - test/support/release/shipped_docs.ex
    - test/scrypath/docs_contract_test.exs
    - test/scrypath/readiness_contract_test.exs
    - test/scrypath/phase99_contract_test.exs
    - test/scrypath/phase110_contract_test.exs
    - test/scrypath/phase112_contract_test.exs
    - test/scrypath/backfill_contract_docs_test.exs
    - .planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md

key-decisions:
  - "Section headings: When Scrypath Fits, When It Does Not, Installation, Quick Path, Next Steps (kept the existing title-case style because the pinned Quick Path heading is title case)"
  - "README search opts: bare keyword list page: [size: 10]; the test wraps it in brackets before Code.eval_string and checks the page value with Scrypath.Options.validate_search_page/1"
  - "The B9 replacement reads the Package/release contract row itself, not the whole verification section, because a section-wide substring still passed when the row dropped mix verify.phase11 (mutation-checked)"
  - "ui_contrast_contract_test.exs is left out of the per-task pin-set runs: it clones committed HEAD and runs the full repository contracts in child processes, so a pre-commit run measures the previous commit; it ran once on the final head inside the core and repository-contracts mirrors"

patterns-established:
  - "assert_docs_extras/1 in docs_contract_test.exs: a route claim is pinned by extras membership, with the accepted gap (sidebar grouping is Phase 193's) stated in a comment and the fate log"
  - "Shared loops keep the README in their lists and special-case it (links_to_guide?/2), so tuple-drift absence checks keep covering it"

requirements-completed: [README-01, README-02, TRUTH-03]

coverage:
  - id: D1
    description: "The README is the fixed shape within the cap: 590 words (floor 400, cap 800, equal to the owner map), 34 fenced lines (cap 60), five level-2 headings, no route block, at most three links after the quick path's last code block (three today), header block unchanged"
    requirement: README-01
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#README shape README stays within the recorded word cap"
        status: pass
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#README shape at most three onward links follow the quick path"
        status: pass
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#README shape the README has no route block and keeps the fixed section shape"
        status: pass
    human_judgment: false
  - id: D2
    description: "The quick path states the Meilisearch prerequisite and eventual consistency before the README's first code block and before its own first code block, syncs inline, and ends in Scrypath.search(Module, \"query\", page: [size: 10]) followed by result.records; the schema fence equals the golden path's and the config fences evaluate through Scrypath.Options.validate_runtime_options!/1"
    requirement: README-02
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#quick path (8 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every README link is absolute on an allowed host; repo-path links use blob/main and exist; HexDocs links name a docs extra or a documented module; no repo-only task outside a source-checkout qualifier; no brand do-not-say word; no time promise; the operator UI sentence says source checkout and not in the Hex package"
    requirement: TRUTH-03
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#README shape (9 tests)"
        status: pass
      - kind: unit
        ref: "test/release/package_metadata_test.exs#extras pages have no self-link, unresolved link or dead anchor (built readme.html)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every README-asserting pin has one recorded fate (re-pointed to its owner, kept in the README, or retired with a named replacement); none was deleted without a replacement; the 15-file pin set passes against the old README at Tasks 1 to 3 and the trimmed one at Task 4"
    requirement: README-01
    verification:
      - kind: integration
        ref: "15-file README pin set (ui_contrast excluded, see Deviations): 427, 427, 426, 435 tests, 0 failures at Tasks 1, 2, 3, 4; 435, 0 failures again on committed head f4d5a2c6"
        status: pass
      - kind: other
        ref: ".planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md fate log and README token ledger"
        status: pass
    human_judgment: false
  - id: D5
    description: "The golden-path config snippet uses the :scrypath :defaults key that Scrypath.Config reads; README and golden path snippets are proven by evaluating them and validating the keyword list"
    requirement: README-02
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#quick path README.md config snippet resolves through Scrypath's runtime options (and guides/golden-path.md)"
        status: pass
    human_judgment: false

duration: about 3h (about 2h 20min of it waiting on lane mirrors under heavy host load)
completed: 2026-11-21
status: complete
---

# Phase 192 Plan 04: README trim, quick path and pin re-pointing Summary

**The README is now 590 words (fit and non-fit, installation, one quick path that ends in a real `Scrypath.search/3` result, three absolute HexDocs links), every link resolves offline, every README pin was re-pointed to its owner before the trim, and the golden-path config snippet finally matches what `Scrypath.Config` reads.**

## Performance

- **Duration:** about 3 h wall clock; about 2 h 20 min of it was the lane mirrors, which were slow because the machine's load average sat between 20 and 46 from unrelated processes
- **Started:** 2026-11-21T07:01:40Z
- **Completed:** 2026-11-21T09:58Z
- **Tasks:** 4 (Task 1 was a tracer)
- **Files modified:** 11 (1 created: this summary; 10 edited)

## Accomplishments

- **Quick path (tracer).** The README opening states the Meilisearch prerequisite and the approved eventual-consistency sentence before the Installation fence; the quick path restates both before its own first fence, then shows the schema (identical to the golden path), the `config :scrypath, :defaults` config, a repo write followed by `Scrypath.sync_record/3` with `sync_mode: :inline`, one sync-modes paragraph, and a last fence that ends in `{:ok, result} = Scrypath.search(MyApp.Blog.Post, "ecto", page: [size: 10])` and `result.records`. The golden-path config snippet was fixed to the same shape. The tracer verify ran green on the exact committed tree before any expansion.
- **Pins re-pointed before the trim.** Task 2 moved the route pins (extras membership for each guide, owner surfaces for the example and ScrypathOps READMEs, `ShippedDocs.links_to_guide?/2` for the support, golden-path and sync-guide links); Task 3 moved the section pins (the `mix verify.phase11` demand now reads the `Package/release contract` row of CONTRIBUTING's matrix, the README-only ops-verification test is deleted because the CONTRIBUTING ops-ui pin carries it, the reindex omission key is pinned on the drift guide). The shared loops keep the README in their lists. The pin set was green at every commit.
- **Trim with its tests.** The README went from 1,479 to 590 words. `readme_contract_test.exs` has 20 tests (2 from Plan 02, 18 here). Fifteen README mutations (relative link, disallowed host, missing repo path, non-main ref, unknown HexDocs page, unqualified repo-only task, brand word, time promise, extra section, dropped operator-UI qualifier, dropped owner-map token, over-cap word count, two-argument search call, schema drift, config keyed on the host app) each fail the intended test; the onward-link mutation shows a count of 4. Every mutation restored the README byte-identically.
- **Inventory.** The fate log has one row per token with fate, owner, replacing test, plan and commit hash, a README token ledger lists every assertion that still reads the README, and a "Not proven" list is recorded.

## Task Commits

1. **Task 1: Tracer, quick path end to end** - `897d696e` (feat)
2. **Task 2: Route pins re-pointed to their owners** - `722a6ee8` (test)
3. **Task 3: Section pins re-pointed, fate rows** - `29ff8916` (test)
4. **Task 4: README trim with README-01 tests and trim-dependent pin rewrites** - `f4d5a2c6` (docs)

**Plan metadata:** committed with this SUMMARY (docs). It also fills the Task 4 hash into the inventory fate log.

Tracer gate: auto mode is not active and the tracer's `<verify>` is automated-only, so it was re-run (format, readme tests, 15-file pin set: 427 tests, 0 failures) on the exact tree that was committed before Tasks 2 to 4.

## Files Created/Modified

- `README.md` - trimmed landing page (header lines 1-7 hash `2124e901b6815608fbac74e116eba2157f19ed20`, same as the Plan 03 head)
- `guides/golden-path.md` - config snippet in the `:scrypath` `:defaults` shape
- `test/scrypath/readme_contract_test.exs` - quick path and README shape tests
- `test/support/release/shipped_docs.ex` - `links_to_guide?/2`
- `test/scrypath/docs_contract_test.exs`, `readiness_contract_test.exs`, `phase99_contract_test.exs`, `phase110_contract_test.exs`, `phase112_contract_test.exs`, `backfill_contract_docs_test.exs` - re-pointed pins
- `.planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md` - fate rows, token ledger, not-proven list

## Decisions Made

See `key-decisions` above. Gate budget: no gate added (GATE-03), no new dependency, no new CI job, no Hex release, no website or `groups_for_extras` edit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The planned B9 replacement could not fail**
- **Found during:** Task 3 mutation check
- **Issue:** the plan's assertion (the `## Canonical verification commands` section contains the `Package/release contract` row and `mix verify.phase11`) still passed after removing the task name from the row, because the name appears elsewhere in that section.
- **Fix:** the assertion finds the `Package/release contract` row and requires the row itself to name `mix verify.phase11`. Mutation: removing it from the row now fails "phase 29 golden path guide and adoption readme contract".
- **Files modified:** `test/scrypath/docs_contract_test.exs`
- **Committed in:** `29ff8916`

### Plan discretion and corrections

**2. [Plan discretion] The README pin set excludes `ui_contrast_contract_test.exs` in the per-task runs.** The plan's set includes it. It clones committed HEAD and runs `mix verify.repository_contracts` in child processes, so a pre-commit run tests the previous commit and costs minutes. It ran on the final head inside the `core` and `repository-contracts` mirrors (see the table). The two orphaned `scrypath-contrast-*` clones from two runs I stopped were removed.

**3. [Plan discretion] Search-opts capture.** The README's third argument is a bare keyword list (`page: [size: 10]`), so the regex captures it without brackets and the test wraps it before `Code.eval_string/1` (the plan said "bracketed text").

**4. [Plan discretion] Word count 590, ten under the owner map's 600 to 800 target.** The test enforces only the 400 floor and the 800 cap, as designed; I added one accurate sentence (`use Scrypath` is metadata-only) and stopped rather than pad.

**5. [Plan discretion] C2.4 README half.** The README task-name demands (`mix scrypath.failed`, `mix scrypath.retry`) moved to the ARCHITECTURE half of the same test, which already carries both (`ARCHITECTURE.md:116-117`), so the replacement is equal, not weaker.

**6. [Plan discretion] Test renames and extra tests.** Renamed "README opens with installation before the quick path", "the jtbd guide is a docs extra and the overview exposes it as a first-class entry point", "route destinations stay docs extras or linked repo files and jtbd next-reading retains unique destinations", "CONTRIBUTING documents example smoke cwd (Phase 33)" and "drift guide lists the reindex omission count" (no tool or file names the old titles). Added tests beyond the plan's list: sync before search order, README config equals golden-path config, golden-path and README config not keyed on the host app.

**7. [Correction] Line numbers.** Pin line numbers in the plan had moved after Plans 02 and 03; I re-located by token and recorded the property, not the number.

**Total deviations:** 1 auto-fixed (Rule 1), 6 discretion or correction notes. **Impact on plan:** no scope change.

## Pre-push lane mirrors (all on committed head `f4d5a2c6`; nothing pushed)

| # | Lane | Result |
|---|------|--------|
| 1 | cheap: `mix format --check-formatted`, shipped_docs and readme tests | green: format clean, 43 tests, 0 failures |
| 2 | doc pins | green: 435 tests, 0 failures (15 files; `ui_contrast_contract_test.exs` ran in rows 5 and 7) |
| 3 | `mix docs --warnings-as-errors` | green, exit 0 |
| 4 | `scripts/ci/pre_push.sh` | green: 11 passed, 0 skipped, exit 0 |
| 5 | `core`: `mix verify.core --exclude integration --exclude docs_contract` | one red, then green on rerun: 1,242 tests, 1 failure, which was `ui_contrast_contract_test.exs` "canonical contrast rejects incomplete inputs and stale focus bindings" timing out at its 600 s ceiling while the host load average was 46. The docs build and the no-optional-deps step after it passed. Rerunning that file alone on the same head: 5 tests, 0 failures (334 s test time). My changes touch no CSS, contrast manifest or checker. Known risk: that test needs about 5 to 6 minutes of CPU, so it can time out on a loaded machine |
| 6 | `package`: `mix verify.package` | green, exit 0 (132 tests, 0 failures) |
| 7 | `repository-contracts` | Mix half green: `mix verify.repository_contracts` exit 0, 171 tests, 0 failures (escalated for FETCH_HEAD). Node half: the plan's `node --test scripts/ci/*.test.cjs` ran 364 tests, 361 pass, 3 fail, all outside the five files the hosted job runs (`ecommerce_build`, `ecommerce_lifecycle`, `ecommerce_evidence`, `ecommerce_target`, `ui_state_pairs`), which had no failures: two `ui_literal_policy.test.cjs` tests (`:267`, `:327`) fail every time because their mutation target `var(--color-neutral, #000)` is no longer in `scrypath_ops/assets/css/app.css` since the brand re-skin, so their `git commit` has nothing to commit (pre-existing, unrelated, see Deferred Issues); one `ui_preservation.test.cjs` 100 ms clock-publication test failed under load and passes alone (53 tests, 0 failures) |
| 8 | `backend`: compose project `scrypath-p192`, `mix verify.backend` | green, exit 0 (smoke, 15 Postgres tests and 1 property, 0 failures) |
| 9 | `ecommerce-mounted`: classifier, then `mix verify.ecommerce_mounted` (escalated, `BUILDX_CONFIG` outside the repo) | classifier `run=true reason=non-allowlisted-path` as expected. First attempt: exit 124, the independent dependency-boundary proof hit the wrapper's 900 s ceiling during cold no-cache builds under load; no behavioural failure, but its cleanup could not enumerate its resources, so I removed the four leftover containers, network and three images by exact run id. Second attempt on the same head: green, exit 0, `cleanup=clean` |
| 10 | `ops-ui`: `PGPORT=5434 mix verify.ops_ui` (escalated) | green, exit 0 (2 doctests, 553 tests, 0 failures) |
| 11 | website (optional) | not run: optional, needs `npm ci`; README and guides changed, so the site redeploys on merge |

**Docker cleanup:** `docker compose -p scrypath-p192 down -v` done; the per-run `scrypath_ecommerce_verify_focused_f4d5a2c6_*` and `scrypath_dependency_boundary_*` containers, networks and images, the external Buildx directory and my temp clones are gone. `docker system df` is back to the starting counts (244 images, 56 containers) except one extra local volume: an anonymous Postgres data volume created at 04:13 EST (`72634ce9...`) that I cannot attribute to my runs, so I left it. Other projects' resources were not touched.

## Issues Encountered

- Host load average ran between 20 and 46 for most of the lane mirrors (a Virtualization VM, fuzzers and other agents), which caused the `core` test timeout, the first `ecommerce-mounted` timeout and one 100 ms flake. Each passed on a rerun at the same SHA.
- `ui_contrast_contract_test.exs` spawns full `mix verify.repository_contracts` children; the first pin-set attempt looked hung for three minutes at 0% CPU in the parent. I stopped it and cleaned up the orphaned children and clones.

## Deferred Issues (pre-existing, out of scope; not logged to `deferred-items.md` because only the plan's files may be committed here)

- `scripts/ci/ui_literal_policy.test.cjs:267` and `:327` fail deterministically since the brand re-skin (stale mutation target in `scrypath_ops/assets/css/app.css`). They are not in the hosted repository-contracts Node file list, so hosted CI should not see them; whoever owns the literal policy should update the mutation target or drop the tests from `scripts/ci/*.test.cjs`-style local runs.
- The plan's row 7 Node command is wider than the hosted job's five-file list; the CI-EFFICIENCY ledger or the next plan's lane table should use the five files.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. No placeholder, empty-value or TODO text was added.

## Threat Flags

None. The plan touches docs and tests only. T-192-11 (header pin) is mitigated by the unchanged header hash and the existing byte-equality tests; T-192-12 (links) by the allowed-host, `blob/main`, path-exists and HexDocs-page checks, each mutation-checked; T-192-13 (vacuous checks) by the section and fence assertions, the 400-word floor, the fence-line cap and the mutation sweep; T-192-14 (pins deleted to reach green) by the re-point-first ordering and the fate log; T-192-15 (config evaluation) accepted as planned (tracked file, temp copy, removed after reading).

## What this does not prove

- That the new README reads better to a newcomer; no reader or reviewer judged it. Time to first search; brand fit beyond the do-not-say and time-promise lists.
- That the quick path runs against a live Meilisearch. The snippets parse, the config goes through `validate_runtime_options!/1` and the search opts through `validate_search_page/1`, but no automated run executes the sync and search lines.
- Live hex.pm and hexdocs.pm rendering, external link liveness and version skew of unversioned HexDocs links (Phase 193 checkpoint).
- That extras membership means the HexDocs sidebar shows each guide where a reader looks (Phase 193 regroups it).
- That hosted CI passes. Not run locally: the optional website lane. The `core` and `ecommerce-mounted` mirrors each needed a rerun under load, so their cold-cache hosted timings are untested here.

## Next Phase Readiness

Ready for verification and the PR. Notes for the orchestrator:

- PR-description notes from the plan still apply: the two named exemptions (`CHANGELOG.md`, the `mix.exs` registration lines), the claims that left the README and where they live (owner map), the retired `version-source` claim, the golden-path search call that drops `preload:`, no gate added, no Hex release.
- Phase 193 inputs: `@differs_marker` in `readme_contract_test.exs` (the parity guard's marker), the golden-path config now equal to the README config, and the word "hydrated" still in `guides/drift-recovery.md` (a pin reads it).
- The README test names the exact headings (`When Scrypath Fits`, `When It Does Not`, `Installation`, `Quick Path`, `Next Steps`); a heading rename needs the `@section_shape` constant too.
- `.planning/config.json` and `.planning/state.json` were never staged; STATE.md and ROADMAP.md were not touched.

## Self-Check: PASSED

- Created and edited files present: `README.md`, `guides/golden-path.md`, `test/scrypath/readme_contract_test.exs`, `test/support/release/shipped_docs.ex`, `192-PIN-INVENTORY.md` and the six re-pointed test files.
- Commits reachable from HEAD: `897d696e`, `722a6ee8`, `29ff8916`, `f4d5a2c6`; measured count `git rev-list --count b011cc89..f4d5a2c6` is 4.
- Acceptance greps re-run at the end: README 590 words, 0 relative link targets, 0 `## Choose a route`, header hash unchanged, `Start here:` 0 in `docs_contract_test.exs`, `blob/main/CHANGELOG.md` 1, `operator UI lives in the source checkout` 1 in `readme_contract_test.exs`, every mutation backup removed.

---
*Phase: 192-docs-truth-and-readme*
*Completed: 2026-11-21*
