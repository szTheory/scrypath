---
phase: 189-website-re-skin
plan: 02
subsystem: website
tags: [static-site, re-skin, theme-picker, brand-tokens, deny-set, copy-accuracy]

requires:
  - phase: 189-website-re-skin
    provides: plan 189-01 build pipeline (tokens.css, pinned copies), static contract and browser check
provides:
  - website source re-skinned in the plum and orchid identity (layout, variables-only stylesheet, theme.js, picker and diagram partials)
  - retired website palette in the deny set, p189 allowlist entries gone, ceilings 5 and 197
  - SITE-06 copy: no website source names a repo-only mix verify task
affects: [189-03]

actuals:
  tokens: 13400
  tasks: 4
  commits: 2
plan_head_before: 2478d7b4825b805e00fc2a5b2a2e71363de3fdfc
plan_head_after: d66376f6ad21e0e1c78b09d22500ae4e1ebac5e8

tech-stack:
  added: []
  patterns:
    - "variables-only CSS: every color is var(--role) from the generated tokens.css, color-mix only for a shadow"
    - "fallback font faces measured in the browser against Arial, then checked by a width sweep, not copied"
    - "one atomic commit for assets, deny set, allowlist, ceilings and deletions (shrink-only allowlist)"

key-files:
  created:
    - website/src/assets/theme.js
    - website/src/partials/theme-picker.html
    - website/src/partials/diagram.svg
  modified:
    - website/src/layout.html
    - website/src/assets/styles.css
    - website/src/pages/index.html
    - website/src/pages/docs.html
    - website/src/pages/operators.html
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - test/mix/tasks/ui_contrast_contract_test.exs
  deleted:
    - website/src/assets/brand-mark.svg
    - website/src/assets/og-image.svg
    - website/src/assets/diagram.svg

key-decisions:
  - "Picker ships: the picker set was green on its first run, so the D-25 light-only fallback did not fire and THEME_MODE stays 'picker'"
  - "Single dark display weight is 670; light is 700 (both asserted by check.mjs)"
  - "Hanken fallback size-adjust is 100.4 percent, measured, instead of the ops value 101.7"

requirements-completed: [SITE-01, SITE-02, SITE-03, SITE-06]

duration: about 2h
completed: 2026-11-20
status: complete
---

# Phase 189 Plan 02: Re-skin, picker and deny set Summary

**The website now renders in the pinned plum and orchid identity with a Light, Dark and System picker, the old website palette can no longer return, and no site copy names a task the Hex package does not ship.**

## Picker outcome

**Picker outcome: shipped.** The picker, `theme.js` and the dark, system and print token blocks all passed on the first run, so the pre-authorized D-25 fallback was not needed and `THEME_MODE` is still `'picker'`. There is no `SITE-02 FALLBACK TAKEN` flag, SITE-02 and success criterion 2 stand as written in `REQUIREMENTS.md`, and no file under `website/scripts/` was edited.

Values the plan asks to record:

| Item | Value |
| --- | --- |
| Dark display weight (asserted) | 670 (light is 700) |
| `HERO_SHIFT_TOLERANCE_PX` | 12, unchanged; measured shift at 390 and 1440 px is 0.0 px for h1 and hero |
| Playwright | 1.65.1 (`npm ci --ignore-scripts`) |
| Local browser | installed Google Chrome 158.0.8127.36 (`SCRYPATH_BROWSER_CHANNEL=chrome`); the bundled Chromium is verified by the first hosted `build-and-check` run, not locally |
| `theme.js` size | 1,791 bytes (limit 2,048) |
| Bricolage fallback metrics source | `size-adjust` 80.7 percent measured in Chrome against Arial Bold (80.5 to 80.9 on the hero and section headings); ascent 115.2 percent and descent 33.5 percent from the pinned font's `hhea` table (930 and 270 of 1000 units) divided by the size adjustment |
| Hanken fallback metrics source | `size-adjust` 100.4 percent, measured and swept (see deviation 2); ascent 99.6 and descent 30.2 percent from `hhea` (1000 and 303 of 1000) |
| Sometype Mono fallback metrics source | copied from `scrypath_ops/assets/css/app.css` (96.7, 95.7, 28.5, 0); my own Chrome measurement reproduced 96.7 |

## What shipped

1. **Markup (Task 1).** `layout.html` has the CSP meta first after charset, absolute og and twitter card meta with the PNG size, the `.ico` plus light and dark themed SVG icon links, `ui` and `display` font preloads, `tokens.css` then `styles.css` then the plain synchronous `theme.js`, two lockup images (light and dark), the picker slot ahead of the star link and version pill, and footer links to the three OFL texts. The old brand mark, OG image and diagram files are deleted; the diagram is now an inline themed SVG partial that shows `mix scrypath.status MyApp.Post`.
2. **Stylesheet and script (Task 2).** `styles.css` has no color literal, no gradient, no grid overlay and no uppercase. It carries three web-font faces plus three measured fallback faces, the brand type scale, the `[hidden]` rule, forced-colors, print and reduced-motion blocks, and an 80 ms color transition. `theme.js` reads the stored choice, accepts only `light`, `dark` or `system`, sets `data-theme` before first paint, sets `theme-color` from the computed `--page` role, reveals the picker only after a storage write probe, and follows a second tab through the `storage` event.
3. **Guards (Task 3).** `DENY_HEX` grows from 30 to 48 values (the 18 retired website hexes; the three values the old brand directory still holds stay out). Both `p189` allowlist entries are gone; the ceilings are 5 entries and 197 hits. The token test has a planted old-palette case (every one of the 18 is planted and caught) and an accept case that scans `website/src` and `website/scripts`; its floor in the ExUnit wrapper is now 55.
4. **Copy (Task 4, its own commit).** Every former repo-only task mention now names a shipped task (`mix scrypath.status`, `mix scrypath.reconcile`, `mix scrypath.failed`). The live-flag sentence is dropped because the shipped tasks have no such flag.

## Commits

| Task | Commit | Message |
| --- | --- | --- |
| 1 to 3 (one commit) | 2f581160 | chore(website): re-skin the site in the plum and orchid identity |
| 4 | d66376f6 | chore(website): name shipped tasks in site copy |

One commit sits between the 189-01 base and the re-skin (`rev-list --count` is 1); the local WIP checkpoint was squashed away with `git reset --soft`. The 189-01 base is `2478d7b4825b805e00fc2a5b2a2e71363de3fdfc`.

## Verification run

All of these ran against the committed state, with the Chrome channel for browser steps.

| Check | Command | Result |
| --- | --- | --- |
| Pinned-sentence tests, baseline and after | `mix test test/scrypath/phase110_contract_test.exs test/scrypath/phase112_contract_test.exs` | 8 tests, 0 failures, before and after |
| Static contract, full | `node --test website/scripts/site-contract.test.mjs` | 78 of 78 pass (live, planted, accept) |
| Browser check, full | `SCRYPATH_BROWSER_CHANNEL=chrome node website/scripts/check.mjs --no-screenshots` | 101 assertions, `failed=none` |
| Picker set | `node --test --test-name-pattern=theme-picker website/scripts/site-contract.test.mjs` and `check.mjs --groups theme-picker --no-screenshots` | 11 contract cases pass; 35 assertions, `failed=none` (floors are 6 and 10) |
| ExUnit files | `mix test` on phase110, phase112, `website_contract_test.exs`, `workflow_wiring_test.exs` | 94 tests, 0 failures |
| Token test | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 61 of 61 pass |
| Wrapper and format | `mix format --check-formatted test/mix/tasks/ui_contrast_contract_test.exs`, `mix test test/mix/tasks/ui_contrast_contract_test.exs:106` | clean; 1 test, 0 failures |
| Allowlist | `grep -c '"tag": "p189"' examples/scrypath_ecommerce/retired-identity-allowlist.json` | 0; 5 entries, 197 hits |
| Review screenshots | `npm --prefix website run check` on a clean tree | 101 assertions, `failed=none`; 16 PNGs written to the ignored `website/artifacts/` inside this worktree (review-only, lost when the worktree is removed) |

`mix verify.core` and `mix verify.repository_contracts` were not run, as the plan requires; plan 189-03 runs each once on the final head.

## Deviations from Plan

**1. [Rule 3 - Blocking] Bricolage fallback metrics derived with Node, not Python fontTools.** The plan said to use fontTools if it loads. It does not load here and installing a package is not allowed, so a small throwaway script (not committed) read `head`, `hhea` and `OS/2` from the pinned WOFF2 with Node's built-in Brotli. The `OS/2` average-width method is unreliable for these subsets (it gave 108.1 percent for Bricolage against a measured 80.7, and 122.1 percent for Hanken against about 101), so `size-adjust` comes from rendered widths in Chrome instead; ascent and descent come from `hhea`. Commit 2f581160.

**2. [Rule 1 - Bug] Hanken fallback `size-adjust` is 100.4 percent, not the ops value 101.7.** The plan said to copy the ops pair. With 101.7 the fonts-blocked height check failed at 390 px (hero 24.8 px taller, one extra line in the hero paragraph, whose second line fits the loaded font with 3 px to spare). Measured over every paragraph on the four pages, Hanken is 100.9 percent of Arial on average. A sweep of 197 viewport widths (320 to 1500 px) found hero-height shifts over 12 px at 8 widths with 101.7, 3 with 100.9, and 2 with 100.0 to 100.4 (the flat minimum), so I used 100.4. The tolerance was not changed. Fixed before the atomic commit, so it is part of commit 2f581160.

**3. [Rule 2 - Accuracy] Two labels changed so they stay true.** The home status strip label "Verify locally" became "Check sync status", and the diagram badge "Verified locally" became "Check sync status", because a status task verifies nothing. No heading, CTA or layout changed.

**4. [Rule 2 - Accuracy] Operators first-response list.** The former "quick verification" step became "Run `mix scrypath.status` for a quick check of sync visibility", and the next step now names only `mix scrypath.failed`, so no task is repeated.

**5. Diagram text is centered in its boxes** (`text-anchor="middle"`), where the old SVG left-aligned each line at a hand-set x. Same five nodes, same flow, same viewBox.

**6. The wrapper test sits at line 106, not 108** in `ui_contrast_contract_test.exs`; I located it by name as the plan allows.

**7. Browser check ran before the atomic commit as a pre-check**, not only after it. It found the font-fallback shift (deviation 2), which was cheaper to fix inside the single commit than as a follow-up.

**8. Plan-head ledger file not written** (git-directory writes are denied in this environment, as in plan 189-01); `commits` is measured with `git rev-list --count` from the orchestrator-supplied base and excludes this summary's own docs commit.

## Known Stubs

None. No placeholder data reaches any page. The diagram shows `MyApp.Post` as an example schema name, the same way the home page code sample uses `Post` and `Repo`.

## Threat Flags

None beyond the plan's register. `theme.js` reads one storage key and only ever writes the validated value into a `data-theme` attribute (T-189-07), and the page's CSP forbids everything but same-origin assets and one same-origin script (T-189-06).

## Follow-ups for plan 189-03

- The Hex-shipped guides `guides/outside-adopter-intake.md` and `guides/support-and-compatibility.md` still name the removed task (D-54); the docs page tile now points readers at the support guide, whose wording differs from the tile. Record as the separate follow-up.
- The bundled Playwright Chromium has not run locally; the first hosted `build-and-check` on the exact head is its evidence.

## What this does not prove

Rendered quality and aesthetics, browsers other than Chromium-family (Chrome 158 here, and Safari's handling of the meta CSP in particular), real screen readers, social-platform card cropping, how the `.ico` renders, the Pages `content-type` for `.woff2` (first post-merge smoke), and the bundled Playwright Chromium locally. The screenshots were glanced at for obvious breakage only; they are review artifacts, not evidence of design quality. Nothing here claims aesthetic or independent-review approval.

## Self-Check: PASSED

All created and modified files exist, the three old brand files are gone, both task commits are ancestors of the head, and the working tree was clean before this file was added.
