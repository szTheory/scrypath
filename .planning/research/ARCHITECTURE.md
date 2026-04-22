# Architecture Research

**Domain:** Scrypath core (`lib/scrypath`) + **`scrypath_ops`** operator shell — **v1.14** extensions for B1 + B2.

**Researched:** 2026-04-21

**Confidence:** HIGH for as-built; MEDIUM for target playbook architecture (depends on persistence MVP).

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Consumer Phoenix app                     │
│  Ecto schemas ──> Scrypath sync ──> Meilisearch indices      │
└───────────────────────────┬─────────────────────────────────┘
                            │ read APIs + Mix tasks
┌───────────────────────────▼─────────────────────────────────┐
│              scrypath_ops (optional, repo-local)             │
│  LiveView (posture, triage, sync/drift, search playground)   │
│       │                                                      │
│       ├── SearchPlayground ──> Adapter.Scrypath / Stub       │
│       └── [v1.14] Playbook store (TBD: session / file / DB)   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | v1.14 touch |
|-----------|----------------|-------------|
| **`Scrypath`** | Search, sync, federation, visibility APIs | **B1** only: targeted improvements |
| **`ScrypathOps.SearchPlayground`** | Caps, validation, dispatch | **B2**: accept playbook-shaped params; maybe `dispatch_*` overloads or normalizer module |
| **`SearchLive`** | Form state, events, telemetry | **B2**: save/load UI, warnings |
| **`operator-ia.md` + router** | Nav contract | **B2**: new nav entry only if JTBD clear; run **`mix scrypath_ops.check_nav_contract`** |

## Recommended Project Structure (incremental)

```
scrypath_ops/lib/scrypath_ops/
  search_playground.ex          # limits + dispatch (extend carefully)
  search_playground/
    adapter.ex
scrypath_ops/lib/scrypath_ops_web/live/
  search_live.ex                # playground UI
  [new] playbook_live.ex        # OR fold into search_live — pick one surface
```

**Rationale:** Keep playbook logic discoverable next to playground; avoid scattering persistence in `Endpoint`.

## Architectural Patterns

### Pattern 1: Adapter seam for testability

**What:** `SearchPlayground` already selects adapter via config.

**When to use:** Playbook “run” should hit the same adapter path as manual runs.

**Trade-offs:** Stub stays deterministic in CI.

### Pattern 2: Value objects for saved payload

**What:** Typed struct or schema for `{mode: :search | :search_many, entries: ..., opts: ...}` with explicit version field (`playbook_format: 1`).

**When to use:** Before any persistence.

**Trade-offs:** Migration story if Meilisearch wire options evolve — version field enables upgrade path.

### Pattern 3: No new library recovery verbs

**What:** UI and playbooks stay read-only / bounded query; actions remain Mix/docs.

**When to use:** Always (per **v1.10** Out of Scope table).

## Data Flow — Playbook Run

```
User selects playbook
    → Load normalized payload (validate version + caps)
    → SearchLive assigns form
    → User clicks Run (or auto-run guarded)
    → SearchPlayground.dispatch_* → Scrypath / Stub
    → Render results + merge trace (existing OPSUI-05 paths)
```

## Anti-Patterns

### Anti-Pattern: Playbook executes hidden Mix

**Wrong:** One-click reindex from saved YAML.

**Right:** Playbook stores **query reproduction** data; operator follows linked Mix for mutations.

### Anti-Pattern: Storing secrets in playbooks

**Wrong:** Full connection strings in JSON.

**Right:** Reference schema keys / index names only; host config stays env.

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Playbook JSON ↔ LiveView | Params + assigns | Sanitize display; length limits |
| OPSUI ↔ Meilisearch | Via `Scrypath` only | No parallel HTTP client in playbooks |

## Sources

- **`scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`**
- **`scrypath_ops/lib/scrypath_ops/search_playground.ex`**
- **`milestones/v1.10-REQUIREMENTS.md`** packaging + security rows

---
*Architecture research for: Scrypath v1.14*
