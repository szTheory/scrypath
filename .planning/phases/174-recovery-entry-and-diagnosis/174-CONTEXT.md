# Phase 174: Recovery Entry and Diagnosis - Context

**Gathered:** 2026-10-06 (America/New_York)
**Recorded:** 2026-10-07 UTC
**Status:** Discussion complete; ready for the Phase 174 UI contract before implementation planning
**Decision authority:** The maintainer selected all four areas, explicitly requested specialist fan-out, primary-source research, relevant stakeholder lenses and an adversarial synthesis, then selected **1 — Adopt these recommendations** after reviewing the combined recommendation. These are maintainer-adopted discussion decisions, not simulated reviewer approval or product verification.

<domain>
## Phase Boundary

Deliver OPUX-16–OPUX-19 across the existing Control Room, Search health and Failed sync work: identify current state and affected schema/work, make the next safe action clear, and retain the operator's chosen allowed schema through rendered recovery navigation, refresh and Back. Include the existing Sync and drift ingress/return and authorization-return seams only where needed to preserve that context.

Reuse delivered Phase 173 neutral visuals, theme preference, quiet-action states and trustworthy operational time/copy behavior. Preserve host-owned authorization, server eligibility, delete confirmation, exact schema/index/task/job identifiers, retained failure history, and accepted/running/terminal/unknown distinctions. Phase 175 owns repair/verification presentation; Phase 176 owns Search and Playbooks; Phase 177 consolidates demonstrated patterns and delivery evidence. No new core API, backend/auth product, infrastructure automation, surface, framework, required CI service or paid visual judge is added.

This discussion implements no UI, completes no requirement and extends no historical exact-source receipt.
</domain>

<decisions>
## Implementation Decisions

### Research, design and dependency posture

- **D-01:** Use bounded specialist consideration followed by a coherent synthesis and one adversarial challenge. Cover relevant operator/product, design/accessibility/mobile, Phoenix/browser/rendering, security, asynchronous evidence and maintenance perspectives. Stop when another pass would not change the recommendation; do not enumerate unrelated specialties or reopen completed work.
- **D-02:** Prefer small owned code and modest repetition over another external dependency. Existing components, URL helpers and platform affordances cover the identified decisions; no new dependency is recommended. Extract a helper/component only when concrete repeated usage justifies it.
- **D-03:** Apply Impeccable Operate guidance within the delivered Phase 173 visual world. Next run `$gsd-ui-phase 174`, using realistic light/dark compositions to resolve hierarchy and responsive placement before `$gsd-plan-phase 174`. The delivered `173-UI-SPEC.md`, current tokens/components and explicit refinement brief govern the inherited appearance; older PRODUCT/DESIGN/inventory descriptions do not reopen the accepted palette or replay historical fixes. Do not repair Impeccable sidecars/config as incidental work.

### Control Room priorities — OPUX-16

- **D-04:** Lead with current observed state, affected allowed-schema scope and one next safe, read-only step. Connect the summary to that step; remove duplicate recovery explanations and controls that merely repeat the same destination. Keep verification and exploration available as quieter destinations, with direct navigation and command palette retained. No wizard or automatic mutation.
- **D-05:** Keep claims bounded by the actual check and configured allowlist. Zero observed failures do not mean all backends are healthy, documents are fresh or promotion is ready. Distinguish setup missing, backend configuration missing, unavailable/partial observations and remotely failed work. Identify affected schemas where evidence supports it, with complete identifiers; do not infer remote failure from a fetch failure or pretend unavailable observations are zero.
- **D-06:** Keep fleet evidence and recovery-target context separate. A chosen target can be healthy while another schema has worse signals. Label the CTA's scope and the current recovery target where present; never make an implicit worst-first recommendation replace an explicit choice.

### Search health scanning — OPUX-17

- **D-07:** Retain existing worst-first schema records and classification semantics. Use one neutral meaningful surface per schema, readable full schema/index identity and sync mode, with plain Backend/Queue diagnostic groups inside it. Prefer this rich-record layout over a new fleet table or nested decorative panels. Do not add pagination/filtering or redesign severity rules without separately scoped evidence.
- **D-08:** Keep local state text and restrained cues near the affected source; avoid duplicate badges/labels conveying the same fact. Zero counts stay neutral. Observation unavailable, retained older evidence, no success observed, queue not used, queue retrying and terminal failure remain distinct. Reuse Phase 173 snapshot-stable time and exact-value access where applicable without changing the meaning of a source time or adding routine Checked copy controls.
- **D-09:** Put schema-specific next checks with their record and give them explicit target identity. Fleet-level guidance serves genuine fleet setup/diagnosis needs; do not repeat a row action or send a specific incident to an unscoped default. A row action for another schema is a deliberate target-changing navigation when clicked.
- **D-10:** Preserve meaningful reading/focus order through responsive reflow and manual-refresh reordering. Keep stable schema/action identity and focused context rather than moving focus to the new worst row. Wrap complete long values, stack groups when space requires, and keep primary controls reachable. Use incumbent body/action sizes and spacing; do not shrink text to fit columns or impose equal-height disclosure groups.

### Failed-work recovery — OPUX-18

- **D-11:** Name records by source: Backend task / Queue job, with complete work identity. Show operation, relevant index/source facts, failure reason, time and recovery availability in the normal reading order before collapsed verbose diagnostics. Keep useful reason/attempt rollups concise and derive them from the displayed inspection. Retain existing bounded reason summaries; do not expand raw payloads or authentication details into the primary flow or invent a new redaction policy.
- **D-12:** A supported manual retry is an ordinary per-row action, using standard readable controls rather than extra-small advanced treatment. Explain unavailable recovery from known source/operation/replay facts; use an honest generic explanation when the specific cause is unknown. A backend task without in-page replay must not acquire an invented action.
- **D-13:** Determine executable recovery from the existing recovery action and current server rules, not reason class, badge color or an automatic-retry label. Oban automatic retry and Scrypath manual replay availability are separate concepts. A discarded historical job may still expose supported replay data; preserve existing eligibility semantics rather than adding a policy that forbids it.
- **D-14:** Keep existing host authorization, allowlist validation, server-side action checks and the delete confirmation showing schema, index, document count and exact IDs. Client row/source/schema values identify a current inspected object; they are not trusted recovery payloads or authorization. Do not change auth policy or claim a visible button guarantees host authorization.
- **D-15:** Keep the accepted replacement-job receipt, original failure history and existing Check sync status handoff. Acceptance is not completion. A subsequent observation failure remains unknown rather than a remote task failure. Keep the current duplicate-acceptance guard without claiming cross-session exactly-once behavior, automatic replay or automatic verified success.
- **D-16:** Use source-qualified identity for internal rendered rows, action lookup, receipts and delete confirmations so equal numeric backend-task and queue-job IDs cannot collide. Preserve public/full source IDs and existing library contracts; this is a UI identity/lookup correction. Resolve the qualified identifier against the current inspection and chosen schema before acting.

### Schema context — OPUX-19

- **D-17:** The canonical validated `schema` query parameter is recovery-target authority. Use existing allowlist string resolution and URL encoding; do not create atoms from external text or add browser/session/global sticky-selection state. This keeps tabs, bookmarked routes and browser history independent and understandable.
- **D-18:** An explicit allowed selection wins over worst-first recommendations. Preserve existing first-allowlist behavior only when the parameter is truly absent on a schema-specific page. Invalid, blank, hostile or removed explicit targets show unavailable with no target action; never substitute another schema. An empty allowlist is a setup state, with no selected target or recovery action.
- **D-19:** Control Room and Search health remain fleet-wide even with target context. Visibly identify the recovery target and carry it through recovery handoffs, return links, desktop/mobile navigation and command-palette recovery destinations. No implicit selection from the worst-first row. Broader Search/Playbooks state propagation remains Phase 176 work.
- **D-20:** Explicit rendered selector changes update URL/history so Back restores the prior validated target; refresh/reconnect restore the same target. Keep context-bound result, confirmation and receipt-generation invalidation when schema changes, including protection against stale asynchronous results. Do not carry a confirmation or successful observation from schema A into schema B.
- **D-21:** Command-palette link targets must actually update after a selector patch despite its current ignored DOM subtree. Initial-render schema links alone are insufficient. Preserve the existing keyboard/focus lifecycle while correcting contextual destinations; choose the bounded implementation in research/planning.
- **D-22:** Preserve validated schema context through the existing sudo interruption/return seam, whose fallback currently drops the query. Retain host-owned authentication/authorization and safe return-path constraints; do not blindly forward arbitrary query data or change auth policy. Returning from confirmation must not silently land on another schema or replay a mutation automatically.

### Acceptance and agent discretion

- **D-23:** Each slice closes its own acceptance with direct before/after inspection and relevant executable proof in existing lanes: component/LiveView state and rendered-event checks; token AA contrast for shared styles; focused browser navigation, geometry, keyboard/focus and actual mounted recovery seams. Include realistic healthy, degraded, setup/missing-backend, partial/unavailable, empty, busy/disabled, long-content and retained-history states as applicable, light/dark and relevant desktop/narrow/intermediate widths, with System and reduced-motion parity preserved. Screenshots alone do not establish visual quality; no pending routine human UAT or new required CI/paid judge.
- **D-24:** Extend existing changed-selection proof through the newly touched fleet/global navigation/palette/auth-return seams. Cover selected A while B is worse, non-first schema selection via rendered controls, Back/reload, invalid/removed target, source-qualified equal IDs, schema change during confirmation/pending observation, double/stale clicks, refresh reordering and palette navigation after a patch. Run mutating fixtures only in disposable stacks; never reseed the retained feedback preview.

### Agent's Discretion

Choose exact concise copy, source-qualified UI-key representation, component extraction where repeated use warrants it, and bounded navigation/hook implementation within these decisions. Resolve material composition in the Phase 174 UI contract before planning. Reuse existing evidence within its source/scenario limits; no product verification is claimed by this discussion.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before planning or implementing.** Paths below are relative to the project root.

### Scope, lifecycle and retained evidence

- `.planning/PROJECT.md` — product truth, verification default, design lifecycle and exact-command handoff.
- `.planning/STATE.md` — prepared planning checkout, immutable Phase 173 source/receipt, preserved original work/preview and current next action.
- `.planning/ROADMAP.md` — Phase 174 boundary, OPUX assignment and later-phase ownership.
- `.planning/REQUIREMENTS.md` — OPUX-16–OPUX-19 and per-slice acceptance.
- `.planning/research/v1.43/SCOPE.md` — approved scope and inventory reuse; original working-directory/pre-execution statements are historical, current STATE governs the prepared successor.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — concrete hierarchy/visual feedback and comp-first lifecycle; historical next commands do not supersede STATE.
- `.planning/reference/OPERATOR-UI-QUALITY.md` — readable operator hierarchy, safety/evidence boundaries and economical proof.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md` — inherited decisions; source observations written before implementation are historical.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — delivered neutral visual/time/action contract.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-VERIFICATION.md` — completed dependency verification, bounded to its declared source.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CLOSEOUT.md` — proof/advisory limits and immutable-source procedure.
- `.planning/reference/v1.43-phase173-final-receipt.json` — final exact-SHA receipt; later planning metadata does not extend it.
- `CONTRIBUTING.md` — focused checks and existing PR-first required gates.

### Existing product and UI context

- `PRODUCT.md` — integrator/operator roles and supported capability/ownership boundaries.
- `DESIGN.md` — incumbent typography/layout/component vocabulary; delivered Phase 173 contract/current source govern superseded palette descriptions.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — current token/component authority.
- `scrypath_ops/docs/operator-ia.md` — existing six surfaces and inspect/recover/verify jobs.
- `.planning/research/v1.42/UI-SYSTEM.md` — historical component inventory; recheck current source.
- `.planning/research/v1.42/UI-STRUCTURE.md` — historical task/handoff inventory; do not replay already fixed findings.
- `.planning/research/v1.42/UI-AUTOMATION.md` — existing lanes and their source/scenario limits.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — local LiveView orientation; verify API specifics against the installed version's official docs.
- `/Users/jon/.agents/skills/impeccable/SKILL.md` and its `reference/operate.md` / `reference/shape.md` — installed external guidance used for this discussion, not vendored project dependencies. Continue the existing comp-first preference without reinitializing product context; the optional `.impeccable/config.json` is absent from this successor and must not become a blocker or be recreated incidentally.

### Primary guidance informing recommendations

External guidance supports platform constraints and comparable patterns; it does not define Scrypath severity, eligibility or safety policy.

- [Cloudscape dashboard items](https://cloudscape.design/patterns/general/service-dashboard/dashboard-items/) — scannable goal-directed items and one primary action.
- [Carbon status indicators](https://www.carbondesignsystem.com/building-blocks/core/patterns/status-indicators) and [W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) — explicit local text/shape cues.
- [W3C Focus Order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html), [Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) and [Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) — keyboard sequence, narrow layouts and feedback without focus disruption.
- [Phoenix LiveView navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html) and [security model](https://hexdocs.pm/phoenix_live_view/security-model.html) — URL navigation and untrusted input/event authorization; the Ops lock currently uses LiveView 1.1.33, so implementation API details must use that installed version rather than assume an upgrade.
- [Oban job lifecycle](https://oban.hexdocs.pm/job_lifecycle.html) — automatic retry versus terminal job states; no new-version features are adopted.
- [Meilisearch asynchronous operations](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations) — accepted task identity versus observed terminal status.
- [Grafana data links](https://grafana.com/docs/grafana/latest/visualizations/panels-visualizations/configure-data-links/) — comparable context-preserving navigation, not an instruction to add Grafana or its abstractions.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scrypath_ops/lib/scrypath_ops/operator_selection.ex` — canonical strings, current-allowlist resolution without atom creation, mounted encoded handoff paths; defaults only when schema param is absent.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — existing record, heading, action, disclosure, time, feedback, schema-picker and modal components. The command palette currently builds unscoped links in a `phx-update=ignore` subtree.
- `scrypath_ops/assets/css/app.css` and `scrypath_ops/assets/js/ops_hooks.js` — delivered visual/action/time interaction vocabulary and shared hook lifecycle.

### Established Patterns

- `scrypath_ops/lib/scrypath_ops/posture.ex` — bounded allowlist/source observations, classification and retained last-success references. Preserve evidence semantics; refine overbroad human-facing claims without inventing health rules.
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — URL-driven selected schema, current allowlist checks, generation invalidation, retry/delete gates, accepted receipts and recovery handoff. Current row/action/receipt/confirmation identities use ID alone, and records are called jobs regardless of source.
- `lib/scrypath/operator/failed_work.ex` and `lib/scrypath/operator/failed_work/translation.ex` — source, operation, reason, attempts and replay data; backend tasks have no in-page replay action, while known queue operations with replay data can expose one. Preserve the core public contract.
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — selected-schema ingress, context generation, stale async guards and exact recovery evidence. Touch only the Phase 174 context seams; its presentation belongs to Phase 175.

### Integration Points

- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` — fleet summary, repeated health/recovery controls and equally weighted intent cards; no current schema-context handling.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — worst-first fleet records and existing explicit per-schema links; regular `handle_params` currently does not retain schema context for global recovery navigation.
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`, `scrypath_ops/lib/scrypath_ops_web/nav.ex` and `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` — mounted shell, desktop/mobile recovery navigation and path handling.
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` — existing authorization boundary; fallback return path uses `socket.host_uri.path` and drops the schema query.
- `scrypath_ops/test/scrypath_ops/operator_selection_test.exs` and current Control Room/Posture/FailedSync/SyncDrift LiveView tests — existing allowlist, selector, handoff, gating and state contracts.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` — already changes Product to Variant through rendered controls and tests Back/reload, invalid schema and exact recovery outcomes. Extend through newly changed routes rather than claiming the existing proof is absent.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` and `.planning/research/v1.42/UI-AUTOMATION.md` — existing focused geometry/visual and mounted lanes; some broad advisory contracts/topology remain failing, as disclosed in STATE.
</code_context>

<specifics>
## Specific Ideas

The maintainer's generic fan-out prompt was adapted to four relevant decision areas, three typed specialist agents (one reused for the fourth area), primary research and a bounded cross-area adversarial challenge. The approved synthesis is state → scope → safe action, source-aware failed work and an explicit URL recovery target. The dependency preference is “another copy and paste is better than another dep,” with genuinely justified exceptions allowed.

Representative adverse examples: selected schema A while B is worst; Backend task 501 beside Queue job 501; a palette opened after changing selection; a sudo interruption on a non-first target; allowlist removal while a delete modal is open; a late observation for the prior schema; manual refresh that reorders the focused record. These are acceptance cases, not claims that every case has already been reproduced or fixed.
</specifics>

<deferred>
## Deferred Ideas

No new capability was approved. Rich table/filter/pagination tools for very large fleets need actual scale evidence and separate scope. Browser-global sticky selection, automatic retry orchestration, cross-session exactly-once guarantees, a new auth/redaction product and infrastructure automation are outside this phase. Phase 175 retains ownership of repair/verification presentation; Phase 176 owns Search/Playbooks; Phase 177 consolidates delivered documentation.

Inherited broad advisory browser failures, the unchanged Ops lock's documented Cloak advisories and historical Phase 173 evidence limitations remain visible in STATE and 173-CLOSEOUT/SECURITY. This discussion grants no dependency exception, risk acceptance, release approval, full-matrix pass or replay of a completed phase. Impeccable config/sidecar maintenance is not incidental scope.
</deferred>

---

*Phase: 174-recovery-entry-and-diagnosis*
*Next: `$gsd-ui-phase 174`, then `$gsd-plan-phase 174`. Automatic chaining remains disabled.*
*Working directory: `/private/tmp/scrypath-phase173-20261006-155750/next-planning`, branch `planning/phase-174-handoff`. The agent handles checkout selection; the maintainer does not need to cd or start another session.*

## Maintainer feedback supersession — 2026-10-09

The maintainer rejected selected-schema context on an overview with no selector
and all schemas visible. D-19’s overview-target provision is superseded: Control
Room and Search health are unscoped all-schema views; old schema queries normalize
with history replacement. Choose a schema through its row’s recovery link. Scoped
selectors, allowlist validation, authorization, and return paths remain. Generic
diagnostic links that could open the default schema are removed from Search
health; setup guidance remains. See
[All-schema Search health](../../reference/ALL-SCHEMA-HEALTH-2026-10-09.md) for the
current decision and executable evidence. Earlier evidence retains its original
date and source.
