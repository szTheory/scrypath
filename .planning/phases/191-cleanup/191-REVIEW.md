---
phase: 191-cleanup
reviewed: 2026-11-21T00:12:42Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - CONTRIBUTING.md
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - .github/workflows/ci.yml
  - dev/mix/tasks/verify.phase99.ex
  - mix.exs
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
  - examples/scrypath_ecommerce/priv/static/favicon.svg
  - test/mix/tasks/brand_pin_contract_test.exs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/release/package_contents_test.exs
  - website/scripts/build.mjs
  - dev/mix/tasks/verify/ui_tokens.ex
  - test/mix/tasks/ui_tokens_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
  necessity: 0
status: issues_found
---

# Phase 191: Code Review Report

**Reviewed:** 2026-11-21T00:12:42Z
**Depth:** standard
**Files Reviewed:** 14 (the two deleted code files were read from `origin/main`; the 36 deleted brand-directory files were checked by tree-wide search, not read)
**Status:** issues_found

## Summary

Reviewed HEAD `885b300b` against `origin/main` (source files only, `.planning/` excluded). The deletion itself is clean and the gates are not vacuous. Nothing here blocks the phase.

What I verified directly:

- **No dangling readers.** `git grep -i` for the old directory name, `ui_tokens`, `UiTokens` and `verify.ui_tokens` across every tracked file outside `.planning/` finds only: the surviving `Scrypath.TestSupport.UiTokens` helper (still used by the contrast test and its helper test), `ui-tokens.test.mjs` references, and one slashless literal in `brand_pin_contract_test.exs:859` (IN-03). Nothing in `mix.exs` (`preferred_envs`, package `files:`), `verify.phase99.ex`, `ci.yml` (the `ops-ui-path` regex member is gone, no other mention), `package_contents_test.exs` (the `later_hidden` pin, the 27-module list, floor 53 vs 54 live) or any doc.
- **The empty allowlist is still a tripwire.** With `entries: []` and both ceilings at 0, any retired value or the directory string in a non-exempt file is "unlisted" (the planted tests run through the same `scanFiles` and `checkAllowlist` with explicit limits, so they do not depend on the live ceilings). A finite raise of either ceiling fails in both directions; only a non-finite value silently disables it (IN-02).
- **Cheap runs are green.** `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` passes 82 of 82 (76 literal `test("` calls, equal to `@min_token_test_calls`). `mix test` on the brand pin, contrast wrapper, workflow wiring, verify.phase99 and package contents files passes (218 tests, `contrast_child` excluded). `mix format --check-formatted` is clean. `git diff --name-only ce250655..HEAD` outside `.planning/` is empty, so the gate receipt matches the final code head.
- **Probes.** I extracted the invariant and consumer-scan code into a scratch module outside the repository and fed it forms the planted cases do not cover. The findings below are each backed by one of those runs.

The weaknesses are all false-negative or false-positive gaps in the new source invariants and a bypass in the favicon consumer scan. They are mostly outside what the planted cases exercise, and none of them fires on today's source.

## Warnings

### WR-01: Class-utility invariants and theme tokens are skipped inside `app.css`, which the scope names

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:2081-2086` (also `:1940`, `:1932`, `:2133-2137`)
**Issue:** `app.css` is in scope, but two of the five invariants are applied only to `.ex`, `.heex` and `.js` (`textSource`, line 2081). In CSS, the uppercase check is only the exact declaration `text-transform: uppercase`, and the arbitrary-size check does not run at all. Probes that were not flagged: `@apply uppercase tracking-wide;`, `@apply text-[10px];` and `@apply animate-spin;` in `app.css`; `text-transform: UPPERCASE` and `FONT-SIZE: 10px` (CSS keywords and property names are case-insensitive, the patterns have no `i` flag).

The floor has a related hole. It resolves only `font-size` declarations. In Tailwind v4 (`@import "tailwindcss"`, `@theme`), a size token declared in `@theme` and used only as a utility class is never resolved: `@theme { --text-xs: 0.5rem; }` or a new `--text-ops-tiny: 0.5rem` used as `class="text-ops-tiny"` passes. That class form is the main live channel (87 `text-ops-*` uses in `scrypath_ops/lib`). The live floor test only asserts that `--text-ops-sm` resolves to 12.

Today `app.css` has zero `@apply` and all eight `--text-ops-*` values are at least 12 px, so nothing fails now. The fix is cheap and passes on live source.
**Fix:**
```js
// 1. run the class checks on CSS too (covers @apply), and make the CSS patterns case-insensitive
const UPPERCASE_DECLARATION = /text-transform\s*:\s*uppercase/gi;
const CSS_FONT_SIZE = /(?<![\w-])font-size\s*:\s*([^;}]*)/gi;   // same for TEXT_FONT_SIZE and CSS_FONT_SHORTHAND
// in opsSourceFailures, drop the `textSource` gate for ARBITRARY_TEXT_SIZE and UPPERCASE_TOKEN
// (keep UPPERCASE_DECLARATION for CSS), so `@apply uppercase` and `@apply text-[10px]` are reported.

// 2. check every size token directly, so a utility-only token cannot hide
if (extension === ".css") {
  for (const [name, values] of props) {
    if (!name.startsWith("--text-")) continue;
    for (const value of values) {
      const outcome = resolveFontSize(value, props);
      if (outcome.error !== undefined || outcome.px < FONT_FLOOR_PX) {
        failures.push(`[${OPS_INVARIANT.floor}] ${relativePath} ${name} ${value} is below ${FONT_FLOOR_PX} px or unresolvable`);
      }
    }
  }
}
```
Add one planted case per form (`@apply uppercase`, `@apply text-[10px]`, `@theme { --text-ops-tiny: 0.5rem }`, `text-transform: UPPERCASE`) and bump `@min_token_test_calls` in the same commit.

### WR-02: Escaped quotes in Elixir strings produce a false positive and a false negative

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:1933` (`TEXT_FONT_SIZE`), `:1935-1936` (`STYLE_ATTRIBUTE`, `STYLE_FONT_SHORTHAND`), `:2071-2079`
**Issue:** In a regular Elixir string the quotes around an attribute are written `\"`. Two consequences, both reproduced:

- `"<p style=\"font-size: 0.875rem\">x</p>"` is flagged as "font-size 0.875rem\ is unresolvable". The captured value keeps the trailing backslash, so a legitimate 14 px declaration fails closed with a misleading message. The same string with `9px` fails too, but for the wrong reason.
- `"<p style=\"font: 9px x\">x</p>"` is not flagged at all. `STYLE_ATTRIBUTE` needs an unescaped quote after `=`, so the font-shorthand channel is blind to every style attribute written in a normal `.ex` string.

The planted and accept cases use `~s(...)` and unescaped quotes, so they never see this form.
**Fix:**
```js
// resolveFontSize: ignore a trailing escape before resolving
const value = raw.replace(/\\+$/, "").replace(/\s*!important\s*$/i, "").trim().replace(/\s+/g, " ");

// STYLE_ATTRIBUTE: allow an escaped quote as the delimiter
const STYLE_ATTRIBUTE = /(?<![\w-])style\s*=\s*(?:\\?"((?:[^"\\]|\\.)*)\\?"|'([^']*)')/g;
```
Add a planted case (`defmodule P do def a, do: "<p style=\"font: 9px x\">x</p>" end`) and an accept case (`"<p style=\"font-size: 0.875rem\">x</p>"`).

### WR-03: The unthemed-favicon consumer scan can be bypassed by a symlink (and by near copies)

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:2353` (`if (!stat.isFile()) continue;`), `:2354-2362`
**Issue:** `faviconConsumerFailures` uses `lstat` and skips anything that is not a regular file. A tracked symlink to the pinned unthemed favicon (the most natural way to "reuse" a brand asset without copying bytes, and Plug.Static serves through it) is neither byte-compared nor has its link target read, so it passes. Reproduced in a scratch git tree: `priv/static/favicon.svg -> ../../brand/assets/icon/favicon.svg` reports no failure. The repository has no tracked symlink today (`git ls-files -s` shows none), so this is a future bypass, not a live one. The same probe showed two further misses that the design accepts but the docs call "path-and-bytes": a byte copy with one trailing newline (the one-changed-byte planted case asserts this is intended), and a path split across string pieces such as `Path.join(["brand", "assets", "icon", "favicon.svg"])`. A directory-level copy such as `cp -r brand/assets/icon dist/` into an ignored output tree is out of reach of any tracked-file scan.

The tripwire in `brand_pin_contract_test.exs` still fires when the pinned file itself changes, so the damage is limited to a consumer silently serving the black icon.
**Fix:** read the link target for symlinks and compare the resolved bytes:
```js
if (stat.isSymbolicLink()) {
  const target = fs.readlinkSync(absolute);
  const resolved = path.resolve(path.dirname(absolute), target);
  if (target.includes(FAVICON_NEEDLE) || (fs.existsSync(resolved) && fs.readFileSync(resolved).equals(pinnedBytes))) {
    failures.push(`${relativePath} is a symlink to the pinned unthemed favicon`);
  }
  continue;
}
if (!stat.isFile()) continue;
```
Add a planted symlink case. For near copies, consider comparing with trailing whitespace trimmed (`pinned.toString().trim()`) and say plainly in the section header that renamed-but-edited copies are out of scope.

## Info

### IN-01: Header of the token test still states the old deletion trigger and churn

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:32-35`
**Issue:** The header says "Deletion trigger: ScrypathOps stops carrying its own theme blocks, or the theme blocks are generated from brand/tokens.json. Expected churn per UI PR: one token-map row flip per adopted property, and a lower ceiling." The reworded CONTRIBUTING row (this phase) says the deny-list and directory tripwire are permanent and the deny set grows only when a value is retired. With 0 pending cells and both ceilings at 0, "a lower ceiling" and "row flip per adopted property" no longer describe anything. The header and the ledger now disagree on when to delete the gate.
**Fix:** Replace the two sentences with a pointer: "Deletion trigger and churn: see the CONTRIBUTING gate ledger row for this file."

### IN-02: A non-finite ceiling silently disables the ratchets

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:68`, `:72`, `:1020-1023`, `:1075-1082`
**Issue:** The "second key" holds for finite values: raising `ALLOWLIST_CEILING` or `HITS_CEILING` without the matching file edit fails ("lower it to 0"). But both comparisons are guarded with `Number.isFinite`, and the planted tests use `Infinity` as "no limit" for their own purposes. Setting either live constant to `Infinity` (or `NaN`) turns both checks off with no test failing, and then allowlist entries can be added with arbitrary `max_hits`. The same is true of `PENDING_CEILING` and `HEX_OUTSIDE_CEILING`. A reviewer would see the diff, so this is hardening, not a live hole.
**Fix:** One cheap test: `for (const value of Object.values(LIMITS)) assert.ok(Number.isInteger(value) && value >= 0, "live ceilings are non-negative integers")`.

### IN-03: One slashless spelling of the old directory name remains

**File:** `test/mix/tasks/brand_pin_contract_test.exs:859`
**Issue:** `assert brand_entries(planted) == ["brand", "brandbook"]` spells the name whole, while line 857 builds it at runtime. The deny scan looks for the name with its trailing slash, so it does not flag this, and both phase summaries record it as a known choice. It is the only remaining tracked mention outside `.planning/`.
**Fix:** Compare against the planted list instead of a literal: `assert brand_entries(planted) == ["brand", "brand" <> "book"]`.

### IN-04: The deleted-to-surviving map overstates what survives for a CSS-only token mutation

**File:** `.planning/phases/191-cleanup/191-01-SUMMARY.md` (assertion map, last row); `test/mix/tasks/ui_contrast_contract_test.exs:324-326`
**Issue:** The deleted `canonical repository contracts ... reject each independent token source mutation` test bumped a dark `--ops-bg` by one hex unit (a change contrast cannot see) and required `mix verify.repository_contracts` to fail with a token-contract message. The map names the `contrast_child` tests as the survivor. They are not: each requires a contrast failure (`"Contrast check: FAIL"` or a checker error; `"failed outside contrast"` is an assertion), so they would stay green if the token parity test were removed from the canonical lane. What survives is unit-level (planted parity cases in the Node test) plus wiring (`ui_contrast_contract_test.exs` listed in `@focused_tests`, asserted by string match in `verify.phase99_test.exs`). I judge that adequate, and the summary does say it does not prove completeness, but the map's wording should not claim an end-to-end witness that no longer exists. A nested canonical run costs about 5 minutes, so a new child case is probably not worth it.
**Fix:** Reword the row to "unit-level and wiring-level only; no end-to-end witness for a parity-only CSS drift".

### IN-05: The header's claim that a comment marker in a string "can only hide a violation on the same line" is wrong

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:1915-1917`, `:1961-1983`
**Issue:** True for the `#` and `//` forms; reproduced as false for the block forms. A JS string `"assets/*"` followed by a real violation on a later line and any later `*/` hides every line in between. The same holds for an HTML comment opener inside a `.heex` attribute string. Also reproduced: in `.ex`, ` #fff; font-size: 10px` inside a string hides the size (a space before the `#` makes it a comment start). The live source has no `/*` in JS, and the only `#`-after-space-in-a-string lines are seven non-style lines, so there is no live exposure.
**Fix:** Correct the sentence (hidden text can span lines for `/* */`, `<!-- -->` and `<%!-- --%>`), or lex string literals before blanking. The comment is the cheap fix.

### IN-06: Known false negatives and noisy matches on the other invariants

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:1938`, `:1941-1943`, `:2082-2090`
**Issue:** Each was probed. None fires on live source.
- Not caught, so the "no arbitrary size", "no infinite" and "no size xs" claims are narrower than their names: `text-[.7rem]` (leading dot, the pattern wants a digit), `text-[small]`, `text-(length:--x)`; a literal `class="btn btn-xs"` or `badge-xs` (only the `size: :xs` caller is checked, which the docs say); `animate-spin`, `animate-pulse` and daisyUI `loading` classes (infinite iteration without the word); `el.style.setProperty("font-size", ...)`, `font_size:` keys, `size="xs"` strings.
- Flagged on legitimate source: the words `uppercase` or `infinite` in a docstring or message (documented); `def a(%{size: :xs})` pattern heads (flagged as a "caller", unlike the `size == :xs` branch the decision record exempts); `font-size: var(--x, 14px)` and `font: var(--font-ops)` (fail closed by design, with a clear message).
**Fix:** If any of these matter, the cheapest additions are `text-\[\.?\d`, `animate-(spin|pulse|ping|bounce)` and `\bloading(?:-[a-z]+)?\b` inside class strings. Otherwise add the missed forms to the section header's "not read" list so the stated limits match the behavior.

---

_Reviewed: 2026-11-21T00:12:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
