# Requirements: Scrypath v1.6

**Defined:** 2026-04-18  
**Milestone:** v1.6 "Adoption-grade integration and trust"  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.6 Requirements

Additive, documentation- and proof-first unless a phase plan explicitly calls for code changes. **No** new search algorithms or backlog search-power features in this milestone.

### Adoption and golden path (prefix: ADPT)

- [ ] **ADPT-01**: A new reader can follow a **single documented golden path** from dependency install through a **working** `Scrypath.search/3` (or equivalent documented entry) using **inline** sync, without hunting across disconnected fragments.

- [ ] **ADPT-02**: Maintainer-facing documentation **compares inline, Oban-backed, and manual sync** clearly enough that a team can choose a mode for local vs production and find the right operator or code hooks for each.

- [ ] **ADPT-03**: **Upgrade and versioning** expectations for adopters are stated consistently (README and/or `CHANGELOG.md` / releasing docs): semver posture, what verify tasks gate, and where breaking vs additive changes are announced.

### Consumer example and smoke (prefix: EXAM)

- [x] **EXAM-01**: The repository exercises **at least one additional consumer-shaped scenario** beyond the existing Phoenix example smoke (for example Oban-backed sync, a second bounded integration scenario, or an expanded smoke script — exact shape decided in phase planning) so integration proof matches how some production apps run.

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
| ADPT-01 | Phase 29 delivered; **gap closure 33–34** | Pending |
| ADPT-02 | Phase 29 delivered; **gap closure 34–35** | Pending |
| ADPT-03 | Phase 29 delivered; **gap closure 34–35** | Pending |
| EXAM-01 | Phase 30 | Complete |
| EXAM-02 | Phase 30 delivered; **gap closure 33** | Pending |
| VRFY-01 | Phase 31 delivered; **gap closure 34** | Pending |
| VRFY-02 | Phase 31 delivered; **gap closure 33** | Pending |
| AUDT-01 | Phase 32 delivered; **gap closure 33** (doc path contracts) | Pending |

_Re-opened for **v1.6-MILESTONE-AUDIT.md** integration and flow gaps; **phase 33** verified in-repo 2026-04-18; close again when phases **34–35** verify._

**Coverage:** v1.6 requirements: **8** — mapped: **8** — unmapped: **0** — **gap closure in flight:** 7 (EXAM-01 unchanged)

| Phase | Goal | Requirements |
|-------|------|----------------|
| **Phase 29** — Golden path and adoption documentation | Install → first search story; sync-mode guidance; upgrade/versioning clarity | ADPT-01, ADPT-02, ADPT-03 |
| **Phase 30** — Consumer example and smoke depth | Extra consumer scenario; example runbook for smoke / env / CI | EXAM-01, EXAM-02 |
| **Phase 31** — Verification story for adopters | Verify matrix explained; CI default vs integration documented | VRFY-01, VRFY-02 |
| **Phase 32** — Planning and state hygiene | Close or re-file v1.5 deferred planning rows | AUDT-01 |
| **Phase 33** — Example smoke paths and doc contracts | Root vs example `smoke.sh` cwd; CONTRIBUTING footnotes; contract tests for implied paths | ADPT-01, EXAM-02, VRFY-02, AUDT-01 |
| **Phase 34** — Golden path, README, and CI alignment | Canonical snippet parity; golden path ↔ PR CI story | ADPT-01, ADPT-02, ADPT-03, VRFY-01 |
| **Phase 35** — Sync guide lifecycle parity | README sync authority ↔ sync guide depth | ADPT-02, ADPT-03 |

### Phase success criteria (observable)

**Phase 29**

1. A maintainer can hand a new adopter **one primary doc path** (README and/or linked guide) that completes the golden path through search with inline sync.
2. Inline vs Oban vs manual is **decision-ready** from docs without reading source.
3. Versioning expectations are **consistent** across README / releasing / changelog pointers.

**Phase 30**

1. At least **one** additional consumer-shaped scenario is **automated or scripted** in-repo and documented — **Oban `sync_mode: :oban`** integration test in **`examples/phoenix_meilisearch`** plus hardened **`scripts/smoke.sh`**.
2. Example README states **exact commands and env** to reproduce integration proof and maps to **CI** via **`CONTRIBUTING.md`** / golden path links.

**Phase 31**

1. CONTRIBUTING **Job \| Purpose** table + **`docs_contract_test`** lock the verify ↔ guarantee story (including **`phoenix-example-integration`**).
2. Default **`test`** job vs **integration** jobs (phase5, phase13, meilisearch-smoke, phoenix example) are **named in CONTRIBUTING** and **enforced against `ci.yml`** in tests.

**Phase 32**

1. Every deferred row targeted by AUDT-01 has a **terminal status** and short reason.

**Phase 33 (gap closure)**

1. No published maintainer path implies `./scripts/smoke.sh` from the **repository root** unless that path exists there; otherwise docs show **`cd examples/phoenix_meilisearch`** (or equivalent) before `./scripts/smoke.sh`.
2. **`docs_contract_test.exs`** (or adjacent contract tests) cover critical **cwd-dependent** strings introduced or corrected in this phase, where practical.

**Phase 34 (gap closure)**

1. README **Quick Path** and **`guides/golden-path.md`** agree on the **first schema** story (including `status` field representation).
2. Golden-path prose for Phoenix example integration matches **`.github/workflows/ci.yml`** (`phoenix-example-integration` on pull requests, not “local-only fiction”).

**Phase 35 (gap closure)**

1. Either **`guides/sync-modes-and-visibility.md`** carries the lifecycle vocabulary README points readers at, or README narrows the authority sentence so the guide is not overstated.

---
*Requirements defined: 2026-04-18 — v1.6 milestone kickoff; gap-closure phases 33–35 added 2026-04-18 from milestone audit*
