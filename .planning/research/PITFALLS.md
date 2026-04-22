# Pitfalls Research

**Domain:** Adding evidence-led library QoL + operator saved playbooks to an existing search library and LiveView ops shell.

**Researched:** 2026-04-21

**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Speculative B1 API churn

**What goes wrong:** New options or macros “for ergonomics” without a linked failure report — breaks semver trust and increases doc surface.

**Why it happens:** Momentum after research; easy to confuse “elegant” with “needed”.

**How to avoid:** Each **B1** REQ cites evidence (issue URL, doc quote, repro snippet). Default to docs/errors first.

**Warning signs:** PRs that only say “cleanup” or “DX” with no user story.

**Phase to address:** Early v1.14 phase — evidence triage gate.

---

### Pitfall 2: Playbooks as covert production logging

**What goes wrong:** Saved payloads include PII-rich query strings; operators replay against prod from laptops.

**Why it happens:** FUT-01 “shared playbooks” interpreted as production truth capture.

**How to avoid:** Warnings in UI (already “Non-production search playground” tone in **`search_live.ex`**); scrub export; document in operator guide.

**Warning signs:** Requests for “run on schedule against prod index”.

**Phase to address:** Playbook design / UX phase.

---

### Pitfall 3: Credential leakage in exports

**What goes wrong:** JSON download embeds API keys or Meilisearch master key copied from env.

**Why it happens:** Naive “serialize whole assigns”.

**How to avoid:** Explicit allowlist of serializable fields; redact unknown keys.

**Warning signs:** Export contains `host` with embedded basic auth.

**Phase to address:** Persistence / export implementation.

---

### Pitfall 4: Drift from `operator-ia.md` without contract update

**What goes wrong:** New playbook nav breaks **OPSUX-01** / nav contract CI.

**Why it happens:** Feature added without IA doc pass.

**How to avoid:** Update **`scrypath_ops/docs/operator-ia.md`** in same PR as router change; run **`mix scrypath_ops.check_nav_contract`**.

**Phase to address:** OPSUI playbook UI phase.

---

### Pitfall 5: Scope creep into recovery verbs

**What goes wrong:** “Run playbook” triggers reindex or settings apply.

**Why it happens:** Incident fatigue.

**How to avoid:** Re-read **v1.10** Out of Scope table in planning archives; keep actions in Mix.

**Phase to address:** Architecture review before implementation merge.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|------------------|
| `localStorage` only playbooks | No migrations | No team sharing | Solo dev OPSUI only; document limitation |
| Postgres without authz | Faster MVP | Data leak risk | Never in multi-user deploy without OPSUI-08 model |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| World-readable playbook index | Competitor intel | Auth plug + default deny |
| CSRF ignored on save | Forged playbooks | Standard Phoenix CSRF on LiveView |

## Pitfall-to-Phase Mapping (preview)

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Speculative B1 | Evidence triage | Checklist in PR template |
| Production logging | Playbook UX | Copy review + doc |
| IA drift | Nav / IA phase | `check_nav_contract` |

## Sources

- **`milestones/v1.10-REQUIREMENTS.md`** — Out of Scope rows.
- **`docs/search-backend-sre.md`** — operator discipline.
- Community: Searchkick import errors, Scout filter foot-guns (symptoms of unclear query contracts).

---
*Pitfalls research for: Scrypath v1.14*
