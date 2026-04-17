# Phase 20: Faceted Search + LiveView Guide - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `20-CONTEXT.md`.

**Date:** 2026-04-17
**Phase:** 20 — Faceted Search + LiveView Guide
**Areas discussed:** Guide packaging; URL sync posture; Test pyramid; Anti-pattern appendix; Docs vs API naming; Cohesion / discretion (all six gray areas from discuss-phase)

**Method:** User elected **all** areas and requested parallel subagent research (ecosystem idioms, cross-language search integrations, Meilisearch wire semantics, Phoenix/LiveView patterns). Primary agent synthesized subagent outputs into locked decisions in `20-CONTEXT.md`.

---

## 1. Guide packaging vs runnable example / generator

| Option | Description | Selected |
|--------|-------------|----------|
| A — Snippets-first guide only | Single `guides/*.md` + ExDoc extras | ✓ (spine) |
| B — Runnable `examples/` app | Full Phoenix app in repo | Deferred |
| C — Mix generator | `mix scrypath.gen.*` | Deferred |
| D — Hybrid later | Compile-check or weekly CI example | Optional follow-on |

**User's choice:** Research delegation — **D-01** in CONTEXT: spine is (A); do not block Phase 20 on (B) or (C); bounded hybrid only if justified later.

**Notes:** Cross-language: Searchkick/Scout DX vs operational footguns; Meilisearch scripts vs Phoenix bridge; small-team CI cost for runnable examples (~0.25–0.5 FTE churn).

---

## 2. URL sync in worked example

| Option | Description | Selected |
|--------|-------------|----------|
| Main path URL sync | `handle_params` + `push_patch`, idiomatic live navigation | ✓ |
| Mount-only default | Simpler tutorial; refresh loses state | Labeled sidebar only |

**User's choice:** Research delegation — **D-02** in CONTEXT.

**Notes:** Single loader; avoid duplicate param reads in `mount` vs `handle_params`; encoding/normalization footguns documented in-guide.

---

## 3. Test placement

| Layer | Description | Selected |
|-------|-------------|----------|
| Unit | Translation, structs, compile checks | ✓ |
| Req.Test / SearchTest | HTTP body + decode | ✓ |
| Docs + Phoenix fixture | DocsContractTest, PhoenixExamplesTest | ✓ |
| Full LiveView browser CI | Heavy | ✗ (default) |

**User's choice:** Research delegation — **D-03** in CONTEXT.

---

## 4. Anti-pattern appendix

| Option | Description | Selected |
|--------|-------------|----------|
| Structured bands | API / Meilisearch / UI | ✓ |
| Order | API → engine → UI | ✓ |
| Per-entry template | + one-line user-visible consequence | ✓ |

**User's choice:** Research delegation — **D-04** in CONTEXT.

---

## 5. Docs vs API naming

| Option | Description | Selected |
|--------|-------------|----------|
| Code-first public API | Structs/types in `lib/` are SSOT | ✓ |
| Wire-explicit mapping | `facetStats` min/max vs filter gte/lte | ✓ |
| Doc-first unshipped names | Guide leads implementation | Rejected for stable sections |

**User's choice:** Research delegation — **D-05** in CONTEXT.

---

## Claude's Discretion

- **D-06** and discretion bullets in CONTEXT: query encoding details, file layout, fixture naming, minor HEEx within UI-SPEC, telemetry shape.

## Deferred Ideas

- Runnable example app; mix generator; first-class Meilisearch facet-search API in v1.3 — see `<deferred>` in `20-CONTEXT.md`.
