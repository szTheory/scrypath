# Phase 28: Operator CLI, docs, and verify gate - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **OPS15-02..04** for v1.5: thin **`mix scrypath.*`** surfacing of the Phase 27 **index contract drift** report (`Scrypath.index_contract_drift/2`), optional **`--json`** consistent with existing operator tasks, updates to **`guides/drift-recovery.md`** and **`docs/operator-support.md`** so operators know when to use **contract drift** vs **`mix scrypath.settings.diff`**, **`Scrypath.reconcile_sync/2`**, and managed **`reindex/2`**, and an **auth-free** verify gate (**`mix verify.phase28`**) running focused tests plus **`mix docs --warnings-as-errors`**.

**Non-goals:** New recovery verbs; silent auto-heal; widening scope beyond OPS15-02..04; dual verify task names without an explicit deprecation story.

</domain>

<decisions>
## Implementation Decisions

### Mix task naming and surface (OPS15-02)

- **D-01:** **Dedicated** Mix task — **do not** overload **`mix scrypath.reconcile`** or fold drift reporting into reconcile flags (keeps read-only contract reporting distinct from triage/repair guidance; aligns with Phase 27 vocabulary guardrails).
- **D-02:** Task invocation: **`mix scrypath.index.contract_drift SCHEMA [opts]`**, implemented as **`Mix.Tasks.Scrypath.Index.ContractDrift`**, delegating to **`Scrypath.index_contract_drift/2`** — mirrors the existing **`mix scrypath.settings.*`** dotted-group pattern and disambiguates from settings-only drift and operational **`drift_signals`**.
- **D-03:** **`@shortdoc`** / **`@moduledoc`** / operator docs must name **`index_contract_drift/2`** explicitly so **grep** and **ExDoc** bridge CLI ↔ API in one hop (CLI string is grouped; API name stays literal).

### Exit codes and `--json` (OPS15-02)

- **D-04:** Match **`mix scrypath.settings.diff`**: exit **`0`** = comparison completed, **no** contract drift; **`2`** = comparison completed, **≥1** mismatch in any included report slice; **`1`** = could not produce a trustworthy comparison (args, missing index, network, internal error).
- **D-05:** **Same exit semantics with and without `--json`** — JSON is transport; exit code is the automation contract (avoids “CI green because `--json`” class bugs).
- **D-06:** Document **`set +e` / `$?`** branching for shell pipelines next to the task moduledoc or operator-support (same discipline as other multi-exit operator tools).

### Default human output (OPS15-02, carries Phase 27 D-08/D-09)

- **D-07:** **Sparse human path:** stable **one-line header** (schema + index identity; repo/prefix when relevant) → **only mismatch blocks** (compact bullets or small per-dimension chunks) → **1–3 line footer** (dimension summary + pointer to **`--json`** for full machine report and, where OPS15-03 fits, pointers to **`settings.diff` / reconcile / reindex`** without implying new verbs).
- **D-08:** **Explicit parity line** on success (e.g. index contract OK) — never rely on empty stdout as the only success signal.
- **D-09:** **No pager by default**; **ANSI only on TTY**; respect **`NO_COLOR`** if coloring is used; prefer human diagnostics on **stderr** if piping ambiguity appears.

### Verify gate (OPS15-04)

- **D-10:** Canonical gate name: **`mix verify.phase28`** (single task; no dual **`phase27` + `phase28`** unless a short documented deprecation). Renumbering is explicitly allowed by OPS15-04 (“next free phase slot”); aligns roadmap phase, requirement wording, and Mix module naming with the rest of **`verify.phaseN`** in-repo.

### Operator docs split (OPS15-03)

- **D-11:** **`guides/drift-recovery.md`** — symptom-oriented runbooks: **when** to run contract drift vs queue/settings symptoms; **minimal duplication** of `operator-support` “first response” ordering — cross-link instead of pasting parallel matrices.
- **D-12:** **`docs/operator-support.md`** — maintainer **first response** list: where **`index.contract_drift`** fits relative to **`status` / `failed` / `reconcile` / `settings.diff`**; update **`mix verify.*`** bullet to cite **`verify.phase28`** as the v1.5 operator/doc contract gate (replace stale **`phase14`**-only framing where Phase 28 supersedes for this milestone slice — exact wording left to planner to avoid unrelated churn).

### Claude's Discretion

- Exact formatting of mismatch blocks (bullets vs unified-diff-style) and whether a **`--verbose`** flag exists later for power users.
- Precise test file list inside **`verify.phase28`** beyond the minimum: index contract drift tests, any doc contract tests, and **`mix docs --warnings-as-errors`** — planner sizes to keep the gate fast and auth-free.

### Folded Todos

None.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — OPS15-02, OPS15-03, OPS15-04; out-of-scope table; traceability
- `.planning/ROADMAP.md` — Phase 28 row; v1.5 goals
- `.planning/PROJECT.md` — v1.5 operator drift milestone; report-first posture

### Prior phase (report API and JSON rules)

- `.planning/phases/027-schema-index-drift-report/027-CONTEXT.md` — Phase 27 decisions D-07..D-14 (structs, JSON explicitness, `compute_drift` reuse, human vs JSON density); Phase 28 boundary callout

### Code (patterns to mirror)

- `lib/mix/tasks/scrypath.settings.diff.ex` — **`--json`**, **`OperatorTask`**, **`--repo` / `--index-prefix`**, exit **0 / 2 / 1**
- `lib/scrypath.ex` — **`index_contract_drift/2`** public delegate
- `lib/scrypath/operator/index_contract_drift.ex` — builder entry
- `lib/scrypath/operator/index_contract_drift/report.ex` — **`Jason.Encoder`**, versioned report
- `lib/scrypath/cli/operator_task.ex` — argv parsing, test operator opts (if used by new task)
- `lib/mix/tasks/verify.phase26.ex` (or nearest verify task) — structure for **`mix verify.phase28`**

### Guides (edit targets for OPS15-03)

- `guides/drift-recovery.md`
- `docs/operator-support.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Mix.Tasks.Scrypath.Settings.Diff`** — template for **`--json`**, exit codes, **`OperatorTask.parse!` / `schema_from_argv!` / `runtime_opts`**, **`Mix.Task.run("app.start")`**
- **`Scrypath.index_contract_drift/2`** and **`%Scrypath.Operator.IndexContractDrift.Report{}`** — single source of truth for CLI output (encode struct for JSON path)

### Established patterns

- **Keyword switches** on operator tasks (`json: :boolean`, repo, index_prefix)
- **`OperatorTask.error!/2`** for exit-1 failures consistent with other **`scrypath.*`** tasks

### Integration points

- **`mix.exs`** aliases or docs listing (if project enumerates verify tasks)
- **`test/documents/docs_contract_test.exs`** (or equivalent) — strings that pin **`mix verify.*`** names to docs

</code_context>

<specifics>
## Specific Ideas

User chose **all four** discuss areas; parallel subagent research (Elixir/Hex idioms, Searchkick/Scout-style namespacing, Terraform-style exit buckets, kubectl/log-volume lessons). Synthesized package: **`mix scrypath.index.contract_drift`**, **0/2/1** parity/drift/error (including **`--json`**), **sparse human + explicit OK line + footer**, **`mix verify.phase28`** as sole gate with planning doc alignment.

</specifics>

<deferred>
## Deferred Ideas

- Shared snapshot builder to avoid **`settings.diff`** double-`get_settings` on drift path — only if small; else backlog (from Phase 27 deferred).

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 28-operator-cli-docs-verify-gate*
*Context gathered: 2026-04-17*
