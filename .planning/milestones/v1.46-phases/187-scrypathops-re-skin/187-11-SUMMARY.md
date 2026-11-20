---
phase: 187-scrypathops-re-skin
plan: 11
subsystem: testing
tags: [host-contract, playwright, ratchet, csp, captures, preservation-guard, canonical-lane, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plans 01 to 10 (fixtures and capture script, fonts, palette, status vocabulary, controls, icons, retired CSS, no-alpha text, motion, the computed-style contract and the ordinary partition)
provides:
  - ops_host_contract.spec.ts, four browser cases (P-17a to P-17d) proving the ops sheet does not leak into the fixture host, a host accent override wins, and a font-src 'self' policy still loads both fonts
  - exact two-way ratchets over the compiled CSS for unscoped selector parts (54) and dual dark rules (12), with planted growth cases (N-11)
  - a one-entry amendment of the pending-state preservation guard so the approved Refreshing… copy no longer fails four loading cases, pinned by a self-test that evaluates the guard's own block
  - the full canonical `mix verify.ecommerce_e2e` lane green on the gate commit (300 of 300: ordinary 239, preservation 61) plus every local gate
  - 12 after captures from the gate commit, and the committed 187-CAPTURE-INVENTORY.md (24 names with sha256, assertion ids by requirement, gates and "What the gates do not prove")
affects: [187-11 orchestrator steps (retained preview refresh and Task 3: Draft PR, hosted dispatch, comment)]

actuals:
  tokens: 16400
  tasks: 2
  commits: 5

plan_head_before: baeca25b5dd8c97ecbbbbf2e71cc8250466b783c
plan_head_after: e6a9754ac200229fac6e45a76b6a19d131ef5eff

tech-stack:
  added: []
  patterns:
    - "a header-probe that must run on a Compose network adds the header through a loopback proxy in the spec process, not page.route plus route.fulfill"
    - "a guard that demands unchanged text lists the approved copy diff inside itself, is pinned to exactly that list, and is tested by evaluating its own source block with planted non-listed changes"
    - "ratchets are exact in both directions: growth fails, and a lower live count fails until the ceiling is lowered to the printed number"

key-files:
  created:
    - examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts
    - .planning/phases/187-scrypathops-re-skin/187-CAPTURE-INVENTORY.md
  modified:
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts
    - scripts/ci/ui_state_pairs.test.cjs
    - test/mix/tasks/ui_contrast_contract_test.exs
    - scrypath_ops/README.md
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md

key-decisions:
  - "The four failing loading preservation cases are fixed by amending the guard, per the orchestrator decision, with the narrowest change: only the whole line `Refreshing…` is read as `Refresh`; route, busy marker and every other line still must match"
  - "N-11 counts selector parts of top-level rules; a rule nested inside another style rule takes its parent's scope and is skipped; `.ops-` anywhere in the same selector part makes it scoped"
  - "P-17d adds its Content-Security-Policy header through a loopback proxy because route.fulfill makes Chromium block every subresource of the document on a private Compose address"
  - "The before captures were not re-taken after the guard amendment: the capture manifest records no overlay digest and a screenshot does not depend on guard code"

requirements-completed: [A11Y-04]

coverage:
  - id: D1
    description: "host contract in a browser: no ops sheet and no accent on host routes, a sentinel host element unchanged across six OS scheme and stored preference combinations and after visiting ops, a host accent override wins, font-src 'self' loads both fonts with no violation (a planted font-src 'none' makes the probe fail)"
    requirement: "A11Y-04"
    verification:
      - kind: e2e
        ref: "ops_host_contract.spec.ts P-17a to P-17d: 4 of 4 on a disposable host stack (127.0.0.1:4102), 4 of 4 inside the canonical browser container (http://web:4002), and in the full lane on 9217f326"
        status: pass
    human_judgment: false
  - id: D2
    description: "unscoped selector parts and dual dark rules in the compiled CSS can only fall"
    requirement: "A11Y-04"
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs: 59 pass (live unscoped selectors stay at the ceiling 54; live dual dark rules stay at the ceiling 12; two planted cases); both directions mutation-checked"
        status: pass
    human_judgment: false
  - id: D3
    description: "the preservation partition is fully green with the approved Refreshing… copy, and the amended guard still fails on any other text change"
    requirement: "SKIN-08"
    verification:
      - kind: e2e
        ref: "canonical mix verify.ecommerce_e2e on 9217f326: 300 expected, 300 passed (ordinary 239, preservation 61), dirty false"
        status: pass
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/ui_state_pairs.test.cjs: 39 pass (5 new guard cases)"
        status: pass
    human_judgment: false
  - id: D4
    description: "12 after captures from the gate commit and the committed inventory"
    requirement: "SKIN-08"
    verification:
      - kind: other
        ref: "reskin-capture.mjs --check on after and before: capture inventory: 12/12 each; after manifest source_sha 9217f326, clean true, git_status []"
        status: pass
    human_judgment: false
  - id: D5
    description: "retained preview preflight before and after, refresh to the head, ui:review inventory, Draft PR, hosted dispatch and comment"
    requirement: "GATE-03, SKIN-08"
    verification: []
    human_judgment: false

duration: 6h
completed: 2026-11-19
status: partial
---

# Phase 187 Plan 11: Host contract, ratchets, final gates and captures Summary

**The host contract now holds in a browser, the unscoped CSS cannot grow, and the whole canonical e2e lane (300 of 300, preservation 61 of 61) and every local gate are green on one commit; the retained-preview refresh and the Draft PR (Task 3) are the orchestrator's and are not done here.**

Status is `partial` by design: the dispatch for this plan excludes the preview preflight, fast-forward and restart, and all of Task 3 (push, Draft PR, hosted dispatch, comment). Everything else in Tasks 1 and 2 is complete.

## What was built

- **Task 1, host contract and ratchets (`5a1a4031`, fix `9217f326`).** `ops_host_contract.spec.ts` has four cases. P-17a: `/` and `/?q=quantum` link no ops stylesheet and compute an empty `--color-primary` (and `/admin/search` computes one, so the probe can see it). P-17b: a bare sentinel element computes the same `color`, `background-color`, `font-family`, `font-size`, margins, `box-sizing` and more in all six OS scheme by stored preference combinations and again after visiting `/admin/search`. P-17c: a rule added with `addStyleTag` after the ops sheet turns `.btn-primary` into `rgb(18, 52, 86)` in light, in an explicit dark theme and in System dark. P-17d: with `font-src 'self'` on the ops document both families have faces that load, `document.fonts.check` is true and no `securitypolicyviolation` fires; a planted `font-src 'none'` makes the same probe see a violation and no loaded face. `ui-tokens.test.mjs` gained N-11: `UNSCOPED_SELECTOR_CEILING` 54 and `DUAL_DARK_RULE_CEILING` 12, exact in both directions (mutation-checked: ceiling 55 and 11 fail with "lower it to 54" and "exceed ... 11"), two live cases and two planted cases. The README hosting notes gained three bullets (link the sheet on ops routes only; a plain `:root` accent override wins; contrast is the host's once it overrides).
- **The guard amendment (`a026c14f`, the orchestrator's decision).** `assertPendingState` now reads the whole line `Refreshing…` as `Refresh` in the observed text and compares the rest exactly; the prior text is never normalized. Five new cases in `scripts/ci/ui_state_pairs.test.cjs` (inside the existing Node step) evaluate the guard's own marked block, pin the allowlist to exactly that one entry, show an approved loading line passes, and plant a changed line, a removed line, an added line, six unlisted loading words, `Refreshing…` standing in for an absent line and the word inside a longer line (all must fail), and check the guard's wiring so the route, text and busy-class comparison are still there.
- **Task 2, gates, captures, inventory, playbook (`bf3dac5d`, `e6a9754a`).** Local gates once on the gate commit, 12 after captures, `187-CAPTURE-INVENTORY.md` and the playbook entries (S8, S22, T9, T17, T19, T20, change log).

## Gate results (`GATE_SHA` `9217f326599095f8d5e150c71b123578b1ade7cd`)

`GATE_SHA` is the last commit with an executable or rendered change. The two later commits are `bf3dac5d` (README prose and one spec header comment; `git diff 9217f326 bf3dac5d` is those two files only) and `e6a9754a` (`.planning/` only). The long gates ran on `9217f326`, not on `bf3dac5d`.

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0 |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail |
| `node --test --test-reporter=tap scripts/ci/ui_state_pairs.test.cjs` | 39 pass, 0 fail |
| root `mix test` on the four `ui_*` contract tests, `--exclude contrast_child` | 29 tests, 0 failures (literal ledger equals the source scan) |
| `mix verify.ops_ui` (`SCRYPATH_OPS_TEST_DATABASE=scrypath_ops_test_187_11`) | boundary 2 tests; 2 doctests, 508 tests, 0 failures, 236 s |
| `mix verify.repository_contracts` | 157 tests, 0 failures, 216 s (normal sandbox; no escalated permission needed) |
| `mix verify.core --exclude integration --exclude docs_contract` | 5 properties, 1158 tests, 0 failures (103 excluded), Standard Maturity Gate PASSED, 319 s |
| `mix verify.package` | 110 tests, 0 failures, 71 s |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan11_mounted`, `E2E_DOCKER_TIMEOUT_SECONDS=2700`) | `Docker verifier passed (scope=focused)`, `containers=0 networks=0 volumes=0 cleanup=clean`, 324 s |
| `mix verify.ecommerce_e2e` (`E2E_PROJECT_NAME=p187_plan11_e2e`, `E2E_DEADLINE_EPOCH` = start + 1800) | exit 0; 300 expected, 300 passed, 0 unexpected, 0 flaky, 0 skipped (ordinary 239 = 235 + 4 host cases, preservation 61); `dirty: false`; 720 s wall, 676 s lane runtime; cleanup clean |
| host spec on a disposable host stack | 4 passed |
| host spec inside the canonical browser container | 4 passed |

Fixture overlay digest in the lane's receipts: `sha256:69893d45ad4b3d5facca629cce9096ff259cdee31582652b29048ea7a6ec3d00` (`sha256:4e3a3b16a3d093cbdc80c71a9a70b806dd75165dd9f5e72c3136cbae092ff586` from Plan 01 through Plan 10); product tree `sha256:639139b79775925835ff45afbf1994498c3992d6e96e435b9502e225c78c0b47`.

## Every run attempt that did not pass

| Run | Result | Cause and what fixed it |
|---|---|---|
| `a026c14f`, canonical `verify.ecommerce_e2e` | exit 1: ordinary 238 of 239, one failure; the verifier stopped before the preservation partition | P-17d (my new spec): `page.route` plus `route.fulfill` to add the CSP header makes Chromium treat the document as public, so on `http://web:4002` it blocked every stylesheet, script and image ("The request client is not a secure context"); no font was requested and no violation fired. It had passed on loopback. Reproduced single-selector in the canonical browser container, fixed with a loopback proxy in the spec process (`9217f326`) and a wait for the late violation event; 4 of 4 in the container, then the whole lane green. |
| `a026c14f`, `verify.ecommerce_mounted` | killed by me before it finished | I stopped it because the commit it was testing was about to be replaced. Its containers never started; I removed its two leftover dependency-boundary images (their labels named `a026c14f`) and the orphaned BEAM. |

The other four gates (`ops_ui`, `repository_contracts`, `core`, `package`) also ran green on `a026c14f` (227, 231, 299, 47 s) and were rerun on `9217f326` as the plan requires.

## Deviations from Plan

1. **[Calibration] The token-test floor is 53, not 42.** `@min_token_test_calls` was 49 before this plan (the instructions said 42); four new cases make 53, and the wrapper floor is now 53.
2. **[Calibration] Measured ratchet baselines.** The first run printed 54 unscoped selector parts and 12 dual dark rules. The plan's research numbers were 52 parts and 23 dual rules from an older stylesheet; later plans retired many dual rules, and my definition also counts `.checkbox::before` and `#flash-group > *`. The code first counted nested relative selectors (72); I fixed that so a nested rule takes its parent's scope. The ceilings are the printed numbers.
3. **[Rule 1] P-17d implementation.** The plan said `page.route`; that cannot run on the Compose network (above). The header now comes from a loopback proxy (`node:http`, no new dependency) that forwards plain requests only, so the page does not connect LiveView; fonts do not need it.
4. **[Plan fact corrected] A CSP is already sent.** `put_secure_browser_headers` adds `base-uri 'self'; frame-ancestors 'self'` to every browser response, so "no CSP is set anywhere" was wrong. It does not restrict fonts; the probe replaces the header and so tests `font-src` alone.
5. **[Judgement] The guard amendment is its own commit** (`a026c14f`), not part of Task 1's commit, so the overlay-digest change is one reviewable change. Its tests sit in `scripts/ci/ui_state_pairs.test.cjs` (already in the CI Node step and already part of the overlay digest), not in the Playwright helper, which cannot be imported by `node --test`.
6. **[Process] The gate commit moved twice.** `a026c14f` then `9217f326`, because of the P-17d failure; every long gate and the captures were redone on `9217f326`. A late finding (a plain `:root` accent override also wins in System dark, so the first README wording and a spec header comment were misleading) was fixed in a prose-only commit after the gates (`bf3dac5d`) instead of a third full rerun; the hosted dispatch on the exact head covers it.
7. **[Calibration] The ordinary partition has 239 cases, not 235 plus a handful.** 235 from Plan 10 plus the four host cases.

## Captures and inventory

`/Users/jon/projects/scrypath/examples/scrypath_ecommerce/ui-review-artifacts/phase187/after/` (12 PNGs and a manifest: label `after`, `clean` true, source `9217f326`, `git_status` empty, Chromium 148.0.7778.96) and `.../before/` (Plan 01, source `3a21916f`) both print `capture inventory: 12/12`. `.../after-superseded-a026c14f/` is the first after set, kept aside because the manifest source commit must equal the gate commit. The committed inventory (`187-CAPTURE-INVENTORY.md`) has the 24 names with sha256, both source commits, the assertion ids by requirement with their commands, the reviewed expectations, the gate results and the heading `What the gates do not prove`. I opened three of the 24 images; the inventory says which and what they show, as facts and not a review.

## Blocked or not done (orchestrator-owned by the dispatch)

- **Retained preview (GATE-03):** the preflight before and after, the fast-forward of `ui-experience-reconciliation` to the head, the seed-disabled restart, `npm run ui:review` and its inventory, and the `.planning/UI-PREVIEW.json` update. I did not touch the preview (compose project `scrypath_ecommerce`, port 4002); it ended `Up 12 hours (healthy)` and `.planning/UI-PREVIEW.json` is unchanged. The acceptance items that need two preflight outputs, the preview HEAD and the `my-search.json` hash (`3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7` in `187-01-SUMMARY.md`) are open.
- **Task 3:** push, Draft PR, `gh workflow run ci.yml` on the exact head, the one comment. Link the inventory at the head SHA in the comment, state the preservation decision as: pair flow not run, geometry differences expected from the font swap, the 136 px lockup and the hairline rows, no baseline recaptured, and the preservation partition is green because of the one-entry guard amendment (not a baseline change). The plan's rule for an overlay-bound preservation failure no longer applies: there is none.
- **After Task 3:** the hosted run is the check for `bf3dac5d` (prose only) and for the exact head.

## Docker and database cleanup

Compose projects used: `scrypath187-p11-host`, `scrypath187-p11-capture` (twice) and `scrypath187-p11-diag`; verifier projects `p187_plan11_e2e` (twice) and `p187_plan11_mounted` (twice, one killed). Each stack was removed with `down -v --rmi local --remove-orphans` or by the verifier's own cleanup (`containers=0 networks=0 volumes=0 cleanup=clean`). Then I removed by exact name the five verifier images, eleven untagged images carrying my compose project labels, and the two dependency-boundary images from the killed run (labels showed `a026c14f`). No `make verify-*` target ran, so no anonymous volume was created (volumes 384 before and after). `scrypath_ops_test_187_11` is dropped (verified absent). The retained preview was never addressed.

| `docker system df` | Before | After |
|---|---|---|
| Images | 317 / 123.1GB | 317 / 123.1GB |
| Containers | 109 / 7.892GB | 109 / 7.892GB |
| Local volumes | 384 / 40.11GB | 384 / 40.11GB |
| Build cache | 469 entries / 26.84GB | 577 entries / 27.15GB (shared across projects, not attributable, not pruned) |

## Notes for later work

- If the pair flow is ever run, qualify afresh: the fixture overlay digest changed in this plan (above).
- A header-probe spec that must run in the Compose lane must not use `route.fulfill`; use the loopback proxy in `ops_host_contract.spec.ts`.
- `UNSCOPED_SELECTOR_CEILING` (54) and `DUAL_DARK_RULE_CEILING` (12) fail in both directions; lowering one needs the printed number and the same edit.
- Scratch diagnostics (the capture-table printer, the blob-report summarizer, the container diag script, the System-dark probe) are in the session scratchpad and not committed.

## Known Stubs

None.

## Threat Flags

None new. T-187-25 and T-187-26: P-17a to P-17d and the N-11 ratchets, with planted growth and a planted `font-src 'none'`. T-187-27: images stay in the ignored directory; only names and hashes are committed. T-187-28: not reached (Task 3 is not run here; nothing was pushed, marked ready or merged). T-187-SC: no package was added (`npm ci` from the lockfile only). The spec's loopback proxy listens on `127.0.0.1` for the length of one case and forwards to the configured base URL only.

## Self-Check

PASSED

- Files exist: `ops_host_contract.spec.ts`, `ui-tokens.test.mjs`, `ui-preservation-states.ts`, `ui_state_pairs.test.cjs`, `ui_contrast_contract_test.exs`, `scrypath_ops/README.md`, the playbook and `187-CAPTURE-INVENTORY.md` (checked with `[ -f ]`).
- Commits are ancestors of HEAD: `5a1a4031`, `a026c14f`, `9217f326`, `bf3dac5d`, `e6a9754a`; `git rev-list --count baeca25b..HEAD` measured 5 before this SUMMARY.
- Acceptance greps: `font-src 'self'` 4 in the spec (at least 1); the two ceiling names 7 in the token test (at least 4); `sha256` 25 lines in the inventory (at least 24); `docker ps -a` for `scrypath187-p11` and `p187_plan11` both 0.
- `git diff --name-only baeca25b..HEAD` touches no `STATE.md`, `ROADMAP.md`, `.planning/config.json` or `.planning/state.json`; every file was staged by path. No pixel baseline or comparator threshold changed.
