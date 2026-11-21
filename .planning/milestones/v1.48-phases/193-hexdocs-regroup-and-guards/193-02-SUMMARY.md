---
phase: 193-hexdocs-regroup-and-guards
plan: 02
subsystem: docs
tags: [exunit, contract-tests, install-line, snippet-parity, forbidden-phrases, hexdocs-urls, claim-owner-map]

requires:
  - phase: 193-hexdocs-regroup-and-guards
    provides: "Plan 01: six sidebar groups, the shrunk overview and the pin inventory this plan appends to"
  - phase: 192-docs-truth-and-readme
    provides: "ShippedDocs scanner and the planted-case style, the README quick-path tests, the TRUTH-03 built-docs link scan, the claim owner map"
provides:
  - "InstallLine guard: every install tuple in the shipped files and website/scripts/build.mjs must equal the mix.exs series and be satisfied by it"
  - "GUARD-01 source rule in ShippedDocs: a versioned, http or non-page own-docs URL in shipped text fails, plus the recorded evidence that the built-docs scan already covers the criterion"
  - "SnippetParity shared module with a reason-carrying marker allowed above either fence"
  - "One forbidden-phrase data table and scanner over README and every guide, with the old README lists moved into it"
  - "CONTRIBUTING same-PR rule pinned by a test and an owner-map row, and a corrected docs-contract sentence"
affects: [194 website decision, docs/releasing.md release notes, scrypath_ops copy-rules exempt_paths]

actuals:
  tokens: 23400
  tasks: 3
  commits: 4

plan_head_before: bbe9891e11e606ab65f926279497c3eb168d2916
plan_head_after: 054207d7477c1dcaf51bd699fc9f1ed009774fe0
commits: 4

tech-stack:
  added: []
  patterns:
    - "Pure scanner under test/support/release with in-memory {path, text} pairs in and sorted tuples out, one real-file zero assertion, a non-vacuity floor and planted failures per guard"
    - "Data table as JSON read with Jason, scanned with fenced code masked so line numbers stay true"
    - "Support files that sort before their dependency require it first (Code.require_file with __DIR__) so --warnings-as-errors stays green"

key-files:
  created:
    - test/support/release/install_line.ex
    - test/release/install_line_contract_test.exs
    - test/support/release/snippet_parity.ex
    - test/release/snippet_parity_contract_test.exs
    - test/support/release/forbidden_phrases.ex
    - test/support/release/forbidden_phrases.json
    - test/release/forbidden_phrases_contract_test.exs
  modified:
    - test/support/release/shipped_docs.ex
    - test/release/shipped_docs_contract_test.exs
    - test/scrypath/readme_contract_test.exs
    - CONTRIBUTING.md
    - docs/releasing.md
    - .planning/reference/CLAIM-OWNER-MAP.md
    - .planning/phases/193-hexdocs-regroup-and-guards/193-PIN-INVENTORY.md
    - scrypath_ops/test/support/copy_rules.json

key-decisions:
  - "GUARD-01 needs no new built-docs code: the TRUTH-03 scan already proves the planted self-link, dead target and dead anchor, README included; the evidence is mapped test by test in the inventory, and the one new rule reads source text in ShippedDocs"
  - "A requirement must equal the same-length prefix of the mix.exs version and satisfy it; the only non-numeric requirement allowed is one named placeholder in docs/releasing.md"
  - "The snippet marker needs a reason and may sit above either fence; the old bare marker is now an error"
  - "magic, federated and hydration are README-only phrase rules with a recorded reason; accepted work is never banned"
  - "The phrase data file joins the ops copy-rules exempt_paths, following the rule table's own precedent, instead of hiding the banned name from the scan"

requirements-completed: [GUARD-01, GUARD-02, GUARD-03]

coverage:
  - id: G1
    description: "The link check passes on the built docs and README and fails a planted self-link, dead target and dead anchor; a versioned, http or non-page own-docs URL in shipped text fails"
    requirement: GUARD-01
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the link scan reports a planted self-link, unresolved link and dead anchor (existing, mapped in the inventory)"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#a versioned own-docs URL fails"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#shipped files hold only unversioned https root or page links to the own docs"
        status: pass
    human_judgment: false
  - id: G2
    description: "Every install line equals the mix.exs version series and is satisfied by it; ~> 0.2 fails at 0.3.x and ~> 0.3 fails at 0.4.0"
    requirement: GUARD-02
    verification:
      - kind: unit
        ref: "test/release/install_line_contract_test.exs#every install line in the shipped files and the website matches the mix.exs version series"
        status: pass
      - kind: unit
        ref: "test/release/install_line_contract_test.exs#an install line from an older series fails"
        status: pass
      - kind: unit
        ref: "test/release/install_line_contract_test.exs#the current series fails after a minor bump"
        status: pass
    human_judgment: false
  - id: G3
    description: "README and golden path schema and config snippets are identical or carry a marker with a reason; planted differ, empty-reason and bare-marker cases fail"
    requirement: GUARD-03
    verification:
      - kind: unit
        ref: "test/release/snippet_parity_contract_test.exs#a marker without a reason fails, including the old bare form"
        status: pass
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#the quick path schema snippet is identical to the golden path"
        status: pass
    human_judgment: false
  - id: G4
    description: "The forbidden-phrase table is green on README and every guide, fails a planted phrase in README and in a guide, scopes magic, federated and hydration to README, equals the brand book's list, and still catches all 18 phrases the README tests banned before"
    requirement: GUARD-03
    verification:
      - kind: unit
        ref: "test/release/forbidden_phrases_contract_test.exs#README and every guide in extras are free of forbidden phrases"
        status: pass
      - kind: unit
        ref: "test/release/forbidden_phrases_contract_test.exs#a planted time promise fails in README and in a guide"
        status: pass
      - kind: unit
        ref: "test/release/forbidden_phrases_contract_test.exs#the brand rules equal the brand book's do-not-say list"
        status: pass
      - kind: unit
        ref: "test/release/forbidden_phrases_contract_test.exs#each phrase the README tests banned before is still caught in README"
        status: pass
    human_judgment: false
  - id: G5
    description: "CONTRIBUTING.md carries the same-PR rule naming the claim owner map, pinned by a test and an owner-map row, and says the docs contract suite runs in the required package lane"
    requirement: GUARD-03
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#CONTRIBUTING carries the same-PR rule for public-surface claims"
        status: pass
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#every owner-map Pinned-by token is present in its named file"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-11-21
status: complete
---

# Phase 193 Plan 02: Docs guards Summary

**Four mechanical guards now keep the install line, own-docs URLs, README/golden-path snippets and banned wording from drifting, each proven both ways: real files pass, and in-memory planted failures fail.**

## Performance

- **Duration:** about 35 min of work plus about 25 min of lane runs under machine load of 11 to 13 (start time was not captured at launch; end 2026-11-21T14:20Z)
- **Tasks:** 3 of 3, plus one follow-up fix commit
- **Files:** 15 across the four commits (7 created, 8 modified), plus this summary

## Accomplishments

- **Install line (GUARD-02).** `Scrypath.Release.InstallLine` reads the `mix.exs` version at test time and checks every install tuple in the shipped files and in `website/scripts/build.mjs`. A requirement must equal the same-length prefix of the version and satisfy it, so `~> 0.2` fails at 0.3.20 and `~> 0.3` fails at 0.4.0. The single named placeholder is the template line in `docs/releasing.md`. Real scan: six occurrences, no violations. `docs/releasing.md` now says what to do at a minor bump (one commit on the release PR).
- **Own-docs URLs (GUARD-01).** The existing built-docs link scan already proves the planted self-link, dead target and dead anchor, README included, so the inventory maps each case to its test and line and no built-scan code changed. The new source rule in `ShippedDocs` rejects a versioned, `http://` or non-page `hexdocs.pm/scrypath` URL in any shipped file (11 URLs read, none violating, one named exception for the release-template URL).
- **Snippet parity (GUARD-03).** `Scrypath.Release.SnippetParity` replaces the README test's private helpers. The marker `<!-- scrypath:snippet-intentionally-differs: <reason> -->` needs a reason and is allowed above either fence; the old bare form fails. The README parity tests keep their names and call it. Both real snippets are byte-identical and no marker ships.
- **Phrase table (GUARD-03).** `test/support/release/forbidden_phrases.json` (four rules) and `Scrypath.Release.ForbiddenPhrases` scan README and all 26 guides (27 targets) with fenced code masked. The two README lists moved into it; a test plants all 18 old phrases to prove none was lost, and a faithfulness test ties the brand terms to `brand/BRAND.md`. Zero offenders, nothing reworded, no allowlist.
- **CONTRIBUTING.** A same-PR rule names the claim owner map, pinned by a new test and a `same-pr-rule` owner-map row. The false sentence that the docs contract suite is "no longer part of the default CI" now says it runs in the required `package` lane through `mix verify.package`.

## Task Commits

1. **Task 1 (tracer): install-line guard, GUARD-01 source rule and record** - `dff73936` (test)
2. **Task 2: snippet parity module and the same-PR rule** - `60be8948` (test)
3. **Task 3: forbidden-phrase table** - `3ad98a12` (test)
4. **Follow-up: keep the phrase table clear of the ops copy-rules scan** - `054207d7` (test)

**Plan metadata:** the SUMMARY commit that follows this file (it also carries the inventory's Task 3 hashes and the copy-rules note).

## Decisions Made

- GUARD-01 stays in the existing built-docs scan; the source rule lives in `ShippedDocs`, runs in `core` as an untagged test and adds no gate and no lane (gate ledger unchanged at 10 of 12).
- The phrase data file is excluded from the ops copy-rules scan by path, the same way that rule table excludes its own file, because it must quote a name the ops table forbids (see deviation 1).
- `check/3` returns `:identical` when the bodies match even if a valid marker is present (the marker is moot); a malformed marker always errors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phrase table quoted a name the ops copy rules forbid**
- **Found during:** the `ops-ui` local mirror after Task 3 (hosted CI would have failed the same way).
- **Issue:** `scrypath_ops/test/support/copy_rules.json` forbids the title-case `Control Room` name in every tracked file. The new JSON table carried it as data and the new test planted it as a string, so the ops copy-rules test failed on four lines (`forbidden_phrases_contract_test.exs:204,205`, `forbidden_phrases.json:64,68`).
- **Fix:** the test builds the string by concatenation (the ops test's own convention), and the data file was added to `exempt_paths` beside the rule table itself (the Phase 190 precedent for a table that must hold the banned text). No ops rule was narrowed or removed. Recorded with a revisit trigger in the inventory.
- **Files modified:** `scrypath_ops/test/support/copy_rules.json`, `test/release/forbidden_phrases_contract_test.exs`
- **Commit:** `054207d7`

### Interpretation choices inside the plan's described behavior

- **`ShippedDocs.own_docs_urls/1`** is a fourth public function beside the three the plan listed. The plan's floors and the "exception still occurs" check need to count valid URLs, which `own_docs_url_problems/2` does not return.
- **Install pattern also reads a tuple with trailing options** (`..., only: :dev}`), so a stale line cannot hide behind them.
- **Literal phrases match across a hard line wrap** (a literal's spaces accept blanks or one line break), so a wrapped sentence is caught. Stricter than the old README helper; zero real hits.
- **Load order.** `test_helper.exs` requires support files in path order, and `install_line.ex` and `forbidden_phrases.ex` sort before the modules they call; each requires its dependency first (`Code.require_file` with `__DIR__`, a no-op once loaded). `--warnings-as-errors` flagged this on the first run.
- **`Version.parse_requirement/1` returns `:error`**, not `{:error, _}`; the Elixir 1.19 type check caught the wrong match.
- **TDD order.** The Task 2 tests were written and run red before the module existed (12 failures), then green. For Task 3 the module and the test file were written in one pass and first run together, so no red run was observed; instead a real-file mutation (a banned sentence appended to `README.md` and `guides/overview.md`, reverted by `git checkout` of those two files) failed the real-file scan and both rewired README tests.

**Total deviations:** 1 auto-fixed (Rule 3), 0 Rule 4 events. **Impact on plan:** one extra commit and one extra line in a file outside the plan's list; no acceptance criterion changed.

## Found issue outside this phase (not fixed)

`scrypath_ops/lib/scrypath_ops/posture.ex` `operator_mix_guide_path/0` (line 416) expands `../../guides/operator-mix-tasks.md` against `scrypath_ops/lib/scrypath_ops`, which resolves to `scrypath_ops/guides/operator-mix-tasks.md`. That file does not exist (checked 2026-11-21), so the posture screen never reads the root guide and its optional mix-status check never appends. Out of this phase's scope; this phase does not edit that guide's content.

## Issues Encountered

- The first `ops-ui` mirror run reported one failure (deviation 1); fixed and re-run green.
- `.impeccable/config.json` shows as modified in the working tree. It is not from this plan (an orchestrator-side change), so it was never staged.

## Local verification (pre-push confidence)

Run from `/Users/jon/projects/scrypath` with the asdf toolchain exported. Machine load was 11 to 13 throughout; no timing-sensitive test flaked.

On head `3ad98a12` (before the follow-up fix):

- `mix format --check-formatted` over the whole tree, and `scripts/ci/pre_push.sh`: 11 steps passed, 0 skipped, exit 0.
- `mix verify.core --exclude integration --exclude docs_contract`: 6 properties, 1297 tests, 0 failures (103 excluded); credo over 289 files clean; docs build clean; isolated no-Oban compile clean. 9 min 36 s.
- `mix verify.package`: 139 tests, 0 failures; 66 s.
- `mix verify.repository_contracts`: 171 tests, 0 failures; 8 min 0 s. The sandbox could write `.git/FETCH_HEAD`, so no escalated permission was needed.
- The doc-pin set of 13 files plus the three new contract files: 290 tests, 0 failures. `docs_contract_test.exs` was named by hand and ran.

On head `054207d7` (after the follow-up fix):

- `ops-ui` focused mirror from `scrypath_ops/` (Postgres on localhost:5432, forced `scrypath` recompile, `PGPORT` unset): 2 doctests, 553 tests, 0 failures. The first run on `3ad98a12` had 1 failure (deviation 1).
- `ecommerce-mounted` host compile from `examples/scrypath_ecommerce/` (forced `scrypath` and `scrypath_ops` recompile, `--warnings-as-errors`): exit 0.
- `mix deps.get --check-locked` in the root, `scrypath_ops` and the ecommerce example: all exit 0.
- Repository-contracts subset (phase 99, 111, no-human-gates, dependency boundary, workflow wiring, website, brand pin, 108, 147 and the CI monitor test): 266 tests, 0 failures.
- The changed test file: format check, credo `--strict` and its 11 tests clean.

Not re-run after the fix, with the reason (known risk, low): `mix verify.core`, `mix verify.package` and the full `mix verify.repository_contracts`. The fix changed one test file (re-run, formatted, credo-clean) and one JSON file that only the ops copy-rules test and `workflow_wiring_test` read (both re-run green); nothing in the package files changed.

Not run here, with the reason:

- `backend`: needs a Meilisearch service on localhost:7700, which is not published on this machine, and this plan changes no library behavior.
- The Docker and browser half of `ecommerce-mounted` (`mix verify.ecommerce_mounted`, about 14 minutes hosted) and the cold isolated builds inside `mix verify.ops_ui`: slow for their value, and the changed inputs reduce to compile-only edits that the host compile and ops suite above exercise. No Docker resources were created, so there was nothing to clean up.
- The Node half of `repository-contracts` (about 587 s): its scripts read none of `mix.exs`, `lib/`, README, `guides/` or `test/`.
- Website build: this plan does not edit `website/`. The hosted `website.yml` `build-and-check` triggers on `README.md`, `guides/**`, `docs/**` and `mix.exs` and must be green on the exact head before the squash merge, because merging deploys the site.

## What this does not prove

That unlisted wording is fine or that the guides read in the brand voice; prose that names a series without an install tuple (the golden path's minor-series sentence) and the website's rendered install block; external link liveness; own-docs URLs assembled by interpolation (the versioned package links in `mix.exs`, intentional and pinned by the package-metadata test) and the website's own HexDocs links, which are not shipped files; how hex.pm renders the marker comment; that contributors follow the same-PR rule. No independent or maintainer aesthetic review took place.

## Known Stubs

None.

## Threat Flags

None. The scanners only read tracked files; no network endpoint, auth path or schema boundary was added. T-193-04, T-193-05, T-193-06 and T-193-08 are mitigated as planned (floors, planted failures, no allowlist, a named exception that must still occur); T-193-07 stays accepted with its evidence recorded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 completes the phase's code and tests. The orchestrator ships: push the branch, open the PR, and squash-merge after the required checks are green on the exact head. `website.yml` `build-and-check` is not a required check but must be green on that head before merging. No Hex release is part of this phase. At the next minor version bump the install-line test goes red on the release PR by design; `docs/releasing.md` says how to fix it.

## Self-Check: PASSED

- FOUND: `test/support/release/install_line.ex`, `test/release/install_line_contract_test.exs`, `test/support/release/snippet_parity.ex`, `test/release/snippet_parity_contract_test.exs`, `test/support/release/forbidden_phrases.ex`, `test/support/release/forbidden_phrases.json`, `test/release/forbidden_phrases_contract_test.exs`
- FOUND commits: `dff73936`, `60be8948`, `3ad98a12`, `054207d7` (all ancestors of HEAD)

---
*Phase: 193-hexdocs-regroup-and-guards*
*Completed: 2026-11-21*
