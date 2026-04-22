# Feature Research — OPSUI second slice (v1.15)

**Researched:** 2026-04-22  
**Confidence:** HIGH  
**Upstream:** **OPSUI-FUT-01** (`.planning/milestones/v1.10-REQUIREMENTS.md` — deferred v2+), **v1.14** playbook MVP (**OPS-PB-01..05**).

## Feature landscape

### Table stakes (operators expect after MVP)

| Feature | Why expected | Complexity |
|---------|--------------|------------|
| **Capture from playground** | Avoid hand-authoring JSON for every saved flow | MEDIUM |
| **Rename / duplicate** | Filenames alone do not scale | LOW–MEDIUM |
| **Visible limits** | Same honesty as playground ceilings | LOW |

### Differentiators (stay on-brand)

| Feature | Value | Complexity |
|---------|-------|------------|
| **Rich metadata** (title, description, tags) | JTBD: “what does this playbook do?” | MEDIUM |
| **Optional shared catalog** | Moves toward “team members” without SaaS pretense | HIGH (if Ecto) — **gate in Phase 62** |

### Anti-features

| Feature | Why problematic | Alternative |
|---------|-----------------|-------------|
| **OPSUI-FUT-02** cluster dashboard | Scope explosion, competes with Meilisearch Cloud | Stay deferred |
| **Inline JSON editor** | Validation footguns, security narrative | Structured forms + preview + export |
| **Playbooks that mutate prod indexes** | Violates non-production posture | Keep read-only / bounded run semantics |

## MVP (this milestone)

- [ ] Save-as-playbook from bounded playground state  
- [ ] Catalog operations + metadata story compatible with **`playbook_format: 1`** (or documented **v1.1** extension)  
- [ ] One explicit **team persistence** outcome (docs-first **or** minimal Ecto)  
- [ ] IA + verify spine extended  

## Dependencies

```
Save-as-playbook
    └──requires──> V1 schema stability (+ optional minor version bump)
Catalog metadata
    └──requires──> Clear precedence: filename vs embedded title
Optional Ecto catalog
    └──requires──> Config flag + migrations + auth notes
```

---
*Feature research for **v1.15***
