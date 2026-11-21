---
phase: 192-docs-truth-and-readme
plan: 03
subsystem: testing
tags: [exunit, contract-test, docs-truth, exdoc, link-scan, hexdocs]

requires:
  - phase: 192-docs-truth-and-readme
    provides: "Plan 01 ShippedDocs module and Plan 02 invariant, owner map and pin rewrites (all kept green)"
provides:
  - "Built-docs link scan inside BuiltDocsBrandTest: no self-link, unresolved link or dead anchor in the author region of any extras page, on the one existing docs build"
  - "Source-level link rule over the 33 docs-extra markdown files: relative targets are extras, repository-path links are absolute blob/main or tree/main URLs whose path and heading exist"
  - "ShippedDocs.markdown_links/1, github_slug/1, heading_slugs/1, repo_blob_base/0 (Plan 04 reuses them)"
  - "Sources fixed: 3 unresolved links, 2 dead anchors, 16 wrong-target repository-path links, plus one test-VM-only autolink"
affects: [192-04, 193-guards]

actuals:
  tokens: 11219
  tasks: 3
  commits: 3
plan_head_before: f6f9fb0976738ceab59ae954665974b1f2f13111
plan_head_after: 790cee1106e9552559785ec9260652936bce89cf

tech-stack:
  added: []
  patterns:
    - "Scan the built HTML of the one existing docs build; a missing author region is a failure, never a skip"
    - "Planted cases are in-memory strings run against the real build directory; a planted-snippet helper subtracts the page's own baseline problems so a planted case never depends on the page being clean"
    - "Source rule next to the built-docs scan: the build cannot see a README.md basename collision, the markdown source can"

key-files:
  created: []
  modified:
    - test/release/package_metadata_test.exs
    - test/release/shipped_docs_contract_test.exs
    - test/support/release/shipped_docs.ex
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - CONTRIBUTING.md
    - docs/local-demo-docker-dx.md
    - guides/support-and-compatibility.md
    - guides/golden-path.md
    - guides/outside-adopter-intake.md
    - guides/overview.md
    - guides/request-edge-search.md
    - guides/faceted-search-with-phoenix-liveview.md
    - .planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md

key-decisions:
  - "Fix every finding at the source; the scan has no ignored-href list"
  - "The scan reads the author region only (the main element marked data-type=\"extras\"), so ExDoc chrome is never scanned; module pages stay out of scope because ExDoc autolinks a module name inside its own docs"
  - "The repo-path definition (blob/<ref>/ or tree/<ref>/ on github.com/szTheory/scrypath) is a constant in the contract test; other links on the repo host (CI badge, issue templates) are not repo-path links and pass"
  - "github_slug keeps connector punctuation such as an underscore, as GitHub does"

patterns-established:
  - "Mutation check by copy-aside with cmp restore, run before the commit, recorded with the observed failure line"
  - "A guide that names a hidden module in backticks fails the scan when the test VM has that module loaded; name the file path instead"

requirements-completed: [TRUTH-03]

coverage:
  - id: D1
    description: "The built extras pages carry no self-link, no unresolved link and no dead anchor, checked on the real ExDoc build in BuiltDocsBrandTest with floors (extras pages at least the configured extras, hrefs greater than zero)"
    requirement: TRUTH-03
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#extras pages have no self-link, unresolved link or dead anchor"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each of a planted self-link, unresolved link and dead anchor is reported; the same self-link after the closing main tag, a link tag, a real anchor and a web link are not; a link that leaves the build is unresolved; a page with no extras region raises"
    requirement: TRUTH-03
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the link scan reports a planted self-link, unresolved link and dead anchor"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every relative link in the docs-extra markdown targets another extra; every link to a repository path outside the package is an absolute blob/main or tree/main URL whose path exists and whose fragment names a heading; floors 298 links and 25 repository-path links against 50 and 16"
    requirement: TRUTH-03
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#shipped markdown links to repo paths outside the package use absolute GitHub URLs"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#the link rule reports planted cases and passes the allowed forms"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pin B13 asserts the same runbook link in its absolute form, the README header pin tests and the 14-file doc-pin set stay green"
    requirement: TRUTH-03
    verification:
      - kind: integration
        ref: "doc-pin set of 14 files: 319 tests, 0 failures; mix docs --warnings-as-errors exit 0; scripts/ci/pre_push.sh 11 passed 0 skipped"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-11-21
status: complete
---

# Phase 192 Plan 03: Built-docs link scan and the absolute repo-path link rule Summary

**TRUTH-03: the built extras pages are scanned for self-links, unresolved links and dead anchors inside the existing docs build, a source rule keeps every repository-path link in the 33 docs-extra markdown files an absolute `blob/main` URL, and the 21 links that failed one or the other are fixed at the source.**

## Performance

- **Duration:** about 15 min (the pre-push mirror took about 8 of them)
- **Started:** 2026-11-21T06:45:26Z
- **Completed:** 2026-11-21T07:00Z
- **Tasks:** 3 (Task 1 was a tracer; its end-to-end verify re-ran green before expansion)
- **Files modified:** 13 (0 created, 13 edited)

## Accomplishments

- **Built-docs scan.** `Scrypath.Release.BuiltDocsBrandTest` gained `extras_pages/1`, `author_content/1`, `author_hrefs/1` and `link_problems/3`, which return `{page, href, kind}` with kind `:self_link`, `:unresolved` or `:dead_anchor`. It reads the one build `setup_all` already makes (no second docs run), scans only the text between the `<main ... data-type="extras">` tag and its `</main>`, skips web, protocol-relative, mail and data hrefs, and treats a href that climbs out of the build as unresolved without opening it. Vacuity floors: extras pages at least the 33 configured extras, hrefs greater than zero.
- **Planted cases.** In-memory snippets against the real build: a self-link inside the region is reported; the same link after `</main>` is not; a missing page is `:unresolved`; `golden-path.html#no-such-anchor` is `:dead_anchor`; `../readme.html` is `:unresolved`; controls (another page, a real `h2` anchor read from the built golden path, a web link, a `<link>` tag) report nothing; a page without the extras region raises.
- **Source link rule.** `ShippedDocs` gained `markdown_links/1` (`{line, target}`, outside fences and code spans, images included), `github_slug/1`, `heading_slugs/1` (duplicates get `-1`, `-2`) and `repo_blob_base/0`. `ShippedDocsContractTest` checks all 33 docs-extra files: 298 links, 53 absolute, 245 relative, 25 repository-path links today (floors 50 and 16). Planted cases cover a relative example README, a relative CI workflow, a link above the root, a missing path, a bad fragment, `blob` to a directory, `tree` to a file and a non-main ref; allowed forms include the CI badge, the issue-template link, a same-page anchor, a line anchor on a code file and a `tree` link to a directory.
- **Sources fixed, no ignore list.** CONTRIBUTING (6 links), the Docker DX doc (1), the support guide (3), golden path (2), intake guide (1), overview (2) and request-edge guide (1) now link repository files by absolute `https://github.com/szTheory/scrypath/blob/main/...` URL with the link text unchanged. The 3 unresolved links and 2 dead anchors the scan found are among them.
- **Pin B13** asserts the same runbook link text and fragment in its absolute form; the other pins that read the example paths still match as substrings of the absolute URL and were not edited. The pin inventory records both, plus the two new checks and what they cannot see.

## Task Commits

1. **Task 1: Tracer, built-docs scan, planted cases, source fixes and B13** - `5cdc6cc1` (test)
2. **Task 2: Remaining guide links to absolute URLs** - `4e9fae86` (docs)
3. **Task 3: Source-level link rule and inventory** - `790cee11` (test)

**Plan metadata:** committed with this SUMMARY (docs).

Tracer gate: auto mode is off and the task's `<verify>` is automated-only, so both Task 1 commands re-ran on the committed head and passed (50 tests, 0 failures; docs exit 0; credo clean) before expansion.

## Mutation checks (each run before its commit, restored with cp and cmp, diff stat matched)

- Task 1, the CI workflow link in `CONTRIBUTING.md` line 229 restored to its relative form: `contributing.html -> .github/workflows/ci.yml (:unresolved)`, 1 failure; restored; rerun green.
- Task 3, the first example link in `guides/overview.md` line 44 restored to its relative form: `guides/overview.md:44 ../examples/phoenix_meilisearch/README.md - relative target resolves to examples/phoenix_meilisearch/README.md, which is not a docs extra`, 1 failure; restored; rerun green.
- Before the source fixes, the Task 1 test run failed with the six findings it was written to find (see the first deviation), which is the failing direction of the real-build scan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A fourth unresolved link, visible only in the test VM**
- **Found during:** Task 1, first run of the new scan
- **Issue:** `guides/faceted-search-with-phoenix-liveview.md` names `Scrypath.TestSupport.Docs.PhoenixExampleCase.FacetedBrowseLive` in backticks. When the docs build runs inside `mix test`, that `@moduledoc false` test-support module is loaded, so ExDoc autolinks it to a page it never writes (`faceted-search-with-phoenix-liveview.html -> Scrypath.TestSupport.Docs.PhoenixExampleCase.FacetedBrowseLive.html`). The research prototype ran the CLI `mix docs`, where the module is not loaded, so it counted 3 unresolved links, not 4. The published docs build has no such link; the test-VM build did.
- **Fix:** the sentence now names the fixture as `FacetedBrowseLive` in `test/support/docs/phoenix_example_case.ex`, a file path and an unqualified name that ExDoc does not link. No test pinned the old sentence. No ignore entry.
- **Files modified:** `guides/faceted-search-with-phoenix-liveview.md` (not in the plan's file list)
- **Commit:** `5cdc6cc1`

### Plan discretion and corrections

**2. [Correction] golden-path second link is at line 158, not 136.** Plan 02 inserted the search fence earlier in the guide (the 22-line shift Plan 02 recorded). The property (16 relative repository-path links, then 0) held; I rewrote the links, not the line numbers.

**3. [Plan discretion] Extra helpers in `ShippedDocs`.** `heading_slugs/1` and a `repo_blob_base/0` accessor were added next to the two the plan named, so Plan 04's README link test shares one definition of the GitHub anchor rule. `github_slug/1` keeps connector punctuation (an underscore stays), as GitHub does; the plan's wording listed letters, digits, spaces and hyphens only. No link in the repo depends on the difference.

**4. [Plan discretion] `markdown_links/1` reports the line of the `](`**, so a link whose text wraps across lines is reported where its target sits.

**5. [Plan discretion] The planted-snippet helper subtracts the page's baseline problems**, so a planted case is judged on what it adds and does not depend on the real README staying clean. Extra planted controls beyond the plan: a real anchor, a build-escaping href, a `<link>` tag, a page with no extras region, and (source rule) a link above the root, `blob` to a directory, `tree` to a file, fenced and code-span links.

**6. [Plan discretion] `@repo_path_link` is private to `ShippedDocsContractTest`.** Plan 04's README link test lives in `readme_contract_test.exs` and must copy the one-line regex (house preference: a copy over a new dependency). The definition is stated in the comment above it.

**Total deviations:** 1 auto-fixed (Rule 1); 5 discretion or correction notes. **Impact on plan:** one extra file edited in Task 1 so the scan is green for a real reason; no scope change.

## Issues Encountered

- `scripts/ci/pre_push.sh` took about 8 minutes (the UI token node tests dominated, 129 tests); it ran in the background and finished with exit 0.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. No placeholder, empty-value or TODO text was added.

## Threat Flags

None. The plan touches tests, planning notes and static docs only; nothing is fetched. T-192-07 (false green) is mitigated by the floors and the planted cases; T-192-08 by reading only files inside the per-run build directory (an escaping href is reported without being opened, proven by a planted case); T-192-09 by the `main` ref, path-exists and heading-exists checks; T-192-10 by the 50-link and 16-repository-link floors with margin (298 and 25).

## What this does not prove

- Live hex.pm and hexdocs.pm rendering, external link liveness, GitHub's own anchor rendering beyond the slug rule, and version skew of unversioned HexDocs links. Phase 193's checkpoint records these once.
- Relative links to another extra are checked for existing, not for a valid fragment on the source side (the built-docs scan checks fragments against the real HTML). Same-page `#anchor` links are not checked by the source rule.
- That the built-docs scan sees what the published (`MIX_ENV=dev`) build produces. It runs inside the test VM with the test-support modules loaded, so it can only be stricter than the published build for autolinks (the first deviation), not looser.
- That hosted lanes pass. Run locally: the 14-file doc-pin set (319 tests, 0 failures), `mix docs --warnings-as-errors` (exit 0), `mix format --check-formatted` and `mix credo --strict` on the touched test files, and `scripts/ci/pre_push.sh` (11 passed, 0 skipped, exit 0). Not run: `core`, `package`, `repository-contracts`, `backend`, `ops-ui`, `ecommerce-mounted` (the orchestrator runs the full lane mirrors at the end of Plan 04). `package_metadata_test.exs` runs in `core` and inside `mix verify.package`; the `package` lane was not mirrored here.

## Next Phase Readiness

Ready for 192-04. Notes for the orchestrator:

- The README is untouched. Both new checks already cover it: the source rule scans `README.md` as a docs extra (a relative `guides/x.md` link passes, an absolute `https://hexdocs.pm/...` link is ignored, a repository-path link must be `blob/main` with an existing path), and the built-docs scan covers `readme.html`. A trimmed README with a relative `../examples/...` link, or a link to a file that is not an extra, fails the default test run.
- Plan 04's README link test should reuse the repo-path definition: `^https://github\.com/szTheory/scrypath/(blob|tree)/([^/#?]+)(?:/([^#?]*))?(?:\?[^#]*)?(?:#(.*))?$` (it is `@repo_path_link` in `shipped_docs_contract_test.exs`), plus `ShippedDocs.markdown_links/1`, `github_slug/1`, `heading_slugs/1` and `repo_blob_base/0`.
- Any new guide sentence that names a `@moduledoc false` module in backticks, while the module is loaded in the test VM, now fails the built-docs scan with the page and href. Name a file path instead.
- B13 is done; the inventory fate log has its row (`5cdc6cc1`) and a new TRUTH-03 section. The golden-path config snippet fix is still Plan 04's.

## Self-Check: PASSED

- Edited files present: all 13 listed under key-files, including `192-PIN-INVENTORY.md`.
- Commits reachable from HEAD: `5cdc6cc1`, `4e9fae86`, `790cee11`; measured count `git rev-list --count f6f9fb09..HEAD` is 3.
- Acceptance greps re-run: `link_problems` 5 (floor 3), `def markdown_links` 1, `use absolute GitHub URLs` 1, B13 absolute URL 1, relative repository-path links across all shipped markdown 0 (HEAD was 16).
- `.planning/config.json`, `.planning/state.json`, STATE.md and ROADMAP.md were never staged or touched by these commits; both mutation backups were removed.

---
*Phase: 192-docs-truth-and-readme*
*Completed: 2026-11-21*
