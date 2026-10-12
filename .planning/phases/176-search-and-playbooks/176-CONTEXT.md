# Phase 176: Search and Playbooks - Context

**Gathered:** 2026-10-10
**Status:** Discussion captured; UI contract approved and five plans independently verified. Execution remains gated by Phases 173–175.
**Authority:** The maintainer selected all four discussion areas and explicitly delegated bounded research, specialist fan-out, adversarial review, synthesis, and automatic adoption of coherent recommendations. This is decision authority for this discussion, not a simulated reviewer approval or an implementation-chain request.

<domain>
## Phase Boundary

Refine the existing Search and Playbooks surfaces so operators can identify query inputs, run a search or saved check, read the actual outcome, and save useful criteria without competing controls. Make occasional file management discoverable while preserving existing workspace, import, validation, read-only, destructive-confirmation, authorization, keyboard, and LiveView behavior. Own OPUX-23, OPUX-24, and OPUX-25 in approved v1.43; add no core search API or new operator capability.

Phase 176 depends on Phase 175 for execution. This forward discussion does not mark Phases 173–175 complete, change their execution order, or claim any requirement implemented. STATE currently records Phase 173 ready to execute. Carry Phase 173's approved shared visual world into the Phase 176 UI contract before planning implementation.
</domain>

<decisions>
## Implementation Decisions

### Research, visual authority, and dependencies

- **D-01:** Use the bounded synthesis below. Three GSD advisor researchers covered all four areas, with a separate cross-area adversarial pass. Consider operator/product, design/accessibility, mobile/browser, Phoenix/async state, operational truth, security/storage, and maintenance perspectives where relevant. Stop at coherent, source-grounded recommendations; unrelated specialties and fresh ecosystem surveys do not improve this scoped task.
- **D-02:** Preserve the Phase 173 neutral light/dark surfaces, restrained local status cues, violet interaction/focus, readable type, spacing, and shared quiet/disabled/busy states. Apply Impeccable Operate guidance within this established world. Do not reopen palette selection, add decorative motion, or manufacture another layer of nested cards to group headings.
- **D-03:** Prefer small owned changes and proven internal components over another dependency: “another copy and paste is better than another dep,” with justified exceptions only for a demonstrated capability/correctness gap. No new dependency is recommended. Use native controls, existing function components, disclosures, uploads, and OpsModal; extract shared patterns when actual repeated use warrants it, without a fixed component count.

### Search reading order — OPUX-23

- **D-04:** Keep target/mode, query, page-size controls, one Run search submit, and results in that reading order at desktop and narrow widths. Use wider space for fields when it improves readability, without turning the screen into a split editor or separate scrolling panes. Full schema identifiers and long values remain readable and wrap without page-wide overflow.
- **D-05:** Remove the empty-state Run current search submit. Empty results teach the next step through concise text referring to the existing form. Preserve normal Enter submission and native disabled behavior for missing schemas/backend; explain the unavailable action adjacent to the form. Busy feedback retains meaningful action text and the existing submit guard rather than introducing another run control.
- **D-06:** Lead results with concise attribution to the actual submitted mode, target(s), query, and page size, followed by readable hits/counts. For multi-index responses, show which indexes returned hits, returned no hits, or failed. Keep partial failure and its next useful check visible, with optional failure detail. Returned hits are a search observation, not proof of global freshness or recovery.
- **D-07:** Keep raw hit payloads, raw per-index responses, merge traces, and federation metadata in closed, clearly labeled disclosures. Keep the essential federation limitation visible: merged order is not one global relevance score. Disclosure is presentation, not redaction; retain the existing exploratory-query/no-secrets/PII notice without adding new logging or data export.
- **D-08:** Distinguish not run, running, successful zero hits, complete response, partial response, run failure, and setup unavailable. Announce a concise outcome/count summary through existing status semantics; do not turn the entire result list into a live announcement or steal focus after an ordinary search. Errors and partial results must not disappear into optional diagnostics.
- **D-09:** Results and capture describe the dispatched submission, never later editable inputs. Freeze mode and criteria together at submit so a queued Search message cannot use a subsequently changed mode. If an earlier result remains visible while controls or URL criteria change, label it as the last run with its own criteria; do not relabel it as the new form. Preserve existing capture invalidation on mode changes and clear result/capture at a new run as appropriate. No run-history product is added.

### Playbook preview and execution — OPUX-24

- **D-10:** Use one vertically staged workspace: catalog → selected preview with common run/save actions → run results → secondary import tools. Keep sections distinct through headings, proximity, and the shared section rhythm. Do not add a wizard, tabs, master/detail state machine, or mandatory preview approval gate.
- **D-11:** Load preview is the normal catalog action. Retain Run without preview beside it as a clearly labeled quiet expert shortcut, preserving its validate-and-run behavior. In the selected preview, use one primary Run playbook action; the label must also be truthful for an imported unsaved draft. Save remains easy to find as an adjacent secondary action or compact form for its separate persistence task.
- **D-12:** Show clear preview provenance: loaded workspace filename, read-only example filename, or imported unsaved draft. Keep file identity, editable/validated draft, execution, and persistence distinct. An import must not inherit a previously selected file's saved label. A failed import explains the failure and whether the previous valid preview remains; it cannot announce the attempted import as ready.
- **D-13:** Bind running, error, timeout, cancellation, success/partial summary, diagnostics, and Search loopback to the actual run's captured source and criteria. A later preview/load/import must not relabel an earlier outcome. If a completed result is retained, visibly identify it as that earlier run; otherwise reset it consistently. Successful saving updates current draft provenance only, without rewriting historical run attribution.
- **D-14:** Preserve existing run-ID correlation, one active-run guard, timeout, Cancel run, supersede handling, and late-response suppression. Cancellation concerns applying/observing this query's response; do not claim remote rollback. Loading/importing while a run is active keeps existing supersede semantics. A returned multi-result with failures is partial and must not read as every selected index succeeded. Use the existing result summary and Search handoff; do not add a new Playbook hit browser.
- **D-15:** Read-only examples remain previewable and runnable with valid runtime configuration. Explain missing run configuration beside the unavailable run affordance. A configured workspace path enables an attempted save; it does not prove filesystem permissions or a completed write. Keep permission/configuration failures truthful and readable, with no change to host-owned authority.

### Saving and imports — OPUX-23 and OPUX-24

- **D-16:** Search's visible Save as playbook action leads to a compact progressive form tied to the last eligible run. Preserve actual-response eligibility: successful zero-hit single results and partial multi responses can produce a reusable check. Save query criteria and metadata, not result documents, a frozen response, or a promise that every index succeeded. Keep exact JSON preview available as optional evidence; do not make raw JSON lead the common save task.
- **D-17:** A valid loaded/imported Playbook draft can be saved independently of whether it ran or returned hits. Keep save reachable near the preview's common actions and identify what will be written. Use Filename with a .json hint and preserve optional Search title/description fields. Do not conflate a successful run with persistence or require execution as a new save prerequisite.
- **D-18:** Keep a visible Import JSON entry near the catalog heading and prominent import access in the empty-workspace state. Place the file-upload/paste section after common selected-playbook work; retain the existing anchor. File upload remains available directly in that section; paste stays a labeled native disclosure. Preserve JSON validation, allowlist/runtime validation at execution, existing upload caps, and paste-size limits. Do not auto-import, auto-save, or auto-run on file choice.
- **D-19:** Preserve the current persistence policies exactly: Search capture rejects a filename already found in the workspace; Playbook save can replace an existing file through Store.save_workspace_file/3; rename and duplicate reject occupied destinations. Explain replacement beside Playbook save before submission. Add no overwrite prohibition, new confirmation policy, or storage abstraction under this UI phase.
- **D-20:** Keep save/import field values through failure where practical; associate errors with the relevant filename/JSON/upload control and retain a concise overall error when needed. Confirmation follows actual successful persistence. Read-only guidance must describe available behavior: current Search provides capture/save, not a download/export action. Correct the stale “export a playbook JSON” wording without inventing that capability.

### Occasional Playbook file actions — OPUX-25

- **D-21:** Put Duplicate, Rename, and Delete inside a closed, labeled per-row Manage file actions disclosure using ordinary buttons. Include the row/file identity in its accessible name or context; full filenames wrap. Keep Load preview and Run without preview outside. Expand in normal document flow to avoid clipped popup geometry. Do not add an icon-only kebab, ARIA menu roles/arrow-key model, or management that requires loading the file first.
- **D-22:** Preserve existing configured-workspace/basename/path checks, collision behavior, server eligibility, host authorization, and typed exact-filename deletion confirmation. Read-only examples omit mutation controls and keep their explanation. Delete remains clearly separated inside management; final Confirm delete owns destructive emphasis. Rearranging controls must not weaken a gate or imply that hiding buttons enforces authorization.
- **D-23:** Reuse OpsModal. Rename/duplicate initially focus the editable filename; delete initially focuses Cancel. Keep a visible close/cancel control, Escape dismissal, Tab/Shift+Tab containment, background inertness, and typed validation inside the active dialog. Invalid submission keeps the dialog and value, with associated error text; focus the relevant invalid field without repeatedly stealing focus on ordinary patches.
- **D-24:** Close the invoking management disclosure when a dialog opens and set a visible return target first. On cancel or successful duplication, return to the same file's Manage summary; after rename, prefer the renamed row's summary, with catalog-heading fallback; after deletion, use the existing logical next-row primary control/catalog-heading successor. Never focus a connected but hidden action button or a DOM node reused for a different file. Verify this through actual LiveView patches and real rendered controls.

### Acceptance, limits, and handoff

- **D-25:** Each implementation slice supplies direct before/after image inspection and focused executable acceptance in existing lanes. Cover light/dark, narrow/desktop and a changed breakpoint, long filenames/modules/payloads, missing setup, busy/disabled, zero hits, full failure, partial results, read-only/configured-but-unwritable workspace, malformed/oversized import, collision/replacement behavior, and dialogs. Exercise rendered form submits, disclosures, run shortcuts, import/save, and keyboard/focus through patches. Specifically test queued-mode changes, changed URL criteria, completed run followed by a different load/import, save provenance, stale async replies, and hidden/deleted modal return targets. Record OPUX-23–25 individually; passing captures or direct-handler tests alone do not establish application quality.
- **D-26:** Preserve local source/design edits and the feedback preview at http://127.0.0.1:4012/admin/search; never reseed it. Mutating save/delete/import fixtures belong in disposable stacks. Reuse CONTRIBUTING's Ops gate and focused browser/contrast lanes; add no required CI service, recurring paid judge, or routine pending UAT. Archived v1.42 receipts do not verify changed source. This discussion runs no product acceptance and completes no requirement.
- **D-27:** Next run $gsd-ui-phase 176 to translate these choices into realistic comps and the phase UI-SPEC, then $gsd-plan-phase 176. Existing shared visual decisions and delegated hierarchy recommendations do not bypass the UI contract, planning checks, PR-first delivery, or the 173 → 174 → 175 → 176 execution dependency chain. No --auto/--chain flag or auto-advance setting is enabled by this discussion.

### Agent's Discretion

Choose exact section composition, concise labels/hints, neutral grouping, disclosure placement, and internal state/test structure within these decisions and the subsequent UI contract. Bind retained outcomes to submitted-run identity or reset them where appropriate; neither choice may attribute old evidence to a new preview. Preserve existing core semantics and supported operations. Comp work resolves material layout details before implementation. A clipboard-copy control moved or rewired here must follow Phase 173's actual-browser-success feedback pattern; if untouched, its existing premature diagnostics-copy flash is a named separate limitation rather than an incidental expansion of this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the relevant references before planning or implementing.** Full repository-relative paths below are canonical; older inventories orient the work but do not certify current source.

### Approved scope and lifecycle

- `.planning/PROJECT.md` — current product truth, operator role, verification, and UI lifecycle defaults.
- `.planning/STATE.md` — active Phase 173 posture, local continuity, retained preview, and source-bounded evidence.
- `.planning/ROADMAP.md` — Phase 176 goal, dependency on 175, success criteria, and later consolidation ownership.
- `.planning/REQUIREMENTS.md` — OPUX-23, OPUX-24, OPUX-25 and common milestone acceptance.
- `.planning/research/v1.43/SCOPE.md` — approved scope, inventory reuse, comp-first sequence, and preservation rules.
- `.planning/reference/OPERATOR-UI-REFINEMENT.md` — concrete form/result, preview/run/save, and management hierarchy feedback.
- `.planning/reference/OPERATOR-UI-QUALITY.md` — conventional controls, disclosure/focus rules, economical evidence, and clean delivery.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-CONTEXT.md` — shared decisions D-01–D-22, including dependency and truthful feedback principles.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — approved shared visual/state contract; static comps are design evidence only.
- `CONTRIBUTING.md` — scoped Ops verification, playbook fixture validation when applicable, PR-first release-train gates.

### Product, design, and existing workspace

- `PRODUCT.md` — operator/integrator jobs, optional Ops product boundaries, host responsibilities.
- `DESIGN.md` — existing vocabulary and explicit refinement direction, subordinate to the approved Phase 173 contract for selected treatments.
- `.impeccable/config.json` — comp-first preference; no incidental sidecar repair.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — shared component/token authority; update with delivered changes.
- `scrypath_ops/docs/operator-ia.md` — existing Search/Playbook jobs, provenance, and safety boundaries.
- `.planning/research/v1.42/UI-SYSTEM.md` — historical component inventory, rechecked against touched source.
- `.planning/research/v1.42/UI-STRUCTURE.md` — historical Search/Playbook flows and pitfalls; do not replay resolved findings.
- `.planning/research/v1.42/UI-AUTOMATION.md` — available economical proof lanes and preview-isolation limitations.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — local LiveView context; current official API docs and locked version govern details.
- `prompts/scrypath-brand-book.md` — exploratory identity context, not a binding palette or capability claim.

### Primary guidance informing the synthesis

These support conventional controls, announcements, validation, and focus. The selected page topology and priorities are project-specific recommendations, not requirements imposed by these sources. Both Ops and the ecommerce example currently lock LiveView 1.1.33; research cited newer unversioned pages only for stable principles, not an upgrade recommendation.

- [GOV.UK Button](https://design-system.service.gov.uk/components/button/) — main versus secondary actions and destructive confirmation emphasis.
- [GOV.UK Details](https://design-system.service.gov.uk/components/details/) — optional detail without hiding information most users need.
- [W3C Disclosure Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) — show/hide semantics and keyboard expectations; no menu role is needed.
- [W3C Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — initial focus, containment, inert background, dismissal, and logical return targets.
- [W3C Focus Order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html) — meaningful reading/keyboard order through responsive layout.
- [W3C ARIA22](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22.html) — concise search-result status announcement without moving focus.
- [W3C Form Notifications](https://www.w3.org/WAI/tutorials/forms/notifications/) — clear errors associated with controls and accessible feedback.
- [Phoenix LiveView 1.1.33](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html) — existing async/cancellation and upload API contract.
- [Phoenix LiveView Form Bindings](https://hexdocs.pm/phoenix_live_view/1.1.33/form-bindings.html) — native submit/change bindings and submission feedback.
- [Phoenix LiveView Uploads](https://hexdocs.pm/phoenix_live_view/1.1.33/uploads.html) — existing file-upload limits, validation, and consumption flow.

No external product specification adds requirements beyond the approved milestone records and decisions above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — shared fields/buttons, object lists, result rows, notices, disclosures, and ops_modal; build on these.
- `scrypath_ops/assets/js/ops_hooks.js` — OpsModal captures triggers, contains focus, makes background inert, and restores after LiveView patch timing. Its current return-target check does not establish visibility after closing a disclosure.
- `scrypath_ops/lib/scrypath_ops/playbook/store.ex` — basename-only workspace operations. Save overwrites; rename/duplicate reject existing destinations. Preserve these actual distinctions.
- `scrypath_ops/lib/scrypath_ops/playbook/v1.ex` and `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` — existing validation/execution services; keep rules beneath presentation.

### Established Patterns and Current Findings

- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — existing form, empty/loading/error/partial results and capture. The empty hero repeats the form submit. Queued handle_info reads current socket mode; submitted identity needs to stay coherent. Capture stores criteria after successful responses, including zero hits/partial multi results. Its progressive toggle currently lacks an explicit expanded state; use native disclosure or synchronized semantics.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — catalog currently has five visible actions; import precedes selected preview; Run saved playbook labels imported drafts as saved. Async runner captures the draft and guards run IDs, but result labels read current selected_basename/draft mode. apply_decoded can retain an earlier terminal result and selected filename; save reloads the catalog without updating current source identity. These are scoped provenance/hierarchy seams, not a request to replace the runner.
- Current workspace_writable? is based on a configured path, not a successful filesystem permission check. Preserve server errors; avoid guarantees inferred from that assign name.
- Search capture rejects an occupied filename before invoking Store; Playbook save invokes the overwriting Store API. The examples-mode export wording is unsupported by the current Search controls.
- Diagnostic-copy currently flashes Copied diagnostics before browser success. Preserve as a named limitation if untouched; any scoped change must reuse the truthful feedback contract rather than expand into an unrelated clipboard rewrite.

### Integration and Verification Points

- `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` — Search state/capture/partial/hard-error proof; local edits are preserved.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — import/save/load/run, collision/file dialogs, cancellation/supersede, timeout and stale-reply proof; extend relevant missing provenance/partial cases.
- `scrypath_ops/test/scrypath_ops/playbook/store_test.exs` and `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` — incumbent storage/execution contracts; avoid duplicating implementation-shaped tests.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` and neighboring existing modal/focus specs — rendered Search capture and Playbook workspace proof. Reuse the disposable lane; screenshot scenarios may reseed and must never target feedback :4012.
- `scrypath_ops/assets/css/app.css` and shared contrast tooling — responsive hierarchy and action states within existing token authority. Shared modal hooks/assets must remain coherent in standalone and mounted entrypoints when touched.
</code_context>

<specifics>
## Specific Ideas

The maintainer's generic fan-out boilerplate is adapted to this two-screen Phoenix operator task. All four gray areas are delegated for automatic recommendation adoption, with primary-source research and an adversarial pass to diminishing returns. No additional interactive defaults or subjective product question remains blocking discussion capture. Exact composition still belongs in the next comp-first UI contract.

Selected direction: one clear query-to-result sequence; catalog-first saved checks; a visible preview/run/save distinction; optional raw evidence; labeled per-file management rather than five competing actions. Copy must describe real workspace and result behavior. Small owned code is preferred over a flatter-looking UI that requires another dependency.
</specifics>

<deferred>
## Deferred Ideas and Named Limits

- Desktop split/master-detail, wizard/tabs, new result-history or Playbook hit-browser capability, and export/download need separate operator evidence and scope.
- New dependencies, public/core APIs, search/relevance changes, authorization or filesystem policy changes, an overwrite ban/confirmation policy, and infrastructure automation are outside this phase.
- New CI services/jobs, recurring paid visual review, routine human UAT, and release/version changes are not authorized by this discussion.
- Existing diagnostics-copy feedback is a limitation if its control is untouched; a scoped change must follow the shared clipboard contract. Impeccable design sidecar drift remains a nonblocking separate maintenance item.
- This context is forward design preparation. Phase 173's execution posture and the 173–175 dependency chain remain unchanged; prior immutable receipts stay source-bounded.
</deferred>

---

*Phase: 176-search-and-playbooks*
*Context gathered: 2026-10-10*
*Handoff: UI and planning work for Phase 176 are complete. Next: `$gsd-execute-phase 173`; Phase 176 execution remains behind Phases 173–175.*
