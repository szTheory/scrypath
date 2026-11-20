---
phase: 187-scrypathops-re-skin
reviewed: 2026-11-19T22:11:29Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - scrypath_ops/lib/scrypath_ops/posture.ex
  - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/help_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/js/app.js
  - scrypath_ops/assets/js/ops_hooks.js
  - examples/scrypath_ecommerce/Dockerfile
  - examples/scrypath_ecommerce/contrast-checker.mjs
  - scrypath_ops/assets/css/contrast-pairs.mjs
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - examples/scrypath_ecommerce/scripts/reskin-capture.mjs
  - examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts
  - examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts
  - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
  - scripts/ci/ui_state_pairs.test.cjs
findings:
  critical: 0
  warning: 3
  info: 8
  total: 11
  necessity: 2
status: issues_found
---

# Phase 187: Code Review Report

**Reviewed:** 2026-11-19T22:11:29Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

I read every file in scope against `origin/main`, then checked the riskiest claims by running things instead of trusting the tests:

- `mix compile --force --warnings-as-errors` in `scrypath_ops` (MIX_ENV=test) is clean.
- The ExUnit contract and LiveView suites I ran pass (motion, static, component, posture, control room, failed sync, sync and index, saved searches: 293 tests, 0 failures).
- `scripts/ci/ui_state_pairs.test.cjs` (39 tests) and `ui-tokens.test.mjs` (59 tests) pass.
- I recomputed the contrast of every status, muted, primary, edge and selected pair in both themes: all clear 4.5:1 (text) and 3:1 (edge) with room to spare.
- I probed `assertCleanTree` in the capture script with eight porcelain shapes (see WR-02).
- I did not run the Playwright specs (no browser stack here), so the e2e findings below come from reading them.

Net assessment: no blockers. The behavior work holds up.

- Destructive confirms (retry delete, saved-search delete, index promotion) still submit to the same handlers. Every Cancel is `type="button"` and carries `data-ops-modal-cancel`, so initial focus lands on Cancel by default, and the typed-name gate for saved-search delete is unchanged.
- Row status and ranking are correct. `Posture.row_status/1` only returns `:clear` when the backend lists are empty and the queue is observed-empty or not used by the sync mode. `Not observed` and `Not checked` sort above Clear. The sort key `{rank, inspect(mod)}` is total and stable, and it runs once per load or refresh, never in render.
- There is no `raw/1` or runtime atom creation in the changed files. The only user-fed atom lookup is `String.to_existing_atom` against the allowlist, and it is unchanged.
- The Dockerfile change is correct: it deletes only the generated `css` and `js` trees, so the committed fonts survive.
- Font URLs resolve to `<mount>/assets/fonts/...?v=<sha256>`. `AssetPlug` serves `font/woff2` with an immutable cache header only when `v` matches the content hash, and the preload URL in the standalone root layout is identical to the `@font-face` URL, so it is not fetched twice.
- The `assertPendingState` amendment cannot mask other text changes. It rewrites only whole lines equal to `Refreshing…`, only in the observed text, and the new tests pin the allowlist, the single call site and the planted negatives.

The three warnings are an accessibility defect that the phase's own test comment describes (WR-01), a provenance gap in the capture manifest (WR-02), and a promised host behavior with no executable test behind it (WR-03).

## Warnings

### WR-01: `aria-busy="true"` sits on the `role="status"` element that holds the loading word, so assistive technology is told to hold the very announcement it carries

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:800-823` (also `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:2196-2203`; locked in by `scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs:818-823,854`)
**Issue:** `ops_loading/1` renders `<div role="status" aria-busy="true"><p>{@label}</p>…</div>` (and `<span role="status" aria-busy="true">{@label}</span>` for `:inline`). `SyncDriftLive` does the same with `<.ops_status role="status" aria-busy="true" title="Checking Meilisearch settings…">`. `aria-busy` on a live region asks AT to hold updates until it clears. The element is removed when loading ends, so the word is never released. The same test file already states this rule for the reconnect flashes (`reskin_component_contract_test.exs:965-967`: "aria-busy on a live region tells assistive technology to hold its announcements, which would silence the very message this flash exists to deliver") and then asserts the opposite for `ops_loading`. The effect is that the phase's A11Y-03 goal, a word that tells AT the content is on its way, is not delivered for Search ("Running search...") or Sync and index ("Checking Meilisearch settings…"). The UI-SPEC wording ("`aria-busy="true"` on the loading region") allows the compliant reading: the region that is loading, not the status node.
**Fix:** Keep the word in a status node with no `aria-busy`, and put `aria-busy` on the container whose content is pending.

```heex
<%!-- ops_loading :bars --%>
<div class={["ops-loading ops-loading__bars", @class]} {@rest}>
  <p class="ops-loading__label" role="status">{@label}</p>
  <span :for={n <- 1..@lines} class={[...]} aria-hidden="true"></span>
</div>
```

and in the LiveViews set `aria-busy={@searching}` / `aria-busy={@settings_checking?}` on the results or settings section that is being replaced. Update the E-16 assertions (`[aria-busy]` and `[role=status]` on the same node) to assert they are on different nodes. The refresh button is fine as it is: a button is not a live region.

### WR-02: The capture manifest claims provenance it never checks (`clean: true` is a literal, untracked files are ignored, nothing ties the running stack to `source_sha`)

**File:** `examples/scrypath_ecommerce/scripts/reskin-capture.mjs:15-17,67-86,165-167,262`
**Issue:** The header says the clean-tree check exists so "the manifest names the source that rendered the images". It does not establish that:
1. `assertCleanTree` runs `git status --porcelain --untracked-files=no`, so a new, untracked `.ex`, `.heex`, `.css` or `.js` file under `scrypath_ops/` or `examples/` passes. The comment's justification, "Untracked entries never affect rendering decisions", is wrong for a bind-mounted dev stack that compiles whatever is on disk. I confirmed `?? scrypath_ops/lib/new.ex` is accepted.
2. The manifest writes `clean: true` unconditionally (line 262).
3. The script records `git rev-parse HEAD` of the checkout it runs in, not of what `--base-url` serves. The maintainer notes in this repo say the base Compose stack runs a stale baked image until rebuilt, so a "before" or "after" set can be rendered by code that is not `source_sha`. Reviewers comparing before and after sets would be reading evidence labelled with the wrong commit.
**Fix:** Bind the evidence to the served build, cheaply. Fetch `${baseUrl}/admin/search/assets/css/app.css`, compare its sha256 with `scrypath_ops/priv/static/assets/css/app.css` at HEAD, refuse on mismatch, and record `served_css_sha256`. Also run the status check without `--untracked-files=no` for paths outside `.planning/` (or list untracked source paths in the refusal). Drop the hard-coded `clean: true` or derive it from the check.

### WR-03: The host-override promise for System dark is not covered by an executable test (and the README omits the cascade-layer condition)

**File:** `examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts:12-14,201` (promise in `scrypath_ops/README.md:125-128`)
**Issue:** The README tells hosts that "a plain `:root { --color-primary: ... }` rule that loads after the ops stylesheet wins in light, in an explicit dark theme and in System dark". P-17c's System dark case does not test that rule. It injects `@media (prefers-color-scheme: dark){:root:not([data-theme]){…}}` instead, and the spec comment says the plain form was confirmed by "a one-off probe". The repo's house rule is never to claim more than automated evidence proves. The claim is also only true for unlayered rules, or rules in a later or equal layer: the daisyUI theme variables are emitted inside `@layer base` (built `app.css` lines 5900 and 5949). A host that sets its accent with Tailwind v4 `@theme { --color-primary: … }` lands in the lower `theme` layer and loses to ops' `base` layer regardless of load order.
**Fix:** Add the plain `:root{--color-primary:#123456}` rule as a fourth case with `{ scheme: "dark", preference: null }` in P-17c, and add one sentence to the README: the override must be an unlayered rule (or in `@layer base` or later).

## Info

### IN-01: Sync and index shows "Pending" for a queue that holds only scheduled retries

**File:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1720-1724,2023`
**Issue:** `signal_status(:pending_queue_work)` is `:pending`, and `Reconcile` raises that signal for `queue.pending != [] or queue.retrying != []` (`lib/scrypath/operator/reconcile.ex:201-204`). A retry-only queue reads "Pending 2 scheduled retries" here while Search health says "Retrying" for the same condition. This is what UI-SPEC line 298 specifies, and `sync_drift_live_test.exs:293-295` pins that no Retrying word is ever rendered there, so it is not a defect against the spec. I flag it because the phase calls `ops_sync_status` "the one sync-status vocabulary" and this is the one place the same condition gets a second word.
**Fix:** Product decision. If the vocabulary should hold, derive the word from the counts (Retrying when only retries exist, otherwise Pending) and relax the test. Otherwise record the exception in the spec.

### IN-02: Control Room prints the Clear word for a retained observation while the refresh that should confirm it failed

**File:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:140-151`
**Issue:** When `@refresh_issue && @last_successful_posture`, `@posture` is the previous complete observation, so `Posture.worst_status(@posture.rows)` can still be `:clear` and the verdict shows the green Clear word beside "Last successful observation". The label and the amber notice qualify it, and the old UI was equally green, so this is not a regression. But `Clear` is documented as "an observed-clear source", and this one is stale.
**Fix:** Pass `status={if @refresh_issue, do: nil, else: Posture.worst_status(@posture.rows)}` so a retained observation shows its headline without a status word.

### IN-03: Dead `Posture.badge_kind/1` and `metric_tone/1`; a family of `OpsUi` components has no call site

**File:** `scrypath_ops/lib/scrypath_ops/posture.ex:167-177`; `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (`ops_tone_chip`, `ops_metric`, `ops_metric_grid`, `ops_scaffold`, `ops_checkbox_list`, `ops_signal_table`, `ops_object_list`, `ops_object_item`, `ops_upload_box`, `ops_fieldset`, `ops_action_group`, `ops_result_row`)
**Issue:** Both LiveViews that called `Posture.badge_kind/1` now use `verdict_kind/1`, so nothing in `lib/` or `test/` references it or `metric_tone/1`. `badge_kind(:ok) -> :success` is also the "green because the state is ok" mapping the new row logic replaced, so leaving it public invites reuse. The listed components appear nowhere in `lib/` or `test/` outside `ops_ui.ex` (only `ops_tone_chip` has a contract test), yet this phase reworked their tones and docs. This is dead code (category 3), not a necessity finding: it does not run.
**Fix:** Delete `badge_kind/1` and `metric_tone/1`. Either delete the unused components or note which UI-engine milestone will instantiate them.

### IN-04: Phantom inputs that no longer change anything: `ops_status` `neutral`, `ops_badge` `kind`

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:355-377,473-494`; `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1978,1990,2013,2097,2167,2203,2217,2257,2333,2350`; `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:1192-1201`
**Category:** necessity
**Issue:** The `ops_status` doc says the `neutral` attr is "accepted for existing call sites and no longer changes the surface", yet ten call sites still pass it. `ops_badge` says `kind` "has no visual effect" (it only feeds `data-badge-kind`), yet `search_status_badge_kind/1` still computes five clauses of it. The kind already decides the rule, so the state these inputs once selected no longer exists. That is provable from the component docs and the call-site list, and it rests on the assumption that no test or e2e selector depends on `data-badge-kind`.
**Fix:** Remove the `neutral` attr and its ten call-site uses. Either drop `search_status_badge_kind/1` and the `kind` attr from `ops_badge` or keep them only if a selector needs `data-badge-kind`.

### IN-05: Dark and System dark twin rules re-declare the value the base rule already resolves to

**File:** `scrypath_ops/assets/css/app.css:2031-2049,2051-2064`
**Category:** necessity
**Issue:** `.ops-data-card` and `.ops-result-row:not(.ops-search-hit)` get `background: var(--color-base-100)` in explicit dark and in System dark, but `--color-base-100` equals `--ops-surface-1` in both themes (lines 57/86 and 106/135), which is what the base rules use. The comment on the hover twins admits "the base hover rule is the same value (the token resolves per theme); the twins stay so the paired selectors remain mirrored". So these twins change nothing and count against the dual-dark ceiling (12). Rated Info because the ratchet pins them on purpose.
**Fix:** Delete the no-op twins and lower `DUAL_DARK_RULE_CEILING` to match.

### IN-06: Command palette close timer (160 ms) does not match the 80 ms animation its comment describes

**File:** `scrypath_ops/assets/js/ops_hooks.js:227-240`
**Issue:** The comment was updated to say the closing animation is 80 ms (`--duration-ops-fast` is now `instant`, 80 ms). The `setTimeout` that adds `hidden` still waits 160 ms, so for 80 ms the panel and backdrop are fully transparent (the animation fills forward) but still in the DOM, hit-testable and holding focus. A click right after Esc lands on an invisible backdrop.
**Fix:** Use 80 ms, or better, end on `animationend` so the timer cannot drift from the token again.

### IN-07: Pre-existing: the breadcrumb renders nothing on any page, and the command palette input has no visible focus indicator

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:639-657` (`trail_for(_), do: nil`); `scrypath_ops/assets/css/app.css:1748-1750` (`.ops-cmdk__input:focus { outline: none }`)
**Issue:** Both are unchanged from `origin/main`, so they are not regressions. `ops_trail/1` is called by five LiveViews but `trail_for/1` returns `nil` for every page, so `<nav :if={@trail}>` never renders and the `elem(@trail, …)` branch is unreachable. The palette input drops its outline and the bottom border has the same Control Edge color focused or not, so focus is invisible (`contrast-pairs.mjs:23` inventories it as an explicit suppression). WCAG 2.4.7 applies.
**Fix:** Either implement `trail_for/1` or remove the call sites and CSS. Give `.ops-cmdk__input:focus` a visible indicator (for example a Plum 2px bottom border).

### IN-08: Small hygiene items

**File:** `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex:69` and `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex:358`; `examples/scrypath_ecommerce/Dockerfile:31-38`; `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:2475`
**Issue:**
1. `ops-flash__close` is applied in two places and asserted by `reskin_static_contract_test.exs:99`, but `app.css` has no rule for it. The close glyph is a bare 20 px control, and the old opacity and hover cue was removed.
2. The Dockerfile now keeps all of `assets/fonts`, including `display.woff2` (27 KB). The stylesheet never declares or requests it, but `AssetPlug` and `Plug.Static` serve it from every image. It is kept only for the brand pin verifier.
3. The promotion confirm is now labelled "Replace live index with target". The dialog's own description says Meilisearch exchanges the two indexes, so the old live index becomes the prepared one rather than being discarded. "Replace" overstates the loss. The saved-search "Delete saved search permanently" is accurate (`delete_all`).
**Fix:** Add a minimal `.ops-flash__close` rule (24 px target, Ink color, Sunken hover) or drop the class. Exclude `display.woff2` from the image unless the verifier needs it at runtime. Consider "Swap live and prepared indexes" for the promotion label.

---

_Reviewed: 2026-11-19T22:11:29Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
