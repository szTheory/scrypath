---
phase: 188-readme-header-and-hexdocs
plan: 02
subsystem: docs
tags: [brand, retired-directory, deny-list, release-guide, playbook]
status: complete

requires:
  - phase: 188-readme-header-and-hexdocs
    provides: Plan 01 built-docs contract, README header, docs-owned stylesheet, ceilings 9 and 236
provides:
  - PRODUCT.md brand paragraph pointing at the pinned brand/ book
  - prompts/scrypath-brand-book.md deleted, both allowlist entries removed, ceilings 7 entries and 201 hits
  - docs/releasing.md subsection on README header and HexDocs brand mechanics, with an anchor test
  - playbook T19 and V1.46-PREP send-back items 12 to 14
  - every Phase 188 gate green on one final code commit
affects: [189-website, v1.47 cleanup of the retired directory, release of the next Hex version]

actuals:
  tokens: 7200
  tasks: 2
  commits: 3
plan_head_before: 638f3176a2201fddf15b0c5e84bcbddf412fc37c
plan_head_after: 54fe57ea63ae7e011ab204b37ea7207dbb1109f1

tech-stack:
  added: []
  patterns:
    - "anchor test over a published maintainer doc, with no planning labels in the doc"

key-files:
  created: []
  modified:
    - PRODUCT.md
    - docs/releasing.md
    - test/release/package_metadata_test.exs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md
    - .planning/research/brand-and-catalog/V1.46-PREP.md
  deleted:
    - prompts/scrypath-brand-book.md

key-decisions:
  - "Delete the superseded brand prompt rather than keep an allowlist entry for it; git history keeps it"
  - "Playbook row T19 stays draft: the stylesheet half is proven by build output and rule assertions, not by a rendered browser probe in CI"

requirements-completed: [BDOC-01, BDOC-02]

duration: about 50 min, of which about 12 min were the two fetch-dependent gates
completed: 2026-11-19
---

# Phase 188 Plan 02: Retired-directory exit, release-guide mechanics and phase gates Summary

No README, PRODUCT.md or docs-extra file names the retired brand directory any more, the superseded brand prompt is gone, the release guide explains how the README header and HexDocs brand assets work, and all Phase 188 gates are green on one final code commit.

## Accomplishments

- **Task 1 (tracer), `6b7eee2d`.** PRODUCT.md "Brand Commitments" now says the brand book (version 1.0, November 2026) and its assets are pinned under `brand/`, that `brand/BRAND.md` is the full text, that `mix verify.brand` checks the files against `brand/brand.pin.json`, that the maintainer adopted it in November 2026, and that product facts and explicit maintainer guidance win over the book. The no-invented-claims sentence is kept. `prompts/scrypath-brand-book.md` (905 lines) is deleted. The PRODUCT.md and prompts allowlist entries are removed and the ceilings are exactly 7 entries and 201 hits (the token test accepted both as written; the prefix entry for the retired directory is untouched). The repo-level retired-name test now covers README.md, PRODUCT.md and every docs extra.
- **Task 2, `e3341197` and `54fe57ea`.** `docs/releasing.md` gained "### README header and HexDocs brand assets" (prose and bullets, no code fence, no planning labels): relative paths mirrored by `assets:`, never the Pages site, commit-pinned `raw.githubusercontent.com` URLs as the fallback if hex.pm starts rendering the README, the `<picture>` OS-versus-toggle residual, the logo and favicon choices, how `dev/docs/scrypath-exdoc.css` is re-derived after a brand pin update, and that the built-docs checks run in `core` and `mix verify.package`. An anchor test pins the heading, `brand/assets/readme`, `raw.githubusercontent.com`, both stylesheet paths and the absence of the retired directory name. The playbook row T19 and its change log, and the V1.46-PREP send-back items 12 to 14, record what the phase proved.

## Gates on `GATE_SHA` = `54fe57ea63ae7e011ab204b37ea7207dbb1109f1`

`GATE_SHA` is the last commit touching non-`.planning/` files. The working tree was clean when each gate ran, and every gate ran once on this commit.

| Command | Result | Wall time |
| --- | --- | --- |
| `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail (ceilings 7 and 201) | about 1 s |
| `MIX_ENV=test mix test test/release/package_metadata_test.exs` | 23 tests, 0 failures | 0.8 s |
| `mix docs --warnings-as-errors` | exit 0; `doc/brand/assets/readme/scrypath-header-light.svg` present | about 2 s |
| `MIX_ENV=test mix test --include docs_contract` on docs_contract, phase108, phase111, phase112 | 85 tests, 0 failures | 1.1 s |
| `mix verify.brand` | ok (44 assets, 326773 bytes) | 0.5 s |
| `mix verify.package` | exit 0 (includes the built-docs module, the docs build and `hex.build --unpack`) | 58 s |
| `mix verify.core --exclude integration --exclude docs_contract` | exit 0; "5 properties, 1175 tests, 0 failures (103 excluded)" and "Standard Maturity Gate: PASSED" | 424 s |
| `mix verify.repository_contracts` | exit 0; 157 tests, 0 failures in the last stage | 282 s |

`mix verify.core` and `mix verify.repository_contracts` ran with the escalated-permission route AGENTS.md authorizes, on the first invocation, and were not denied. The `scrypath-0.3.18/` directory that `hex.build --unpack` left at the repository root was removed (it is gitignored); `git status --short` is empty.

Acceptance checks (all as the plan expects): `brand/` is unchanged (`git diff 140c25da..GATE_SHA -- brand .planning/config.json .planning/state.json` is empty); `package.files` is unchanged; `git grep 'brandbook/'` over README, PRODUCT.md, guides, docs and the top-level docs returns nothing; the allowlist has 7 entries and a `max_hits` sum of 201; the playbook mentions Phase 188 in two places and the send-back list has item 12.

Only `.planning/` paths follow `GATE_SHA`: `git diff --name-only 54fe57ea..HEAD` lists only this SUMMARY.

## Deviations from Plan

None in this plan's own tasks: it ran as written. The deviations that belong to the phase (the `docs_config.js` exemption and the `.build.epub` manifest, both in Plan 01's test) are recorded in `188-01-SUMMARY.md`.

Notes:
- Commit order differs slightly from the plan's task order to keep the gates clean: the `.planning/` playbook and send-back commit (`e3341197`) came before the final code commit (`54fe57ea`), so `GATE_SHA` is the tip and the working tree was clean for the snapshot-based gate.
- `brandbook/notes/pressure-test.md` still names the deleted prompt. It sits inside the retired directory, which the first v1.47 cleanup deletes, so it was left alone.
- The two fetch-dependent gates and `verify.package` ran once each. No gate was rerun and no gate was blocked.

## Known Stubs

None.

## Threat Flags

None. `docs/releasing.md` names only public repository paths and the public raw-content host.

## What is proven and what is not

Proven, by named tests on `GATE_SHA`:
- SC1 and SC2 (BDOC-01): header paths and every local reference resolve in a real docs build; no retired directory name in any built text file or epub entry (`Scrypath.Release.BuiltDocsBrandTest` in `test/release/package_metadata_test.exs`, run in `core` and `mix verify.package`).
- SC3 (BDOC-02): head order, favicon, logo, stylesheet byte equality, stylesheet derivation from the pin, code colors bound to the brand tokens, selector specificity over ExDoc's rules (same module).
- SC4 (BDOC-01): README.md, PRODUCT.md and every docs extra are free of the retired name (same module); the prompts and PRODUCT.md entries are gone and the shrink-only token test passes at 7 and 201.
- The release guide carries the documented mechanics and fallback (anchor test).

Not proven:
- Rendered pixels: no browser probe of the shipped docs or the README ran; code colors are proven by rule assertions, not computed styles.
- The `<picture>` residual: a dark OS with ExDoc set to light shows the dark header on a light page. It is documented, not fixed.
- Token classes outside the book's list keep ExDoc's own colors.
- The mirrored `brand/assets/readme/header-snippet.html`: its own local references do not resolve in the build (it is a pinned file, not a docs page). Plan 01's test pins it as the only such file.
- Whether hex.pm will ever render the README header: the fallback is documented, not exercised.

No PR was opened. The next step is the orchestrator's rebase onto main and PR, after Phase 187's PR #138 lands (ROADMAP: no stacked PRs). Commit hashes in these summaries are branch hashes and will change on rebase.

## Self-Check: PASSED

- `PRODUCT.md`, `docs/releasing.md`, `test/release/package_metadata_test.exs`, both allowlist files, the playbook and `V1.46-PREP.md` exist and are committed; `prompts/scrypath-brand-book.md` is absent.
- Commits `6b7eee2d`, `e3341197` and `54fe57ea` are ancestors of HEAD.
