# Operator UI quality default

**Owner direction:** 2026-10-03, v1.42. Applies to later operator UI work unless the maintainer changes it.

## Product direction

Build a conventional, legible operator interface from the existing Phoenix components and design tokens. Use the principle of least surprise and established patterns from comparable operational tools. Improve the consistency of the system with each change. The maintainer can explore a running preview and give direction while work proceeds; routine acceptance must not require human UAT.

The maintained operator audience and job model is in the **Experience model** section below. Treat roles as task contexts that may overlap, not fictional demographic personas. It is a maintainer-curated hypothesis grounded in Scrypath's supported workflows and direct feedback, not validated adopter research. Inventory the six existing surfaces against relevant job IDs before changing shared behavior. Follow the task priorities below and fix demonstrated issues in shared controls and adjacent surfaces. Keep the existing brand and proven behaviors as the baseline.

## Experience model: roles, jobs, and language

**Reviewed:** 2026-10-14. **Evidence status:** repo-supported workflows and maintainer feedback; no adopter interview or usage study is claimed by this model. Stable IDs make the model easy to reference from a phase without copying persona prose into every plan.

### Current task priorities

**Maintainer direction, 2026-10-14:** establish a usable baseline for content, information hierarchy, controls, and visual consistency within the existing brand. A future brand refresh is separate work. Trying and inspecting search is a primary everyday task, not merely an optional destination after recovery. Failures still deserve immediate attention when present. This supersedes the earlier incident-recovery-first review order; it does not establish measured adopter frequency or change operational guarantees.

Use three concrete browser tasks to orient the existing job model: try a query and understand its results (`JOB-05`); understand a problem and reach the appropriate recovery/check (`JOB-03`/`JOB-04`); save and rerun useful search inputs (`JOB-05`). `JOB-01`/`JOB-02` remain the setup and consistency context for those tasks. Do not invent new personas or duplicate the job table for this baseline. Maintainer corrections to these tasks are useful; a persona workshop or human UAT is not a prerequisite for routine repairs.

See [UI-BASELINE-PLAN.md](UI-BASELINE-PLAN.md) for the bounded repair sequence, behavioral benchmarks, and observable finish criteria. That plan is a delivery checklist, not another persona or terminology authority.

### Task contexts

| ID | Context | What this person is trying to do | Evidence boundary |
| --- | --- | --- | --- |
| `ROLE-INT` | Ecto/Phoenix integrator | Add search to an existing schema and host app with a small, understandable setup. | Core product direction and shipped API/examples; relative adopter priority is not measured here. |
| `ROLE-OPS` | Operator or on-call engineer | Determine whether search is usable, inspect failed work, and choose a safe recovery step. | Existing optional ScrypathOps workflows and maintainer feedback; role frequency is unknown. |
| `ROLE-OWNER` | Search/index owner | Check a search or index change, inspect results by target, and preserve a useful bounded check. | Existing Search/Playbooks capabilities and approved UI scope; actual workflow frequency is unvalidated. |

These are contexts, not mutually exclusive people. A library maintainer is a contributor/support stakeholder, not automatically an end-user persona. “First run” is a setup state that can affect any role, not a separate invented demographic.

### Jobs to evaluate

| ID | When… | Help me… | So I can… | Done means… |
| --- | --- | --- | --- | --- |
| `JOB-01` | I am adding search to an existing Ecto schema. | Declare what is indexed and connect it to my Phoenix context. | Ship search without adopting a second application model. | I can identify the minimum setup and see a record returned through the supported search path. |
| `JOB-02` | I am choosing how writes reach the search index. | Select inline, Oban-backed, or manual sync and understand its consistency and delete/backfill implications. | Choose an operational tradeoff deliberately. | I can state what is accepted, what may still be pending, and how visibility will be checked. |
| `JOB-03` | Search looks unhealthy or sync work fails. | Identify the affected schema/work, inspect the evidence, and take an eligible bounded recovery action. | Restore service without losing failure history or retrying the wrong work. | The exact work is correlated and the post-recovery check reports observed visibility or an honest unknown. |
| `JOB-04` | I am changing index settings or promoting an index. | Compare the declared/live settings and verify the active index's document visibility. | Avoid treating configuration agreement as proof that users can search the expected records. | Fresh evidence names the selected schema/index and separates settings, task outcome, and document visibility. |
| `JOB-05` | I need to investigate or preserve a search behavior. | Run a bounded query against explicit targets, inspect per-target results, and save/replay the check when useful. | Compare behavior without implying separate indexes are one merged index. | The query, targets, result provenance, and saved/executed state remain distinguishable. |

These jobs describe product intent, not proof of demand. Direct maintainer feedback is evidence about the reported experience only; code/tests prove supported behavior, not that the model is complete or that adopters prioritize it.

### Internal concepts and user-facing language

Translate from the implementation model into the user's task while preserving distinctions that affect a decision. Do not rename public APIs, internal types, or domain concepts merely to make every screen sound nontechnical. Scrypath's audience includes working Elixir/Phoenix engineers; precise technical terms are appropriate when they identify the object the user must act on.

| Internal concept | User-facing starting term | Keep this distinction explicit |
| --- | --- | --- |
| Oban `Job` / queued sync work | **Queue job** or **sync work** | It is work in the host application's queue. Do not call it a Meilisearch task. |
| Meilisearch task UID | **Meilisearch task** in the supported v1 UI; **backend task** in implementation-neutral context | Acceptance is not completion; retain the task ID until an exact terminal result is observed. |
| Ecto schema / module | **Schema**, with its readable module name available in diagnostic context | Do not erase schema scope behind a vague “collection” label; the selected schema controls evidence and recovery. |
| Declared/live index settings comparison | **Index settings** in the primary path; **contract** may remain in advanced detail | Matching settings do not prove documents are fresh or visible. |
| Active-index document check | **Documents visible in the active index** / **Check document visibility** | State the selected schema/index and observation time; do not infer visibility from queue or settings status. |
| Saved Playbook JSON | **Saved search** is the 2026-10-14 recommended UI term; **Playbook** remains the API/file-format name | A saved definition can contain multiple schema/query entries. It is not a stored result, pass/fail test, scheduled job or completed run. Preserve draft, saved, and run provenance; align nav and headings when implementing the change. |
| `playbook_workspace_dir` | **Storage folder** in details or configuration/error guidance | This is a server-side directory for saved JSON files, not a separate team/account concept. Preserve scope and exact path where actionable. |
| Schema allowlist | **Configured schemas** in ordinary task guidance | Keep authorization/allowlist policy explicit in setup or access errors when it changes what the user can do; enforcement is unchanged. |
| `sync_mode: :oban` | **Background sync · Oban**, with inline/manual context when relevant | This describes the write path, not completion or freshness. Keep exact configured mode available in technical detail. |
| Multi-schema/federated search | **Search across selected schemas** when orienting a new user; keep per-schema detail | Per-target results remain separate; do not promise a merged index or combined relevance score. |
| Search result hydration from the app Repo | **Load matching Ecto records from the app** in explanatory docs | It is an app-side lookup after search, not a Meilisearch operation; preserve failure/consistency semantics. |

This is a decision aid, not a blind find/replace glossary. For each new or changed screen, ask whether the person needs the internal term to choose an action. If yes, keep it and define it briefly; otherwise lead with the task or observed outcome and retain exact technical evidence in context. Add a mapping only when real copy or a repeated misunderstanding demonstrates a need.

### Keeping the model current

- Review only the role/job rows touched when a new UI phase, API/workflow change, repeated support issue, adopter report, or maintainer feedback invalidates an assumption. Do not schedule a recurring persona-gardening ceremony.
- Record the observation source and date beside any adopted change. Keep “maintainer hypothesis,” “repository capability,” and “adopter-validated” evidence distinct; never promote one category into another by repetition.
- Revise or retire stable IDs explicitly when the job changes; do not silently repurpose an ID. Keep the model small and remove roles/jobs that no longer guide a real decision.
- Each frontend `UI-SPEC.md` should name the relevant `ROLE-*` and `JOB-*` IDs, the user's trigger, the decision/outcome the interface supports, the exact states that can change the copy, and the evidence used. A role/JTBD match is not a visual-quality pass.
- Review copy for task fit, accuracy, consistency, accessibility, and actual state provenance. The installed UX-writing skill is an editorial aid; its generic word-count, reading-grade, and comprehension figures are heuristics, not Scrypath acceptance thresholds.

## Design rules

| Area | Default |
| --- | --- |
| Hierarchy | Put the current state, affected object, and next safe action before secondary explanation. One clear page heading; meaningful section headings. |
| Layout | Choose the component for the information: lists/cards for rich records, definition lists for object facts, tables for genuine comparisons. Choose columns from available content width. Do not shrink text to fit a grid. |
| Responsive behavior | Design the task at narrow widths first, then use wider space where it improves scanning. Keep primary controls visible and reachable. Long identifiers must wrap or have an explicit accessible scroll/copy affordance; no page-wide overflow. |
| Typography | Use named roles from the shared system. Body/action labels must remain readable; small metadata is secondary. Preserve hierarchy rather than applying a global size increase. |
| Tokens | One documented authority for typography, spacing, padding, colors, radii, shadows, motion, and layering. Extend shared components before adding nearly identical screen-specific variants. |
| Controls | Use native semantics, visible labels, help/error associations, selected/disabled/busy states, visible focus, and complete dialog focus/dismissal behavior. |
| Disclosure | Keep frequent actions visible. Remove redundant or low-value content before adding a disclosure. Collapse evidence or uncommon options only when it reduces total task effort; a row of repeated disclosures can itself be noise. Consider one shared display preference for a repeated presentation choice. Do not hide every action in a menu. Maintainer feedback, 2026-10-14. |
| Copy | Use concise domain nouns and verb–object actions. Distinguish schema, index, queue job, backend task, check, and saved playbook. Distinguish queued/accepted/running/completed/failed/unknown. Avoid marketing language, repeated instructions, implementation narration, and raw API/path lists in the primary flow. |
| Operational truth | A successful retry can coexist with retained failure history. A task acceptance is not task completion, and a clean settings contract is not proof of document freshness. Never force a green aggregate to manufacture a success story. |
| States | Cover populated, empty, setup-missing, loading, error, partial, disabled, stale, long-content, zero/one/many, and keyboard/mobile cases where applicable. |

## Motion reference

Whenever considering or reviewing UI animation or micro-interactions, cross-reference [Emil Kowalski's design-engineering work](https://emilkowal.ski/skill) and the [emilkowalski/skills collection](https://github.com/emilkowalski/skills). Use it to sharpen decisions about whether motion helps, its timing, and how it responds to interruption; keep Scrypath's infrastructural motion style, shared tokens, and reduced-motion support as the implementation contract.

## Efficient verification and change control

The executable pilot and required agent review loop are documented in [`examples/scrypath_ecommerce/e2e/UI-REVIEW.md`](../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md). Start with the whole screen/journey inventory; maintainer examples are regression checks, not the review's boundary. Review unreported problems explicitly before repairing. The capture command produces pending evidence, never automatic aesthetic acceptance.

1. Capture current rendering and establish a named user problem before changing a pattern. Preserve useful existing behavior and tests; do not repeat completed palette/brand work without an invalidator.
2. Use existing LiveView checks for state boundaries, fast token/contrast checks for shared styles, and browser tests for actual navigation, focus, geometry, and real service seams. Exercise changed inputs through rendered forms or controls in the same plan; direct handler calls alone cannot prove event wiring. Cross-screen tests must change the selected schema before handing off, not only enter a non-first schema directly.
3. Use a small representative matrix in the existing CI lanes. Keep the full screenshot/contrast matrix advisory. Report actual coverage rather than treating screenshot existence or a filename check as visual parity.
4. Inspect before/after screenshots in the active agent session. No paid visual-judge API calls, new AI service, or recurring model gate by default. Never auto-update a pixel baseline merely to clear a failure.
5. User feedback is design direction, not a substitute for acceptance tests. Escalate only an actual unresolved product/risk choice or external permission; record the reason.
6. Record completed findings, evidence, source identity, remaining limits, and explicit revisit triggers. Later milestones reopen only changed or invalidated claims.
7. During integration debugging, retain only the task-owned disposable stack and reload changed source without reseeding the feedback preview. Preserve first failures, use bounded action timeouts, and rerun the focused cases. Finish with the canonical fresh-stack command at committed source; repeated full image rebuilds are not the inner feedback loop.

8. Measure the generated CSS rather than assuming a token-like class exists. Check CSS layer precedence when a repair has no effect.
9. Modal focus must survive real LiveView patches and object rename/delete; use stable object IDs and a reachable successor. Keep validation errors inside the active dialog's accessibility tree.
10. Distinguish observation failure from remote operation failure. Only exact terminal evidence supports completed/failed copy; unknown outcomes retain accepted task identity.

## Clean finish

Use PR-first delivery and the existing required checks. Keep planning records and source evidence distinct without freezing completion bookkeeping. Leave task-owned files committed, generated artifacts outside tracked source, and temporary verification services removed. A preview intentionally retained for maintainer feedback has a documented URL, owner, and stop command. Preserve unrelated worktrees and stashes. Decide whether a release is warranted from the delivered package changes; never bump a version merely to close a planning milestone.

Current evidence/inventory: `research/v1.42/UI-SYSTEM.md`, `UI-STRUCTURE.md`, and `UI-AUTOMATION.md`.
