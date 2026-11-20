---
phase: 187-scrypathops-re-skin
plan: 02
subsystem: ui
tags: [fonts, typography, brand-assets, favicon, docker, static-contract, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 01 evidence prep (exact token ceilings, wrapper floor, capture script, before captures)
provides:
  - Hanken Grotesk and Sometype Mono served from the mount prefix with content-hash URLs, at any mount depth
  - Dockerfile asset-builder that keeps the committed fonts in every image
  - 28px Hanken 700 h1, 12px type floor, weight snapping, mono identities and times, no capital-letter transforms
  - brand lockups, symbol, favicon SVG and ICO (byte-identical to brand/) under their frozen names, wordmark at 136px
  - standalone-only font preload and ICO link in the root layout
  - reskin_static_contract_test.exs (E-13, E-14, E-15) and the mounted-lane font request
  - README host note for the re-skin
affects: [187-03, 187-04, 187-05, 187-06, 187-07, 187-08, 187-09, 187-10]

actuals:
  tokens: 9700
  tasks: 3
  commits: 3

plan_head_before: a50fb9118b30b063875db1adcfc7a7a21a9e8450
plan_head_after: f84a5d6b1710917c434d332676d624c897350b2c

tech-stack:
  added: []
  patterns:
    - "CSS-relative font URLs with a content-hash ?v= resolve against <mount>/assets/css/app.css, so one declaration serves every mount depth"
    - "unlayered rules for identity-bearing type, because generated utilities (font-semibold) otherwise beat component-layer rules and synthesize bold on a mono face that has no 600"
    - "request-level font check in a required hosted lane, because font-display: swap hides a 404 behind the fallback face"

key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
  modified:
    - examples/scrypath_ecommerce/Dockerfile
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/e2e/harness.spec.ts
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - test/mix/tasks/ui_contrast_contract_test.exs
    - CONTRIBUTING.md
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/priv/static/favicon.svg
    - scrypath_ops/priv/static/favicon.ico
    - scrypath_ops/priv/static/images/scrypath-wordmark.svg
    - scrypath_ops/priv/static/images/scrypath-wordmark-inverse.svg
    - scrypath_ops/priv/static/images/logo.svg
    - scrypath_ops/README.md

key-decisions:
  - "Identity and mono text is styled by an unlayered rule at the end of app.css (weight 500 for identities and kbd, 400 for code, pre and times), not by utility classes, so Sometype Mono never receives a 600 request"
  - "The glyph coverage set is the intersection of the two subsets; the up and down arrows (mono only) are not covered, so a rendered arrow fails until it is moved or allowlisted"
  - "@min_token_test_calls in the ExUnit wrapper moves from 39 to 42 because this plan added three token-test cases; the floor keeps meaning 'the real count'"

requirements-completed: []

coverage:
  - id: D1
    description: "fonts are declared once with relative hash-pinned URLs, served 200 with an immutable header at /ops, and fetched with 200 through /admin/search/assets/fonts in the required mounted lane; Docker images keep them"
    requirement: "SKIN-02"
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs (live font URLs are relative and hash-pinned, plus two planted cases)"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs (E-14 font faces, E-15 font serving at /ops, /admin/search and /a/b/c)"
        status: pass
      - kind: e2e
        ref: "examples/scrypath_ecommerce/e2e/harness.spec.ts#mounted ops fonts load from the mount prefix (mix verify.ecommerce_mounted, GATE_SHA)"
        status: pass
    human_judgment: false
  - id: D2
    description: "h1 28px/700 with title leading and tracking, 12px floor, weight snapping, mono identities and times, no capital-letter transform, glyph coverage guarded over the six screens and CSS content strings"
    requirement: "SKIN-06"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs (E-14 glyph coverage, planted U+2500) and design_tokens_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "lockups, symbol, favicon SVG and ICO are byte-identical to brand/ under frozen names; ICO has 16 and 32 px entries; standalone layout preloads the interface font with crossorigin and links the ICO; mounted host layout has no preload; wordmark 136px"
    requirement: "SKIN-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs (E-13 brand assets, E-15 root layout links and font preload)"
        status: pass
      - kind: cli
        ref: "MIX_ENV=test mix verify.brand (verify.brand: ok, 44 assets)"
        status: pass
    human_judgment: false
  - id: D4
    description: "required-gate ledger lists the two new gates and reads Budget used: 7 of 12.; allowlist ceilings equal the live counts (17 entries, 471 hits)"
    requirement: "SKIN-02"
    verification:
      - kind: integration
        ref: "test/mix/tasks/workflow_wiring_test.exs (budget ledger) and ui-tokens.test.mjs (live allowlist entries are current and tagged)"
        status: pass
    human_judgment: false

duration: 1h50m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 02: Brand fonts, type floor, lockup and favicon Summary

**The brand fonts now ship end to end (and are proven to reach the mounted Docker image), the h1 is Hanken 700 at 28 px on a 12 px floor with mono identities and no capital-letter transforms, and the real brand lockup and favicon are served at 136 px under their frozen names.**

GATE-02: this is the phase's first rendered change. The ScrypathOps screens now render in Hanken Grotesk and Sometype Mono with the new lockup; colors, status wording and layout are untouched (later plans).

Status is `complete` for this plan's scope. SKIN-02, SKIN-03 and SKIN-06 are advanced, not closed: the browser computed-style checks for them (P-02, P-11, P-14 and the others in the validation map) belong to Plans 09 and 10, so `requirements-completed` is empty here and the orchestrator decides when to mark them.

## What was built

- **Task 1, font delivery (tracer).** Four `@font-face` blocks (Hanken 400 to 700, Sometype Mono 400 to 500, and the two metric-adjusted `local()` fallbacks) with CSS-relative `../fonts/<file>?v=<sha256>` URLs and `font-display: swap`; `--font-sans` and `--font-mono` in `@theme`. The display face is never declared. The demo Dockerfile's asset-builder used to delete the whole `scrypath_ops/priv/static/assets` tree, which removed the committed fonts from every image; it now deletes only the generated `css` and `js` subtrees. Checks: a Node test recomputes the font hashes and fails on a wrong hash or a root-absolute URL; an ExUnit contract checks the declarations, the exact fallback numbers, `/ops/assets/fonts/*.woff2` serving (200, `font/woff2`, immutable) and that the URLs resolve to `<prefix>/assets/fonts/` for `/ops`, `/admin/search` and `/a/b/c`; and `harness.spec.ts` fetches both fonts through `/admin/search/assets/css/app.css` in the required mounted lane.
- **Task 2, type.** `--text-ops-h1` 1.75rem with `--leading-ops-title` 1.2 and `--tracking-ops-title` -0.01em; `--text-ops-xs` 0.75rem (the 12 px floor); weights snapped to what ships (500 and 650 to 600 on Hanken and 500 on mono, 700 to 600 except the h1, no `font-medium`); the four hard-coded monospace stacks replaced by `var(--font-mono)`; schema and index names carry `data-ops-identity`; every capital-letter transform removed from the CSS and from the two component class strings (labels are sentence case, 12 px, 600, 0.01em). `DESIGN-TOKENS.md` records the size scale and the new floor sentence, and its pin in `design_tokens_contract_test.exs` moved with it. A glyph coverage test renders the six screens (plus the all-statuses fixture) and every CSS `content:` string and fails on any non-ASCII character outside the font subsets and the three-entry fallback list (`·`, `›`, `⌘`).
- **Task 3, brand assets.** The five files are plain `cp` copies of the pinned brand sources under the frozen names; the ICO holds the 16 and 32 px entries. The standalone root layout links the SVG and the ICO and preloads `ui.woff2` with `crossorigin`; the mounted host layout has no preload (asserted). `brand_mark/1` and `.ops-wordmark` give 136 px (`8.5rem`, `flex: none`). The four retired-asset allowlist entries are gone. `scrypath_ops/README.md` has the host note.

## Gate results (GATE_SHA `f84a5d6b1710917c434d332676d624c897350b2c`, the last code commit)

| Check | Result |
|---|---|
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 48 pass, 0 fail (includes "live font URLs are relative and hash-pinned" and the two planted font cases) |
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0 |
| `scrypath_ops` `mix test` on `reskin_static_contract_test.exs`, `asset_plug_test.exs`, `ops_shell_contract_test.exs` and the four ops CSS regex tests | 0 failures (reskin file: 19 tests) |
| root `mix test` on `workflow_wiring_test`, `ui_contrast_contract_test` (`--exclude contrast_child`), `ui_tokens_contract_test`, `ui_tokens_helper_test`, `ui_literal_contract_test`, `brand_pin_contract_test` | 198 tests, 0 failures (the literal ratchet ledger equals the source scan) |
| `MIX_ENV=test mix verify.brand` | `verify.brand: ok (44 assets, 326773 bytes)` |
| `mix verify.ops_ui` | boundary test, then ops suite 2 doctests + 350 tests, 0 failures |
| `mix verify.repository_contracts` | 157 tests, 0 failures (376 s); ran through the escalated route per AGENTS.md for the `origin/main` fetch |
| `mix verify.core --exclude integration --exclude docs_contract` | 5 properties, 1158 tests, 0 failures (103 excluded); Standard Maturity Gate PASSED; isolated no-Oban compile clean |
| `mix verify.ecommerce_mounted` (project `scrypath187-p02-mounted`, escalated Docker) | passed on the second attempt (see Deviations 7): dependency-boundary proof passed, then 5 Playwright tests passed including "mounted ops fonts load from the mount prefix"; verifier cleanup `clean` |
| `git diff --name-only GATE_SHA..HEAD` after the SUMMARY commit | only `.planning/` paths |

Tracer note (Task 1): `type="tracer"` with no `gate="blocking-human"`, auto mode off, `<verify>` automated only, so the three Task 1 verify commands were re-run before Task 2 started and passed: Tracer verified end-to-end, expanding.

## Printed numbers

- Allowlist ceilings: the test printed "ALLOWLIST_CEILING is 21 but the allowlist has only 17 entries: lower it to 17" and "allowlist max_hits add up to 471, under HITS_CEILING 483"; both were set to 17 and 471 (the plan's expectation held).
- Font hashes (recomputed by the tests, not copied): `ui.woff2` b9929d24..., `mono.woff2` d8c5ea4c... (match UI-SPEC).
- Glyph coverage read with fontTools 4.62.1 from the pinned files: both subsets lack `·` `›` `⌘`; the mono subset also has U+2191 and U+2193, the Hanken subset does not.

## Gate-ledger counting rule (CONTRIBUTING "Required-gate budget")

A new contract test file, or a new check that runs in a required lane, counts as one gate; assertions added to an existing required file do not. Phase 187 adds three gates: the re-skin static contract and the mounted font check (this plan, 5 to 7 of 12) and the re-skin component contract (Plan 04, 7 to 8 of 12). The ledger now has two new rows and reads `Budget used: 7 of 12.`; `workflow_wiring_test.exs` parses it and passes (both new enforcing files exist).

## Docker cleanup and usage

- Everything used the task-scoped project `scrypath187-p02-mounted` (no host port: the e2e overlay publishes none) and `BUILDX_CONFIG=/private/tmp/scrypath187-buildx`. I never touched the retained preview (`scrypath_ecommerce` on 4002; it stayed `Up (healthy)` throughout).
- Removed after the runs: the compose containers, network and volumes (verifier cleanup `clean`), the images `scrypath187-p02-mounted-web` and `scrypath187-p02-mounted-browser`, and from the failed first attempt the leftover `scrypath_dependency_boundary_20261119t104042z-...:asset-builder` image and my orphaned `docker build` client. A final check shows 0 containers, images, networks or volumes matching `scrypath187` or `scrypath_dependency_boundary`.
- `docker system df` before the Docker runs: Images 315 (120.3 GB), Containers 111 (7.892 GB), Volumes 384 (40.06 GB), Build Cache 168 entries (12.8 GB). After cleanup: Images 315 (120.3 GB), Containers 111 (7.892 GB), Volumes 384 (40.06 GB), Build Cache 224 entries (15.5 GB). The extra ~2.7 GB is shared, unlabelled BuildKit cache from two cold builds. I left it (as in Plan 01) because pruning unlabelled shared cache can hit other projects' in-use entries; nothing was pruned.
- The task-scoped Postgres database `scrypath_ops_test_187_02` was dropped (verified absent).

## Blocked gates

None. Every gate ran and passed. (The first mounted-lane attempt failed on a time budget, not on a check; see Deviations 7.)

## Deviations from Plan

### Auto-fixed issues and judgement calls

**1. [Rule 3 - Blocking] `ops_metric` value cannot use a 600 weight on the mono face**
- **Found during:** Task 2
- **Issue:** `ops_metric/1` styles its value `font-mono ... font-semibold`, and Sometype Mono ships only 400 and 500, so the browser would synthesize bold. The plan forbids `font-medium` in `lib/` (acceptance count 0), so the class could not just change.
- **Fix:** dropped `font-semibold` from that class string; the unlayered rule gives `.ops-metric__value` weight 500. (No template calls `ops_metric` today.) **Commit:** `d19b9038`

**2. [Rule 3 - Blocking] Identity and mono weights needed an unlayered block, not a component-layer rule**
- **Found during:** Task 2
- **Issue:** Tailwind's utilities layer beats the components layer, so `font-semibold` on the schema-name `h3` would win over a component rule and request 600 from the mono face.
- **Fix:** one unlayered block at the end of `app.css` (like the existing "Cascade-safe" blocks) sets the mono family, weight 500 for `[data-ops-identity]`, `kbd` and `.ops-metric__value`, weight 400 for `code`, `pre`, times and the inline-code class, and `font-variant-ligatures: none` on code, pre and kbd. **Commit:** `d19b9038`

**3. `layouts.ex` edit landed in the Task 2 commit.** The plan lists `layouts.ex` only under Task 3, but Task 2's acceptance requires zero `font-medium` in `lib/`, and the skip-link `focus:font-medium` lives there. The `brand_mark` width change is in Task 3 as planned.

**4. Wrapper floor 39 to 42.** `@min_token_test_calls` in `ui_contrast_contract_test.exs` rises by the three token-test cases this plan added (one live, two planted), so the floor still equals the real count and deleting one case still fails the wrapper. The plan did not ask for this; Plan 01's summary said later plans own the floor. `@token_test_names` needed no edit (the wrapper already requires every `test("...")` name).

**5. Glyph test scope choices.** `@covered` is the intersection of the two subsets (not the union), so a rendered up or down arrow fails until it is moved to a mono-only element or allowlisted; none is rendered today. The test also reads rendered attribute text (`title`, `aria-label`, `placeholder`, `alt`, `value`) and a seventh screen, the all-statuses Search health fixture, so every status word is covered. Row templates that only render with real failed-sync data are covered by the fixture and the static screens, not by seeded failed rows (a gap, recorded below).

**6. Unused `.uppercase` utility remains in the built stylesheet.** Tailwind's source scan (`@source "../css"`) reads the word "uppercase" in `scrypath_ops/assets/css/contrast-pairs.mjs` notes ("uppercase sidebar nav group label", "uppercase signal metric term") and in `DESIGN-TOKENS.md`, so it still emits an unused `.uppercase` class. No element uses it (source `app.css` and `lib/` have zero), and the computed-style checks in Plan 10 look at elements, not at this class. I left `contrast-pairs.mjs` alone: it is part of a fixture-overlay digest and Plan 08 rewrites its alpha-text entries anyway. Plan 08 should reword those two notes so the built CSS drops the class.

**7. First `verify.ecommerce_mounted` attempt timed out; the second passed.** The first attempt failed in the independent dependency-boundary proof: the cold, no-cache `runtime_test` build had a ~930 s gap with no output between two dependency compiles while the shared host's load average was 11 to 13, so the verifier's 900 s per-operation budget expired (exit 124) before the Compose stack started. I stopped my orphaned `docker build` and removed its leftover image, then reran with the verifier's own `E2E_DOCKER_TIMEOUT_SECONDS=2700`. That variable only changes the wall-time allowed per Docker operation; the proof and the Playwright specs are unchanged, and hosted CI keeps the 900 s default. The rerun passed (boundary proof, 5 of 5 specs, clean cleanup). I did not run a negative case (old Dockerfile) through the lane: the Dockerfile cause is read from the file and RESEARCH D-1, and the passing font request proves the fix is present.

**8. Process note.** In a mutation check I ran `git checkout -- root.html.heex` to undo a one-line change, which also discarded my uncommitted layout edits. I re-applied them before committing and the E-15 preload test and the standalone `GET` assertions pass on the committed tree.

### Calibration

All plan numbers held: 12 weight declarations (ten 650, two 500), four capital transforms, four monospace stacks, three `font-medium`, the allowlist counts 17 and 471, and the four allowlist entries removed. The tracked built CSS is not byte-identical to a fresh build at the base (Phase 186 already noted this in the token-test header), so the first rebuild showed a large diff (about +287 and -215 lines) that includes utilities for classes already in source; the token test compares tokens, not bytes.

## Decisions / what later plans must know

- Anything that styles schema or index names, times, code, keys or metric values must keep to the faces' real weights: Hanken 400, 600, 700; Sometype Mono 400, 500. Put new mono rules in the unlayered block or avoid weight utilities on those elements.
- Mono identities are marked with `data-ops-identity`. Plan 04's row components should add it to any new schema or index name heading.
- The up and down arrows are not in the Hanken subset. Use text `→` and `←`, or keep arrows on mono-only elements, or extend the allowlist deliberately.
- Token ceilings are exact (Plan 01). This plan lowered the allowlist pair to 17 and 471; later plans that change allowlist entries or hits edit the JSON and `ui-tokens.test.mjs` together, and the token test prints the number.
- Required-gate budget: 7 of 12 used. Plan 04 adds one more (the component contract), to 8.
- Gap for Plan 10: glyph coverage is not exercised with seeded failed-sync rows or the saved-search sheet; the browser lane should render those states for P-02.

## Known Stubs

None.

## Threat Flags

None. The only new request is the font preload, a GET to the existing `AssetPlug` route; no router, plug or schema change. T-187-04 to T-187-07 mitigations are in place: no plug change, byte-equality and `verify.brand` for the brand files, narrowed Dockerfile deletion plus the required-lane font request, and `font-src 'self'` documented in the README. No package was added.

## Self-Check: PASSED

- Files exist: `reskin_static_contract_test.exs`, the five brand files under `scrypath_ops/priv/static`, `scrypath_ops/README.md`, `DESIGN-TOKENS.md`.
- Commits are ancestors of HEAD: `18a9850d`, `d19b9038`, `f84a5d6b`.
- `git diff --name-only a50fb911..HEAD` touches no `STATE.md` or `ROADMAP.md`.
