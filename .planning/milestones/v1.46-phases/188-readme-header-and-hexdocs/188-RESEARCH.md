# Phase 188: README header and HexDocs - Research

**Researched:** 2026-11-19 (planner did the research; the phase is small)
**Tree:** `feat/v1.46-188-readme-hexdocs` at `140c25da`, ExDoc 0.40.4 from `mix.lock`
**Grades:** V = verified by running something on this tree; R = read in code, not run; W = primary web source; U = unverified or inferred.

## Summary

Every decision in 188-CONTEXT.md holds against the current tree, with four corrections the plans carry:

1. The previous session's probed stylesheet (scratchpad `docbuild/brand/docs/scrypath-exdoc.css`) left `pre code.makeup` unprefixed. ExDoc's `.dark .makeup{color:#dce1e6}` is (0,2,0) and beats `pre code.makeup` (0,1,2), so untagged code text stays ExDoc grey in dark (V, read against `deps/ex_doc/formatters/html/dist/html-elixir-RXHHCTJW.css`). A fresh derivation that prefixes every rule with a non-custom declaration fixes it. Do not copy the scratchpad file.
2. The pinned `brand/assets/icon/favicon.svg` has classes `g` and `l` but no `<style>` and no fill, so it draws black in both themes (V, read the 891-byte file). BRAND.md line 225 says it follows the device theme. The docs therefore use `brand/assets/icon/favicon-light.svg` (ink and plum fills, pinned). Docs default to light (owner decision 5). Phase 187 copied `favicon.svg` into ops, so ops has the same black favicon: this goes to the send-back list, and ops is out of scope here.
3. ExDoc takes one `logo`. It sits on the sidebar header: `--sidebarHeader` is gray100 `hsl(212,33%,91%)` in light and gray700 `hsl(212,35%,17%)` in dark. Computed contrast (V): ink `#1E1220` is 14.56:1 on light and 1.25:1 on dark, and plum is 6.97:1 on light and 1.68:1 on dark. Pale ink and orchid are the reverse. Neither symbol works in both themes. Planner decision (reversible, one CSS rule): set `logo` to `scrypath-symbol-light.svg` and add one docs-owned rule, `body.dark .sidebar-projectImage img{content:url("../brand/assets/logo/scrypath-symbol-dark.svg")}`, with `brand/assets/logo` mirrored through `assets:`. MDN says all browsers support replacing an element with an image through `content` (W). No browser in this phase renders it, so the swap is proven only by rule and file assertions (U for pixels).
4. The ExUnit `:tmp_dir` tag writes under `<repo>/tmp/`, which is not gitignored. The deny-list scan reads untracked-but-not-ignored files (`git ls-files --others --exclude-standard`, `ui-tokens.test.mjs:856`), and ExDoc's own dist CSS is full of hex values. The built-docs test must write to `System.tmp_dir!()` with a unique name and clean up `on_exit`, as `brand_pin_contract_test.exs:891` does (V for the scan source; U for whether ExDoc's CSS holds a retired value).

## Current tree (V unless marked)

| Item | Finding |
|------|---------|
| README header | Lines 1-6: `<p align="center"><picture>` with `srcset` and `src` pointing into the retired brand directory (`logo-primary-inverse.svg` and `logo-primary.svg`, width 300). 2 retired-directory hits. |
| PRODUCT.md | Line 49 names the retired directory's `assets/` and calls the brand book exploratory. 1 hit. |
| Other docs | `git grep` finds the retired directory name only in README.md and PRODUCT.md among the docs and extras. Other hits are `ci.yml:367` (ops-ui path regex), `dev/mix/tasks/verify/ui_tokens.ex`, the allowlist, `ui_tokens_contract_test.exs` and `brand_pin_contract_test.exs`, all `retire-last` or test-owned. All stay for v1.47. |
| `prompts/scrypath-brand-book.md` | 905 lines, the superseded v1 brand prompt, with 34 retired-identity hex hits (allowlist `max_hits: 34`). No test, task or doc reads it (`git grep`). AGENTS.md only names `prompts/` in general. `brand/BRAND.md` is the complete pinned text of the current book. Decision: delete it; git history keeps it. |
| mix.exs `docs/0` | `main: "readme"`, `source_url`, `source_ref`, `extras` (33 files), `groups_for_extras`. No `logo`, `favicon`, `assets` or `before_closing_head_tag`. `package.files` excludes `brand*` (guarded by `brand_pin_contract_test.exs` "the package files list has no brand entry"). |
| Pinned assets | 44 pin entries in `brand/brand.pin.json`, including `readme/scrypath-header-{light,dark}.svg`, `readme/header-snippet.html`, `logo/scrypath-symbol-{light,dark}.svg`, `icon/favicon{,-light,-dark}.svg`, `icon/favicon.ico` and `docs/scrypath-exdoc.css`. Nothing new is needed under `brand/`, so no pin update. `mix verify.brand` takes 0.5 s. |
| Brand snippet | `header-snippet.html`: `<picture>` with a dark `source` and a light `img`, `alt="scrypath"`, `width="260"`. Header SVGs are 520x110 (aspect 4.73, so 55 px tall at 260 wide). |
| Code colors | `brand/tokens.json` `color.code.{background,text,comment,keyword,string,atom}-{light,dark}` equal the pinned stylesheet's `:root` and `body.dark` custom properties (`#F0E9E6`/`#110A14`, `#1E1220`/`#F4EDF3`, `#6B5F6E`/`#A89BAD`, `#7B2D6B`/`#D58BC4`, `#2748A8`/`#93A9F5`, `#006A7A`/`#6FD0DC`). |

## ExDoc 0.40.4 facts (R in `deps/ex_doc`, V by build)

- `assets:` is a map of source directory to target directory, copied as is (`ExDoc.Formatter.copy_assets/2`). A missing source directory is silently skipped (`is_binary` and not a dir gives `[]`), so a Hex consumer evaluating `docs/0` never reads `brand/`. The list-of-content form exists in code but is undocumented: do not use it.
- `logo` and `favicon` accept `.png`, `.jpg`, `.jpeg` and `.svg` only (`copy_image/3` raises otherwise). They are copied to `assets/logo.<ext>` and `assets/favicon.<ext>`. The sidebar renders `<img src="assets/logo.svg">` inside `.sidebar-projectImage`, with `max-width:48px;max-height:48px`.
- Head template order: `<link rel="icon" href="assets/favicon.svg" />`, then `dist/html-elixir-*.css`, then the scripts, then `before_closing_head_tag.(:html)`. So a stylesheet linked from `before_closing_head_tag` loads after ExDoc's CSS. The option accepts a 1-arity function, called with `:html` or `:epub`.
- Dark mode is the class `dark` on `body`, toggled from JS (settings `theme: system|dark|light`). ExDoc's CSS has no `prefers-color-scheme` query (count 0).
- Specificity (V by reading the dist CSS): ExDoc light `.makeup .kd` is (0,2,0) and dark `.dark .makeup .kd` is (0,3,0). The book's `.makeup .kd` is (0,2,0): it wins light on load order and loses dark. Prefixed, `body .makeup .kd` is (0,2,1) and `body.dark .makeup .kd` is (0,3,1), which win both regardless of order. `body pre code.makeup` (0,1,3) and `body.dark pre code.makeup` (0,2,3) beat `.content-inner code` (0,1,1, background) and `.dark .makeup` (0,2,0, color).
- Token classes ExDoc colors in dark that the book does not cover (V, set difference): `bp dl err gd ge gi gp gs gt gu hll kc l ld n nb nd ne ni nl nt nv nx o p py vc vg vi vm`. These keep ExDoc's colors, for example operators `.o` in orange `#bc5400` on light. The book defines which classes get brand colors, so this phase does not invent more. Recorded as a residual and on the send-back list.

## Prototype (V, scratch copy of HEAD, not the repo)

The scratch copy (`git archive HEAD`, deps symlinked) had `logo`, `favicon`, `assets: %{"brand/assets/readme" => "brand/assets/readme", "dev/docs" => "assets"}`, a `before_closing_head_tag/1` that returns a `<link>` for `:html` and `""` otherwise, and the README `<picture>` pointed at `brand/assets/readme/scrypath-header-{dark,light}.svg`. `mix docs --warnings-as-errors` passed in 1.7 s. In the build:

- `doc/assets/` holds `favicon.svg`, `logo.svg` and `scrypath-exdoc.css`. `doc/brand/assets/readme/` holds both header SVGs and `header-snippet.html`.
- The `readme.html` head is icon (line 13), ExDoc CSS (line 15), brand CSS (line 20). The sidebar has `<img src="assets/logo.svg">`.
- `readme.html` header `srcset`/`src` resolve to `doc/brand/assets/readme/...`.
- `header-snippet.html` is copied too. Its own `src="assets/readme/..."` does not resolve inside `doc/`. It is a mirrored pinned file, not a docs page, so the src/srcset check scans only pages carrying ExDoc's `<meta name="generator" content="ExDoc v`.
- An ExUnit test calling `Mix.Tasks.Docs.run(["--output", tmp, "--formatter", "html", "--warnings-as-errors"])` in-process took 0.57 s for 108 HTML pages. The whole `mix test` of that file took 2.7 s wall. In-process works because `ex_doc` is `only: [:dev, :test]` and the suite is already compiled. ExDoc keeps its warned flag in `:persistent_term` and erases it per run; no other test builds docs. With all formatters (no `--formatter`) and `System.tmp_dir!()` output, the build took 0.92 s and produced 108 `.html`, 104 `.md`, `llms.txt` and `scrypath.epub`. `:zip.extract(epub, [:memory])` reads the 116 epub entries. The epub carries `OEBPS/brand/assets/readme/*.svg` and `OEBPS/assets/scrypath-exdoc.css`, so the mirrored assets reach the epub too.

## File placement (V)

- The fixed stylesheet cannot live under `brand/`: `mix verify.brand` owns that directory and the pin must stay byte-identical. It also cannot live under `docs/`: `package_metadata_test.exs` "every root docs file is covered by the package allowlist" requires every `docs/**` file in `package.files`. `dev/` is maintainer tooling outside the Hex package. Only `dev/**/*.ex` is enumerated (`workflow_wiring_test.exs:20,30`), and ops-ui already path-triggers on `dev/`, `mix.exs` and `test/release/`. Choice: `dev/docs/scrypath-exdoc.css`, mirrored with `"dev/docs" => "assets"`.
- Built-docs contract home: `test/release/package_metadata_test.exs`. It is already the docs-metadata contract, has no tags (so it runs in `core`), and `mix verify.package` (phase11) runs it too. Extending an existing file adds no new gate, so the ledger stays at 8 of 12 (CONTRIBUTING "Required-gate budget"). `docs_contract_test.exs` is the wrong home because its `@moduletag :docs_contract` excludes it from `core`.
- The test source must not hold the retired directory literal: the deny-list scans `test/` too. Build it at runtime (`"brand" <> "book/"`), as `ui-tokens.test.mjs` does with `RETIRED_DIR`.

## Deny-list mechanics (V)

`retired-identity-allowlist.json` has 10 entries summing `max_hits` 238. The entries this phase removes are README.md (`p188`, 2), PRODUCT.md (`p188`, 1) and `prompts/scrypath-brand-book.md` (`retire-last`, 34). `ui-tokens.test.mjs` has exact ceilings: `ALLOWLIST_CEILING = 10` and `HITS_CEILING = 238`. A stale entry, an entry count under the ceiling, or a hit sum under the ceiling each fails and prints the number to use (`:1012-1014`, `:1069-1071`). So each removal must land in the same commit as the edit that empties the file:

- After the README edit: 9 entries and 236 hits.
- After the PRODUCT edit and the prompts deletion: 7 entries and 201 hits.

`node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` takes 1.2 s (59 tests) and needs no `node_modules`. The `p188` tag can stay in `ALLOWLIST_TAGS`: no rule requires every tag to be used.

## Residuals (stated, not fixed)

- The README `<picture>` follows the OS theme; ExDoc follows its own toggle. With a dark OS and ExDoc set to light, HexDocs shows the dark header on a light page (U, not probed; locked as a residual by CONTEXT).
- Code token classes outside the book's list keep ExDoc colors (V, listed above).
- The favicon is the light drawing in every tab theme. A themed favicon needs an SVG with a style block, which the pin does not have (V for the file).
- No computed-style browser probe runs in this phase. Executors have no `node_modules`, and CONTEXT makes the probe advisory. Code colors are proven by stylesheet rule assertions bound to `brand/tokens.json` and ExDoc's built CSS, not by pixels.
- How the header and logo look is subjective and is not a gate.

## Send-back list additions for the brand book's author

12. `icon/favicon.svg` has class names but no style, so it is black in both themes, contrary to BRAND.md line 225.
13. One ExDoc logo cannot serve both sidebar themes (contrast numbers above). The book could ship a docs logo rule or say which symbol to use.
14. The ExDoc stylesheet colors 41 token classes. ExDoc colors about 70 in dark, so operators, constants, punctuation and names keep ExDoc colors.

## Costs (V on this machine)

| Command | Wall time | Notes |
|---------|-----------|-------|
| `mix docs` (warm) | 1.1 s, 1.7 s with the brand config | writes the gitignored `doc/` |
| In-process docs build inside ExUnit | 0.57 s | the contract test's own build |
| `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 1.2 s | builtins only |
| `mix verify.brand` | 0.5 s | |
| `mix verify.package` | 59 s | runs package_metadata, package_contents, consumer_smoke and docs_contract tests, the docs build, then `hex.build --unpack` (writes the gitignored `scrypath-<version>/`) |
| `mix verify.core --exclude integration --exclude docs_contract` | about 5 min (the `mix test` step was 272 s in Phase 186) | fetch-dependent `contrast_child` tests: first run needs the escalated permission AGENTS.md authorizes |

## Validation Architecture

There is no human verification. Each criterion maps to an automated check. All new assertions live in `test/release/package_metadata_test.exs` (call it PMT) unless named otherwise.

| Requirement / criterion | Automated check | Command | Cost |
|---|---|---|---|
| SC1 / BDOC-01: built `readme.html` header uses `brand/assets/readme/...` | PMT built-docs test: `readme.html` holds `srcset="brand/assets/readme/scrypath-header-dark.svg"` and `src="brand/assets/readme/scrypath-header-light.svg"` | `MIX_ENV=test mix test test/release/package_metadata_test.exs` | about 3 s |
| SC1: every `src`/`srcset` in the built docs resolves | PMT: for every ExDoc-generated page, every local `src` and every `srcset` candidate (skipping `http(s):`, `//`, `data:` and `#`) is a regular file relative to the page | same | same |
| SC1: the same paths resolve for the GitHub README | PMT: every local `src`/`srcset` in `README.md` is a regular file in the repository | same | same |
| SC2 / BDOC-01: no retired directory reference in the built docs | PMT: no text file in the built output (all formatters) contains the runtime-joined retired directory name | same | same |
| SC3 / BDOC-02: head links the brand stylesheet after ExDoc's, the favicon and the logo from `assets/` | PMT: on every generated page, the `dist/html-elixir-` link offset is below the `assets/scrypath-exdoc.css` link offset; the page has `rel="icon" href="assets/favicon.svg"` and `src="assets/logo.svg"`; the built `assets/favicon.svg` and `assets/logo.svg` are byte-equal to the pinned `favicon-light.svg` and `scrypath-symbol-light.svg`; the built brand CSS is byte-equal to `dev/docs/scrypath-exdoc.css` | same | same |
| SC3 / BDOC-02: every color rule prefixed `body ` and `body.dark `, no `prefers-color-scheme` | PMT stylesheet test: raw file has no `prefers-color-scheme` and no `@media`; every rule declaring `color`/`background*` lists, for each base selector S, exactly `body S` and `body.dark S`; the rules equal the derivation of the pinned file plus exactly one docs-owned logo rule | same | same |
| SC3 / BDOC-02: code-block colors asserted | PMT: `:root` and `body.dark` custom properties equal `brand/tokens.json` `color.code.*` light and dark; each token class maps to its custom property as in the pin; each prefixed selector outranks ExDoc's `.makeup .X`, `.dark .makeup .X`, `.dark .makeup` and `.content-inner code` by computed specificity; the built ExDoc CSS still contains `.dark .makeup .kd` (proves the bug the fix targets) | same | same |
| SC4 / BDOC-01: no README or doc reference to the retired directory | PMT repo test: README.md, PRODUCT.md and every `docs[:extras]` file are free of the runtime-joined name | same | same |
| SC4: prompts entry removed, deny-list passes | `node --test` the token test (exact ceilings 7 and 201; stale entries fail); `test ! -e prompts/scrypath-brand-book.md` | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 1.2 s |
| Existing pins stay green | docs_contract, phase108, phase111 and phase112 contract tests | `MIX_ENV=test mix test --include docs_contract test/scrypath/docs_contract_test.exs test/scrypath/phase108_contract_test.exs test/scrypath/phase111_contract_test.exs test/scrypath/phase112_contract_test.exs` | about 5 s |
| Docs build warning-free in the published env | `mix docs --warnings-as-errors` (dev env, like `hex.publish`) | `mix docs --warnings-as-errors` | about 2 s warm |
| Package unchanged in shape, brand stays out | `mix verify.package` and `mix verify.brand` | as named | 59 s, 0.5 s |
| Phase gate | `mix verify.core --exclude integration --exclude docs_contract` | as named | about 5 min |

Order: cheap checks first (token test, PMT, docs build), then the docs_contract family, then `verify.brand`, `verify.package` and `verify.core` once per plan on the final code commit.
