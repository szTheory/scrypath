# Phase 44: OPSUI foundations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **44-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 44-OPSUI foundations
**Areas discussed:** Repository layout & dependencies; Personas/JTBD & navigation; Phoenix LiveView shell; Security model

---

## Repository layout & dependencies

| Option | Description | Selected |
|--------|-------------|----------|
| Top-level sibling Mix app (`scrypath_ops/`) | Clear Hex boundary; `cd scrypath_ops`; path dep to core | ✓ |
| Umbrella `apps/` | Shared lockfile; publish-path footguns | |
| Under `examples/` | Consumer-demo connotation; wrong for privileged ops | |
| Separate git repository | Clean isolation; cross-repo friction | |

**User's choice:** Discuss **all** areas; synthesis locked **top-level `scrypath_ops/`** with **`{:scrypath, path: ".."}`**, exclude from Hex **`package.files`**, keep **`examples/phoenix_meilisearch`** as consumer reference.

**Notes:** GSD **`init.phase-op`** initially failed until **`.planning/ROADMAP.md`** gained **`### Phase N:`** headings (table-only roadmap was invisible to the parser).

---

## Personas, JTBD, and primary navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical doc in `scrypath_ops/docs/` + short pointer from README/guides | Single PR updates IA + router | ✓ |
| Long-form JTBD only in `guides/` | Drift from LiveView routes | |
| Nav as dead links / static HTML | Fails least-surprise / testability | |
| Thin real LiveViews per nav item | Stub copy OK; real modules and routes | ✓ |

**User's choice:** Coherent bundle with **operator-ia.md**, **ranked jobs**, **nav order = triage spine** (posture → failures → sync/drift → search).

---

## Phoenix LiveView shell

| Option | Description | Selected |
|--------|-------------|----------|
| Stock Phoenix 1.7+; `scope "/ops"`; one `live_session :ops` | Matches OPSUI-07 | ✓ |
| Early streams / LiveDashboard / OIDC | Deferred to later phases | |

**User's choice:** **Boring Phoenix** defaults; verified routes; flash group; defer heavy patterns.

---

## Security model

| Option | Description | Selected |
|--------|-------------|----------|
| Documentation only | Industry precedent shows repeated failure | |
| Doc + prod fail-closed until explicit auth mode | OPSUI-08 satisfied structurally | ✓ |

**User's choice:** **README/SECURITY** plus **runtime guard** in prod; dev ergonomics explicit; telemetry low-cardinality per **`docs/search-backend-sre.md`**.

---

## Claude's Discretion

- Minor naming (exact env enum strings, web module prefix) left flexible where not locked in **44-CONTEXT.md**.

## Deferred Ideas

See **44-CONTEXT.md** `<deferred>` — phases 45–47 scope and optional future **`scrypath_ops`** Hex package.
