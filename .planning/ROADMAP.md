# Roadmap: Scrypath

## Milestones

- 🚧 **v1.47 Brand completion** — Phases 189–191 (active; 3 phases, about 5 to 7 plans; website re-skin, catalog-free wording, old-identity cleanup)
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

v1.47 Brand completion is the active milestone. Requirements are defined and this roadmap maps all 16 to Phases 189–191. No phase has started. The first step is the kickoff CI chore (below, not a phase), then discussing Phase 189. v1.46 is complete and on `main`; its [audit](milestones/v1.46-MILESTONE-AUDIT.md) is `tech_debt` with no unsatisfied requirement. Hex 0.3.19 (2026-11-20) shipped the README and HexDocs branding; no library change is planned in v1.47, and any Hex release stays the maintainer's separate explicit yes.

`deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## v1.47 Brand completion

**Milestone goal:** Finish the brand adoption v1.46 started: the website in the new identity, the wording fixes that do not need the catalog, and removal of the old identity's last code, so v1.48 (Catalog foundation) starts from a clean base.

**Inputs:** [REQUIREMENTS.md](REQUIREMENTS.md), [ROLLING-ROADMAP.md](reference/ROLLING-ROADMAP.md) "Post-v1.46 proposal", prep notes [A scope and shape](research/v1.47-prep/A-scope-and-shape.md), [B website](research/v1.47-prep/B-website-reskin.md), [C release and delivery](research/v1.47-prep/C-release-and-delivery.md), [D verification and cleanup](research/v1.47-prep/D-verification-and-cleanup.md), and the [brand adoption playbook](reference/BRAND-ADOPTION-PLAYBOOK.md).

**Verification default:** no human UAT. Every success criterion below is proved by an executable check (static contract, computed style, DOM or LiveView test, request and hash assertion, or hosted CI at the exact head SHA). Screenshots stay review artifacts and do not block. Nothing here claims aesthetic or independent-review approval.

**Guardrails (GATE-02, standing for every phase):** GATE-02 is mapped to Phase 189, where it is first exercised, and applies to Phases 190 and 191 as well. A second consecutive evidence-only plan forces a stop-and-decide; one full gate run per commit SHA; a stale receipt is a failed gate; no capture runs from a dirty tree. New required gates stay within the budget of 12 (8 used at the start of v1.47), each with a deletion trigger and expected churn recorded in the CONTRIBUTING ledger that `workflow_wiring_test` enforces.

**Delivery:** PR-first, no stacked PRs; each phase lands on `main` before the next phase's PR opens. Green PRs are squash-merged under the standing rule, with one addition for Phase 189: merging to `main` deploys the website and `build-and-check` is not a required check, so that PR merges only after `build-and-check` is green on the exact head.

**Kickoff chore (not a phase):** before Phase 189, a small plain CI PR adds an `ecommerce-path` classifier so planning-only and docs-only PRs skip the browser lanes while the required contexts still report (finding 2 in [CI-EFFICIENCY.md](reference/CI-EFFICIENCY.md)). It must not skip when `brand/`, `scrypath_ops/`, `examples/`, `scripts/ci/`, `lib/`, `mix.exs` or workflow files change. It carries no requirement ID and is tracked in the CI ledger, not here.

## Phases

**Phase Numbering:**
- Integer phases (189, 190, 191): planned milestone work, continuing from v1.46 (ended at 188). Numbers are fixed: the `p189` allowlist tags already point at Phase 189.
- Decimal phases (189.1, ...): urgent insertions (marked with INSERTED)

- [ ] **Phase 189: Website re-skin** - Visitors see the website in the new identity, light by default with a Light/Dark/System picker, derived from the pinned brand files and proved before the merge that deploys it (2-3 plans)
- [ ] **Phase 190: Wording that does not need the catalog** - Operators read screen copy that follows the recorded glossary rules and "Control room" casing, guarded by a data table the v1.48 copy lint can ingest (1-2 plans)
- [ ] **Phase 191: Cleanup** - The old identity's last code is gone: demo favicon swapped, `brandbook/` readers and data deleted, the allowlist empty, and cheap static invariants and tripwires keep it that way (1-2 plans)

<details>
<summary>✅ v1.46 Brand foundation and re-skin (Phases 186-188) — SHIPPED 2026-11-19</summary>

- [x] Phase 186: Ingest, pin and guard (3/3 plans) — completed 2026-11-19
- [x] Phase 187: ScrypathOps re-skin (11/11 plans) — completed 2026-11-19
- [x] Phase 188: README header and HexDocs (2/2 plans) — completed 2026-11-19
- Phases 189 (website re-skin) and 190 (wording that does not need the catalog) deferred to v1.47 by the maintainer on 2026-11-19.

</details>

## Phase Details

### Phase 189: Website re-skin

**Goal**: A visitor sees the website in the plum/orchid identity (palette, Hanken, Bricolage and Sometype Mono fonts, light and dark lockups and favicons, PNG social card), light by default with a remembered Light/Dark/System choice, everything derived from the pinned `brand/` files at build time and proved before the merge that deploys it.
**Depends on**: The kickoff CI chore merged (not a phase). Nothing else within v1.47; starts from current `main` (v1.46 and Hex 0.3.19 landed).
**Requirements**: SITE-01, SITE-02, SITE-03, SITE-04, SITE-05, GATE-02
**Research flags**: prep note B is the input. Unverified there: the browser-install speedup, the CSP meta in Safari, the `.ico` contents and the cross-directory import of `contrast-checker.mjs` from `website/` (copy the small WCAG function instead if the import is awkward). Picker confidence is 0.6; the recorded fallback is light-only (drop the picker, script and dark tokens).
**Success Criteria** (what must be TRUE):
  1. A dependency-free Node static contract, run through an ExUnit wrapper in `core` and `repository-contracts`, builds the site into a temp directory and passes on `main`: every served font, OFL text, lockup, light and dark favicon and the social card is byte-identical to its `brand.pin.json` hash; the generated theme variables equal `brand/tokens.json` for both themes; website source holds no color literal and every hex in the built output belongs to the brand token set; no file references the unthemed `favicon.svg`. Each planted failure (an off-set hex, an `rgba`, a missing OFL file, a changed font byte, an inline script) makes it fail. (SITE-01, SITE-04)
  2. The rewritten `check.mjs` browser check proves the theme behavior on every page: with empty storage and a dark device the page computes the light page token; choosing Dark, Light and System changes the computed background and `aria-pressed`, survives a reload, and System follows the emulated scheme both ways; with storage blocked the page renders light; `scroll-behavior` computes `smooth` only with `prefers-reduced-motion: no-preference` and `auto` under reduce. (SITE-02)
  3. The same browser check proves the identity renders: exactly three same-origin `.woff2` responses return 200 with the pinned hashes and the h1, body and code compute to Bricolage, Hanken and Sometype Mono; exactly one lockup is visible per theme; both favicon links and the `.ico` return 200; the contrast table passes in light and dark and the body and link pairs match the ratios published in `brand/brand.json`; no console error, CSP violation or off-origin request occurs. (SITE-01, SITE-04)
  4. In the same commit as the asset swap, the website's old palette is in the deny-set and both `p189` allowlist entries are gone with the ceilings lowered in lockstep: a grep for `"tag": "p189"` returns nothing, the token test passes on the final commit and fails a planted old website hex, and `website.yml` lists `brand/**` in its path filter. (SITE-03, SITE-04)
  5. `build-and-check` is recorded green for the exact PR head SHA before the squash merge; the phase records whether that job becomes required gate 9 of 12 and, if it does, its deletion trigger and expected churn in the CONTRIBUTING ledger with `workflow_wiring_test` green; the phase verification shows one full gate run per commit SHA, no stale receipt and no capture from a dirty tree. (SITE-05, GATE-02; GATE-02 stays a standing rule for Phases 190 and 191)
**Plans**: TBD (2-3 expected: guards and build pipeline; the atomic re-skin commit; closeout with ledger, playbook and exact-head evidence)
**UI hint**: yes

### Phase 190: Wording that does not need the catalog

**Goal**: Operators read consistent ScrypathOps screen copy that follows the recorded glossary rules and the agreed "Control room" casing, each rule guarded by a data-table check in the required `ops-ui` job that the v1.48 copy lint can ingest unchanged.
**Depends on**: Phase 189 landed on `main` (no stacked PRs; no code dependency). Phase 187's status component and re-skinned screens are already on `main`.
**Requirements**: COPY-01, COPY-02, COPY-03, COPY-04
**Research flags**: re-count at planning the advisory e2e specs that pin old casing or wording (prep note A counted none by exact grep; V1.46-PREP counted five). Those specs run only on schedule or dispatch, so a green required lane will not notice a stale one.
**Success Criteria** (what must be TRUE):
  1. LiveView and DOM tests prove the glossary rules on every rendered surface: bare "Searchable" appears only for a record or update state shown with an observation time; the settings row reads "Searchable fields: Used for search" or "Not used for search"; Pending and Queued follow the recorded rule; the host queue reads "Retry queued" and "accepted" appears only for a Meilisearch task; "Last succeeded" replaces every "Last successful" variant. (COPY-01)
  2. "Control room" renders in the agreed sentence casing in page titles, navigation and headings, and a scan of ops source, ops tests, the ecommerce tests and e2e specs finds no other casing of the label. (COPY-02)
  3. The COPY-01 and COPY-02 guards live in one data table (rule, forbidden text, required text, surfaces) asserted inside the required `ops-ui` job; a planted forbidden string on a listed surface fails it, and the table's shape is documented as the v1.48 copy-lint input. (COPY-03)
  4. A browser assertion proves Cancel holds focus when a destructive dialog opens, and tests pin the promotion-notice body copy and the `ops_modal` default-focus selector; one local run of the ordinary e2e partition on the final commit passes with the new wording. (COPY-04)
**Plans**: TBD (1-2 expected)
**UI hint**: yes

### Phase 191: Cleanup

**Goal**: The old identity's last code is gone and stays gone: the demo favicon is the pinned light favicon, the `brandbook/` readers and data are deleted with the allowlist ending empty, cheap static invariants and an unthemed-favicon tripwire guard what the re-skin promised, and `brand/tokens.json` is the named single token authority.
**Depends on**: Phase 190 landed on `main`, and Phase 189's removal of the two `p189` allowlist entries (so the allowlist can end empty here).
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04, CLEAN-05, CLEAN-06
**Order inside the phase** (prep note D): demo favicon, then the readers, then the data, with the allowlist entries and both ceilings moving in the same commit as each deletion. Run the cheap focused checks before each commit, then `mix verify.repository_contracts` once on each committed state (it snapshots HEAD).
**Success Criteria** (what must be TRUE):
  1. The demo favicon is byte-identical to `brand/assets/icon/favicon-light.svg`, pinned by a root-level test that reads `brand/`, and its allowlist entry is removed. (CLEAN-01)
  2. `ui_tokens.ex`, its contract test, the `verify.phase99` entry and the `verify.ui_tokens` mix alias are gone, a scan finds no remaining reader of `brandbook/`, and `mix verify.repository_contracts` passes on the committed state. (CLEAN-02)
  3. `brandbook/` and its `ci.yml` path-regex entry are deleted in the same commit as their allowlist entries and ceilings, the allowlist ends with zero entries and zero hits, and the kept deny-list and `RETIRED_DIR` tripwire still fail a planted retired value and a planted `brandbook` path. (CLEAN-03)
  4. The existing token test asserts the 12 px font-size floor, no arbitrary text sizes, no `uppercase` and no `infinite` in ops-authored source; each invariant fails its planted case and accepts its valid case, no required gate is added, and the docs say these are source checks, not rendered-size proof. (CLEAN-04)
  5. A tripwire test fails if the pinned `brand/assets/icon/favicon.svg` gains a theme, a scan finds no use of it outside `brand/`, and the upstream report is linked from the phase record; the CONTRIBUTING ledger triggers for the token and deny-list row are reworded with `brand/tokens.json` named as the single token authority, and `workflow_wiring_test` stays green. (CLEAN-05, CLEAN-06)
**Plans**: TBD (1-2 expected: the deletion chain with docs; the static invariants and tripwire)

## Progress

**Execution Order:** kickoff CI chore (not a phase), then 189, 190, 191.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 189. Website re-skin | 0/TBD | Not started | - |
| 190. Wording that does not need the catalog | 0/TBD | Not started | - |
| 191. Cleanup | 0/TBD | Not started | - |
