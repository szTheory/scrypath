# Phase 48 — Technical research

**Phase:** 48 — IA and JTBD alignment  
**Question:** What do we need to know to plan this phase well?

## Summary

Phase 48 hardens **information architecture** between **`operator-ia.md`**, **`router.ex`**, and **ops chrome** while improving **posture** as the on-call entry surface. Elixir/Phoenix patterns favor a **single compile-time or runtime source** for nav (`Nav.primary/0`) consumed by **layouts** and verified by **tests** and optionally **`mix`** so CI catches drift without brittle full-markdown regex.

## Findings

### 1. Single source of truth for primary nav

- **Pattern:** Define `ScrypathOpsWeb.Nav` (or `ScrypathOpsWeb.OperatorNav`) with `primary/0` returning an ordered list of `%{path: ..., label: ...}` using **`~p`** sigils for paths (e.g. `~p"/ops/posture"`).
- **Why:** CONTEXT **D-03** / **D-05** — avoids triple maintenance (HEEx literals, doc table, test strings). Router remains authority for **which** `live` routes exist; Nav is the **curated** subset for chrome.
- **Router parity:** Existing **`OperatorIaContractTest`** already asserts all four `/ops/...` paths appear in **`operator-ia.md`**. Extend to: (a) ordered nav from **`Nav.primary/0`**, (b) labels match **Top nav label** column intent, (c) every `live("/..."` under **`live_session :ops`** is either in **`Nav.primary/0`** or covered by an explicit escape hatch (default: none — all four must appear).

### 2. Doc ↔ code sync without hand-editing tables

- **Pattern A:** Delimited machine block inside **`operator-ia.md`** (e.g. HTML comment `<!-- nav-contract:begin -->` … `<!-- nav-contract:end -->` wrapping JSON/YAML) regenerated or verified by **`mix scrypath_ops.check_operator_ia`** (name illustrative — pick under **`lib/mix/tasks/`** in **`scrypath_ops`**).
- **Pattern B:** `mix … --write` rewrites only the fenced block from **`Nav.primary/0`**; `mix …` (default) compares and exits non-zero on drift — fits CI in **`scrypath_ops`** root **`mix test`** or a dedicated **`mix precommit`** alias.
- **Why:** CONTEXT **D-04** — personas/JTBD prose stays hand-written; nav table stays mechanically aligned.

### 3. Posture “next checks” (OPSUX-02)

- **UX pattern:** One **headline** state (Healthy / Degraded / Broken or equivalent) + short **evidence** line from existing assigns (`aggregate_error_count`, `:empty_allowlist`, `:missing_backend`, row errors).
- **Next checks:** Fixed ordered list **≤ 5** items; each: imperative copy + **one** primary egress (`~p` to another ops surface, `https://` to repo **`guides/`**, or monospace **`mix …`** string from **`guides/operator-mix-tasks.md`**).
- **Implementation:** New HEEx region with stable **`data-testid="posture-next-checks"`** (and optional **`<details>`** for link-only runbook per **D-08**). No new write-side recovery actions (**D-09**).

### 4. Testing strategy

- **Contract tests:** Extend **`operator_ia_contract_test.exs`** — keep compile-time file reads; add assertions on **`Nav`** module API and order.
- **LiveView tests:** Add or extend **`posture_live_test.exs`** (if missing, create under **`scrypath_ops/test/scrypath_ops_web/live/`**) using **`Phoenix.LiveViewTest`** for presence/order/max length of next-check list — avoid full copy equality (**CONTEXT D-10**).

### 5. Tooling / roadmap

- **`gsd-sdk query roadmap.get-phase 48`** currently returns **`malformed_roadmap`** (phase listed in summary but no **`### Phase 48:`** detail block). Fixing **`ROADMAP.md`** is **meta** (CONTEXT deferred); recommend a follow-up quick task outside product scope unless it blocks execution tracking.

### 6. Security posture (read-only ops shell)

- Threats are mostly **integrity** (misleading nav or next-step pointers) and **information disclosure** (pointing operators at wrong docs). No new authenticated surfaces; **`/ops`** remains dev-oriented with existing auth boot guards from prior phases.

---

## Validation Architecture

Nyquist / execution feedback for this phase:

| Dimension | Strategy |
|-----------|----------|
| **Automated regression** | `cd scrypath_ops && mix test` after each logical commit; contract test + new LiveView tests + optional `mix check_operator_ia` in CI or alias |
| **Sampling** | After Wave 1 (Nav): full **`mix test`**. After Wave 2 (doc check + posture): full **`mix test`** again |
| **Manual spot-check** | Optional: open **`/ops/posture`** in dev — headline + next checks read sensibly for empty allowlist and healthy table (not a CI gate) |

**Dimension 8 (continuous validation):** Every plan task maps to **`mix test`** and/or the new **`mix`** check with grep-verifiable acceptance criteria in PLAN files.

---

## RESEARCH COMPLETE
