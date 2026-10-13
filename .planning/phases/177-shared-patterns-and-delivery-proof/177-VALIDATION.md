---
phase: "177"
slug: "shared-patterns-and-delivery-proof"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-11"
validated: "2026-10-13"
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for the six-surface UI audit and bounded delivery evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView; Playwright for existing browser lanes |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/package.json` |
| **Quick run command** | `mix verify.ops_ui` from the repository root |
| **Full phase UI command** | `mix verify.ops_ui`, plus only the affected existing screenshot, contrast, browser, or mounted target |
| **Estimated runtime** | Not measured in the current shell; record observed duration when the corresponding lane runs |

There is no approved new framework, dependency, CI service, or paid visual judge in scope. Exact hosted evidence covers PR #98 branch SHA `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7`, its same-tree merge SHA `32193307418c00cd83d14d55c208ae145ca51eb3`, and current `main` SHA `017c7389544291b30146d25b73239ed33296d7b7`. Future source changes require their own exact-SHA closeout via `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`.

## Sampling Rate

- After a task changes Ops UI source or a contract test, run `mix verify.ops_ui`.
- For a token/color change, also run `make contrast` and the relevant existing `make contrast-matrix` lane.
- For every changed rendered slice, capture and directly inspect matched before/after screenshots at light, dark, and System-dark across 390×844, 768×900, and 1440×900; run the existing browser/layout/state target for that slice. System-dark capture leaves `phx:theme` unset, emulates dark `colorScheme`, and asserts System mode and effective dark. If the matching route/state is absent from existing fixtures, extend only the existing screenshot matrix with that fixture-backed capture.
- Run `make verify-mounted` only if the change touches a recovery handoff; keep its task-owned cleanup and evidence.
- Before completion, run the existing source-specific checks required for the final diff, record exact-SHA hosted review/check evidence, decide release/no-release from the Hex package file set, and only then run exact-SHA closeout.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-----------------------------|-------------|--------|
| 177-01 T1–T3; 177-02 T1–T2; 177-03 T1–T2; 177-04 T1–T2 | Plans 177-01 through 177-04 | Waves 1–4 | OPUX-26 | — | Preserve contextual grouping, eligibility, truthful states, complete identity/reasons, and distinct safe actions across six surfaces. | ExUnit behavioral suites + Ops UI gate; catalog contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 HEX_HOME=/private/tmp/scrypath-phase177-hex mix verify.ops_ui` (rerun: 2 doctests, 302 tests, 0 failures); Plan 177-01 token contract 8 tests, Plan 177-02 contract 9 tests; Plans 177-03/04 six named LiveView suites (68 and 55 focused tests) recorded passing in summaries | ✅ Existing tests | ✅ green |
| 177-01 T2–T3; 177-02 T2; 177-03 T1–T2; 177-04 T1–T2 | Plans 177-01 through 177-04 | Waves 1–4 | OPUX-27 | — | Preserve keyboard access, visible focus, reduced motion, theme behavior, safe task identity, and responsive content/control reachability. | ExUnit + browser/layout/contrast; direct six-surface image inspection | Existing run records: `npm run test:e2e:admin-depth` (38 passed); full Ops gate above; `make contrast` (0 AA failures); `make contrast-matrix` (3 scenarios); 90-image matrix (10 route/state captures × 3 themes × 3 widths), with selected before/after pairs directly inspected. Evidence and image/source limits are documented in `177-UI-AUDIT.md` and summaries; these browser/image lanes were not rerun in this audit. Route-boundary follow-up: the focused ecommerce controller suite passed 6/6; `mix verify.core --exclude integration --exclude docs_contract` passed 660 tests; `HEX_HOME=/private/tmp/scrypath-hex-cache mix verify.ops_ui` passed 305 tests; and `bash scripts/verify-phase173.sh shell` passed all 14 browser tests with complete cleanup at exact local source SHA `633765dc71fde47366f6f31a6b584cd0d04905b2`. These local runs validate the change and are not hosted CI evidence. | ✅ Existing screenshot matrix and lanes | ✅ green (per recorded exact-source evidence) |
| 177-05 T1–T3 | Plan 177-05 | Wave 5 | OPUX-28 | T-177-05, T-177-06 | Bind claims to source identities and exact check SHAs; preserve unresolved hosted facts and task-owned cleanup boundaries. | Trace artifact validator + hosted evidence + package gate + final attestation | 20-row ordered trace validator and `git diff --check` passed; summary records `mix verify.package` (81 tests, package built). PR #98 run 38339367275 passed at exact branch SHA `83cc3dfda33a30ba38ece7e0bbfc13383c01edc7`; merge closeout run 38340671440 passed at exact merge SHA `32193307418c00cd83d14d55c208ae145ca51eb3`, whose tree matches the branch. Current `main` run 38395852546 passed the five required jobs, coverage, and closeout attestation at `017c7389544291b30146d25b73239ed33296d7b7`. The owner accepted only the missing independent-review evidence as a one-time waiver; no review is claimed. `deep-quality` and `ecommerce-e2e` advisory jobs failed and remain disclosed. | ✅ Trace and hosted evidence exist | ✅ green; no validation coverage gap |
| 177-06 T1–T3 | Plan 177-06 | Wave 6 | OPUX-27, OPUX-28 | T-177-07, T-177-08 | Keep the mounted Ops route boundary slash-delimited; bind checks to the exact candidate head; record the owner's explicit review waiver without claiming independent review; keep provisional and final closeouts separate. | Focused ExUnit regression + exact-head GitHub check runs + merge-source comparison | Isolated PR #101 head `431d2d3265ae0d77c565baf169ed95ba018f0d16` contained only the route predicate and sibling-path regression test; focused controller suite passed 6/6. Run [38417510422](https://github.com/szTheory/scrypath/actions/runs/38417510422) passed all five required checks at that exact SHA; `ops-ui-path` and Website `build-and-check` also passed. The owner authorized squash merge conditional on green required CI; the GitHub review API returned no reviews, so no independent approval is claimed. PR #101 merged at `f0e05bc8857f56f2a030faa45d4da09a510ef625`; both changed source/test files compare identical between head and merge. `deep-quality (advisory)` failed; coverage, ecommerce E2E, path-scoped Ops UI, and closeout were skipped. No closeout has run on the merge or final post-transition source. | ✅ Source, exact-head checks, owner disposition, merge comparison | Required CI green; review requirement explicitly waived by owner; closeout pending |

## Plan 177-06 local, hosted, and merge evidence

The route-boundary change was exercised at local source snapshot `633765dc71fde47366f6f31a6b584cd0d04905b2`: focused ecommerce controller 6/6, core verification 660/660, Ops UI verification 305/305, and mounted-shell browser 14/14. The isolated PR candidate passed the focused controller suite again (6/6) at `431d2d3265ae0d77c565baf169ed95ba018f0d16`.

PR [#101](https://github.com/szTheory/scrypath/pull/101) run [38417510422](https://github.com/szTheory/scrypath/actions/runs/38417510422) passed all five required jobs at exact PR head `431d2d3265ae0d77c565baf169ed95ba018f0d16`; `ops-ui-path` and Website `build-and-check` passed at the same head. The live review API returned an empty list. The owner explicitly authorized marking the PR ready and squash-merging conditional on green required CI; this waived the separate independent-review requirement for this PR only. The PR merged at `f0e05bc8857f56f2a030faa45d4da09a510ef625`; both changed product source/test files compare identical between head and merge. The owner waiver is not an independent review, and no reviewer identity or GitHub approval is claimed. `deep-quality (advisory)` failed in the dependency audit; `coverage`, `ecommerce-e2e`, path-scoped `ops-ui`, and `closeout-attestation` were skipped. No closeout has yet been run on the merged source or final post-transition source.

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements; extend the current Playwright screenshot matrix for direct visual samples without installing a new framework, dependency, or service.
- Create the committed 20-requirement evidence trace and root `DESIGN.md` as planned artifacts; visually inspect all six surfaces before deciding whether any source correction is warranted.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Direct before/after rendered-image inspection across the six surfaces | OPUX-27 | Visual pattern drift and hierarchy need direct inspection in addition to automated layout/state/contrast evidence. This is an execution record, not pending routine human UAT. | The existing screenshot matrix captures each representative state for all six surfaces in explicit light, explicit dark, and System-dark at 390×844, 768×900, and 1440×900. System-dark leaves `phx:theme` unset, emulates dark `colorScheme`, and asserts System mode and effective dark. For each changed slice inspect matched before/after images for all nine theme/viewport combinations; if its exact route/state is not in the current fixtures, add a fixture-backed entry to that existing matrix. Record generated paths and exact source/route/state/theme/viewport identities. Automated behavior/layout/contrast evidence stays separate and complementary. |
| Owner disposition of PR #101's independent-review gate | OPUX-28 | Only the maintainer can waive this trust gate; a waiver is not an independent review. | The owner explicitly authorized marking PR #101 ready and squash-merging if required CI was green. Required checks passed at full head `431d2d3265ae0d77c565baf169ed95ba018f0d16`, and the PR merged at `f0e05bc8857f56f2a030faa45d4da09a510ef625`. GitHub reviews remain empty; no independent review is claimed. This owner waiver applies to PR #101 only. |

## Validation Sign-Off

- [x] Every planned task has an automated verification command or documented artifact gate.
- [x] Sampling continuity has no three consecutive tasks without executable or artifact verification.
- [x] Wave 0 creates no new framework/dependency and covers only actual missing validation artifacts.
- [x] No watch-mode flags are used.
- [x] Feedback latency is recorded from actual runs; no runtime estimate is invented. The rerun of `mix verify.ops_ui` completed in about 17 seconds after dependency compilation began.
- [x] `nyquist_compliant: true` set after executable and artifact coverage was confirmed; each requirement has passing verification or completed visual evidence, and exact branch, merge, and current-main closeout evidence is recorded above. Any future source delta must be re-attested at its own exact SHA.

**Approval:** The pre-follow-up validation audit found no Nyquist coverage gaps. OPUX-26/27 retain passing executable, browser, contrast, and recorded visual evidence; the route-boundary follow-up has local results and exact-head required PR #101 CI. The owner explicitly waived PR #101's independent-review gate, and the PR is merged; the GitHub review API is empty, so no independent review is claimed. This waiver is separate from PR #98's earlier waiver. The provisional verifier-enabling closeout and separate post-transition terminal closeout remain pending. T-177-06 remains a documented medium-severity recordkeeping gap below the blocking threshold; it is not a validation coverage gap.

## Validation Audit 2026-10-12

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

## Validation Audit 2026-10-13

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
