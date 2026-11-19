# Phase 187 capture inventory

Phase 187 (ScrypathOps re-skin), Plan 11. This is the committed index behind the pull request: file names, hashes, source commits, assertion ids and the commands that prove them. The screenshots themselves stay in a git-ignored directory on the maintainer's machine and are never committed or uploaded (they hold demo data).

The captures are review context, not a gate. No image is compared by pixel and no baseline was recaptured. Nothing here is an independent review, and nothing here says the result looks good: whether it looks right is the maintainer's call.

## Source commits and manifests

| | Before | After |
|---|---|---|
| Source commit | `3a21916f61affcaa0b9c73c5491f26778739dab6` (Plan 01 gate commit: the old identity, with the Plan 01 fixture and guard edits) | `9217f326599095f8d5e150c71b123578b1ade7cd` (`GATE_SHA`, the last commit with an executable or rendered change) |
| `clean` | `true` | `true` |
| `git_status` | `[" M .planning/UI-PREVIEW.json"]` | `[]` |
| Captured at (UTC) | 2026-11-19T09:46:24Z | 2026-11-19T21:52:19Z |
| Stack | `MIX_ENV=test`, base `compose.yaml`, port 4102, project removed after use | same recipe, project `scrypath187-p11-capture`, port 4102, removed after use |
| Browser | Chromium 148.0.7778.96 | Chromium 148.0.7778.96 |
| Data | seeded `incident` (5 failed items), Search health scenario `all-statuses`, 5 rows in every Search health image | same |
| Page errors | none in any image | none in any image |

Manifests (ignored directory): `/Users/jon/projects/scrypath/examples/scrypath_ecommerce/ui-review-artifacts/phase187/before/manifest.json` and `.../after/manifest.json`. `node examples/scrypath_ecommerce/scripts/reskin-capture.mjs --check <dir>` prints `capture inventory: 12/12` for both. "No capture from a dirty tree" means no tracked change outside `.planning/`; the manifest records the whole `git status --porcelain`, so any other difference would show there. A first after set taken from `a026c14f` (the commit before `GATE_SHA`, which only fixed a test) is kept beside it as `after-superseded-a026c14f` and is not part of this inventory.

## The 24 captures

Screens: Control room, Search health (the `all-statuses` scenario, so all four status words and one condition word are on one page) and Failed sync work. File names read `{screen}-{theme}-{width}.png`; widths are 1280 and 390 px, themes light and dark.

Before (source `3a21916f`):

| Capture | Bytes hash |
|---|---|
| `control-room-light-1280.png` | sha256 `92f5e8fdaa5d436e2cacdcd20ebd93f8e2c69629ddf583a5c1fe5a3c6b50f21d` |
| `search-health-light-1280.png` | sha256 `5ea909cf8393476842b9a32d6890611b73456de1ea3ff2b244e9a1cf5446838e` |
| `failed-sync-light-1280.png` | sha256 `189efdc3c578e0eec0cb406dd4d5750d9418008cb9bae78afd475460f5c631ba` |
| `control-room-light-390.png` | sha256 `0f524f0fad9925186f6086df7b403f99355c811d01f1a97251befdc8f0f0d6c6` |
| `search-health-light-390.png` | sha256 `57f0cbf8ab92c27cec4658e8add39f907415c0b0f782a9e0d9413b04d6f2dbd8` |
| `failed-sync-light-390.png` | sha256 `7307366a8eeccc681e2822c940aaedfe12289e48ae799a12f8ef476749cf667d` |
| `control-room-dark-1280.png` | sha256 `ae2cc4f3b2f93360f47b56429926e03b2a28cf785aaaa09afe38e2df3f0bec2a` |
| `search-health-dark-1280.png` | sha256 `f01ead0a8217470d48a9a84b1d5e2e43d0997b00584a1f51f651ef598b2b2f0a` |
| `failed-sync-dark-1280.png` | sha256 `fc88c52e057756727a5414e31449fea11425932870d4fa3a083b98affdd83be1` |
| `control-room-dark-390.png` | sha256 `321e875fc663822f71fd948bb80b8ec2e78ec382c908f7197bd3f0575dca7b49` |
| `search-health-dark-390.png` | sha256 `ee78ca164e7c0234ab52cf8cc5f64730c349d878de5d8fe6575a2ac7d0fd4443` |
| `failed-sync-dark-390.png` | sha256 `e90fcad69eeed298e8a65888bb7148a58568549e05a878e3493d166ae80f0905` |

After (source `9217f326`):

| Capture | Bytes hash |
|---|---|
| `control-room-light-1280.png` | sha256 `1c3870b788ca2c19a8c05eebcb5314b87472670ac0baaba8d831dae34e8b2de1` |
| `search-health-light-1280.png` | sha256 `0a9e0db2eb008f7586a04abe6136757ea68a08ce0abdfc4c925dda580c2b6df5` |
| `failed-sync-light-1280.png` | sha256 `30d468ec90fb4641f901d138d54ef129abaef74082ee17f07deb17b8b69ed7c7` |
| `control-room-light-390.png` | sha256 `15763c81666d0c9b863d874bb2bcfaad812cce928af53f48826ce16505a91000` |
| `search-health-light-390.png` | sha256 `7b338a38d2d220103908719020150edcf304ed156143f4cfedf66303cc65a62d` |
| `failed-sync-light-390.png` | sha256 `f660ebbe926bc0254dac26cf0d4f65ce1da254db705fb0cbd38247b799712b15` |
| `control-room-dark-1280.png` | sha256 `556776c58d384d7667cd4d84e15c641ede9f070eae3958cebc07cc5bfaad4583` |
| `search-health-dark-1280.png` | sha256 `400e08ffdaed365670e72eece31270ed5b107d74e0b4fd770183aa45c13fe3a7` |
| `failed-sync-dark-1280.png` | sha256 `8d1c50b93671ebc6740ace398a86e1a217d38a0cce423cd5a43f866b253a5689` |
| `control-room-dark-390.png` | sha256 `d5cb22b70f3092265f0b92e231dcfc86dd72cdb39f93b46fe63663f9836ff4f4` |
| `search-health-dark-390.png` | sha256 `a4c3fe709c4302a741b2c8716086b94f93f67c78bf9a2c6cda6d6855de2a3719` |
| `failed-sync-dark-390.png` | sha256 `ee99c64bcf878e31bae9d2cd8720c7fdd1a98c810e9c33e25f4401c2a6737c12` |

Between the two after sets (same rendered code), all four Search health images came out byte-identical, because that fixture route shows a fixed "Checked" time; the Control room and Failed sync work images differ because they print the live time.

## What I looked at (facts, not a review)

A coding agent opened three of the 24 images: `search-health-light-1280.png`, `failed-sync-light-1280.png` (both final after set) and `control-room-dark-390.png` (from the superseded after set, same rendered code). It opened none of the before images in this plan and none of the other after images.

- Search health, light, 1280: five schema rows in the order Failed, Retrying, Pending, Not checked, Clear. All four status words carry their own slash glyph and color; the one condition word, "Not checked", has no glyph. The wordmark is the scry/path lockup in plum and ink.
- Failed sync work, light, 1280: each row starts with a status word and glyph (Failed three times, Retrying twice), Retry is an underlined text action, and the notice at the top has a left rule and no tint.
- Control room, dark, 390: the verdict reads Failed with its glyph and the failed-job count, there is one filled button (the page's single Plum action) and two underlined intent links with an arrow.

Possible problems and gaps I did not chase, so nothing here is settled: the Variant count chip on Failed sync work has a dashed outline and I did not check whether that is intended; in the 1280 captures the sidebar panel ends at the 900 px viewport height while the page continues (likely an effect of full-page capture, not checked in a live browser); 21 of 24 images were not opened in this plan (Plan 01 recorded looking at three of the before images).

## Reviewed expectations (decided before the pull request; not failures)

1. **Geometry-class differences from the re-skin are expected.** The font swap (Hanken Grotesk and Sometype Mono replace the old faces), the 136 px minimum lockup and the hairline Search health rows change geometry on purpose. The Phase 185 pair flow (it compares an old-identity build with a re-skinned one) was not run, so no pixel baseline was recaptured or updated and no comparator threshold changed. None of those three classes failed a case in the canonical lane's preservation partition (61 of 61 passed).
2. **One narrow edit to a preservation guard.** `assertPendingState` in `examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts` required the page text to stay identical while a refresh is in flight. The approved UI-SPEC copy-diff allowlist shows `Refreshing…` on the refresh button during a refresh, so four `loading` cases (E2 Control Room, E3 Search health, E4 Failed sync work, E6 Sync and index) failed on exactly that one line (`Refresh` against `Refreshing…`) in Plan 10's rehearsal. The guard now reads that one whole line as its idle line and still fails on every other difference (route, busy marker, any other text). `scripts/ci/ui_state_pairs.test.cjs` evaluates the guard's own allowlist block, pins it to exactly that one entry, and plants non-allowlisted changes that must still fail. Result in the canonical lane on `GATE_SHA`: all 61 preservation cases pass.
   - Digest consequence: the two edited files are in the fixture overlay digest, so the digest moved from `sha256:4e3a3b16a3d093cbdc80c71a9a70b806dd75165dd9f5e72c3136cbae092ff586` (unchanged from Plan 01 through Plan 10) to `sha256:69893d45ad4b3d5facca629cce9096ff259cdee31582652b29048ea7a6ec3d00` (the value in the canonical lane's receipts for `GATE_SHA`). The verifier computes it from the checked-out files, so each receipt of this phase's runs carries the value of its own checkout. A stored qualification identity from an earlier phase would not match the new digest; this phase does not use one because the pair flow was not run. Anyone who runs the pair flow later needs a fresh qualification.
   - The before captures were not re-taken. The capture manifest records the source commit and `git_status` and no overlay digest, and a screenshot of a page does not depend on guard code, so the before set from `3a21916f` stays valid review context.
3. **A recorded failure that was fixed.** The first canonical lane run (on `a026c14f`) failed one test of 239 in the ordinary partition: `ops_host_contract.spec.ts` P-17d. It added its `Content-Security-Policy` header with `page.route` and `route.fulfill`, and on the Compose network (`http://web:4002`, a private address that is not a secure context) Chromium blocked every stylesheet, script and image of the served document, so no font was requested and no violation fired. Reproduced and fixed inside the canonical browser container: the header now comes from a loopback proxy in the spec process. All four host cases pass in the container, on the host, and in the full lane. That run stopped after the ordinary partition, so its preservation partition did not run; the rerun on `GATE_SHA` ran both.

## Assertion ids by requirement

Every check is automated. Ids are those of `187-UI-SPEC.md` (Assertion Index) and `187-VALIDATION.md`. N is Node, E is ops ExUnit, P is a Playwright spec. The browser specs run in the canonical `mix verify.ecommerce_e2e` lane (ordinary partition); the required subset also runs in `mix verify.ecommerce_mounted`.

| Requirement | Assertion ids | Command that proves them |
|---|---|---|
| SKIN-01 | N-01, N-02, N-06, N-08, N-10, P-01, P-18 | `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs`; `node examples/scrypath_ecommerce/contrast-checker.mjs`; `ops_reskin_contract.spec.ts` |
| SKIN-02 | N-10, E-14, E-15, P-02, P-14, P-19, P-20 | token test; `reskin_static_contract_test.exs` and `design_tokens_contract_test.exs` under `mix verify.ops_ui`; `harness.spec.ts` in `mix verify.ecommerce_mounted`; `ops_reskin_contract.spec.ts` |
| SKIN-03 | E-13, P-11 | `reskin_static_contract_test.exs` (`mix verify.ops_ui`); `ops_reskin_contract.spec.ts` |
| SKIN-04 | E-07, E-08, E-09, P-04, P-05, P-06 | `reskin_component_contract_test.exs` and the live tests (`mix verify.ops_ui`); `operator.spec.ts` (`mix verify.ecommerce_mounted`); `ops_reskin_contract.spec.ts` |
| SKIN-05 | E-10, E-12, E-16, E-18, N-12, P-12, P-15, P-21 | ops ExUnit contract tests; token test (N-12); `admin_path_motion.spec.ts` (P-12); `ops_reskin_contract.spec.ts` |
| SKIN-06 | N-13, P-02 | token test; `ops_reskin_contract.spec.ts` |
| SKIN-07 | E-05, E-11 | ops ExUnit live and component contract tests (`mix verify.ops_ui`) |
| SKIN-08 | E-19, capture inventory, PR gates list | `posture_live_test.exs` (all-statuses fixture); `node examples/scrypath_ecommerce/scripts/reskin-capture.mjs --check <dir>` on both directories; the hosted run on the exact head SHA |
| STAT-01 | E-01, E-02, E-06, E-19, P-03 | ops ExUnit component and live tests; `ops_reskin_contract.spec.ts` |
| STAT-02 | E-03, E-04 | ops ExUnit live tests |
| STAT-03 | E-06, E-17, P-15, P-18 | ops ExUnit tests; `ops_reskin_contract.spec.ts` |
| A11Y-01 | N-03, N-04, N-05, N-06, N-07, P-07, P-08, P-13, P-16 | `node examples/scrypath_ecommerce/contrast-checker.mjs`; token test; `ops_reskin_contract.spec.ts` |
| A11Y-02 | N-09, P-09, P-10 | token test; `ops_reskin_contract.spec.ts` |
| A11Y-03 | E-16, P-02, P-12, P-20 | ops ExUnit component contract; `admin_path_motion.spec.ts`; `ops_reskin_contract.spec.ts` |
| A11Y-04 | N-11, P-17a to P-17d, mounted font request | token test (`UNSCOPED_SELECTOR_CEILING` 54, `DUAL_DARK_RULE_CEILING` 12, exact both ways, planted growth fails); `ops_host_contract.spec.ts`; `harness.spec.ts` |
| GATE-03 | `npm run ui:preflight` exit 0 before and after, `my-search.json` hash unchanged, seed-disabled start | run on the retained preview checkout by the orchestrator step; see the plan SUMMARY |

## Local gate results on `GATE_SHA` (`9217f326`)

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0 |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail (4 new: two live ratchets, two planted) |
| `node --test --test-reporter=tap scripts/ci/ui_state_pairs.test.cjs` | 39 pass, 0 fail (5 new for the guard allowlist) |
| root `mix test` on the four `ui_*` contract tests, `--exclude contrast_child` | 29 tests, 0 failures (token-test floor now 53) |
| `mix verify.ops_ui` (database `scrypath_ops_test_187_11`) | 2 boundary tests; 2 doctests, 508 tests, 0 failures, 236 s |
| `mix verify.repository_contracts` | 157 tests, 0 failures, 216 s (ran in the normal sandbox; no escalated permission was needed) |
| `mix verify.core --exclude integration --exclude docs_contract` | 5 properties, 1158 tests, 0 failures (103 excluded), Standard Maturity Gate PASSED, 319 s |
| `mix verify.package` | 110 tests, 0 failures, 71 s |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan11_mounted`) | `Docker verifier passed (scope=focused)`, `containers=0 networks=0 volumes=0 cleanup=clean`, 324 s |
| `mix verify.ecommerce_e2e` (`E2E_PROJECT_NAME=p187_plan11_e2e`, `E2E_DEADLINE_EPOCH` = start + 1800) | exit 0: 300 expected, 300 passed, 0 unexpected, 0 flaky, 0 skipped (ordinary 239, preservation 61), `dirty: false`, 720 s wall (676 s lane runtime), `containers=0 networks=0 volumes=0 cleanup=clean` |
| `ops_host_contract.spec.ts` on a disposable stack on the host (`PLAYWRIGHT_BASE_URL=http://127.0.0.1:4102`) | 4 passed |
| the same spec inside the canonical browser container (`http://web:4002`) | 4 passed |

`bf3dac5d` follows `GATE_SHA`; it changes README prose and one spec header comment only (`git diff 9217f326 bf3dac5d` is those two files). The long gates were not rerun on it; the hosted dispatch on the exact head covers it.

## What the gates do not prove

- That the result looks good. No person judged the rendered screens and no independent review took place. The captures above are context for the maintainer's own look.
- Anything on screens outside the six the computed-style contract drives (Control Room, Search health, Failed sync work, Sync and index, Search and Help), plus the command palette, mobile drawer, Save modal and Manage sheet it opens. The index-promotion confirm is covered in a browser only by `operator.spec.ts` at 320 px.
- How the fallback glyphs look. Three characters (`·`, `›`, `⌘`) are not in the shipped font subsets and render from the fallback faces. The checks prove the fallbacks are named, that layout does not shift, and that rendered text stays inside a named allowlist; they do not prove what those glyphs look like.
- Behavior in host applications other than the e-commerce fixture, or when a host overrides ops variables with colors that fail contrast (the host owns contrast once it overrides).
- Pixel equivalence with the old identity. The pair flow was not run and no baseline was updated; copy, state, action and identity checks stay green and geometry is expected to differ.
- That the hosted run behaves like the local one. The hosted lane is confirmed on the exact head SHA by the step that opens the pull request, after this file.

## For the maintainer's merge-time yes

- **What changes for an operator:** the plum and orchid identity and the scry/path lockup, Hanken Grotesk and Sometype Mono, status words with their own glyphs (Failed, Retrying, Pending, Clear, plus condition words that carry no glyph), one Plum action per page, flat hairline rows, a loading word instead of a spinner, no looping animation. Routes, the nine JavaScript hook names and the file names under `priv/static` are unchanged.
- **What a host app may notice:** the ops stylesheet still carries a CSS reset and `:root` rules, so link it on ops routes only (the demo does, and its own pages load none). A plain `:root { --color-primary: ... }` host rule after the sheet wins. The unscoped-selector count (54) and dual dark rule count (12) may only fall.
- **Evidence summary:** the local lanes above are green on `GATE_SHA`. The preservation partition is fully green because of the one-entry guard amendment above; no baseline or threshold moved.
- **Not done here:** the retained preview refresh and its two preflight runs, the Draft PR, the hosted dispatch on the exact head and the PR comment belong to the orchestrator step. The squash merge is the maintainer's yes; after it, `ui/next` has to be reconciled to the merged `main` before anyone calls the preview latest.
