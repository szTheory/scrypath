# Phase 176: Search and Playbooks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents. Decisions are captured in CONTEXT.md; this log preserves alternatives and delegated selections.

**Date:** 2026-10-10
**Phase:** 176-search-and-playbooks
**Areas discussed:** Search reading order; Preview and execution; Saving and imports; Playbook file actions.

## Maintainer direction and method

The initial numbered selection offered all four areas. The maintainer replied with “discuss/consider all” and explicitly requested relevant-role fan-out, breadth/depth, reputable primary sources, examples and tradeoffs, an adversarial pass, synthesis to diminishing returns, and automatically following the coherent recommendations. They also stated the preference “another copy and paste is better than another dep,” allowing a dependency only when truly needed.

No individual recommendation is represented as a separately clicked user answer or reviewer approval. The selections below are the agent's choices under that explicit delegation. The command did not include --auto or --chain; automatic decision adoption does not enable automatic planning/execution or change project configuration.

Read current Search/Playbook code, shared modal hooks, storage/runner contracts, focused tests, approved scope, and prior shared visual decisions. Applied Impeccable Operate guidance with existing PRODUCT.md/DESIGN.md and comp-first preference. Used three typed GSD advisor researchers, resolved through the project's adaptive gpt-6-luna/high routing:

- search_hierarchy: Search reading order, then a separate saving/imports pass.
- playbook_workflow: preview/execution hierarchy and async/result provenance.
- playbook_management: occasional actions and modal focus, then a separate adversarial cross-area pass.

Each area considered operator/product, design/accessibility/mobile, Phoenix/browser state, operational truth, safety/storage, and maintenance as relevant. Primary-source guidance came from W3C, Phoenix and GOV.UK; page topology is a project inference. Four area studies plus one adversarial pass yielded a consistent direction and concrete source findings. Stop here: additional general research would not change the scoped recommendation. Product tests, screenshot acceptance and implementation review were not performed or simulated.

## Search reading order

| Option | Pros | Cons / failure modes | Selected |
| --- | --- | --- | --- |
| Controls above results in one reading order | Matches target → query → run → inspect; consistent mobile/keyboard sequence; broad result area | Longer page; submitted identity must remain separate from later inputs | ✓ |
| Desktop split with narrow stacking | Useful for repeated tuning while keeping controls visible | Cramped results/identifiers; more responsive/focus obligations; no current evidence of a dominant desktop editor job | |

**Decision points considered:** controls/results topology; primary submit placement; summary versus raw diagnostics; attribution when mode/query/URL inputs change.

**Delegated selections:** One Run search form submit, no empty-state duplicate. Results show actual submitted criteria, readable hit/per-index outcomes and visible partial failure. Raw payload/trace/metadata are secondary disclosures. Preserve setup/disabled/busy/zero-hit/full-failure distinctions and meaningful status announcement. Freeze submitted mode alongside params; do not let a queued dispatch read a later mode or label old results/capture with new inputs.

**Tradeoff:** Prefer dependable scanning and wide result content over a second desktop interaction model. Revisit a split only with concrete operator evidence that repeated tuning suffers under the vertical flow.

**Primary guidance:** [W3C focus order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html), [W3C search status example](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22.html), [Phoenix form bindings](https://hexdocs.pm/phoenix_live_view/1.1.33/form-bindings.html).

## Preview and execution

| Option | Pros | Cons / failure modes | Selected |
| --- | --- | --- | --- |
| Catalog → preview with run/save → results; secondary import after common work | Same task sequence across widths; selection, preview, execution and persistence remain distinct | Page length; stale result attribution must be handled | ✓ |
| Desktop master/detail | Faster switching with a large catalog | Additional focus/layout state and narrower content; selected file can be confused with imported draft | |
| Wizard or tabs | Compresses the initial screen and forces stages | Hides context/errors; conflicts with supported direct run and independent saving; unnecessary keyboard/navigation obligations | |

**Decision points considered:** section ordering; catalog/direct-run priority; imported-preview naming; running/terminal/partial and old-result attribution.

**Delegated selections:** Load preview is normal; Run without preview stays visible and quiet. The preview uses Run playbook with reachable saving, not Run saved playbook for an unsaved import. Show draft provenance separately from run source and saved file. Run outcomes and Search loopback describe the captured run, including partial multi responses. Preserve cancellation, timeout, supersede and run-ID/late-result guards.

**Tradeoff:** Explicit task stages without locked sequencing. A valid draft may run without being saved and may save without running. Retain an older result only with its own visible attribution; otherwise reset it consistently. Do not add a new detailed Playbook result browser.

**Primary guidance:** [Phoenix LiveView 1.1.33 async API](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html), [W3C status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), [W3C tabs obligations](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/).

## Saving and imports

| Option | Pros | Cons / failure modes | Selected |
| --- | --- | --- | --- |
| Catalog first; contextual Search capture; independent Playbook draft saving; visible import entry to later tools | Common checks lead; save scope is clear; upload/paste remain discoverable | Import needs an obvious entry when placed lower; error/provenance must not expose an old preview as a new successful import | ✓ |
| Import/create first, catalog later | Easier for operators arriving primarily with new JSON | Pushes repeat checks down; import/run/save compete as primary tasks | |
| Require successful execution before every save | Enforces a simple apparent sequence | Changes existing supported save semantics; zero-hit or partial checks may still be useful; success is not persistence | |

**Decision points considered:** Search capture eligibility/meaning; saving a Playbook without running; import placement and file/paste access; actual filename/replacement and permission behavior.

**Delegated selections:** Search capture follows an actual response, including zero hits/partial multi results, and saves criteria rather than hits. Playbooks can save any valid imported/loaded draft without executing. Keep Save as playbook visible and its form progressive; JSON evidence stays optional. Keep Import JSON visible near the catalog and prominent in empty state, with file upload and a paste disclosure in the later section.

**Source corrections:** Search has capture/save but no export/download control. Search capture rejects an existing filename; Playbook save uses an overwriting Store API; rename/duplicate reject occupied destinations. Preserve these differences and explain replacement before Playbook save. A configured workspace is not a guaranteed successful write. Keep failed input and accessible field errors, and update current draft provenance only after successful persistence.

**Synthesis adjustment:** The saving researcher favored preserving a directly available upload section; the workflow researcher favored placing it after common preview work. Combine both with a visible catalog-level import anchor and the later file/paste section, rather than hiding every import affordance or forcing import ahead of a selected preview.

**Primary guidance:** [GOV.UK details](https://design-system.service.gov.uk/components/details/), [GOV.UK action hierarchy](https://design-system.service.gov.uk/components/button/), [W3C form notifications](https://www.w3.org/WAI/tutorials/forms/notifications/), [Phoenix uploads](https://hexdocs.pm/phoenix_live_view/1.1.33/uploads.html).

## Playbook file actions

| Option | Pros | Cons / failure modes | Selected |
| --- | --- | --- | --- |
| Labeled per-row Manage file actions native disclosure and ordinary buttons | Contextual file identity; familiar keyboard; removes three competing row actions; no menu dependency | Requires visible focus-return target after closing the disclosure; long names must wrap | ✓ |
| Icon overflow ARIA menu | Compact | Hidden affordance; arrow/focus/menu obligations; popup clipping and support complexity | |
| Management for selected file only | Fewer repeated controls | Must load/select before managing another file; preview identity can misdirect file mutation | |

**Decision points considered:** management discoverability; read-only/server/destructive safeguards; dialog initial/error focus; visible focus return after patches, rename or deletion.

**Delegated selections:** Keep preview/direct-run outside management. Use ordinary buttons inside a native disclosure, no menu role or custom menu keyboard model. Preserve filename/path/collision/authorization checks and typed exact-filename delete confirmation. Reuse OpsModal for initial focus, background inertness, Escape and Tab containment. Keep invalid values/errors inside the open dialog. Close the disclosure on modal open only after selecting its visible summary as the return target; preserve logical successor handling for renamed/deleted rows.

**Tradeoff:** A labeled control occupies more space than an icon, but it communicates the available occasional actions and avoids a second interaction framework. Expansion in document flow avoids popup clipping. Test focus through actual LiveView patches rather than assuming a connected DOM element is visible or still belongs to the same file.

**Primary guidance:** [W3C disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/), [W3C modal dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/), [W3C menu-button example](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/examples/menu-button-links/).

## Adversarial synthesis and concrete examples

| Example | Risk | Selected contract |
| --- | --- | --- |
| Submit a single-index Search, then switch mode before the queued message runs | Dispatch/capture/URL may use later socket mode | Freeze mode and submitted criteria together; display actual run attribution |
| Edit query or visit different URL criteria while results remain | Old outcome appears to answer new inputs | Attribute retained results to last submitted criteria; preserve proper capture invalidation |
| Run file A, then import draft B or load file C | B/C inherits A's filename, mode or terminal success | Separate current preview provenance from the captured run source; reset or label retained outcome |
| Save an imported draft under new-name.json | Success still appears attached to earlier selected file | Change current persistence provenance only after successful write, retain run attribution |
| Save to a configured but unwritable workspace | UI implies permissions or completion from configuration | Explain attempted availability; show actual write error; retain values |
| Multi-result contains per-index failures | Green completion implies all indexes succeeded | Visible partial outcome and counts; diagnostics optional, failure itself visible |
| Management disclosure closes before dialog return | Connected trigger is hidden, so focus disappears | Return to visible same-file summary or logical successor after settled patch |
| A deleted row's button DOM is reused | Focus lands on the wrong file | Check file identity plus visibility, not connection alone |
| A raw payload is collapsed | Hidden content is mistaken for privacy protection | Preserve data warning; disclose that folding is not redaction |
| Copy diagnostics dispatches a browser event | Immediate flash falsely promises clipboard success | Named existing limitation if untouched; any scoped rewire follows actual-result feedback |

This pass did not recommend changing overwrite, authorization or filesystem safety policy, expanding Search APIs, or adding dependencies. It supplied scoped attribution/focus corrections necessary to deliver the requested hierarchy truthfully. No product behavior has been implemented or verified here.

## Agent's Discretion

Exact composition, labels, neutral grouping, small internal state structure, and focused tests follow the locked behavior in CONTEXT.md and the next UI contract. Existing shared palette and product scope are already decided. Preserve local edits and feedback :4012; mutating acceptance uses disposable stacks. No ordinary human UAT or new CI lane is added.

## Deferred Ideas

Desktop split/master/detail without new evidence; wizard/tabs; export/download, run history or a Playbook hit browser; new dependencies; core/search/relevance changes; altered overwrite/authorization/filesystem policy; infrastructure automation; new CI services/paid judges; incidental diagnostics-copy rewrite; Impeccable sidecar maintenance. Forward Phase 176 discussion does not skip Phase 173–175 execution.

**Next lifecycle command:** `$gsd-ui-phase 176`, then `$gsd-plan-phase 176`. No implementation-chain flag was requested.

**Document validation:** Confirmed 27 unique sequential decision IDs, all six context sections, OPUX-23–25, 20 existing local canonical references, and four resolved areas. All 24 snapshotted pre-existing source/design/config files remained byte-identical. Automatic advance and chaining remain disabled. The three version-pinned Phoenix references resolve successfully. This is planning-document validation, not product acceptance.
