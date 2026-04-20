# Pitfalls Research

**Domain:** Adding operator LiveView UI to an existing search library ecosystem
**Researched:** 2026-04-20
**Confidence:** HIGH

## Pitfalls When Adding OPSUI

| Pitfall | Symptom | Prevention | Phase to address |
|---------|-----------|------------|------------------|
| UI implies stronger guarantees than APIs | Users trust wrong ordering or “live” sync | Label data sources; link to docs; show timestamps/versions | 46, 47 |
| High-cardinality telemetry in widgets | Performance + privacy incidents | Follow `docs/search-backend-sre.md`; aggregate in context | 45, 47 |
| Federation shown as flat search | Misread merge / weight semantics | Dedicated federation view using library structs | 46 |
| OPSUI in core Hex package | Dependency bloat for API-only users | OPSUI-09 enforcement in reviews | 44 |
| Weak auth in production | Open admin on internet | OPSUI-08: default dev-only or explicit plug contract | 44 |
| Drift between UI and Mix tasks | Two sources of truth | Reuse same functions where possible; document gaps | 45–47 |

## Integration Pitfalls

- **Partial multi-search failures:** UI must surface envelope semantics (not hide failed legs).
- **Per-query options:** If shown, must stay allowlisted and match `%Scrypath.Query{}` docs—no “raw JSON” escape hatch unless explicitly scoped and warned.

## Prevention Strategy

- Contract tests or LiveView tests that pin critical copy/structure (OPSUI-10).
- PR checklist: “Does this screen lie about federation or sync timing?”

---
*Pitfalls research for: Scrypath v1.10 OPSUI*
*Researched: 2026-04-20*
