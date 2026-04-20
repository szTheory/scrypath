# Phase 44 — UI design contract (OPSUI foundations)

**Selected framework:** Phoenix LiveView 1.8+ (stock layouts, `~p`, `<.flash_group>`)

**Status:** Ready for planning  
**Source:** Phase 44 CONTEXT decisions (D-05–D-13) + ROADMAP OPSUI-06/07

---

## Product surface

- **Audience:** Repository maintainers and early adopters running the optional operator app—not end users of host applications.
- **Primary shell:** Conventional Phoenix root + app layouts, operator-scoped routes under `/ops`, dedicated `*OpsWeb` namespace (no `ScrypathWeb` reuse for operator routes).
- **Depth:** Thin stub LiveViews with honest “ships in phase 45/46” copy; no real triage, search, or federation inspectors in this phase.

---

## Information architecture

**Canonical doc:** `scrypath_ops/docs/operator-ia.md` (personas, JTBD table, nav ↔ route mapping).

**Primary nav order (force-ranked):**

1. Posture / health (phase 45) — highest priority slot in shell.
2. Failed sync work (phase 45).
3. Sync / drift read-only + links to Mix tasks and library guides.
4. Bounded search / federation honesty (phase 46) — **not** co-equal with triage in prominence.

**Nav rules:**

- Every item is a **real route** into a LiveView module (no `href="#"` off LiveView).
- Any PR that adds or reorders nav **must** update `operator-ia.md` in the same change.

---

## Visual and layout

- **Chrome:** Boring Phoenix defaults: header with app name, primary nav list, flash group, simple content area.
- **Styling:** Default Phoenix/Tailwind stack as generated; no custom design system beyond semantic HTML and Phoenix core components.
- **Responsive:** Desktop-first; mobile usable but not optimized (operator tooling assumption).

---

## Interaction patterns

- **Navigation:** `~p` links between operator LiveViews; `live_session :ops, on_mount: [...]` wraps all `/ops` LiveViews for shared assigns and future auth halting.
- **Feedback:** Flash for success/error; generic error pages via `controllers/error_*`.
- **Empty / stub states:** Single short heading + one paragraph explaining phase boundary and pointer to roadmap phase.

---

## Accessibility (baseline)

- Nav uses semantic lists or nav landmarks; buttons/links have visible text (no icon-only primary actions).
- Flash messages are announced via LiveView defaults where applicable.

---

## Out of scope (explicit)

- LiveView streams, LiveDashboard in prod, Oban.Web UI, OIDC product flow, heavy i18n, non-default asset pipelines (per CONTEXT D-12).
- Automated LiveView tests in CI (phase 47).

---

*UI-SPEC for phase 44 — aligns plans with OPSUI-06 and OPSUI-07.*
