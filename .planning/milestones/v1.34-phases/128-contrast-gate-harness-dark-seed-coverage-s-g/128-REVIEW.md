---
phase: 128-contrast-gate-harness-dark-seed-coverage-s-g
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/scrypath_ecommerce/contrast-checker.mjs
  - examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts
  - examples/scrypath_ecommerce/Makefile
  - examples/scrypath_ecommerce/package.json
  - scrypath_ops/assets/css/contrast-pairs.mjs
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 128: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the WCAG AA contrast gate harness: the dependency-free token-pair checker
(`contrast-checker.mjs`), the `@axe-core/playwright` contrast matrix spec
(`admin_contrast_matrix.spec.ts`), the muted-alpha manifest (`contrast-pairs.mjs`),
the Makefile lanes, `package.json`, and the design-tokens doc.

The WCAG math is correct (verified: black/white = 21.00; `#777777`/white = 4.48;
`#767676`/white = 4.54; `#595959`/white = 7.00 — all match the self-test assertions),
and the self-test passes and exits 0. The exit-code contract (`exit 1 iff aa_fail > 0`,
advisory never gates) is implemented correctly in the token checker.

However, the review surfaced three correctness/integrity BLOCKERs:

1. **D-15 Guard 2 silently misses every single-line CSS rule.** The guard regex is
   anchored to `^\s*color:`, so the one single-line muted rule in `app.css`
   (`.ops-text-meta`, line 537) is never scanned — the "lockstep" integrity guarantee
   has a hole exactly where the prompt flagged fragility.
2. **The axe spec's three scenario tests clobber a single `contrast-report.{json,md}`**
   — only the last scenario's findings survive.
3. **The AAA "advisory, never gates" pass can hard-fail a test** via an uncaught
   axe-core throw on screens where none of the 8 `BODY_SELECTORS` exist — violating
   D-20's exit-code contract.

Plus rounding-before-threshold, one-directional manifest validation, nested-block
selector mis-attribution, and report-dir collision between the two producers.

## Critical Issues

### CR-01: D-15 Guard 2 silently skips single-line CSS rules — the lockstep guarantee has a hole

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:346` (and 354-394)
**Issue:**
`colorMixRe` is anchored to the start of the line:
`/^\s*color:\s*color-mix\(in oklch,\s*var\(--color-base-content\)\s*(\d+)%,\s*transparent\)/`.
This only matches when `color:` is the first token on the line. But `app.css` line 537
is a single-line rule:

```css
.ops-text-meta  { font-size: ...; line-height: ...; color: color-mix(in oklch, var(--color-base-content) 55%, transparent); }
```

Here `color:` is mid-line, so the guard never sees it. I confirmed empirically that the
guard matches only **12 of the 13** `color: color-mix(... base-content ...)` occurrences
in `app.css` — `.ops-text-meta` is dropped. Because `.ops-text-meta` happens to already
be in the manifest, the gate still passes today, but the guard provides **zero
protection** for that selector: if someone deletes the `.ops-text-meta` entry from
`contrast-pairs.mjs` or changes its alpha in `app.css`, the "untracked muted token"
guard will not catch it. This is precisely the false-negative the D-15 lockstep exists
to prevent, and it generalizes to any future single-line muted rule.

**Fix:** Match the property anywhere on the line, not just at line start, and pull the
selector when the rule is single-line. Minimal change — drop the `^\s*` anchor and detect
same-line selectors:

```js
// Match `color: color-mix(...)` anywhere on the line (handles single-line rules)
const colorMixRe = /(?:^|[{;]\s*)color:\s*color-mix\(in oklch,\s*var\(--color-base-content\)\s*(\d+)%,\s*transparent\)/;
// ...
// If the match line itself contains a `{`, treat the text before `{` as the selector;
// otherwise walk backwards as today.
const sameLineSel = lines[i].match(/^\s*([^{}@]+?)\s*\{/);
let selector = sameLineSel ? sameLineSel[1].trim() : null;
if (!selector) { /* existing backward walk */ }
```

Add a self-test fixture that feeds a single-line muted rule and asserts the guard detects
it, so this regression is locked.

### CR-02: Three scenario reports overwrite the same file — only the last scenario survives

**File:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts:242-309` (and 401)
**Issue:**
`describeScenario` is invoked three times (`incident`, `all_green`, `empty`), each
defining a separate Playwright `test()`. Each test calls
`writeContrastReport(findings, scenario)`, which writes to a **fixed path**
`path.join(contrastReportDir, "contrast-report.json")` (and `.md`). With
`fullyParallel: false` + `workers: 1` (CI), the tests run sequentially and the last to
finish (`empty`) **overwrites** the `incident` and `all_green` reports — so the persisted
report reflects only one scenario's findings, not the full matrix. Locally
(`workers: undefined`) it is worse: parallel workers race on the same file, producing a
torn/interleaved report. The per-test `expect(aaFails).toBe(0)` gate is still correct
(each test asserts its own in-memory findings), but the artifact consumed downstream is
lossy/misleading. D-21 promises a readable report of *what failed*; this delivers one
scenario's worth.

**Fix:** Namespace the report filename by scenario, then optionally merge:

```js
await writeFile(
  path.join(contrastReportDir, `contrast-report.${scenario}.json`),
  JSON.stringify(report, null, 2)
);
await writeFile(
  path.join(contrastReportDir, `contrast-report.${scenario}.md`),
  md
);
```

Or accumulate findings across scenarios in a module-level array and write the unified
report once in a `test.afterAll`. Either way, stop colliding on one filename.

### CR-03: AAA "advisory" pass can hard-fail the test via an uncaught axe-core throw

**File:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts:354-359` (no try/catch)
**Issue:**
The AAA pass adds all 8 `BODY_SELECTORS` as `.include(sel)` filters, then calls
`aaaBuilder.analyze()`. axe-core throws
`Error("No elements found for include in page Context")` (confirmed in
`node_modules/axe-core/axe.js:18997`, guarded by
`context.include.length === 0 && context.frames.length === 0`) when the **entire** include
set resolves to zero elements — i.e., on any screen where *none* of
`main p / main li / main dd / main dt / .ops-text-body / .ops-preflight__hint /
.ops-handoff__hint / .ops-intent-card__summary` are present. Several of the 13
screen-states (e.g. empty-state / zero-result screens) plausibly contain none of these.
There is no `try/catch` around the AAA pass, so the throw propagates out of `axeCheck`,
out of the scenario test, and **fails the gate** — even with zero AA contrast violations.
This directly violates D-20 ("AAA advisory NEVER affects exit code"): a screen lacking
body text can turn a clean run red.

**Fix:** Make the AAA pass non-fatal and tolerant of empty includes:

```js
let aaaResults = { violations: [] };
try {
  const aaaBuilder = new AxeBuilder({ page }).withRules(["color-contrast-enhanced"]);
  // Only include selectors that actually match on this page
  for (const sel of BODY_SELECTORS) {
    if (await page.locator(sel).count() > 0) aaaBuilder.include(sel);
  }
  // If nothing matched, skip the AAA pass entirely (no body text to advise on)
  if (/* at least one include added */) aaaResults = await aaaBuilder.analyze();
} catch (err) {
  // D-20: AAA is advisory — never let it affect the gate
  console.warn(`AAA advisory pass skipped (${err.message})`);
}
```

## Warnings

### WR-01: Contrast ratio is rounded to 2 decimals *before* the AA/AAA threshold compare

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:71` (consumed at 419-421)
**Issue:**
`contrastRatio` returns `Math.round(ratio * 100) / 100`, and `evaluatePair` compares the
*rounded* value against the threshold (`actual >= thresholds.aa`). A true ratio of, say,
4.497 rounds to 4.50 and **passes** AA, whereas axe-core (the browser gate this checker is
meant to agree with) compares the un-rounded ratio and would **fail** it. The manifest and
DESIGN-TOKENS.md both promise "one verdict" between the fast checker and axe; rounding
before thresholding can break that at the boundary. No current token pair lands in the
(4.495, 4.5) window, so this is latent, not active — but it is a correctness defect.
**Fix:** Keep full precision for the comparison; round only for display:

```js
function contrastRatioRaw(fg, bg) { /* return (lighter+0.05)/(darker+0.05) without rounding */ }
// in evaluatePair:
const raw = contrastRatioRaw(fg, bg);
const passAA = raw >= thresholds.aa;
const actual = Math.round(raw * 100) / 100; // display only
```

### WR-02: D-15 manifest validation is one-directional — stale manifest entries are never caught

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:340-412`
**Issue:**
`assertNoUntrackedMutedTokens` only fails when an `app.css` occurrence is missing from the
manifest. The reverse — a manifest entry whose `(selector, alpha)` no longer exists in
`app.css` (renamed selector, removed rule, changed alpha) — is never flagged. Combined
with CR-01, a single-line rule whose alpha changes in `app.css` but not in the manifest
would go fully undetected: the guard never scans the line, and the stale manifest entry is
never reconciled. The checker would then evaluate contrast against a `(selector, alpha)`
that no longer matches the CSS — a silently wrong verdict.
**Fix:** After collecting `found`, also assert every non-`decorative` manifest entry was
matched against an `app.css` occurrence (within the 0.01 alpha tolerance); throw on any
manifest entry with no corresponding CSS hit.

### WR-03: Selector backward-walk mis-attributes muted colors inside nested blocks

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:350` and 376-384
**Issue:**
The nearest-selector backward walk uses `selectorRe`, which deliberately rejects `@media`
(and other `@`-rules). So a muted `color:` placed inside a nested block —
`@media (...) { .ops-foo { color: color-mix(...) } }` — would skip past the `@media {`
line and bind the muted color to the **outer** selector (or, if the nested rule reopened
`.ops-foo`, to a wrong ancestor). Today no muted `color:` is nested (`@media` blocks at
lines 529/774/780/936/1009/1237 contain none), so this is latent, but `app.css` has 6
`@media` blocks and the harness is meant to guard future edits. The walk also assumes the
nearest `{`-terminated line is the owning selector, which breaks for any multi-selector or
brace-bearing comment.
**Fix:** Track brace depth while scanning so the walk binds to the innermost open rule, and
do not silently skip at-rule wrappers — either resolve into them or fail loudly when a
muted `color:` is nested where the simple walk cannot attribute it.

### WR-04: Both producers default to the same report dir+filename and clobber each other

**File:** `examples/scrypath_ecommerce/Makefile:25, 73-80` (and `contrast-checker.mjs:34`, `admin_contrast_matrix.spec.ts:42`)
**Issue:**
`make contrast` (token checker, `producer: "token"`) and `make contrast-matrix` (axe spec,
`producer: "axe"`) both default `CONTRAST_REPORT_DIR` to `test-results/contrast` and both
write `contrast-report.{json,md}`. Running one after the other overwrites the first's
report with the second's, despite the different `producer` and (for axe) `scenario` fields
making them non-interchangeable. A consumer reading `contrast-report.json` cannot tell
which producer it came from without inspecting the body.
**Fix:** Either give each producer a distinct filename
(`contrast-report.token.json` / `contrast-report.axe.json`) or distinct default subdirs
(`test-results/contrast/token/` vs `.../axe/`). Update both writers and the Makefile.

### WR-05: `import(absolutePath)` of the cross-workspace manifest is not portable

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:470` (PAIRS_PATH from line 32)
**Issue:**
`await import(PAIRS_PATH)` is given a raw absolute filesystem path. This works on POSIX
(verified here), but Node ESM dynamic import of an absolute path is **not** reliable on
Windows, where a `file://` URL is required (`ERR_UNSUPPORTED_ESM_URL_SCHEME`). The path is
already constructed via `path.resolve(__dirname, "../../scrypath_ops/...")`, so the
cross-`examples/`↔`scrypath_ops/` boundary itself is sound, but the import scheme is the
fragile part.
**Fix:** Wrap with `pathToFileURL` before importing:

```js
import { fileURLToPath, pathToFileURL } from "node:url";
// ...
const manifest = await import(pathToFileURL(PAIRS_PATH).href);
```

## Info

### IN-01: Unused imports in contrast-checker.mjs

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:20-21`
**Issue:** `appendFile` (line 20, from `node:fs/promises`) and `createWriteStream`
(line 21, from `node:fs`) are imported but never used — the CI summary append uses a
dynamically-imported `appendFileSync` instead (line 563).
**Fix:** Remove both unused imports.

### IN-02: Header comment says "11 semantic pair rules" but PAIR_RULES has 11 entries while comment math says base+semantic

**File:** `examples/scrypath_ecommerce/contrast-checker.mjs:78-92`
**Issue:** The comment labels `PAIR_RULES` as "11 semantic pair rules" and the array does
contain 11 entries (3 base-content + 8 X-content). This is consistent, but the adjacent
D-15 Guard 1 comment (line 318) describes a separate "20 tokens (4 base + 16 semantic)"
count; the two "semantic" counts use the word differently and can confuse a future editor
reconciling the manifest. Purely a documentation-clarity nit.
**Fix:** Disambiguate the comments (e.g. "11 contrast *pair* rules" vs "20 `--color-*`
*token declarations*").

### IN-03: `degraded` scenario is referenced in a comment but never exercised by the matrix

**File:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts:378`
**Issue:** The comment at line 378 mentions `incident`/`degraded` injecting contract
drift, but only `incident`, `all_green`, and `empty` are run via `describeScenario`. The
`degraded` seed scenario (defined in `helpers/e2e.ts`) is never contrast-checked. This may
be intentional curation, but the dangling reference invites a reader to assume coverage
that does not exist.
**Fix:** Either add a `describeScenario("degraded", ...)` block or drop `degraded` from the
comment so the documented scope matches the executed scope.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
