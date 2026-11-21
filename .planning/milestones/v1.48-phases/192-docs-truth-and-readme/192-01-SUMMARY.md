---
phase: 192-docs-truth-and-readme
plan: 01
subsystem: testing
tags: [exunit, contract-test, docs-truth, hex-package, scanner]

requires:
  - phase: 183-verifier-relocation
    provides: repo-only verify tasks under dev/mix/tasks, compiled only under MIX_ENV=test
provides:
  - "Scrypath.Release.ShippedDocs: derived repo-only task list, package-file expansion, sentence-level qualifier units, scan/2, violations/0"
  - "test/release/shipped_docs_contract_test.exs: planted cases and non-vacuity guards (untagged, core lane)"
  - "192-PIN-INVENTORY.md: tables A to D, mention inventory, fate log"
  - "Eight shipped files whose repo-only task mentions all sit in source-checkout-qualified units (scanner reports zero violations)"
affects: [192-02, 192-03, 192-04, 193-guards]

actuals:
  tokens: 15481
  tasks: 3
  commits: 3
plan_head_before: 1d7573e5e4d34b47237c47bebf9f91468a708386
plan_head_after: 209e6fa905318493d092340d25aff59db7c7222b

tech-stack:
  added: []
  patterns:
    - "Invariant scanner as pure test-support module (in-memory pairs in, sorted violations out) so planted cases never edit a shipped file"
    - "Qualifier unit: sentence of a plain paragraph, list item, heading, table row, or fence judged with the sentence directly above it"
    - "Derived data over hand-kept lists: task names come from the AST collector over the task trees"

key-files:
  created:
    - test/support/release/shipped_docs.ex
    - test/release/shipped_docs_contract_test.exs
    - .planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md
  modified:
    - README.md
    - guides/support-and-compatibility.md
    - guides/outside-adopter-intake.md
    - guides/golden-path.md
    - guides/operator-mix-tasks.md
    - docs/operator-support.md
    - docs/search-backend-sre.md
    - docs/jtbd-gap-map.md

key-decisions:
  - "Family forms (mix verify.*, backticked verify.*) are reported under the family root name (verify), derived from names that have children, so every violation tuple names a derived repo-only task"
  - "The sentence boundary also accepts closing punctuation (a bracket, quote or emphasis mark) between the terminal mark and the whitespace, so a qualifier cannot hide in a sibling sentence that follows a closing parenthesis"
  - "Exempt entries carry their scope as data: whole_file for CHANGELOG.md, {:lines, regex} for the mix.exs registration lines, so the contract test counts the registration lines from the same regex the scanner uses"
  - "qualifier_example/0 is a public accessor so planted cases and later doc edits share one canonical qualifier string"

patterns-established:
  - "Mutation check by copy-aside: mutate the scanner on a copy, confirm the named planted test fails, restore with cp and cmp"
  - "Inventory rows carry an action and a plan; the fate log carries the commit column, filled as plans land"

requirements-completed: [TRUTH-01]

coverage:
  - id: D1
    description: "Scanner derives 60 repo-only task names from the task trees and expands 133 shipped text files from mix.exs package files; no task name is hand-kept"
    requirement: TRUTH-01
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#repo-only task names are derived from the task directories, not a hand-kept list"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#the shipped file set is expanded from mix.exs package files and is not empty"
        status: pass
    human_judgment: false
  - id: D2
    description: "An unqualified repo-only task line fails the scan; a same-sentence source-checkout qualifier passes; a sibling-sentence qualifier, a heading or list item above a fence, and a second table or fence do not qualify"
    requirement: TRUTH-01
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#planted cases (in-memory strings only)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Two named exemptions (CHANGELOG.md whole file, mix.exs registration lines only) each record a reason and a revisit trigger; allowlist and exempt paths are in package files"
    requirement: TRUTH-01
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#each exemption records a reason and a revisit trigger"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#mix.exs scope mix.exs is exempt only for its preferred_envs registration lines"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every repo-only task mention in README, five guides and three docs files sits in a qualified unit; the scanner reports zero violations on the real shipped set and every pre-existing doc pin still passes"
    requirement: TRUTH-01
    verification:
      - kind: other
        ref: "MIX_ENV=test mix run --no-start -r test/support/release/package_contract.ex -r test/support/release/shipped_docs.ex -e 'Scrypath.Release.ShippedDocs.violations()' prints violations=0"
        status: pass
      - kind: integration
        ref: "doc-pin set of 13 files, 308 tests, 0 failures; mix docs --warnings-as-errors exit 0; scripts/ci/pre_push.sh 11 passed 0 skipped"
        status: pass
    human_judgment: false
  - id: D5
    description: "192-PIN-INVENTORY.md has tables A to D, a mention inventory with an action and plan per row, and a fate log, reproducible from the probe and grep commands in its header"
    requirement: TRUTH-01
    verification:
      - kind: other
        ref: "grep -cE '^## (Table A|Table B|Table C|Table D|Mention inventory|Fate log)' 192-PIN-INVENTORY.md prints 6"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-11-21
status: complete
---

# Phase 192 Plan 01: Derived repo-only scanner, pin inventory and in-place qualifiers Summary

**TRUTH-01 scanner that derives 60 repo-only task names from the task trees, judges every shipped sentence, list item, table row and fence against a source-checkout qualifier, and now reports zero violations on the real shipped files with all 291 existing doc pins still green.**

## Performance

- **Duration:** about 15 min
- **Started:** 2026-11-21T05:50Z (approximate; the start time was not recorded at launch)
- **Completed:** 2026-11-21T06:08Z
- **Tasks:** 3
- **Files modified:** 11 (3 created, 8 edited)

## Accomplishments

- `Scrypath.Release.ShippedDocs` (test support, never packaged): derives the repo-only task list from `dev/mix/tasks`, `scrypath_ops/lib/mix/tasks` and `examples/*/lib/mix/tasks` minus the shipped `lib/` tasks via `PackageContract.collect_task_modules/1`, expands the 133 text files from the `mix.exs` package files, splits text into qualifier units, and reports `{path, line, name}` tuples. No task name is written in the module.
- 17 untagged tests (run in `core`) prove the scanner can fail and can pass on in-memory strings: an unqualified bullet fails; the same bullet with the canonical qualifier passes; a qualifier in a sibling sentence does not qualify; a fence or table is judged only with the sentence directly above it; a heading, a list item, a second table or a second fence do not lend a qualifier; a code span with sentence-like text does not split a sentence; the family form `mix verify.*` is reported; allowlisted and exempt paths pass; `mix.exs` is exempt only for its 55 registration lines.
- Mutation checks (copy-aside, restored with `cmp`): breaking the sentence splitter, the code-span mask, `qualified?/1`, the lead-in rule, the registration-line blanking, the table and fence lead-in resets, and the `mix ` prefix rule each fails the named planted test. Stripping the words "source checkout" in memory from each of the eight edited real files makes the scanner report 1 to 15 violations in each, so the real qualifiers are what make them pass.
- 192-PIN-INVENTORY.md: Tables A to D re-verified against HEAD, a mention inventory with an action and plan per row, and a fate log. Eleven line citations from the research had moved or were slightly off and were corrected in place (for example the `--live` order check is `phase99_contract_test.exs:73-87`, not `:50-62`).
- Qualified every repo-only task mention in README, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, `guides/golden-path.md`, `guides/operator-mix-tasks.md`, `docs/operator-support.md`, `docs/search-backend-sre.md` and `docs/jtbd-gap-map.md` inside the same unit. No pinned token was removed and no neighbouring line was reflowed. Probe count: 28 at Task 1, 16 after Task 2, 0 after Task 3.

## Task Commits

1. **Task 1: Tracer, scanner, planted cases and pin inventory** - `4d0bdd1f` (test)
2. **Task 2: Qualify README and guide mentions** - `149545f7` (docs)
3. **Task 3: Qualify docs/ mentions, record actions in the inventory** - `209e6fa9` (docs)

**Plan metadata:** committed with this SUMMARY (docs).

The tracer gate passed: both Task 1 `<verify>` commands re-ran green end to end on the committed head (17 tests, 0 failures, probe `violations=28` with every path in the expected set), so expansion went ahead.

## Files Created/Modified

- `test/support/release/shipped_docs.ex` - the scanner (derivation, expansion, units, mentions, scan, violations)
- `test/release/shipped_docs_contract_test.exs` - planted cases and non-vacuity guards (`async: true`, untagged)
- `.planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md` - pin inventory
- `README.md`, `guides/*.md` (4 files), `docs/*.md` (3 files) - one qualifier per unit, in place

## Decisions Made

- Family forms are reported under the family root name (`verify`), derived from the task names that have children, so the well-formedness test (every tuple names a derived repo-only task) holds and no family list is hand-kept.
- The sentence boundary accepts closing punctuation after the terminal mark, so `(...not in the Hex package.) Run mix verify.adopter` splits into two units. This only ever adds splits, so it can only make the check stricter.
- Exempt scope lives in the data (`:whole_file`, `{:lines, regex}`), so the test counts registration lines from the regex the scanner uses.
- The Plan 02 real-file zero assertion is intentionally absent: this plan adds no assertion on the real files, so no commit here can disagree with the PROJECT.md contract text.

## Deviations from Plan

### Auto-fixed Issues

None needed fixing under Rules 1 to 3. The items below are discretion calls and corrections, recorded because Plan 02 reads the API:

**1. [Plan discretion] Public `qualifier_example/0` accessor added**
- **Found during:** Task 1 (planted cases need the canonical qualifier string)
- **Fix:** exposed `@qualifier_example` through an accessor instead of repeating the string in the test.
- **Files modified:** `test/support/release/shipped_docs.ex`
- **Committed in:** `4d0bdd1f`

**2. [Plan discretion] Family name is `verify`, not `verify.*`**
- **Issue:** the plan's well-formedness check requires every violation name to be in `repo_only_tasks/0`; a literal `verify.*` is not.
- **Fix:** `mentions/2` reports the family root (a name that has children), still derived from the task trees.
- **Committed in:** `4d0bdd1f`

**3. [Plan discretion] Boundary regex allows closing punctuation; six more planted tests than the plan lists**
- **Fix:** hardening as described above; extra tests cover heading and list-item lead-in blocking, second table, second fence, and a fence after a table. Test file has 17 tests (plan minimum 12).
- **Committed in:** `4d0bdd1f`

**4. [Correction] Research line numbers re-verified**
- Corrected in the inventory: A4 is `phase99_contract_test.exs:73-87`; `mix.exs` has 55 registration lines; `phase110_contract_test.exs:22,36`; `telemetry_test.exs:329`; `phase112_contract_test.exs:43-51`; `readiness_contract_test.exs:21`. The plan's own phase99 citations (B6 `:21-26`, B7 `:35-39`, B8 `:41-46`, CONTRIBUTING `:28-33`) matched HEAD.

**5. [Plan property over literal count] Probe count**
- The plan asked for at least 15 violations after Task 1; the sentence rule reports 28 (each operator-support gate line and table row separately). Paths were all in the expected set.

---

**Total deviations:** 0 auto-fixed; 5 discretion or correction notes. **Impact on plan:** none on scope; the API Plan 02 consumes is `scan/2`, `units/1`, `unit_qualified?/1`, `mentions/2`, `qualified?/1`, `qualifier_example/0`, `exempt/0`, `allowlist/0`, `violations/0`.

## Issues Encountered

- `~R` sigils are deprecated on Elixir 1.19; the heading classifier uses `~r/^\s{0,3}[#]{1,6}\s/` instead.
- Three planted-case line expectations were first written one line off (blank-line arithmetic); the scanner was right and the expectations were corrected.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. No placeholder, empty-value or TODO text was added.

## Threat Flags

None. The plan touches tests, planning notes and static docs only; the scanner reads tracked files and shells out to nothing. T-192-01 (false green) is mitigated by the non-vacuity guards (at least 50 derived names, at least 100 shipped files, named anchors, exactly two exemptions); T-192-02 by in-memory planted cases only; T-192-03 by the extension filter and UTF-8 check that drops local-only binaries such as `lib/.DS_Store`.

## What this does not prove

- That no shipped doc instructs a repo-only task in a form the regex cannot see (for example a task spelled in prose), or in a file outside `package.files`.
- That each qualifier sentence is itself accurate.
- That hosted lanes pass: `core`, `package`, `repository-contracts`, `backend`, `ops-ui` and `ecommerce-mounted` were not run here (the orchestrator runs the full lane mirrors at the end of Plan 04). Run locally instead: the 13-file doc-pin set (308 tests, 0 failures, about 14 s), `mix docs --warnings-as-errors` (exit 0) and `scripts/ci/pre_push.sh` (11 passed, 0 skipped, exit 0).

## Next Phase Readiness

Ready for 192-02: the scanner API is in place and the shipped files are clean, so Plan 02 can add the real-file zero assertion, rewrite the PROJECT.md contract bullet and the Table B pins in one commit. Notes for it: keep the contract bullet one list item so the task name and qualifier share a unit; `units/1` splits only plain paragraphs. The inventory Fate log commit column is blank for every row except B12 (`149545f7`); B11 points at `209e6fa9`.

## Self-Check: PASSED

- Created files present: `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`, `192-PIN-INVENTORY.md`.
- Commits reachable from HEAD: `4d0bdd1f`, `149545f7`, `209e6fa9`.
- All Task 1 to 3 acceptance criteria re-run: 17 tests 0 failures, format clean, credo strict clean, probe `violations=0`, six inventory headings, `mix verify.phase14` token kept (3 hits).

---
*Phase: 192-docs-truth-and-readme*
*Completed: 2026-11-21*
