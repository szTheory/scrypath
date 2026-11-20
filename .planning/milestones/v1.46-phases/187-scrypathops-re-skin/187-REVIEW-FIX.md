---
phase: 187-scrypathops-re-skin
fixed_at: 2026-11-19T22:52:37Z
review_path: .planning/phases/187-scrypathops-re-skin/187-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 187: Code Review Fix Report

**Fixed at:** 2026-11-19T22:52:37Z
**Source review:** `.planning/phases/187-scrypathops-re-skin/187-REVIEW.md`
**Iteration:** 1
**Final code commit:** `cf7441092d18cedb2fca26475906725fbeb67b94` (every later commit touches only `.planning/`)

**Summary:**
- Findings in scope: 4 (WR-01, WR-02, WR-03 and IN-06, as assigned)
- Fixed: 4
- Skipped: 0
- Out of scope, untouched: IN-01 (recorded product decision), IN-02, IN-03, IN-04, IN-05, IN-07 (pre-existing), IN-08

Work ran in the main checkout on `feat/v1.46-187-ops-reskin` (no worktree, as instructed). No branch switch, push or merge.

## Fixed Issues

### WR-01: `aria-busy="true"` sat on the `role="status"` node that holds the loading word

**Disposition:** fixed, with one placement change from the stated decision (see "Where this differs from the decision" below).
**Files modified:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`, `scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs`, `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`
**Commit:** `10b44732`
**Applied fix:**
- `ops_loading` (bars): the word is now `<p class="ops-loading__label" role="status">` with no `aria-busy`. The static skeleton lines sit in a sibling `<div class="grid gap-ops-2" aria-busy="true">`, the stand-in for the content that is loading. The root `div` no longer has a role. The wrapper uses utilities already in the built stylesheet, so the tracked CSS did not change and the layout is the same (same grid gap, same last-child short bar).
- `ops_loading` (inline): just the `role="status"` word, no `aria-busy`. Nothing is being replaced there.
- Sync and index: "Checking Meilisearch settings…" is a plain `role="status"` node. The earlier comparison that stays on show during a re-check (the `#index-settings-status` verdict and the settings-difference table) carries `aria-busy` while `settings_checking?` is true, because that is the content being replaced. A HEEx comment says why.
- Visible words are unchanged. Reconnect flashes still carry no `aria-busy` (the existing assertion stays). The refresh button is unchanged (a button is not a live region).
- E-16 (`reskin_component_contract_test.exs`) now asserts: exactly one `[role='status']` holding the word, `[role='status'][aria-busy]` count 0, `[aria-busy] [role='status']` count 0, one `[aria-busy]` region that holds only the aria-hidden bars (the short last bar, no inline style, no animation class), and the inline variant has a status and no `aria-busy`. The Sync and index test asserts the same for the first paint, and a new test renders a re-check with the earlier comparison on show and asserts the earlier verdict is busy while the word is not and has no busy ancestor.
- Every other reader of `aria-busy` was checked and needs no change: the refresh button (`phase173_status_actions.spec.ts`, `reskin_component_contract_test.exs`, `ops_hooks.js`), `admin_path_motion.spec.ts` (header comment only), and the capture script and `ui-preservation-states.ts` (neither reads it). `settings_layout.spec.ts` reads only the `#index-settings-checking` text, which is unchanged.

**Where this differs from the decision:** the decision said to put `aria-busy` on "the container being replaced (the results area or settings section)". I put it on the content nodes being replaced instead, and kept the word outside every busy node. Reason: `aria-busy` on an element asks assistive technology to hold changes inside that element, and implementations differ on whether a busy ancestor also holds a live region inside it (I believe Firefox's accessibility layer does; I did not verify that against its source). A busy `<section>` that contains the status word (and, on Search, the existing `#search-outcome` "Search running." live region) would move the same defect up one level. Search clears its old results when a search starts, so there is no replaced content to mark there; the skeleton stand-in is the busy region. This is a small change to revert if you prefer the section-level placement: move the attribute to the `<section>` in `search_live.ex` and `<.ops_section>` in `sync_drift_live.ex` and flip the two "no busy ancestor" assertions. The tests prove the DOM structure; they cannot prove what a given screen reader announces, and no real assistive-technology run was done.

### WR-02: the capture manifest claimed provenance it never checked

**Disposition:** fixed.
**Files modified:** `examples/scrypath_ecommerce/scripts/reskin-capture.mjs`, `examples/scrypath_ecommerce/scripts/reskin-capture.selftest.mjs`
**Commit:** `897ec7e6`
**Applied fix:**
- The tree check now reads plain `git status --porcelain` and counts every change outside `.planning/`, tracked or untracked (files and directories, quoted paths, both sides of a rename). Ignored entries never count. One status read serves both the refusal and the manifest's `git_status`.
- `clean` in the manifest is `tree.clean` from that check (the literal `true` is gone).
- Before anything is created, the script fetches `/admin/search` from `--base-url`, takes the one stylesheet link ending in `/assets/css/app.css` (preferring the mounted one, refusing zero or several), hashes the served bytes, and compares them with `git show HEAD:scrypath_ops/priv/static/assets/css/app.css`. A difference refuses the capture and names both hashes, unless `--allow-stale-source` is passed.
- The manifest records `served_css_url`, `served_css_sha256`, `head_css_path`, `head_css_sha256`, `served_css_matches_head` and `allow_stale_source`. `--check` re-derives the match from the two hashes and fails a manifest that says `clean: false`, a mismatch without `allow_stale_source`, a match flag its hashes contradict, or only one of the two hashes. Manifests taken before this change stay valid; both existing Phase 187 sets still print `capture inventory: 12/12`.
- Self-test (25 tests, up from 12): planted untracked file, untracked directory, quoted path, `.planning` and ignored entries accepted; the source no longer contains `clean: true` or `--untracked-files`; stylesheet link found among a host's own links, refused when missing or ambiguous; a loopback stand-in stack serving matching and stale bytes, a 404 sheet and an unreachable page; the flag defaults off; HEAD is read through `git show`; the manifest fields come from the checks and the stylesheet check runs before the scratch directory exists.
- Smoke run against a stale loopback stack and against a tree with an untracked source file: both refuse with the specific message and create nothing.
- The script and its self-test are not in `PRESERVATION_FIXTURE_FILES` and not under `PRODUCT_SOURCE_ROOTS` in `scripts/ci/ecommerce_evidence.cjs`, so no fixture-overlay digest is affected.
- The new check found a real drift while I was verifying: see the IN-06 follow-up below.

### WR-03: the System dark host-override promise had no executable test, and the README omitted the layer condition

**Disposition:** fixed.
**Files modified:** `examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts`, `scrypath_ops/README.md`, `scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs`
**Commits:** `4d887f5f` (spec and README), `fb56e970` (static premise test)
**Applied fix:**
- P-17c has a fourth case, "System dark, plain :root rule" (`{ scheme: "dark", preference: null }` with `:root{--color-primary:#123456}`), beside the three existing cases. The comment that cited a one-off probe is replaced by what the spec now proves.
- `scrypath_ops/README.md` says the guarantee holds for unlayered rules (or `@layer base` and later), that the daisyUI theme variables live in `@layer base`, and that a Tailwind `@theme` override lands in the lower `theme` layer and loses.
- Beyond the request, a small ExUnit contract keeps that README premise true: every `--color-primary` declaration in the built stylesheet must sit in a top-level `@layer base` block, with a planted stylesheet proving the reader sees a theme-layer, a nested and an unlayered declaration.
- Layer behaviour was also confirmed once in Chromium on the disposable stack with a throwaway probe (not committed, not a gate): in light and dark an unlayered `:root` rule, a later `@layer base` rule and an `@layer components` rule win, and an `@layer theme` rule loses. That matches the README sentence.

### IN-06: command palette close timer (160 ms) did not match its 80 ms animation

**Disposition:** fixed.
**Files modified:** `scrypath_ops/assets/js/ops_hooks.js`, `scrypath_ops/priv/static/assets/js/app.js`, `scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs`
**Commits:** `95db20a5`, `cf744109` (follow-up)
**Applied fix:**
- The closing animation runs on `--duration-ops-fast`, which aliases the 80 ms `instant` token, so the timer is now `const OPS_PALETTE_CLOSE_MS = 80`, commented against the token. The panel is hidden when its animation ends and no longer sits transparent, focusable and click-catching for 80 ms more. The CSS is unchanged.
- A motion-contract test resolves the duration each `.ops-cmdk--closing` rule names (through the old-name alias to the brand value) and fails when it differs from the constant or when the timer stops using the constant. I confirmed it fails when the constant is set to 160. A planted stylesheet proves the reader resolves aliases and sees a drifted token.
- The tracked ops bundle was rebuilt with the pinned esbuild; its only diff is this change.
- Follow-up `cf744109`: the IN-06 comment contained the word "invisible". Tailwind scans `scrypath_ops/assets/js`, so a fresh build emitted an `.invisible` rule the tracked stylesheet lacks. The new WR-02 check caught it on a stack built from the commit (served hash differed from HEAD, with exactly that one extra rule). The comment now says "fully faded"; a local Tailwind rebuild leaves the tracked stylesheet byte-identical, and a second stack built from the final commit served exactly the HEAD stylesheet (`a4b2db26…`).

## Skipped Issues

None. IN-01, IN-02, IN-03, IN-04, IN-05, IN-07 and IN-08 were out of scope by instruction and are untouched.

## Verification

Where it ran: the main checkout (no worktree), plus a disposable Compose stack for browser specs. The stack was project `p187_fix_e2e` on port 4377, built twice from this checkout (the second build is the final code commit; the only uncommitted differences were `.planning/` files). It was torn down with its volumes, network and image; the retained preview (`scrypath_ecommerce`, port 4002) was never touched. Docker build cache from the two builds is shared with other projects and was not pruned.

Passed on the final code commit `cf744109`:

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | 0 AA failures |
| `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass |
| `node --test scripts/ci/ui_state_pairs.test.cjs` | 39 pass |
| `node --test examples/scrypath_ecommerce/scripts/reskin-capture.selftest.mjs` | 25 pass |
| `cd scrypath_ops && mix test` | 2 doctests, 513 tests, 0 failures |
| `mix format --check-formatted` (root and `scrypath_ops`) | clean |
| `MIX_ENV=test mix credo --strict` (root) | no issues. `scrypath_ops` has no credo dependency, so there is nothing to run there |
| `mix verify.ops_ui` | exit 0: boundary test 2 tests, ops suite 2 doctests and 513 tests, 0 failures |
| `mix verify.core --exclude integration --exclude docs_contract` | exit 0: 5 properties, 1158 tests, 0 failures (103 excluded), docs built with warnings as errors, no-optional-deps build verified |
| `ops_host_contract.spec.ts` (P-17a to P-17d, including the new case) | 4 passed |
| `settings_layout.spec.ts` (the "Checking Meilisearch settings…" word, 8 theme and width variants with axe) | passed |
| `admin_path_motion.spec.ts` | passed |
| `admin_shell_chrome.spec.ts` (palette open and Escape close, drawer, shortcuts, flash) | 38 passed |
| `ops_reskin_contract.spec.ts` | 30 passed |
| `phase173_status_actions.spec.ts` | the mounted variants passed; 3 `standalone` tests could not run (see below) |
| WR-02 on a real stack | served stylesheet equals HEAD on the rebuilt stack; a smoke run refuses a stale loopback stack and an untracked source file |

Not run, and why:
- The 3 `standalone` tests in `phase173_status_actions.spec.ts` (Search health status, long evidence, refresh action) navigate to `http://standalone_ops:4003`, a second stack from `compose.phase173.yaml` that this single-host stack does not provide (`ERR_NAME_NOT_RESOLVED`). They are not related to these changes, and the mounted variants of the same tests, which read the refresh button's `aria-busy`, passed. I did not bring up the second stack.
- No real screen-reader run was done. The accessibility changes are proven as DOM structure only.
- No gate was blocked by permissions; `mix verify.repository_contracts` was not part of this request and was not run.

## Notes for the orchestrator

- `187-CAPTURE-INVENTORY.md` gained one sentence saying the two existing capture sets were taken under the old rule (constant `clean: true`, no served-stylesheet hash) and what a set taken now records. It is committed with this report. A re-capture would produce manifests that carry the new evidence; I did not re-capture.
- `187-UI-SPEC.md` E-16 and `DESIGN-TOKENS.md` still say loading is "a word plus `aria-busy`". That is still true in the corrected structure (the busy region is the skeleton or the replaced content, not the word), so I left them alone.
- `.planning/config.json`, `.planning/state.json`, `.planning/STATE.md` and the untracked `187-REVIEW.md` were not staged.

---

_Fixed: 2026-11-19T22:52:37Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
