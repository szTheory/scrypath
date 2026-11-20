# v1.47 prep, decision A: shape and phase list

Status: PREP NOTE for the maintainer, written 2026-11-19. It feeds the discuss, plan, execute and verify workflow and is not a phase plan. Nothing here is started or approved.

Labels: V = verified this session by fetching a primary page (hex.pm API, GitHub API) or running a read-only command; R = read in a repo file; J = judgment. Facts come first, judgment after.

## Question

v1.46 shipped phases 186 to 188. Phases 189 (website, SITE-01) and 190 (catalog-free wording, COPY-01) were deferred, plus tracked cleanup (delete `brandbook/`, `dev/mix/tasks/verify/ui_tokens.ex`, the `ops.*` token mirror and `test/mix/tasks/ui_tokens_contract_test.exs`, replace the demo favicon, remove the `retire-last` allowlist entries). The rolling plan for v1.47 was "Catalog foundation" (191 spike, 192 fixtures, 193 pilot read-only, 194 pilot retry, 195 scale). Should v1.47 be (a) deferred items plus catalog in one milestone, (b) a small "Brand completion" then a separate "Catalog foundation", or (c) something else?

## Recommendation

**Option (b), with one numbering change and one ordering rule.** v1.47 "Brand completion" is three phases (189 website, 190 wording, 191 cleanup), about 5 to 6 plans. v1.48 "Catalog foundation" is the existing catalog plan renumbered 192 to 196. The old v1.48 "Screens" and v1.49 "Adopter features" shift to v1.49 and v1.50. Confidence: medium-high (about 0.7). The decision is cheap to reverse: the phase list is the same under (a), so choosing wrong costs one extra closeout, not rework.

### Phase list

| Phase | Milestone | Scope | Plans | Gates (no new required gate unless noted) | Needs the maintainer |
|---|---|---|---|---|---|
| 189 Website re-skin | v1.47 | SITE-01: palette, three self-hosted fonts, brand logo and favicon, pinned PNG social card, light default with dark by OS preference | 2 | Extend `website/scripts/check.mjs` from capture-only to computed-style, font-200-and-hash, logo and favicon, contrast pairs in both schemes; deny-list `p189` entries removed; `website.yml` `build-and-check` green on the exact head before merge | One merge yes (merging deploys the public site) |
| 190 Catalog-free wording | v1.47 | COPY-01 plus the sentence-case "Control room" rename (the v1.46 out-of-scope note assigns it to this wording phase) | 2 (1 if it fits) | Copy guards as a small data table (rule id, forbidden pattern, allowed form, scope) asserted in the existing required `ops-ui` job (extend `reskin_component_contract_test.exs`); one local run of the ordinary e2e partition with fix authority | One batched yes on visible copy |
| 191 Retire old token mirror and brandbook | v1.47 | Delete `brandbook/`, `ui_tokens.ex`, `ui_tokens_contract_test.exs`, the `ops.*` mirror; fix `mix.exs` `preferred_envs`, `verify.phase99.ex` file list, the `ci.yml` path regex and the `brand_pin_contract_test.exs` planted case; replace the demo favicon; empty the allowlist | 1 to 2 | A table mapping every deleted assertion class to a surviving test or an explicit "brandbook-only, dropped"; allowlist holds no `retire-last` entry; `core`, `repository-contracts`, `ops-ui` green | None (squash on green) |
| 192 Storybook spike and boundary proof | v1.48 | Dependency pin, macro-guarded dev route, prod and test-endpoint route absence, about five primitives rendered in both themes, record the ADR 0001 numbers | 2 | Existing "Storybook boundary" row (already counted); spike records cold and warm `ops-ui` time, NIF fetch, CSS isolation effort | Only if an ADR 0001 trigger fires |
| 193 Fixtures and cheap copy layers | v1.48 | ADR 0002 fixtures project, delete both `Phase173FixtureSource` copies, rendered-text lint starting from the fixed copy | 2 | Fixture invariants (counts as one new gate); lint (second); no third | No |
| 194 Pilot, read-only half (JOB-03) | v1.48 | Control room, Search health, Failed sync list extracted pixel-identical; whole-job journey test; stories | 3 | JOB-03 whole-job test (third new gate) | No |
| 195 Pilot, retry half with `decide/4` | v1.48 | Retry path, blocked states via the pure `decide/4` | 2 | Extends the JOB-03 test | No |
| 196 Catalog at scale (trimmed) | v1.48 | Scenario manifest and coverage; cut line if 192 to 195 overran | 2 | At most the fourth and last new gate | No |

Order inside v1.47: 189, 190, 191. Cleanup goes last because the allowlist tag is literally `retire-last`; the "first v1.47 phase" wording in the allowlist reasons was written when 189 and 190 were still in v1.46 and is now stale.

Sequencing rules for the roadmap file: keep 189 and 190 numbers (the `p189` allowlist tags and requirement IDs point at them), give cleanup 191, and shift the catalog to 192 to 196. Rename the later rows v1.49 (screens) and v1.50 (adopter features). `ROLLING-ROADMAP.md`, `PROPOSAL.md` and the allowlist `reason` strings mention the old numbers.

## Facts verified (separate from judgment)

Repo (R):
1. v1.46 closed with 3 phases and 16 plans; audit status `tech_debt`; SITE-01 and COPY-01 are the only unsatisfied requirements (`v1.46-MILESTONE-AUDIT.md`). The closeout cost three docs commits (`c3233864`, `b643478b`, `713101ad`).
2. The website is dark-only (`website/src/assets/styles.css` defines `--bg: #0b0f15` and the old violet and copper tokens; no `prefers-color-scheme` or `data-theme`; `layout.html` has `theme-color` `#0b0f15`). It uses an SVG `og:image` (`assets/og-image.svg`) and a stub brand mark as favicon. `check.mjs` (89 lines) only asserts the h1 text and writes screenshots in forced dark; it asserts no palette, font or logo. SITE-01 therefore needs a real check written, not just a CSS swap.
3. `website.yml` runs `build-and-check` on every pull request and `deploy` on push to main with `needs: build-and-check`. `build-and-check` is not among the six required checks (`CONTRIBUTING.md`: core, package, repository-contracts, backend, ecommerce-mounted, ops-ui). A standing merge-on-green rule would not wait for it.
4. The brand pin already holds the social card PNG, logos, favicons and the three woff2 files (`brand/brand.pin.json`; fonts under `scrypath_ops/priv/static/assets/fonts/`, 53,076 bytes with Bricolage).
5. The allowlist (`examples/scrypath_ecommerce/retired-identity-allowlist.json`) has seven entries: two `p189` website SVGs and five `retire-last` (`brandbook/`, `ui_tokens.ex`, `ui_tokens_contract_test.exs`, `ci.yml`, the demo favicon). Cleanup also touches `mix.exs` (`"verify.ui_tokens": :test`), `dev/mix/tasks/verify.phase99.ex` (names the contract test) and `brand_pin_contract_test.exs` (a planted `brandbook` case). `ui_tokens.ex` is 898 lines and its contract test 836 lines; `brandbook/` is 384 KB.
6. The required-gate ledger in `CONTRIBUTING.md` says "Budget used: 8 of 12", scoped by name to "the brand and UI milestone (v1.46)"; `workflow_wiring_test.exs` fails above 12 rows. The "Token parity and retired-identity deny-list" row says to delete the deny-list half once the allowlist holds no `retire-last` entry, which phase 191 will trigger. The "ScrypathOps re-skin component contract" row says it is replaced by the catalog contract in v1.47.
7. The static storybook boundary already exists in `test/mix/tasks/dependency_boundary_contract_test.exs` (a `describe "storybook boundary (v1.47 catalog)"` block: root lib never mentions it, root manifest never depends on it, ops declaration must be `only: [:dev, :test]`). No `PhoenixStorybook` mention exists in code yet.
8. COPY-01 touches `sync_drift_live.ex` (the `"Searchable"` / `"Not searchable"` tuple at line 1734, `Retry accepted`, `Index swap accepted`), `control_room_live.ex` (`Last successful observation`, `Last successful check`) and 10 files mention "Control Room" (code, ops tests, one ecommerce controller test). The GLOSSARY entry is "Control room".
9. ADR 0001 itself names one revisit condition (a fidelity gap an iframe cannot solve). The five measurable triggers live only in `V1.46-PREP.md` D12.
10. The v1.46 retrospective records that a Draft PR waiting for a merge yes made later phases stack, and that a standing squash-merge-on-green rule now removes that wait.

External (V, 2026-11-19):
11. phoenix_storybook latest is 1.5.0 (2026-09-15); no newer release in the two months since. Requirements: `makeup_eex ~> 2.0.2`, `makeup_html ~> 0.2.0`, `mdex ~> 0.12`, `phoenix ~> 1.8.1`, `phoenix_live_view ~> 1.1.21 or ~> 1.2.0`; igniter and jason optional. Repo: last commit 2026-11-02, active Dependabot, open issues are small (iframe 500 on wrong `variation_id` #912, resizable sandbox).
12. Its security advisories list has exactly three entries, all published 2026-05-20 and patched in 1.1.0 (critical RCE via the playground GHSA-55hg-8qxv-qj4p, high atom exhaustion GHSA-833p-95jq-929q, low PubSub injection GHSA-mrhx-6pw9-q5fh). None after that date. 1.5.0 is above the fix.
13. `scrypath_ops/mix.lock` has 54 packages and none of `phoenix_storybook`, `mdex`, `mdex_native`, `rustler_precompiled`, `makeup*`, `nimble_parsec`. Adding the storybook adds 9 new packages (storybook, makeup, makeup_elixir, makeup_eex, makeup_html, nimble_parsec, mdex, mdex_native, rustler_precompiled), about +17 percent; `jason` and `nimble_options` are already locked. `mdex_native 0.3.2` is the only native-code addition (Rust NIF fetched at compile by `rustler_precompiled`, which the PREP says is checksum-verified). Ops already carries a precompiled NIF in its test graph (`lazy_html` with `cc_precompiler`, `elixir_make`, `fine`), so "downloads a binary at compile" is not a new category, only a second mechanism.
14. mdex shipped six releases between 2026-10-04 and 2026-11-14 (0.14.2 to 0.14.7; `mdex_native >= 0.3.2` has no upper bound; one owner). Expect Dependabot churn on a dev-only dependency.
15. Sigra: Hex's newest release is 1.7.1 (2026-10-11), which still requires `cloak_ecto ~> 1.3` non-optionally; a `v1.7.2` tag exists on GitHub but is not on Hex. So `deep-quality` stays red for cloak and cloak_ecto, no patched release exists for either.

## ADR 0001 revisit triggers: did any fire?

No trigger has fired. Status of each (J on the reading, V and R on the inputs):

| Trigger (V1.46-PREP D12) | Status today |
|---|---|
| Unpatched advisory open more than 14 days | None open (fact 12). Caution: `deep-quality` is already red from cloak, so a new advisory would not change the job's colour; the spike must read the audit output, not the job status. |
| NIF download failing once in a required job after caching | Not testable yet; needs the spike. |
| CSS isolation work exceeding one day | Not testable yet. The theme risk is known (23 `html:not([data-theme="light"])` rules; iframe stories) and the ADR already chose iframes. |
| Storybook blocking a LiveView 1.2 bump | Not blocked: it accepts `~> 1.1.21 or ~> 1.2.0` and ops pins `~> 1.1.33` (fact 11, R). |
| Cold `ops-ui` time growing by more than 3 minutes | Not measured; needs a baseline in the spike. |

So the ADR stands as decided on 2026-10-25, and the spike (phase 192) is exactly the measurement of the four untested rows. Copy the five numeric triggers into the ADR file during 192 so they live with the decision.

## Lenses (strongest point from each)

- **Security.** The only new exposure in either milestone is the storybook playground, which has a recorded critical RCE (fixed in 1.1.0, unaffected at 1.5.0). The real risk is deployment shape, not the version: the ops test endpoint binds `0.0.0.0` with `check_origin: false` when `PHX_SERVER=true` (R, per V1.46-PREP), so route absence in test and prod must be asserted, not assumed. Brand completion adds none; the website phase should copy fonts from the pinned directory with a hash assertion rather than fetch anything from a third party. The cleanup phase's own risk is deleting a gate: a deleted assertion must map to a surviving one.
- **Product (adopter and maintainer value).** Neither milestone changes the Hex library. The website is the adopter front door and currently shows the retired violet and copper identity next to a plum README and HexDocs; finishing it has the highest adopter-visible value per plan in the whole next stretch. The catalog is maintainer tooling (ops is not on Hex). Splitting lets the maintainer choose between catalog and adopter features at a milestone boundary with fresh prep, which the standing instruction already requires.
- **Architecture.** Brand completion is three independent slices with no shared code (a static site, ops strings, dev tooling); the catalog is one sequential dependency chain (spike, fixtures, extraction, journey). Mixing them in one phase list hides that the catalog's first phase can end the milestone's direction (a trigger fires, ADR fallback or separate Mix project). Isolating the fork keeps the brand work from being hostage to it.
- **Devops and CI cost.** The catalog is the CI-cost event: cold `ops-ui` and the boundary test compile fresh graphs, and the BEAM cache goes cold every one to two weeks (V in V1.46-PREP: 775 s cold vs 19 s warm for repository-contracts). Brand completion adds no required gate and removes about 1,700 lines of Elixir gate code. Gate ledger: 8 of 12 used; the catalog needs about 3 new gates (fixture invariants, rendered-text lint, JOB-03 test) and the component contract row is replaced by it, so the cap holds at 11 to 12. The cap is worded for v1.46, so v1.48 needs one confirmation that it carries over.
- **Design and UX.** The website flips from dark-only to light default; that is the only visual decision left in v1.47 and it is already decided in SITE-01 and the book. Keep v1.46's rule: recolor, fonts, logo, favicon; no layout reflow of the four pages. Wording is visible too, so it gets the batched yes. The catalog's rendered artifacts are the first time the maintainer can browse states, which is its UX payoff.
- **Accessibility.** Website needs both schemes checked for contrast, `color-scheme`, a `theme-color` for each scheme, visible focus and reduced motion; the pinned `brand.json` has the contrast pairs to reuse (copy, no dependency). In ops, the wording work is an accessibility fix for status words ("Searchable" shown without an observation, "Clear" semantics) and must keep word-plus-icon rules. Catalog axe checks belong to 194, not earlier.
- **OSS maintainer and adopter.** A public repo currently carries three identities (new in ops, README, HexDocs; old on the website and demo favicon; a superseded `brandbook/` directory contributors can find). Completing brand removes the contributor-facing confusion and lets the next Hex release carry a coherent page. One residual Hex item stays outside any phase: the README header image does not load on hex.pm until the two URLs are commit-pinned (`docs/releasing.md`), a release-time step.

## Patterns, anti-patterns, footguns

Patterns to keep: one finite inventory per milestone; one independent read-only check of merged `main` at closeout (it found two defects the per-phase verifiers missed in v1.46); a local run of the whole ordinary e2e partition with fix authority once per UI-touching phase; deny-list and allowlist that only shrink.

Anti-patterns to refuse: bundling the spike's go/no-go with unrelated deploys; counting "no required gate added" as "no gate cost" (the ledger table and wiring test still need a row edit when a trigger text changes); writing the wording guards as scattered string asserts that phase 193 would redo as lint rules.

Footguns found:
1. **Merge-on-green skips the website check.** `build-and-check` is not required (fact 3). The plan for 189 must state "merge only after `build-and-check` is green on the exact head". The deploy job's `needs` is a backstop, not a gate. Do not add it as a required gate to fix this; the budget is tight.
2. **The deletion trigger will fire in 191.** The deny-list half is to be "deleted once no `retire-last` entry remains". Recommend keeping the deny-list (it is cheap, one mechanism, and stops the old identity coming back from old branches or sibling copy-paste), and rewriting that trigger text and the `retire-last` vocabulary in the same change. Net gate count stays 8.
3. **`og:image` as SVG.** Social crawlers generally do not render SVG; use the pinned PNG social card (1280 by 640).
4. **Deleting the mirror drops silent coverage.** `ui_tokens.ex` also validated brandbook documentation parity. Most of that dies with the directory on purpose; the mapping table in 191 is the evidence, and the Node token test plus the contrast checker already own live-token parity (R, `v1.46-MILESTONE-AUDIT.md`).
5. **Wording renames can hit advisory specs.** V1.46-PREP counts five e2e specs that pin the old casing; my exact-string grep over `.ts` found none, so re-count at planning. Those specs run only on schedule or dispatch, so a green required lane will not notice a stale one; 190 must run the e2e partition once.
6. **`deep-quality` masking.** See the trigger table. It also means the storybook's new packages are audited inside an already-red job.
7. **Progress guard.** Phases 192 and 193 are infrastructure-heavy; 192 renders first stories and 193 renders states from fixtures, which satisfies "a rendered story or proven-identical extraction", but a second plan with neither forces a stop-and-decide.
8. **UI-PREVIEW.json is stale** (audit tech debt). Refresh and run `npm run ui:preflight` before capture-based review in 190; the ExUnit copy guards do not need the preview.

## Options compared

| | (a) one milestone | (b) split (recommended) | (c) other |
|---|---|---|---|
| Phases and plans | 8 phases, about 16 to 17 plans (same order of size as v1.46's 16 and v1.44's 17) | 3 phases about 5 to 6, then 5 phases about 11 | c1: spike inside v1.47; c2: cleanup inside catalog; c3: swap catalog behind adopter features |
| Public outcome earlier | Website waits behind the catalog or gets reordered ahead of it | Website, wording, cleanup land in days | c1 muddies the audit; c2 delays old-identity retirement for no dependency reason |
| Closeout ceremony | One | Two (about three docs commits each, per v1.46) | |
| Scope fork (ADR fallback) | Held inside a larger milestone | Isolated in v1.48 | |
| Milestone-boundary optionality | None until the end of the catalog | Maintainer re-chooses catalog vs adopter features after v1.47 with fresh prep | c3 uses this option and is a product call, not mine |
| Copy lint baseline | Starts from known debt unless 190 is first | Starts from fixed copy | |
| Progress guard | Evidence-heavy stretch inside the milestone | Visible increments first | |

Size alone does not reject (a): the plan count is comparable to earlier milestones. The case for (b) is heterogeneity, optionality and a clean audit boundary.

## Adversarial pass

Attacks on the recommendation, and what survives:

1. **"A three-phase, five-plan milestone is mostly ceremony."** Partly true. The closeout is about three docs commits plus an audit, similar to v1.46. It survives only because the milestone ends with a public deploy and a deletion of a gate family, which both deserve an independent read of merged `main` (v1.46 precedent). If the website phase turns out to be one plan and cleanup folds into it, a two-phase milestone is too thin: then use (a) with 189 to 191 first and a checkpoint before 192.
2. **"The catalog is the maintainer's stated priority; splitting delays it."** The delay is the plan count of v1.47. v1.46 completed all three phases on 2026-11-19. If the maintainer wants no delay at all, (a) with the same order loses nothing but the boundary. Survives, medium confidence.
3. **"Wording before the catalog will be redone by the catalog's copy lint."** Real risk. Mitigated by writing 190's guards as a data table (rule id, pattern, allowed form, scope) that 193's lint ingests; otherwise this attack wins and 190 should wait. Survives only with that mitigation.
4. **"Website light default may be a taste decision, not automatable."** SITE-01 and the book already fix it, and the maintainer delegates design calls; the checks are computed-style and contrast, not taste. The subjective read stays nonblocking and unclaimed, consistent with the Phase 185 correction.
5. **"The spike should run now, in parallel, because the catalog is the long pole."** Dev-only and independent, so it could. Rejected: it would mix a go/no-go with a public deploy in one audit and spend the one-evidence-phase allowance outside its milestone. If the maintainer wants parallelism, it belongs in a separate worktree with its own PR, not in v1.47's scope.
6. **"Is the storybook worth +9 packages and a Rust NIF at all?"** ADR 0001 decided yes; no trigger has fired; the plan keeps the fallback (hand-rolled harness, or a separate Mix project like `fixtures/`). What the pass changes: the spike must produce the numbers, and it must read the audit output because the job is already red.
7. **"Catalog-first order is unproven."** Agreed: it is one chosen path (V1.46-PREP). Splitting is what makes the order revisable after v1.47.

## What would change the recommendation

- Website plus cleanup measured at one plan combined before planning: move to (a) with 189 to 191 first.
- The maintainer prefers fewer boundaries over optionality: (a), same phase order.
- The maintainer wants adopter features before screens or before the catalog: still (b); the choice is made at the v1.47 boundary and costs only roadmap rows.
- A spike trigger firing after the split: v1.48 shrinks to the spike and an ADR decision, which (b) already isolates.
- A hex.pm README-header fix or a library change needing a release: add it as a release step after 191, not a phase.

## What needs the maintainer

1. Approve (b) and the renumbering (one answer; default yes).
2. One merge yes for the 189 website PR and one batched yes for 190's visible wording. 191 needs none.
3. Confirm the 12-gate cap carries into v1.48 (default yes; ask again only if a fifth new gate is proposed).
4. Optional, outside the milestone: a Hex release (a separate yes), and releasing sigra 1.7.2 so `deep-quality` can go green and the audit signal means something before the storybook enters the graph.

## Follow-ups for whoever applies this

- Update `ROLLING-ROADMAP.md` (v1.47, v1.48, v1.49 rows and "Known stale text"), the allowlist `reason` strings, and the `CONTRIBUTING.md` budget sentence (it names v1.46).
- Requirements to add on `/gsd-new-milestone v1.47`: SITE-01, COPY-01 (plus the Control room rename wording), and a short TIDY item for 191; no catalog requirements until v1.48.
- Per the standing instruction, the other decision points for v1.47 (website theme details, copy rule shapes, cleanup mapping) are separate prep notes; this note decides only shape and order.
