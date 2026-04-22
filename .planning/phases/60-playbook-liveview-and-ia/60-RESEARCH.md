# Phase 60 — Technical Research

**Question:** What do we need to know to plan **Playbook LiveView and IA** (OPS-PB-02, OPS-PB-04) well?

## Summary

Phase 60 adds a **dedicated** `/ops/playbooks` LiveView (not folded into `SearchLive`), file-backed workspace under **`SCRYPATH_OPS_PLAYBOOK_DIR`** with **basename-only** APIs and **prefix/realpath** containment, **upload-primary + paste-secondary** import converging on **`Jason.decode/1` → `Playbook.V1.validate/1`**, read-only JSON preview after load, and **run** paths that mirror **`SearchLive`** by calling **`SearchPlayground.dispatch_search/3`** and **`dispatch_search_many/2`** after building keyword opts from the validated playbook (including `page.size` via **`SearchPlayground.validate_page_size/1`**). **OPS-PB-04** extends **`Nav.primary/0`**, **`router.ex`**, **`operator-ia.md`** (nav table + **`nav-contract`** JSON), and keeps **`mix scrypath_ops.check_nav_contract`** green.

## Code anchors

| Concern | Primary files |
|--------|----------------|
| Honesty + bounded run UX | `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` (`Non-production search playground`, `format_run_error`, telemetry `[:scrypath_ops, :search_playground, :run]`) |
| Dispatch seam | `scrypath_ops/lib/scrypath_ops/search_playground.ex` — `dispatch_search/3`, `dispatch_search_many/2`, `validate_page_size/1`, adapter env |
| Playbook validation | `scrypath_ops/lib/scrypath_ops/playbook/v1.ex` — `decode/1`, `validate/1`, banned keys, schema string fields |
| Allowlist + Scrypath opts | `scrypath_ops/lib/scrypath_ops/schemas.ex` — `allowlist/0`, `scrypath_opts/0` |
| Ops routes | `scrypath_ops/lib/scrypath_ops_web/router.ex` — `live_session :ops` |
| Primary nav source of truth | `scrypath_ops/lib/scrypath_ops_web/nav.ex` — `primary/0` |
| Nav doc + contract fence | `scrypath_ops/docs/operator-ia.md` — markers `<!-- scrypath:nav-contract-begin -->` … `end` |
| Contract enforcement | `scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex` |
| Runtime env pattern | `scrypath_ops/config/runtime.exs` — `SCRYPATH_OPS_SCHEMAS`, search playground env cases |
| Test patterns | `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`, `test/support/search_playground_stub_adapter.ex` |

## Run pipeline (from validated playbook)

1. **`Playbook.V1.validate/1`** already ensures shapes, caps, and banned option keys.
2. Resolve **`schema`** strings to modules with the **same** rule as **`SearchLive`** (`String.to_existing_atom` per segment + membership in **`Schemas.allowlist/0`**). Reject if not in allowlist (surface as operator-safe run error, not stack trace).
3. Build **`Keyword.t`** for Scrypath: start from **`Schemas.scrypath_opts/0`**, merge **`page`** from playbook `opts` when present, run **`SearchPlayground.validate_page_size/1`** on effective size before dispatch.
4. **`"search"`** → **`SearchPlayground.dispatch_search(mod, q, merged_opts)`**.
5. **`"search_many"`** → map `entries` to `{mod, q, eopts}` tuples compatible with stub adapter / real adapter, then **`SearchPlayground.dispatch_search_many/2`**.

Optional: centralize steps 2–5 in a small module (e.g. **`ScrypathOps.Playbook.Runner`**) to keep **`PlaybookLive`** thin and testable without LiveView.

## Filesystem workspace

- **Writable root:** only from **`SCRYPATH_OPS_PLAYBOOK_DIR`** parsed in **`runtime.exs`** into **`Application.get_env(:scrypath_ops, :playbook_workspace_dir)`** (exact key chosen in implementation). Normalize to **absolute** path once at config load.
- **Release:** if unset, **no** default under `priv/` for writes; UI shows read-only **examples** from **`Application.app_dir(:scrypath_ops, "priv/playbooks")`** (or agreed path) and disables save/delete with explicit copy.
- **Dev/test:** `dev.exs` / `test.exs` may set tmp/repo-local defaults; tests should use **`System.tmp_dir!()`**-based roots per test.
- **List:** `*.json` non-recursive in workspace root.
- **Save/delete:** basename whitelist `~r/\A[\w.\-]+\.json\z/` (adjust if CONTEXT stricter), `Path.join` + **realpath/prefix** check under root (Phase 59 spirit).

## LiveView uploads

- **`allow_upload`** with `.json` / `application/json`, **`max_entries: 1`**, explicit **`max_file_size`** aligned with paste **`byte_size`** cap in CONTEXT.
- **`consume_uploaded_entries/3`** on import submit; paste path uses single **`phx-submit`** “Import” to avoid decode on every change.

## IA / nav

- Insert **`%{path: ~p"/ops/playbooks", label: "Saved playbooks"}`** as **fifth** entry **after** search in **`Nav.primary/0`**.
- Add **`live("/playbooks", PlaybookLive)`** inside the same **`live_session :ops`** as search.
- Update **`operator-ia.md`**: nav table row + JTBD line for saved playbooks; regenerate **`nav-contract`** JSON to match **`Nav.primary/0`** (task may run **`mix scrypath_ops.check_nav_contract`** which can rewrite fence — follow task’s Mix output).
- **`SearchLive`**: add subdued nav link per D-03 (e.g. near header or secondary row) to **`~p"/ops/playbooks"`**.

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Path traversal / LFI | Basename-only API + resolved path under root only |
| Atom exhaustion from JSON | Already avoided in **`Playbook.V1`**; runner uses **`to_existing_atom`** only for allowlisted schema strings |
| XSS from playbook JSON in preview | Render via **`Phoenix.HTML.html_escape`** / `<pre>` with escaped content or `JSON.encode!` display pattern used elsewhere |
| Operator pastes secrets | Honesty panel + banned keys in playbook; steer copy away from raw logging |
| Nav drift | **`check_nav_contract`** in CI / test suite |

## Open choices (planner discretion)

- Extract **`module_in_allowlist/2`** from **`SearchLive`** to shared module vs duplicating in **`PlaybookLive`** / **`Playbook.Runner`** (prefer single source if trivial).
- Upload **`auto_upload`** vs explicit button — CONTEXT allows either; pick one consistent with **`60-UI-SPEC.md`**.

## Validation Architecture

**Nyquist / execution feedback**

- **Framework:** ExUnit (`mix test` in `scrypath_ops/`).
- **Quick command:** `mix test test/scrypath_ops/playbook/` (and targeted LiveView tests once added).
- **Full command:** `mix test` from repo root or `scrypath_ops` app root per CI.
- **Sampling:** After each task that changes executable code, run the **quick** command covering new modules. After the final wave, run **full** `mix test` for `scrypath_ops` plus **`mix scrypath_ops.check_nav_contract`**.
- **Manual spot-check:** Load `/ops/playbooks` in dev with stub adapter — save → reload → run stub path (success criteria 1).

Dimension 8 coverage: every plan lists concrete **`mix test`** (or Mix task) assertions in task `<acceptance_criteria>`; path-safety and nav contract have dedicated automated checks.

---

## RESEARCH COMPLETE

Phase 60 implementation can proceed with dedicated LiveView, env-backed workspace module, runner/dispatch alignment with **`SearchPlayground`**, and nav/IA updates guarded by **`check_nav_contract`**.
