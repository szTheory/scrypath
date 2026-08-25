---
quick_id: 260816-thg
phase: quick-260816-thg-rewrite-ops-ui-microcopy-around-operator
plan: 01
type: execute
wave: 1
depends_on: []
description: Rewrite Ops UI microcopy around operator JTBD
status: ready
created: 2026-08-16
autonomous: true
files_modified:
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
  - .planning/todos/pending/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md
  - .planning/todos/completed/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md
  - .planning/STATE.md
must_haves:
  truths:
    - "An operator can scan Control Room, Search, Sync/Drift, and Playbooks and understand the job and next action without translating backend implementation jargon."
    - "Precise operational terms remain where they communicate a real constraint, state, or recovery decision."
    - "Routes, events, controls, status meanings, safety warnings, and runtime behavior do not change."
  artifacts:
    - path: "scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex"
      provides: "Job-first landing and intent-card copy"
    - path: "scrypath_ops/lib/scrypath_ops_web/live/search_live.ex"
      provides: "Task-oriented search exploration and result copy"
    - path: "scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex"
      provides: "Operator-readable promotion and recovery copy"
    - path: "scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex"
      provides: "Task-oriented saved-check workflow copy"
  key_links:
    - from: "the four LiveView source files"
      to: "their four focused LiveView test files"
      via: "visible-text assertions that lock the operator-facing wording and stable workflow"
---

# Quick Task 260816-thg: Rewrite Ops UI Microcopy Around Operator JTBD

<objective>
Rewrite the primary scan-path copy across Control Room, Search, Sync/Drift, and Playbooks so it leads with the operator's job, decision, and next action.

Purpose: Remove unnecessary backend/library translation work while retaining Scrypath's calm, exact voice and its operational honesty about limits, drift, federation, safety, and promotion.
Output: Copy-only LiveView edits, focused wording contracts, and completed quick-task bookkeeping.
</objective>

<context>
@.planning/STATE.md
@.planning/todos/pending/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md
@prompts/scrypath-brand-book.md
@prompts/search-lib-use-cases-deep-research.md
@prompts/phoenix-live-view-best-practices-deep-research.md
@scrypath_ops/AGENTS.md
@scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
@scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
@scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
@scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
@scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
@scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
@scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
@scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Rewrite the four operator scan paths and lock the new wording</name>
  <files>scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex, scrypath_ops/lib/scrypath_ops_web/live/search_live.ex, scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex, scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex, scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs, scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs, scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs, scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs</files>
  <behavior>
    - Control Room states the three operator jobs in outcome language: recover search, verify a change before promotion, and inspect/save a useful search check.
    - Search tells the operator to choose an index, run a query, inspect the answer, and save a repeatable check; implementation terms appear only in constraint/evidence regions where they are accurate and useful.
    - Sync/Drift explains the promotion sequence in decision language while retaining the exact distinctions among reconcile state, declared-versus-live contract drift, mismatches, and the gated index swap.
    - Playbooks describes saved, repeatable search checks and makes preview/run/import/save next actions obvious without changing their behavior.
    - Existing non-production, PII/secrets, allowlist, page-size/index-cap, read-only, and destructive-action warnings keep their operational meaning.
  </behavior>
  <action>Begin by updating or adding focused visible-text assertions for each screen, then rewrite the operator-facing page subtitles, intent summaries, section introductions, helper sentences, empty states, error recovery guidance, and action labels they cover. Use short sentence-case copy in Scrypath's calm, precise voice. Lead with what the operator is trying to learn or accomplish; retain terms such as schema, federation, bounded limits, reconcile, contract drift, and gated swap only when they identify a concrete object, constraint, evidence state, or irreversible promotion step. In particular, replace the QA-called-out implementation-led Search and Control Room explanations with direct job language. Keep page titles and established navigation vocabulary stable unless a focused test proves a label is local helper copy rather than IA. Do not change routes, event names, assigns, component structure, conditional rendering, async/deferred reads, backend calls, authorization, or status calculations. Update only assertions affected by the copy and add one positive operator-job assertion per screen; keep tests focused on user-visible behavior rather than full rendered snapshots.</action>
  <verify>
    <automated>cd scrypath_ops &amp;&amp; mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/live/search_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops_web/live/playbook_live_test.exs</automated>
  </verify>
  <done>All four screens use concise operator-job language across their primary scan paths, technical terms remain only where operationally informative, safety/cap disclosures remain truthful, and focused LiveView tests pass with explicit wording coverage for every screen.</done>
</task>

<task type="auto">
  <name>Task 2: Run the Ops UI gate and close the pending todo</name>
  <files>.planning/todos/pending/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md, .planning/todos/completed/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md, .planning/STATE.md</files>
  <action>Run the repository's ScrypathOps verification gate after the copy and focused tests are green. Review the final diff to confirm it contains only copy, wording assertions, and normal quick-task bookkeeping. After successful verification, move the canonical todo from pending to completed without changing its original problem/solution text, add completion metadata in the same style as neighboring completed todos, and update the STATE Todos entry from pending to completed. Do not alter archived milestone truth or reopen a milestone.</action>
  <verify>
    <automated>mix verify.opsui &amp;&amp; test -f .planning/todos/completed/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md &amp;&amp; test ! -e .planning/todos/pending/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md</automated>
  </verify>
  <done>The full Ops UI gate passes, the diff contains no behavior or layout change, the todo is recoverably represented in completed history, and STATE still reports the release train as idle.</done>
</task>

</tasks>

<threat_model>
## Trust boundaries

No trust boundary changes. The copy pass must preserve the existing non-production, sensitive-data, allowlist/cap, read-only, authentication, and destructive-action disclosures.

## STRIDE register

| Threat ID | Category | Component | Severity | Disposition | Mitigation plan |
|---|---|---|---|---|---|
| T-quick-copy-01 | Information disclosure | Search and Playbooks safety notices | medium | mitigate | Keep explicit warnings against production secrets/PII and preserve configured query/index caps while simplifying surrounding prose. |
| T-quick-copy-02 | Tampering / Elevation of privilege | Sync/Drift promotion and Playbooks destructive actions | high | mitigate | Preserve gated-swap, sudo/auth, confirmation, and irreversible-action wording; do not alter handlers or authorization logic. |
</threat_model>

<verification>
Focused tests prove each new scan path; `mix verify.opsui` proves the complete optional Phoenix operator application remains green. Final diff inspection confirms the task is copy-only except for wording contracts and quick-task state bookkeeping.
</verification>

<success_criteria>
- The two QA-called-out implementation-led explanations no longer appear in rendered scan-path copy.
- Each surface tells the operator what to check or do before explaining implementation detail.
- Operationally necessary vocabulary and all safety/constraint disclosures remain accurate.
- No route, handler, assign, component, layout, status computation, or runtime behavior changes.
- Focused LiveView tests and `mix verify.opsui` pass.
</success_criteria>

## Source coverage audit

| Source | ID | Feature / constraint | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Rewrite Ops UI microcopy around operator JTBD | Task 1 | COVERED | All four named scan paths are included. |
| REQ | — | No roadmap requirement IDs; this is an idle-release-train quick follow-up | Task 2 | COVERED | Quick-task bookkeeping preserves idle milestone state. |
| RESEARCH | — | Calm, exact, task-oriented voice with operational honesty | Task 1 | COVERED | Brand and search-library operator vocabulary constrain the rewrite. |
| RESEARCH | — | Assert user-observable LiveView outcomes rather than implementation details | Task 1 | COVERED | Focused visible-text tests lock the wording. |
| CONTEXT | — | Copy-only; retain precise terms only when they clarify real constraints | Task 1 | COVERED | Runtime and UI structure are explicitly out of bounds. |
| CONTEXT | — | Close/move pending todo only through normal verified quick-task bookkeeping | Task 2 | COVERED | Move occurs only after the Ops UI gate succeeds. |
