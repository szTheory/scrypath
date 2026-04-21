---
phase: 47
slug: verification-hardening
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-21
reviewed_at: 2026-04-21T00:00:00Z
---

# Phase 47 — UI verification contract

> Phase **47** does **not** introduce new operator surfaces. Automated checks must preserve **copy, structure, and honesty semantics** already locked for OPSUI.

**Normative design contracts (read before changing assertions):**

- `.planning/phases/46-search-federation-honesty/46-UI-SPEC.md` — search / federation strip, CTAs, partial vs hard-error copy, accent usage, **`data-testid`** conventions for **`/ops/search`**.
- `.planning/phases/44-opsui-foundations/44-UI-SPEC.md` — shell, nav density, **`live_session :ops`** expectations (where still applicable).
- `scrypath_ops/docs/operator-ia.md` — heading spine, primary nav order, route table vs **`router.ex`**.

**In scope for Phase 47 verification:**

- **`Phoenix.LiveViewTest`** and narrow **markdown / router** contract tests under **`scrypath_ops/test/`** that pin the above — not full-page HTML snapshots.

**Out of scope:**

- New visual design tokens, new screens, or shadcn-style component work (none planned).
