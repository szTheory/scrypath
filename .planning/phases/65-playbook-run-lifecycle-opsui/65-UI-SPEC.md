# Phase 65 — UI design contract (OPSUI)

**Phase:** 65 — Playbook run lifecycle  
**Surface:** `ScrypathOpsWeb.PlaybookLive` (`/ops/playbooks`)  
**Status:** Locked for planning (derived from `65-CONTEXT.md`)

---

## Scope

Operator-facing LiveView for **`playbook_format: 1`** playbooks: catalog, preview, explicit run lifecycle, structured failure surface. DaisyUI / Tailwind per existing OPSUI.

---

## States and transitions

| UI state | Meaning | Visible cues |
|----------|---------|----------------|
| **Idle** | No in-flight run; draft may or may not be loaded | Run / Run now enabled when backend + allowlist OK; no spinner |
| **Running** | Async playbook execution in progress | Primary run actions disabled; spinner + elapsed time |
| **Success** | Last run completed `{:ok, _}` | Success panel with `run_result_summary`-equivalent copy; flash may show short toast |
| **Failure** | Last run completed `{:error, reason}` or timeout/cancel | Error panel: `failure_class`, human `message`, doc links, **Copy diagnostics** (allowlisted JSON) |

**Transitions:** idle → running (user run); running → success | failure | idle (cancel or superseded load); success/failure → running on new run; new catalog load while running **cancels async + resets to idle** (per D-14).

**Disconnect:** remount shows idle without fabricated history; optional neutral info line only (D-15).

---

## Controls and labels

| Control | Action | Notes |
|---------|--------|------|
| **Load** | Stages playbook JSON into preview; **does not** run | Copy must not imply execution (D-01) |
| **Run now** (catalog) | Decode + validate + set `draft_playbook` + **same** run pipeline as preview Run | Unambiguous execution label (D-02) |
| **Run saved playbook** (preview) | Same pipeline when `draft_playbook` valid | Single code path with catalog (D-03) |
| **Cancel run** | Visible only in **Running**; `cancel_async` for run task | Best-effort copy (D-13) |

Adjacent to Run / Run now: show **basename or title + mode** so operator sees what will execute (specifics).

---

## Failure surface (OPS3-02)

- Prominent **failure class** + **message** (not flash-only).
- **Primary** doc link + up to **two** related links; URLs resolved via **DocResolver**, not hard-coded scattered strings in HEEx (D-18).
- **Copy diagnostics** produces JSON with stable keys: `failure_class`, `reason`, `message`, `copy` (allowlist), `doc` — **no secrets** (threat model).
- Replace `search_many`-only guide link with **registry-driven** links for all modes (D-20).

---

## Accessibility

- Run / Cancel: `type="button"`, disabled state reflected in `disabled` + `aria-busy` on region where appropriate.
- Error panel: `role="alert"` for terminal failure message.
- Spinner region: `aria-live="polite"` for phase changes if not too noisy.

---

## Non-goals (this phase)

- i18n / Gettext for strings (English-first).
- Durable run history or reconnect (deferred in CONTEXT).

---

## UI-SPEC complete

This contract is sufficient for `/gsd-plan-phase 65` and `/gsd-execute-phase 65` without further visual mockups.
