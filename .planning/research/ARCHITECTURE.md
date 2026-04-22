# Architecture Research — OPSUI second slice (v1.15)

**Researched:** 2026-04-22  
**Confidence:** HIGH

## Current architecture (v1.14)

- **`PlaybookLive`** — mount lists workspace + examples; import paste/upload; validate via **`V1`**; run via **`Runner`**; persist via **`Store`** to configured dir.
- **`SearchPlaygroundLive`** (and related) — bounded `search_many`; stub adapter in CI.
- **Boundary:** `scrypath_ops` remains optional; core **`Scrypath`** unchanged unless playbook schema needs shared structs (prefer ops-local).

## Integration for second slice

1. **Playground → playbook**  
   - Add a **pure function** (or context module) that maps playground assigns / form params → **`V1`** map — **LiveView stays thin**.  
   - Reuse **`V1`** validation; surface same error taxonomy as import path.

2. **Metadata**  
   - Prefer **fields inside JSON** (`title`, `description`, `tags`) with **`V1` strict allowlist** over sidecar files (fewer sync bugs). If schema bump → **`playbook_format`** minor doc + migration note.

3. **Optional Ecto catalog** (if selected)  
   - **Table:** `playbook_entries` (id, inserted_at, title, basename_ref or `bytea` blob) — simplest shape decided in plan phase.  
   - **Sync:** optional watcher from DB rows → workspace export for gitops teams **out of scope** unless trivial.

4. **Telemetry**  
   - Mirror playground: attach **`:playbook_id`** / basename to events for operators.

## Suggested build order

1. Domain mapping + validation (**capture**).  
2. **Store** / LiveView for catalog ops.  
3. Persistence fork (docs vs Ecto) **after** capture ships.  
4. IA + **`verify.opsui`** last so strings stabilize.

---
*Architecture research for **v1.15***
