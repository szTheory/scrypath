# Phase 62: Playground capture and playbook catalog - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **62-CONTEXT.md** — this log preserves alternatives and research synthesis.

**Date:** 2026-04-22  
**Phase:** 62 — Playground capture and playbook catalog  
**Areas discussed:** Wire format for metadata; Tags scope; Capture session semantics; Rename/duplicate/collisions  
**Mode:** User requested **all** areas + parallel **generalPurpose** subagent research, then one-shot cohesive recommendations (accepted as locking decisions).

---

## 1. Wire format for title/description/tags

| Option | Description | Selected |
|--------|-------------|----------|
| A — Flat optional top-level keys | `title`, `description`, `tags` alongside existing keys; extend allow-list | ✓ |
| B — Nested `meta` object | Single extension subtree for non-executable fields |  |
| C — `playbook_format` 2 | New envelope version for metadata |  |
| D — Sidecar files | `.meta.json` next to playbook |  |

**User's choice:** Research-backed **A + strict doc/codec update**; reject **C** for metadata-only; reject **D** as primary.  
**Notes:** Idiomatic Elixir: string keys, fail-fast validation, explicit allow-list. Analogues: Postman nested `info` vs flat tradeoffs; GitHub Actions strict top-level; avoid silent ignore.

---

## 2. Tags in Phase 62

| Option | Description | Selected |
|--------|-------------|----------|
| Ship tags in UI + list + filters | Full tag product in 62 |  |
| Title + description in UI; optional `tags` in JSON | Codec accepts `tags` when present; no tag authoring/display in 62 | ✓ |

**User's choice:** **Defer tag UX**; keep optional **`tags`** in schema/validator for imports and forward compatibility.  
**Notes:** Kibana/Grafana-style tags help at scale; internal ops catalog avoids normalization footguns early.

---

## 3. Capture source semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A — Ephemeral only | Lost on any navigation |  |
| B — Assigns survive `push_patch` within mode | Same LiveView, URL patch | Partial ✓ (within mode) |
| C — Server session persistence | Cross-route without re-run |  |
| D — Explicit pin | Separate pinned snapshot | Deferred |

**User's choice:** **Latest successful run in assigns**; **survive** in-mode **`push_patch`**; **clear on mode switch** and **mount**; no **C** or **D** in Phase 62.  
**Notes:** Jupyter/SQL-client analogy — persistence through explicit save; avoid stale cross-mode payloads.

---

## 4. Rename / duplicate / collisions

| Option | Description | Selected |
|--------|-------------|----------|
| A — Hard error on rename collision | No replace | ✓ |
| B — Typed confirm replace | Same ritual as delete | Deferred |
| C — Implicit overwrite | Never | ✓ (never implicit) |

**Duplicate naming:** Prefer **`stem-n.json`** increment over verbose **`copy-of-…`** prefix.  
**Notes:** Unix `mv` clobber lesson; TOCTOU → rely on atomic rename error paths; web admin explicit modals.

---

## Claude's Discretion

- Numeric bounds for metadata and tag array (within reason).
- Implementation details of “material config change” detection for clearing capture.

## Deferred Ideas

- Pin snapshot / session-persisted capture draft.  
- Replace-on-rename with typed confirmation.  
- Full tag product (chips, filters, normalization).
