---
phase: 188
slug: readme-header-and-hexdocs
status: verified
verdict: SECURED
threats_total: 13
threats_closed: 13
threats_open: 0
asvs_level: 1
block_on: high
audited_commit: 54fe57ea
---

# Phase 188 Security Verification

Branch `feat/v1.46-188-readme-hexdocs`, code commit `54fe57ea`. Read-only audit; no implementation file was changed.
`T-188-SC` appears in both plans, so there are 12 distinct IDs plus the repeated supply-chain row counted once per plan (13 rows).

## Threat register

| Threat ID | Category | Sev | Disposition | Evidence | Status |
|-----------|----------|-----|-------------|----------|--------|
| T-188-01 (Plan 01) | Tampering, README image URLs | medium | mitigate | `README.md:3-4` uses relative `brand/assets/readme/...` paths only; no `github.io` or remote host in any `src`/`srcset`. Test `test/release/package_metadata_test.exs:216` ("README.md header paths are committed files and no README image points at the Pages site") asserts every ref is under `brand/assets/readme/`, a regular file, committed, and refutes `github.io` (`:232`). Run green (23 tests, 0 failures). | CLOSED |
| T-188-02 (Plan 01) | Tampering, docs stylesheet drift | low | mitigate | Tests `:402` (docs-owned rules equal derivation from the pin plus one dark-logo rule), `:407`/`:420` (code colors bound to `brand/tokens.json`), `:335`/`:346` (byte equality, `url()` resolution). `git diff origin/main..HEAD -- brand` is empty; `mix verify.brand` prints `ok (44 assets)`. | CLOSED |
| T-188-03 (Plan 01) | Information disclosure, Hex package | low | mitigate | `mix.exs` `package[:files]` is unchanged against origin/main (the only `files` hit in the mix.exs diff is a comment). `mix hex.build --unpack` into a scratch directory outside the repo: 135 files, none under `brand/`, `brandbook/`, `dev/`, `doc/` or `prompts/`, and no `.svg`/`.css`/`.woff`/`.html`. Tests `package_metadata_test.exs:56-73` (`refute "dev"`, `scrypath_ops`, `.planning` etc.) and `test/mix/tasks/brand_pin_contract_test.exs:848` ("the package files list has no brand entry"). | CLOSED |
| T-188-04 (Plan 01) | Tampering, deny-list allowlist and ceilings | medium | mitigate | `examples/scrypath_ecommerce/retired-identity-allowlist.json`: README entry removed, none added; `brandbook/` prefix hit ceiling lowered 270 to 177. `ui-tokens.test.mjs:63-72` exact ceilings (0, 0, 7, 201). `node --test` runs 59 pass, 0 fail. The test fails both on growth and on unused room. | CLOSED |
| T-188-05 (Plan 01) | Denial of service, Hex consumers evaluating mix.exs | low | mitigate | `mix.exs` `docs/0` additions are string literals and a function capture (`&before_closing_head_tag/1`); no `File.*` read added in `project/0`. `mix hex.build --unpack` succeeded with no `brand/` or `dev/` present in the unpacked tree. ExDoc skips missing asset sources. | CLOSED |
| T-188-06 (Plan 01) | Denial of service, core suite and workspace | low | mitigate | `package_metadata_test.exs:177-178` builds docs into `Path.join(System.tmp_dir!(), ...)` with `on_exit(File.rm_rf!)`. After running the file, `git status --porcelain -- tmp brand brandbook` is empty and no `scrypath-docs-*` leftovers remain in `/tmp`. | CLOSED |
| T-188-07 (Plan 01) | Tampering, `before_closing_head_tag` injection | low | accept | Accepted risk is justified: `mix.exs` `before_closing_head_tag(:html)` is a static `~s(...)` literal with no `#{}` interpolation and no input; other formats return `""`. Test `:369` ("the head hook links the stylesheet for html only and stays private"). Active-content scan of `brand/assets/readme`, `logo`, `icon` and `dev/docs`: no `<script`, `on*=`, `javascript:`, `foreignObject`, `iframe`, `@import` or remote `url()`; the sole `url()` is relative (`dev/docs/scrypath-exdoc.css:20`). The mirrored `header-snippet.html` is inert markup (`<picture>`, `<img>`, `<p>`; no script). | ACCEPTED-RISK (verified benign) |
| T-188-SC (Plan 01) | Tampering, supply chain | high | mitigate | `git diff origin/main..HEAD -- mix.lock` is empty; no `package*.json` or other lockfile in the branch diff; `mix.exs` diff holds no `deps` change (docs keys only). | CLOSED |
| T-188-08 (Plan 02) | Tampering, allowlist entries and exact ceilings | medium | mitigate | Allowlist diff: two entries removed (`PRODUCT.md`, `prompts/scrypath-brand-book.md`) plus README from Plan 01, none added; `prefix: brandbook/` and its `retire-last` tag retained. Exact ceilings 7 entries / 201 hits enforced by `ui-tokens.test.mjs:68,72`; 59 pass. | CLOSED |
| T-188-09 (Plan 02) | Repudiation, deleting the prompts brand book | low | accept | `git ls-files --error-unmatch prompts/scrypath-brand-book.md` fails (deleted). The remaining `git grep` hit outside `.planning/` is a historical citation in `brandbook/notes/pressure-test.md:3` (a note, not a reader of the file). `brand/BRAND.md` supersedes it; history keeps the file. | ACCEPTED-RISK (documented, reversible) |
| T-188-10 (Plan 02) | Information disclosure, releasing doc and PRODUCT.md wording | low | mitigate | `docs/releasing.md:26-27` names only public repo paths and `raw.githubusercontent.com/szTheory/scrypath/<commit>/...`; no tokens or private hosts found. Anchor test `package_metadata_test.exs:267` pins the section. | CLOSED |
| T-188-11 (Plan 02) | Spoofing, future raw image URL fallback | low | mitigate | `docs/releasing.md:26` forbids the mutable Pages site; `:27` requires commit-pinned raw URLs. It is documented only: README uses no raw URLs (see T-188-01). Anchor test `:267` asserts `raw.githubusercontent.com` is present. | CLOSED |
| T-188-SC (Plan 02) | Tampering, supply chain | high | mitigate | Same evidence as Plan 01 `T-188-SC`: lockfile and package manifests unchanged, no install step. | CLOSED |

## Unregistered flags

None. Both SUMMARY `## Threat Flags` sections say "None".

## Observations (not threats, not blocking)

- `brand/assets/readme/header-snippet.html` ships in the built docs (via the `brand/assets/readme` mirror) with unresolvable relative `assets/readme/...` refs. Inert; a test (`package_metadata_test.exs:283`) pins it as the single such file. It never ships in the Hex tarball.
- The branch is far ahead of origin/main, so the whole-branch diff also contains Phase 187 files; the Phase 188 supply-chain checks (`mix.lock`, package manifests, `mix.exs`) were evaluated on the full branch diff and are clean.

## Verdict

SECURED. `threats_open: 0` of 13 rows; no blocking or non-blocking open items.
