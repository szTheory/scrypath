# Requirements: Scrypath v1.47 Brand completion

**Defined:** 2026-11-20
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

Scope source: the prepared v1.47 input (`research/v1.47-prep/` notes A to D, `reference/ROLLING-ROADMAP.md` "Post-v1.46 proposal"), carried over from the Phases 189 and 190 deferred out of v1.46. Every criterion is an executable check; nothing here claims aesthetic or independent-review approval.

## v1 Requirements

### Website (Phase 189)

- [ ] **SITE-01**: A visitor sees the website in the new identity: palette, Hanken/Bricolage/Sometype Mono fonts with their OFL texts served, the light and dark lockups, the light and dark favicons and the social card. All of it is derived or copied at build time from the pinned `brand/` files; no hex literal or retired asset remains in website source, and the unthemed `favicon.svg` is not used.
- [ ] **SITE-02**: The website is light by default and offers a Light, Dark and System picker that remembers the choice; System follows the device setting. `scroll-behavior: smooth` applies only under `prefers-reduced-motion: no-preference`.
- [ ] **SITE-03**: The website's old palette is added to the retired-value deny-set in the same commit as the asset swap, the two `p189` allowlist entries are removed, and the deny-list reports no retired value in website source.
- [ ] **SITE-04**: `website/check.mjs` asserts computed styles, served font-file hashes and contrast pairs for both themes (replacing the capture-only script), and a dependency-free static contract for the website runs in `core` and `repository-contracts`. `brand/**` is added to the website workflow path filter.
- [ ] **SITE-05**: Because merging to `main` deploys, the website `build-and-check` job is green on the exact PR head before merge, and the plan records whether that job becomes required gate 9 of 12 (with its deletion trigger and expected churn if it does).

### Wording that does not need the catalog (Phase 190)

- [ ] **COPY-01**: Screen copy follows the recorded glossary rules: bare "Searchable" only for record or update state with an observation time, the settings row reads "Searchable fields: Used for search or Not used for search", Pending versus Queued per the rule, "Retry queued" for the host queue and "accepted" only for a Meilisearch task, and "Last succeeded" everywhere.
- [ ] **COPY-02**: The "Control room" label uses the agreed sentence casing everywhere it is rendered, including titles, navigation and tests.
- [ ] **COPY-03**: The COPY-01 and COPY-02 guards are a data table (rule, forbidden and required text, surfaces) inside the required `ops-ui` job, in a shape the v1.48 copy lint can ingest without rewriting.
- [ ] **COPY-04**: A browser assertion proves Cancel is focused when a destructive dialog opens, and the promotion-notice body copy and the `ops_modal` default-focus selector are pinned by tests.

### Cleanup (Phase 191)

- [ ] **CLEAN-01**: The demo favicon is a byte copy of `brand/assets/icon/favicon-light.svg`, pinned by a root-level test that can read `brand/`, and its allowlist entry is removed.
- [ ] **CLEAN-02**: The `brandbook/` readers are gone (`ui_tokens.ex`, its contract test, the `verify.phase99` entry and the `verify.ui_tokens` mix alias) with `mix verify.repository_contracts` green on the committed state.
- [ ] **CLEAN-03**: `brandbook/`, its `ci.yml` path-regex entry and its allowlist entries are removed in the same commit as their ratchet ceilings (7 entries and 201 hits today; the two `p189` entries go in Phase 189, so the allowlist ends empty), with the deny-list and `RETIRED_DIR` tripwire kept.
- [ ] **CLEAN-04**: Static invariants in the existing token test cover the 12 px font-size floor, no arbitrary text sizes, no `uppercase` and no `infinite` in ops-authored source; each has a planted failing case and an accept case, adds no new gate, and the docs say these are source checks, not rendered-size proof.
- [ ] **CLEAN-05**: A tripwire test proves the pinned `brand/assets/icon/favicon.svg` is still unthemed and a scan proves nothing outside `brand/` uses it; the defect is reported upstream.
- [ ] **CLEAN-06**: The CONTRIBUTING ledger triggers for the token and deny-list row are reworded now that their literal conditions are met, and `brand/tokens.json` is named as the single token authority.

### Standing guardrails

- [ ] **GATE-02**: Each phase honors the guardrails: a second consecutive evidence-only plan forces a stop-and-decide, one full gate runs per commit SHA, a stale receipt is a failed gate, and no capture runs from a dirty tree. New required gates stay within the budget of 12 (8 used), each with a deletion trigger and expected churn.

## v2 Requirements

Deferred to later milestones; not in this roadmap.

- **CAT-01**: phoenix_storybook catalog foundation, fixtures, the JOB-03 read-only and retry pilot halves (v1.48, Phases 192-196).
- **SCRN-01**: Search (JOB-05), Sync and index, Help, shell and job stories, type-scale reflow, per-area parity checks (v1.49).
- **ADOPT-01**: Adopter features: testing kit, indexable predicate, highlighting passthrough, hit and facet limits, backfill and reindex tasks (v1.50, grill the API shapes first).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Kickoff CI chore (`ecommerce-path` classifier) | A small CI PR before Phase 189, tracked in `reference/CI-EFFICIENCY.md`, not a roadmap phase; it must not skip when `brand/`, `scrypath_ops/`, `examples/`, `scripts/ci/`, `lib/`, `mix.exs` or workflow files change |
| Promoting a browser computed-style spec to a required lane | One observed hole does not justify gate 9; revisit if a regression only a browser spec would catch reaches `main` |
| Ops theme default change or Bricolage in ops | Settled in v1.46: ops stays System-default, no type-scale reflow |
| Catalog, storybook, fixtures | v1.48 |
| Hex release | The maintainer's separate explicit yes; no library change is planned |
| Aesthetic or independent-review approval claims | No person or independent reviewer is simulated |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 0
- Unmapped: 16 ⚠️

---
*Requirements defined: 2026-11-20*
*Last updated: 2026-11-20 after initial definition*
