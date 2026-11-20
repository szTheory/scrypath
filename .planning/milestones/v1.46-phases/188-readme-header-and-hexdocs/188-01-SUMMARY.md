---
phase: 188-readme-header-and-hexdocs
plan: 01
subsystem: docs
tags: [exdoc, hexdocs, readme, brand, css, contract-test]
status: complete

requires:
  - phase: 186-ingest-pin-and-guard
    provides: pinned brand/ book, brand/tokens.json, the shrink-only retired-identity deny-list
provides:
  - README brand header through relative brand/assets/readme paths
  - HexDocs logo, favicon and a docs-owned code stylesheet loaded after ExDoc's CSS
  - Scrypath.Release.BuiltDocsBrandTest, a built-docs contract inside the root suite
  - README allowlist entry removed, ceilings 9 entries and 236 hits
affects: [188-02, 189-website, v1.47 cleanup]

actuals:
  tokens: 6600
  tasks: 3
  commits: 3
plan_head_before: 0382fcbb6884325abe202ca08d95dd0a9dee07d9
plan_head_after: 09143ec035a514b2fd29483e5b26bcc70e48ab49

tech-stack:
  added: []
  patterns:
    - "one real mix docs build per test module, written to System.tmp_dir!, never the ExUnit tmp_dir tag"
    - "docs-owned stylesheet derived from the pin and asserted equal to its re-derivation"

key-files:
  created:
    - dev/docs/scrypath-exdoc.css
  modified:
    - README.md
    - mix.exs
    - test/release/package_metadata_test.exs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs

key-decisions:
  - "docs_config.js is the one host-supplied local reference exempt from the resolution check (see Deviations)"
  - "logo is the light symbol; the dark symbol arrives through one body.dark content:url() rule"
  - "favicon is favicon-light.svg because the pinned favicon.svg has no fill"

requirements-completed: [BDOC-01, BDOC-02]

duration: about 45 min
completed: 2026-11-19
---

# Phase 188 Plan 01: README header and HexDocs brand Summary

README now shows the brand header from committed relative paths, and HexDocs shows the brand logo, favicon and a corrected code stylesheet, all proved by one real `mix docs` build inside the root ExUnit suite.

## Accomplishments

- **Task 1 (tracer), `5e335e64`.** README header `<picture>` uses `brand/assets/readme/scrypath-header-dark.svg` (srcset) and `...-light.svg` (src, alt `scrypath`, width 260). `mix.exs` mirrors `brand/assets/readme` through `assets:`. The new module `Scrypath.Release.BuiltDocsBrandTest` builds the docs once into `System.tmp_dir!()` and checks the header paths in `readme.html`, every local `src`/`srcset` on every ExDoc page, the README references (committed files, no github.io host), the retired directory name in every text file and epub entry, README and every docs extra, and that the only non-ExDoc html with an unresolved reference is the mirrored pinned snippet. The README allowlist entry is gone and the ceilings are 9 and 236.
- **Task 2, `6fb215b9`.** `mix.exs` gains `logo`, `favicon`, three asset mirrors and a private `before_closing_head_tag/1`. `dev/docs/scrypath-exdoc.css` is the pinned stylesheet without the OS-dark block, every color rule written for `body S` and `body.dark S`, plus one dark-logo rule. Tests check head order on every content page (at least 50, `readme.html` included), that the only generator-marked pages without ExDoc's CSS are the meta-refresh redirects, byte equality of the built favicon, logo and stylesheet with their sources, that every `url()` resolves to a pinned logo file, and that the head hook is private.
- **Task 3, `09143ec0`.** Rule-level contract: no `prefers-color-scheme` or `@media` in the raw file; every color or background rule has exactly `body S` and `body.dark S` per base selector; the parsed rules equal the derivation from the pin plus the one logo rule; `:root` and `body.dark` custom properties equal `brand/tokens.json` `color.code.*`; each token class maps as in the pin in both themes; each prefixed selector outranks ExDoc's competing rule by computed specificity, and the built ExDoc CSS must still contain the rules the fix targets.

Final code commit and `plan_head_after`: `09143ec035a514b2fd29483e5b26bcc70e48ab49`. Commits measured with `git rev-list --count 0382fcbb..HEAD` before this SUMMARY: 3.

## Cheap-command results (on `09143ec0`)

| Command | Result |
| --- | --- |
| `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail (ceilings 9 and 236 accepted as written; the test printed no different number) |
| `MIX_ENV=test mix test test/release/package_metadata_test.exs` | 22 tests, 0 failures (6 existing plus 16 new) |
| `mix docs --warnings-as-errors` | exit 0; `doc/brand/assets/readme/scrypath-header-light.svg` present; `doc/readme.html` links `assets/scrypath-exdoc.css` |
| `MIX_ENV=test mix test --include docs_contract` on docs_contract, phase108, phase111 and phase112 | 85 tests, 0 failures |
| `mix verify.brand` | ok (44 assets, 326773 bytes) |
| `mix format --check-formatted` | ok |
| `git diff 140c25da -- brand/ .planning/config.json .planning/state.json` | empty |

Measured docs-build time: about 0.6 s for the in-process `Mix.Tasks.Docs.run` with all formatters on a warm build; the whole new module runs in about 0.9 s.

## Mutation proof (run once, not committed)

1. Dropping `body.dark pre code.makeup` from `dev/docs/scrypath-exdoc.css` turned three tests red: "the docs-owned selectors outrank ExDoc's competing code rules", "the docs-owned rules equal the rules derived from the pinned file plus the dark-logo rule" and "every color or background rule is written once for body and once for body.dark".
2. Adding an unprefixed `.makeup .kd` selector turned the same three red.
3. Task 1 and Task 2 RED evidence: before the README and `mix.exs` edits, six of the new tests failed (header paths, readme refs, retired name in the build, refs resolution); removing `before_closing_head_tag:` from `docs/0` turned "the head hook links the stylesheet for html only and stays private" and "every content page links the favicon and the docs-owned stylesheet after ExDoc's CSS" red. The stylesheet was restored byte-identical (`cmp`) after both CSS mutations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in the plan's check] `docs_config.js` cannot resolve in a local build**
- **Found during:** Task 1, first test run.
- **Issue:** ExDoc's head template always emits `<script defer src="docs_config.js">`. The file is an optional host-supplied file (the version dropdown, per ExDoc's own documentation) that hexdocs.pm provides; a local build never contains it. The plan's "every local src resolves" assertion therefore failed on all 108 pages. 188-RESEARCH.md does not mention it.
- **Fix:** one named exemption, `@host_supplied_ref "docs_config.js"`, skipped only in the all-pages resolution test, with a comment naming the reason. Every other local reference must still resolve and the test still fails on a zero-pages or zero-refs result. No check elsewhere was loosened.
- **Files modified:** `test/release/package_metadata_test.exs`
- **Commit:** `5e335e64`

**2. [Rule 1 - Bug in the plan's check] `.build.epub` is not a zip**
- **Found during:** Task 1.
- **Issue:** ExDoc writes a plain-text `.build.epub` manifest next to `scrypath.epub`. Treating every `*.epub` as an archive made `:zip.extract` return `:bad_eocd`.
- **Fix:** only non-dot `*.epub` files are extracted as zips; `.build.epub` stays in the plain-text scan.
- **Commit:** `5e335e64`

**3. [Rule 1 - Bug in my first draft] light `pre code.makeup` was compared with the dark competitor**
- **Found during:** Task 3.
- **Issue:** `body pre code.makeup` (0,1,3) was asserted to outrank `.dark .makeup` (0,2,0), which it cannot and need not: that rule only applies under `.dark`. The plan states the requirement only for `body.dark pre code.makeup`.
- **Fix:** the dark selector is compared with `.dark .makeup`, the light selector with `.makeup`, both with `.content-inner code`. The stylesheet was not changed.
- **Commit:** `09143ec0`

### Other notes

- The test count is 6 new tests in Task 1 (one per behavior bullet), not 5; the plan's floor of 11 is met (22 total at the end).
- A tool outside my control rewrote `.planning/STATE.md` in this worktree at start (state head and timestamps). I reverted it with `git checkout -- .planning/STATE.md` and never staged it.
- Baselines `[HEAD=...]` re-derived on `0382fcbb`: all matched the plan (README 0 and 2 hits, ceilings 10 and 238, allowlist README entry 1).

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or file access beyond the planned `assets:` mirrors.

## What is proven and what is not

Proven by tests in `core`: header paths in the built `readme.html` and in README.md; every local reference on every ExDoc page resolves (except the one host-supplied name); no retired directory name in any text file or epub entry; head order, favicon, logo and stylesheet byte equality; the stylesheet equals its derivation from the pin plus one rule; code colors equal the brand tokens; selector specificity beats ExDoc's competing rules.

Not proven: rendered pixels (no browser probe was run, and executors have no `node_modules`); the `<picture>` residual (the OS theme chooses the header while ExDoc follows its own toggle, so a dark OS with ExDoc set to light shows the dark header on a light page); token classes outside the book's list (they keep ExDoc's colors); the mirrored `brand/assets/readme/header-snippet.html`, whose own local references do not resolve in the build (it is a pinned file, not a docs page, and the Task 1 test pins it as the only such file). The full gates (`mix verify.package`, `mix verify.core`, `mix verify.repository_contracts`) run in Plan 02 on the phase's final code commit.

## Self-Check: PASSED

- `dev/docs/scrypath-exdoc.css`, `README.md`, `mix.exs`, `test/release/package_metadata_test.exs` exist and are committed.
- Commits `5e335e64`, `6fb215b9` and `09143ec0` are ancestors of HEAD.
