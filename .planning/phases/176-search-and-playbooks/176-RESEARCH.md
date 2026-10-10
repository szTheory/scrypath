# Phase 176: Search and Playbooks - Research

**Researched:** 2026-10-10
**Domain:** ScrypathOps Phoenix LiveView search and saved-playbook operator UI
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Research, visual authority, and dependencies

- **D-01:** Use the bounded synthesis below. Three GSD advisor researchers covered all four areas, with a separate cross-area adversarial pass. Consider operator/product, design/accessibility, mobile/browser, Phoenix/async state, operational truth, security/storage, and maintenance perspectives where relevant. Stop at coherent, source-grounded recommendations; unrelated specialties and fresh ecosystem surveys do not improve this scoped task.
- **D-02:** Preserve the Phase 173 neutral light/dark surfaces, restrained local status cues, violet interaction/focus, readable type, spacing, and shared quiet/disabled/busy states. Apply Impeccable Operate guidance within this established world. Do not reopen palette selection, add decorative motion, or manufacture another layer of nested cards to group headings.
- **D-03:** Prefer small owned changes and proven internal components over another dependency: “another copy and paste is better than another dep,” with justified exceptions only for a demonstrated capability/correctness gap. No new dependency is recommended. Use native controls, existing function components, disclosures, uploads, and OpsModal; extract shared patterns when actual repeated use warrants it, without a fixed component count.

#### Search reading order — OPUX-23

- **D-04:** Keep target/mode, query, page-size controls, one Run search submit, and results in that reading order at desktop and narrow widths. Use wider space for fields when it improves readability, without turning the screen into a split editor or separate scrolling panes. Full schema identifiers and long values remain readable and wrap without page-wide overflow.
- **D-05:** Remove the empty-state Run current search submit. Empty results teach the next step through concise text referring to the existing form. Preserve normal Enter submission and native disabled behavior for missing schemas/backend; explain the unavailable action adjacent to the form. Busy feedback retains meaningful action text and the existing submit guard rather than introducing another run control.
- **D-06:** Lead results with concise attribution to the actual submitted mode, target(s), query, and page size, followed by readable hits/counts. For multi-index responses, show which indexes returned hits, returned no hits, or failed. Keep partial failure and its next useful check visible, with optional failure detail. Returned hits are a search observation, not proof of global freshness or recovery.
- **D-07:** Keep raw hit payloads, raw per-index responses, merge traces, and federation metadata in closed, clearly labeled disclosures. Keep the essential federation limitation visible: merged order is not one global relevance score. Disclosure is presentation, not redaction; retain the existing exploratory-query/no-secrets/PII notice without adding new logging or data export.
- **D-08:** Distinguish not run, running, successful zero hits, complete response, partial response, run failure, and setup unavailable. Announce a concise outcome/count summary through existing status semantics; do not turn the entire result list into a live announcement or steal focus after an ordinary search. Errors and partial results must not disappear into optional diagnostics.
- **D-09:** Results and capture describe the dispatched submission, never later editable inputs. Freeze mode and criteria together at submit so a queued Search message cannot use a subsequently changed mode. If an earlier result remains visible while controls or URL criteria change, label it as the last run with its own criteria; do not relabel it as the new form. Preserve existing capture invalidation on mode changes and clear result/capture at a new run as appropriate. No run-history product is added.

#### Playbook preview and execution — OPUX-24

- **D-10:** Use one vertically staged workspace: catalog → selected preview with common run/save actions → run results → secondary import tools. Keep sections distinct through headings, proximity, and the shared section rhythm. Do not add a wizard, tabs, master/detail state machine, or mandatory preview approval gate.
- **D-11:** Load preview is the normal catalog action. Retain Run without preview beside it as a clearly labeled quiet expert shortcut, preserving its validate-and-run behavior. In the selected preview, use one primary Run playbook action; the label must also be truthful for an imported unsaved draft. Save remains easy to find as an adjacent secondary action or compact form for its separate persistence task.
- **D-12:** Show clear preview provenance: loaded workspace filename, read-only example filename, or imported unsaved draft. Keep file identity, editable/validated draft, execution, and persistence distinct. An import must not inherit a previously selected file's saved label. A failed import explains the failure and whether the previous valid preview remains; it cannot announce the attempted import as ready.
- **D-13:** Bind running, error, timeout, cancellation, success/partial summary, diagnostics, and Search loopback to the actual run's captured source and criteria. A later preview/load/import must not relabel an earlier outcome. If a completed result is retained, visibly identify it as that earlier run; otherwise reset it consistently. Successful saving updates current draft provenance only, without rewriting historical run attribution.
- **D-14:** Preserve existing run-ID correlation, one active-run guard, timeout, Cancel run, supersede handling, and late-response suppression. Cancellation concerns applying/observing this query's response; do not claim remote rollback. Loading/importing while a run is active keeps existing supersede semantics. A returned multi-result with failures is partial and must not read as every selected index succeeded. Use the existing result summary and Search handoff; do not add a new Playbook hit browser.
- **D-15:** Read-only examples remain previewable and runnable with valid runtime configuration. Explain missing run configuration beside the unavailable run affordance. A configured workspace path enables an attempted save; it does not prove filesystem permissions or a completed write. Keep permission/configuration failures truthful and readable, with no change to host-owned authority.

#### Saving and imports — OPUX-23 and OPUX-24

- **D-16:** Search's visible Save as playbook action leads to a compact progressive form tied to the last eligible run. Preserve actual-response eligibility: successful zero-hit single results and partial multi responses can produce a reusable check. Save query criteria and metadata, not result documents, a frozen response, or a promise that every index succeeded. Keep exact JSON preview available as optional evidence; do not make raw JSON lead the common save task.
- **D-17:** A valid loaded/imported Playbook draft can be saved independently of whether it ran or returned hits. Keep save reachable near the preview's common actions and identify what will be written. Use Filename with a .json hint and preserve optional Search title/description fields. Do not conflate a successful run with persistence or require execution as a new save prerequisite.
- **D-18:** Keep a visible Import JSON entry near the catalog heading and prominent import access in the empty-workspace state. Place the file-upload/paste section after common selected-playbook work; retain the existing anchor. File upload remains available directly in that section; paste stays a labeled native disclosure. Preserve JSON validation, allowlist/runtime validation at execution, existing upload caps, and paste-size limits. Do not auto-import, auto-save, or auto-run on file choice.
- **D-19:** Preserve the current persistence policies exactly: Search capture rejects a filename already found in the workspace; Playbook save can replace an existing file through Store.save_workspace_file/3; rename and duplicate reject occupied destinations. Explain replacement beside Playbook save before submission. Add no overwrite prohibition, new confirmation policy, or storage abstraction under this UI phase.
- **D-20:** Keep save/import field values through failure where practical; associate errors with the relevant filename/JSON/upload control and retain a concise overall error when needed. Confirmation follows actual successful persistence. Read-only guidance must describe available behavior: current Search provides capture/save, not a download/export action. Correct the stale “export a playbook JSON” wording without inventing that capability.

#### Occasional Playbook file actions — OPUX-25

- **D-21:** Put Duplicate, Rename, and Delete inside a closed, labeled per-row Manage file actions disclosure using ordinary buttons. Include the row/file identity in its accessible name or context; full filenames wrap. Keep Load preview and Run without preview outside. Expand in normal document flow to avoid clipped popup geometry. Do not add an icon-only kebab, ARIA menu roles/arrow-key model, or management that requires loading the file first.
- **D-22:** Preserve existing configured-workspace/basename/path checks, collision behavior, server eligibility, host authorization, and typed exact-filename deletion confirmation. Read-only examples omit mutation controls and keep their explanation. Delete remains clearly separated inside management; final Confirm delete owns destructive emphasis. Rearranging controls must not weaken a gate or imply that hiding buttons enforces authorization.
- **D-23:** Reuse OpsModal. Rename/duplicate initially focus the editable filename; delete initially focuses Cancel. Keep a visible close/cancel control, Escape dismissal, Tab/Shift+Tab containment, background inertness, and typed validation inside the active dialog. Invalid submission keeps the dialog and value, with associated error text; focus the relevant invalid field without repeatedly stealing focus on ordinary patches.
- **D-24:** Close the invoking management disclosure when a dialog opens and set a visible return target first. On cancel or successful duplication, return to the same file's Manage summary; after rename, prefer the renamed row's summary, with catalog-heading fallback; after deletion, use the existing logical next-row primary control/catalog-heading successor. Never focus a connected but hidden action button or a DOM node reused for a different file. Verify this through actual LiveView patches and real rendered controls.

#### Acceptance, limits, and handoff

- **D-25:** Each implementation slice supplies direct before/after image inspection and focused executable acceptance in existing lanes. Cover light/dark, narrow/desktop and a changed breakpoint, long filenames/modules/payloads, missing setup, busy/disabled, zero hits, full failure, partial results, read-only/configured-but-unwritable workspace, malformed/oversized import, collision/replacement behavior, and dialogs. Exercise rendered form submits, disclosures, run shortcuts, import/save, and keyboard/focus through patches. Specifically test queued-mode changes, changed URL criteria, completed run followed by a different load/import, save provenance, stale async replies, and hidden/deleted modal return targets. Record OPUX-23–25 individually; passing captures or direct-handler tests alone do not establish application quality.
- **D-26:** Preserve local source/design edits and the feedback preview at http://127.0.0.1:4012/admin/search; never reseed it. Mutating save/delete/import fixtures belong in disposable stacks. Reuse CONTRIBUTING's Ops gate and focused browser/contrast lanes; add no required CI service, recurring paid judge, or routine pending UAT. Archived v1.42 receipts do not verify changed source. This discussion runs no product acceptance and completes no requirement.
- **D-27:** Next run $gsd-ui-phase 176 to translate these choices into realistic comps and the phase UI-SPEC, then $gsd-plan-phase 176. Existing shared visual decisions and delegated hierarchy recommendations do not bypass the UI contract, planning checks, PR-first delivery, or the 173 → 174 → 175 → 176 execution dependency chain. No --auto/--chain flag or auto-advance setting is enabled by this discussion.

### Agent's Discretion

Choose exact section composition, concise labels/hints, neutral grouping, disclosure placement, and internal state/test structure within these decisions and the subsequent UI contract. Bind retained outcomes to submitted-run identity or reset them where appropriate; neither choice may attribute old evidence to a new preview. Preserve existing core semantics and supported operations. Comp work resolves material layout details before implementation. A clipboard-copy control moved or rewired here must follow Phase 173's actual-browser-success feedback pattern; if untouched, its existing premature diagnostics-copy flash is a named separate limitation rather than an incidental expansion of this phase.

### Deferred Ideas (OUT OF SCOPE)

- Desktop split/master-detail, wizard/tabs, new result-history or Playbook hit-browser capability, and export/download need separate operator evidence and scope.
- New dependencies, public/core APIs, search/relevance changes, authorization or filesystem policy changes, an overwrite ban/confirmation policy, and infrastructure automation are outside this phase.
- New CI services/jobs, recurring paid visual review, routine human UAT, and release/version changes are not authorized by this discussion.
- Existing diagnostics-copy feedback is a limitation if its control is untouched; a scoped change must follow the shared clipboard contract. Impeccable design sidecar drift remains a nonblocking separate maintenance item.
- This context is forward design preparation. Phase 173's execution posture and the 173–175 dependency chain remain unchanged; prior immutable receipts stay source-bounded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPUX-23 | “Operators using Search can identify the target/query controls, primary run action, and results in a clear hierarchy without redundant run actions for the same task; empty/error/partial states, disabled behavior, and optional diagnostic evidence remain usable.” [VERIFIED: .planning/REQUIREMENTS.md:36] | Existing SearchLive and LiveView tests provide the form, request handling, partial/error behavior, and capture seams. Freeze submitted criteria before queued work; test actual rendered order, response attribution, and status semantics. |
| OPUX-24 | “Operators using Playbooks can distinguish preview, execution, results, and saving, with common run/save actions prioritized and existing workspace, import, validation, and read-only behaviors preserved.” [VERIFIED: .planning/REQUIREMENTS.md:37] | Existing PlaybookLive, Runner, V1, Store and tests already own these behaviors. Bind draft provenance and execution identity in LiveView state; preserve independent save and existing validation/replace policy. |
| OPUX-25 | “Operators can discover occasional Playbook rename/duplicate/delete actions without those actions competing with common work; destructive confirmation and dialog keyboard, validation, focus containment/return, and LiveView patch behavior remain correct.” [VERIFIED: .planning/REQUIREMENTS.md:38] | Existing native disclosure, OpsModal and server-side Store checks are the implementation seam. LiveView tests cover rendered events and server rules; a browser lane must exercise focus visibility/return after real patches and row changes. |
</phase_requirements>

## Summary

Plan Phase 176 as a source-preserving refinement of two existing Phoenix LiveViews. Keep the current app dependencies, shared OpsUi components, native forms/details, Playbook Store/Runner, and OpsModal; no new package, API, persistence layer, or backend behavior is needed. The approved contract already settles hierarchy and interaction rules, so planning should decompose around the Search submission/result identity, Playbook provenance/run/save state, and per-row file-management dialog/focus seam. [VERIFIED: scrypath_ops/mix.exs:41-52] The exact declared dependency lines are `{:phoenix, "~> 1.8.9"}` and `{:phoenix_live_view, "~> 1.1.33"}`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html]

The highest-risk implementation work is state ownership. Search sends submitted params to a later `handle_info/2`, but currently reads mode from the then-current socket assigns; Playbook async callbacks correlate the run ID, while the rendered source/mode/query can be derived from the currently selected draft. Freeze the actual submitted criteria with the queued/async operation and render every result, error, diagnostic and handoff from that immutable run context. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:225-263] The source says `send(self(), {:run_search, params})` and later `mode = socket.assigns.mode`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:739-783] The source says `draft = assigns.draft_playbook`, calls `start_async(run_async_key(run_id), ...)`, and checks `socket.assigns.run_ui.run_id == run_id and socket.assigns.run_ui.phase == :running`.

**Primary recommendation:** Keep changes in SearchLive, PlaybookLive, existing OpsUi/OpsModal hooks, and the existing LiveView/browser verification lanes. Plan behavior checks at the rendered-control boundary and real-browser focus/layout boundary. Phase 176 is downstream of Phase 175; `.planning/STATE.md` still places Phase 173 at “READY TO EXECUTE,” so research/planning now does not authorize or imply phase execution or completion. [VERIFIED: .planning/STATE.md:2-12] The source states `current_phase: 173`, `status: Ready to execute`, and `stopped_at: "Phase 176 UI-SPEC approved; next: $gsd-plan-phase 176; Phase 173 remains ready to execute"`. [VERIFIED: .planning/ROADMAP.md:108-118] The source states `**Depends on**: Phase 175`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Search criteria and result presentation | Browser / Client | Frontend Server (SSR/LiveView) | The browser owns native form, responsive order, disclosures and concise status presentation; SearchLive validates/dispatches on the server and assigns the result. The backend response remains the evidence source. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:225-290] |
| Playbook preview, run and save | Frontend Server (SSR/LiveView) | Database / Storage | LiveView owns draft and run state; Runner executes validated criteria; Store performs configured workspace file operations. Search backend is an external service for a run, not the source of saved-file truth. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:30-69] The source initializes `:draft_playbook`, `:selected_basename`, `:run_result`, and `:run_ui` and calls `allow_upload(:playbook_file, ...)`. |
| Occasional file management and destructive confirmation | Frontend Server (SSR/LiveView) | Browser / Client | Server-side eligibility, authorization and path/collision checks own mutation safety; browser disclosure/dialog behavior owns discoverability and focus. Hiding controls is not an authorization check. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:9-16,78-129] The source defines `@basename_regex ~r/\A[\w.\-]+\.json\z/` and `safe_basename?/1` matching that pattern. |

## Standard Stack

### Core

| Library / system | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Project constraint `~> 1.17`; current shell shim has no version selected | ScrypathOps server-side UI and ExUnit tests | Existing project and `scrypath_ops/AGENTS.md` establish Elixir/Phoenix conventions. [VERIFIED: scrypath_ops/mix.exs:4-14] Exact source: `elixir: "~> 1.17"`. |
| Phoenix LiveView | Locked version `1.1.33`; project constraint `~> 1.1.33` | Server-rendered forms, patches, async run lifecycle and uploads | Already used by both surfaces; current versioned docs cover the relevant lifecycle. [VERIFIED: scrypath_ops/mix.exs:45-52] Exact source: `{:phoenix_live_view, "~> 1.1.33"}`. [VERIFIED: scrypath_ops/mix.lock:40] Exact lock source: `"phoenix_live_view": {:hex, :phoenix_live_view, "1.1.33"`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html] |
| Phoenix.Component / existing ScrypathOps OpsUi | Existing app components | Shared controls, fields, disclosures, statuses, object rows and OpsModal | Phase 173 makes the current token/component system authoritative and Phase 176 UI-SPEC inherits it. Existing `<details>` disclosure renders through `ops_disclosure/1`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1280-1307] Exact source includes `<details`, `<summary`, and `open={@open}`. |
| Playbook V1, Runner and Store | Existing project modules | JSON validation, execution, workspace persistence and filename safety | These own behavior beneath presentation; do not duplicate policy in new UI helpers. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:54-64] Exact source: `Writes UTF-8 data to a workspace file by basename (overwrites).` |

### Supporting verification

| Tool | Version / status | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | Bundled with project Elixir; runtime not selected in this shell | Rendered LiveView form/event, state, validation and persistence contract tests | Every changed server-side UI/state rule; keep tests in the existing Ops suite. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs:1-8; scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:1-7] Exact source includes `use ScrypathOpsWeb.ConnCase` and `import Phoenix.LiveViewTest`. |
| Playwright | Existing ecommerce operator browser lane; package declaration is already present | Actual rendered responsive layout, disclosure, dialog focus and LiveView patch behavior | Use the focused admin surface depth tests for browser-only behavior that LiveViewTest does not model; run inside the existing disposable app stack. [VERIFIED: examples/scrypath_ecommerce/package.json:1-24] Exact source contains `"@playwright/test": "^1.54.2"`. |
| Existing contrast command | Existing repository lane | Contrast of updated tokens/styles in both themes | Run when changed styling affects contrast; no new CI service. [CITED: .planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md:251-265] |

**Installation:** None. Do not add a package for these changes; use the app's current Phoenix, native HTML controls, existing OpsUi, and OpsModal. [VERIFIED: .planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md:267-271] Exact source: `| None | None; owned existing Phoenix components only | Not applicable; no registry import or dependency added |`.

## Architecture Patterns

### System Architecture Diagram

```text
Search form (mode + target + query + page size)
  → SearchLive validates and freezes submitted identity
  → SearchPlayground dispatches to existing Scrypath adapter/backend
  → SearchLive renders complete / zero-hit / partial / failed outcome
  → eligible criteria + metadata may be saved as a Playbook

Playbook catalog / JSON upload or paste
  → PlaybookLive decodes and validates a draft
  → preview → captured run identity/context → existing Runner → existing search backend
  → run summary / diagnostics / Search handoff
  → independent save or per-file Store action
  → configured workspace filesystem (mutation guarded server-side)
```

This traces the two user workflows across the browser, LiveView, adapter/runner, backend and workspace boundary. The UI does not own search freshness or workspace authorization. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:225-290] [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:86-172,739-783] [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:54-129]

### Recommended Project Structure

Keep work within the existing ownership boundaries: `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`, `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`, the shared `ops_ui.ex` only for demonstrated reusable presentation, and `assets/js/ops_hooks.js` only for the existing modal's necessary focus-return correction. Extend their current LiveView tests and the existing ecommerce admin browser spec. These are current source locations, not a request to split the app into new modules. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:118-142] The context names these exact source/test paths and assigns their existing duties.

### Pattern 1: Bind Search output to the dispatched submission

**What:** At submit time, keep the run's mode, allowed target(s), query, page size and identity together; queued work and all result/capture rendering must consume that frozen context. URL/control edits after submit may change the editable form, but cannot relabel the old response. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:225-263] Exact current source: `send(self(), {:run_search, params})` and later `mode = socket.assigns.mode`.

**When to use:** Search's current two-step loading path and any visible last-run response. Add acceptance for a mode change between event enqueue and message handling, changed URL criteria while a result stays visible, and save eligibility after successful zero hits/partial multi response. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:23-32]

**Implementation guide:** Keep native form submit and Enter behavior. Use the source-level values only after reading their definitions; avoid new per-result enums unless the phase requirements establish them. Make a concise result summary the status region, not the full hit list. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html]

### Pattern 2: Separate current Playbook draft from historical run evidence

**What:** Snapshot the validated draft's provenance and criteria with the generated run identity when scheduling. Result status, errors, timeout/cancel text, diagnostics and Search handoff must use that run snapshot. Saving changes current draft persistence provenance only. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:739-783] Exact current source captures `draft = assigns.draft_playbook`, starts `start_async(run_async_key(run_id), ...)`, and applies a result only when `active_run?/2` succeeds.

**When to use:** Load/import after a completed run, imported drafts following a saved file selection, and run cancellation/supersede/timeout. A late async reply should continue to be ignored by run ID; do not replace the existing runner lifecycle. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html]

### Pattern 3: Use native disclosures and existing modal behavior

**What:** Put per-file occasional actions in a closed native disclosure in document flow. Keep mutation eligibility and authorization server-side. Reuse OpsModal for exact confirmation, focus containment, Escape and sensible focus return across patches. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1280-1307; scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1376-1422]

**Why:** W3C's disclosure pattern uses button activation and expanded/collapsed state; its dialog guidance includes focus containment and logical focus restoration when the trigger no longer exists. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

### Anti-Patterns to Avoid

- Do not add a second search submit or move actions into a split-scrolling editor; preserve the UI-SPEC reading order and normal form submission. [VERIFIED: .planning/phases/176-search-and-playbooks/176-UI-SPEC.md:89-107]
- Do not conflate an accepted search, zero hits, partial response, failed request or unavailable setup. Search hits are an observation, not a freshness claim. [VERIFIED: .planning/phases/176-search-and-playbooks/176-UI-SPEC.md:99-107]
- Do not let later form edits, URL patches or imported drafts change the identity of an older result. Use captured criteria and visible “earlier run” attribution or reset consistently. [VERIFIED: .planning/phases/176-search-and-playbooks/176-UI-SPEC.md:99-117]
- Do not infer writable storage from a configured path, or success from a click/flash; surface the actual Store return and preserve existing replacement/collision semantics. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:54-64,78-125]
- Do not use a custom ARIA menu/kebab to model a small occasional file-action group; native disclosure is the locked pattern. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/]
- Do not claim Cancel run rolls back remote work; cancellation applies to the LiveView async task/result path. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:423-457,767-783] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toggleable optional details | Custom disclosure JS, custom keyboard menu | Native `<details>/<summary>` through `OpsUi.ops_disclosure/1` | Native document-flow semantics match the locked action group; avoids introducing menu keyboard behavior. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1280-1307] |
| Modal lifecycle and focus | New modal/focus-trap abstraction | Existing `OpsModal` and its hook, with the phase's visible-target correction | It already handles initial focus, Tab containment, Escape and background inertness; the known gap is checking target visibility after disclosure close, then correct successor targeting. [VERIFIED: scrypath_ops/assets/js/ops_hooks.js:420-576] |
| Workspace safety/persistence | UI-only filename checks, a second filesystem layer, overwrites policy | `Playbook.Store`, `V1`, and existing host authorization | Server-side basename/path, collision and host-eligibility policy already exists. UI presentation must not become the security boundary. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:9-16,54-64,78-129] |
| Search backend or result semantics | New backend client, adapter abstraction, hit browser or export flow | Existing SearchPlayground dispatch, MultiSearchResult, and current capture path | Phase scope is operator UI; no new core API/backend capability is authorized. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:8-14,153-160] |

**Key insight:** This phase's hard work is attribution and focus across async state/DOM patches. Existing LiveView and storage services already supply the behavior seams; preserving those seams keeps UI changes small and prevents a second security or persistence policy from emerging.

## Common Pitfalls

### Pitfall 1: Search mode can drift between submit and dispatch

**What goes wrong:** A queued Search message can execute submitted query/page size with a subsequently selected mode or fallback target, then label/capture it as another submission.
**Why it happens:** `handle_event("search", params, socket)` queues params, while `handle_info/2` currently reads `socket.assigns.mode`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:225-263] Exact source: `send(self(), {:run_search, params})`; `mode = socket.assigns.mode`.
**How to avoid:** Capture the validated mode and all criteria at event time, carry one run snapshot through dispatch and result/capture rendering; add the explicitly locked queued-mode regression case.
**Warning signs:** Result summary changes after a mode/URL update or a saved check uses criteria different from the actual call.

### Pitfall 2: Playbook run ID alone does not preserve attribution

**What goes wrong:** A correctly correlated completion can still be displayed beside a newer preview or current `selected_basename`, making the old outcome look like the new draft's result.
**Why it happens:** Async success checks run ID but currently assigns only result/phase; rendering may use current draft/source. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:389-420,739-783] Exact source: `assign(:run_result, result)` and `assign(:run_ui, %{phase: :ok, run_id: run_id, started_monotonic: nil})`.
**How to avoid:** Store submitted filename-or-import identity and criteria under the run record; keep current save provenance independent; test load/import after a completed run and stale replies.

### Pitfall 3: Partial is not complete, and zero hits is not failure

**What goes wrong:** Counts or success styling imply all indexes returned, or a successful empty search is treated as an error/ineligible capture.
**Why it happens:** Multi-search carries per-index failures separately from the result; zero-length hits are still a returned response. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:382-414] Exact source: `outcome = if failures == [], do: :ok, else: :partial`.
**How to avoid:** Render per-index returned/no-hit/failed outcomes and a concise always-visible partial explanation; test empty success, partial and hard failure separately. Do not claim global freshness or recovery from hits. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22.html]

### Pitfall 4: Configured workspace does not mean writable workspace

**What goes wrong:** UI announces a write before `File.write/2` succeeds or treats configuration as a permission check.
**Why it happens:** Existing `workspace_writable?` is assigned from `workspace_root != nil`; actual persistence can fail in `Store.save_workspace_file/3`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:30-44] Exact source: `workspace_writable? = workspace_root != nil`. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:54-62] Exact source: `File.write(path, data)`.
**How to avoid:** Keep configuration guidance adjacent to the action but report actual write failure from the server, retain entered values, and confirm only after successful persistence.

### Pitfall 5: A connected modal trigger can still be hidden or reused

**What goes wrong:** Closing a modal restores focus into a disclosure that was closed, or to a connected button that now represents another row.
**Why it happens:** The modal hook's return-target check tests connection and matching `phx-value-name`, but does not check visibility after closing a disclosure. [VERIFIED: scrypath_ops/assets/js/ops_hooks.js:535-542] Exact source: `target.isConnected && sameRecord`.
**How to avoid:** Close the disclosure before opening the dialog, retain an explicit visible return target, and test cancel/success/delete/rename with real LiveView patches and row identity changes. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

## Code Examples

Use the project's existing keyed LiveView async shape. The official v1.1.33 documentation shows the generic callback form below; in Phase 176 keep ScrypathOps's current run key and run-ID guard, adding the run snapshot around the existing call rather than changing its execution lifecycle. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html]

```elixir
def handle_async(:my_task, {:ok, result}, socket) do
  {:noreply, assign(socket, :result, result)}
end

def handle_async(:my_task, {:exit, reason}, socket) do
  {:noreply, assign(socket, :error, reason)}
end
```

The source's actual contract to preserve is quoted verbatim here: `@playbook_run_async_key :playbook_run`; `@playbook_run_timeout_ms 60_000`; `@max_import_bytes 256_000`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:24-27] Keep those exact existing values when planning run correlation, timeout and import-limit coverage.

For file input, retain explicit form submission (`auto_upload: false`) and server size validation. LiveView documents `allow_upload/3` limits and completed-entry consumption; current source configures the cap and extension directly. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html] [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:64-69] Exact source: `accept: ~w(.json)`, `max_entries: 1`, `max_file_size: @max_import_bytes`, `auto_upload: false`.

## Project Constraints (from AGENTS.md)

- Keep edits focused and run the checks CONTRIBUTING names for the change; update `.planning/PROJECT.md` only if product scope or shipped claims intentionally change. [VERIFIED: AGENTS.md:54-59]
- Keep `main` green on the lean required gates; feature-depth work is PR-first; completion needs executable tests or exact-SHA hosted evidence, not post-implementation human verification or pending UAT. Do not simulate reviewer identity or auto-approve a trust gate. [VERIFIED: AGENTS.md:59-66]
- ScrypathOps changes use the repository's `mix verify.ops_ui` gate. The sub-app instructions also require `mix precommit`; use existing Req for HTTP and avoid new dependencies unless asked or a demonstrated gap requires one. [VERIFIED: scrypath_ops/AGENTS.md:5-7] [VERIFIED: CONTRIBUTING.md:198-200]
- Use imported Phoenix.Component forms and unique DOM IDs, HEEx, current shared inputs/components when available; do not add inline script tags or use `@apply`. Elixir tests should avoid `Process.sleep/1`; rely on process/test synchronization. [VERIFIED: scrypath_ops/AGENTS.md:31-37,91-103,139-143]
- Preserve Phoenix 1.8 layout/authenticated-route conventions and use imported icon/input components where available; if a component class override replaces defaults, style the replacement fully. Keep CSS/JS in the existing app bundles and do not introduce external script/link assets. [VERIFIED: scrypath_ops/AGENTS.md:8-19,31-37]
- Follow Elixir source rules if implementation touches them: no index-style list access, bind block-expression results, do not nest modules, do not atomize user input, use predicate names ending with `?`, and name OTP processes. Read Mix task help before using unfamiliar tasks and avoid `mix deps.clean --all`. Tests should use `start_supervised!/1` and process synchronization rather than sleeps. [VERIFIED: scrypath_ops/AGENTS.md:49-103]
- Existing sub-app guidance calls for micro-interactions, but the phase's higher-authority D-02 rules out decorative motion for this scope; preserve only functional states and reduced-motion behavior. [VERIFIED: scrypath_ops/AGENTS.md:39-45] [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:20-24]
- Preserve the local source/design baseline and feedback preview; all mutating workspace/browser fixtures belong in a disposable stack. This is also locked in D-26 and `.planning/STATE.md`. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:53-61]

## Validation Architecture

`workflow.nyquist_validation` is enabled in `.planning/config.json`; retain this section. The existing Ops gate is the canonical server/UI test command. This research did not run product tests or UI acceptance. [VERIFIED: .planning/config.json:15-22] Exact source: `"nyquist_validation": true`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest (version follows the configured Elixir toolchain; this shell has no selected Elixir version) |
| Config file | `scrypath_ops/mix.exs`; LiveView tests under `scrypath_ops/test/` |
| Quick run command | `mix verify.ops_ui` from repository root; `mix test test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/live/playbook_live_test.exs` from `scrypath_ops/` for focused iteration |
| Full suite command | `mix verify.ops_ui` from repository root |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|-------------|----------|-----------|-------------------|-------------|
| OPUX-23 | One native Search form/submit in reading order; submitted criteria remain attributed through queue, URL changes, partial/zero/failure/setup and capture | LiveView + focused browser | `mix verify.ops_ui`; `npm run test:e2e:admin-depth` from `examples/scrypath_ecommerce/` against a disposable stack | Yes: `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`; add the frozen-mode/criteria and real browser-order cases required by D-25 |
| OPUX-24 | Preview/run/save/import stages preserve source/run/save provenance and existing validation, read-only and overwrite behavior | LiveView + focused browser | `mix verify.ops_ui`; `npm run test:e2e:admin-depth` when rendered workflow/layout changes | Yes: `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`; add/import-run-save provenance transitions and preserve existing workflow assertions |
| OPUX-25 | Per-row disclosure plus safe rename/duplicate/delete, typed confirmation, validation and logical focus return after patches | LiveView + real browser | `mix verify.ops_ui`; `npm run test:e2e:admin-depth` against a disposable stack | Yes: current Playbook LiveView tests cover server behavior/dialog markup; real rendered focus/visibility after close/rename/delete patches is a browser acceptance gap to add |

### Sampling Rate

- **Per task commit:** Run the relevant focused LiveView test(s), then `mix verify.ops_ui` at the phase slice gate.
- **Per wave merge:** Inspect paired desktop/narrow and light/dark renders for the touched state; run focused browser interaction/focus and contrast checks where layout/style changed.
- **Phase gate:** OPUX-23, OPUX-24 and OPUX-25 each have executable, source-bounded evidence; pass `mix verify.ops_ui` and the applicable focused browser/contrast lanes before final verification.

### Wave 0 Gaps

- No new test framework or CI lane is needed. Existing tests already cover basic rendered form behavior, partial/hard failure, upload hints, run timeout/supersede and server dialog rules. [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs:53-66,162-262] [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:95-112,574-636,715-758]
- Add focused tests alongside the implementation for the exact missing-risk cases: queued Search mode/criteria mutation, result/capture provenance after URL edits, Playbook run provenance after load/import/save, import failure with previous preview state, and visible focus return across real LiveView row patches. D-25 already requires these cases; plans should give each a named acceptance slice.

## Security Domain

Security enforcement is enabled by default. The phase changes presentation around existing operator actions, so preserve server authority and never treat hidden UI as a security control. Use current OWASP ASVS 5.0 names: V2 Validation and Business Logic, V5 File Handling, and V8 Authorization are relevant to user-submitted search/playbook criteria, JSON uploads/workspace paths and host-controlled file mutation. [CITED: https://github.com/OWASP/ASVS/releases] [CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Encoding and Sanitization | Yes | Keep rendered user-provided filenames, query values and JSON in escaped HEEx text/code components; do not create raw HTML from them. |
| V2 Validation and Business Logic | Yes | Server validates selected schemas, page size, Playbook structure and typed deletion confirmation; client constraints are only usability feedback. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.flat.json] |
| V5 File Handling | Yes | Keep upload extension/count/size limits and paste byte check; only use safe basename/path-resolved Store operations. Existing Playbook import is bounded by the exact source value `@max_import_bytes 256_000`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:24-27,64-69,75-83] |
| V8 Authorization | Yes | Retain host authorization and server eligibility at every mutation event; catalog visibility is not authorization. The UI-SPEC explicitly preserves host-owned policy. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.flat.json] |
| V6 Authentication / V7 Session Management | No new control in this UI phase | Existing host/operator authentication/session ownership is outside scope; do not alter routes, host authorization product or session policy. |
| V11 Cryptography | No | No cryptographic operation, secret storage or credential handling is being added. |

### Known Threat Patterns for Phoenix LiveView Operator UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged `phx-click`/form fields for file actions | Elevation of privilege / Tampering | Validate eligibility, auth, basename/path and collisions in server event + Store; preserve exact delete confirmation. [VERIFIED: scrypath_ops/lib/scrypath_ops/playbook/store.ex:9-16,78-129] |
| Oversized or malformed JSON | Denial of service / Tampering | Preserve LiveView upload size/count and server paste-byte limits, decode as JSON object, apply V1 validation before preview/run/save. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:24-27,64-107,731-737] |
| User text interpreted as code/HTML | Tampering | Keep filenames, query and raw JSON as escaped HEEx text; do not introduce HTML injection or logging/export. |
| Stale result presented as current evidence | Tampering / Information quality | Bind submitted criteria, source and run identity into each rendered outcome; do not claim search freshness or remote rollback. |

## Environment Availability

The plan depends on existing Mix/Elixir tests and an existing Docker-backed browser stack; the canonical `mix verify.ops_ui` gate does not require a live Meilisearch service. [CITED: CONTRIBUTING.md:198-200] Current shell probes found:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Ops LiveView tests and canonical gate | No usable selection | Both `elixir --version` and `mix --version` report “No version is set for command” [VERIFIED: shell probe 2026-10-10] | Select a supported local BEAM runtime; the CI path-scoped Ops gate remains available outside this shell [CITED: CONTRIBUTING.md:198-200] |
| Docker | Disposable browser acceptance stack | Yes | Docker 29.5.2 [VERIFIED: shell probe 2026-10-10] | — |
| Node.js / npm | Existing Playwright browser lane | Yes | Node v26.10.0; npm 11.19.0 [VERIFIED: shell probe 2026-10-10] | Existing Docker browser lane owns browser/runtime setup [CITED: examples/scrypath_ecommerce/Makefile:1-8] |
| PostgreSQL | Ops LiveView test setup | Yes, local port 5432 responds accepting connections [VERIFIED: shell probe 2026-10-10] | Version not probed | Existing test/docker configuration [CITED: CONTRIBUTING.md:198-200] |
| Meilisearch | SearchLive's configured backend in tests | Not probed; not required by canonical Ops gate [CITED: CONTRIBUTING.md:198-200] | — | LiveView suite uses a stub adapter [VERIFIED: scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs:10-12]; do not add service requirement |

Missing dependencies with no fallback:
- None for CI planning. Local `mix verify.ops_ui` cannot run until a supported Elixir/Mix version is selected; the Docker browser lane alone does not replace that server-side gate.

Missing dependencies with fallback:
- Local BEAM tool selection: restore a supported Elixir/Mix installation or rely on the path-scoped CI gate for the canonical Mix suite.

## Sources

### Primary documentation (MEDIUM confidence per provider classification)

- [Phoenix LiveView 1.1.33 API docs](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html) — async start/cancel, task result callbacks, upload limits and consumption.
- [W3C ARIA Disclosure Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) — Enter/Space activation and disclosure expanded state.
- [W3C ARIA Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — initial focus, containment, inert background, Escape and return target logic.
- [W3C ARIA22](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22.html) and [WCAG Focus Order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html) — concise status announcements and reading/keyboard sequence.
- [OWASP ASVS 5.0 release](https://github.com/OWASP/ASVS/releases) and [OWASP ASVS index](https://cheatsheetseries.owasp.org/IndexASVS.html) — current category names and security scope.

## State of the Art

| Earlier/current alternative | Recommended current approach | When Changed | Impact |
|--------------|----------------------------|--------------|--------|
| Expose every row mutation beside common file actions | Keep Load preview and Run without preview visible; place mutations in a closed native Manage disclosure | Phase 176's locked UI contract | Reduces action competition while preserving normal form/button and server-side mutation behavior. [VERIFIED: .planning/phases/176-search-and-playbooks/176-UI-SPEC.md:109-118] |
| Let current form/draft assigns label whatever result is visible | Bind each visible outcome to its submitted Search or Playbook run context | Phase 176's locked UI contract | Prevents editable query/URL changes and later imports from rewriting earlier evidence. [VERIFIED: .planning/phases/176-search-and-playbooks/176-UI-SPEC.md:99-117] |

**Deprecated/outdated:** No external library or framework transition is recommended. Avoid stale “export a playbook JSON” UI copy because the locked context says current Search offers capture/save, not download/export. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:44-48]

### Project sources

- `.planning/phases/176-search-and-playbooks/176-CONTEXT.md`, `176-UI-SPEC.md`, `176-UI-CHECK.md` — locked implementation behavior, realistic static compositions and acceptance obligations. Static comps are not application proof.
- `.planning/phases/173-shared-visual-foundation-and-operational-time/173-UI-SPEC.md` — inherited theme, token/component system and verification standards.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/research/v1.43/SCOPE.md`, `.planning/reference/OPERATOR-UI-REFINEMENT.md`, `.planning/reference/OPERATOR-UI-QUALITY.md`, `CONTRIBUTING.md`, and root/sub-app `AGENTS.md` — lifecycle, product limits, verification, and repository constraints.
- `prompts/phoenix-live-view-best-practices-deep-research.md`, `prompts/elixir-search-lib-deep-research.md`, `prompts/meileisearch best practices for scrypath deep research.md`, `prompts/search-lib-use-cases-deep-research.md`, `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`, and `prompts/phoenix-best-practices-deep-research.md` — local context only; no new product claim or alternative backend recommendation is drawn from them.
- Current Search/Playbook LiveViews, OpsUi, OpsModal hook, Store, tests and `scrypath_ops/mix.exs` — source-of-truth implementation evidence. The current dirty Search UI source was read only and left unchanged.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The existing focused browser acceptance can run through the documented disposable Docker workflow once its phase-specific checks are added. | Validation Architecture / Environment Availability | If the existing lane cannot exercise the new controls, planning must select a current existing browser target or surface a concrete testability gap; do not create a new required service by default. |
| A2 | ASVS 5.0 is the appropriate current taxonomy for security mapping in the plan. | Security Domain | The concrete controls remain server-side validation, safe file paths, and host authorization; taxonomy changes would affect labels rather than scope. |

## Open Questions

1. No product or interaction decision blocks planning; CONTEXT and UI-SPEC resolve the behavior. [VERIFIED: .planning/phases/176-search-and-playbooks/176-CONTEXT.md:16-69] The local shell needs a supported Elixir version selected before local Mix verification, with CI available for the canonical Ops gate. [VERIFIED: shell probe 2026-10-10] [CITED: CONTRIBUTING.md:198-200] The planner should include runtime availability in the first execution preconditions rather than infer that a missing shell version means the repository no longer supports its declared Elixir range. [VERIFIED: scrypath_ops/mix.exs:4-14]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — current dependency constraints and versioned official LiveView docs were read; local BEAM version is unset.
- Architecture: HIGH — based on current LiveView, Store, component and hook source, plus phase-owned UI contract.
- Pitfalls: HIGH — stale attribution, server trust and focus-return seams are directly observable in source and already named by approved context.

**Research date:** 2026-10-10
**Valid until:** 2026-11-09 for stable project architecture; recheck toolchain and upstream docs if dependency constraints change.
