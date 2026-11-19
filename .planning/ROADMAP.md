# Roadmap: Scrypath

## Milestones

- 🚧 **v1.46 Brand foundation and re-skin** — Phases 186–190 (in progress; 189 and 190 deferrable to v1.47)
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

v1.46 Brand foundation and re-skin is the active milestone; the project is no longer awaiting a next milestone. Requirements are defined and this roadmap maps all 29 to Phases 186–190. No phase has started; the next step is discussing Phase 186.

v1.44 and v1.45 landed on main (PRs #123, #124, #126) and `scrypath` 0.3.18 is released. The v1.45 archive keeps its documented debt and historical verification overrides. `deep-quality` stays an advisory red with one known cause (cloak and cloak_ecto via optional sigra) until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed. The retained UI preview is stale and is refreshed before visible UI work (GATE-03 in Phase 187). Hex releases and the Phase 187 merge each wait for the maintainer's explicit yes.

## v1.46 Brand foundation and re-skin

**Milestone goal:** Adopt the plum/orchid scry/path brand book across ScrypathOps, the README and HexDocs, and the website, changing colors, font families, logo, favicon and status vocabulary without reflowing type sizes or adding new interactions.

**Inputs:** [REQUIREMENTS.md](REQUIREMENTS.md), [V1.46-PREP.md](research/brand-and-catalog/V1.46-PREP.md) (authoritative where it differs from [PROPOSAL.md](research/brand-and-catalog/PROPOSAL.md)), [brand adoption playbook](reference/BRAND-ADOPTION-PLAYBOOK.md).

**Verification default:** no human UAT. Every success criterion below is proved by an executable check (computed style, DOM, contract test, or hosted CI at the exact head SHA). Rendered captures are review context and do not block. Nothing here claims aesthetic or independent-review approval.

**Guardrails (GATE-02, standing for every phase):** a second consecutive evidence-only plan forces a stop-and-decide; evidence-only phases stay at or below 2 plans (Phase 186 at most 3); one full gate run per commit SHA; a stale receipt is a failed gate; no capture runs from a dirty tree. At most 12 new required gates across the milestone, each with a deletion trigger and expected churn per UI PR.

**Delivery:** PR-first, no stacked PRs. Each phase lands on main before the next phase's PR opens.

## Phases

**Phase Numbering:**
- Integer phases (186, 187, ...): planned milestone work, continuing from v1.45 (ended at 185)
- Decimal phases (186.1, ...): urgent insertions (marked with INSERTED)

- [ ] **Phase 186: Ingest, pin and guard** - Pin the adopted brand assets offline, add one token-parity and retired-value test, lift the pinned old-identity literals, and make the recolor tolerable to existing checks (test and evidence only, at most 3 plans)
- [ ] **Phase 187: ScrypathOps re-skin** - Operators see ScrypathOps in the new identity in light and dark with one status vocabulary, delivered as one Draft PR
- [ ] **Phase 188: README header and HexDocs** - Readers see the brand header, logo, favicon and corrected stylesheet on GitHub and HexDocs
- [ ] **Phase 189: Website re-skin** (deferrable to v1.47) - Visitors see the website in the new identity, verified before the merge that deploys it
- [ ] **Phase 190: Wording that does not need the catalog** (deferrable to v1.47) - Screen copy follows the recorded glossary rules, each guarded by a copy test

## Phase Details

### Phase 186: Ingest, pin and guard
**Goal**: Maintainers can prove the committed brand assets are exactly the pinned ones and that retired identity values cannot re-enter the repository, and the existing contract tests read live tokens so the Phase 187 recolor fails only on what Phase 187 owns.
**Depends on**: Nothing within v1.46; starts from current main (v1.44, v1.45 and the Step 0b dependency and CI fixes landed; 0.3.18 released).
**Requirements**: PIN-01, PIN-02, PIN-03, TOK-01, TOK-02, TOK-03, TOK-04, GATE-01, GATE-02
**Success Criteria** (what must be TRUE):
  1. The offline brand verify passes on a clean checkout and blocks merging when a test adds an unpinned file to `brand/` or the ops fonts directory or changes one byte of a pinned asset; the update task refuses tampered size, hash, entry-count and uncompressed-size inputs in tests and writes only allowlisted members; `brand/` holds only the adopted assets (about 330 KB, no PDFs, HTML books, motion, sounds, previews or TTFs) and the Hex package file list contains no `brand/` or `brandbook/` path. (PIN-01, PIN-02, PIN-03)
  2. One Node token test, run by an existing required step, passes on main and fails each of its six planted sabotage cases (including a missing token row, an orphan row, a resolved-hex mismatch, stale built CSS, a retired hex or rgb triplet, and a stale allowlist entry) while accepting the valid fixtures. (TOK-01, TOK-02)
  3. The about 12 pinned old-identity literals are gone from the three root and ops contract tests, which now assert token relationships through a resolved-token helper, landed in at most 3 test-only commits; the recolor dry-run projection after those commits shows no failing test outside Phase 187's scope (otherwise the phase stops and re-plans). (TOK-03)
  4. The Phase 185 preservation specs still fail on copy, geometry, state, action and identity changes, and the replacement structural check accepts its calibrated recolor case and rejects its calibrated regression case. (TOK-04)
  5. `ops-ui (path-scoped)` is a required check asserted by the workflow-wiring test with its path list covering `brand/`, `language/` and `fixtures/`, the static storybook-boundary checks run in a required job, every new required gate records its deletion trigger and churn within the budget of 12, and the phase closes in at most 3 plans with one full gate run per commit SHA. (GATE-01, GATE-02; GATE-02 is first satisfied here and stays a standing rule for later phases)
**Plans**: TBD (at most 3)

### Phase 187: ScrypathOps re-skin
**Goal**: Operators see ScrypathOps in the plum/orchid identity in light and dark with one consistent sync-status vocabulary, hosts that mount it see no change outside ops, and the maintainer receives it as one Draft PR with green gates and capture inventory, merged only on the maintainer's yes.
**Depends on**: Phase 186 (pin, token test and lifted literals on main)
**Requirements**: SKIN-01, SKIN-02, SKIN-03, SKIN-04, SKIN-05, SKIN-06, SKIN-07, SKIN-08, STAT-01, STAT-02, STAT-03, A11Y-01, A11Y-02, A11Y-03, A11Y-04, GATE-03
**Success Criteria** (what must be TRUE):
  1. Computed-style and request checks in light, dark and System show the brand theme roles with no `primary-strong`, copper or glow tokens; Hanken Grotesk and Sometype Mono load with status 200 from the mount prefix at two nesting depths with content-hash `?v=` values; the h1 is Hanken 700 at 28 px, the minimum text size is 12 px, nothing computes to `uppercase`, exactly one brand lockup shows per theme at a legible size at 320 px, and the brand favicon replaces the stub; the deny-list and grep gates find no retired path, copper, glow or infinite-animation code in ops, and every transition duration is a brand motion token. (SKIN-01, SKIN-02, SKIN-03, SKIN-05, SKIN-06)
  2. On Failed sync work and Search health, every sync status renders through `ops_sync_status` with a word in {Failed, Retrying, Pending, Clear}, a matching `aria-hidden` icon shape and the token word color; "Not observed", "Not checked" and "Queue not used" render as muted words with no icon; "Clear" appears only with an observation; notices use Panel plus a 2 px rule; Search health rows sort Failed, Retrying, Pending, Clear, then name; the promotion prefix and the `inspect(reason)` leak are fixed, each proved by LiveView or DOM tests. (STAT-01, STAT-02, STAT-03, SKIN-07)
  3. DOM checks find at most one visible, non-inert Plum button per page and per open dialog and no `.btn-error`; destructive confirms name the consequence in the label and open with Cancel focused; row actions share one computed style with at least a 24 px target; prose links are underlined at rest. (SKIN-04)
  4. The extended contrast checker, reading the stylesheet's custom properties, passes every text role at 4.5:1 or better on page, panel, sunken and selected backdrops in both themes and the control edge at 3:1 or better, with no alpha on text and a 2 px inline-start rule on the selected row; the focus ring is a 2 px solid Plum or Orchid ring that stays inside the scrollport of `.ops-table-scroll`; a tab-through keeps the focused element at least 64 px below the viewport top; `getAnimations()` finds no infinite animation and reduced motion is honored. (A11Y-01, A11Y-02, A11Y-03)
  5. A fixture host in light, dark and System shows no computed-style change on its sentinel element off ops routes, a host accent override still wins, a CSP of `font-src 'self'` still loads the fonts, and the unscoped-selector ratchet passes; the retained preview is refreshed to post-merge main with preflight passing and preview data intact before captures; one Draft PR is open with every automated gate green at the exact head SHA, light and dark before and after captures of Control room, Search health and Failed sync work at 390 and 1280 px, and a plain list of what the gates prove and do not prove, with no aesthetic or independent-review claim. (A11Y-04, GATE-03, SKIN-08)
**Plans**: TBD
**UI hint**: yes

### Phase 188: README header and HexDocs
**Goal**: A reader sees the new brand header, logo and favicon in the README on GitHub and on HexDocs, with code blocks in brand colors that follow ExDoc's own theme toggle.
**Depends on**: Phase 186 (pinned `brand/` assets). Sequenced after Phase 187's PR lands on main (no stacked PRs).
**Requirements**: BDOC-01, BDOC-02
**Success Criteria** (what must be TRUE):
  1. One real `mix docs` build produces a `readme.html` whose header images use `brand/assets/readme/...` paths, and every `src` and `srcset` in the built docs resolves to a file in the output; the same relative paths resolve to committed files for the GitHub README. (BDOC-01)
  2. The built docs contain no `brandbook/` reference. (BDOC-01)
  3. The built docs head links the brand stylesheet after ExDoc's, the brand favicon and the brand logo from `doc/assets/`; the stylesheet prefixes every color rule with `body ` and `body.dark `, has no `prefers-color-scheme` block, and the contract test asserts the code-block colors. (BDOC-02)
**Plans**: TBD
**UI hint**: yes

### Phase 189: Website re-skin
**Deferrable**: yes, to v1.47 (see Deferral of Phases 189 and 190)
**Goal**: A visitor sees the website in the new identity (palette, fonts including Bricolage, logo, favicon, light default), proved before the merge because merging to main deploys it.
**Depends on**: Phase 186 (pinned assets and deny-list). Sequenced after Phase 188 lands (no stacked PRs).
**Requirements**: SITE-01
**Success Criteria** (what must be TRUE):
  1. The website build check asserts the brand palette, the three brand fonts served from the site, the brand logo and favicon, and light as the default theme.
  2. The deny-list scan reports no retired identity value in website assets, and every deny-list allowlist entry tagged for the website is removed.
  3. The website build-and-check job passes on the exact PR head before the merge that deploys the site.
**Plans**: TBD
**UI hint**: yes

### Phase 190: Wording that does not need the catalog
**Deferrable**: yes, to v1.47 (see Deferral of Phases 189 and 190)
**Goal**: Operators read consistent screen copy that follows the glossary rules recorded in the prep, each rule guarded by a copy test.
**Depends on**: Phase 187 (status component and re-skinned screens on main)
**Requirements**: COPY-01
**Success Criteria** (what must be TRUE):
  1. Copy tests prove bare "Searchable" appears only for a record or update state shown with an observation time, and the settings row reads "Searchable fields: Used for search" or "Not used for search".
  2. Copy tests prove Pending labels row and schema aggregates while Queued labels a single update's step and the host-queue outcome.
  3. Copy tests prove "Retry queued" is used for the host queue, "accepted" only for a Meilisearch task, and "Last succeeded" everywhere a last-success time appears.
**Plans**: TBD
**UI hint**: yes

## Deferral of Phases 189 and 190

Phases 189 and 190 move to v1.47 if v1.46 runs long. This is a scope call by the maintainer, not an automatic action, and it is raised at the Phase 188 boundary or earlier when either of these happens:

- Phase 187 needed a re-plan, or the GATE-02 progress guard forced a stop-and-decide in Phase 186 or 187.
- Phase 187's Draft PR is still waiting on fixes or the merge yes when Phase 188 completes, so starting 189 or 190 would stack work behind an unmerged PR.

On deferral: SITE-01 and COPY-01 move to the v1.47 requirements and the traceability table is updated; website entries in the deny-list allowlist keep their entries with the phase tag retargeted to the v1.47 phase (the shrink-only rule still applies); v1.46 closes after Phase 188. Phase 190 is independent of 189 and can stay in v1.46 alone if only the website is deferred.

## Out of scope for v1.46

Type-scale reflow, master-detail Search health and the progress line, sounds, logo animation, bulk retry, fully scoped `.ops-root` isolation, Bricolage in ops, light default for ops, the "Control room" sentence-case rename (v1.47 wording), and the online brand re-download check in CI. See the Out of Scope table in [REQUIREMENTS.md](REQUIREMENTS.md).

## Progress

**Execution Order:** 186 → 187 → 188 → 189 → 190 (189 and 190 deferrable)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 186. Ingest, pin and guard | v1.46 | 0/TBD | Not started | - |
| 187. ScrypathOps re-skin | v1.46 | 0/TBD | Not started | - |
| 188. README header and HexDocs | v1.46 | 0/TBD | Not started | - |
| 189. Website re-skin | v1.46 (deferrable) | 0/TBD | Not started | - |
| 190. Wording that does not need the catalog | v1.46 (deferrable) | 0/TBD | Not started | - |
