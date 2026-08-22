# Requirements: Scrypath v1.36 Dependency Security Remediation

**Defined:** 2026-08-21
**Status:** Active
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.36 Requirements

### Dependency Remediation

- [ ] **SEC-01:** Maintainers can resolve root Scrypath beyond its recorded Req, Mint, hpax, and Plug advisories using fixed-compatible constraints.
- [ ] **SEC-02:** Maintainers can resolve the legacy Phoenix example's recorded advisories through coordinated Phoenix/Bandit and Ecto/Ecto SQL/Decimal upgrades.
- [ ] **SEC-03:** Maintainers can independently resolve ScrypathOps beyond its recorded web, LiveView, mailer, HTTP, and database advisories.
- [ ] **SEC-04:** Maintainers can independently resolve the ecommerce example beyond its recorded advisories after the remediated root and ScrypathOps sources are green.

### Compatibility Proof

- [ ] **COMPAT-01:** Each dependency graph passes its documented deterministic gates before maintainers begin the next remediation batch.
- [ ] **COMPAT-02:** Existing Req-backed Meilisearch and Swoosh behavior remains covered after the Req 0.6 transition.
- [ ] **COMPAT-03:** Maintainers record available ecommerce browser proof separately from required deterministic checks and never report unavailable prerequisites as passing.

### Security Evidence

- [ ] **EVID-01:** Maintainers have dated `mix deps.get` evidence from all four project directories showing none of the advisories recorded on 2026-08-16.
- [ ] **EVID-02:** The milestone delivers four ordered, graph-local commits with explained lockfile changes and no unrelated upgrades.
- [ ] **EVID-03:** Postgrex changes remain blocked until both the live advisory and Hex registry confirm a stable published fixed release; maintainers do not substitute an invented version or prerelease.

## Future Requirements

### Dependency Maintenance

- **DEPS-01:** Maintainers can perform broader dependency modernization after a separate compatibility review establishes value beyond the reproduced advisories.
- **AUTO-01:** Maintainers can evaluate additional security automation or cross-project dependency tooling after repeated maintenance cycles establish a concrete need.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Package-head modernization | Expands regression scope beyond the recorded advisories and weakens causal review. |
| Advisory suppression or ignore configuration | Silences findings without providing patched dependency evidence. |
| New permanent CI or security infrastructure | Changes green-main policy and requires a separately approved design. |
| Product APIs, search behavior, backend breadth, or Phoenix UI work | v1.36 is maintenance-only and must preserve the existing product contract. |
| Broad compatibility refactors | Only narrowly demonstrated fixes required by an approved dependency transition belong in this milestone. |

## Traceability

Roadmap creation maps each v1.36 requirement to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | TBD | Pending |
| SEC-02 | TBD | Pending |
| SEC-03 | TBD | Pending |
| SEC-04 | TBD | Pending |
| COMPAT-01 | TBD | Pending |
| COMPAT-02 | TBD | Pending |
| COMPAT-03 | TBD | Pending |
| EVID-01 | TBD | Pending |
| EVID-02 | TBD | Pending |
| EVID-03 | TBD | Pending |

**Coverage:**
- v1.36 requirements: 10 total
- Mapped to phases: 0
- Unmapped: 10

---
*Requirements defined: 2026-08-21*
*Last updated: 2026-08-21 after v1.36 requirements approval*
