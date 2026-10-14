# Scrypath UI baseline

**Direction recorded:** 2026-10-14, direct maintainer feedback. **Status:** scoped; implementation and product acceptance remain open. This is the next UI follow-up, not a replay of Phases 173–177 or a new phase-completion receipt.

## Purpose and boundaries

Make the existing experience understandable, efficient and visually consistent before any future brand refresh. Keep the current brand, native controls and architecture; no new framework, dependency, paid design service or visual-judge gate is needed for this work. The previous source recovery, simpler shared controls and evidence safeguards are real delivered progress. They do not establish that the overall UX is good or close to accepted.

The single role/job/language authority remains [OPERATOR-UI-QUALITY.md](OPERATOR-UI-QUALITY.md). The single feedback ledger remains [UI-FEEDBACK.md](../UI-FEEDBACK.md). This plan sequences that work rather than creating a competing model. Feedback examples are a sample; inventory the whole application and find additional task blockers before narrowing repairs.

Maintainer input is useful for task priority and comprehension. It must not become a requirement that the maintainer find every defect or approve every copy edit. No full persona workshop is required. The current direction is enough to begin: trying search is a primary task; operational problems must be clear and actionable; saved inputs should be understandable and reusable.

## Behavioral references

Reviewed official public material on 2026-10-14. These are dimension-specific references, not a claim that every screen or feature in these products is exemplary, nor a hands-on comparative usability study. Evaluate task sequence, information placement, state explanation and control behavior; do not copy their visual identity or import their entire feature set.

| Reference | What the source establishes | Benchmark question for Scrypath |
| --- | --- | --- |
| [Meilisearch search preview](https://www.meilisearch.com/blog/q4-2024-release-wrap-up), with [current performance inspection](https://www.meilisearch.com/launch-week/q1-2026) | Search options, facets and optional ranking evidence sit within a query-inspection workflow; performance detail is reached from search preview. | Can someone select a schema, run a query, see attributed results and reach relevant detail without reading an operational essay first? |
| [Algolia relevance inspection](https://support.algolia.com/hc/en-us/articles/7964661896849-How-can-I-troubleshoot-relevancy-using-Algolia-dashboard) | Result-level ranking explanations and an optional query interpretation view support debugging. | Does detail answer a concrete question about this query/result, and can it remain secondary until needed? Scrypath should expose only evidence it actually supports. |
| [Oban Web](https://oban.pro/web) | Job filtering, job/error inspection, queue controls, and real throughput/depth/execution metrics are separate capabilities. | Can someone distinguish pending work, retries and terminal failures, reach affected work, and see what action is available? Scrypath need not recreate a full queue dashboard or show graphs without history. |

These benchmark questions are our recommendations inferred from the documented patterns. They do not validate Scrypath personas or prove demand for additional features.

## Concrete recommendations

- Keep Search prominent in the existing navigation and home actions. With six destinations, a flat list is a stronger starting point than Home/Recover/Explore taxonomy. Keep an attention cue for real failures; do not silently change the landing route during editorial cleanup.
- Show each navigation action once. A whole-card link needs one title, relevant supporting information and an optional arrow; repeating its title as another CTA adds no value.
- Use sentence case and task language. “Go to…” is clearer than “Jump to surface”; schema allowlisting is a security implementation detail until configuration or authorization affects the task.
- Home should give a short problem, affected object and next action. For the reported queue-only failure, a candidate is **“3 sync jobs failed”**, **“Product · Some search results may be out of date.”**, **“View failed sync work”**. This wording is conditional on actual source state, not a universal summary. Use correct singular/plural and a distinct summary when Meilisearch tasks or observations fail. Keep the full schema identity available, including disambiguation for duplicate short names.
- Prefer **Saved searches** consistently in the UI. Explain once: “Save queries and options to run again.” A file can contain multiple schema/query entries. Keep Playbook module names, routes and `playbook_format` unchanged; these are saved inputs, not stored results, pass/fail tests, scheduled jobs or recovery runbooks. Expose **Storage folder** and its exact path in details or configuration/error contexts.
- Name the Meilisearch index and Meilisearch tasks explicitly where that context matters. Describe Oban as background synchronization; keep the configured mode and the inline/manual alternatives available in appropriate help. Preserve the job/task distinction.
- Health should summarize exceptions first and put diagnostic counts/evidence below. Normal zero counts may be compactly summarized or disclosed. Missing/unavailable/stale observations must remain visible and cannot become a reassuring zero. No broad “healthy” claim based solely on an absence of failed tasks.
- Pending jobs are normal work; retrying jobs have encountered errors; terminal failed jobs need investigation. Numbers should lead to relevant inspection. A count without elapsed-time/rate evidence does not prove a backlog or stuck worker. Keep charts out of this baseline unless real retained history and a user decision justify them.
- Prefer a single timestamp button with visible-on-focus/hover copy affordance and an accessible name. Copy the exact source value; retain exact-time access and truthful clipboard failure/success feedback. Do not make copy behavior invisible, hide essential help on touch, or prevent normal keyboard operation.
- Evaluate one shared UTC/local display preference instead of repeated Source ISO/UTC disclosures. The maintainer suggested placing it near theme controls; assess placement rather than automatically adding another prominent picker. The displayed zone must be unambiguous; relative ages are timezone-independent, and copying must preserve the original source value and precision. Verify local-zone/DST conversion, preference persistence and unknown states. The default/placement remain an implementation decision to resolve within batch 2.
- Use surrounding context once: a failed-work action inside a schema summary need not repeat its full module name visually. Preserve the selected-schema destination and accessible context. Failed-sync selection/help/result text must distinguish current selection from retained result scope, without repeating the current selection in every section.
- A successfully inspected empty failed-work result needs one compact confirmation, not a green summary plus empty hero, zero reason badges and another refresh action. Do not infer an empty queue or healthy search from zero failures. Omit “dominant reason” when there are no failures; actual unclassified failures are a different state.
- Replace raw operator-reference path lists with descriptive links to useful rendered help. Keep next-step guidance only where it supports the current journey, with state-appropriate wording. The user explicitly asked not to discard useful handoffs prematurely. “When the queue's clear” is not supported merely by absence of failures.
- Progressive disclosure is a tool, not an acceptance goal. Remove redundancy first; assess the additional choices/clicks a disclosure or global preference creates. Avoid replacing one noisy element with another hierarchy or settings mechanism.

## Source findings to resolve

At source `97706bfb502e2b3940b6da6e752208a68ac6b6b7`:

1. `ScrypathOps.Posture.queue_observed_count/1` counts **schemas with observed queue status**, not distinct queues. The “Queues observed” label misstates its unit.
2. `degraded_evidence/1` adds failed Meilisearch tasks and failed queue jobs, calls the sum “sync jobs”, and gives all causes the same queue-first instruction. Preserve separate counts and choose the next action by cause. Fetch errors may coexist with valid retained observations; keep that boundary intact.
3. `Scrypath.Operator.Status` computes last success from completed states in the supplied history. The demo seeds catalog documents inline and injects failed/retrying Oban rows; that does not guarantee a completed Oban job in retained history. The demo inspector also bounds its history and maps selected timestamp fields. Trace the actual current missing-time case and completion mapping before diagnosing it as a seed bug. No success in available history does not prove that sync has never succeeded.
4. The historical “incident first” UI-review priority was a documented choice. The maintainer's 2026-10-14 everyday-search direction supersedes it. Keep job IDs and operational guarantees stable; update priority instead of inventing a new product story.

**Additional source check at `c5be0598`, same product source:** `FailedSyncLive` always renders the selected-schema/dominant-reason summary and all reason counts for a successful inspection. `dominant_reason_class/1` chooses a maximum even when every class count is zero. An empty result then also renders an empty hero with its own Refresh action, and the handoff is present for any successful selected-schema inspection regardless of failure/pending counts. These are rendering/meaning issues; seed changes alone would not address them. The maintainer's Variant route is evidence of the reported experience, not a reason to remove empty-state coverage.

## Three repair batches

| Batch | Deliverable | Evidence needed before closing |
| --- | --- | --- |
| 1. Orientation and primary search path | Search prominence; clear navigation/palette; concise home verdict; single destination actions; Search target/query/result hierarchy and accurate schema/index language. Covers CONTENT-04/05/08, UX-02, UI-12 and the Search part of UI-08. | Whole-inventory critique before repair; actual query/result journey and invalid/missing target behavior; observed home failure/normal/partial/retained states; keyboard/mobile and adjacent shared navigation checks. |
| 2. Health and operational evidence | Natural, cause-specific failure summaries; correct units; compact normal/empty-state information; clear Oban/Meilisearch/index context; contextual links and useful help/handoffs; timestamp controls/shared display preference; representative success/missing history. Covers CONTENT-09–16, UI-13–16, DATA-01, DOC-04 and UX-03/04. | Separate queue/backend/observation failure scenarios, pending/retrying/terminal cohorts, zero/nonzero reasons, unknown/stale/partial cases, sync modes, exact scope and retained evidence; eligible recovery to follow-up check in disposable tests. Verify exact timestamp copying and zone behavior. No fabricated timestamp, empty-queue inference or freshness promise. |
| 3. Saved-search flow and baseline confirmation | Consistent Saved searches language, preview/select/run/save hierarchy, secondary storage details; remaining storefront/help/theme/legacy-test findings reconciled with current design. Covers CONTENT-06/07 plus existing UI-01–08, DOC-01/03, CONTENT-01/03 and AUTO-02 according to their evidence. | Query → saved inputs → preview → rerun with attributed results; import/save/run errors and file scope; populated/no-hit/unavailable facets; readable rendered guide; matching light/dark/system and compact/wide evidence. Close only verified portions; report remaining findings explicitly. |

Each batch is one coherent repair followed by a bounded confirmation, using the existing [UI review loop](../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md). Inspect unreported defects and shared effects, preserve working behavior, and update the ledger. Do not restart palette exploration, replay completed phases, or make repeated unscoped polish passes. Split a batch only when an actual technical dependency requires it; retain these outcomes and finish criteria.

## Observable finish criteria

The baseline is complete when current-source evidence demonstrates all of the following:

- **Try search:** select the intended schema(s), enter/run a query, distinguish results/no results/unavailable results, and understand result origin. The primary controls and result status have a clear responsive reading order.
- **Understand and recover:** identify the affected schema/index and actual source of a problem, reach relevant work, take only an eligible action, and distinguish task acceptance from completion and document visibility. Normal/unknown/stale states are honest.
- **Save and reuse:** understand what is being saved, preview it, save/import/rerun it, and distinguish saved definition, current draft and execution result without understanding the server filesystem first.
- **Whole application:** storefront, all six operator routes, and the guide handoff have been assessed for unreported hierarchy/content/control defects. Required populated, empty, setup-missing, loading/error/partial/stale and long-content cases have receipts or an explicitly unresolved coverage gap. A gap keeps completion open.
- **Consistent baseline:** no unresolved task-blocking or misleading-state findings, no known glaring control/layout/contrast defects, and all reported baseline issues are either verified fixed or explicitly dispositioned with evidence. Existing brand and tokens remain coherent across light/dark/system and 1440/768/390 widths. No claim of independently validated taste or adopter research.
- **No regression:** meaningful functional/accessibility checks and required CI pass on delivered source, after the last change. Compare before/after rendered evidence; a capture count or old review score is insufficient. Use a reviewed deterministic visual reference only after it is actually reviewed.

Progress reports should show **which of the three tasks now succeeds, which batch is delivered, which concrete findings remain, and which evidence is missing**. Do not invent a percentage from issue counts or treat tooling completion as product acceptance. Stop at this baseline; future brand work and speculative features are a separate decision.

## Handoff

Continue in the checkout named by `../UI-PREVIEW.json`. Run `npm run ui:preflight` before product edits/capture, preserve the seed-disabled retained preview, and use disposable data for stateful verification. Start with batch 1's current-evidence critique and implementation plan. Do not run `$gsd-execute-phase 173`, `174`, or `176` again; no new numbered phase is created by this document. Additional maintainer feedback extends the existing ledger, not a competing backlog.
