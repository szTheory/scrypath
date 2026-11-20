# Phase 188: README header and HexDocs - Context

**Gathered:** 2026-11-20
**Status:** Ready for planning
**Mode:** Autonomous discuss. Decisions come from the milestone prep ([V1.46-PREP.md](../../research/brand-and-catalog/V1.46-PREP.md) D11, which already ran a real `mix docs` build and Chromium probes) and the ROADMAP Phase 188 section and scope note. The maintainer chose to follow the recommendations on 2026-11-19 (defer 189 and 190, run 188 now). Nothing here is a hard-to-reverse or preference question; no user question was needed.

<domain>
## Phase Boundary

A reader sees the new brand header, logo and favicon in the README on GitHub and on HexDocs, with code blocks in brand colors that follow ExDoc's own theme toggle. Requirements: BDOC-01, BDOC-02. Docs-only: no ScrypathOps UI change, no Hex release (a published README cannot be fixed afterwards, so everything is verified before any release; releasing stays a separate maintainer yes).

</domain>

<decisions>
## Implementation Decisions

- **README header paths:** use relative `brand/assets/readme/...` paths (light and dark `<picture>` sources from the pinned brand assets already committed by Phase 186) and mirror them into ExDoc with `assets: %{"brand/assets/readme" => "brand/assets/readme"}` in `mix.exs` docs config. Keep commit-pinned `raw.githubusercontent.com` URLs only as a documented fallback if hex.pm ever renders the README; never point README images at the Pages site (mutable). Remove every `brandbook/` reference from README.md, PRODUCT.md and the docs set. The `<picture>` follows the OS theme while ExDoc follows its own toggle: record that residual in the docs, do not fix it.
- **ExDoc logo and favicon:** ExDoc 0.40.4 `logo` and `favicon` accept PNG, JPEG or SVG only (no `.ico`), copied to `doc/assets/`; `logo` renders in a 48 by 48 area. Use the pinned brand symbol/favicon SVG; check the exact files under `brand/assets/` and their pin entries (`brand/brand.pin.json`; `mix verify.brand` must stay green; do not add unpinned files under `brand/`: if a file is needed that the pin lacks, run the pin update flow as Phase 186 documented, which requires the original zip at the scratchpad path recorded in `186-01-SUMMARY.md` if it still exists, otherwise copy an already-pinned file).
- **ExDoc stylesheet:** the brand book's ExDoc stylesheet (pinned under `brand/`) has two bugs: ExDoc's `.dark .makeup .kd` rules (specificity 0,3,0) beat the book's `.makeup .kd` (0,2,0), so code keeps Monokai colors on the brand Night background; and its `@media (prefers-color-scheme: dark)` block paints a dark code block on a light page when the OS is dark but ExDoc is light (ExDoc toggles `body.dark` from JS). Fix: delete the media block and prefix every color rule with `body ` and `body.dark `. The pinned file must stay byte-identical to the brand pin, so ship the fixed stylesheet as a NEW docs-owned file (for example `docs/assets/exdoc-brand.css` or the repo's existing docs assets location) generated or copied by a documented step, load it via ExDoc `before_closing_head_tag` AFTER ExDoc's own CSS, and keep the pinned original untouched. A previous session left a probed fixed copy at `/private/tmp/claude-501/-Users-jon-projects-scrypath/6a10a263-f1f2-442c-9d6b-b7ca7848ca6d/scratchpad/docbuild/brand/docs/scrypath-exdoc.css` (may be gone; if present compare it with a fresh derivation, do not trust it blindly).
- **Contract test (the phase's proof):** one real `mix docs` build asserting: the head links the brand stylesheet after ExDoc's CSS, the favicon and the logo from `doc/assets/`; every `src` and `srcset` in the built docs resolves to a file in the output; no `brandbook/` reference remains in the built output or README; the stylesheet has no `prefers-color-scheme` block and every color rule is prefixed `body ` or `body.dark `; code-block colors asserted by a computed-style probe if cheap (advisory), otherwise by stylesheet rule assertions. Put it in the existing root ExUnit suite (docs contract) so it runs in `core`; do not add a new required gate beyond what the CONTRIBUTING gate-budget parser allows (8 of 12 used; a new contract FILE in a required lane counts as one; prefer extending an existing docs contract test file, which counts as zero). Existing README/docs pinned-phrase contract tests (`test/scrypath/docs_contract_test.exs`, run with `--include docs_contract`, and `phase108`/`phase111` tests) must stay green.
- **Allowlist and guards:** remove the `README.md`, `PRODUCT.md` and `prompts/scrypath-brand-book.md` entries (or lower their `max_hits`) from `examples/scrypath_ecommerce/retired-identity-allowlist.json` as their retired values disappear, lowering the test-owned ceilings by the number the token test prints; handle `prompts/scrypath-brand-book.md` (the superseded brand prompt documenting the old directory) by deleting or rewriting it. `brandbook/` itself is NOT deleted here (the old token tooling still reads it; first v1.47 cleanup).
- **Hex package:** README.md is in the package `files` and reaches hex.pm; run `mix verify.package` and `mix docs --warnings-as-errors`. `brand/` and `brandbook/` stay out of the Hex `files` list. HexDocs gets the logo and favicon through ExDoc config, not through packaged `brand/` files.
- **Delivery:** this branch stacks on the unmerged Phase 187 Draft PR #138 only for planning-state continuity; the code diff is README/docs/mix.exs/tests/allowlist. Do not open the PR until Phase 187 lands on main (ROADMAP: no stacked PRs): the orchestrator rebases onto main and opens it then.
- No human UAT: the stylesheet and header are proven by the built-docs contract test; what is subjective (how the header looks) is not a gate and is stated as not proven.

### Claude's Discretion
File layout for the docs asset, helper naming, test structure, commit slicing (aim for 1 to 2 plans), the cheap checks first (docs build, then contract tests, then `verify.package`, `verify.core`).

</decisions>

<code_context>
- Pinned brand assets under `brand/assets/{readme,logo,icon,docs,social}` and `brand/brand.pin.json` (Phase 186); `mix verify.brand` must stay green.
- The token test and deny-list (`examples/scrypath_ecommerce/ui-tokens.test.mjs`, `retired-identity-allowlist.json`) currently allowlist README.md, PRODUCT.md and the prompts file.
- Local toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`. Docs build: `mix docs` (ExDoc 0.40.x).
</code_context>

<deferred>
- Deleting `brandbook/` and the old token tooling: first v1.47 phase cleanup. Website and wording renames: deferred to v1.47 (Phases 189, 190).
- The `<picture>` OS-theme versus ExDoc-toggle mismatch: recorded as a known residual.
</deferred>
