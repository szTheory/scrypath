# Phase 25: Settings hot apply (narrow) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can patch **only** `synonyms`, `stop_words`, and `typo_tolerance` on a **live** Meilisearch index when a full managed reindex is too heavy, with **explicit errors** for unsupported keys and **no silent remote mutation** when validation fails. Documentation must contrast **`hot_apply/3`** vs managed **`Scrypath.reindex/2`**, including non-goals (e.g. no `ranking_rules` or other keys on the hot path in v1.4). Satisfies **TUNE14-01** and **TUNE14-02**; depends on Phase **24** release baseline.

</domain>

<decisions>
## Implementation Decisions

### Live-index safety gate

- **D-01:** Require **`acknowledge_live_index: true`** in the options keyword passed to `Scrypath.Meilisearch.Settings.hot_apply/3`, in **addition** to the allow-listed settings payload. The allowlist answers *what* may be PATCHed; the flag answers *intent to mutate the live index now*. If absent, return a stable tagged error (e.g. `{:error, :live_ack_required}`) — pick one atom and keep it as a public contract.
- **D-02:** Rationale: least surprise vs treating any settings-shaped map as authorization; grep-able call sites; aligns with Scrypath’s “managed reindex is primary” story and Elixir’s pattern of explicit opts when widening behavior beyond the default safe pipeline.

### Error taxonomy and validation order

- **D-03:** Public contract remains **`{:ok, term()} | {:error, term()}`** — no exceptions for normal unsupported-key or transport/backend failure paths.
- **D-04:** **Validate before any HTTP.** If any disallowed top-level keys are present, return **`{:error, {:unsupported_hot_apply_keys, keys}}`** where `keys` lists **all** invalid keys in one response (sorted/deduped for stable output), mirroring the “full list” honesty of `{:settings_drift, drift}` from `verify_applied/3`.
- **D-05:** For failures after validation (PATCH, task wait, Meilisearch error JSON, transport), return a **single second shape** such as **`{:error, {:hot_apply_failed, details}}`**, where `details` carries normalized backend info when available (`code`, `message`, task UID) without coupling callers to raw Meilisearch JSON shape long-term.
- **D-06:** Defer introducing a cross-cutting `%Scrypath.Error{}` struct for this phase unless the planner finds unavoidable collision with existing error patterns — prefer tagged tuples consistent with settings drift and other library surfaces.

### Operator entry points (API vs Mix)

- **D-07:** Implement **`Settings.hot_apply/3`** (or the exact module/fn name locked in plan) as the **single source of truth** — unit tests, integration tests, Oban jobs, and **`release eval`** must call this API.
- **D-08:** Add a **thin** **`mix scrypath.settings.hot_apply`** (name may be adjusted in plan for consistency with `scrypath.settings.read` / `scrypath.settings.diff`) that resolves repo config the same way as sibling tasks, requires an explicit CLI acknowledgement flag (**`--ack-live`** or equivalent) mapping to **D-01**, delegates to the API, and prints a human-clear outcome (and task UID when relevant).
- **D-09:** Document **`bin/<release> eval '…'`** examples for production nodes where Mix is unavailable — same API, no second implementation path.

### Post-PATCH verification

- **D-10:** **Default:** after a successful PATCH + **settings task success** (wait until the task the API enqueues reaches succeeded — same discipline as other mutating Meilisearch calls), **do not** invoke today’s **full** `verify_applied/3` automatically. Full verify compares **entire** `resolve → translate` to GET and can report **false drift** after a partial hot update when the live index legitimately differs on keys the hot path did not touch.
- **D-11:** **Optional (same phase if small, else follow-on):** a **`verify: :subset`** or **`only: [:synonyms, :stop_words, :typo_tolerance]`** (exact API spelling left to planner) that GETs and compares **only** allow-listed keys — never treat full `verify_applied/3` as the default postcondition for `hot_apply`.
- **D-12:** **TUNE14-02** docs must state explicitly: proof of full declared-vs-applied parity remains **`mix scrypath.settings.diff`** / managed **`reindex/2`** with verification; **`hot_apply`** is a bounded relief path optimized for latency and honest semantics.

### Telemetry

- **D-13:** Emit telemetry on hot apply success and failure (e.g. under **`[:scrypath, :settings, :hot_apply, ...]`** or aligned with existing `[:scrypath, :reindex, ...]` naming — planner to match codebase conventions) including **index**, **schema module**, **which allow-listed families were touched**, and **outcome**. Exact metadata shape is Claude’s discretion within existing span conventions.

### Claude's Discretion

- Exact atom names for **D-01** / **D-05** if a quick audit finds near-collisions with existing error atoms.
- **`{:ok, ...}`** success payload shape (minimal map vs task struct) — align with other settings/task-returning functions in `Scrypath.Meilisearch.Client` / task helpers.
- CLI flag spelling beyond **`--ack-live`** if a clearer name fits existing Mix task style.
- Whether **D-11** ships in Phase 25 or is deferred to a micro-follow-up — default defer if schedule-tight; **D-10** is mandatory for v1.4 hot path correctness story.

### Folded Todos

None — automated `todo.match-phase` was unavailable during discuss-phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — § Phase 25: Settings hot apply (narrow); goal, success criteria, **TUNE14-01..02**
- `.planning/milestones/v1.4-REQUIREMENTS.md` — § Relevance — hot apply (prefix: TUNE14); **TUNE14-01**, **TUNE14-02**; § Out of Scope (v1.4) (ranking_rules and broader hot apply explicitly out)
- `.planning/PROJECT.md` — Core value, constraints, current milestone v1.4 narrative

### Prior phase decisions (carry-forward)

- `.planning/phases/19-relevance-tuning/19-CONTEXT.md` — managed settings pipeline, `verify_applied/3`, `hot_apply/3` stub contract, normalize/translate/drift patterns
- `.planning/phases/24-public-hex-release-parity-gates/24-CONTEXT.md` — Hex **0.3.1** / release baseline this phase assumes merged

### Implementation touchpoints

- `lib/scrypath/meilisearch/settings.ex` — stub `hot_apply/3`, `resolve/2`, `translate_settings/1`, `verify_applied/3`
- `lib/scrypath/meilisearch/client.ex` — `update_settings/3` (PATCH), `get_settings/2`, task helpers as used elsewhere
- `lib/mix/tasks/scrypath.settings.diff.ex` — operator task patterns (`--repo`, `--index-prefix`, exit codes, delegates)
- `lib/mix/tasks/scrypath.settings.read.ex` — config resolution pattern for sibling tasks
- `guides/relevance-tuning.md` — extend per **TUNE14-02** with hot vs managed table and non-goals

### External

- [Meilisearch settings API](https://www.meilisearch.com/docs/reference/api/settings) — PATCH behavior, async tasks
- [Meilisearch error codes](https://www.meilisearch.com/docs/reference/errors/error_codes) — normalize **D-05** `details` where applicable

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.Meilisearch.Client.update_settings/3`** — already PATCHes `/indexes/{uid}/settings`; hot apply should reuse rather than duplicate HTTP.
- **`Settings.resolve/2`**, **`translate_settings/1`**, **`normalize`** pipeline — reuse for wire correctness; do not fork camelCase / `__unrecognized__` rules for the three allow-listed families.
- **`mix scrypath.settings.diff`** / **`mix scrypath.settings.read`** — CLI patterns, `Mix.Task.run("app.start")`, `--repo` / `--index-prefix`, exit code discipline.

### Established patterns

- Managed **`Scrypath.reindex/2`** owns apply + optional **`verify_applied/3`** with **`skip_settings_verification?: true`** escape — hot path should mirror “explicit escape” philosophy without copying full-verify as default.
- Results and errors use **tagged tuples** (`{:settings_drift, ...}`) for evidence-bearing failures.

### Integration points

- **`guides/relevance-tuning.md`** + **CHANGELOG** (Unreleased) for adopters discovering stub → real behavior.
- **`mix.exs`** — `preferred_envs` for any new Mix task mirroring `settings.diff` / `settings.read`.

</code_context>

<specifics>
## Specific Ideas

- Discuss-phase research (2026-04-17): explicit **`acknowledge_live_index`**, collect-all-keys error tuple, API-first + thin Mix task with **`--ack-live`**, default no full **`verify_applied`** after hot apply with optional subset verify deferred if needed.
- Cohesion: bounded hot path, operational honesty, least surprise vs implicit live PATCH and false drift from full verify after partial PATCH.

</specifics>

<deferred>
## Deferred Ideas

- **Subset-scoped verify helper** if **D-11** slips out of Phase 25 scope — capture as a small follow-on plan, not scope creep inside hot apply.
- **`%Scrypath.Error{}`**-style unified errors — library-wide concern; not Phase 25 unless planner finds hard conflict.

### Reviewed Todos (not folded)

None recorded (tooling unavailable during discuss-phase).

</deferred>

---

*Phase: 25-settings-hot-apply-narrow*
*Context gathered: 2026-04-17*
