# Requirements: Scrypath v1.29 Contract Repair and Proof Hardening

**Defined:** 2026-05-31
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1 Requirements

Requirements for this bounded repair milestone. Each maps to exactly one roadmap phase.

### Fan-Out Contract

- [x] **FAN-01**: Adopter can declare related-data fan-out metadata with `use Scrypath, fan_outs:` and have `__scrypath__(:fan_outs)` generated.
- [x] **FAN-02**: Existing hand-written fan-out reflection remains compatible for unusual owner schemas.

### Ecommerce Proof

- [x] **E2E-01**: Ecommerce readiness probes preserve tenant scope when category filtering is present.

### Truth Alignment

- [ ] **TRUTH-01**: Related-data docs and planning/JTBD truth describe the repaired contract and keep deferred breadth out of v1.29.

## Future Requirements

Deferred until outside-adopter evidence or a concrete production bug justifies the surface.

### Fan-Out Ergonomics

- **FAN-FUTURE-01**: Non-searchable owner schemas can use an owner-only fan-out declaration macro without pretending to be searchable.
- **FAN-FUTURE-02**: Public fan-out reflection helper exposes fan-out metadata without callers reaching directly for `__scrypath__/1`.
- **FAN-FUTURE-03**: Fan-out validation rejects duplicate fan-out keys and nil target/resolver members with dedicated diagnostics.

### Ecommerce Proof

- **E2E-FUTURE-01**: Browser E2E includes explicit cross-tenant negative assertions and projected category-name readiness checks.

## Out of Scope

Explicit exclusions for v1.29.

| Feature | Reason |
|---------|--------|
| `Scrypath.FanOuts` owner-only macro | Valid future ergonomic surface, but it is new public API beyond this repair closeout. |
| `Scrypath.schema_fan_outs/1` public helper | Useful, but not required to close the shipped `use Scrypath, fan_outs:` reflection gap. |
| Deeper Playwright cross-tenant fixture expansion | Valuable proof depth, but current scope is the known readiness-filter regression guard. |
| Promote `phase105-e2e` to required CI | Promotion needs stability history and release-policy approval; v1.29 keeps it advisory. |
| New search features or OPSUI productization | Feature lane remains evidence-gated after v1.28. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FAN-01 | Phase 106 | Complete |
| FAN-02 | Phase 106 | Complete |
| E2E-01 | Phase 107 | Complete |
| TRUTH-01 | Phase 108 | Pending |

**Coverage:**
- v1 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 after v1.29 milestone initialization*
