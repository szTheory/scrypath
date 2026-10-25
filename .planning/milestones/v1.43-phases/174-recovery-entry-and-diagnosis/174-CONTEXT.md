# Phase 174: Recovery Entry and Diagnosis - Context

**Gathered:** 2026-10-10
**Status:** Discussion complete; ready for the comp-first UI contract
**Decision authority:** The maintainer asked to automatically follow the recommendations and keep the approved phase moving. These are the agent's synthesized defaults adopted under that instruction; they are not verbatim user selections or a simulated interview/reviewer approval.

<domain>
## Phase Boundary

Deliver OPUX-16–OPUX-19 across the existing Control Room, Search health, and Failed sync work surfaces. Operators must be able to understand the current search state and affected scope, scan schema-specific evidence, discover only the safe supported recovery action, and carry an explicitly selected allowlisted schema through rendered recovery navigation and browser history.

Keep the existing six surfaces, shared Phoenix components, neutral theme foundation, host-owned authorization, retry eligibility, retained failure history, and operational evidence semantics. Do not add an operator surface, backend or core API, infrastructure automation, or new recovery capability. Phase 175 owns repair and verification; Phases 176–177 own Search/Playbooks and later cross-surface consolidation. This discussion chooses presentation and navigation behavior; it does not implement or verify product changes.
</domain>

<decisions>
## Implementation Decisions

### Control Room: current state, scope, and next safe action

- **D-01:** Lead with one concise health statement and the affected search scope, then one status-appropriate safe route into Search health for schema diagnosis. Keep Refresh in the shared toolbar; keep change verification and search exploration available as secondary intents. The Control Room is an orientation point, not a duplicate schema ledger.
- For `:degraded`, name the affected scope accurately and direct operators to inspect Search health. For `:unconfigured` or `:missing_backend`, keep setup guidance as the next step and do not frame retry or recovery as available. A healthy state must not imply document freshness or manufacture an incident.
- Remove repeated explanation and competing primary controls. Preserve full schema identity in the detailed schema records rather than forcing it into a fleet-level summary. This keeps the first screen actionable without expanding it into a dashboard.

### Search health: scannable schema records

- **D-02:** Keep one meaningful record/surface per schema in the established worst-first order. Put explicit state, the complete readable schema identity, relevant observed time, and the concise schema-specific next check in the record. Keep Backend and Queue as plain diagnostic groups within that record; use the existing section rhythm rather than adding an outer panel or nested diagnostic cards.
- Preserve the current ordering semantics: fetch errors first, then backend failures, then unobserved/failed/retrying queue signals, then clean records; ties remain alphabetic by module name unless visual evidence or a concrete requirement demonstrates a defect. Preserve the existing newest-evidence-first ordering on the separate Failed sync work list.
- Use text and restrained local cues together; severity cannot depend on hue. Keep long module names, timestamps, and diagnostic values readable by wrapping/reflow rather than shrinking them. A last success, zero errors, or an unavailable queue observation does not prove current document freshness or overall health.
- Keep the next-check link adjacent to the schema evidence it acts on and carry that exact schema identity into Failed sync work. Do not replace the current record model with a fleet table whose reasons/actions require extra expansion.

### Failed sync work: reason and eligibility before verbose evidence

- **D-03:** Before optional Diagnostics, show the failure reason, source-specific work identity (queue job or backend task), relevant attempt time, and whether the common supported retry is currently available. When the existing recovery policy allows retry, make the action discoverable in the row. When it does not, state why and provide the next safe observation or setup step; do not render an apparently available action that the server will reject without explanation.
- Keep raw metadata and verbose payload details in the existing disclosure. Keep an accepted retry receipt next to its original failed record and preserve the original failure history. An accepted replacement is not terminal success, and historical failure must not be relabeled or removed to make the page look green.
- Any retry still passes through the current schema/eligibility and host authorization checks at action time. The visual action must never imply that Scrypath owns the host's authorization policy or that a UI-only disabled state is a security boundary.

### Selected schema: URL-backed, revalidated handoffs

- **D-04:** Treat the canonical `schema` query parameter as the durable identity for a selected schema across recovery destinations. Keep it through refresh, back/forward, and schema-specific links; validate it against the current allowlist whenever a destination loads and again before an action. This matches the existing `OperatorSelection` seam and Phoenix LiveView's public/untrusted URL-parameter model.
- If an explicit target is invalid, removed, or unavailable, show an explicit unavailable state and prevent actions. Never silently fall back to the first or another schema. Preserve the current no-parameter behavior on pages that already default to the first allowlisted schema, unless the UI contract finds a concrete user-facing problem. When the selected schema changes, clear/invalidate schema-bound observations, pending receipts, and confirmations so evidence cannot bleed across targets.
- Verify the behavior through the rendered selector after choosing a non-first schema, then follow the real schema-specific handoff, refresh, and browser Back/Forward. Include invalid and newly unavailable targets and assert that no operation reaches a different schema.

### Shared quality and dependency posture

- **D-05:** Carry forward Phase 173's neutral visual foundation, explicit state text, restrained local status cues, shared action states, responsive behavior, and no-color-alone rule. Preserve native semantics, visible focus, keyboard operation, readable long values, and the existing standalone/mounted route prefixes. Status changes that do not move focus remain programmatically available without making the screen reader experience unnecessarily chatty.
- Reuse `OperatorSelection`, the established Ops components/tokens, and current LiveView navigation. Prefer a small local change or a little repeated code over adding a dependency; no new dependency or UI framework is justified for this phase. Do not copy third-party code without review.
- The decision review considered on-call/operator task order, product truth, visual hierarchy, keyboard/screen-reader and narrow-width use, Phoenix URL state, host security boundaries, stale evidence, and ongoing maintenance. Adversarial cases include a forged or removed schema parameter, stale browser history, a selector change while a retry receipt/confirmation exists, a missing backend or unconfigured host, unavailable queue data, retained failures after accepted retry, and long IDs/reasons on mobile.

### the agent's Discretion

The UI contract may settle exact copy, icon choice, responsive spacing/breakpoints, and whether the existing components need a small semantic improvement, using realistic light/dark comps and current source. Keep the hierarchy and safety rules above fixed. Reuse components where they express a repeated task; do not add an abstraction or dependency without a concrete repeated need. Keep routine human UAT and paid visual-judge services out of acceptance.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before designing, planning, or implementing.**

### Approved product scope and lifecycle

- `.planning/PROJECT.md` — product truth, UI lifecycle, verification, and operator quality defaults.
- `.planning/STATE.md` — Phase 173 evidence and exact next action; this phase work continues in the isolated Phase 173 worktree recorded there.
- `.planning/ROADMAP.md` — Phase 174 boundary, OPUX assignments, success criteria, and required ordering.
- `.planning/REQUIREMENTS.md` — approved OPUX-16–OPUX-19 acceptance requirements.
- `.planning/research/v1.43/SCOPE.md` — approved milestone boundaries, evidence strategy, and preservation rules.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — maintainer's observed recovery-surface issues and phase delivery sequence.
- `.planning/reference/OPERATOR-UI-QUALITY.md` — hierarchy, disclosure, operational truth, responsive, accessibility, and verification rules.
- `CONTRIBUTING.md` and `scrypath_ops/AGENTS.md` — repository gates and Ops-local implementation/test conventions.

### Prior design and recovery decisions

- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md` — locked neutral-state, shared-control, and dependency decisions to carry forward.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — Phase 173 visual/interaction contract and state language.
- `.planning/research/v1.42/UI-STRUCTURE.md` — observed recovery findings STR-01–STR-14, domain vocabulary, existing components, and tradeoffs; use as orientation and recheck current source.
- `.planning/research/v1.42/UI-SYSTEM.md` — historical shared component/token inventory; current source is authoritative.
- `.planning/research/v1.42/UI-AUTOMATION.md` — existing economical browser, LiveView, and mounted verification lanes.
- `scrypath_ops/docs/operator-ia.md` — operator personas, navigation model, and inspect/recover/verify job loop.
- `.planning/milestones/v1.42-phases/172-consistent-operator-ui-and-verified-recovery/172-CONTEXT.md` and `172-REVIEW.md` — archived prior UI decisions and observed recovery findings; recheck present source and do not replay completed fixes.

### Existing implementation and local technical guidance

- `scrypath_ops/lib/scrypath_ops/operator_selection.ex` — canonical allowlisted schema resolution and path construction.
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` — existing fleet summary, setup states, refresh, and intent hierarchy.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — current worst-first schema records and contextual Failed sync handoffs.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — URL selection resolution, retry eligibility, schema-change invalidation, rows, outcomes, and diagnostic disclosure.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — shared page structure, status, record, disclosure, action, and schema-select components.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — local context on LiveView navigation, URL state, and parameter validation; official versioned docs govern API details.
- `PRODUCT.md` and `DESIGN.md` are preserved as untracked user material in the root checkout at `/Users/jon/projects/scrypath/PRODUCT.md` and `/Users/jon/projects/scrypath/DESIGN.md`; they are not copied into this isolated worktree. Consult those root copies if the UI-contract work needs detail beyond the committed scope and refinement references.

### Primary external guidance

- [Phoenix LiveView v1.1.33 API](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html) — current locked version documents `handle_params/3` and warns that params are untrusted; validate/authorize before fetch or mutation.
- [WCAG 2.2: Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) — pair color-coded state with another visible cue.
- [WCAG 2.2: Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) — expose non-focus-moving status changes programmatically and avoid needless interruption.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ScrypathOps.OperatorSelection` already canonicalizes loaded schema modules, resolves URL values only against the allowlist without creating atoms, builds safely encoded paths, and returns `:unavailable` for an explicit invalid target.
- `ScrypathOpsWeb.ControlRoomLive` already has the fleet summary and distinct intent routes; `ScrypathOpsWeb.PostureLive` already sorts per-schema records worst-first and links each schema to Failed sync work.
- `ScrypathOpsWeb.FailedSyncLive` already resolves schema query params in `handle_params/3`, changes the URL with `push_patch/2` from the selector, clears schema-bound recovery receipts/confirmation when selection changes, and preserves a retry receipt beside the original failure.
- `ScrypathOpsWeb.Components.OpsUI` has shared verdict, section, result-row, schema-select, status, action, and disclosure primitives. Extend only when a repeated, visible need is demonstrated.

### Established Patterns

- Cross-LiveView context uses `navigate`/`push_navigate`; state changes within a LiveView use `patch`/`push_patch`. The schema identity belongs in the query string so reload/history and links resolve the same target.
- URL/event values remain untrusted. Re-resolve against the live allowlist and re-check action authorization/eligibility at event time; an invalid target is a visible stop, never a fallback.
- The existing Search health sort ranks fetch error → backend failures → queue not observed/failures/retries → clean, with alphabetical module-name tie breaking. The distinct Failed sync list sorts by newest evidence.
- Shared status language distinguishes unknown/unavailable from zero, accepted from terminal, queue jobs from backend tasks, and current evidence from retained failure history.

### Integration Points

- The Control Room, Search health, and Failed sync LiveViews share Ops shell/components and run in both standalone and mounted route prefixes.
- Schema-specific health links, the Failed sync selector, retry receipts, and downstream Sync and drift handoffs form the recovery navigation chain. UI changes must preserve selection and must not let cached evidence cross a schema switch.
- Focused LiveView checks cover classifications/actions; existing browser checks can prove selector interaction, route/history continuity, long-content reflow, keyboard focus, and both-theme presentation. Use the disposable browser stack for mutating fixtures; retain the maintainer's preview.
</code_context>

<specifics>
## Specific Ideas

- The selected direction is task-first and quiet: state → affected scope → safe action; full schema/work identity and detailed evidence remain available at the record where they matter.
- On-call safety outranks a shorter but ambiguous flow. Keep common, eligible retry discoverable; keep verbose diagnostics collapsed; never auto-retry or treat acceptance as completion.
- URL state is the continuity mechanism, not hidden session memory. An explicit stale/invalid schema must fail closed and visibly.
- No external product needs to be copied wholesale. Reuse the previously reviewed GitHub/Grafana/Carbon/Primer pattern analysis only where useful; project requirements and current behavior define the contract.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the approved Phase 174 boundary. Search/Playbooks changes remain Phase 176; repair/promotion behavior remains Phase 175; no new authorization, backend, infrastructure, or operator-surface capability is proposed.
</deferred>

---

*Phase: 174-recovery-entry-and-diagnosis*
*Context gathered: 2026-10-10*
