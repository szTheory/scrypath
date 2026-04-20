# Feature Research

**Domain:** Operator admin UI for Ecto/Phoenix search (Scrypath-shaped)
**Researched:** 2026-04-20
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Operators Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Posture landing (“what’s on fire?”) | First screen after login | MEDIUM | Maps to sync status, error rates, failed work presence |
| Failed work triage | Day-2 ops is debugging stuck sync | MEDIUM | Align UI rows with `failed_sync_work/2` semantics |
| Read-only drill-down | Ops must not “fix” via mystery buttons | LOW | Link out to Mix tasks / runbooks where action lives |
| Honest multi-index display | Federation changed expectations in v1.8–v1.9 | MEDIUM | Show merge order, weights, partial failures explicitly |
| Conventional Phoenix layout | Least surprise for library adopters | LOW | Router scopes, live_session, flash, errors |

### Differentiators (Valuable for Scrypath)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| JTBD-ordered navigation | Personas (SRE vs app dev) land on the right work faster | LOW–MEDIUM | Document personas once; nav reflects priority |
| Per-query / pipeline hints in UI | v1.9 invested in semantics; UI can surface “active knobs” read-only | MEDIUM | Optional panel when viewing query/debug paths |
| Telemetry-aware copy | Teaches low-cardinality discipline | LOW | Inline help from SRE doc themes |

### Anti-Features (Commonly Requested, Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full Meilisearch admin clone | “One pane of glass” | Duplicates vendor UI; security + scope explosion | Deep links or iframe policy explicit out-of-scope |
| Arbitrary query log in UI | Debugging | High cardinality PII / secrets risk | Bounded playground (OPSUI-04) with warnings |
| Silent auto-remediation | Convenience | Hides operational reality; conflicts with library contracts | Keep actions in existing Mix/API paths; UI explains |

## Feature Dependencies

```
[OPSUI packaging / app shell]
    └──requires──> [Security model doc]
                       └──requires──> [IA / personas]

[Posture landing]
    └──requires──> [Scrypath sync/search visibility APIs]

[Federation inspector]
    └──requires──> [search_many/2 + MultiSearchResult truth]
```

## MVP Definition (this milestone)

### Launch With (v1.10)

- [ ] Packaged OPSUI outside core Hex (OPSUI-09)
- [ ] Persona/JTBD IA in nav (OPSUI-06)
- [ ] Posture + failed work + sync read paths (OPSUI-01..03)
- [ ] Federation-honest + bounded search exploration (OPSUI-04..05)
- [ ] Conventional LiveView UX + explicit security story (OPSUI-07..08)
- [ ] CI-safe verification slice (OPSUI-10)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Failed work triage | HIGH | MEDIUM | P1 |
| Posture landing | HIGH | MEDIUM | P1 |
| Federation honesty | HIGH | MEDIUM | P1 |
| Conventional shell + security | HIGH | LOW | P1 |
| Bounded query playground | MEDIUM | MEDIUM | P2 |

## Sources

- `.planning/ROADMAP.md` backlog OPSUI-01
- `docs/search-backend-sre.md`
- Shipped Scrypath operator APIs (codebase)

---
*Feature research for: Scrypath v1.10 OPSUI*
*Researched: 2026-04-20*
