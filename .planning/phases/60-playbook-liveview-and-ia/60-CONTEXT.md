# Phase 60: Playbook LiveView and IA - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS-PB-02** (operators can **save**, **list**, **load**, and **run** a playbook from **`scrypath_ops`**) and **OPS-PB-04** (**`operator-ia.md`**, router, **`mix scrypath_ops.check_nav_contract`**). Runs use the same **bounded** **`SearchPlayground`** dispatch path and honesty posture as **`/ops/search`**. **Out of scope:** Phase 61 stub lifecycle matrix (**OPS-PB-05**), durable DB catalog, Monaco/IDE-grade editing, arbitrary server path pickers in the UI.

</domain>

<spec_lock>
## UI and copy (locked via UI-SPEC)

**Approved contract:** `.planning/phases/60-playbook-liveview-and-ia/60-UI-SPEC.md` — design system (daisyUI + `CoreComponents`), typography, semantic color roles, honesty panel placement, CTA copy, empty states, destructive confirm wording.

**Implementation note (aligned with decisions below):** v1.14 **does not** ship inline JSON editing. Validation/run error copy should steer operators to **Import playbook JSON** / **Reload list** / offline fix — omit or defer any “Edit JSON (if inline)” branch from the UI-SPEC until a later phase explicitly adds an editor.

Downstream agents MUST read **`60-UI-SPEC.md`** before implementing HEEx or copy.

</spec_lock>

<decisions>
## Implementation Decisions

### Surface boundary — dedicated LiveView vs SearchLive

- **D-01:** Ship a **dedicated** primary surface **`live "/ops/playbooks", …`** (exact module name at planner discretion, e.g. `PlaybookLive`) under the **same** `live_session :ops` as **`SearchLive`**. **Do not** fold save/list/load/run into **`SearchLive`** — keeps SRP, tests, and assigns bounded; avoids “kitchen sink” ops console drift.
- **D-02:** **Reuse, do not fork execution:** honesty panel + dispatch MUST call the same **`SearchPlayground.dispatch_search` / `dispatch_search_many`** seam (and adapter) as the playground after **`ScrypathOps.Playbook.V1.validate/1`**. Extract or share small **presentational** components / assigns helpers where it reduces duplication.
- **D-03:** **Cross-links:** From **`/ops/search`**, keep or add a clear affordance to **Saved playbooks** (and vice versa: “open in search” / export path) via **navigation links** and shared docs — **not** by nesting one LiveView inside another.

**Rationale (external patterns):** Postman/Grafana separate **artifact libraries** from **ad-hoc builders**; folding persistence into Explore/Search compounds state and regressions. Phoenix idiom: **one mount, one responsibility** per LiveView.

### Import UX — file vs paste

- **D-04:** Implement **both** import paths, converging on **one** function: `utf8_string → Jason.decode/1 → ScrypathOps.Playbook.V1.validate/1` (never `keys: :atoms!` on untrusted input — Phase 59).
- **D-05:** **Presentation:** **Upload-primary** — prominent **`allow_upload`** (`.json` / `application/json`, `max_entries: 1`, explicit **`max_file_size`**) with **`consume_uploaded_entries`**; secondary **collapsed** or tabbed **“Or paste JSON”** textarea with an explicit **Import** button (no decode on every `phx-change` for huge strings).
- **D-06:** **Guards:** `byte_size` cap on paste before decode; map **`Jason.DecodeError`** / validation errors to operator-safe messages (no raw body in logs). **Never** interpret client filename as a server filesystem path.

**Rationale:** Upload matches ticket/artifact workflows; paste matches Slack/docs snippets. Dual UI, **single trust boundary** — same as Postman/Insomnia mature import flows.

### Playbook directory — list, save, delete

- **D-07:** **Single writable workspace root** from environment **`SCRYPATH_OPS_PLAYBOOK_DIR`**, read in **`scrypath_ops/config/runtime.exs`** (same pattern as **`SCRYPATH_OPS_SCHEMAS`** / search bound env vars) into **`config :scrypath_ops, :playbook_workspace_dir`** (exact key at planner discretion). Normalize once to an **absolute** path **from env only** — not from LiveView params.
- **D-08:** **If env unset:** show **read-only packaged examples** from **`Application.app_dir(:scrypath_ops, "priv/playbooks")`** (or agreed fixture path) under a **labeled** “Examples (read-only)” region; **disable save and delete** to workspace with explicit copy pointing to env/docs. **Never** default writable location to **`priv/`** in release builds.
- **D-09:** **`:dev` / `:test`:** may set a **repo-local** or **tmp** default via **`config/dev.exs`** / **`config/test.exs`** so contributors and CI do not need manual env for **mutating** tests (use per-test tmp dirs where tests write/delete).
- **D-10:** **List:** only `*.json` directly under the workspace root (start **non-recursive** unless a future phase explicitly needs recursion with depth caps). **Save/delete:** **basename-only** API (strict `~r/…\.json$/` whitelist); `Path.join(root, name)` then **prefix / realpath** check so resolved path stays under workspace root (Phase 59 **D-05** spirit).
- **D-11:** **No in-UI directory picker** for v1.14 — changing roots is **admin/config** (Grafana-style **`GF_PATHS_DATA`** mental model), not browser-controlled.

### Loaded playbook — preview vs edit

- **D-12:** After **load**, show **read-only** JSON preview (pretty-printed from validated map) plus **Run saved playbook**; **no** inline **Save to disk** from a mutable editor for v1.14.
- **D-13:** **Content changes** round-trip through **Import playbook JSON** (upload or paste) or through **export from Search** then import — preserves one explicit gate for arbitrary bytes, avoids textarea/disk split-brain, minimizes Phase 61 test matrix and asset pipeline (no Monaco).
- **D-14 (optional nicety):** “Copy path” or doc-only hints for external `$EDITOR` are **nice-to-have**; not required for OPS-PB-02 closure.

**Rationale:** Argo/GitOps and hardened K8s workflows keep **UI truth read-only** vs **files/repo**; Terraform-style tools avoid raw bags without gates. Bounded OPSUI matches **preview + run + explicit import**.

### OPS-PB-04 — IA and nav contract

- **D-15:** Add **`/ops/playbooks`** to **`router.ex`** and to **`scrypath_ops/docs/operator-ia.md`** primary nav table + **`nav-contract` JSON** with label **`Saved playbooks`** (match **`60-UI-SPEC.md`** OPS-PB-04 note). **Placement:** **fifth** primary nav entry **after** **`/ops/search`** so triage order **posture → failed sync → sync/drift → search** remains intact and playbooks read as **post-search** learning/replay tooling.
- **D-16:** Extend JTBD prose only as needed so the new row is honest (no duplicate “phase N” planning voice in **`guides/`** — follow existing IA tone).

### Claude's Discretion

- Exact LiveView module name; upload `auto_upload` vs explicit button; whether examples use a **second** assign list vs merged list with badges; minor aria / flash wording not covered by UI-SPEC.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **OPS-PB-02**, **OPS-PB-04** normative text.
- `.planning/ROADMAP.md` — Phase **60** success criteria.
- `.planning/PROJECT.md` — v1.14 B2 operator playbooks vision, bounded OPSUI.
- `.planning/phases/60-playbook-liveview-and-ia/60-UI-SPEC.md` — Approved UI/copy/visual contract (see `<spec_lock>`).

### Prior phase decisions

- `.planning/phases/59-playbook-schema-and-persistence-mvp/59-CONTEXT.md` — File-backed JSON, **`Playbook.V1`**, path safety, no secrets in JSON, dispatch-only payload.
- `.planning/phases/58-core-library-and-doc-qol-b1/58-CONTEXT.md` — Doc-contract boundaries for new ops surfaces where relevant.

### Operator docs and code

- `scrypath_ops/docs/playbook-schema-v1.md` — Normative playbook fields and caps.
- `scrypath_ops/docs/operator-ia.md` — Nav contract source of truth (must update with new route).
- `scrypath_ops/lib/scrypath_ops/playbook/v1.ex` — Codec + validation entrypoint.
- `scrypath_ops/lib/scrypath_ops/search_playground.ex` — Ceilings and **`dispatch_*`** integration.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — Live routes.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — Honesty + bounded run patterns to mirror.
- `scrypath_ops/config/runtime.exs` — Pattern for env-driven operator config.

### Guides

- `guides/multi-index-search.md` — Federation authority for run-error “next doc” links when mode is **`search_many`**.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ScrypathOpsWeb.Live.SearchLive`** — Honesty panel, bounded dispatch UX; patterns to extract or mirror (not duplicate business logic).
- **`ScrypathOps.SearchPlayground`** — Single execution seam for run; reuse caps/validation helpers where applicable.
- **`ScrypathOps.Playbook.V1`** — `validate/1`, `encode/1` / decode path for import and pre-run checks.
- **`ScrypathOpsWeb.CoreComponents`** + daisyUI — Shell per **`60-UI-SPEC.md`**.

### Established Patterns

- **`live_session :ops`** with **`ScrypathOpsWeb.Live.OnMount`** — New LiveView should mount consistently with other **`/ops`** surfaces.
- **Nav contract** — Embedded JSON between `nav-contract-begin/end` in **`operator-ia.md`** must match **`router.ex`** labels/order; **`mix scrypath_ops.check_nav_contract`** enforces this.

### Integration Points

- New **`live "/ops/playbooks", …`**; optional links from **`SearchLive`** template; runtime config for **`SCRYPATH_OPS_PLAYBOOK_DIR`**; **`Phoenix.LiveView` upload** APIs for import.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** discuss areas with **parallel subagent research**; recommendations above synthesize those reports into one coherent MVP: **dedicated LiveView**, **upload-primary + paste-secondary import**, **env-driven workspace + optional read-only `priv` examples**, **read-only preview + run (no inline save-to-disk editor)**, **nav fifth slot “Saved playbooks”** after search.
- External analogues explicitly weighed: **Postman collections vs builder**, **Grafana dashboards vs Explore**, **Kibana saved-object sprawl (avoid)**, **Argo/K8s read-only UI truth**, **Terraform typed forms vs raw JSON**, **Grafana/Docker data path** admin configuration.

</specifics>

<deferred>
## Deferred Ideas

- **Inline / Monaco JSON editor** with save-to-disk — defer until there is explicit product pressure and test budget; **Import** remains the safer write path.
- **In-UI workspace root picker** or multi-root catalogs — conflicts with Phase 59 single-operator file bus; revisit with shared OPSUI + authz story.
- **Embedding playbook UI inside `SearchLive`** (drawer-first) — only if future scope collapses list/load/run to “serialize current session” only; current roadmap needs explicit library UX.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase **60**.

</deferred>

---

*Phase: 60-playbook-liveview-and-ia*  
*Context gathered: 2026-04-22*
