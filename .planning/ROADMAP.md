# Roadmap: Scrypath

## Milestones

- 🚧 **v1.47 Brand completion** — Phases 188.1, 189–191 (active; 4 phases, about 7 to 9 plans; CI path classifier, website re-skin, catalog-free wording, old-identity cleanup)
- ✅ **v1.46 Brand foundation and re-skin** — Phases 186–188 (3 phases, 16 plans, 27 of 29 requirements; shipped to `main` 2026-11-19 via PRs #137, #138, #139, #143; `tech_debt`; not released to Hex; Phases 189 and 190 deferred to v1.47) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.45 Foundation and CI** — Phases 182–185 (archived locally 2026-11-01; qualified `tech_debt` closeout; final-source acceptance external; merge/publication separate) — [archive](milestones/v1.45-ROADMAP.md)
- ✅ **v1.44 Sync correctness** — Phases 178–181 (4 phases, 17 plans, 45 tasks; archived locally 2026-10-26; `tech_debt` carried forward; PR #122 merge/publication pending) — [archive](milestones/v1.44-ROADMAP.md)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase 172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.47 Brand completion is the active milestone. Requirements are defined (18, revised after a four-review gap pass in [research/v1.47-gap-pass/](research/v1.47-gap-pass/)) and this roadmap maps all of them to Phases 188.1 and 189–191. Phases 188.1 (PR #149), 189 (PR #152, website deployed) and 190 (PR #153) are merged; Phase 190 (PR #153) is merged. Next: Phase 191. v1.46 is complete and on `main`; its [audit](milestones/v1.46-MILESTONE-AUDIT.md) is `tech_debt` with no unsatisfied requirement. Hex 0.3.19 (2026-11-20) shipped the README and HexDocs branding; no library change is planned in v1.47, and any Hex release stays the maintainer's separate explicit yes.

`deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## v1.47 Brand completion

**Milestone goal:** Finish the brand adoption v1.46 started: the website in the new identity, the wording fixes that do not need the catalog, and removal of the old identity's last code, so v1.48 (Catalog foundation) starts from a clean base.

**Inputs:** [REQUIREMENTS.md](REQUIREMENTS.md), [ROLLING-ROADMAP.md](reference/ROLLING-ROADMAP.md) "Post-v1.46 proposal", prep notes [A scope and shape](research/v1.47-prep/A-scope-and-shape.md), [B website](research/v1.47-prep/B-website-reskin.md), [C release and delivery](research/v1.47-prep/C-release-and-delivery.md), [D verification and cleanup](research/v1.47-prep/D-verification-and-cleanup.md); gap-pass notes [E adversarial review](research/v1.47-gap-pass/E-adversarial-review.md), [F autonomy stalls](research/v1.47-gap-pass/F-autonomy-stalls.md), [G website risk](research/v1.47-gap-pass/G-website-risk.md), [H wording and cleanup coupling](research/v1.47-gap-pass/H-wording-cleanup.md); the [glossary rulings](research/brand-and-catalog/V1.46-PREP.md) and the [brand adoption playbook](reference/BRAND-ADOPTION-PLAYBOOK.md). Where a prep note says "merge yes", "Draft PR" or places the Cancel-focus assertion on the nightly lane, the standing instruction (AGENTS.md, 2026-11-19) and this roadmap supersede it.

**Verification default:** no human UAT. Every success criterion below is proved by an executable check (static contract, computed style, DOM or LiveView test, request and hash assertion, or hosted CI at the exact head SHA) or is a recorded decision stated as such. Screenshots stay review artifacts and do not block. Nothing here claims aesthetic or independent-review approval, and each phase record carries a "what this does not prove" line (rendered quality, browsers other than Chromium, real screen readers).

**Guardrails (GATE-02, standing for every phase):** GATE-02 is mapped to Phase 189, where it is first exercised, and applies to every other phase. A second consecutive evidence-only plan forces a stop-and-decide (each phase has at most one); one full gate run per commit SHA; a stale receipt is a failed gate; no capture runs from a dirty tree; a fix to a snapshot-based gate is committed before the gate reruns. New required gates stay within the budget of 12 (8 used at the start of v1.47), each with a deletion trigger and expected churn recorded in the CONTRIBUTING ledger that `workflow_wiring_test` enforces.

**Delivery:** PR-first, non-draft PRs, no stacked PRs; each phase lands on `main` before the next phase's branch is cut from fresh `origin/main`. Green PRs are squash-merged under the standing rule, with one addition for Phase 189: merging to `main` deploys the website and `build-and-check` is not a required check, so that PR merges only after `build-and-check` is green on the exact head. Squash titles use `chore(...)` or `docs(...)`, not `feat` or `fix`. No preview refresh or `ui:review` runs in this milestone (`UI-PREVIEW.json` gets a one-line "stale since squash" note; the refresh is the first rendered-evidence phase of v1.48). At milestone close, one read-only cross-phase check of merged `main` at the final SHA runs before archive.

**Run book:** [RUN-V147.md](RUN-V147.md) is the one-paste orchestration (phase order, standing approvals, stop conditions, per-phase loop).

**Run notes for `gsd-autonomous`** (full table with citations in [F](research/v1.47-gap-pass/F-autonomy-stalls.md)): the workflow never opens or merges a PR, so run it one phase at a time (`--only N`), ship and squash-merge between phases, then run audit and complete after 191 (do not push the `v1.47` tag). Each phase gets a pre-seeded `CONTEXT.md` and `RESEARCH.md` built from the prep and gap-pass notes so smart-discuss does not ask neutral preference questions. Set `mode: yolo`, move the standing conditions out of STATE.md "Blockers/Concerns", and keep plans free of `<human-check>` blocks and `verification: backstop` truths (either routes the verifier to `human_needed` and halts the run). The four genuine maintainer decisions: changing branch protection, the picker fallback (approved by the maintainer on 2026-11-20 when they said to follow the recommendations: SITE-02's light-only fallback runs without pausing and is flagged in the handoff, so it is not a stop), `gaps_found` at the milestone audit, and choosing v1.48 or any Hex release.

## Phases

**Phase Numbering:**
- Integer phases (189, 190, 191): planned milestone work, continuing from v1.46 (ended at 188). Numbers are fixed: the `p189` allowlist tags already point at Phase 189.
- Decimal phase 188.1 (INSERTED): the CI path classifier, a plain PR that runs first so autonomous mode tracks it.

- [x] **Phase 188.1: CI path classifier (INSERTED)** - Planning-only and docs-only PRs skip the browser lanes, as an allowlist that fails open to running them (1 plan)
- [x] **Phase 189: Website re-skin** - Visitors see the website in the new identity, light by default with a Light/Dark/System picker, derived from the pinned brand files and proved before the merge that deploys it (3 plans)
- [x] **Phase 190: Wording that does not need the catalog** - Operators read screen copy that follows the recorded glossary rules and "Control room" casing, guarded by one data table the v1.48 copy lint can ingest (2 plans)
- [ ] **Phase 191: Cleanup** - The old identity's last code is gone: demo favicon swapped, `brandbook/` readers and data deleted, the allowlist empty, and cheap static invariants and tripwires keep it that way (2 plans)

<details>
<summary>✅ v1.46 Brand foundation and re-skin (Phases 186-188) — SHIPPED 2026-11-19</summary>

- [x] Phase 186: Ingest, pin and guard (3/3 plans) — completed 2026-11-19
- [x] Phase 187: ScrypathOps re-skin (11/11 plans) — completed 2026-11-19
- [x] Phase 188: README header and HexDocs (2/2 plans) — completed 2026-11-19
- Phases 189 (website re-skin) and 190 (wording that does not need the catalog) deferred to v1.47 by the maintainer on 2026-11-19.

</details>

## Phase Details

### Phase 188.1: CI path classifier (INSERTED)

**Goal**: A planning-only or docs-only PR no longer waits about 19 minutes for browser lanes it cannot affect, and a PR touching anything else still runs every lane.
**Depends on**: Nothing. Preferred before Phase 189 but not a blocker: if it slips, 189 proceeds and the classifier lands later.
**Requirements**: CI-01
**Research flags**: measured in [CI-EFFICIENCY.md](reference/CI-EFFICIENCY.md) finding 2 (about 19 minutes and 35 runner-minutes per docs-only PR). Dependabot #132 conflicts with Phase 189's `website.yml` edit, so land its SHA-pin relaxation here and merge it.
**Success Criteria** (what must be TRUE):
  1. The `ecommerce-path` classifier runs the browser lanes unless every changed path matches `^(\.planning/|docs/|[^/]+\.md$)`; a skipped required context still reports success. `workflow_wiring_test` fails a planted diff touching one non-allowlisted path that the classifier would skip, and accepts a `.planning`-only diff. (CI-01)
  2. `workflow_wiring_test` pins the `upload-artifact` action by pattern rather than a fixed SHA, #132 is merged green, and #129 is re-run on the re-skinned base and either merged green or left open with its real cause recorded. (CI-01)
  3. The change adds no required gate (8 of 12 unchanged) and is recorded in `CI-EFFICIENCY.md` with the measured before and after; the PR is a plain `chore(ci)` squash. (CI-01, GATE-02)
**Plans**: 1 expected (classifier, wiring test, #132 sequencing)

### Phase 189: Website re-skin

**Goal**: A visitor sees the website in the plum/orchid identity (palette, Hanken, Bricolage and Sometype Mono fonts, light and dark lockups and favicons, PNG social card), light by default with a remembered Light/Dark/System choice, everything derived from the pinned `brand/` files at build time and proved, including against the production URL shape, before and after the merge that deploys it.
**Depends on**: Phase 188.1 preferred first (not blocking). Starts from current `main`.
**Requirements**: SITE-01, SITE-02, SITE-03, SITE-04, SITE-05, SITE-06, GATE-02
**Research flags**: prep note B is the input, corrected by [G](research/v1.47-gap-pass/G-website-risk.md) and [E](research/v1.47-gap-pass/E-adversarial-review.md). Plan 189-01 verifies the items B left unverified: the install-time fix (`channel: 'chrome'` or cache, measured cold and warm), the CSP meta in Safari (stated limit, not asserted), the `.ico` contents, and copying the small WCAG function instead of importing `contrast-checker.mjs` across directories (preferred; assert its results against the ratios in `brand/brand.json`). Picker confidence is 0.6; the fallback is pre-decided in SITE-02.
**Success Criteria** (what must be TRUE):
  1. A dependency-free Node static contract, run through an ExUnit wrapper in `core` and `repository-contracts` and taking ledger row 9 of 12, builds the site into a temp directory and passes on `main`: every served font, OFL text, lockup, favicon and the social card is byte-identical to its `brand.pin.json` hash; generated theme variables equal `brand/tokens.json` for both themes through the build.mjs role map (which fails the build when a role resolves to nothing); no color literal in any file under `website/src` (css, html, js, svg); every hex in the built output belongs to the closed brand set (every hex in `brand/tokens.json`, plus every `text` and `background` hex in `brand.json` `color.contrastPairs`, plus the Control Edge sentence hex; see the phase record); no `href`, `src` or CSS `url()` is root-absolute; no reference to the unthemed `favicon.svg`; `og:image` and `twitter:image` are absolute PNG URLs whose width and height meta equal the PNG header; the CSP meta has no `unsafe-inline` or `*`; `font-display: swap`, a glyph allowlist and the three-face font set hold. Each planted failure (off-set hex, `rgba`, missing OFL file, changed font byte, inline script, root-absolute URL, dropped role) fails it, and `workflow_wiring_test` is green. (SITE-01, SITE-04)
  2. The rewritten `website/scripts/check.mjs` runs every page assertion at `http://127.0.0.1:<port>/scrypath/` (404 at `/`) and proves theme behavior: with JS off the page is light and the picker is not visible; with storage empty and a dark device the page computes the light page token; choosing Dark, Light and System changes the computed background and `aria-pressed`, survives a reload, and System follows the emulated scheme both ways; with storage blocked the page is light and the picker hidden; stored `dark` computes the dark background at `DOMContentLoaded`; `scroll-behavior` is `smooth` only without reduced motion and transitions compute 0 s under reduce; with `forcedColors: 'active'` one lockup shows and the pressed button differs by a non-color property; with print media and stored `dark` the body color equals the light ink. (SITE-02, SITE-04)
  3. The same check proves the identity renders: home loads exactly three same-origin `.woff2` files and every page loads a subset of the pinned set, each 200 with the pinned hash, computing to Bricolage, Hanken and Sometype Mono; exactly one lockup is visible per theme; every declared icon returns 200 with no request to a root `/favicon.ico`; contrast passes in both themes per `brand.json` pair id with its stated selector and background (including the primary button's `on-primary` pair in rest, hover and focus states), through a resolver tested on a planted translucent surface; no horizontal overflow at 320 px; the h1 and hero height differ by under a set tolerance with fonts blocked versus loaded; no console error, CSP violation or off-origin request. (SITE-01, SITE-04)
  4. In the same commit as the asset swap, the website's old palette (minus `d08e54`, `0c0f14` and `9aa4b6`, which the site contract asserts absent until Phase 191) is in the deny-set and both `p189` allowlist entries are gone with ceilings at 5 entries and 197 hits: `"tag": "p189"` returns nothing, the token test passes and fails a planted old website hex, and both website workflow filters list `brand/**`. (SITE-03, SITE-04)
  5. `gh api .../commits/<head>/check-runs` shows `build-and-check` successful for the exact PR head before the squash merge; the `deploy` job has its own concurrency group with `cancel-in-progress: false`, the post-merge `deploy` run is recorded green and its smoke step confirms the live font, lockup and social-card URLs under `/scrypath/`; rollback via `workflow_dispatch` with a `ref` is documented in `docs/releasing.md`; no `mix verify.*` string remains in website source (SITE-06), with `phase110` and `phase112` green; the non-required decision and its re-open trigger are recorded; the phase record shows one full gate run per commit SHA, no stale receipt, no capture from a dirty tree and a "what this does not prove" line. (SITE-05, SITE-06, GATE-02)
**Plans**: 3 expected. 189-01 guards and pipeline (static contract and its ledger row 9, `serve.mjs --base`, `check.mjs` rewrite, workflow filters, install fix, deploy smoke); 189-02 the atomic re-skin commit including the deny-set and allowlist change and the picker (fallback rule applies at the end of this plan); 189-03 closeout (playbook and CI-EFFICIENCY updates, exact-head evidence, upstream favicon issue draft). Only 189-03 is evidence-only.
**UI hint**: yes

### Phase 190: Wording that does not need the catalog

**Goal**: Operators read consistent ScrypathOps screen copy that follows the recorded glossary rules and sentence-case "Control room", each rule guarded by one data table in the required `ops-ui` job that the v1.48 copy lint can ingest unchanged.
**Depends on**: Phase 189 landed on `main` (no stacked PRs; no code dependency). 190 and 189 touch disjoint files, so 190 may be developed in parallel and merged in order of green, each rebased on fresh `main`.
**Requirements**: COPY-01, COPY-02, COPY-03, COPY-04
**Research flags**: [H](research/v1.47-gap-pass/H-wording-cleanup.md) holds the full coupling inventory: 54 occurrences of "Control Room" in 28 files, four exact-match Playwright sites that fail silently on the advisory lane, vacuous `refute` assertions, the strings the required-lane `operator.spec.ts` pins, and the string-by-string COPY-01 mapping table. Baseline: `ecommerce-e2e` was green on the 2026-11-20 nightly (run 44689855947, head `bd69905e`), but that run predates seven merges, so plan 190-01 dispatches `ci.yml` on current `main` first to get a clean baseline before attributing any later red to this phase. Plan 190-01 starts with the `GLOSSARY.md` status-wording block, then owner-visible wording choices are resolved in discuss.
**Success Criteria** (what must be TRUE):
  1. `GLOSSARY.md` carries the status-wording block, and LiveView and DOM tests prove each rule on the surfaces listed in the copy table: bare "Searchable" only for record or update state with an observation time; the settings row reads "Searchable fields: Used for search" or "Not used for search"; Pending names a row or schema aggregate and Queued one update's step or the host-queue outcome; "Retry queued" for the host queue and "accepted" only for a Meilisearch task; "Last succeeded" replaces every "Last successful" and "Last success" variant; every string `operator.spec.ts` pins is unchanged. Surfaces the table does not cover (JS strings, some attributes) are listed as not covered. (COPY-01)
  2. "Control room" is sentence case in page titles, navigation, headings and the return link; the case-sensitive scan of every tracked file outside `.planning/` and `brand/` finds no `Control Room`; the four exact-match Playwright sites are updated; a LiveView test proves `aria-current="page"` and the title on the Control room route. (COPY-02)
  3. `copy_rules.json` holds the rows, one `ops-ui` ExUnit test scans and renders them, a planted forbidden string in a scoped file and on a rendered surface each fail it, a row missing a field fails it, every old `refute` of a renamed string has become a refute-old plus assert-new on the same fixture, the `ops-ui` path regex and `workflow_wiring_test` cover the scanned paths, and the CONTRIBUTING ledger row and budget line are consistent. (COPY-03)
  4. `operator.spec.ts` asserts Cancel is focused when the promotion dialog opens; ExUnit pins the `ops_modal` default focus selector, each destructive `ops_modal` and each promotion-notice sentence; `page_controller_test.exs` passes locally and `ci.yml` dispatched on the exact PR head shows `ecommerce-e2e` green, with both run ids recorded. No preview capture or `ui:review` runs, and the phase record says no design pass was done. (COPY-04)
**Plans**: 2 expected. 190-01 glossary, rename and wording changes, copy table and guards, vacuous-assertion repairs; 190-02 Cancel-focus and pins, path-regex and ledger changes, exact-head dispatch evidence. Neither is evidence-only.
**UI hint**: yes

### Phase 191: Cleanup

**Goal**: The old identity's last code is gone and stays gone: the demo favicon is the pinned light favicon, the `brandbook/` readers and data are deleted with the allowlist ending empty, cheap static invariants and an unthemed-favicon tripwire guard what the re-skin promised, and `brand/tokens.json` is the named single token authority.
**Depends on**: Phase 190 landed on `main`, and Phase 189's removal of the two `p189` allowlist entries (so the allowlist can end empty here).
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04, CLEAN-05, CLEAN-06
**Order inside the phase** (prep note D, ceilings corrected by [H](research/v1.47-gap-pass/H-wording-cleanup.md)): demo favicon (5/197 to 4/194), then the readers (to 2/178), then the data (to 0/0), with the allowlist entries and both ceilings moving in the same commit as each deletion; recompute from merged `main`. Run the cheap focused checks before each commit, then `mix verify.repository_contracts` once on each committed state (it clones HEAD). The CLEAN-04 tests and the `@min_token_test_calls` floor raise are one commit; CLEAN-06 lands in or after the commit that empties the allowlist.
**Success Criteria** (what must be TRUE):
  1. A root-level test in `core` proves the demo favicon is byte-identical to `brand/assets/icon/favicon-light.svg`, and its allowlist entry is removed. (CLEAN-01)
  2. `ui_tokens.ex`, its contract test, the `verify.phase99` entry and the `verify.ui_tokens` `preferred_envs` line are gone, a scan finds no remaining reader of `brandbook/`, and `mix verify.repository_contracts` passes on the committed state; the plan records which deleted assertion maps to which surviving one, or accepts the hosted exact-head run as the replacement for the lost clean-clone baseline. (CLEAN-02)
  3. `brandbook/` and its `ci.yml` regex entry are deleted in the same commit as their allowlist entries and ceilings, the allowlist ends at zero entries and zero hits, the three shared hexes join the deny set, and the kept deny-list and `RETIRED_DIR` tripwire still fail a planted retired value and a planted retired path; Phase 191 docs never spell that path. (CLEAN-03)
  4. The 12 px floor, arbitrary-size, `uppercase`, `infinite` and `size: :xs` invariants each fail a planted case and accept their valid cases on ops-authored source only; no required gate is added; the floor count and test names rise with them; the docs say these are source checks, not rendered-size proof. (CLEAN-04)
  5. The unthemed-favicon tripwire and the consumer scan (path and bytes) pass on `main` and fail their planted cases, the upstream report draft is in the phase record, the CONTRIBUTING ledger is reworded as CLEAN-06 states with `brand/tokens.json` named as the single token authority, and `workflow_wiring_test` stays green. (CLEAN-05, CLEAN-06)
**Plans**: 2 expected. 191-01 the deletion chain with docs; 191-02 the static invariants, tripwire, scan and ledger rewording. Neither is evidence-only.

## Progress

**Execution Order:** 188.1 (plain PR), then 189, 190, 191.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 188.1. CI path classifier | 1/1 | Complete | 2026-11-20 |
| 189. Website re-skin | 3/3 | Complete | 2026-11-20 |
| 190. Wording that does not need the catalog | 2/2 | Complete | 2026-11-20 |
| 191. Cleanup | 0/2 | Not started | - |
