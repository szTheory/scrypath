---
phase: 189-website-re-skin
plan: 01
subsystem: website
tags: [static-site, build-pipeline, contract-tests, playwright, wcag, brand-tokens]

requires:
  - phase: 186-ingest-pin-and-guard
    provides: brand.pin.json hashes and the planted/accept wrapper pattern this plan copies
provides:
  - build.mjs that derives tokens.css from brand/tokens.json through a role map and copies pinned brand files after hash verification
  - serve.mjs that reproduces the production /scrypath/ URL shape (404 at the root, port 0, real MIME types)
  - dependency-free static contract (live, planted, accept) wrapped by an ExUnit file that rides core and repository-contracts
  - CONTRIBUTING ledger row 9 of 12
  - check.mjs rewritten to grouped assertions at /scrypath/ with a proven color resolver
affects: [189-02, 189-03]

actuals:
  tokens: 48000
  tasks: 4
  commits: 6
plan_head_before: d83d6bc5460312039c98b8de3430f59928c75e5b
plan_head_after: c2d8c071413e1bae844c2a3d5375fd87c73a42e7

tech-stack:
  added: []
  patterns:
    - "role map to token path, build throws on an unresolved role; contract keeps an independent second table"
    - "planted cases mutate a copy of a known-good fixture built through the real build"
    - "theme-picker tag plus THEME_MODE so the light-only fallback needs no test edit"

key-files:
  created:
    - website/scripts/theme-mode.mjs
    - website/scripts/lib/server.mjs
    - website/scripts/lib/wcag.mjs
    - website/scripts/lib/contract.mjs
    - website/scripts/lib/golden.mjs
    - website/scripts/site-contract.test.mjs
    - test/mix/tasks/website_contract_test.exs
  modified:
    - website/scripts/build.mjs
    - website/scripts/serve.mjs
    - website/scripts/check.mjs
    - website/package.json
    - dev/mix/tasks/verify.phase99.ex
    - test/mix/tasks/verify.phase99_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "Dark control-edge is the one literal in the build.mjs role map; build and contract both assert it equals the Control Edge sentence in brand.json and tokens.json"
  - "Planted cases mutate a known-good fixture (lib/golden.mjs), not the old site, so each planted code is attributable"
  - "check.mjs splits every contrast pair into a background assertion and a ratio assertion, so the floor of 12 holds in light-only mode too"

requirements-completed: [SITE-01, SITE-02, SITE-04, GATE-02]

duration: about 45min
completed: 2026-11-20
status: complete
---

# Phase 189 Plan 01: Guards and pipeline Summary

**The website now builds its colors, fonts, lockups, favicons and social card from the pinned brand files, serves under the production `/scrypath/` shape, and has a static contract and a browser check that already fail on the old identity.**

This plan is the guards-and-pipeline half of SITE-01, SITE-02, SITE-04 and GATE-02. The re-skin itself (plan 189-02) and the deploy safety net (plan 189-03) are not done here, so those requirements complete later.

## What shipped

1. **Tracer (build to served URL).** `build.mjs` resolves 17 color roles in light and dark, emits `assets/tokens.css` (light `:root`, dark, `system` media block, print), and copies three fonts, three OFL texts, both lockups, both themed favicons, the `.ico` and the social card after comparing each file's sha256 with `brand.pin.json`. It also gained `--out`, `--brand` and `--src` (and env equivalents), the `THEME_COLOR`, `SOCIAL_WIDTH`, `SOCIAL_HEIGHT`, `THEME_PICKER`, `THEME_SCRIPT` and `{{INLINE:name}}` substitutions, and an output-directory guard. `serve.mjs` takes `--base`, `--port 0`, `--dir`, `--log`, answers 404 outside the base, redirects bare directories like Pages does, and serves `.woff2`, `.png` and `.ico` with real MIME types. A real HTTP test fetches `tokens.css` and a hash-checked font under `/scrypath/` and sees 404 at `/`.
2. **Static contract.** `lib/contract.mjs` returns coded violations for source and built output (24 codes). It keeps its own role-to-token table, a closed hex set (every `tokens.json` hex, every `contrastPairs` text and background hex, and the Control Edge sentence hex), and the CSP, font, icon, preload, lockup, OFL, non-ASCII and theme-script rules. `lib/wcag.mjs` holds the copied WCAG math plus a parser for `rgb()`, `rgba()` and `color(srgb ...)`. 78 cases: 27 live (one is the tracer), 41 planted, 10 accept.
3. **ExUnit wrapper and ledger.** `test/mix/tasks/website_contract_test.exs` enforces a floor of 78 test calls, the planted/accept naming rule, a floor of 6 `theme-picker` cases and an `ok N - name` TAP line for every case. `WEBSITE_CONTRACT_PATTERN` allows a filtered local run and flunks under `CI`. The wrapper is in `@focused_tests`, and `CONTRIBUTING.md` has row 9 and "Budget used: 9 of 12."
4. **check.mjs.** Six groups (`production-shape`, `resolver`, `contrast`, `identity`, `theme-picker`, `motion`) with floors, an ephemeral-port server under `/scrypath/`, a resolver proved on planted translucent surfaces, the six brand pair ids in both themes, and a screenshot step that skips dirty trees. `THEME_MODE` switches the picker group to its light-only form.

## Verification run

| Check | Command | Result |
| --- | --- | --- |
| Tracer | `node --test --test-name-pattern='live tracer' website/scripts/site-contract.test.mjs` | pass |
| Old site still builds, brand untouched | `node website/scripts/build.mjs --out "$(mktemp -d)"` then `git status --porcelain -- brand` | exit 0, no changes under `brand/` |
| Planted and accept cases | `node --test --test-name-pattern='^(planted\|accept)' website/scripts/site-contract.test.mjs` | 51 of 51 pass (41 planted including the clean-baseline case, 10 accept) |
| Live cases on the old site | `node --test --test-reporter=tap --test-name-pattern='^live' ...` | the five named cases are `not ok` (count 5) |
| Wrapper, filtered | `WEBSITE_CONTRACT_PATTERN='^(planted\|accept)' mix test test/mix/tasks/website_contract_test.exs` | pass |
| Wrapper, unfiltered | `mix test test/mix/tasks/website_contract_test.exs` | fails on the live cases, as intended; flunks under `CI` with a pattern |
| Wiring | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify.phase99_test.exs` | 88 tests, 0 failures |
| Format | `mix format --check-formatted` on the three touched Elixir files | clean |
| Budget line | `grep -c 'Budget used: 9 of 12\.' CONTRIBUTING.md` | 1 |
| Token deny scan | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 of 59 pass with the new files present |
| Browser, cheap groups | `node website/scripts/check.mjs --groups resolver,production-shape --no-screenshots` | 16 assertions, `failed=none` |
| Browser, expected red | `node website/scripts/check.mjs --groups identity,contrast --no-screenshots` | `failed=contrast,identity,theme-picker` |
| Browser, green candidate | full `check.mjs` against a scratch site built from the fixture plus selectors | 101 assertions, `failed=none` in picker mode; 75, `failed=none` in light-only mode |

The long gates (`mix verify.core`, `mix verify.repository_contracts`) were not run, as the plan requires; plan 189-03 runs each once on the final head.

## Expected red on the old site (intended)

- **Static contract, live cases that fail:** `color-literal`, `repo-only-task`, `carved-out-hex`, `uppercase-transform`, `hex-outside-brand-set`, `font-face`, `font-synthesis`, `csp`, `theme-script theme-picker`, `default-state theme-picker`, `og-image`, `icon-links`, `preload`, `lockups`, `ofl-links`. They go green in plan 189-02. The live cases that already pass are the ones about derived or copied output (`token-mismatch`, `pin-hash-mismatch`, `missing-asset`, tracer) and clean-by-default rules (inline script and style, root-absolute and external URLs, non-ASCII, unthemed favicon).
- **check.mjs on the old site:** `identity` fails (no fonts load, system font family, no lockups, uppercase text, no dark weight), `contrast` fails (gradients under the text, so the surface cannot be resolved; focus ring is 1 px), `theme-picker` fails (no picker, no theme script) and `motion` fails (smooth scroll under reduce, 13 elements keep a transition). `resolver` and `production-shape` pass.
- The old site passes the 320 px overflow check and the fonts-blocked height check (system fonts both ways), so those two are only informative until real fonts load.

## Deviations from Plan

**1. [Rule 3 - Blocking] Added `--src` and `SCRYPATH_SITE_SRC` to build.mjs.** The plan names `--out` and `--brand` only. Without a source override the contract could not build a known-good fixture through the real pipeline, and the new substitutions (`THEME_PICKER`, `THEME_SCRIPT`, `{{INLINE:...}}`) would have gone untested until the re-skin. Commit 8c312ceb.

**2. [Rule 3 - Blocking] Planted cases mutate a known-good fixture, not a copy of the built old site.** The live build is red on the old source, so a planted code could not be told apart from existing defects. `lib/golden.mjs` (new file, not in the plan's list) writes a small source tree that passes the contract with zero violations in both theme modes; every planted case mutates a copy of its real build and asserts the exact code. A baseline case proves the fixture is clean. Commits a2533e97 and 77571d65.

**3. [Rule 3 - Blocking] Local browser is the installed Google Chrome 158, not a downloaded Playwright Chromium.** The plan's `npx playwright install chromium` (Chromium revision 1255 for Playwright 1.65.1) was denied by the session's permission classifier, so I did not download it. I ran the browser groups with `SCRYPATH_BROWSER_CHANNEL=chrome`, which `check.mjs` supports for CI anyway. Playwright is the lockup version, 1.65.1 (`npm ci --ignore-scripts`). So the local runs are Chrome 158, not the bundled Chromium 159 that CI installs; the first hosted run is the evidence for that browser.

**4. [Rule 2 - Missing critical functionality] Output-directory guard in build.mjs and `--parent-pipe` in serve.mjs.** The build removes its output directory, so it now refuses an output that is or contains the repository, `website/`, the source or brand directory, the home directory or a filesystem root (a planted case proves it, built so a broken guard could only delete scratch files). The test server exits when its parent's pipe closes so a crashed run cannot leave a server running.

**5. check.mjs contrast pairs are two assertions each.** A pair is one assertion for the resolved background and one for the ratio. With one assertion per pair the `contrast` floor of 12 could not be met in the light-only fallback (9 assertions); with two it is 16 in light-only and 32 with dark.

**6. Commit slicing.** Task 2 landed as two commits and Task 4 as one (`check.mjs` is a single file, and the plan allows but does not require group commits). A follow-up commit (77571d65) fixed the fixture after a browser run showed its print and forced-colors lockup rules lost on specificity.

**7. Plan-head ledger file not written.** Writing into the worktree's git directory was denied, so `commits` is measured with `git rev-list --count` from the orchestrator-supplied base (d83d6bc5) and recorded above. `commits: 6` is the count before this summary's own docs commit.

## Notes for plan 189-02

- Selectors the checks need on the home page: `.hero`, `.hero-copy .lede`, `.hero-visual .panel-kicker > span:first-child`, `.route-item strong` (on a Panel background), one `.button-primary`, `h1`, `h2`, `code` and `.skip-link` as the first Tab stop. Picker: `.theme-picker` with `role="group"` and three buttons carrying `data-theme-choice` and `aria-pressed`; the markup must ship `hidden`.
- A working reference for the pieces most likely to go wrong is the fixture in `website/scripts/lib/golden.mjs`: a working `theme.js` of 1,490 bytes (the contract's limit is 2048; a first, commented version was over it), and `print` and `forced-colors` lockup rules written as `:root[data-theme] .lockup-light` so they outrank the dark-selector rules. A plain `.lockup-light` in the print block loses.
- Every published ratio reproduces from live computed colors in a browser (body 16.53 and 16.43, descriptor 6.67 and 8.66, caption 7.29 and 8.01, link 8.64 and 6.92, focus 7.91 and 7.49, button 8.64 and 7.49), so a CSS that uses the role variables as the plan describes should pass the contrast group without tuning.
- `HERO_SHIFT_TOLERANCE_PX` is 12 (start value). Chromium serialized colors as `rgb()`, `rgba()` and `color(srgb ...)` (Chrome 158); the resolver parses all three.
- Role inventory: all 17 roles resolve in both themes. Dark `sunken` and `code-bg` are `code.background-dark`; dark `selected` comes from `contrastPairs` (`selected-row` and `selected-status` agree); dark `control-edge` is the role-map literal, equal to the sentence in both brand files.
- `.ico` check: the pinned file holds a 16 and a 32 px PNG, is byte-identical to its pin in the contract and is served as `image/x-icon`.
- `core` runs the wrapper through `mix verify` (the full suite) and `repository-contracts` through `@focused_tests`; no `ci.yml` step was added or needed.

## What this does not prove

Rendered quality and aesthetics, browsers other than Chromium-family (including Safari's handling of the meta CSP), real screen readers, social-platform card cropping, how the `.ico` renders, the Pages `content-type` for `.woff2` (first post-merge smoke), and the bundled Playwright Chromium locally (Chrome 158 was used). The scratch site that showed the browser check can go green is not a design and is not committed. Nothing here claims aesthetic or independent-review approval.

## Known Stubs

None. No placeholder data reaches any page.

## Threat Flags

None beyond the plan's register: `serve.mjs` and the test helpers bind to loopback only, and the path-escape guard is covered by an accept case.

## Self-Check: PASSED

All created and modified files exist; all six task commits are ancestors of the head; the working tree was clean before this file was added; `examples/scrypath_ecommerce/contrast-checker.mjs`, `.github/workflows/ci.yml`, `website/package-lock.json` and the package dependencies are unchanged.
