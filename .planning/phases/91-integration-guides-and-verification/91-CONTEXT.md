# Phase 91: Integration, Guides, and Verification - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.24 by making the related-data fan-out that shipped in Phases 89–90
(`Scrypath.sync_related/3` + the internal `RelatedWorker` Oban path) the
**canonical, documented, and contract-locked** story. Three deliverables:

1. **91-01** — Rewrite `guides/related-data-and-reindexing.md` so `Scrypath.sync_related/3`
   and the built-in Oban path are the canonical recommendation, removing all
   "temporary workaround" framing.
2. **91-02** — Add `mix verify.phase91` plus docs-contract assertions that lock the
   explicit-only boundary and the new non-goals (no callback magic).
3. **91-03** — Polish the Phoenix example app (`examples/phoenix_meilisearch`) to
   exercise the new related-data sync across a real association.

**This phase ships NO new public API.** `Scrypath.sync_related/3`, the `fan_outs:`
metadata, and the `RelatedWorker` error contract are already shipped (Phases 89–90)
and are fixed inputs here. Scope is docs + a verify gate + example polish only.

**Requirements:** EXEC-02, TEST-01, TEST-02.
</domain>

<decisions>
## Implementation Decisions

### Fixed inputs carried forward from Phases 89–90 (do NOT re-litigate)
- **D-01 — Public API shape (locked):** `Scrypath.sync_related(schema_module, records, opts)`.
  `opts[:fan_out]` is **required** (raises `ArgumentError` if absent) and names a key in
  the schema's `fan_outs:` declaration. `opts[:sync_mode]` selects `:inline` (resolve +
  `sync_records` now) or `:oban` (enqueue internal `RelatedWorker`). See `lib/scrypath.ex:192`
  and `lib/scrypath/sync.ex:38`.
- **D-02 — `fan_outs:` declaration (locked):** A keyword list on the *owning* schema's
  `use Scrypath` block, each entry `target:` (the schema whose documents get re-synced) +
  `resolver:` (an `{mod, fun, extra_args}` MFA invoked as `apply(mod, fun, [records | extra_args])`,
  returning the target records to sync). Validated in `lib/scrypath/options.ex`.
- **D-03 — Oban path is config-driven, NOT a macro (locked):** The `:oban` path uses the
  internal `Scrypath.Sync.RelatedWorker`. There is **no public `use Scrypath.Oban.Worker`
  macro** — adopters never name the worker module (90-DISCUSS.md §1). Docs/example must
  reflect this: just `sync_mode: :oban, oban: [queue: …, max_attempts: …]`.
- **D-04 — Error/handoff contract (locked):** Oban path returns `{:ok, %Result{status: :accepted}}`
  on successful enqueue. `RelatedWorker.perform/1` maps fan-out failures onto Oban outcomes:
  HTTP 4xx → `{:cancel, _}` (permanent), HTTP 5xx/generic → `{:error, _}` (transient retry),
  invalid schema/fan_out → `{:cancel, {:invalid_job, reason}}` (90-01-SUMMARY.md). Docs must
  state these outcomes and the honest truth boundary ("durably queued" ≠ "searchable now").
- **D-05 — Invariant (locked):** Explicit orchestration only. No Ecto lifecycle callbacks,
  no hidden association walking, no deep preload cascade. Contexts own the fan-out decision
  and invoke it; the library owns execution. This is the boundary the verify gate must assert.

### 91-01 — Guide rewrite
- **D-06:** Replace the `### Temporary Workaround: Custom Oban Jobs` subsection
  (current `guides/related-data-and-reindexing.md` lines 82–135) with a canonical
  "fan-out with `Scrypath.sync_related/3`" section. Show: (a) the schema-side `fan_outs:`
  declaration on the owning schema (Author declaring a fan-out to Post), then (b) the
  context-side call for both `sync_mode: :inline` and `sync_mode: :oban`.
- **D-07:** Preserve the guide's existing voice — "your app owns the fan-out / no callback
  magic." Frame `sync_related/3` as *explicit orchestration the context invokes*, not a
  hidden callback. The custom-worker code (lines 88–135) is removed, not kept as an alternative.
- **D-08 (EXEC-02):** Fold the new API into the existing "Picking the right follow-up path"
  section so the inline-vs-Oban choice maps explicitly to **blast radius + request latency**:
  small/bounded + latency-tolerant → `:inline`; large/many rows + latency-sensitive +
  Oban-as-normal-infra → `:oban`. Keep the existing honest truth/cannot-say boundaries and
  add the `RelatedWorker` retry/cancel outcomes (D-04) so adopters know what failures look like.
- **D-09:** Remove the strings the old contract test asserted ("temporary workaround",
  "first-class feature") — they must not survive anywhere in the guide.

### 91-02 — `mix verify.phase91` + docs contract (TEST-01, TEST-02)
- **D-10:** New `Mix.Tasks.Verify.Phase91` mirroring the `verify.phase85` shape
  (`lib/mix/tasks/verify.phase85.ex`): `app.start` → no-args guard → run focused tests →
  `mix docs --warnings-as-errors`. Focused test set:
  `test/scrypath/sync/related_test.exs`, `test/scrypath/sync/related_worker_test.exs`,
  `test/scrypath/docs_contract_test.exs`. These are hermetic (no live Meilisearch), which
  is how TEST-01 is satisfied — the gate *runs* the existing hermetic propagation tests.
- **D-11 (TEST-02):** Invert the existing docs-contract test
  (`test/scrypath/docs_contract_test.exs:1128`, "related-data guide explicitly mentions
  temporary Oban workaround"). New assertions on `guides/related-data-and-reindexing.md`:
  - does **NOT** contain `"temporary workaround"` or `"first-class feature"`;
  - **DOES** reference `Scrypath.sync_related/3`, a `fan_outs:` declaration, and both
    `sync_mode: :inline` and `sync_mode: :oban`;
  - articulates the **context-owned orchestration vs library-owned execution** boundary and
    the **no-callback-magic** invariant (the literal boundary phrasing the guide will use).
- **D-12:** Register the new task file in the docs-contract test's `@verify_phase*`
  module-attribute list so the verify task stays discoverable per the existing pattern
  (`docs_contract_test.exs` reads each `verify.phaseNN.ex` source).

### 91-03 — Phoenix example polish
- **D-13:** Add an `Author` schema + `posts.author_id` association (migration) to
  `examples/phoenix_meilisearch`. `Author` declares a `fan_outs:` entry targeting
  `ScrypathDemo.Blog.Post` via a Blog-context resolver. The example's `update_author` flow
  calls `Scrypath.sync_related(Author, author, fan_out: :posts, …)` so renaming an author
  re-syncs that author's post documents (the canonical Author-rename example from the guide).
- **D-14 (user-selected):** The example smoke proof exercises **both** the `sync_mode: :inline`
  and `sync_mode: :oban` fan-out paths — mirroring the example's existing dual `sync_record`
  smoke coverage (`test/smoke/meilisearch_stack_test.exs` inline,
  `test/smoke/meilisearch_oban_stack_test.exs` Oban) and making the EXEC-02 guidance
  demonstrable end-to-end. Oban already wired in the example (`config/config.exs`,
  `config/test.exs` `testing: :inline`).
- **D-15:** The mechanism for getting the renamed author's name into the Post document
  (denormalized `author_name` column kept in sync vs an app-owned preload inside the
  resolver/projection) is an **implementation detail left to research/planning**. Locked
  constraint: whatever mechanism is chosen stays **app-owned and explicit** — the library
  must not gain implicit preload/association-walking behavior to make this example work.
- **D-16:** Update `examples/phoenix_meilisearch/README.md` to describe the related-data
  fan-out path alongside the existing inline/Oban `sync_record` narrative.

### Claude's Discretion
- Exact section ordering and prose of the rewritten guide, provided D-06–D-09 hold.
- Exact assertion strings in the docs-contract test, provided they enforce D-11.
- The `author_name` projection mechanism in the example (D-15), provided it stays explicit.
- Whether the example needs a thin `ScrypathDemo.Blog` context module to host the resolver
  + `update_author/2` (likely yes, since the context currently lives only in smoke tests).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/milestones/v1.24-REQUIREMENTS.md` — EXEC-02, TEST-01, TEST-02 definitions and the
  related-data Out-of-Scope table (callback magic, changeset field-diffing, full-index rebuild).
- `.planning/milestones/v1.24-ROADMAP.md` — Phase 91 goal, the three plan stubs, and the
  milestone working assumptions (explicit orchestration, opt-in Oban, tenant-safe deferred).

### Shipped API this phase documents (read to get signatures right)
- `lib/scrypath.ex` §`sync_related/3` (line ~192) — public entrypoint + `@spec`.
- `lib/scrypath/sync.ex` §`sync_related/3` (line ~38) — inline resolver + `:oban` dispatch,
  `fan_out` required, resolver MFA invocation shape.
- `lib/scrypath/options.ex` — `fan_outs:` metadata validation (`target` + `resolver` keys).
- `lib/scrypath/sync/related_worker.ex` — `RelatedWorker.perform/1` retry/cancel matrix (D-04).

### Patterns to mirror
- `lib/mix/tasks/verify.phase85.ex` — canonical recent verify-task shape for 91-02 (D-10).
- `test/scrypath/docs_contract_test.exs` — `@verify_phase*` attr list (line ~26), `@guide_paths`
  (line ~33), the existing related-data test to invert (line ~1128), and `assert_contains_all/2`.
- `test/scrypath/sync/related_test.exs`, `test/scrypath/sync/related_worker_test.exs` — the
  hermetic propagation tests the new gate runs (TEST-01).

### Files to edit
- `guides/related-data-and-reindexing.md` — the rewrite target (91-01).
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex`,
  `examples/phoenix_meilisearch/README.md`,
  `examples/phoenix_meilisearch/priv/repo/` (migration),
  `examples/phoenix_meilisearch/test/smoke/` — example polish (91-03).

### Upstream decision records
- `.planning/phases/90-async-execution/90-DISCUSS.md` — worker-not-macro + transient/permanent
  error design rationale (D-03, D-04).
- `.planning/phases/89-related-data/89-0{1,2,3}-SUMMARY.md`,
  `.planning/phases/90-async-execution/90-0{1,2}-SUMMARY.md` — what was actually built.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `verify.phase85` task structure (`app.start` → focused tests → `mix docs --warnings-as-errors`)
  is copy-adaptable for `verify.phase91` (D-10).
- `docs_contract_test.exs` helpers `assert_contains_all/2`, `ordered?/3`, `extract_elixir_fences/1`,
  and the `@guide_paths`/`@verify_phase*` attr lists are the wiring points for D-11/D-12.
- The example already wires Oban (`config/config.exs`, `config/test.exs` `testing: :inline`) and
  has parallel inline/Oban smoke tests for `sync_record` — D-14 extends this same shape to fan-out.

### Established Patterns
- Schemas declare search behavior via `use Scrypath, fields: …, filterable: …` (see
  `examples/.../blog/post.ex`). `fan_outs:` is declared on the *owning* schema (Author), not Post.
- Verify tasks are kept discoverable by being read into `docs_contract_test.exs` — new tasks must
  be registered there or the contract test does not cover them.
- Guides are listed in `@guide_paths`; `related-data-and-reindexing.md` is already present (line ~54).

### Integration Points
- `verify.phase91` joins the existing `mix verify.phaseNN` family and the docs-contract spine.
- The example's new `Author`/fan-out path connects to the existing `phoenix-example-integration`
  CI job and the `SCRYPATH_EXAMPLE_INTEGRATION` smoke gating described in the example README.
</code_context>

<specifics>
## Specific Ideas

- The guide's canonical worked example should be **Author rename → re-sync the author's posts**
  (posts store `author_name`), matching the example app and the existing guide's recurring
  Author/Post motif (current lines 9, 60, 168). Keep both the schema-side declaration and the
  context-side call in the same example so adopters see the full loop.
- The guide must keep the existing "Truth you can say / Truth you cannot say" honesty block and
  attach it to the `:oban` path explicitly.
</specifics>

<deferred>
## Deferred Ideas

- **Tenant-safe search access (AUTH-01)** — explicitly the next milestone's wedge, not this phase
  (v1.24-REQUIREMENTS.md "Future requirements carried forward"). The guide may *mention* that
  tenant/permission changes are higher-risk related-data events (it already does), but no
  tenant-safety mechanism is built here.
- **High-cardinality facet-value search (FACET-UX-01)** — unrelated catalog-depth follow-on.
- No scope-creep ideas surfaced during discussion — stayed within docs/verify/example boundaries.

</deferred>

---

*Phase: 91-integration-guides-and-verification*
*Context gathered: 2026-05-25*
