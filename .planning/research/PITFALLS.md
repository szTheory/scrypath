# Pitfalls Research — OPSUI second slice (v1.15)

**Researched:** 2026-04-22  
**Confidence:** HIGH

## Top pitfalls

1. **Schema drift** — Playground emits keys **`V1`** rejects → silent frustration. **Mitigation:** single encoder module + contract tests round-trip playground fixture → JSON → validate.

2. **Two persistence truths** — File workspace + DB without migration story → orphaned rows. **Mitigation:** pick **one** authoritative store per deployment in docs; if both exist, define precedence in **Phase 62**.

3. **Secrets in JSON** — “Share playbook” invites API keys in pasted JSON. **Mitigation:** extend banned-key list / scrubber same as import path; flash copy.

4. **CI bloat** — Ecto integration pulls Postgres in **`verify.opsui`**. **Mitigation:** keep default verify on **stub** + **SQLite** (if Ecto) or gate Ecto tests behind **`SCRYPATH_OPS_PLAYBOOK_DB=1`**.

5. **IA regression** — New buttons bypass **`operator-ia.md`**. **Mitigation:** update table + **`operator_ia_contract_test`** in same PR as nav change.

6. **Over-promising team sync** — **OPSUI-FUT-01** wording implies real-time collaboration. **Mitigation:** docs say **catalog shared via app DB**, not Google Docs semantics.

## Phase placement

| Pitfall | Best addressed |
|---------|----------------|
| Schema drift | Phase **62** (capture) |
| Persistence truth | Phase **63** |
| IA regression | Phase **64** |

---
*Pitfalls research for **v1.15***
