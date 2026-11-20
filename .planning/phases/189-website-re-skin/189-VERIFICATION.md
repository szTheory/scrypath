---
phase: 189-website-re-skin
verified: 2026-11-20T19:15:00Z
status: passed
score: 7/7 must-haves verified (rollback gap closed by the review-fix commits)
behavior_unverified: 0
overrides_applied: 0
verified_head: 5c1d461c
does_not_prove: "Rendered quality and aesthetics (no approval or independent review is claimed); any browser other than Chrome 158 (Safari's handling of the meta Content-Security-Policy in particular); real screen readers; social-platform card cropping; how the .ico renders; the content-type GitHub Pages sends for .woff2 and the live deploy and smoke result (pending by design); the hosted behavior of the runner-Chrome browser step and of the bundled Playwright Chromium; and that the rollback path works for a pre-merge ref (it does not, see the gap)."
covered_files:
  - .github/workflows/website.yml
  - .planning/phases/189-website-re-skin/189-01-PLAN.md
  - .planning/phases/189-website-re-skin/189-01-SUMMARY.md
  - .planning/phases/189-website-re-skin/189-02-PLAN.md
  - .planning/phases/189-website-re-skin/189-02-SUMMARY.md
  - .planning/phases/189-website-re-skin/189-03-PLAN.md
  - .planning/phases/189-website-re-skin/189-03-SUMMARY.md
  - CONTRIBUTING.md
  - dev/mix/tasks/verify.phase99.ex
  - docs/releasing.md
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/mix/tasks/verify.phase99_test.exs
  - test/mix/tasks/website_contract_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - website/package.json
  - website/scripts/build.mjs
  - website/scripts/check.mjs
  - website/scripts/lib/contract.mjs
  - website/scripts/lib/golden.mjs
  - website/scripts/lib/server.mjs
  - website/scripts/lib/wcag.mjs
  - website/scripts/serve.mjs
  - website/scripts/site-contract.test.mjs
  - website/scripts/smoke.mjs
  - website/scripts/theme-mode.mjs
  - website/src/assets/styles.css
  - website/src/assets/theme.js
  - website/src/layout.html
  - website/src/pages/docs.html
  - website/src/pages/index.html
  - website/src/pages/operators.html
  - website/src/partials/diagram.svg
  - website/src/partials/theme-picker.html
covered_digest: "v4:sha256:be2787766e6e26d9a291aba7ab0a8d6b5f88a76e8e00f0aecc2d6f9c56ae7b2d"
pending_by_design:
  - item: "Exact-head check-runs for the PR head (build-and-check success with head_sha equal to the head, six required contexts green)"
    owner: "orchestrator, before the squash merge"
  - item: "Post-merge deploy run for the merge commit, smoke step output (font 200, font/woff2, pinned hash, both lockups, social card, favicon.ico, all under /scrypath/)"
    owner: "orchestrator, after the merge"
  - item: "After numbers for the browser install in CI-EFFICIENCY.md finding 5"
    owner: "orchestrator, after the merge"
gaps:
  - truth: "A workflow_dispatch rollback to a ref that predates smoke.mjs ends in a defined soft check instead of a red (189-03 must-have truth 3), so the documented rollback works for the commit just before this phase's merge"
    status: partial
    reason: "On main, every ref that predates smoke.mjs is the old site, whose website/scripts/check.mjs launches plain chromium.launch() and ignores SCRYPATH_BROWSER_CHANNEL. The new Select browser step sets SCRYPATH_BROWSER_CHANNEL=chrome and skips the Playwright Chromium install whenever the runner's Chrome launches (the expected case on ubuntu-24.04). So build-and-check goes red at Run site checks for that ref, the deploy job (needs: build-and-check) is skipped, and the soft-check branch is never reached. Reproduced locally: the old check.mjs with SCRYPATH_BROWSER_CHANNEL=chrome and no Playwright Chromium installed exits with browserType.launch: Executable doesn't exist. The likeliest rollback target after a red first smoke is exactly that pre-merge commit."
    artifacts:
      - path: ".github/workflows/website.yml"
        issue: "Select browser step chooses the Chrome path without checking that the checked-out check.mjs honors SCRYPATH_BROWSER_CHANNEL"
      - path: "test/mix/tasks/workflow_wiring_test.exs"
        issue: "assert_website_safety_net! asserts the step's text shape only; no case covers a ref whose check script lacks channel support"
      - path: "docs/releasing.md"
        issue: "Rollback section says a pre-smoke ref ends in the soft check; it does not say the ref's own check script must still launch"
    missing:
      - "In the Select browser step, take the Chrome path only when the checked-out check script supports it (for example grep -q SCRYPATH_BROWSER_CHANNEL scripts/check.mjs before the google-chrome probe), otherwise run npx playwright install --with-deps chromium"
      - "One workflow_wiring_test planted mutation that removes the guard and is rejected"
      - "Either that fix plus one fresh gate run on the new SHA and a re-issued receipt (workflow, test and docs edits are outside .planning/), or an accepted override recorded in the phase record with the operational workaround (roll back a pre-merge ref by revert PR)"
---

# Phase 189: Website re-skin Verification Report

**Phase Goal:** A visitor sees the website in the plum/orchid identity (palette, Hanken, Bricolage and Sometype Mono fonts, light and dark lockups and favicons, PNG social card), light by default with a remembered Light/Dark/System choice, everything derived from the pinned `brand/` files at build time and proved, including against the production URL shape, before and after the merge that deploys it.
**Verified:** 2026-11-20T19:15:00Z, code head `5c1d461c`
**Status:** gaps_found
**Re-verification:** No, initial verification

## Verdict in plain language

The goal is achieved for everything that can exist before the push: the site builds in the plum and orchid identity from the pinned brand files, is light by default with a working Light, Dark and System picker, and holds up served under `/scrypath/`. I re-ran the cheap checks myself, built the site into a scratch directory, ran the full browser check in a scratch copy, and broke the checks on purpose to see them fail. One real defect turned up in the deploy safety net: the documented rollback does not work for the commit just before this merge. That is small to fix. The three post-ship items are empty by design and are not gaps; none is routed to human verification.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | SC1: dependency-free static contract (byte identity to `brand.pin.json`, token parity through the role map, no color literal in `website/src`, closed hex set, no root-absolute URL, og meta, CSP, `font-display`, glyph set) with planted and accept cases, in `core` and `repository-contracts`, ledger row 9 of 12 | ✓ VERIFIED | `node --test website/scripts/site-contract.test.mjs`: 82 of 82 pass on Node 26.10, 22.14 and 20.18. I hashed all 12 served brand files against the pin myself: all match. `tokens.css` matches `brand/tokens.json` for every role in light, dark and print; dark selected `#2B2130` and dark control-edge `#8F7F94` come from a contrast pair and the Control Edge sentence. Closed set is tokens.json plus exactly those two hexes (computed). Wrapper `website_contract_test.exs` (floor 82, planted and accept naming) is in `verify.phase99` `@focused_tests` and the full suite. `CONTRIBUTING.md` row 9, "Budget used: 9 of 12." Mutations below. |
| 2 | SC2: theme behavior at `http://127.0.0.1:<port>/scrypath/` (JS off, empty and blocked storage, dark device, Light/Dark/System, reload, System follows the device, `DOMContentLoaded` paint, reduced motion, forced colors, print) | ✓ VERIFIED | `check.mjs --no-screenshots` in a scratch copy at HEAD with Chrome 158 and Playwright 1.65.1: 101 assertions, `failed=none`, all 22 theme-picker and 3 motion assertions ok. Picker shipped, the light-only fallback was not taken (`THEME_MODE` picker). Mutations bm1 and bm3 caught. |
| 3 | SC3: identity renders (three pinned woff2 on home, subset elsewhere, each 200 and hash-checked, computed Bricolage, Hanken and Sometype Mono, one lockup per theme, icons, contrast per pair id in both themes through a proven resolver, no 320 px overflow, fonts-blocked height shift, no console error or CSP violation or off-origin request) | ✓ VERIFIED | Same run: every identity, contrast and resolver line ok; published ratios reproduce (16.53 and 16.43, 6.67 and 8.66, 7.29 and 8.01, 8.64 and 6.92, 7.91 and 7.49, 8.64 and 7.49); hero and h1 shift 0.0 px at 390 and 1440. I read `index.html` head: CSP meta first after charset, absolute PNG `og:image` and `twitter:image` with 1280 by 640 matching the PNG header (read myself), `.ico` holds 16 and 32 px, light and dark SVG icons, unthemed `favicon.svg` absent from the build. The card's alt text matches what the PNG shows. |
| 4 | SC4: old website palette in the deny set in the same commit as the swap, both `p189` entries gone, ceilings 5 and 197 | ✓ VERIFIED | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`: 61 of 61 pass. `DENY_HEX` gained exactly the 18 values of D-36; `"tag": "p189"` count 0; ceilings 5 and 197; planted old-palette and accept cases present and passing; the three carved-out hexes appear nowhere in `website/`; `brand/**` is in both workflow filters. |
| 5 | SC5 (pre-merge part): deploy job has its own `cancel-in-progress: false` group, `id: deployment`, smoke step; rollback by `workflow_dispatch` with `ref` documented; non-required decision and re-open trigger recorded; no `mix verify.*` string in website source with `phase110` and `phase112` green; one gate run per SHA, no stale receipt, no dirty-tree capture, does-not-prove line | ✓ VERIFIED (see gap on rollback reach) | `actionlint` clean. `workflow_wiring_test` and the website wrapper: 88 tests, 0 failures. `phase110`, `phase112` and `no_human_gates`: 10 tests, 0 failures. `docs/releasing.md` has the section. `smoke.mjs` run by me against the served build: exits 1 with a clear message with no URL; its offline accept and planted cases pass. Receipt SHA `76948c2e` is an ancestor of HEAD and `git diff --name-only 76948c2e HEAD` lists only three `.planning/` files, so the receipt is not stale. The screenshot step refuses a dirty tree. |
| 6 | SITE-06: no website source names a repo-only task, and each replacement sentence is true | ✓ VERIFIED | The built pages name only `mix scrypath.status`, `failed` and `reconcile`; all three exist in `lib/mix/tasks`, and the shipped docs say status prints sync visibility and failed lists failed or retrying work. Planted mutation m8 (re-adding `mix verify.adopter`) is caught. Scope judgment below. |
| 7 | 189-03 truth 3 (second half): a rollback to a ref that predates `smoke.mjs` ends in the defined soft check instead of a red | ✗ FAILED (partial) | See the gap. Reproduced, not inferred. |

**Score:** 6/7 truths verified (0 behavior-unverified). The three post-ship items are excluded from the denominator because they cannot exist before the push; they are listed under Pending by design.

### Pending by design (not gaps, not human verification)

| # | Item | Command (from the phase record) | Owner | Result |
| --- | --- | --- | --- | --- |
| 1 | Exact-head check-runs on the PR head | `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs --jq '.check_runs[] \| [.name, .status, .conclusion, .head_sha] \| @tsv'` | orchestrator, before the squash merge | empty until the push |
| 2 | Post-merge `deploy` run and smoke output, and the first live `.woff2` content-type | `gh run list --workflow website.yml --branch main --limit 5 ...`, then `gh run view <id> --log` | orchestrator, after the merge | empty until the merge |
| 3 | After numbers for the browser install | `gh run view <id> --json jobs` | orchestrator, after the merge | empty until the merge |

The procedures, owners and pass conditions for all three are written down in `189-PHASE-RECORD.md`, so the work after the merge is a command, not a decision.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `website/scripts/build.mjs` | role map, `tokens.css`, pin-checked copies, `--out` | ✓ VERIFIED | Built to a scratch dir. Removing a token role, changing the Control Edge sentence by one digit, and flipping one font byte each stop the build with a named error (checked by hand). |
| `website/scripts/serve.mjs`, `lib/server.mjs` | `--base`, `--port 0`, MIME types, 404 at root | ✓ VERIFIED | Served under `/scrypath/` in the browser run; production-shape group ok. |
| `website/scripts/lib/contract.mjs`, `site-contract.test.mjs` | coded violations; live, planted, accept | ✓ VERIFIED | 82 cases. |
| `website/scripts/check.mjs` | grouped assertions with a proven resolver | ✓ VERIFIED | 101 assertions at HEAD. |
| `website/scripts/smoke.mjs` | live-URL smoke | ✓ VERIFIED offline | Hosted run pending by design. |
| `website/src/*` (layout, styles, theme.js, partials, pages) | variables-only identity | ✓ VERIFIED | Independent grep: no hex, rgb, hsl, gradient, named color or uppercase in source; one `color-mix` for a shadow; `[hidden]`, forced-colors, print and reduced-motion blocks present; no `data-theme` hard-coded; `theme.js` is a classic synchronous head script of 1,791 bytes. |
| `test/mix/tasks/website_contract_test.exs`, `workflow_wiring_test.exs` | wrapper and workflow contract | ✓ VERIFIED | Pass; nine planted workflow regressions are in the test. |
| `.github/workflows/website.yml` | filters, timeout, deploy group, smoke, dispatch | ⚠️ VERIFIED with the rollback gap | Shape is right; one reachability defect. |
| `docs/releasing.md` | deploy and rollback section | ⚠️ VERIFIED with the same gap | Reads true except for the pre-merge-ref case. |
| `.planning/.../189-PHASE-RECORD.md`, `189-GATE-RECEIPT.md` | decisions, procedures, receipt | ✓ VERIFIED | Present and consistent with the code. |

### Key Link Verification

| From | To | Via | Status |
| --- | --- | --- | --- |
| `build.mjs` | `brand/tokens.json` | role map throws on an unresolved role | WIRED (mutation b1) |
| `build.mjs` | `brand/brand.pin.json` | sha256 check before copy | WIRED (mutation b3) |
| `website_contract_test.exs` | `site-contract.test.mjs` | TAP run, floor 82, name rules | WIRED |
| `verify.phase99.ex` | `website_contract_test.exs` | `@focused_tests` entry plus its own test | WIRED |
| `CONTRIBUTING.md` row 9 | `workflow_wiring_test.exs` | enforcing file named; budget line equals row count | WIRED |
| `layout.html` | `theme.js` | `{{THEME_SCRIPT}}` expands to a plain head script after the stylesheets | WIRED |
| `styles.css` | `tokens.css` | `var(--role)` only | WIRED |
| `retired-identity-allowlist.json` | `ui-tokens.test.mjs` | ceilings equal the file | WIRED |
| `website.yml` deploy | `smoke.mjs` | `SCRYPATH_SMOKE_URL` from `steps.deployment.outputs.page_url` | WIRED (hosted run pending) |
| `website.yml` rollback input | a pre-merge ref's own check script | Select browser step | NOT WIRED for that ref class (the gap) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
| --- | --- | --- | --- | --- |
| `dist/assets/tokens.css` | every role value | `brand/tokens.json` and `brand.json` through the role map, one literal checked against the brand sentence | yes | ✓ FLOWING |
| `dist/assets/fonts/*`, lockups, icons, card | file bytes | pinned `brand/` and `scrypath_ops` font copies, hash-checked | yes | ✓ FLOWING |
| `theme-color` meta | `#F8F4F2` | role map at build, computed `--page` at runtime | yes | ✓ FLOWING |

### Behavioral Spot-Checks (run by me)

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Static contract | `node --test website/scripts/site-contract.test.mjs` | 82 pass, Node 26.10 / 22.14 / 20.18 | ✓ PASS |
| Deny set and allowlist | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 61 pass | ✓ PASS |
| Workflow and wrapper | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/website_contract_test.exs` | 88 tests, 0 failures | ✓ PASS |
| Pinned-sentence, docs and package tests | `mix test phase110 phase112 no_human_gates docs_contract package_metadata` | 110 tests, 0 failures | ✓ PASS |
| Workflow lint | `actionlint .github/workflows/website.yml` | exit 0 | ✓ PASS |
| Build | `node website/scripts/build.mjs --out <scratch>` | built; 12 pinned files byte-identical; 0 root-absolute URLs; 0 inline scripts; only non-ASCII chars are U+201C and U+201D; one hex in HTML (`#F8F4F2` theme-color) | ✓ PASS |
| Full browser check | `SCRYPATH_BROWSER_CHANNEL=chrome node scripts/check.mjs --no-screenshots` in a scratch copy (npm ci, Playwright 1.65.1, Chrome 158) | 101 assertions, `failed=none` | ✓ PASS |
| Smoke, no URL | `node scripts/smoke.mjs` with no env | exit 1, message names the variable | ✓ PASS |
| Smoke against a local build whose og URLs name the production origin | `SCRYPATH_SMOKE_URL=http://127.0.0.1:<port>/scrypath/ node scripts/smoke.mjs` | `not ok` on base-path and card, because og URLs point at the production origin; correct refusal to fetch outside the base | ✓ PASS (expected) |
| Rollback reach for an old ref | old `check.mjs` (`git show d83d6bc5:...`) with `SCRYPATH_BROWSER_CHANNEL=chrome`, empty `PLAYWRIGHT_BROWSERS_PATH` | `browserType.launch: Executable doesn't exist`, exit non-zero | ✗ FAIL (the gap) |

### Mutation tests (scratch copies; repo never modified)

| Mutation | Caught by | Result |
| --- | --- | --- |
| `#9f8cff` appended to `styles.css` | live `color-literal`, `hex-outside-brand-set` | caught |
| `rgba(0,0,0,.5)` in `styles.css` | live `color-literal` | caught |
| inline `<script>` in `layout.html` | live `inline-script` | caught |
| root-absolute stylesheet link | live `root-absolute-url` | caught |
| `font-display: swap` to `block` | live `font-face` | caught |
| hex literal in `theme.js` | `color-literal`, `hex-outside-brand-set`, `theme-script` | caught |
| `'unsafe-inline'` added to `style-src` | live `csp` | caught |
| `mix verify.adopter` back on the home page | live `repo-only-task` | caught |
| `data-theme="dark"` hard-coded on `<html>` | live `default-state` | caught |
| `text-transform: uppercase` rule | live `uppercase-transform` | caught |
| relative `og:image` | live `og-image` | caught |
| contract weakened: no `font-display` check, no root-absolute css url check, no pin-hash push, no color-literal push | the matching planted case in each | caught (4 of 4) |
| contract weakened: CSP `unsafe-inline` regex removed | nothing fails | redundant, not a hole: the exact directive allowlist still rejects it |
| contract weakened: `og:image` URL equality removed | nothing fails | survived: only the live case and the width and PNG branches have planted partners |
| tokens.json role removed; Control Edge sentence off by one; one font byte flipped | `build.mjs` | all three fail the build with a named error |
| browser: `[hidden]` rule removed | `check.mjs` JS-off and blocked-storage picker assertions | caught |
| browser: print block leaves the dark lockup visible | `check.mjs` print lockup assertion | caught |
| browser: `theme.js` accepts any stored value | nothing fails | survived: an unknown `data-theme` still computes light, so the requirement ("anything else is light") holds by outcome; only the validator is untested |

### Requirements Coverage

| Requirement | Plans | Status | Evidence |
| --- | --- | --- | --- |
| SITE-01 | 01, 02 | ✓ SATISFIED | Truths 1 and 3. |
| SITE-02 | 01, 02 | ✓ SATISFIED | Truth 2; picker shipped, no fallback. |
| SITE-03 | 02 | ✓ SATISFIED | Truth 4. |
| SITE-04 | 01, 03 | ✓ SATISFIED for everything runnable before the merge | Truths 1 to 3, filters, timeout. The install after-numbers are pending by design. |
| SITE-05 | 03 | ⚠️ PARTIAL | Concurrency, smoke, dispatch, docs and the non-required decision are in place; exact-head and post-merge evidence pending by design; the rollback does not reach a pre-merge ref (gap). |
| SITE-06 | 02 | ✓ SATISFIED | Truth 6. |
| GATE-02 | 01 to 03 | ✓ SATISFIED so far | One gate run per SHA, receipt not stale, no dirty-tree capture, ledger 9 of 12, no `human_needed`, no backstop truth. A fix to the gap makes the receipt stale (see below). |

No orphaned requirement: REQUIREMENTS maps SITE-01 to SITE-06 and GATE-02 to Phase 189 and all are claimed by a plan. `REQUIREMENTS.md` still shows them Pending and the ROADMAP progress table still says 0/3; that is bookkeeping for after the merge.

### Decision coverage (non-blocking)

45 of 52 honored by the tool's substring match. The seven it did not find are D-46 to D-51 (informational delivery and scope rules) and D-20. D-20 is a heuristic miss: I checked `theme.js` directly and it uses the `scrypath-theme` key, falls back to light on a throwing store, and listens for `storage`.

### Anti-Patterns Found

None. No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` or placeholder text in the 29 non-`.planning` files this phase changed, no skipped or todo tests, and no placeholder data reaches any page.

### Scope check: identity only, and SITE-06 wording

Identity only holds. The page diffs are 14, 6 and 4 lines in the home, docs and operators pages. The headline, the three buttons ("Read the docs", "See operator support", "View on GitHub"), the code sample, the version pill and the layout are unchanged (I looked at a home page render in both themes only to check nothing broke; that is not a design review). The old header tagline `<small>` is gone, which D-12 asks for.

The label changes stay inside SITE-06, with one caveat. SITE-06 and D-53 literally say to replace each `mix verify.adopter` mention with a shipped task. The executor also changed two labels, "Verify locally" to "Check sync status" (home status strip) and "Verified locally" to "Check sync status" (diagram badge), and reworded the operators list into two steps. In my judgment these are the same accuracy fix: `mix scrypath.status` prints sync visibility and verifies nothing, so leaving "Verify locally" over it would have been a new false claim of exactly the kind SITE-06 exists to remove. No headline, call to action, structure or layout moved. Two things I would not call a violation but did notice: the home page section heading "Install, then verify locally." and its eyebrow were left untouched (a heading fence), and the paragraph under it now describes a status check; and the docs-page tile now points at the support guide, whose own text still names the repo-only task (the recorded D-54 follow-up).

### Observations (not gaps)

- D-18's 24 px target is implemented (`min-height: 2rem`) but no check asserts it. It is not a roadmap criterion.
- `og:image` URL equality has a live case but no planted partner (mutation above); `theme.js` stored-value validation is pinned by outcome only. Both are cheap to harden later and neither affects the goal.
- Text inside the inline diagram renders very small at desktop width because the SVG scales. The sizes are the same as the old diagram's and the diagram is `aria-hidden`, so this is not a regression; the 12 px rule in `check.mjs` reads HTML computed sizes, not SVG user units.
- `docs/releasing.md` says `build-and-check` runs "about 47 to 64 seconds". The measured median is 64 s with a 175 s p90 (`CI-EFFICIENCY.md` finding 5), and the doc already mentions the timeout that bounds the tail.
- The closed hex set that ROADMAP criterion 1 now spells out is tokens.json plus exactly two hexes that SITE-01 itself authorizes (the dark selected color from a contrast pair and the dark control edge from the brand sentence). I computed that, so the ROADMAP edit follows SITE-01 and does not widen the set.

### Gaps Summary

One gap, small and fixable. The rollback path the phase builds for a bad first deploy does not work for the likeliest target, the commit just before the merge. The old `check.mjs` cannot launch on the runner's Chrome, so `build-and-check` goes red and `deploy` never runs. The smoke step's soft-check branch, which exists for exactly that ref, is unreachable on `main`. This was reproduced with the old script, not inferred.

Two ways to close it:

1. **Fix (recommended).** Guard the Chrome path in the Select browser step so it is used only when the checked-out `check.mjs` supports the channel variable, with one planted wiring-test case. It touches `website.yml` and `workflow_wiring_test.exs`, so under GATE-02 it needs one fresh `mix verify.repository_contracts` and `mix verify.core` on the new SHA and a re-issued receipt. Run `actionlint` and the wiring test first.
2. **Accept.** Record the limitation in the phase record with the workaround (for a pre-merge ref, revert through a PR instead of dispatching), as an override. That is a `.planning/` change only, so the receipt stays valid.

Everything else is verified. Nothing here routes to human verification.

---

_Verified: 2026-11-20T19:15:00Z_
_Verifier: Claude (gsd-verifier)_


## Gap closure (orchestrator, 2026-11-20)

The one gap above (rollback to a ref that predates the new `check.mjs`, reported by this verifier as CR-01 in the code review too) is closed by commit `58737f61` (the runner-Chrome path is taken only when the checked-out `scripts/check.mjs` supports `SCRYPATH_BROWSER_CHANNEL`). Its regression tests ran green: a wiring test pins the guard ahead of the probe, and a test runs the real step script against stub `google-chrome`, `node` and `npx` and failed on the old code. This is the orchestrator's re-check of that one gap, not a second independent verification. The other code-review findings (WR-01 to WR-08) were fixed in the same series, see `189-REVIEW.md` "Fix disposition". The real rollback dry run (dispatch with `ref=<pre-merge sha>` after the merge) is recorded as post-ship evidence.

Gate evidence for the final head: the local long gates ran once on `76948c2e` (see `189-GATE-RECEIPT.md`); the review fixes after it touched the workflow, tests, docs and website scripts, so the hosted required checks on the exact pushed head are the full gate for that SHA. Decision recorded by the orchestrator under the value-over-procedure principle: re-running the identical local long gates a second time (about 30 minutes) would duplicate the hosted `core` and `repository-contracts` lanes, which run the same commands on the exact head and decide the merge. Revisit if a hosted-only red ever contradicts a green local gate.
