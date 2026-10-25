# Phase 177: Shared Patterns and Delivery Proof - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 5 durable file groups; six existing UI surfaces audited as scope, not presumed edits  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `DESIGN.md` (root, create) | documentation | transform / reference | `scrypath_ops/assets/css/DESIGN-TOKENS.md` | role-match |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` (update) | documentation | transform / reference | existing file; `scrypath_ops/assets/css/app.css` is the implementation authority | exact |
| `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` (update if needed) | test | transform / contract | existing test | exact |
| `.planning/phases/177-shared-patterns-and-delivery-proof/177-OPUX-TRACE.md` (new trace; exact filename/placement is discretionary) | documentation / evidence record | transform / reference | `.planning/milestones/v1.42-phases/172-consistent-operator-ui-and-verified-recovery/172-VERIFICATION.md` | role-match |
| Six current operator LiveViews / shared OpsUi and CSS files (only if audit proves drift) | component / stylesheet | request-response rendering and event-driven UI | `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`; `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`; `scrypath_ops/assets/css/app.css` | exact |

The six audit targets are Control Room, Search health (`posture_live.ex`), Failed sync work, Sync and drift, Search, and Playbooks. Context explicitly allows evidence-based source corrections but no source edits should be assumed before rendered inspection. No new dependency, test framework, evidence service, or fixed component count is implied. Existing prior phase receipts remain linked evidence, not modified files.

## Pattern Assignments

### Root `DESIGN.md` and `DESIGN-TOKENS.md` (documentation, transform/reference)

**Analog:** `scrypath_ops/assets/css/DESIGN-TOKENS.md` (tracked).

Use the existing catalog's implementation-link convention and concise tables: its lines 1–6 declare `app.css` as the value authority and state that the catalog describes it. Lines 8–25 explain how theme utilities and reusable `.ops-*` classes are assigned; lines 27–43 list semantic colors, and lines 66–77 describe elevation tokens and consumers. Keep the new root `DESIGN.md` a concise map of demonstrated shared vocabulary and component usage; keep token values and detailed token roles in the existing catalog. Reconcile superseded rules concretely against `app.css` instead of copying obsolete claims.

The token catalog is self-analogous for edits: verify each description against the current stylesheet and exported `OpsUi` components. Do not elevate the exploratory brand-book into a binding UI contract.

### `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` (test, transform/contract)

**Analog:** itself (tracked), lines 136–150.

The test dynamically scans `OpsUi` exports (lines 137–139), reads the catalog (141), and checks every export has a catalog entry (145–146). The current fixed count assertion, `assert length(exports) == 49` at line 143, conflicts with the locked no-arbitrary-count decision; retain the dynamic coverage and role/contract assertions while removing that count. Extend only for a concrete contract gap found during audit. This is ExUnit source-inspection style; no new test harness is needed.

```elixir
exports =
  Regex.scan(~r/^\s*def (ops_\w+)\(/m, ops_ui())
  |> Enum.map(fn [_, name] -> name end)

catalog = File.read!(@token_catalog)
missing = Enum.reject(exports, &String.contains?(catalog, "`#{&1}`"))
assert missing == [], "Add these OpsUi exports to DESIGN-TOKENS.md: #{inspect(missing)}"
```

### Conditional UI corrections (LiveView/component/CSS, request-response + event-driven)

**Analogs:** `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` (tracked), lines 29–49 and 76–110; `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (tracked), lines 1–10 and 134–162.

LiveView behavior is event-driven: `handle_event/3` computes a fresh summary and branches on completeness, retaining the last successful observation and reporting an incomplete refresh through explicit assigns (ControlRoom lines 29–49). Rendering uses shared `OpsUi` components within `Layouts.app`, and semantic sections provide labelled headings and conditional action slots (ControlRoom lines 76–110; OpsUi `ops_section/1` lines 134–162). Prefer the shared component for demonstrated repeated grouping/actions/status, preserving surface-specific wording and semantics. Existing application imports and `Layouts.app` shell pattern should be retained.

The concrete section component pattern is:

```elixir
<section aria-labelledby={@heading_id} class={["space-y-3", @class]}>
  <.ops_toolbar class="items-start gap-3">
    ... heading, optional subtitle/meta, optional actions ...
  </.ops_toolbar>
  {render_slot(@inner_block)}
</section>
```

For CSS, `scrypath_ops/assets/css/app.css` is the tracked source of truth named by the catalog. Changes should reuse existing semantic theme variables and `--ops-*`/`*-ops-*` tokens. Inspect exact nearby rules during implementation; this map does not infer a visual mismatch from static source.

### `177-OPUX-TRACE.md` (documentation/evidence record, transform/reference)

**Analog:** `.planning/milestones/v1.42-phases/172-consistent-operator-ui-and-verified-recovery/172-VERIFICATION.md` (tracked), especially its YAML front matter and explicit recorded-source receipt, plus `.planning/REQUIREMENTS.md` lines 42–44 for the canonical OPUX-26–28 descriptions.

Use one row per OPUX-09–28 with links to authoritative existing phase verification/behavior reports and their recorded source SHAs, then reviewed PR source SHA and each applicable required check's run link and exact tested SHA. Mark local, hosted, and unavailable evidence distinctly. Link to receipts; do not copy reports into a second archive. Record release/no-release and cleanup/retained-preview facts in the appropriate closeout records, with final-source attestation after bookkeeping. Script-required job names are defined at `scripts/ci_monitor.cjs:13–20`: `core (required)`, `package (required)`, `repository-contracts (required)`, `backend (required)`, `ecommerce-mounted (required)`; advisory readiness names are `coverage (advisory)` and `closeout-attestation`.

Prior verification paths must stay within their actual source/scenario bounds. The tracked v1.42 receipt is under `.planning/milestones/v1.42-phases/...`; there is no tracked `.planning/phases/172-...` receipt path in this worktree.

## Shared Patterns

### Component and token authority

**Sources:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1–10,134–162`, `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md:1–25`.

`OpsUi` is the Phoenix function-component vocabulary, `app.css` owns token values/styles, and `DESIGN-TOKENS.md` catalogs them. Keep these roles aligned; avoid a component tally as a design goal.

### Evidence boundaries

**Sources:** `.planning/milestones/v1.42-phases/172-consistent-operator-ui-and-verified-recovery/172-VERIFICATION.md:1–6,95–99`, `.planning/REQUIREMENTS.md:42–44`, `scripts/ci_monitor.cjs:13–20`.

Every claim should point to the receipt and source tested. A local phase result is not hosted PR/CI evidence, and a green branch alone does not prove individual requirements. Keep unavailable hosted review/check evidence unresolved.

## No Analog Found

None. The new design guide can follow the existing token-catalog documentation style; the phase trace can follow existing source-bound verification receipts. The trace itself has no same-purpose 20-row artifact in the current phase scope, so the verification receipt is a structural analog, not a pre-existing trace to duplicate.

## Metadata

**Analog search scope:** `scrypath_ops/lib/scrypath_ops_web/{components,live}`, `scrypath_ops/assets/css`, `scrypath_ops/test/scrypath_ops_web`, `.planning/phases`, `.planning/milestones`, `scripts/ci_monitor.cjs`, and root requirements.  
**Tracked-source gate:** Every code/docs analog named above was checked with `git ls-files`; all are tracked. Phase 177 validation metadata itself is a generated/planning artifact and not used as an implementation analog.  
**Pattern extraction date:** 2026-10-11.
