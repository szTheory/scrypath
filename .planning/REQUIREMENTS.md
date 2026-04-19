# Requirements: Scrypath v1.6

**Defined:** 2026-04-18  
**Milestone:** v1.6 "Adoption-grade integration and trust"  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.6 Requirements

Additive, documentation- and proof-first unless a phase plan explicitly calls for code changes. **No** new search algorithms or backlog search-power features in this milestone.

### Adoption and golden path (prefix: ADPT)

- [x] **ADPT-01**: A new reader can follow a **single documented golden path** from dependency install through a **working** `Scrypath.search/3` (or equivalent documented entry) using **inline** sync, without hunting across disconnected fragments.

- [x] **ADPT-02**: Maintainer-facing documentation **compares inline, Oban-backed, and manual sync** clearly enough that a team can choose a mode for local vs production and find the right operator or code hooks for each.

- [x] **ADPT-03**: **Upgrade and versioning** expectations for adopters are stated consistently (README and/or `CHANGELOG.md` / releasing docs): semver posture, what verify tasks gate, and where breaking vs additive changes are announced.

### Consumer example and smoke (prefix: EXAM)

- [ ] **EXAM-01**: The repository exercises **at least one additional consumer-shaped scenario** beyond the existing Phoenix example smoke (for example Oban-backed sync, a second bounded integration scenario, or an expanded smoke script — exact shape decided in phase planning) so integration proof matches how some production apps run.

- [ ] **EXAM-02**: The **example app** (or primary smoke path) documents **how to run** integration smoke locally, including required env vars and how that aligns with CI jobs that use Meilisearch.

### Verification clarity (prefix: VRFY)

- [ ] **VRFY-01**: **`CONTRIBUTING.md`** (or linked maintainer doc) **maps major verify / CI steps** to what consumer-visible guarantees they protect (not only task names).

- [ ] **VRFY-02**: The **default CI matrix** remains documented as green for contributors who skip live Meilisearch, with **integration** jobs called out explicitly (what runs where, and how to approximate locally).

### Planning hygiene (prefix: AUDT)

- [ ] **AUDT-01**: **Deferred rows** carried from the v1.5 milestone close in **`STATE.md`** (UAT listing noise, missing quick-task stubs) are **triaged**: fixed, re-filed as tracked issues, or marked **wont-fix / obsolete** with a one-line reason in `STATE.md` or `.planning/` as appropriate.

## v2+ Requirements (deferred)

Unchanged product backlog; not in v1.6.

### Faceting

- **FACET-V14-01** … **FACET-V14-03**: Hierarchical facets, disjunctive counts, `search_within_facet/4`.

### Multi-index

- **MULTI-V14-01** … **MULTI-V14-03**: Federation scoring, weighting, `:all` wildcard.

### Relevance

- **TUNE-V15-01**: Per-query setting overrides (blocked on pipeline semantics design).

## Out of Scope (v1.6)

| Item | Reason |
|------|--------|
| Hierarchical facets, multi-index scoring, per-query relevance | Backlog feature work; v1.6 is adoption and trust, not search-power expansion. |
| Public multi-backend abstraction | Product boundary unchanged. |
| New silent heal or auto-mutation operator verbs | Report-first discipline unchanged. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADPT-01 | Phase 29 | Complete |
| ADPT-02 | Phase 29 | Complete |
| ADPT-03 | Phase 29 | Complete |
| EXAM-01 | Phase 30 | Pending |
| EXAM-02 | Phase 30 | Pending |
| VRFY-01 | Phase 31 | Pending |
| VRFY-02 | Phase 31 | Pending |
| AUDT-01 | Phase 32 | Pending |

**Coverage:** v1.6 requirements: **8** — mapped: **8** — unmapped: **0**

| Phase | Goal | Requirements |
|-------|------|----------------|
| **Phase 29** — Golden path and adoption documentation | Install → first search story; sync-mode guidance; upgrade/versioning clarity | ADPT-01, ADPT-02, ADPT-03 |
| **Phase 30** — Consumer example and smoke depth | Extra consumer scenario; example runbook for smoke / env / CI | EXAM-01, EXAM-02 |
| **Phase 31** — Verification story for adopters | Verify matrix explained; CI default vs integration documented | VRFY-01, VRFY-02 |
| **Phase 32** — Planning and state hygiene | Close or re-file v1.5 deferred planning rows | AUDT-01 |

### Phase success criteria (observable)

**Phase 29**

1. A maintainer can hand a new adopter **one primary doc path** (README and/or linked guide) that completes the golden path through search with inline sync.
2. Inline vs Oban vs manual is **decision-ready** from docs without reading source.
3. Versioning expectations are **consistent** across README / releasing / changelog pointers.

**Phase 30**

1. At least **one** additional consumer-shaped scenario is **automated or scripted** in-repo and documented.
2. Example or smoke README states **exact commands and env** to reproduce integration proof.

**Phase 31**

1. CONTRIBUTING (or linked doc) contains a **table or list** mapping verify tasks to guarantees.
2. CI jobs for default vs integration are **named and described** for contributors.

**Phase 32**

1. Every deferred row targeted by AUDT-01 has a **terminal status** and short reason.

---
*Requirements defined: 2026-04-18 — v1.6 milestone kickoff*
