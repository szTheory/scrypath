# Phase 49 — Technical Research

**Question:** What do we need to know to plan visual hierarchy, theming, and Phoenix ergonomics for ScrypathOps `/ops`?

**Sources:** `49-CONTEXT.md`, `49-UI-SPEC.md`, `layouts.ex`, `root.html.heex`, `app.css`, Phoenix LiveView layout docs, daisyUI theme behavior.

---

## Findings

### 1. Theme contract (OPSUX-04)

- **Inline head script** in `root.html.heex` already implements `system` (no `data-theme`, no `phx:theme` key), explicit `light`/`dark` with `localStorage` key **`phx:theme`**, and `storage` sync — preserve verbatim semantics (**D-04–D-06**).
- **Tailwind `@custom-variant dark`** in `app.css` line 100 matches **only** `[data-theme=dark]`. daisyUI **system** dark uses **`prefersdark: true`** on the dark theme plugin — components using semantic tokens track OS dark; **`dark:`** utilities do **not** unless the variant is extended or usage avoids `dark:` for system-dependent chrome (**D-07**).
- **`theme_toggle`** knob uses `[[data-theme=light]_&]` and `[[data-theme=dark]_&]` only — in **`system`** mode neither matches, so the pill stays visually in the first third (**D-08** bug).

### 2. Layout shell (OPSUX-03)

- **`:ops`** `Layouts.app/1` already centralizes nav, `theme_toggle`, `main` with **`max-w-3xl`**, and **`flash_group`** after `main` — correct integration point for **width variant** (`max-w-7xl` / full) via new assign or attr (**D-02**).
- LiveViews already use **`Layouts.app flash={@flash} shell={@shell}`** and **`OnMount`** sets **`shell: :ops`** — width can be passed as **`ops_main_width={:wide}`** (or default) per route without router changes.

### 3. Phoenix ergonomics (OPSUX-05)

- **`live_title`** in root uses suffix **` · Phoenix Framework`** — generic generator branding (**D-16**).
- Marketing **`home.html.heex`** uses **`Layouts.flash_group`** alone (no `Layouts.app`) — **not** a duplicate of ops `flash_group` inside `Layouts.app`; document boundary (**D-17**).
- Internal ops links should remain **`<.link navigate={~p"…"}>`** / **`push_patch`** per CONTEXT (**D-18**).

### 4. LiveView surface inventory

| LiveView        | `page_title`           | Wide layout candidate                          |
|----------------|------------------------|-----------------------------------------------|
| PostureLive    | Posture / health       | default + dense tables if any                 |
| FailedSyncLive | Failed sync work       | default + table                             |
| SyncDriftLive  | Sync / drift           | default + tables                            |
| SearchLive     | Search & federation    | **wide** (playground + honesty panels)        |

### 5. Testing boundary (Phase 48 vs 49)

- **Do not** duplicate **`operator_ia_contract_test`** nav order/label assertions (**D-19**). Phase **49** adds **structural** tests: `:ops` shell, `page_title`, optional scaffold markers, single document-level flash pattern on `/ops`.

---

## Recommendations for planning

1. **Wave 1 — Scaffold + layout width:** New **`ScrypathOpsWeb.OpsUi`** (or extend **`CoreComponents`**) with **`ops_page_header`**, **`ops_panel`**, optional **`ops_scaffold`**, plus **`layouts.ex`** attr for **`ops_main_width`** enum.
2. **Wave 2 — Theme coherence:** Extend **`@custom-variant dark`** *or* document + restrict `dark:` usage; fix **`theme_toggle`** effective state; adjust **`live_title`** suffix for product branding.
3. **Wave 3 — LiveViews:** Refactor four LiveViews to compose scaffold, apply **UI-SPEC** copy for CTAs and empty states, set **`ops_main_width={:wide}`** on Search (and others if needed).
4. **Wave 4 — Verification:** New **`ops_shell_contract_test.exs`** (or equivalent), **`mix test`**, manual light/dark checklist note in SUMMARY.

---

## Validation Architecture

Phase validation uses **ExUnit** in `scrypath_ops`:

- **Quick command:** `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` (after file exists) plus targeted LiveView tests if extended.
- **Full command:** `cd scrypath_ops && mix test`
- **Sampling:** After each plan wave, run **quick** then **full** before closing the phase.
- **Manual:** Visual pass **light / dark / system** on all four `/ops` routes (checklist in roadmap success criteria) — cannot fully automate contrast perception in CI.

Nyquist **Dimension 8** is satisfied by mapping each plan’s tasks to automated `mix test` slices and documenting the manual theme checklist in `49-VALIDATION.md`.

---

## RESEARCH COMPLETE
