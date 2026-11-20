---
phase: 188-readme-header-and-hexdocs
verified: 2026-11-19T21:20:00Z
status: passed
score: 12/12 must-haves verified
covered_files:
  - ".planning/phases/188-readme-header-and-hexdocs/188-01-PLAN.md"
  - ".planning/phases/188-readme-header-and-hexdocs/188-01-SUMMARY.md"
  - ".planning/phases/188-readme-header-and-hexdocs/188-02-PLAN.md"
  - ".planning/phases/188-readme-header-and-hexdocs/188-02-SUMMARY.md"
  - "PRODUCT.md"
  - "README.md"
  - "dev/docs/scrypath-exdoc.css"
  - "docs/releasing.md"
  - "examples/scrypath_ecommerce/retired-identity-allowlist.json"
  - "examples/scrypath_ecommerce/ui-tokens.test.mjs"
  - "mix.exs"
  - "test/release/package_metadata_test.exs"
covered_digest: "v4:sha256:9762fe38196352baca9eb6dd305c828044f894a112d95c970b723fe4f8ed10b7"
behavior_unverified: 0
overrides_applied: 0
human_verification: []
---

# Phase 188: README header and HexDocs Verification Report

**Phase Goal:** A reader sees the new brand header, logo and favicon in the README on GitHub and on HexDocs, with code blocks in brand colors that follow ExDoc's own theme toggle (BDOC-01, BDOC-02).
**Verified:** 2026-11-19, on branch `feat/v1.46-188-readme-hexdocs` at `4266b726` (last code commit `54fe57ea`; every later commit touches only `.planning/`).
**Status:** passed
**Re-verification:** No, initial verification.

Starting hypothesis was "tasks complete, goal missed". It did not survive: every claim below was re-derived from the tree, a fresh docs build into a scratch directory outside the repo, my own scans (not the project's test code), and a real Chromium computed-style probe. Where the SUMMARYs and the code disagreed, the code is quoted. One SUMMARY-adjacent inaccuracy (a code comment, not behavior) is listed under Anti-Patterns.

## Goal Achievement

### Observable Truths

Roadmap success criteria (the contract) first, then the plan-only must-haves that add detail.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 (BDOC-01): one real `mix docs` build yields a `readme.html` whose header uses `brand/assets/readme/...` paths, and every `src`/`srcset` in the built docs resolves | VERIFIED (two named exemptions) | My fresh build (`mix docs --warnings-as-errors --output <scratch>`, exit 0, 1.0 s): `readme.html` lines 118-119 carry `srcset="brand/assets/readme/scrypath-header-dark.svg"` and `src="brand/assets/readme/scrypath-header-light.svg"`, both files present under `doc/brand/assets/readme/`. My own scan of all HTML (317 local refs): the only unresolved refs are `docs_config.js` on ExDoc pages and the mirrored `header-snippet.html`'s own refs. `docs_config.js` is ExDoc's optional host-supplied version-dropdown file, emitted unconditionally by `head_template.eex:24` and documented as optional in `deps/ex_doc/lib/ex_doc.ex:486`; the snippet is a pinned file, not a docs page. Both are named and pinned in the test (see Anti-Patterns for a comment inaccuracy) |
| 2 | SC1 (BDOC-01): the same relative paths resolve to committed files for the GitHub README; no README image points at the Pages site | VERIFIED | `README.md` lines 1-6 use the same two paths. Test uses `git ls-files --error-unmatch` plus `File.regular?` per ref and refutes `github.io` in every `src`/`srcset`. Mutation M8 (path to a missing file) turned 3 tests red |
| 3 | SC2 (BDOC-01): the built docs contain no `brandbook/` reference | VERIFIED | My scan of every file in the build, including every entry of `scrypath.epub`, `llms.txt` and markdown: 0 hits. Mutation M4 (README names it) turned 2 tests red |
| 4 | SC3 (BDOC-02): the head links the brand stylesheet after ExDoc's, the brand favicon and the brand logo from `assets/` | VERIFIED | My scan of all 78 ExDoc content pages: icon link, then `dist/html-elixir-*.css`, then `assets/scrypath-exdoc.css`, with 0 order violations. The one generator page without ExDoc CSS is the `index.html` meta-refresh redirect, and the test pins the exclusion to refresh pages. `cmp` confirms `assets/favicon.svg` = `brand/assets/icon/favicon-light.svg`, `assets/logo.svg` = `brand/assets/logo/scrypath-symbol-light.svg`, `assets/scrypath-exdoc.css` = `dev/docs/scrypath-exdoc.css`. Mutations M6 (hook removed) and M7 (colorless favicon) turned tests red |
| 5 | SC3 (BDOC-02): the stylesheet prefixes every color rule with `body ` and `body.dark `, has no `prefers-color-scheme` block, and the contract test asserts the code-block colors | VERIFIED | Read `dev/docs/scrypath-exdoc.css` in full: no `@media`, every painting rule lists `body S` and `body.dark S`. Test asserts custom properties equal `brand/tokens.json` `color.code.*` per theme, class-to-property mapping, derivation-equality with the pinned file plus one logo rule, and computed specificity over ExDoc's `.makeup .X`, `.dark .makeup .X`, `.dark .makeup` and `.content-inner code`. Mutations M1 (unprefixed `.makeup .kd`), M2 (media block), M3 (color off by one hex digit), M9 (drop `body.dark pre code.makeup`) each turned 2-3 tests red; baseline green in the same scratch copy |
| 6 | SC4 (BDOC-01): no documentation or README reference to `brandbook/` remains, the `prompts/scrypath-brand-book.md` entry is gone from the allowlist, and the shrink-only deny-list test still passes | VERIFIED | `git grep brandbook` over README, PRODUCT.md, docs, guides, CONTRIBUTING, ARCHITECTURE, SECURITY, CHANGELOG, mix.exs: empty. Repo-wide, remaining hits are only `ci.yml`, `ui_tokens.ex`, the allowlist, and two test files, all the `retire-last` set the roadmap defers. `prompts/scrypath-brand-book.md` is absent from `git ls-files`. Allowlist: 7 entries, 201 `max_hits`, matching ceilings 7 and 201 (`ui-tokens.test.mjs:68,72`). Token test (TAP): 59 pass, 0 fail. Scratch mutations: re-adding the retired directory name to PRODUCT.md, and a retired hex (`#c17a3e`) to README, each fail "live deny-list scan finds no unlisted retired value" now that those entries are gone |
| 7 | Goal clause: code blocks in brand colors follow ExDoc's own theme toggle (not the OS) | VERIFIED | Mechanism: ExDoc's inline head script adds `dark` to `document.body` from its own `theme` setting (`system`/`dark`/`light`), and the stylesheet keys on `body.dark`. My independent specificity scan of ExDoc's built CSS (148 paint rules touching code/makeup, none `!important`) found no rule that ties or outranks a brand selector on the same target (the single apparent hit, `.content-inner pre code.output:before`, styles a generated "Output" label, not the code). Behavior: a real Chromium probe (scratch, advisory, not committed) loaded `getting-started.html` with `?theme=` against all four ExDoc-toggle by OS-scheme combinations, including the two mismatches the book's original stylesheet got wrong. In every case the code background, text, keyword and string colors computed to the exact brand-token values for the ExDoc theme, independent of the OS scheme |
| 8 | Plan 01: pinned `brand/` byte-identical, `package.files` unchanged, no `brand*` or `dev` entry in the Hex package | VERIFIED | `git diff 140c25da -- brand/` is empty (0 files, `git diff --name-only 140c25da..HEAD -- brand brandbook` = 0). `mix verify.brand`: ok (44 assets, 326773 bytes). `git diff -U0 140c25da..HEAD -- mix.exs` has exactly two hunks (`docs/0`, and the private hook below it); `package/0` untouched. My re-run of `mix verify.package` unpacked the tarball: no `brand*`, `dev` or `doc` entry |
| 9 | Plan 02: README and PRODUCT.md entries removed, prompts file deleted, `brandbook/` directory, its `prefix` entry, `ci.yml`, `ui_tokens.ex` and `ui_tokens_contract_test.exs` untouched | VERIFIED | Allowlist diff removes exactly the README, PRODUCT.md and prompts entries; the prefix entry (`max_hits` 177) and the other retire-last entries are byte-identical. `brandbook/` is still present (the roadmap defers its deletion to the first v1.47 cleanup). `ui_tokens_contract_test.exs` still passes in my 237-test spot run |
| 10 | Plan 02: `docs/releasing.md` records the mechanics, fallback and residuals, with no planning labels | VERIFIED | Subsection "### README header and HexDocs brand assets" present with relative paths, no Pages site, commit-pinned `raw.githubusercontent.com` fallback, the `<picture>` OS-versus-toggle residual, logo/favicon choices and the re-derivation step. Added lines contain no requirement, decision, threat, UI-spec, phase or plan labels (grep exit 1). Mutation M10 (anchor removed) red. docs_contract family: 85 tests, 0 failures |
| 11 | Plan 02: playbook T19 and V1.46-PREP send-back list record the findings | VERIFIED | `BRAND-ADOPTION-PLAYBOOK.md` mentions Phase 188 in the T19 row (line 72) and change log (line 186); `V1.46-PREP.md` lines 169-171 are items 12-14 |
| 12 | Gate ledger still 8 of 12; no new required gate | VERIFIED | `CONTRIBUTING.md` and `.github/` are unchanged since the planning base; "Budget used: 8 of 12", 8 table rows. The built-docs contract is a second module in the existing `test/release/package_metadata_test.exs` (no new file, no new lane) |

**Score:** 12/12 truths verified (0 present-but-behavior-unverified).

### Deferred Items

None are gaps. The roadmap's own deferrals are out of scope by design: deleting the `brandbook/` directory, `mix verify.ui_tokens`, `ui_tokens_contract_test.exs`, the ops DTCG mirror and the demo favicon (first v1.47 cleanup phase; "Deferred to v1.47" in ROADMAP.md).

### Advisory (New Scope, Unevidenced)

Not applicable: initial verification. None.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `README.md` | brand header `<picture>` with relative `brand/assets/readme/...` paths | VERIFIED | lines 1-6; both files committed |
| `mix.exs` | `logo`, `favicon`, three `assets:` mirrors, private `before_closing_head_tag/1` | VERIFIED | lines 199-214 and 298-303; hook private (`function_exported?` refuted in test); strings only, so a Hex consumer evaluating `docs/0` never reads `brand/` |
| `dev/docs/scrypath-exdoc.css` | pin-derived, prefixed, media-free, plus one logo rule | VERIFIED | 20 lines; equals its derivation from the pin (test) and is mirrored byte-equal into `doc/assets/` |
| `test/release/package_metadata_test.exs` | built-docs contract module, one real build in `setup_all` | VERIFIED | `Scrypath.Release.BuiltDocsBrandTest`, 17 tests; 23 tests total in the file, 0 failures; build goes to `System.tmp_dir!()` (no `<repo>/tmp` residue: `git status` shows none) |
| `examples/scrypath_ecommerce/retired-identity-allowlist.json` and `ui-tokens.test.mjs` | 7 entries / 201 hits with matching exact ceilings | VERIFIED | confirmed by `node` count and the TAP run |
| `PRODUCT.md`, `docs/releasing.md` | rewritten brand paragraph, new subsection | VERIFIED | diffs read; "Do not invent customer, adoption, or performance claims." retained |
| `prompts/scrypath-brand-book.md` | deleted | VERIFIED | absent from the index and the tree |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `README.md` | built `doc/` | `assets: %{"brand/assets/readme" => "brand/assets/readme"}` | WIRED | header paths resolve in my build; M5 (mirror removed) turns 2 tests red |
| `mix.exs` | `dev/docs/scrypath-exdoc.css` | `"dev/docs" => "assets"` plus `before_closing_head_tag(:html)` | WIRED | linked after ExDoc's CSS on all 78 content pages; `:epub` returns `""` |
| dark-logo rule | `brand/assets/logo/scrypath-symbol-dark.svg` | `content:url("../brand/assets/logo/scrypath-symbol-dark.svg")` | WIRED | resolves from `assets/` to the mirrored file; computed `content` shows the url under `body.dark`, and the rendered sidebar crop shows the pale-ink and orchid symbol on the dark header |
| test module | pinned CSS and `brand/tokens.json` | derivation and token binding | WIRED | M2, M3, M9 red |
| allowlist | `ui-tokens.test.mjs` ceilings | exact `ALLOWLIST_CEILING` 7, `HITS_CEILING` 201 | WIRED | token test green; planted hits red |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| code-block colors | `--scrypath-doc-*` custom properties | `:root` / `body.dark` in the stylesheet, equal to `brand/tokens.json` `color.code.*` | Yes: computed colors in Chromium equal the token values | FLOWING |
| sidebar logo | `img` `content` | `url()` to a mirrored pinned SVG | Yes: renders the dark symbol under ExDoc dark | FLOWING |
| README header | `<picture>` sources | committed brand SVGs, no `<text>` element (no font dependency) | Yes: `naturalWidth` 520 in both OS schemes, with the dark source chosen under OS dark | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| docs build is warning-free in the published env | `mix docs --warnings-as-errors --output <scratch>` | exit 0, 1.0 s | PASS |
| built-docs contract | `MIX_ENV=test mix test test/release/package_metadata_test.exs` | 23 tests, 0 failures | PASS |
| token deny-list | `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail | PASS |
| brand pin | `mix verify.brand` | ok (44 assets, 326773 bytes) | PASS |
| docs contract family | `MIX_ENV=test mix test --include docs_contract` on docs_contract, phase108, phase111, phase112 | 85 tests, 0 failures | PASS |
| neighbouring core contracts | `MIX_ENV=test mix test` on workflow_wiring, brand_pin_contract, ui_tokens_contract, `test/release` | 237 tests, 0 failures | PASS |
| package gate | `mix verify.package` | all stages ran through the `hex.build --unpack`; the log shows "127 tests, 0 failures" and no failure lines. The exit code was not captured because I launched it in a timed background subshell; aliased stages stop at the first failure and the last stage completed | PASS (log-backed) |
| code colors follow the ExDoc toggle | Chromium via Playwright (scratch script, not committed) | 4 of 4 theme-by-OS combinations match the brand tokens | PASS |
| mutation spot checks | 11 mutations on a scratch copy outside the repo (baseline green first) | every mutation turned the intended test red; tree restored | PASS |

### Probe Execution

No phase probe scripts (`scripts/*/tests/probe-*.sh`) declared or present for this phase. Not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| BDOC-01 | 188-01, 188-02 | Brand header in the README on GitHub and HexDocs via relative `brand/assets/readme/...` paths mirrored through `assets:`; no `brandbook/` reference left in the built docs | SATISFIED | Truths 1, 2, 3, 6, 9 |
| BDOC-02 | 188-01, 188-02 | HexDocs uses the brand logo, favicon and corrected stylesheet (prefixed, media block removed), proved by one real build asserting head links, resolving refs and code-block colors | SATISFIED | Truths 1, 4, 5, 7 |

No orphaned requirements: REQUIREMENTS.md maps only BDOC-01 and BDOC-02 to Phase 188 (lines 130-131), both claimed by both plans.

### Decision Coverage

`check.decision-coverage-verify` skipped ("no trackable decisions": CONTEXT.md has no D-numbered entries). Checked by hand against the CONTEXT decisions: relative paths plus `assets:` mirror, pinned logo and favicon, a NEW docs-owned stylesheet loaded after ExDoc's CSS with the pinned original untouched, the contract test in an existing root file, allowlist entries removed with ceilings lowered, `brandbook/` not deleted, `package.files` unchanged, no PR opened. All honored.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `test/release/package_metadata_test.exs` | 168-172 | The `@host_supplied_ref` comment says "the test asserts that the unresolved references equal exactly this name". The test only skips that name (`unexpected == []`); it does not assert the unresolved set equals it. | Warning (comment overstates, behavior is sound; the exemption is exact-string and narrow) | None on the goal. If `docs_config.js` ever started resolving, nothing would flag the stale exemption |
| `mix.exs` | 199-214 | `brand/assets/logo` is mirrored whole, so all 8 logo and lockup SVGs (about 28 KB) ship to HexDocs and the epub, though only the dark symbol is used | Info | Small published-size cost; could mirror one file |
| `doc/brand/assets/readme/header-snippet.html` (built) | n/a | The mirrored pinned snippet is a stray published page whose own refs do not resolve | Info | Unlinked; pinned by test as the only such page |

Debt-marker scan (`TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`) on the added lines of every non-`.planning` file: none. No stubs, empty implementations or hollow props in the changed code.

### Human Verification Required

None. Per the project rule, nothing here is impossible to automate. How the header and logo look is subjective and is not a gate. The one remaining unautomated check is a rendered-browser assertion of code colors, which the phase deliberately left advisory; I ran it myself (above) and it passes, but it is not a committed or CI-enforced test (see Not proven).

### Not Proven (stated plainly)

- **Rendered pixels in CI.** The repo's own proof of code colors is rule-level (custom properties bound to `brand/tokens.json`, class mapping, computed specificity), run in `core`. My Chromium computed-style probe confirms the rules produce the expected colors, but it lives in my scratchpad, is not committed, and nothing in CI runs a browser against the built docs. A future ExDoc change that alters the cascade in a way the specificity model does not capture would not be caught by the committed test until someone re-probes.
- **Visual quality.** Only the logo swap crops and a `naturalWidth` check on the header were inspected; no aesthetic or independent-review claim is made. The header SVGs have no `<text>` element, so no font dependency, but GitHub's own rendering of the README was not observed.
- **`<picture>` OS-versus-toggle residual.** Confirmed concretely (OS dark with ExDoc light loads the dark header on the light page). It is documented in `docs/releasing.md`, not fixed, as the roadmap and CONTEXT direct.
- **Token classes outside the book's list** (operators, punctuation, names and others) keep ExDoc's own colors; the ExDoc chrome (for example the active-tab underline) is also ExDoc's palette, not the brand's. Recorded on the send-back list.
- **hex.pm rendering.** The release guide asserts hex.pm does not render the README today; I did not check this. Packaged `README.md` references `brand/assets/readme/...`, which is not in the Hex package, so if hex.pm renders it the header would be broken there. The goal names GitHub and HexDocs only, and the guide documents the commit-pinned `raw.githubusercontent.com` fallback to apply before the next release.
- **Hosted CI.** Nothing is pushed (no upstream configured). No GitHub Actions run, no exact-SHA hosted evidence yet. **Pending orchestrator, not a gap:** rebase onto main after Phase 187's PR #138 merges, open the PR, and collect the hosted run.
- **SUMMARY-backed only (not re-run by me):** `mix verify.core --exclude integration --exclude docs_contract` (summary: 1175 tests, 0 failures, "Standard Maturity Gate: PASSED", 424 s) and `mix verify.repository_contracts` (summary: exit 0, 157 tests in the last stage, 282 s), both on `54fe57ea`. I re-ran everything cheaper, plus `verify.package` and a 237-test subset of core (workflow wiring and ledger, brand pin, ui_tokens contract, all of `test/release`).

### Gaps Summary

No gaps. All four roadmap success criteria and the plan-level must-haves hold against the code, a fresh build, my own scans, a browser probe and 11 mutation checks. The two named exemptions to the literal "every `src`" wording (the optional host-supplied `docs_config.js`, and the mirrored pinned snippet's own refs) are legitimate, narrow, and pinned by tests; neither affects what a reader sees.

Bookkeeping for the orchestrator, not code gaps: ROADMAP.md still shows Phase 188 unchecked with "Plans: TBD" and its progress row "0/TBD", and REQUIREMENTS.md still lists BDOC-01 and BDOC-02 as Pending. Update on phase close. `.planning/STATE.md`, `config.json` and `state.json` show as modified and `188-SECURITY.md` appeared untracked in the phase directory during my run; I did not touch or read either set, and committing was left to the orchestrator.

---

_Verified: 2026-11-19_
_Verifier: Claude (gsd-verifier)_
