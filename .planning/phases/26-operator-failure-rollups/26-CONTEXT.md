# Phase 26: Operator failure rollups - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose **rollup counts** grouped by `reason_class` for operator triage on the failed-sync inspection path, consistent with underlying `%Scrypath.Operator.FailedWork{}` rows and **Phase 22** classification discipline. **No new recovery verbs**; **additive** API and structs only; **`%FailedWork{}` `@enforce_keys` unchanged**. Satisfies **OPS14-01** and roadmap Phase 26 success criteria (documented API or Mix output + tests that lock shape and unknown-class honesty).

</domain>

<decisions>
## Implementation Decisions

### Single aggregator (DRY)

- **D-01:** Implement **one pure function** from `[FailedWork.t()]` to the rollup carrier (e.g. `FailedWork.reason_class_counts/1` or nested module — exact name is planner discretion). **Every** consumer (`failed_sync_work/2` opt-in path, `%Reconcile{}`, Mix renderers) uses this on the **exact same list** that is attached to the response/report. If `failed_work` is ever filtered for a view, rollups MUST be computed from that **post-filter** list; document the invariant in `@moduledoc`.

### Public API (`failed_sync_work/2`) — fold into existing entry point

- **D-02:** **Do not** add a separate top-level summary function as the primary design (e.g. no `failed_sync_work_summary/2` as the main story) — **`.planning/research/FEATURES.md`** explicitly prefers folding rollups into the **existing** return path, not a second summary API.
- **D-03:** **Default unchanged:** `Scrypath.failed_sync_work/2` continues to return `{:ok, [FailedWork.t()]}` when no rollup option is passed — preserves all existing `with {:ok, rows} <- ...` callers.
- **D-04:** **Opt-in enriched return** via a keyword (exact key left to planner; align with research **OPERATOR_POLISH.md** OPS-10 sketch: e.g. `rollup: true` or `include: :reason_class_counts`). When enabled, return `{:ok, %FailedSyncWorkInspection{entries: [FailedWork.t()], counts: %ReasonClassCounts{}}}` — **names illustrative**; planner picks final module/struct names under `Scrypath.Operator` or `Scrypath` per existing conventions.
- **D-05:** Enriched branch uses a **named public struct** for the wrapper and for counts (not a bare map) — better ExDoc, `Inspect`, optional `Jason.Encoder`, and Dialyzer-friendly `@spec` union with the list-only branch.

### Rollup carrier shape (`%ReasonClassCounts{}` or equivalent)

- **D-06:** **Dense contract:** `by_class` (or equivalent field) is a map with **all five** `FailedWork.reason_class()` atoms as keys, each a **non_neg_integer** (zeros explicit). Prevents silent “missing key” from being misread as zero pileup in a different class.
- **D-07:** Include **`total`** (sum of counts == length of contributing rows for the default rollup-over-full-list case; if rollups are ever over a filtered list, `total` must match that list’s length).
- **D-08:** Include a small **`version`** integer (e.g. `1`) on the counts struct for forward evolution of JSON/docs without breaking silent decode assumptions.
- **D-09:** **Canonical ordering:** store or document **`by_class`** in **fixed taxonomy order** (same order as Phase 22 docs). Optional **derived** helper for “sort by count descending” for CLI samples only — not the only canonical shape.
- **D-10:** **No silent `:other` bucket** for values that should map to a known class. If a future need arises for unknown string classes, add an explicit **`extras`** (or similar) **in addition to** the five keys, with tests; do not lump unknown classifier outputs into a misleading bucket without a semver + type change.

### `%Reconcile{}` parity

- **D-11:** Add an **additive** field on `%Scrypath.Operator.Reconcile{}` (e.g. `failed_work_counts: %ReasonClassCounts{}`) computed via **D-01** from **`failed_work`** as assembled in `Reconcile.run/3`. Keeps **report-first** triage: one `reconcile_sync/2` snapshot shows drift signals **and** failure pileup shape.
- **D-12:** **`failed_sync_work/2` opt-in** remains required for **OPS14-01** wording (“`failed_sync_work/2` or documented operator entry point”); reconcile field satisfies operators who only run reconcile, without duplicating fetch logic (same `FailedWork.list/3` source today).

### Mix tasks and CLI

- **D-13:** **`mix scrypath.failed`:** Default human output: after header, when failed count **> 0**, print a **compact rollup block** (same counts as API) **before** per-row lines so it stays visible above long lists. Add **`reason_class`** (or stable short token `class=`) **on each row** — aligns with `%FailedWork{}` and telemetry story.
- **D-14:** Add **`--json`** (boolean), consistent with **`mix scrypath.settings.diff`** — single JSON document to stdout; **no** interleaved `Mix.shell().info` lines on the JSON path.
- **D-15:** Optional **`--no-class-summary`** (or equivalent) to suppress **only** the rollup block for rare pipe/grep workflows — do not hide per-row `reason_class` by default (bounded token).
- **D-16:** **`mix scrypath.reconcile`:** Extend human render to include the **same** rollup summary (counts) so SSH operators see pileup shape without a second command.

### Tests (roadmap success criteria)

- **D-17:** Tests assert **exhaustive keys** on `by_class` match the known `reason_class` set; **`sum(values) == total`**; rollup counts match **`Enum.frequencies_by(& &1.reason_class, rows)`** (or equivalent) for fixture rows.
- **D-18:** Include at least one test that proves **unknown / future class** cannot be silently dropped into a wrong bucket without changing the public type set — align with Phase 22 “default `:unknown`” honesty.

### Claude's Discretion

- Exact keyword atom for opt-in (`:rollup`, `:include`, etc.) after a quick grep for collisions in `Scrypath` public opts.
- Final struct names (`FailedSyncWorkInspection`, `ReasonClassCounts`, nesting under `Operator` vs top-level `Scrypath`).
- Whether `Jason.Encoder` is derived on counts only or also on the inspection wrapper.
- Exact CLI token spelling (`reason_class=` vs `class=`).

### Folded Todos

None — `gsd-sdk query todo.match-phase` was unavailable during discuss-phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — § Phase 26: Operator failure rollups; goal; success criteria; non-goals
- `.planning/milestones/v1.4-REQUIREMENTS.md` — **OPS14-01**; traceability table
- `.planning/PROJECT.md` — v1.4 milestone; operator rollup bullet

### Prior phase and research

- `.planning/phases/22-operator-polish-drift-recovery-guide/22-CONTEXT.md` — `reason_class` taxonomy, telemetry, classifier discipline, no `@enforce_keys` changes
- `.planning/research/deep/OPERATOR_POLISH.md` — OPS-10 optional rollup sketch (`rollup:` + entries); no new recovery verbs
- `.planning/research/FEATURES.md` — failure-class rollup folded into `failed_sync_work/2`, not separate summary API
- `.planning/research/PITFALLS.md` — operator surface must not become a dashboard; no invented recovery APIs

### Code touchpoints

- `lib/scrypath/operator/failed_work.ex` — list pipeline, `reason_class` per row
- `lib/scrypath/operator.ex` — `failed_sync_work/2`
- `lib/scrypath.ex` — public delegate and `@spec`
- `lib/scrypath/operator/reconcile.ex` — `%Reconcile{}`, `run/3`
- `lib/scrypath/cli/operator_task.ex` — `render_failed_work/2`, `render_reconcile_report/1`, parse patterns
- `lib/mix/tasks/scrypath.failed.ex` — task entry
- `guides/operator-mix-tasks.md` — document default sections, `--json`, CHANGELOG-worthy line format changes
- `guides/drift-recovery.md` — cross-links if failure triage prose should mention rollups

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- `%FailedWork{}` already carries **`reason_class`** for every constructed row; classification is centralized in `FailedWork`.
- `FailedWork.list/3` is shared by **`Operator.failed_sync_work/2`** and **`Reconcile.run/3`** — single fetch path today.

### Established patterns

- Operator Mix tasks delegate to **`Scrypath.*`** APIs and use **`OperatorTask`** for argv, `render_*`, and **`--json`** on settings diff.
- Additive struct fields **outside** `@enforce_keys` match v1.3/v1.4 evolution for operator types.

### Integration points

- `@spec` and docs on **`Scrypath.failed_sync_work/2`**; reconcile struct `@type`; ExDoc sections for operator visibility.

</code_context>

<specifics>
## Specific Ideas

Research synthesis (subagent + maintainer session, 2026-04-17): prefer **opt-in on `failed_sync_work/2`** over a second summary function; **dense five-key counts struct**; **default Mix output** shows rollup + per-row class; **`--json`** for machines; **reconcile** includes the same counts for report-first DX.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 26 scope.

</deferred>

---

*Phase: 26-operator-failure-rollups*
*Context gathered: 2026-04-17*
