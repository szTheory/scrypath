---
phase: 188-readme-header-and-hexdocs
reviewed: 2026-11-20T02:22:46Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - README.md
  - PRODUCT.md
  - mix.exs
  - dev/docs/scrypath-exdoc.css
  - docs/releasing.md
  - test/release/package_metadata_test.exs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
findings:
  critical: 0
  warning: 2
  info: 9
  total: 11
  necessity: 0
status: issues_found
---

# Phase 188: Code Review Report

**Reviewed:** 2026-11-20T02:22:46Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Docs-only phase for the Hex library: README `<picture>` header on relative `brand/assets/readme/...` paths, ExDoc `logo`/`favicon`/`assets:`/`before_closing_head_tag`, a docs-owned stylesheet, a new `Scrypath.Release.BuiltDocsBrandTest` module, a release-guide section, and shrunken retired-identity allowlist ceilings.

What I verified by running it (not only by reading):

- `mix test test/release/package_metadata_test.exs` (23 tests), the full `test/release` directory (154 tests), `ui_contrast_contract_test.exs` plus `brand_pin_contract_test.exs` (101 tests, which carries the retired-identity guard), and `test/scrypath/docs_contract_test.exs --include docs_contract` (74 tests) are all green. `mix format --check-formatted` and `mix credo --strict` are clean on `mix.exs` and the new test file.
- `mix docs --warnings-as-errors` is clean in both `MIX_ENV=test` and `MIX_ENV=dev` (the published build).
- Rendered the built docs in Chromium with the OS color scheme deliberately opposite to the ExDoc toggle. Code block background, text, keyword and string colors equal the brand tokens in both themes, so the `body ` / `body.dark ` specificity design really does beat ExDoc's `.dark .makeup ...` rules and is independent of the OS setting. The dark-logo `content:url()` swap works in Chromium and in the installed Firefox (headless screenshot), so no cross-browser concern there.
- `dark` is applied to `document.body` by ExDoc's inline script, so `body.dark` selectors match.
- `package.files` is unchanged, nothing from `brand/` or `brandbook/` is whitelisted, and `package_contents_test` passes. The `docs_config.js` exemption is an exact-string match on one name and cannot mask other unresolved refs. Every guard has a non-empty assertion, so none passes vacuously on an empty build.
- Allowlist arithmetic is exact: entries 10 to 7, `max_hits` sum 238 to 201 (removed 2 + 1 + 34 = 37). Removing README, PRODUCT and the deleted prompt only tightens the guard, and nothing in this phase weakens a ceiling.
- No internal planning labels appear in adopter-facing docs (`README.md`, `docs/releasing.md`, the new `mix.exs` comments).

No blockers. One real accessibility regression comes from the brand background override combined with retained ExDoc colors, and one test-hygiene defect could cause cross-process flakiness. The rest are Info-level. Necessity (#4100) was assessed per `necessity-review.md`; nothing qualified (no impossible-state guards or unused generality that the repository proves), so `necessity: 0`.

## Warnings

### WR-01: Retained ExDoc operator color fails WCAG AA on the new brand code background (light mode)

**File:** `dev/docs/scrypath-exdoc.css:12-19` (also `docs/releasing.md:31`)
**Issue:** The stylesheet paints every `pre code.makeup` block with the brand background `#F0E9E6` but recolors only the token classes the brand book lists. Every other class keeps ExDoc's own color, which was tuned for ExDoc's near-white code background. ExDoc's operator class is `.makeup .o{color:#bc5400}` (also `.ni`, and `.nl` `#b65800`, `.dl` `#408200`). On `#F0E9E6` that is 3.97:1 (relative luminance 0.1703 vs 0.8251), below the 4.5:1 AA threshold for normal text. On ExDoc's own `--gray10` background it was about 4.58:1, so this phase pushed it under AA.
This is not a corner case. The built docs contain 301 `<span class="o">` tokens (`|>`, `=`, `->`, `<-`, `\\`), and Chromium's computed style in light mode is `rgb(188, 84, 0)` on `rgb(240, 233, 230)`. The release guide records "Token classes the brand book does not color keep ExDoc's own colors" as accepted, but nothing checks the resulting contrast, and this repo treats WCAG AA as a gate elsewhere. The new test module proves token-to-role mapping and specificity but never the contrast of what is left over.
**Fix:** Two parts. (a) Add a docs-owned override for the classes that fail and update the derivation test so the extra rule is an explicit, named addition (like `@dark_logo_rule`), for example:
```css
body .makeup .o,body.dark .makeup .o,body .makeup .ni,body.dark .makeup .ni,body .makeup .nl,body.dark .makeup .nl,body .makeup .dl,body.dark .makeup .dl{color:var(--scrypath-doc-text)}
```
Prefer sending the same classes back to the brand book owner so the pin carries them and the derivation stays "pin plus one rule". (b) Add a test in `BuiltDocsBrandTest` that parses the built ExDoc CSS, takes every `.makeup .X{color:#hex}` not overridden by the docs sheet, and asserts contrast against both brand backgrounds is at least 4.5 (the repo already has a contrast helper in `examples/scrypath_ecommerce/contrast-checker.mjs`). Dark mode currently passes for all classes that occur in the docs, so only light mode needs the fix today.

### WR-02: Built-docs output directory name is not unique across concurrent OS processes

**File:** `test/release/package_metadata_test.exs:177-178`
**Issue:** `out = Path.join(System.tmp_dir!(), "scrypath-docs-#{System.unique_integer([:positive])}")`. `System.unique_integer/1` is unique only inside one VM, and a deterministic `mix test` start-up yields near-identical values in separate OS processes (three plain `elixir -e` runs printed 2643, 2626 and 2629). Two overlapping runs on one machine (for example `mix verify.package` and `mix test` in two terminals, or a self-hosted runner) can pick the same directory. One run's `on_exit(File.rm_rf!(out))` then deletes the other's build mid-assertion, or ExDoc writes into a half-populated directory. The failure would show up as a spurious "no ExDoc-generated page" or `File.read!` error in an unrelated test. The sibling contrast test in the same repo already avoids this by adding `System.pid()` (`test/mix/tasks/ui_contrast_contract_test.exs:16-19`), and this file is also the release-publish gate (`mix verify.package` runs in `release-please.yml` and `publish-hex.yml`), so flakiness here blocks releases.
**Fix:**
```elixir
out =
  Path.join(
    System.tmp_dir!(),
    "scrypath-docs-#{System.pid()}-#{System.unique_integer([:positive])}"
  )
```
or create the directory with an exclusive `File.mkdir!/1` after adding random bytes to the name.

## Info

### IN-01: Release guide documents only one direction of the README header theme mismatch

**File:** `docs/releasing.md:28`
**Issue:** The guide says "A dark operating system with ExDoc set to light shows the dark header on a light page." The mirror case is equally invisible: a light operating system with ExDoc set to dark shows the `#1E1220` typemark on ExDoc's dark navy page (about 1.1:1). Because ExDoc's default is "system", both cases need an explicit override and are uncommon, but the guide reads as if only one direction exists. The mechanism already proven for the sidebar logo (`content:url()` on an `<img>`, working in Chromium and Firefox) could close both directions with two docs-owned rules keyed on `body.dark` / `body:not(.dark)` and the header `img`, instead of leaving it a "known residual".
**Fix:** Name both directions in the guide. Optionally add rules such as `body.dark .content-inner picture img{content:url("../brand/assets/readme/scrypath-header-dark.svg")}` and the light equivalent for `body:not(.dark)`, with the same kind of rule assertion the logo rule has.

### IN-02: Guide says a published README "and its docs" cannot be corrected

**File:** `docs/releasing.md:23`
**Issue:** The README inside the Hex tarball is immutable once the replace window closes, but HexDocs for a version can be republished (`mix hex.publish docs`). I believe this is how Hex behaves, but I could not confirm it offline, so please verify before changing the text. If correct, the sentence overstates the risk for the docs half and could mislead a future release decision about when the commit-pinned URL switch is needed.
**Fix:** Reword to "A published README (inside the tarball) cannot be corrected after a release", or confirm Hex's docs-republish behavior and keep the current wording.

### IN-03: The `assets:` mirrors publish more than the docs reference

**File:** `mix.exs:210-214`
**Issue:** ExDoc mirrors whole directories, so the build and the EPUB also ship the pinned `header-snippet.html` (a page whose relative image paths are deliberately unresolvable; the test `unresolved == [@snippet]` pins this at line 297), all eight `brand/assets/logo/*.svg` variants (only `scrypath-symbol-dark.svg` is referenced), and everything later added to `dev/docs/` (merged into ExDoc's own `assets/` directory beside `logo.svg` and `favicon.svg`). Sizes are trivial (about 70 KB), so this is hygiene, not breakage. The coupling in `unresolved == [@snippet]` is more of a nuisance: a brand pin update that edits the snippet fails `verify.package`, which gates publishing, and the release guide's "after a brand pin update" paragraph only mentions the stylesheet.
**Fix:** Note the snippet in the "after a brand pin update" step of `docs/releasing.md`, or relax that assertion to "only pages under `brand/` may have unresolved references". Keep the narrow mirror list as is; ExDoc cannot mirror single files.

### IN-04: EPUB references the README header images but does not declare them in its manifest

**File:** `mix.exs:210-214`, built `OEBPS/content.opf`
**Issue:** In the built EPUB, `readme.xhtml` references `brand/assets/readme/scrypath-header-*.svg` and those files are copied into the archive, but `content.opf` declares only `assets/logo.svg`. Strict EPUB validators flag undeclared referenced resources, and some readers drop such images. This predates the phase in kind (the old `brandbook/...` header was not in the EPUB at all), and the new test scans the EPUB for the retired directory but not for image resolution. It also copies `assets/scrypath-exdoc.css` into the archive although `before_closing_head_tag(:epub)` correctly returns "" so nothing links it.
**Fix:** Accept and note it, or add an EPUB resolution check (read `content.opf`, assert every `src` in the xhtml is declared). Do not rely on `assets:` to fix this; ExDoc does not add custom assets to the manifest.

### IN-05: The contract builds the `:test` docs, which differ from the published `:dev` docs

**File:** `test/release/package_metadata_test.exs:176-185, 307`
**Issue:** The `:test` build has 106 content pages including every `Mix.Tasks.Verify.*` and `Mix.Tasks.Brand.Update` page; the published `:dev` build has 78 (the `mix.exs` comment above `extras:` already explains why). The checks here are environment independent for assets, CSS and the README, so nothing is wrong today, but the retired-directory scan also covers unpublished verifier moduledocs (a moduledoc in a verify task that names the retired directory would fail a check about HexDocs content that never ships it), and `length(content) >= 50` is calibrated to the `:test` count. I confirmed the `:dev` build separately is clean with `--warnings-as-errors`.
**Fix:** Leave as is, but record in the module comment that the build is `:test` and that this module does not exercise the `:dev` publish build (the dev build was checked separately during this review).

### IN-06: `committed?/1` checks the git index, not a commit

**File:** `test/release/package_metadata_test.exs:228, 608-613`
**Issue:** `git ls-files --error-unmatch` succeeds for a file that is staged but never committed, and says nothing about uncommitted edits to a tracked file. The test name and message say "committed". Because the publish job checks out a tag and runs `mix verify.workspace_clean` first, the practical gap is small.
**Fix:** Use `git cat-file -e HEAD:<path>` for "committed", or rename the assertion to "tracked".

### IN-07: README image guard only inspects HTML attributes

**File:** `test/release/package_metadata_test.exs:216-234`
**Issue:** The test name promises "no README image points at the Pages site", but it only scans `src`/`srcset` attributes (`html_attribute_values/2`). A Markdown image (`![x](https://sztheory.github.io/scrypath/...)`) or a custom Pages domain would pass. The README has no Markdown images today (only the four badges at line 8, on external hosts), so this is a latent gap, not a live defect.
**Fix:** Also scan `!\[[^\]]*\]\(([^)\s]+)` matches against `github.io` (and apply the same `local_refs` resolution to Markdown image targets).

### IN-08: Code blocks without a `makeup` class keep ExDoc's background next to brand-colored blocks

**File:** `dev/docs/scrypath-exdoc.css:12`
**Issue:** The background rule is `pre code.makeup`. Blocks fenced as `text` (3), `yaml`, `heex` and `hcl` render as `<code class="text">` etc. without `makeup`, so on three pages they keep ExDoc's near-white or navy block next to the `#F0E9E6` / `#110A14` blocks. This is a small visual inconsistency, consistent with the documented "keeps ExDoc's own colors" posture, but the background half of that is not mentioned.
**Fix:** Either extend the background rule to `pre code` (and re-derive from a pin update that does the same), or add the background case to the release guide's residual list.

### IN-09: Published stylesheet carries internal maintainer prose; favicon is light-only

**File:** `dev/docs/scrypath-exdoc.css:1-9`, `mix.exs:199-202`
**Issue:** The file is copied verbatim to `hexdocs.pm/scrypath/<version>/assets/scrypath-exdoc.css` (the build test requires byte equality), so the header comment, including `test/release/package_metadata_test.exs` and "After a brand pin update, re-derive it", is public. It is harmless but is maintainer workflow text in an adopter-facing asset. Separately, `favicon-light.svg` is `#1E1220` on transparent, so it is close to invisible on a dark browser tab strip; the guide explains why `favicon.svg` was avoided but not this trade-off, and the brand set has `favicon-dark.svg`. Also, `logo:` and `favicon:` raise (`File.copy!`, `deps/ex_doc/lib/ex_doc/formatter.ex:copy_image/3`) when `brand/` is absent, so `mix docs` from an unpacked Hex tarball would now fail with ENOENT; the `mix.exs` comment says only that a missing `assets:` source is skipped, which is true of `assets:` alone.
**Fix:** Move the maintainer instructions out of the shipped file (keep a one-line description; the test already pins the file), mention the light-favicon trade-off in the guide, and make the `mix.exs` comment explicit that `logo:`/`favicon:` require `brand/` (only `assets:` degrades gracefully).

---

_Reviewed: 2026-11-20T02:22:46Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
