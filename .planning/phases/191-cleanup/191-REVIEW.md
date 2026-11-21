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

---

## Fix disposition

**Recorded:** 2026-11-20, on `gsd/phase-191-cleanup`, after the review above.
**Scope decision:** fix WR-01 and IN-01; defer WR-02, WR-03 and IN-02 to IN-06 with no code change.

What the deferred items have in common: the source invariants and the favicon consumer scan are cheap source checks. They read declarations and file bytes, they have known limits, and they are not proof of rendered text size. Every limit below is a known false negative or a known false alarm, and none of them fires on today's ops source (checked with `git grep`, noted per item where it was). The hosted required checks on the pushed head are the full gate for this fix; `mix verify.repository_contracts` and `mix verify.core` were deliberately not run locally.

**Revisit trigger for every deferred item:** revisit this list if the first real violation or the first false alarm appears in ops source, or when the v1.48 rendered-text and size lint lands (a rendered check makes most of the source-level limits moot, so re-decide which of these still earn their cost then).

### Fixed

| Finding | Status | Commit | What changed |
|---------|--------|--------|--------------|
| WR-01 | fixed | `d1af1b56` | (a) the `font-size`, `font`, `style` and `text-transform` patterns are case-insensitive, so `FONT-SIZE: 10px` and `text-transform: UPPERCASE` fail. (b) the arbitrary `text-[` size and the `uppercase` class checks now run on `app.css`, so `@apply uppercase` and `@apply text-[10px]` fail; `animate-spin`, `animate-ping`, `animate-pulse` and `animate-bounce` count as infinite iteration in `@apply` and in `.ex`, `.heex` and `.js` class strings. (c) every `--text-*` token declared in `app.css` must resolve to at least 12 px, whether or not a `var()` names it, so `@theme { --text-xs: 0.5rem }` used only as `text-ops-tiny` fails. |
| IN-01 | fixed | `aba88094` | The token test header no longer restates the old deletion trigger and churn; it points at the CONTRIBUTING ledger row, so the two cannot disagree. Comment-only. |

Evidence for WR-01, all automated:

- Eight new tests in `examples/scrypath_ecommerce/ui-tokens.test.mjs`: six planted (31 sub-cases, one temp file each, per-file assertions) and two accept cases. Run before the fix, all six planted tests failed and every one of the 31 sub-cases was reported as missed; the accept cases passed. After the fix all 90 node tests pass.
- `@min_token_test_calls` went from 76 to 84 in the same commit, equal to the literal `^test("` count.
- The live-source tests stay green on today's source with no rule narrowed. `git grep` over `scrypath_ops/lib`, `scrypath_ops/assets/js` and `app.css` finds no `@apply`, no `animate-spin`, `animate-ping`, `animate-pulse` or `animate-bounce`, no `text-[`, no `uppercase` or `text-transform` in any case, and exactly eight `--text-ops-*` declarations, all at least 12 px. There is no `--text-*` companion property such as `--text-ops-sm--line-height` today.
- A live mutation confirmed the token check is wired to the real file: lowering `--text-ops-h3` (used only as a class) to `0.5rem` failed "live ops source holds the 12 px font-size floor"; the file was restored with `git checkout`.
- Side effects to know about: a lowercase `text-transform: uppercase` inside an inline style in `.ex`, `.heex` or `.js` is now reported by the declaration pass with the message "text-transform: uppercase" (before it was the "uppercase class or word" message); the word pass skips a word the declaration pass already reported, so there is one report, not two. The `--text-*` namespace is treated as reserved for sizes: a `--text-*` property that is not a px or rem size (and is not a `--text-x--y` companion) fails closed. `DESIGN-TOKENS.md` gained one sentence saying so.

### Deferred (no code change)

| Finding | Known limit | Live today | Why it is deferred |
|---------|-------------|------------|--------------------|
| WR-02 | Escaped quotes in regular Elixir strings. `"<p style=\"font-size: 0.875rem\">x</p>"` is a false positive (the captured value keeps a trailing backslash and fails closed with a misleading message); `"<p style=\"font: 9px x\">x</p>"` is a false negative (the style-attribute channel needs an unescaped quote). | No escaped-quote style attribute or font string in `scrypath_ops/lib`. | Both forms need a small lexer-level change to the string handling; ops writes templates as HEEx or `~H`, where the quotes are plain. The false positive fails closed, so it is loud, not silent. |
| WR-03 | The favicon consumer scan skips symlinks (a tracked symlink to the pinned unthemed favicon passes), a byte copy with one trailing newline, a path split across string pieces such as `Path.join(["brand", "assets", ...])`, and a directory-level copy into an ignored output tree. | No tracked symlink (`git ls-files -s` shows none with mode 120000). | A future bypass, not a live one. The tripwire in `brand_pin_contract_test.exs` still fires when the pinned file itself changes, so the worst case is a consumer serving the black icon. The planted one-changed-byte case already records that near copies are intended to pass. |
| IN-02 | A non-finite live ceiling (`Infinity`, `NaN`) turns the ratchets off because the comparisons are guarded with `Number.isFinite`. | All four live ceilings are finite and 0. | Hardening only; a reviewer sees the diff. The cheap test the review suggests (every live ceiling is a non-negative integer) stays available. |
| IN-03 | `brand_pin_contract_test.exs:859` spells the old directory name whole (`["brand", "brandbook"]`). | One tracked mention outside `.planning/`. | **Kept as the recorded optional cleanup.** The deny scan looks for the slash form, so it does not flag it, both phase summaries record it, and it predates the phase. The suggested one-line fix is to build the second element at runtime the way line 857 does. |
| IN-04 | The assertion map in `191-01-SUMMARY.md` names the `contrast_child` tests as the survivor of the deleted token-mutation test; they are not an end-to-end witness for a parity-only CSS drift. | n/a (wording) | What survives is unit-level (planted parity cases) plus wiring (`ui_contrast_contract_test.exs` in `@focused_tests`). A new nested canonical child case costs about 5 minutes per run and is not worth it. The review's reword ("unit-level and wiring-level only") stands as the correct reading. |
| IN-05 | The header says a comment marker inside a string "can only hide a violation on the same line". That is true for `#` and `//` and false for `/* */`, `<!-- -->` and `<%!-- --%>`, whose hidden text can span lines. In `.ex`, ` #fff; font-size: 10px` inside a string also hides the size. | No `/*` in ops JS; the only `#`-after-space-in-a-string lines are seven non-style lines. | No live exposure. The comment sentence is still inaccurate and a one-line correction is available whenever someone next edits that header. |
| IN-06 | False negatives: `text-[.7rem]` (leading dot), `text-[small]`, `text-(length:--x)`; a literal `class="btn btn-xs"` or `badge-xs` (only the `size: :xs` caller is checked); daisyUI `loading` classes; `el.style.setProperty("font-size", ...)`; `font_size:` keys; `size="xs"` strings; a capitalised `INFINITE` keyword in CSS (a new note from this fix, since the font and text-transform patterns became case-insensitive and this one did not). False alarms: the words `uppercase` or `infinite` in a docstring or message; `def a(%{size: :xs})` pattern heads flagged as callers; `font-size: var(--x, 14px)` and `font: var(--font-ops)` fail closed by design. | None fires on today's ops source. | Each is a cheap-check limit, not a defect: the invariants are documented as source checks, and `animate-spin`, `animate-ping`, `animate-pulse` and `animate-bounce` moved out of this list with the WR-01 fix. Chasing each remaining form costs more than the browser-level check the v1.48 lint will give. |

---

_Fix disposition recorded: 2026-11-20_
_Fixer: Claude (gsd-code-fixer)_
