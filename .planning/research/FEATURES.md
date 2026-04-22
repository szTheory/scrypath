# Feature Research

**Domain:** Search integration libraries (Rails Searchkick, Laravel Scout, Meilisearch docs) vs Scrypath **v1.14** themes (**B1** evidence-led QoL, **B2** operator playbooks).

**Researched:** 2026-04-21

**Confidence:** MEDIUM–HIGH (ecosystem patterns from public docs + Stack Overflow themes; B1 item list must still be grounded in **this** repo’s evidence).

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Repeatable reindex / sync paths | Operators rerun the same recovery; Searchkick exposes `Model.reindex` and async promotion flows | LOW in library; MEDIUM in UI | Scrypath already has Mix tasks + guides; **B1** tightens error surfaces and doc hops |
| Explicit query / filter construction | Scout users hit filter-operator foot-guns; docs show callback escape hatches | LOW | **`guides/common-mistakes.md`** and playground warnings already exist — extend for federation edge cases if evidence |
| Test doubles for search in CI | Scout ecosystem uses array / fake drivers for assertions | LOW | **`SearchPlaygroundStubAdapter`** — playbooks must remain testable without live Meilisearch |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Honest federation + merge trace** | Few libs document multi-search merge ordering; Scrypath does in code + OPSUI | HIGH already shipped | **B2** playbooks should capture **multi-index** entries + weights + `:all` expansion intent for replay |
| **Per-query tuning pipeline as product language** | v1.9 guide distinguishes Plane A vs B | MEDIUM | Playbook metadata can reference pipeline step labels (not internal phase IDs) |
| **Ecto-native projection** | Searchkick-style “model knows index shape” | Shipped | **B1** avoids new macro magic; prefer messages and small API clarifications |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Silent “fix my index” buttons in OPSUI | Faster incident response | Violates **v1.10** out-of-scope: new recovery verbs via UI | Deep links to Mix + docs; playbooks **record** intent, not auto-mutate |
| Production query logging | Replay customer searches | Privacy + cardinality (`docs/search-backend-sre.md` discipline) | Bounded playground only; export scrubbed fixtures |
| Full vendor dashboard | Parity with Meilisearch Cloud | **OPSUI-FUT-02** deferred | Keep read-only posture + playground |

## Feature Dependencies

```
Evidence triage (B1)
    └── informs──> Small lib/doc fixes

Playbook persistence choice (research)
    └──requires──> Clear MVP (export/import vs DB)
                       └──requires──> Auth story (OPSUI-08)

Playbook UI (B2)
    └──requires──> SearchLive + SearchPlayground extensions
```

## MVP Definition (v1.14 planning sense)

### Launch With (milestone)

- [ ] **Named evidence list for B1** — issues or maintainer log; no drive-by API.
- [ ] **Playbook MVP** — save + list + load + run (single-user or export-first acceptable if research chooses); federation-honest payload shape.
- [ ] **Verification** — `mix test` / `mix verify.opsui` extended; no Tier-C Playwright mandate.

### Add After Validation (v1.14.x or later)

- [ ] Multi-user playbook ACLs — trigger: real multi-tenant OPSUI deploys.
- [ ] Shared team library — trigger: evidence from adopters.

### Future (v2+)

- [ ] **OPSUI-FUT-02** cluster observability.

## Competitor Feature Analysis

| Feature | Searchkick (Rails) | Laravel Scout + Meilisearch | Our Approach (v1.14) |
|---------|-------------------|----------------------------|---------------------|
| Console reindex | First-class `reindex`, async index promotion | Driver-level testing patterns | Mix tasks + OPSUI links; playbooks for **repeatable** query/repro |
| Query debugging | Rails console + `search` | Callback to pass raw Meilisearch options | **`search_live.ex`** + adapter; save **structured** opts Scrypath already accepts |
| Saved searches / admin | Often app-specific (not core gem) | App-level | **OPSUI-FUT-01** in **`scrypath_ops`** only |

## Sources

- Searchkick GitHub + Stack Overflow reindex / `Searchkick::ImportError` themes.
- Meilisearch Laravel Scout guide; Stack Overflow Scout filter callbacks.
- **`milestones/v1.10-REQUIREMENTS.md`** (OPSUI scope + FUT items).

---
*Feature research for: Scrypath v1.14*
